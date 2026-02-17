#!/usr/bin/env bash
#
# NAS 備份腳本（整合版）
# 從遠端 NAS 備份到本地外接硬碟，透過 Tailscale 連線
#
# 使用方式:
#   ./nas_backup.sh test              測試連線（Ping、SSH、路徑）
#   ./nas_backup.sh list [路徑]       列出遠端資料夾
#   ./nas_backup.sh backup [--force] [--parallel] [--fpsync]   執行單向備份
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/nas_backup.conf"
BACKUP_PATHS_FILE="$SCRIPT_DIR/backup_paths.txt"
NOTIFY_ENV="$SCRIPT_DIR/backup_notify.env"

CMD="${1:-}"
shift || true

show_help() {
    echo "用法: $0 <指令> [選項]"
    echo ""
    echo "指令:"
    echo "  test              測試 NAS 連線（Ping、SSH、路徑存取）"
    echo "  list [路徑]       列出遠端資料夾（不指定則列出 NAS_BASE_PATH）"
    echo "  backup [--force] [--parallel] [--fpsync]  執行單向備份"
    echo "      --force 略過空間檢查；--parallel 多路徑同時備份"
    echo "      --fpsync 使用 fpsync 加速（無即時進度）；預設 rsync 有進度顯示"
    echo ""
    echo "範例:"
    echo "  $0 test"
    echo "  $0 list"
    echo "  $0 list photos"
    echo "  $0 backup"
    echo "  $0 backup --force"
    echo "  $0 backup --parallel"
    echo "  $0 backup --fpsync"
}

# 載入設定並檢查必要變數
load_config() {
    local required=("$@")
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "錯誤: 找不到 $CONFIG_FILE"
        echo "請複製 nas_backup.conf.example 為 nas_backup.conf 並填入設定"
        exit 1
    fi
    source "$CONFIG_FILE"
    for var in "${required[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "錯誤: $CONFIG_FILE 中缺少 $var"
            exit 1
        fi
    done
}

# 取得 SSH 選項
get_ssh_opts() {
    local timeout="${1:-10}"
    local opts="-o ConnectTimeout=$timeout"
    [[ -n "${SSH_KEY:-}" && -f "${SSH_KEY/\~/$HOME}" ]] && opts="$opts -i ${SSH_KEY/\~/$HOME} -o BatchMode=yes"
    echo "$opts"
}

# 通知函數（Telegram 或 Email）
notify() {
    local msg="$1"
    echo "$msg"
    if [[ ! -f "$NOTIFY_ENV" ]]; then
        return
    fi
    source "$NOTIFY_ENV"
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
            --data-urlencode "text=$msg" &>/dev/null && echo "  (已發送 Telegram 通知)"
    elif [[ -n "${NOTIFY_EMAIL:-}" ]] && command -v mail &>/dev/null; then
        echo "$msg" | mail -s "NAS 備份通知" "$NOTIFY_EMAIL" 2>/dev/null || true
    fi
}

# --- 指令: test ---
cmd_test() {
    load_config NAS_HOST NAS_USER
    SSH_OPTS=$(get_ssh_opts 5)
    NAS_BASE="${NAS_BASE_PATH:-/}"

    echo "=== NAS 連線測試 ==="
    echo "目標: $NAS_USER@$NAS_HOST"
    echo ""

    echo "[1/3] Ping 測試..."
    if ping -c 2 -W 3 "$NAS_HOST" &>/dev/null; then
        echo "  ✓ Ping 成功"
    else
        echo "  ✗ Ping 失敗（可能 NAS 阻擋 ICMP，繼續測試 SSH）"
    fi

    echo ""
    echo "[2/3] SSH 連線測試..."
    if ssh $SSH_OPTS "$NAS_USER@$NAS_HOST" "echo 'SSH 連線成功'" 2>/dev/null; then
        echo "  ✓ SSH 連線成功"
    else
        echo "  ✗ SSH 連線失敗"
        echo "  請確認：Tailscale 連線、NAS SSH 服務、NAS_USER/NAS_HOST、SSH_KEY"
        exit 1
    fi

    echo ""
    echo "[3/3] 路徑存取測試..."
    if ssh $SSH_OPTS "$NAS_USER@$NAS_HOST" "test -d '$NAS_BASE' && echo '路徑可存取'" 2>/dev/null; then
        echo "  ✓ 基礎路徑 $NAS_BASE 可存取"
    else
        echo "  ✗ 無法存取 $NAS_BASE"
    fi
    echo ""
    echo "=== 連線測試完成 ==="
}

# --- 指令: list ---
cmd_list() {
    load_config NAS_HOST NAS_USER
    SSH_OPTS=$(get_ssh_opts 5)

    if [[ -z "${1:-}" ]]; then
        REMOTE_PATH="${NAS_BASE_PATH:-/}"
    elif [[ "$1" == /* ]]; then
        REMOTE_PATH="$1"
    else
        REMOTE_PATH="${NAS_BASE_PATH:-/}/${1}"
    fi
    [[ "$REMOTE_PATH" != */ ]] && REMOTE_PATH="${REMOTE_PATH}/"

    echo "=== 遠端 NAS 資料夾列表 ==="
    echo "路徑: $REMOTE_PATH"
    echo ""

    ssh $SSH_OPTS "$NAS_USER@$NAS_HOST" "ls -la '$REMOTE_PATH'" 2>/dev/null || {
        echo "錯誤: 無法列出 $REMOTE_PATH"
        echo "請先執行: $0 test"
        exit 1
    }
    echo ""
    echo "提示: 將要備份的路徑加入 backup_paths.txt，每行一個路徑（相對於 NAS_BASE_PATH）"
}

# --- 指令: backup ---
cmd_backup() {
    load_config NAS_HOST NAS_USER LOCAL_BACKUP_ROOT
    SSH_OPTS=$(get_ssh_opts 10)
    RSYNC_SSH="ssh $SSH_OPTS"

    FORCE_MODE=false
    PARALLEL_MODE=false
    FPSYNC_MODE=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)    FORCE_MODE=true ;;
            --parallel) PARALLEL_MODE=true ;;
            --fpsync)   FPSYNC_MODE=true ;;
        esac
        shift
    done

    NAS_BASE="${NAS_BASE_PATH:-/}"
    [[ "$NAS_BASE" != */ ]] && NAS_BASE="${NAS_BASE}/"

    if [[ ! -f "$BACKUP_PATHS_FILE" ]]; then
        echo "錯誤: 找不到 $BACKUP_PATHS_FILE"
        exit 1
    fi

    if [[ ! -d "$LOCAL_BACKUP_ROOT" ]]; then
        echo "錯誤: 本地備份目錄不存在: $LOCAL_BACKUP_ROOT"
        exit 1
    fi

    PATHS=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        line="${line%%#*}"
        line="${line// /}"
        [[ -z "$line" ]] && continue
        PATHS+=("$line")
    done < "$BACKUP_PATHS_FILE"

    if [[ ${#PATHS[@]} -eq 0 ]]; then
        echo "錯誤: backup_paths.txt 中沒有有效的路徑"
        exit 1
    fi

    echo "=== NAS 備份 ==="
    echo "遠端: $NAS_USER@$NAS_HOST"
    echo "本地: $LOCAL_BACKUP_ROOT"
    echo "路徑: ${PATHS[*]}"
    echo ""

    echo "[1/3] 計算備份來源總大小..."
    TOTAL_BYTES=0
    for rel_path in "${PATHS[@]}"; do
        full_path="${NAS_BASE}${rel_path}"
        size=$(ssh $SSH_OPTS "$NAS_USER@$NAS_HOST" "du -sb '$full_path' 2>/dev/null | cut -f1" 2>/dev/null)
        if [[ -z "$size" ]]; then
            size_k=$(ssh $SSH_OPTS "$NAS_USER@$NAS_HOST" "du -sk '$full_path' 2>/dev/null | cut -f1" 2>/dev/null || echo "0")
            size=$((size_k * 1024))
        fi
        TOTAL_BYTES=$((TOTAL_BYTES + size))
    done
    TOTAL_GB=$((TOTAL_BYTES / 1024 / 1024 / 1024))
    TOTAL_MB=$((TOTAL_BYTES / 1024 / 1024))
    echo "  來源總大小: ${TOTAL_GB} GB (${TOTAL_MB} MB)"
    echo ""

    echo "[2/3] 檢查本地磁碟空間..."
    AVAIL_BYTES=$(df -P "$LOCAL_BACKUP_ROOT" 2>/dev/null | tail -1 | awk '{print $4*512}')
    AVAIL_GB=$((AVAIL_BYTES / 1024 / 1024 / 1024))
    AVAIL_MB=$((AVAIL_BYTES / 1024 / 1024))
    echo "  可用空間: ${AVAIL_GB} GB (${AVAIL_MB} MB)"
    echo ""

    if [[ "$FORCE_MODE" != true ]] && [[ $AVAIL_BYTES -lt $TOTAL_BYTES ]]; then
        MSG="❌ 備份中止：空間不足

來源總大小: ${TOTAL_GB} GB
可用空間: ${AVAIL_GB} GB

請釋放空間後再執行，或使用 --force 略過檢查。"
        notify "$MSG"
        exit 1
    fi
    echo "  空間檢查通過 ✓"
    echo ""

    echo "[3/3] 開始備份${PARALLEL_MODE:+（平行模式）}..."
    BACKUP_START=$(date +%s)
    BACKUP_ERRORS=0

    # 預設 rsync（有即時進度）；--fpsync 時才用 fpsync（較快但無進度）
    USE_FPSYNC=false
    RSYNC_OPTS=(-az --update --no-perms --no-owner --no-group --info=progress2 --stats)
    if [[ "$FPSYNC_MODE" == true ]]; then
        HAS_FPSYNC=false
        HAS_SSHFS=false
        (command -v fpsync &>/dev/null || [[ -x /usr/bin/fpsync ]]) && HAS_FPSYNC=true
        (command -v sshfs &>/dev/null || [[ -x /usr/bin/sshfs ]]) && HAS_SSHFS=true
        if [[ "$HAS_FPSYNC" == true ]] && [[ "$HAS_SSHFS" == true ]]; then
            USE_FPSYNC=true
            FPSYNC_JOBS=4
            FPSYNC_MOUNT_BASE="/tmp/fpsync_nas_$$"
            mkdir -p "$FPSYNC_MOUNT_BASE"
            trap 'cleanup_fpsync_mounts' EXIT
            echo "  使用 fpsync 備份（無即時進度）"
        else
            [[ "$HAS_FPSYNC" != true ]] && echo "  (fpsync 未找到，改用 rsync)"
            [[ "$HAS_SSHFS" != true ]] && echo "  (sshfs 未找到，改用 rsync)"
        fi
    fi

    cleanup_fpsync_mounts() {
        [[ -z "${FPSYNC_MOUNT_BASE:-}" ]] && return
        for m in "$FPSYNC_MOUNT_BASE"/*/; do
            [[ -d "$m" ]] && { umount "$m" 2>/dev/null || fusermount -u "$m" 2>/dev/null; } || true
        done
        rm -rf "$FPSYNC_MOUNT_BASE" 2>/dev/null || true
    }

    do_sync() {
        local rel_path="$1"
        local full_remote="${NAS_BASE}${rel_path}"
        local local_dest="$LOCAL_BACKUP_ROOT/$rel_path"
        mkdir -p "$local_dest"

        if [[ "$USE_FPSYNC" == true ]]; then
            local mount_safe="${rel_path//\//_}"
            local mount_pt="$FPSYNC_MOUNT_BASE/$mount_safe"
            mkdir -p "$mount_pt"
            # sshfs 掛載遠端
            local sshfs_opts="-o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"
            [[ -n "${SSH_KEY:-}" && -f "${SSH_KEY/\~/$HOME}" ]] && sshfs_opts="$sshfs_opts -o IdentityFile=${SSH_KEY/\~/$HOME}"
            if ! sshfs "$NAS_USER@$NAS_HOST:$full_remote" "$mount_pt" $sshfs_opts 2>/dev/null; then
                echo "  ⚠ 掛載失敗: $rel_path，改用 rsync"
                rsync -az --update --no-perms --no-owner --no-group --info=progress2 --stats \
                    -e "ssh $SSH_OPTS" "$NAS_USER@$NAS_HOST:$full_remote/" "$local_dest/" 2>&1
                return $?
            fi
            # fpsync: -n 平行數 -f 每 job 檔案數 -s 每 job 大小 -o rsync 選項
            # --no-perms/owner/group 避免外接硬碟權限錯誤；--update 略過較新檔案
            local fpsync_ok=false
            if fpsync -n "$FPSYNC_JOBS" -f 2000 -s $((2 * 1024 * 1024 * 1024)) \
                -o "-q -lptgoD -z --update --no-perms --no-owner --no-group --stats" \
                "$mount_pt/" "$local_dest/" 2>&1; then
                fpsync_ok=true
            fi
            umount "$mount_pt" 2>/dev/null || fusermount -u "$mount_pt" 2>/dev/null || true
            rmdir "$mount_pt" 2>/dev/null || true
            $fpsync_ok
        else
            rsync "${RSYNC_OPTS[@]}" -e "$RSYNC_SSH" \
                "$NAS_USER@$NAS_HOST:$full_remote/" "$local_dest/" 2>&1
        fi
    }

    if [[ "$PARALLEL_MODE" == true ]] && [[ ${#PATHS[@]} -gt 1 ]]; then
        PIDS=()
        for rel_path in "${PATHS[@]}"; do
            echo ">>> 備份（背景）: $rel_path"
            do_sync "$rel_path" &
            PIDS+=($!)
        done
        for i in "${!PIDS[@]}"; do
            if ! wait "${PIDS[$i]}"; then
                echo "  ⚠ 錯誤: ${PATHS[$i]} 備份失敗"
                ((BACKUP_ERRORS++)) || true
            fi
        done
    else
        for rel_path in "${PATHS[@]}"; do
            echo ""
            echo ">>> 備份: $rel_path"
            if ! do_sync "$rel_path"; then
                echo "  ⚠ 錯誤: $rel_path 備份失敗"
                ((BACKUP_ERRORS++)) || true
            fi
        done
    fi

    BACKUP_END=$(date +%s)
    DURATION=$((BACKUP_END - BACKUP_START))
    M=$((DURATION / 60))
    S=$((DURATION % 60))

    echo ""
    echo "=== 備份完成 ==="
    echo "  耗時: ${M} 分 ${S} 秒"
    if [[ $BACKUP_ERRORS -gt 0 ]]; then
        echo "  狀態: ⚠ $BACKUP_ERRORS 個路徑發生錯誤"
    else
        echo "  狀態: ✓ 全部成功"
    fi
    notify "✅ NAS 備份已完成 - $(date '+%Y-%m-%d %H:%M')，耗時 ${M}m${S}s"
}

# --- 主程式 ---
case "$CMD" in
    test)
        cmd_test
        ;;
    list)
        cmd_list "$@"
        ;;
    backup)
        cmd_backup "$@"
        ;;
    -h|--help|help|"")
        show_help
        ;;
    *)
        echo "錯誤: 未知指令 '$CMD'"
        show_help
        exit 1
        ;;
esac

#!/usr/bin/env bash
#
# 部署腳本：安裝 tools.txt 與 python_packages.txt 中的套件，
# 並將 configs/ 複製到正確路徑
# 支援 Linux (apt) 與 macOS (brew)
#
# Config 處理模式（當目標已存在時）:
#   overwrite   - 備份後覆蓋（預設）
#   skip        - 略過已存在的 config
#   interactive - 逐一詢問是否覆蓋
#   check       - 僅檢查與預覽，不實際部署
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_FILE="$SCRIPT_DIR/tools.txt"
PYTHON_FILE="$SCRIPT_DIR/python_packages.txt"
CONFIG_MAPPING="$SCRIPT_DIR/config_mapping.txt"

# 預設：備份後覆蓋
CONFIG_MODE="overwrite"

# 解析參數
for arg in "$@"; do
    case "$arg" in
        --config-overwrite)   CONFIG_MODE="overwrite" ;;
        --config-skip)        CONFIG_MODE="skip" ;;
        --config-interactive) CONFIG_MODE="interactive" ;;
        --config-check)       CONFIG_MODE="check" ;;
        -h|--help)
            echo "用法: $0 [選項]"
            echo ""
            echo "Config 處理選項（當目標路徑已存在時）:"
            echo "  --config-overwrite   備份現有 config 後覆蓋（預設）"
            echo "  --config-skip        略過已存在的 config，保留本機設定"
            echo "  --config-interactive 逐一顯示 diff 並詢問是否覆蓋"
            echo "  --config-check       僅檢查與預覽，不實際部署（略過套件安裝）"
            exit 0
            ;;
    esac
done

# 偵測系統與套件管理器
detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo ""
    fi
}

# apt 與 brew 套件名稱對照（不同則需映射）
# 回傳空字串表示該平台略過不安裝
get_package_name() {
    local pkg="$1"
    local pm="$2"
    case "$pkg" in
        openssh-client)
            [[ "$pm" == "brew" ]] && echo "openssh" || echo "openssh-client"
            ;;
        openssh-server)
            [[ "$pm" == "brew" ]] && echo "" || echo "openssh-server"
            ;;
        fd-find)
            [[ "$pm" == "brew" ]] && echo "fd" || echo "fd-find"
            ;;
        python3)
            [[ "$pm" == "brew" ]] && echo "python" || echo "python3 python3-pip python3-venv"
            ;;
        python3-pip|python3-venv)
            [[ "$pm" == "brew" ]] && echo "" || echo "$pkg"
            ;;
        # Linux 專用，macOS 略過
        xfce4|xfce4-goodies|xorg|dbus-x11|x11-xserver-utils|xrdp|exfat-utils|exfat-fuse|fpart|sshfs)
            [[ "$pm" == "brew" ]] && echo "" || echo "$pkg"
            ;;
        deluged)
            [[ "$pm" == "brew" ]] && echo "deluge" || echo "deluged"
            ;;
        deluge-web)
            [[ "$pm" == "brew" ]] && echo "" || echo "deluge-web"
            ;;
        *)
            echo "$pkg"
            ;;
    esac
}

# 略過的套件（需手動安裝，如 oh-my-zsh）
SKIP_PACKAGES="oh-my-zsh powerlevel10k"

echo "=== 環境部署腳本 ==="
echo "Repo 根目錄: $REPO_ROOT"
echo ""

# 檢查套件管理器
PM=$(detect_package_manager)
if [[ -z "$PM" ]]; then
    echo "錯誤: 找不到 apt 或 brew，請先安裝其中之一。"
    echo "  - Linux: sudo apt update && sudo apt install -y apt"
    echo "  - macOS: https://brew.sh"
    exit 1
fi
echo "偵測到套件管理器: $PM"
echo ""

# check 模式僅檢查 config，不安裝套件
if [[ "$CONFIG_MODE" != "check" ]]; then

# --- 安裝系統套件 ---
if [[ -f "$TOOLS_FILE" ]]; then
    echo "=== 安裝系統套件 (tools.txt) ==="
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        pkg="${line%%#*}"
        pkg="${pkg// /}"
        [[ -z "$pkg" ]] && continue

        # 檢查是否在略過清單
        if echo "$SKIP_PACKAGES" | grep -qw "$pkg"; then
            echo "[略過] $pkg (需手動安裝)"
            continue
        fi

        install_name=$(get_package_name "$pkg" "$PM")
        if [[ -z "$install_name" ]]; then
            echo "[略過] $pkg (該平台不適用)"
            continue
        fi
        if [[ "$PM" == "apt" ]]; then
            to_install=()
            for p in $install_name; do
                if ! dpkg -s "$p" &>/dev/null; then
                    to_install+=("$p")
                else
                    echo "[已安裝] $p"
                fi
            done
            if [[ ${#to_install[@]} -gt 0 ]]; then
                echo "[安裝] ${to_install[*]}"
                sudo apt-get install -y "${to_install[@]}"
            fi
        else
            # brew: install_name 可能有多個
            for p in $install_name; do
                if brew list "$p" &>/dev/null; then
                    echo "[已安裝] $p"
                else
                    echo "[安裝] $p"
                    brew install "$p"
                fi
            done
        fi
    done < "$TOOLS_FILE"
    echo ""
fi

# --- 安裝 Python 套件 ---
if [[ -f "$PYTHON_FILE" ]]; then
    echo "=== 安裝 Python 套件 ==="
    if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
        PIP_CMD="pip3"
        command -v pip3 &>/dev/null || PIP_CMD="pip"
        echo "使用: $PIP_CMD install -r python_packages.txt"
        $PIP_CMD install -r "$PYTHON_FILE" || {
            echo "警告: 部分套件安裝失敗，請檢查 python_packages.txt"
        }
    else
        echo "警告: 找不到 pip/pip3，略過 Python 套件安裝"
    fi
    echo ""
fi

fi  # CONFIG_MODE != check

# --- 部署設定檔 ---
if [[ -f "$CONFIG_MAPPING" ]]; then
    echo "=== 部署設定檔 (模式: $CONFIG_MODE) ==="

    if [[ "$CONFIG_MODE" == "check" ]]; then
        echo ""
        echo "【檢查】以下為 config 對應狀態："
        echo ""
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        src_repo="${line##*|}"
        dst_path="${line%%|*}"
        dst_path="${dst_path//\~/$HOME}"
        src_full="$REPO_ROOT/$src_repo"

        if [[ ! -e "$src_full" ]]; then
            echo "[略過] $src_repo (repo 中不存在)"
            continue
        fi

        dst_exists=false
        [[ -e "$dst_path" ]] && dst_exists=true

        # check 模式：僅顯示狀態
        if [[ "$CONFIG_MODE" == "check" ]]; then
            if [[ "$dst_exists" == true ]]; then
                if [[ -f "$dst_path" ]] && [[ -f "$src_full" ]]; then
                    if diff -q "$src_full" "$dst_path" &>/dev/null; then
                        echo "  $dst_path"
                        echo "    → 已存在，與 repo 相同"
                    else
                        echo "  $dst_path"
                        echo "    → 已存在，與 repo 不同（可執行 diff 比較）"
                    fi
                else
                    echo "  $dst_path"
                    echo "    → 已存在（目錄或類型不同）"
                fi
            else
                echo "  $dst_path"
                echo "    → 不存在，部署時會新增"
            fi
            continue
        fi

        # 目標已存在時的處理
        if [[ "$dst_exists" == true ]]; then
            case "$CONFIG_MODE" in
                skip)
                    echo "[略過] $dst_path (已存在)"
                    continue
                    ;;
                interactive)
                    echo ""
                    echo "目標已存在: $dst_path"
                    if [[ -f "$dst_path" ]] && [[ -f "$src_full" ]]; then
                        diff "$dst_path" "$src_full" 2>/dev/null || true
                    fi
                    read -p "覆蓋? [y/N]: " ans
                    ans="${ans:-n}"
                    if [[ ! "$ans" =~ ^[yY] ]]; then
                        echo "  → 略過"
                        continue
                    fi
                    # 使用者確認後，仍先備份
                    backup_suffix=".backup.$(date +%Y%m%d_%H%M%S)"
                    if [[ -d "$dst_path" ]]; then
                        backup_path="${dst_path}${backup_suffix}"
                        echo "[備份] $dst_path -> $backup_path"
                        mv "$dst_path" "$backup_path"
                    else
                        backup_path="${dst_path}${backup_suffix}"
                        echo "[備份] $dst_path -> $backup_path"
                        cp "$dst_path" "$backup_path"
                    fi
                    ;;
                overwrite)
                    # 備份現有 config
                    backup_suffix=".backup.$(date +%Y%m%d_%H%M%S)"
                    if [[ -d "$dst_path" ]]; then
                        backup_path="${dst_path}${backup_suffix}"
                        echo "[備份] $dst_path -> $backup_path"
                        mv "$dst_path" "$backup_path"
                    else
                        backup_path="${dst_path}${backup_suffix}"
                        echo "[備份] $dst_path -> $backup_path"
                        cp "$dst_path" "$backup_path"
                    fi
                    ;;
            esac
        fi

        dst_dir="$(dirname "$dst_path")"
        if [[ ! -d "$dst_dir" ]]; then
            echo "[建立] $dst_dir"
            mkdir -p "$dst_dir"
        fi

        if [[ -d "$src_full" ]]; then
            echo "[部署] $src_repo -> $dst_path"
            [[ -e "$dst_path" ]] && rm -rf "$dst_path"
            cp -r "$src_full" "$dst_path"
        else
            echo "[部署] $src_repo -> $dst_path"
            cp "$src_full" "$dst_path"
        fi
    done < "$CONFIG_MAPPING"
    echo ""
fi

echo "=== 部署完成 ==="
echo ""
echo "若使用 zsh + oh-my-zsh + powerlevel10k，請手動安裝："
echo "  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
echo "  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
echo "  並在 .zshrc 中設定 ZSH_THEME=\"powerlevel10k/powerlevel10k\""

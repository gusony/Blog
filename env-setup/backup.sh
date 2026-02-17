#!/usr/bin/env bash
#
# 備份腳本：將常用設定檔備份到本 repo 的 configs/ 目錄
# 執行後會 git add, commit, 並提示是否 push
# 支援 Linux 與 macOS
#

set -e

# 取得腳本所在目錄，並切換到 repo 根目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_MAPPING="$SCRIPT_DIR/config_mapping.txt"

cd "$REPO_ROOT"

echo "=== 設定檔備份腳本 ==="
echo "Repo 根目錄: $REPO_ROOT"
echo ""

# 檢查 config_mapping.txt 是否存在
if [[ ! -f "$CONFIG_MAPPING" ]]; then
    echo "錯誤: 找不到 config_mapping.txt"
    exit 1
fi

BACKED_UP=0
SKIPPED=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # 略過空行與註解
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # 解析 來源|目標
    src="${line%%|*}"
    dst="${line##*|}"
    src="${src//\~/$HOME}"
    dst="$REPO_ROOT/$dst"

    # 確保目標目錄存在
    dst_dir="$(dirname "$dst")"
    if [[ ! -d "$dst_dir" ]]; then
        mkdir -p "$dst_dir"
    fi

    if [[ -e "$src" ]]; then
        if [[ -d "$src" ]]; then
            echo "[備份] $src -> $dst (目錄)"
            rm -rf "$dst"
            cp -r "$src" "$dst"
        else
            echo "[備份] $src -> $dst"
            cp "$src" "$dst"
        fi
        ((BACKED_UP++)) || true
    else
        echo "[略過] $src (不存在)"
        ((SKIPPED++)) || true
    fi
done < "$CONFIG_MAPPING"

echo ""
echo "備份完成: $BACKED_UP 個檔案/目錄, 略過 $SKIPPED 個不存在的項目"
echo ""

if [[ $BACKED_UP -eq 0 ]]; then
    echo "沒有需要備份的變更，結束。"
    exit 0
fi

# Git 操作
echo "=== Git 操作 ==="
git add -A configs/
git status

echo ""
read -p "是否要 commit 並 push? (y/N): " confirm
confirm="${confirm:-n}"

if [[ "$confirm" =~ ^[yY] ]]; then
    git add -A env-setup/
    git commit -m "chore: backup config files"
    echo ""
    read -p "是否 push 到遠端? (y/N): " push_confirm
    push_confirm="${push_confirm:-n}"
    if [[ "$push_confirm" =~ ^[yY] ]]; then
        git push
        echo "已 push 到遠端。"
    else
        echo "已 commit，請稍後手動 git push。"
    fi
else
    echo "已備份到本地，請手動 git add / commit / push。"
fi

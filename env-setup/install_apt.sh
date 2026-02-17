#!/usr/bin/env bash
# apt 快速安裝：從 tools.txt 擷取套件並安裝
# 完整部署請使用 deploy.sh（含 brew 支援與 config）
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_FILE="$SCRIPT_DIR/tools.txt"

sudo apt update -y
sudo apt upgrade -y
grep -v '^#' "$TOOLS_FILE" | grep -v '^[[:space:]]*$' | sed 's/#.*//' | awk '{print $1}' | grep -v '^$' | xargs -r sudo apt install -y
sudo apt autoremove -y

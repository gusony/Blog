#!/usr/bin/env bash
#
# 查詢腳本：顯示已安裝套件及其使用的設定檔路徑
# 用法:
#   ./list_packages.sh              # 列出 tools.txt 中所有套件與其 config
#   ./list_packages.sh --installed  # 僅列出已安裝的套件
#   ./list_packages.sh vim tmux     # 查詢指定套件
#   ./list_packages.sh --config    # 僅顯示 config 路徑（精簡輸出）
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_FILE="$SCRIPT_DIR/tools.txt"
MAPPING_FILE="$SCRIPT_DIR/package_config_mapping.txt"

# 偵測套件管理器
detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v brew &>/dev/null; then
        echo "brew"
    else
        echo ""
    fi
}

# 取得實際套件名稱（apt/brew 對照）
get_install_names() {
    local pkg="$1"
    local pm="$2"
    case "$pkg" in
        openssh-client) [[ "$pm" == "brew" ]] && echo "openssh" || echo "openssh-client" ;;
        fd-find)        [[ "$pm" == "brew" ]] && echo "fd" || echo "fd-find" ;;
        python3)        [[ "$pm" == "brew" ]] && echo "python" || echo "python3" ;;
        *)              echo "$pkg" ;;
    esac
}

# 檢查套件是否已安裝
is_installed() {
    local pkg="$1"
    local pm="$2"
    local check_name
    check_name=$(get_install_names "$pkg" "$pm")

    if [[ "$pm" == "apt" ]]; then
        dpkg -s "$check_name" &>/dev/null
    else
        brew list "$check_name" &>/dev/null
    fi
}

# 取得套件對應的 config 路徑
get_config_for_package() {
    local pkg="$1"
    local pm="$2"
    local search_name

    # brew 的 openssh 在 mapping 裡是 openssh
    case "$pkg" in
        openssh-client) search_name="openssh-client openssh" ;;
        *)              search_name="$pkg" ;;
    esac

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        map_pkg="${line%%|*}"
        map_paths="${line##*|}"
        for p in $search_name; do
            if [[ "$map_pkg" == "$p" ]]; then
                echo "$map_paths"
                return
            fi
        done
    done < "$MAPPING_FILE"
}

# 主程式
main() {
    local filter_pkgs=()
    local installed_only=false
    local config_only=false

    # 解析參數
    for arg in "$@"; do
        case "$arg" in
            --installed|-i) installed_only=true ;;
            --config|-c)    config_only=true ;;
            -h|--help)
                echo "用法: $0 [選項] [套件名稱...]"
                echo ""
                echo "選項:"
                echo "  --installed, -i  僅顯示已安裝的套件"
                echo "  --config, -c     僅顯示 config 路徑（精簡輸出）"
                echo "  -h, --help       顯示此說明"
                echo ""
                echo "範例:"
                echo "  $0                    # 列出所有套件"
                echo "  $0 --installed        # 僅已安裝"
                echo "  $0 vim tmux git       # 查詢指定套件"
                echo "  $0 -c --installed     # 已安裝套件的 config 路徑"
                exit 0
                ;;
            *) filter_pkgs+=("$arg") ;;
        esac
    done

    PM=$(detect_package_manager)
    if [[ -z "$PM" ]]; then
        echo "錯誤: 找不到 apt 或 brew"
        exit 1
    fi

    [[ ! -f "$TOOLS_FILE" ]] && { echo "錯誤: 找不到 tools.txt"; exit 1; }
    [[ ! -f "$MAPPING_FILE" ]] && { echo "錯誤: 找不到 package_config_mapping.txt"; exit 1; }

    # 收集要顯示的套件
    pkgs_to_show=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        pkg="${line%%#*}"
        pkg="${pkg// /}"
        [[ -z "$pkg" ]] && continue

        if [[ ${#filter_pkgs[@]} -gt 0 ]]; then
            for f in "${filter_pkgs[@]}"; do
                [[ "$pkg" == "$f" ]] && { pkgs_to_show+=("$pkg"); break; }
            done
        else
            pkgs_to_show+=("$pkg")
        fi
    done < "$TOOLS_FILE"

    # 輸出
    if [[ "$config_only" == true ]]; then
        for pkg in "${pkgs_to_show[@]}"; do
            if [[ "$installed_only" == true ]] && ! is_installed "$pkg" "$PM"; then
                continue
            fi
            configs=$(get_config_for_package "$pkg" "$PM")
            if [[ -n "$configs" ]]; then
                echo "$configs" | tr ',' '\n' | sed "s|~|$HOME|g"
            fi
        done
    else
        [[ "$config_only" == false ]] && echo "套件管理器: $PM"
        [[ "$config_only" == false ]] && echo ""

        for pkg in "${pkgs_to_show[@]}"; do
            if [[ "$installed_only" == true ]] && ! is_installed "$pkg" "$PM"; then
                continue
            fi

            status="未安裝"
            is_installed "$pkg" "$PM" && status="已安裝"

            configs=$(get_config_for_package "$pkg" "$PM")
            configs="${configs//\~/$HOME}"

            if [[ "$config_only" == true ]]; then
                [[ -n "$configs" ]] && echo "$pkg: ${configs//,/, }"
            else
                printf "%-18s [%s]\n" "$pkg" "$status"
                if [[ -n "$configs" ]]; then
                    echo "$configs" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/^/  → /'
                else
                    echo "  → (無對應 config)"
                fi
                echo ""
            fi
        done
    fi
}

main "$@"

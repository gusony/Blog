#!/usr/bin/env bash
#
# 檢查目錄下所有檔案，找出「英文字母-數字」組合重複的檔案
# 檔名格式通常為: [一段文字_1] [3~5英文字母]-[數字][一段文字_2].mp4
# 只比對 英文字母-數字 的組合（如 ABC-123、XY-4567）
#
# 使用方式: ./find_duplicate_files.sh [目錄]
# 不指定目錄則使用當前目錄
#

set -e

TARGET_DIR="${1:-.}"
[[ ! -d "$TARGET_DIR" ]] && { echo "錯誤: 目錄不存在: $TARGET_DIR"; exit 1; }

TMPFILE=$(mktemp)
trap "rm -f '$TMPFILE'" EXIT

# 從檔名擷取 3~5 英文字母-數字的組合（不區分大小寫，統一轉小寫比對）
while IFS= read -r -d '' file; do
    name=$(basename "$file")
    key=$(echo "$name" | grep -oE '[a-zA-Z]{3,5}-[0-9]+' | tr '[:upper:]' '[:lower:]' | head -1)
    [[ -n "$key" ]] && echo "$key|$file"
done < <(find "$TARGET_DIR" -type f -print0 2>/dev/null) | sort -t'|' -k1,1 > "$TMPFILE"

# 依 key 分組，只輸出重複的
awk -F'|' '
    $1 != prev && prev != "" {
        if (count > 1) {
            if (printed) print "============"
            printed = 1
            print "重複組合: " prev
            for (i = 1; i <= count; i++) print "  " files[i]
        }
        count = 0
    }
    { files[++count] = $2; prev = $1 }
    END {
        if (count > 1) {
            if (printed) print "============"
            print "重複組合: " prev
            for (i = 1; i <= count; i++) print "  " files[i]
        }
        if (!printed && (count <= 1 || NR == 0)) print "未發現重複的 英文字母-數字 組合"
    }
' "$TMPFILE"

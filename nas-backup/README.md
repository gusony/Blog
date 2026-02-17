# NAS 備份腳本

從遠端 NAS（透過 Tailscale）單向備份到本地 Linux 外接硬碟。

## 需求

- Linux（Acer 筆電）
- 已安裝 Tailscale
- NAS 已啟用 SSH
- 外接硬碟已掛載
- `rsync`、`ssh`、`curl`（若使用 Telegram 通知）
- **fpsync + sshfs**（推薦，細碎小檔案平行備份）：`apt install fpart sshfs`
  - 若未安裝，腳本會自動退回 rsync

## 快速開始

```bash
cd nas-backup

# 1. 複製設定檔並填入你的資訊
cp nas_backup.conf.example nas_backup.conf
cp backup_paths.txt.example backup_paths.txt
cp backup_notify.env.example backup_notify.env   # 選填，用於空間不足時通知

# 2. 編輯 nas_backup.conf：NAS 連線、本地備份路徑
# 3. 編輯 backup_paths.txt：要備份的遠端路徑（每行一個）
# 4. 編輯 backup_notify.env：Telegram 或 Email（選填）

# 5. 測試連線
./nas_backup.sh test

# 6. 列出遠端資料夾（確認路徑）
./nas_backup.sh list
./nas_backup.sh list photos   # 指定子路徑

# 7. 執行備份
./nas_backup.sh backup
```

## 指令說明

| 指令 | 功能 |
|------|------|
| `./nas_backup.sh test` | 測試 Ping、SSH、路徑存取 |
| `./nas_backup.sh list [路徑]` | 列出遠端 NAS 資料夾 |
| `./nas_backup.sh backup [--force] [--parallel] [--fpsync]` | 執行單向備份 |

## 備份邏輯

- **rsync**（預設）：有即時進度顯示 `--info=progress2`
- **fpsync**（選用 `--fpsync`）：細碎小檔案較快，但無即時進度
- `--no-perms --no-owner --no-group`：避免外接硬碟(exFAT/NTFS)權限錯誤
- `--update`：目的地較新則略過
- 備份前檢查：計算來源總大小 vs 本地可用空間
- 空間不足時：發送通知（Telegram/Email）並中止
- `--force` 略過空間檢查；`--parallel` 多路徑同時備份

## 個人設定檔（不提交 Git）

- `nas_backup.conf` - NAS 連線、本地路徑
- `backup_paths.txt` - 要備份的路徑列表
- `backup_notify.env` - Telegram Bot Token、Chat ID 或 Email

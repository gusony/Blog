# 個人環境設定 (env-setup)

用於備份與部署個人開發環境的設定檔與套件清單。

## 檔案說明

| 檔案 | 說明 |
|------|------|
| `tools.txt` | 系統套件清單（apt / brew 通用） |
| `python_packages.txt` | Python pip 套件清單 |
| `config_mapping.txt` | 設定檔路徑對應（來源 \| repo 路徑） |
| `package_config_mapping.txt` | 套件與設定檔路徑對應（供 list_packages 使用） |
| `backup.sh` | 備份腳本：將設定檔備份到 repo |
| `deploy.sh` | 部署腳本：安裝套件並複製設定檔 |
| `list_packages.sh` | 查詢腳本：顯示套件安裝狀態與對應的 config 路徑 |

## 使用方式

### 備份 (backup.sh)

將本機設定檔備份到 `configs/`，並可選擇 commit & push：

```bash
cd /path/to/Blog
./env-setup/backup.sh
```

### 部署 (deploy.sh)

在新機器上安裝套件並部署設定檔：

```bash
cd /path/to/Blog
./env-setup/deploy.sh
```

- 會自動偵測 **apt** (Linux) 或 **brew** (macOS)
- 安裝 `tools.txt` 中的系統套件
- 安裝 `python_packages.txt` 中的 Python 套件
- 將 `configs/` 複製到對應路徑

**Config 處理選項**（當目標路徑已存在時）：

| 選項 | 說明 |
|------|------|
| `--config-overwrite` | 備份現有 config 後覆蓋（預設） |
| `--config-skip` | 略過已存在的 config，保留本機設定 |
| `--config-interactive` | 逐一顯示 diff 並詢問是否覆蓋 |
| `--config-check` | 僅檢查與預覽，不實際部署（不安裝套件） |

```bash
./env-setup/deploy.sh --config-check        # 預覽哪些 config 會受影響
./env-setup/deploy.sh --config-skip         # 保留既有 config，只部署不存在的
./env-setup/deploy.sh --config-interactive  # 逐一決定是否覆蓋
```

### 查詢 (list_packages.sh)

顯示套件安裝狀態與其使用的設定檔路徑：

```bash
./env-setup/list_packages.sh              # 列出所有套件
./env-setup/list_packages.sh --installed  # 僅已安裝的套件
./env-setup/list_packages.sh vim tmux     # 查詢指定套件
./env-setup/list_packages.sh -c -i        # 已安裝套件的 config 路徑（精簡）
```

## 自訂

- **tools.txt**：每行一個套件，`#` 開頭為註解
- **python_packages.txt**：每行一個套件，可加版本如 `requests==2.28.0`
- **config_mapping.txt**：新增 `~/.你的路徑|configs/檔名` 以備份/部署更多設定檔
- **package_config_mapping.txt**：新增 `套件名|~/.config路徑` 以讓 list_packages 顯示對應關係

## 需手動安裝的項目

- **oh-my-zsh**
- **powerlevel10k**（zsh 主題）

部署完成後，腳本會提示對應的安裝指令。

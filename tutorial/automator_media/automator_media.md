# Use Mac Automator to custom define media hotkey
```
使用 Automator 建立服務後, 就可以在 “系統偏好設定->鍵盤->快速鍵->服務”中產生我們建立的腳本，以至於可以設定快速鍵
MAC os 10.13
```

## Automator
1. 可以從Launchpad打開, 或者使用spotlight
2. 選擇文件類型 -> 服務
![Alt text](/automator_media/1-2.png)
3. 選擇”動作->工具程式->執行AppleScript" 拖曳到右側視窗
![Alt text](/automator_media/1-3-1.png)
![Alt text](/automator_media/1-3-2.png)
4. 填入需要的腳本

## 腳本
這邊以Spotify為例
* play/pause
```
tell application "Spotify" to playpause
```

* next track
```
tell application "Spotify" to next track
```
* previous track
```
tell application "Spotify" to previous track
```
* volume+
```
set volume output volume (output volume of (get volume settings)) + 2 --100%
```
* volume-
```
set volume output volume (output volume of (get volume settings)) - 2 --100%
```
* mute
```
set volume with output muted
```

## 快捷鍵設定
1 “系統偏好設定->鍵盤->快速鍵->服務” , go to end
2 勾選需要的服務&設定想要的快速鍵
![Alt text](/automator_media/3.png)

[more detail](https://dougscripts.com/itunes/itinfo/info03.php)
Thank!

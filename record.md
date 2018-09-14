## change time
open/close NTP service
```
sudo timedatectl set-ntp no
sudo timedatectl set-ntp yes
```
when 'set-ntp no', can set time manually
```
sudo timedatectl set-time "2018-6-18 18:10:40"
sudo timedatectl set-time "2018-02-04"
```

## SSH quick connect
/* setup */
```vim ~/.ssh/config```
```
Host short-name
HostName domain-name
User username
Port 22
```
/* How to use? */
```ssh <short-name>```


## SSH keygen
```
ssh-keygen -t rsa                                 # generate rsa publish key to ~/.ssh/id_rsa.pub
ssh-copy-id -i .ssh/id_rsa.pub hostname           # recommend
(optional):scp id_rsa.pub server_hostname:~/.ssh  # (擇一)缺點, 機器沒有.ssh目錄時，會有問題
```
you can copy the id_rsa.pub(content) to target server you want to login without keying password
ex: github -> setting -> SSH and GPG keys -> NEW SSH key -> paste your key -> done!
you don't need to keyin password when git clone,push,pull or ssh login.

## tar
```
tar -jcv -f filename.tar.bz2    # zip 要被壓縮的檔案或目錄名稱
tar -jxv -f filename.tar.bz2 -C # unzip 欲解壓縮的目錄
```
## ZIP
```
zip -r filename.zip folder/
unzip filename.zip
```

## Editor
#### vim .vimrc theme***
0. download theme from my github
1. mkdir ~/.vim/colors
2. vim ~/.vimrc
    syntax enable
    colorscheme monokai
3:finish

#### sublime recommand plugins
* Alignment //自動註解
* SFTP // 遠端ftp
* TrailingSpace  // 儲存時順便清除多餘空白
    ```
    # (Preferences > Package Settings > Trailing Spaces > Settings - User)
    {
        "trailing_spaces_trim_on_save": true #儲存時清除
    }
    ```
* macbook 外接鍵盤 Home/End 回到句首句尾
```Preferences > Key Bindings - User```
    ```
    { "keys": ["home"], "command": "move_to", "args": {"to": "bol"} },
    { "keys": ["end"], "command": "move_to", "args": {"to": "eol"} },
    { "keys": ["shift+end"], "command": "move_to", "args": {"to": "eol", "extend": true} },
    { "keys": ["shift+home"], "command": "move_to", "args": {"to": "bol", "extend": true } }
    ```


## gdb usage
1. when going to compile ,add '-g'
2. gdb xxxxxxx

(enter gdb)
* l : show the code
* b <line_number> : set breakpoint at a line
* n : next line ,only one line
* r [argv]: run program, can add parameters you need
* p <var> : print var
* q : quit
* display <var> : show var ,every 'next line'
* info break,display : can see the breakpoint or display status
* disable /enable break <num> : disable or enable some breakpoint ,no num mean 'all'
* delete break <num> : no longer need the breakpoint ,you can delete ,no num mean 'all' too
* step : like next , but this command will enter the function.


## time
```time <command>```
real time 表示後面所接的指令或程式從開始執行到結束終止所需要的時間。
user CPU time 表示程式在 user mode 所佔用的 CPU 時間總和。多核心的 CPU 或多顆 CPU 計算時，則必須將每一個核心或每一顆 CPU 的時間加總起來。
system CPU time 表示程式在 kernel mode 所佔用的 CPU 時間總和。


## iperf3
server端: ```iperf3 -s```
client端: ```iperf3 -c 192.168.0.1```
client example :
```
iperf –c 192.168.0.1 –w 100M –t 120 –i 10
#-c server端IP
#-w 測試檔案的大小
#-t 測試多久
#-i 每隔幾秒顯示一次
```

## apt-get remove
* ```sudo apt-get purge texlive-full <package name>``` or ```sudo apt-get autoremove --purge```  
* ```dpkg -l | grep ^rc``` : 列出沒清乾淨的package  
* ```sudo apt-get purge `dpkg -l | grep ^rc | awk '{ print $2 }'` ``` : 清除清單上的package  

有時候沒辦法update的時候
```
sudo apt-get dist-upgrade
sudo apt-get update
sudo apt-get upgrade
```
## git
#### git, push an existing repository from the command line
```git remote add origin <url>```
```git push -u origin master```


#### git remote set-url origin
after git clone, don't need to key in username and password everytime when git push
ex: ```git remote set-url origin git@github.com:gusony/my_learning_log.git```

#### git reset
```
git reset <版本號>:回到某個commit之後的狀態，但檔案還是新的
git checkout -f ：把檔案恢復到該commit 的狀態
git checkout <commit id> <file> : 把某個檔案回復到某個版本
git checkout HEAD <file>
```

## homebrew
```
brew install [Formula]
brew uninstall [Formula]
brew update       (like apt-get update)
brew upgrade      (like apt-get upgrade)
brew doctor       (check the brew system)
brew cleanup      (clean garbage)
brew info [Formula]
brew list
```

*** nohup ***
nohup 指令可以在系統登出後繼續執行
通常指令最後會在一個‘＆’ 在背景執行
nohup your_command & //會自動把結果輸出到nohup.txt
nohup your_command &>myout.txt &  //可以把結果導到myout.txt

*** linux serial port ***
dmesg | grep tty

## tmux
tmux server > session > windows > pane
下面狀態列的[x] 是第x個session
[]右側的是window

#### pane
```
%   :水平分割
"   :垂直分割
方向鍵 :移動pane
x   :關閉目前pane
```
#### window
```
c   :new window
&   :close current window
p   :last window
n   :next windwo
```
#### session
```
tmux    :new session
tmux ls :list all session
d   :exit tmux temporarily
s   :switch session
tmux attach -t 0    :enter 0 session
tmux kill-session -t 0  :close 0 session
```
## screen
```screen -參數```
```
-L ：開啟自動記錄功能
-ls :列出所有執行中的screen環境
-r  : 重新連接執行中的screen環境
-wipe:將廢棄的screen環境清除
```
```前綴鍵 Ctrl+a```
```
c : create new screen window
n : next screen window
p : previous screen window
# : 0~9的數字 直接跳到該window
k : close current window
w : list all window
d : exit screen
S : 分隔成上下畫面
Q : 關閉分割畫面
Tab:切換分割畫面
A : rename window's name
```

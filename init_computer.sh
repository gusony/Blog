echo "[apt] install start"
./env-setup/install_apt.sh

echo "[p3 venv]"
python3 -m venv ~/myvenv

echo "[config] Copy bash_profile"
cp -r ./config/vim ~/.vim
mv ~/.vim/vimrc ~/.vimrc

echo "[config] Copy tmux.conf"
cp ./configs/tmux.conf ~/.tmux.conf

echo "[config] Copy bash_profile"
cp ./configs/bash_profile ~/.bash_profile

echo "[config] Copy gitconfig"
cp ./config/gitconfig ~/.gitconfig

echo "[config] Copy SSH config"
if [ ! -d "~/.ssh" ]; then
    mkdir ~/.ssh
fi
cp ./config/ssh_config ~/.ssh/config
ssh-keygen -t rsa



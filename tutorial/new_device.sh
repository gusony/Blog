sudo su
./apt/install-apt-package-list.sh
cp ../config/tmux.conf ~/.tmux.conf
mkdir ~/.vim
mkdir ~/.vim/colors
cp -r ../config/vim/colors/* ~/.vim/colors
cp ../config/vim/vimrc ~/.vimrc
cp ../config/bash_profile ~/.bash_profile
echo -ne '\n' | echo -ne '\n' | ssh-keygen -t rsa  

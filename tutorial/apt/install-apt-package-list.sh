sudo apt upgrade -y 
xargs -a apt_packages.txt sudo apt install -y
sudo apt autoremove -y 

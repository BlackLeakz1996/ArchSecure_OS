#!/bin/bash
# livecd-builder.sh

echo "Livecd builder started...."


sudo pacman -S make squashfs-tools libisoburn dosfstools patch lynx devtools git
cd ~
sudo git clone git://projects.archlinux.org/archiso.git && cd archiso;
sudo make install && cd .. && rm -rf archiso;
cd ~
usr=$(whoami)
sudo chmod 777 -R ./*
sudo chown -hR $usr ./*
mkdir livecd

read -p "Enter baseline for minimal install (1) or rleng for full install: " nr
case $nr in
  [1]* ) sudo cp -r /usr/share/archiso/configs/baseline/* ~/livecd && cd ~/livecd; continue;;
  [2]* ) sudo cp -r /usr/share/archiso/configs/releng/* ~/livecd && cd ~/livecd; continue;;
  * ) echo -n "invalid input"; continue;;
esac

cd ~/livecd

read -p "Building packages from pacman application list? Pacman -Qe* ; (Yy/Nn): " yn
case $yn in
  [yY]* ) echo "using current packages" && sudo pacman -Qe && sudo pacman -Qqe > packages.x86_64; continue;;
  [Nn]* ) echo "configure packages manual!!!"; continue;;
  * ) echo -n "invalid input"; continue;;
esac

sudo chown root -hR ~/livecd;
echo -n "Copying configurations and other files..."
sudo mkdir ~/livecd/airootfs/etc/iptables
sudo cp /etc/iptables/iptables.rules ~/livecd/airootfs/etc/iptables/

sudo mkdir -p ~/livecd/airootfs/usr/share/fonts
sudo cp -r /usr/share/fonts/* ~/livecd/airootfs/usr/share/fonts/

sudo mkdir -p ~/livecd/airootfs/usr/share/backgrounds
sudo cp /usr/share/backgrounds/* ~/livecd/airootfs/usr/share/backgrounds

sudo mkdir -p ~/livecd/airootfs/usr/share/xfce4
sudo cp /usr/share/backgrounds/* ~/livecd/airootfs/usr/share/xfce4

echo "Creating user enviroment"

sudo mkdir -p ~/livecd/airootfs/home/archsecure
sudo cp /home/black/.gtkrc-2.0 ~/livecd/airootfs/home/archsecure/
sudo cp -r /home/black/.themes ~/livecd/airootfs/home/archsecure/

sudo mkdir ~/livecd/airootfs/etc/xdg/xfce4/xinitrc
sudo cp -r ~/.config/xfce4/xfconf/xfce-perchannel-xml/* ~/livecd/airootfs/etc/xdg/xfce4/xinitrc

sudo mkdir ~/livecd/airootfs/etc/skel/
sudo cp /etc/skel/.bash_profile/* ~/livecd/airootfs/etc/skel/.bash_profile

cd ~/livecd
sudo chmod 777 ~/Livecd
echo "Building now the ISO file..."
./build.sh -v
echo "Done."

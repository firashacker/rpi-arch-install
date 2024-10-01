#!/bin/bash
TIMEZONE="Asia/Jerusalem"
cd "$( dirname "${BASH_SOURCE[0]}")"
cd "$( dirname "${BASH_SOURCE[0]}")"
cd tmp
declare curdir="$(pwd)"
echo $curdir 
if [[ "$(whoami)" != "root" ]];then
  echo "Please run as root"
  exit
fi
 


if [[ ! -f /usr/bin/qemu-arm-static ]];then
  if [[ ! -f "$(which pacman)" ]];then
    echo -e "\e[31mErr: please install qemu-user-static then try runing\e[0m 'sudo ./post_install.sh'"
    exit
  fi
  pacman -S qemu-user-static
fi
if [[ ! -f $(which arch-chroot) ]];then
  if [[ ! -f "$(which pacman)" ]];then
    echo -e "\e[31mErr: couldn't install arch-install-scripts\e[0m"
    exit
  fi
  pacman -S arch-install-scripts
fi


setChroot(){
  echo -e "\e[32mSetting Up Chroot ! \e[0m"
  cp /usr/bin/qemu-arm-static root/usr/bin
  echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:' > /proc/sys/fs/binfmt_misc/register
  mount -B boot root/boot
  #mount -t proc /proc root/proc
  #mount -o bind /dev root/dev
  #mount -o bind /dev/pts root/dev/pts
  #mount -o bind /sys root/sys
}

cleanMess(){
  echo -e "\e[32mCleaning Up ! \e[0m"
  umount root/boot
  #umount  root/proc
  #umount  root/dev
  #umount  root/dev/pts
  #umount  root/sys
}



setConsole(){
  echo -e "\e[32mSetting Up Console ! \e[0m"
  echo "KEYMAP=us" > root/etc/console.conf
#  echo "FONTSIZE=28x14" >> root/etc/console.conf
}

setLocales(){
  echo -e "\e[32mSetting Up Locales ! \e[0m"
  echo "LANG=en_US.UTF-8" > root/etc/locale.conf
  sed -i "s/#\(en_US\.UTF-8\)/\1/" root/etc/locale.gen
  ln -s /usr/share/zoneinfo/${TIMEZONE} root/etc/localtime
  #chroot root locale-gen
  arch-chroot root locale-gen
  #chroot root timedatectl set-timezone ${TIMEZONE}
  arch-chroot root timedatectl set-timezone ${TIMEZONE}
}

setKeyring(){
  echo -e "\e[32mInitializing Keyring ! \e[0m"
  #chroot root pacman-key --init
  arch-chroot root pacman-key --init
  #chroot root pacman-key --populate archlinuxarm
  arch-chroot root pacman-key --populate archlinuxarm
}

setUpdate(){
  setKeyring
  rm root/etc/resolv.conf
  echo "nameserver 8.8.8.8" > root/etc/resolv.conf
  #chroot root pacman -Syu
  arch-chroot root pacman -Syu
}

setWifi(){
  echo -e "\e[32mSetting Up Network ! \e[0m"
  echo "Please Enter Wifi Network Name:"
  read SSID
  echo "please Enter Wifi Network Password:"
  read WIFIPASS

  echo "[Match]" > root/etc/systemd/network/wlan0.network
  echo "Name=wlan0" >> root/etc/systemd/network/wlan0.network
  echo "[Network]"  >> root/etc/systemd/network/wlan0.network
  echo "Description=On-board wireless NIC"  >> root/etc/systemd/network/wlan0.network
  echo "DHCP=yes"  >> root/etc/systemd/network/wlan0.network

  echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel" > root/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  echo "network={" >> root/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  echo "     ssid=\"${SSID}\"" >> root/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  echo "     scan_ssid=1" >> root/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  echo "     key_mgmt=WPA-PSK" >> root/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  echo "     psk=\"${WIFIPASS}\"" >> root/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  echo "}" >> root/etc/wpa_supplicant/wpa_supplicant-wlan0.conf

  #chroot root systemctl enable wpa_supplicant@wlan0.service
  arch-chroot root systemctl enable wpa_supplicant@wlan0.service
}



setBootOptions(){
  echo -e "\e[32mAppending Boot Options ! \e[0m"
  sed -i "s/dtoverlay=vc4-kms-v3d\ninitramfs /disable_overscan=1\ninitramfs /g" boot/config.txt
}

setXserver(){
  echo -e "\e[32mSetting Up X11 ! \e[0m"
  #chroot root pacman -Syu
  arch-chroot root pacman -Syu
  #chroot root pacman -S accountsservice xf86-video-fbdev xorg-server xorg-xrefresh
  arch-chroot root pacman -S accountsservice xf86-video-fbdev xorg-server xorg-xrefresh

  echo "allowed_users=anybody" > root/etc/X11/Xwrapper.config
  echo "needs_root_rights=yes" >> root/etc/X11/Xwrapper.config

  echo "xset s off" > root/etc/X11/xinit/xinitrc
  echo "xset -dpms" >> root/etc/X11/xinit/xinitrc
  echo "xset s noblank" >> root/etc/X11/xinit/xinitrc
#  cp root/etc/X11/xinit/xinitrc root/home/${User}/.xinitrc
  cp root/etc/X11/xinit/xinitrc root/home/alarm/.xinitrc
  cp root/etc/X11/xinit/xinitrc root/etc/skel/.xinitrc
}

setXFCE(){
  echo -e "\e[32mInstalling xfce4 ! \e[0m"
  #chroot root pacman -S xfce4 xfce4-goodies sddm
  arch-chroot root pacman -S xfce4 xfce4-goodies sddm
  #chroot root sddm --example-config > root/etc/sddm.conf
  arch-chroot root sddm --example-config > root/etc/sddm.conf
}

setUser(){
  echo -e "\e[32mSetting Up User ! \e[0m"
  echo "please enter user name:"
  read User
  #chroot root useradd -m -G wheel  ${User} --home /home/${User}
  arch-chroot root useradd -m -G wheel  ${User} --home /home/${User}
  #chroot root pacman -Sy sudo
  arch-chroot root pacman -Sy sudo
  #chroot root passwd ${User}
  arch-chroot root passwd ${User}
  sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL:ALL)\s\+ALL\)/\1/' root/etc/sudoers
  usermod -aG video,tty,audio ${User}
  echo "[Autologin]" >> root/etc/sddm.conf
  echo "User=${User}" >> root/etc/sddm.conf
}

#Always First
setChroot

setConsole

setLocales

setUpdate

setWifi

setXserver

setXFCE

setUser

setBootOptions

cleanMess

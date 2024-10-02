#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}")"
declare BASEDIR="$(pwd)"

if [[ "$(whoami)" != "root" ]];then
  echo "Please run as root"
  exit
fi
  
mkdir -p tmp
cp ./post_install.sh ./tmp
cd tmp
declare curdir="$(pwd)"
echo $curdir 



umount boot
umount root

download(){
echo -e "\e[32mDownloading System Image !\e[0m"
wget  -c http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz
}

getInput(){
lsblk
echo "please enter disk name [ex: sdb]:"
read PART

if [[ ! -e /dev/${PART} ]];then
  echo -e "\e[31mErr: invalid Disk PART !\e[0m"
  exit -2
fi
echo "are you sure your disk is /dev/${PART} [y/N]?"
read x
while [[ $x != 'y' ]] && [[ $x != 'Y' ]] && [[ $x != "n" ]] && [[ $x != "N" ]];do
echo -e "\e[31mErr: Invalid Input ! \e[0m"
echo "Try Again :"
read x
done

if [ $x != "y" ] && [ $x != "Y" ];then
  echo -e  "\e[31mErr: quit by User !\e[0m"
  exit -1
fi
#return PART
}

partition() {
echo "partition the filesystem [y/N]?"

read xx
while [[ $xx != 'y' ]] && [[ $xx != 'Y' ]] && [[ $xx != "n" ]] && [[ $xx != "N" ]];do 
echo -e "\e[31mErr: Invalid Input ! \e[0m"
echo "Try Again :"
read xx
done


if [ $xx != "y" ] && [ $xx != "Y" ];then
  echo -e  "\e[31mWarning: didn't partition the disk !\e[0m"
  return 0
fi

echo -e "\e[32mdisk partition tsarted ! for disk /dev/${PART}\e[0m"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/${PART}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +200M # 100 MB boot parttion
  t # set partition type
  c # to Fat 32
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  w # write partition table
  q # exit
EOF
}

format(){
echo "format the filesystem [y/N]?"
read xxx
while [[ $xxx != 'y' ]] && [[ $xxx != 'Y' ]] && [[ $xxx != "n" ]] && [[ $xxx != "N" ]];do 
echo -e "\e[31mErr: Invalid Input ! \e[0m"
echo "Try Again :"
read xxx
done

if [ $xxx != "y" ] && [ $xxx != "Y" ];then
  echo -e  "\e[31mWarning: didn't format the disk !\e[0m"
  return 0
fi
echo -e "\e[32mformatting Boot partition !\e[0m"
mkfs.vfat /dev/${PART}1

echo -e "\e[32mformatting Root partition !\e[0m"
mkfs.ext4 /dev/${PART}2
}

mountfs(){
echo -e "\e[32mmounting filesystem ! \e[0m "
mkdir -p boot root
mount /dev/${PART}1 boot
mount /dev/${PART}2 root
}

extract(){
echo -e "\e[32mextracting archlinux !\e[0m"
tar -xpf ArchLinuxARM-rpi-armv7-latest.tar.gz -C root > extraction.log
sync
mv root/boot/* boot
}

postInstall(){
  ${BASEDIR}/post_install.sh
}

clean(){
echo -e "\e[32mCleaning up !\e[0m"
sync
umount boot root
}

download
getInput
partition
format
mountfs
extract
postInstall
clean

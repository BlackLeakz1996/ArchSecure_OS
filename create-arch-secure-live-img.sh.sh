#!/bin/bash
# create-arch-secure-live-img.sh


echo "Autogen Live-Iso"
echo "Exporting some important folder-paths"
export WORK=~/work
export CD=~/cd
export FORMAT=squashfs
export FS_DIR=casper

sudo mkdir -p ${CD}/{${FS_DIR},boot/grub} ${WORK}/rootfs
sudo rsync -av --one-file-system --exclude=/proc/* --exclude=/dev/* \
--exclude=/sys/* --exclude=/tmp/* --exclude=/home/* --exclude=/lost+found \
--exclude=/var/tmp/* --exclude=/boot/grub/* --exclude=/root/* \
--exclude=/var/mail/* --exclude=/var/spool/* --exclude=/media/* \
--exclude=/etc/fstab --exclude=/etc/mtab --exclude=/etc/hosts \
--exclude=/etc/timezone --exclude=/etc/shadow* --exclude=/etc/gshadow* \
--exclude=/etc/X11/xorg.conf* --exclude=/etc/gdm/custom.conf \
--exclude=/etc/lightdm/lightdm.conf --exclude=${WORK}/rootfs / ${WORK}/rootfs
sudo cp -av /boot/* ${WORK}/rootfs/boot
CONFIG='.config .bashrc'
cd ~ && for i in $CONFIG
do
sudo cp -rpv --parents $i ${WORK}/rootfs/etc/skel
done
echo "chrooting into new live-sys"
sudo mount  --bind /dev/ ${WORK}/rootfs/dev

sudo mount -t proc proc ${WORK}/rootfs/proc

sudo mount -t sysfs sysfs ${WORK}/rootfs/sys

sudo mount -o bind /run ${WORK}/rootfs/run

sudo chroot ${WORK}/rootfs /bin/bash
echo "4 example de_DE.UTF-8"
read -p "LANG=" lang
sudo pacman -Syu
sudo pacman -S casper lupin-casper
sudo pacman -S ubiquity ubiquity-frontend-gtk
sudo pacman -S ubiquity ubiquity-frontend-kde
sudo pacman -S gparted ms-sys testdisk wipe partimage xfsprogs reiserfsprogs jfsutils ntfs-3g ntfsprogs dosfstools mtools
depmod -a $(uname -r)
update-initramfs -u -k $(uname -r)
for i in `cat /etc/passwd | awk -F":" '{print $1}'`
do
        uid=`cat /etc/passwd | grep "^${i}:" | awk -F":" '{print $3}'`
        [ "$uid" -gt "998" -a  "$uid" -ne "65534"  ] && userdel --force ${i} 2> /dev/null
done
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
find /var/log -type f | while read file
do
        cat /dev/null | tee $file
done
rm /etc/resolv.conf /etc/hostname
exit
echo "Prepare The CD directory tree"
export kversion=`cd ${WORK}/rootfs/boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`

sudo cp -vp ${WORK}/rootfs/boot/vmlinuz-${kversion} ${CD}/${FS_DIR}/vmlinuz

sudo cp -vp ${WORK}/rootfs/boot/initrd.img-${kversion} ${CD}/${FS_DIR}/initrd.img

sudo cp -vp ${WORK}/rootfs/boot/memtest86+.bin ${CD}/boot
sudo chroot ${WORK}/rootfs dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee ${CD}/${FS_DIR}/filesystem.manifest

sudo cp -v ${CD}/${FS_DIR}/filesystem.manifest{,-desktop}
REMOVE='ubiquity casper user-setup os-prober libdebian-installer4'
for i in $REMOVE
do
        sudo sed -i "/${i}/d" ${CD}/${FS_DIR}/filesystem.manifest-desktop
done
echo "Unmount bind mounted dirs: "
sudo umount ${WORK}/rootfs/proc

sudo umount ${WORK}/rootfs/sys

sudo umount ${WORK}/rootfs/dev
sudo mksquashfs ${WORK}/rootfs ${CD}/${FS_DIR}/filesystem.${FORMAT} -noappend
echo -n $(sudo du -s --block-size=1 ${WORK}/rootfs | tail -1 | awk '{print $1}') | sudo tee ${CD}/${FS_DIR}/filesystem.size
find ${CD} -type f -print0 | xargs -0 md5sum | sed "s@${CD}@.@" | grep -v md5sum.txt | sudo tee -a ${CD}/md5sum.txt
sudo gedit ${CD}/boot/grub/grub.cfg
echo "set default="0"
set timeout=10

menuentry "Ubuntu GUI" {
linux /casper/vmlinuz boot=casper quiet splash
initrd /casper/initrd.img
}

menuentry "Ubuntu in safe mode" {
linux /casper/vmlinuz boot=casper xforcevesa quiet splash
initrd /casper/initrd.img
}

menuentry "Ubuntu CLI" {
linux /casper/vmlinuz boot=casper textonly quiet splash
initrd /casper/initrd.img
}

menuentry "Ubuntu GUI persistent mode" {
linux /casper/vmlinuz boot=casper persistent quiet splash
initrd /casper/initrd.img
}

menuentry "Ubuntu GUI from RAM" {
linux /casper/vmlinuz boot=casper toram quiet splash
initrd /casper/initrd.img
}

menuentry "Check Disk for Defects" {
linux /casper/vmlinuz boot=casper integrity-check quiet splash
initrd /casper/initrd.img
}

menuentry "Memory Test" {
linux16 /boot/memtest86+.bin
}

menuentry "Boot from the first hard disk" {
set root=(hd0)
chainloader +1
}" > ${CD}/boot/grub/grub.cfg
sudo grub-mkrescue -o ~/live-cd.iso ${CD}
qemu -cdrom ~/live-cd.iso -boot d
[ -d "$WORK" ] && rm -r $WORK $CD
sudo blkid
break;
continue;
read -p "enter dev by uuid:~$ " uuid
sudo mount -t vfat /dev/by-uuid/$uuid /mnt
sudo blkid
sudo fdisk -l
read -p "dev:~$" devv
sudo grub-install --no-floppy --force --root-directory=/mnt /dev/$devv
cp -v ~/live-cd.iso /mnt
sudo gedit /mnt/boot/grub/grub.cfg
echo "set default="0"
set timeout=10

insmod ntfs
search --no-floppy --fs-uuid <insert the UUID> --set=usb
set iso_path=/live-cd.iso
loopback loop (${usb})${iso_path}
set root=(loop)
set bootopts="boot=casper iso-scan/filename=${iso_path} noprompt"

menuentry "Boot ISO from HDD/USB" {
linux (loop)/casper/vmlinuz $bootopts
initrd (loop)/casper/initrd.img
}" > /mnt/boot/grub/grub.cfg
search --no-floppy -l $uuid --set=usb
echo "done"

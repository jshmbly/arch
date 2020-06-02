#!/bin/bash
#
# Lime Arch Installer - UEFI
# Revision: 4.7 -- by 
# (GNU/General Public License version 3.0)
#
#
#
# ---------------------------------------
# Define Functions:
# ---------------------------------------
#
#
handlerr () {
  clear
  set -uo pipefail
  trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
  clear
}
#
#
welcome () {
  clear
  echo "==================================================="
  echo "=                                                 ="
  echo "=     Welcome to the Arch Installer Script        ="
  echo "=                                                 ="
  echo "=     UEFI Lime Edition                           ="
  echo "=     Version 4.7  (Development)                  ="
  echo "=                                                 ="
  echo "=                                                 ="
  echo "=     ----------------------------------------    ="
  echo "=                                                 ="
  echo -e "=================================================== \n"
  sleep 4
}
#
#
hrdclck () {
  clear
  timedatectl set-ntp true
  MYTMZ="$(curl -s https://ipapi.co/timezone)"
}
#
#
localestg () {
  clear
  LCLGET1=$(curl -s https://ipapi.co/languages | head -c 2)
  LCLGET2=$(curl -s https://ipapi.co/country | head -c 2)
  LCLST="${LCLGET1}"_"${LCLGET2}"
}
#
#
usrname () { 
  clear
  echo -e "\n"
  read -p "Type your user name, be exact, and press Enter: " USRNAME
  [[ -z "$USRNAME" ]] && usrname
  clear
  echo -e "\n"
  echo "User name set to "${USRNAME}"..."
  sleep 2
  clear
}
#
#
usrpwd () { 
  clear
  echo -e "\n"
  read -p "Type your user password, be exact, and press Enter: " USRPWD
  [[ -z "$USRPWD" ]] && usrpwd
  clear
  echo -e "\n"
  echo "User password set to "${USRPWD}"..."
  sleep 2
  clear
}
#
#
rtpwd () { 
  clear
  echo -e "\n"
  read -p "Type your root password, be exact, and press Enter: " RTPWD
  [[ -z "$RTPWD" ]] && rtpwd
  clear
  echo -e "\n"
  echo "Root password set to "${RTPWD}"..."
  sleep 2
  clear
}
#
#
hstname () { 
  clear
  echo -e "\n"
  read -p "Type your hostname, be exact, and press Enter: " HSTNAME
  [[ -z "$HSTNAME" ]] && hstname
  clear
  echo -e "\n"
  echo "Hostname set to "${HSTNAME}"..."
  sleep 2
  clear
}
#
#
swapsize () {
  clear
  echo -e "\n"
  read -p "Pick Swap Partition Size (2G, 4G, or 8G): " SWPSIZE
  case $SWPSIZE in
    2|2G|2g)
    SWPSIZE=2GiB
    ;;
    4|4G|4g)
    SWPSIZE=4GiB
    ;;
    8|8G|8g)
    SWPSIZE=8Gib
    ;;
    *)
    echo "Invalid input..."
    sleep 2
    unset SWPSIZE
    swapsize
    ;;
  esac
  clear
  echo -e "\n"
  echo "SWAP Partition Set To "${SWPSIZE}""
  sleep 2
  clear
}
#
#
rootsize () {
  clear
  echo -e "\n"
  read -p "Pick Root Partition Size (20G, 40G, or 468.4G): " RTSIZE
  case $RTSIZE in
    20|20G|20g)
    RTSIZE=20GiB
    ;;
    40|40G|40g)
    RTSIZE=40GiB
    ;;
    60|60G|60g)
    RTSIZE=468.4Gib
    ;;
    *)
    echo "Invalid input..."
    sleep 2
    unset RTSIZE
    rootsize
    ;;
  esac
  clear
  echo -e "\n"
  echo "Root Partition Set To "${RTSIZE}""
  sleep 2
  clear
}
#
#
trgtdrvsd () { 
  clear
  echo -e "Check to see the available drives: \n"
  /bin/lsblk
  echo -e "\n"
  read -p "Type your target device (e.g. sda), be exact, and press Enter: " TRGTDRV
  [[ -z "$TRGTDRV" ]] && trgtdrvsd
  clear
  echo -e "\n"
  echo "Target device set to "${TRGTDRV}"..."
  sleep 2
  clear
}
#
#
trgtdrvnv () { 
  clear
  echo -e "Check to see the available drives: \n"
  /bin/lsblk
  echo -e "\n"
  read -p "Type your target device (e.g. nvme0n1), be exact, and press Enter: " TRGTDRV
  [[ -z "$TRGTDRV" ]] && trgtdrvnv
  clear
  echo -e "\n"
  echo "Target device set to "${TRGTDRV}"..."
  sleep 2
  clear
}
#
#
optmirrors () {
  clear
  pacman -Syy
  pacman -Sy --noconfirm reflector
  reflector --latest 50 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
  clear
  echo -e "\n"
  echo "Mirrorlist optimized for 50 fastest..."
  sleep 2
  clear
}
#
#
mkpartsd () {
  clear
  wipefs -a -f /dev/"${TRGTDRV}"
  dd bs=512 if=/dev/zero of=/dev/"${TRGTDRV}" count=8192
  dd bs=512 if=/dev/zero of=/dev/"${TRGTDRV}" count=8192 seek=$((`blockdev --getsz /dev/"${TRGTDRV}"` - 8192))
  parted -s /dev/"${TRGTDRV}" mklabel gpt
  sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:efi /dev/"${TRGTDRV}"
  sgdisk -n 0:0:+"${SWPSIZE}" -t 0:8200 -c 0:swap /dev/"${TRGTDRV}"
  sgdisk -n 0:0:+"${RTSIZE}" -t 0:8300 -c 0:root /dev/"${TRGTDRV}"
  sgdisk -n 0:0:0 -t 0:8300 -c 0:home /dev/"${TRGTDRV}"
  clear
  echo -e "\n"
  echo "Partitions created..."
  sleep 2
  clear
}
#
#
frmtpartsd () {
  clear
  mkswap -L swap /dev/"${TRGTDRV}"\2
  mkfs.fat -F32 /dev/"${TRGTDRV}"\1
  mkfs.ext4 -L root /dev/"${TRGTDRV}"\3
  mkfs.ext4 -L home /dev/"${TRGTDRV}"\4
  clear
  echo -e "\n"
  echo "Partitions formatted..."
  sleep 2
  clear
}
#
#
mntpartsd () {
  clear
  mount /dev/"${TRGTDRV}"\3 /mnt
  mkdir /mnt/efi
  mount /dev/"${TRGTDRV}"\1 /mnt/efi
  mkdir /mnt/home
  mount /dev/"${TRGTDRV}"\4 /mnt/home
  swapon /dev/"${TRGTDRV}"\2
  clear
  echo -e "\n"
  echo "Mounted partitions..."
  sleep 2
  clear
}
#
#
mkpartnv () {
  clear
  wipefs -a -f /dev/"${TRGTDRV}"
  dd bs=512 if=/dev/zero of=/dev/"${TRGTDRV}" count=8192
  dd bs=512 if=/dev/zero of=/dev/"${TRGTDRV}" count=8192 seek=$((`blockdev --getsz /dev/"${TRGTDRV}"` - 8192))
  parted -s /dev/"${TRGTDRV}" mklabel gpt
  sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:efi /dev/"${TRGTDRV}"
  sgdisk -n 0:0:+"${SWPSIZE}" -t 0:8200 -c 0:swap /dev/"${TRGTDRV}"
  sgdisk -n 0:0:+"${RTSIZE}" -t 0:8300 -c 0:root /dev/"${TRGTDRV}"
  sgdisk -n 0:0:0 -t 0:8300 -c 0:home /dev/"${TRGTDRV}"
  clear
  echo -e "\n"
  echo "Partitions created..."
  sleep 2
  clear
}
#
#
frmtpartnv () {
  clear
  mkswap -L swap /dev/"${TRGTDRV}"\p2
  mkfs.fat -F32 /dev/"${TRGTDRV}"\p1
  mkfs.ext4 -L root /dev/"${TRGTDRV}"\p3
  mkfs.ext4 -L home /dev/"${TRGTDRV}"\p4
  clear
  echo -e "\n"
  echo "Partitions formatted..."
  sleep 2
  clear
}
#
#
mntpartnv () {
  clear
  mount /dev/"${TRGTDRV}"\p3 /mnt
  mkdir /mnt/efi
  mount /dev/"${TRGTDRV}"\p1 /mnt/efi
  mkdir /mnt/home
  mount /dev/"${TRGTDRV}"\p4 /mnt/home
  swapon /dev/"${TRGTDRV}"\p2
  clear
  echo -e "\n"
  echo "Mounted partitions..."
  sleep 2
  clear
}
#
#
psbase () {
  clear
  pacstrap /mnt base base-devel linux-lts linux-firmware sysfsutils e2fsprogs dosfstools mtools mkinitcpio dhcpcd inetutils netctl device-mapper cryptsetup gptfdisk nano less lvm2 dialog reflector
  clear
  echo -e "\n"
  echo "Pacstrap base system complete..."
  sleep 2
  clear
}
#
#
mkfstab () {
  clear
  genfstab -U /mnt >> /mnt/etc/fstab
  clear
}
#
#
syshstnm () {
  clear
  echo ""${HSTNAME}"" > /mnt/etc/hostname
  echo "127.0.0.1          localhost" >> /mnt/etc/hosts
  echo "::1          localhost" >> /mnt/etc/hosts
  echo "127.0.1.1          "${HSTNAME}".localdomain "${HSTNAME}"" >> /mnt/etc/hosts
  clear
}
#
#
syslocale () {
  clear
  echo ""${LCLST}".UTF-8 UTF-8" >> /mnt/etc/locale.gen
  echo "LANG="${LCLST}".UTF-8" > /mnt/etc/locale.conf
  arch-chroot /mnt locale-gen
  arch-chroot /mnt localectl set-locale LANG="${LCLST}".UTF-8
  clear
}
#
#
sysusrpwd () {
  clear
  arch-chroot /mnt useradd -mU -s /bin/bash -G sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel,adm "${USRNAME}"
  arch-chroot /mnt echo ""${USRNAME}":"${USRPWD}"" | chpasswd --root /mnt
  arch-chroot /mnt echo "root:"${RTPWD}"" | chpasswd --root /mnt
  clear
}
#
#
systmzone () {
  clear
  arch-chroot /mnt hwclock --systohc --utc
  arch-chroot /mnt timedatectl set-ntp true
  arch-chroot /mnt rm -rf /etc/localtime
  arch-chroot /mnt ln -sf /usr/share/zoneinfo/"${MYTMZ}" /etc/localtime
  clear
}
#
#
sysconfig () {
  clear
  echo -e "\n"
  echo "Basic system config completed..."
  sleep 2
  clear
}
#
#
instgrub () {
  clear
  arch-chroot /mnt pacman -Sy --noconfirm grub efibootmgr os-prober
  arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
  arch-chroot /mnt mkinitcpio -p linux-lts
  clear
  echo -e "\n"
  echo "Grub installed & mkinicpio run..."
  sleep 2
  clear
}
#
#
instxorg () {
  clear
  pacstrap /mnt xorg xorg-apps xorg-server xorg-drivers xorg-xkill xorg-xinit xterm mesa
  clear
  echo -e "\n"
  echo "Xorg installed installed..."
  sleep 2
  clear
}
#
#
instgen () {
  clear
  pacstrap /mnt linux-lts-headers dkms p7zip archiso haveged pacman-contrib pkgfile git diffutils usbutils jfsutils reiserfsprogs btrfs-progs f2fs-tools logrotate man-db man-pages mdadm perl s-nail texinfo which xfsprogs lsscsi sdparm sg3_utils smartmontools fuse2 fuse3 ntfs-3g exfat-utils gvfs gvfs-afc gvfs-goa gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb unrar unzip unace xz xdg-user-dirs grsync ddrescue dd_rescue testdisk hdparm htop rsync hardinfo bash-completion geany lsb-release polkit bleachbit packagekit gparted papirus-icon-theme
  sleep 2
  arch-chroot /mnt systemctl enable haveged.service
  clear
  echo -e "\n"
  echo "General packages installed..."
  sleep 2
  clear
}
#
#
instmedia () {
  clear
  pacstrap /mnt pulseaudio vlc simplescreenrecorder cdrtools gstreamer gst-libav gst-plugins-base gst-plugins-base-libs gst-plugins-good gst-plugins-bad gst-plugins-ugly gstreamer-vaapi gst-transcoder xvidcore frei0r-plugins cdrdao dvdauthor transcode alsa-utils alsa-plugins alsa-firmware pulseaudio-alsa pulseaudio-equalizer pulseaudio-jack ffmpeg ffmpegthumbnailer libdvdcss gimp guvcview imagemagick flac faad2 faac mjpegtools x265 x264 lame sox mencoder
  clear
  echo -e "\n"
  echo "Multimedia packages installed..."
  sleep 2
  clear
}
#
#
instnet () {
  clear
  pacstrap /mnt b43-fwcutter broadcom-wl-dkms intel-ucode ipw2100-fw ipw2200-fw net-tools networkmanager networkmanager-openvpn nm-connection-editor network-manager-applet wget curl firefox thunderbird wireless_tools nfs-utils nilfs-utils dhclient dnsmasq dmraid dnsutils openvpn openssh openssl samba whois iwd filezilla avahi openresolv youtube-dl vsftpd wpa_supplicant
  sleep 2
  arch-chroot /mnt systemctl enable NetworkManager
  clear
  echo -e "\n"
  echo "Networking packages installed..."
  sleep 2
  clear
}
#
#
instfonts () {
  clear
  pacstrap /mnt ttf-ubuntu-font-family ttf-dejavu ttf-bitstream-vera ttf-liberation noto-fonts ttf-roboto ttf-opensans opendesktop-fonts cantarell-fonts freetype2 
  clear
  echo -e "\n"
  echo "Fonts packages installed..."
  sleep 2
  clear
}
#
#
instprint () {
  clear
  pacstrap /mnt system-config-printer foomatic-db foomatic-db-engine gutenprint hplip simple-scan cups cups-pdf cups-filters cups-pk-helper ghostscript gsfonts python-pillow python-pyqt5 python-pip python-reportlab
  sleep 2
  arch-chroot /mnt systemctl enable org.cups.cupsd.service
  clear
  echo -e "\n"
  echo "Printing packages installed..."
  sleep 2
  clear
}
#
#
instlxqt () {
  clear
  pacstrap /mnt lxqt openbox obconf-qt pcmanfm-qt lxqt-sudo breeze-icons qterminal kwrite networkmanager-qt qbittorrent pavucontrol-qt quodlibet kdenlive k3b xarchiver galculator polkit-qt5 packagekit-qt5 xscreensaver sddm sddm-kcm
  sleep 2
  arch-chroot /mnt systemctl enable sddm
  clear
  echo -e "\n"
  echo "LXQt desktop installed..."
  sleep 2
  clear
}
#
#
instkde () {
  clear
  pacstrap /mnt plasma breeze-icons kwrite qbittorrent pavucontrol-qt quodlibet print-manager sweeper dolphin kdenlive k3b ark konsole gwenview okular kcalc packagekit-qt5 sddm sddm-kcm
  sleep 2
  arch-chroot /mnt systemctl enable sddm
  clear
  echo -e "\n"
  echo "KDE Plasma desktop installed..."
  sleep 2
  clear
}
#
#
instxfce () {
  clear
  pacstrap /mnt xfce4 xfce4-goodies galculator transmission-gtk pavucontrol xfburn asunder libburn libisofs libisoburn quodlibet xarchiver arc-gtk-theme arc-icon-theme gtk-engine-murrine adapta-gtk-theme polkit-gnome gnome-disk-utility gnome-packagekit catfish lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings accountsservice
  sleep 2
  arch-chroot /mnt systemctl enable lightdm
  clear
  echo -e "\n"
  echo "XFCE desktop installed..."
  sleep 2
  clear
}
#
#
instmate () {
  clear
  pacstrap /mnt mate mate-extra mate-applet-dock adapta-gtk-theme arc-gtk-theme arc-icon-theme gtk-engine-murrine transmission-gtk brasero asunder quodlibet gnome-disk-utility mate-polkit gnome-packagekit lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings accountsservice
  sleep 2
  arch-chroot /mnt systemctl enable lightdm
  clear
  echo -e "\n"
  echo "Mate desktop installed..."
  sleep 2
  clear
}
#
#
instcinn () {
  clear
  pacstrap /mnt cinnamon cinnamon-translations gnome-terminal adwaita-icon-theme adapta-gtk-theme arc-gtk-theme arc-icon-theme gtk-engine-murrine gnome-keyring nemo nemo-share xed file-roller nemo-fileroller tmux tldr transmission-gtk brasero asunder quodlibet gnome-disk-utility polkit-gnome gnome-packagekit evince viewnior lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings accountsservice
  sleep 2
  arch-chroot /mnt systemctl enable lightdm
  clear
  echo -e "\n"
  echo "Cinnamon desktop installed..."
  sleep 2
  clear
}
#
#
instgnome () {
  clear
  pacstrap /mnt gnome gdm accerciser dconf-editor ghex gnome-builder gnome-sound-recorder gnome-todo gnome-tweaks gnome-usage sysprof gnome-nettool chrome-gnome-shell gnome-shell-extensions adapta-gtk-theme arc-gtk-theme arc-icon-theme gtk-engine-murrine gnome-keyring transmission-gtk brasero asunder quodlibet gnome-disk-utility polkit-gnome gnome-packagekit evince
  sleep 2
  arch-chroot /mnt systemctl enable gdm.service
  clear
  echo -e "\n"
  echo "Gnome desktop installed..."
  sleep 2
  clear
}
#
#
invalid () {
  echo -e "\n"
  echo "Invalid answer, Please try again"
  sleep 2
}
#
#
make_upht () { while true
do
  clear
  echo "----------------------------------"
  echo " User, Passwords, & Hostname"
  echo "----------------------------------"
  echo ""
  echo "  1) Create user name"
  echo "  2) Make user password"
  echo "  3) Make root password"
  echo "  4) Make hostname"
  echo ""
  echo "  R) Return to menu"
  echo -e "\n"
  read -p "Please enter your choice: " choice2
  case $choice2 in
    1 ) usrname ;;
    2 ) usrpwd ;;
    3 ) rtpwd ;;
    4 ) hstname ;;
    r|R ) main_menu ;;
    * ) invalid ;;
  esac
done
}
#
#
sata_drv () { while true
do
  clear
  echo "--------------------------------"
  echo " Partition Drive"
  echo "--------------------------------"
  echo ""
  echo "  1) Enter device name (e.g.sda)"
  echo "  2) Choose Swap partition size"
  echo "  3) Choose Root partition size"
  echo "  4) Create partitions"
  echo "  5) Format partitions"
  echo "  6) Mount partitions"
  echo ""
  echo "  R) Return to menu"
  echo -e "\n"
  read -p "Please enter your choice: " choice3
  case $choice3 in
    1 ) trgtdrvsd ;;
    2 ) swapsize ;;
    3 ) rootsize ;;
    4 ) mkpartsd ;;
    5 ) frmtpartsd ;;
    6 ) mntpartsd ;;
    r|R ) main_menu ;;
    * ) invalid ;;
  esac
done
}
#
#
nvme_drv () { while true
do
  clear
  echo "--------------------------------"
  echo " Partition Drive"
  echo "--------------------------------"
  echo ""
  echo "  1) Enter device name (e.g.nvme0n1)"
  echo "  2) Choose Swap partition size"
  echo "  3) Choose Root partition size"
  echo "  4) Create partitions"
  echo "  5) Format partitions"
  echo "  6) Mount partitions"
  echo ""
  echo "  R) Return to menu"
  echo -e "\n"
  read -p "Please enter your choice: " choice4
  case $choice4 in
    1 ) trgtdrvnv ;;
    2 ) swapsize ;;
    3 ) rootsize ;;
    4 ) mkpartnv ;;
    5 ) frmtpartnv ;;
    6 ) mntpartnv ;;
    r|R ) main_menu ;;
    * ) invalid ;;
  esac
done
}
#
#
chdrvtype () { while true
do
  clear
  echo "-----------------------------------"
  echo " Choose SATA or NVME Disk"
  echo "-----------------------------------"
  echo ""
  echo "  1) SATA Disk"
  echo "  2) NVME Disk"
  echo ""
  echo "  R) Return to menu"
  echo -e "\n"
  read -p "Please enter your choice: " choice5
  case $choice5 in
    1 ) sata_drv ;;
    2 ) nvme_drv ;;
    r|R ) main_menu ;;
    * ) invalid ;;
  esac
done
}
#
#
inst_soft () { while true
do
  clear
  echo "--------------------------------"
  echo " Install Software Categories"
  echo "--------------------------------"
  echo ""
  echo "  1) Xorg"
  echo "  2) General"
  echo "  3) Multimedia"
  echo "  4) Networking"
  echo "  5) Fonts"
  echo "  6) Printing support"
  echo ""
  echo "  R) Return to menu"
  echo -e "\n"
  read -p "Please enter your choice: " choice6
  case $choice6 in
    1 ) instxorg ;;
    2 ) instgen ;;
    3 ) instmedia ;;
    4 ) instnet ;;
    5 ) instfonts ;;
    6 ) instprint ;;
    r|R ) main_menu ;;
    * ) invalid ;;
  esac
done
}
#
#
inst_desk () { while true
do
  clear
  echo "--------------------------------"
  echo " Choose A Desktop"
  echo "--------------------------------"
  echo ""
  echo "  1) LXQt"
  echo "  2) Plasma"
  echo "  3) XFCE"
  echo "  4) Mate"
  echo "  5) Cinnamon"
  echo "  6) Gnome"
  echo ""
  echo "  R) Return to menu"
  echo -e "\n"
  read -p "Please enter your choice: " choice7
  case $choice7 in
    1 ) instlxqt ;;
    2 ) instkde ;;
    3 ) instxfce ;;
    4 ) instmate ;;
    5 ) instcinn ;;
    6 ) instgnome ;;
    r|R ) main_menu ;;
    * ) invalid ;;
  esac
done
}
#
#
main_menu () { while true
do
  clear
  echo "-------------------------------------"
  echo " EZ Arch Installer - UEFI Systems"
  echo "-------------------------------------"
  echo ""
  echo "  1) Username, Passwords, & Hostname"
  echo "  2) Optimize Mirrorlist"
  echo "  3) Choose Device Type & Partition Drive"
  echo "  4) Install Base System (pacstrap)"
  echo "  5) Configure System Settings"
  echo "  6) Install Broad Categories of Software"
  echo "  7) Choose Desktop"
  echo "  8) Install GRUB"
  echo ""
  echo "  X) Exit"
  echo -e "\n"
  read -p "Enter your choice: " choice1
  case $choice1 in
    1 ) make_upht ;;
    2 ) optmirrors ;;
    3 ) chdrvtype ;;
    4 ) psbase ;;
    5 ) mkfstab; syshstnm; syslocale; sysusrpwd; systmzone; sysconfig ;;
    6 ) inst_soft ;;
    7 ) inst_desk ;;
    8 ) instgrub ;;
    x|X ) exit;;
    * ) invalid ;;
  esac
done
}
#
#
handlerr
welcome
hrdclck
localestg
main_menu
#
#
done
#
#
# Disclaimer:
#
# THIS SOFTWARE IS PROVIDED BY EZNIX “AS IS” AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL EZNIX BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# END
#

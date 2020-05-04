#!/bin/bash

## CONFIGURE THESE VARIABLES
## ALSO LOOK AT THE install_packages FUNCTION TO SEE WHAT IS ACTUALLY INSTALLED

# Is this computer a laptop? (TRUE/FALSE)
LAPTOP='FALSE'

# Computer Model ( e.g Thinkpad T420s )
MODEL=''

# Drive to install to (leave blank to be prompted).
DRIVE='/dev/sda'
PARTITION='FALSE'

# Hostname of the installed machine (leave blank to be prompted).
HOSTNAME='archbox'

# Encrypt everything (except /boot).  Leave blank to disable.
#ENCRYPT_DRIVE=''

# Passphrase used to encrypt the drive (leave blank to be prompted).
#DRIVE_PASSPHRASE=''

# Root password (leave blank to be prompted).
ROOT_PASSWORD='rootpass'

# Main user to create (by default, added to wheel group, and others). (leave blank to be prompted)
USER_NAME='justin'

# The main user's password (leave blank to be prompted).
USER_PASSWORD='password'

# System timezone.
TIMEZONE='US/Eastern'

KEYMAP='US'
# KEYMAP='dvorak'

LOCALE='en_US'

# Choose your video driver
# For Intel
#VIDEO_DRIVER=""
# For nVidia
#VIDEO_DRIVER="nouveau"
# For ATI
#VIDEO_DRIVER="radeon"
# For generic stuff
#VIDEO_DRIVER="vesa"

# Wireless device, leave blank to not use wireless and use DHCP instead.
WIRELESS_DEVICE=""
# For tc4200's
#WIRELESS_DEVICE="eth1"

# DETECT
if [ -d /sys/firmware/efi ]; then
        BOOT='UEFI'
        echo "UEFI Boot Detected"
        echo
    else
        BOOT=BIOS
        echo "BIOS Boot Detected"
        echo
    fi

if [ -z "$MODEL" ]; then
        set MODEL=$( cat /sys/devices/virtual/dmi/id/product_name )
        echo "Computer Model detected as: $MODEL"
        echo
    else
        echo "Computer Model detected as: $MODEL"
        echo
    fi

# MODEL Specific settings

if [ "$MODEL" == 'T420s' ]; then
        HOSTNAME='thinkpad-arch'
        WIRELESS_DEVICE='wlp3s0'
        KEYMAP='US'
        VIDEO_DRIVER='nvidia-390xx'
        LAPTOP='TRUE'
        MODEL_PACKAGES='bumblebee lib32-virtualgl lib32-nvidia-340xx-utils bbswitch'
    elif [ "$MODEL" == 'HP ZBook 14u G5' ]; then
        HOSTNAME='zbook-arch'
        WIRELESS_DEVICE='wlp3s0'
        KEYMAP='US'
        VIDEO_DRIVER='vulkan-intel'
        LAPTOP='TRUE'
        MODEL_PACKAGES='bolt'
    elif [ "$MODEL" == 'Z97X-UD5H-BK' ]; then
        HOSTNAME='phantom-arch'
        WIRELESS_DEVICE=''
        KEYMAP='US'
        VIDEO_DRIVER='nvidia'
        LAPTOP='TRUE'
        MODEL_PACKAGES=''
    fi


# PROMPT
if [ -z "$DRIVE" ]; then
        echo "Enter the drive to install ArchLinux to ( e.g. /dev/sda ):"
        lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'
        stty -echo
        read DRIVE
        stty echo
        echo "Installing to $DRIVE"
        echo
    else
        echo "Installing ArchLinux to $DRIVE"
        echo
    fi

if [ -z "$KEYMAP" ]; then
        echo "Enter the desired Keymap ( e.g. US ):"
        stty -echo 
        read KEYMAP
        stty echo
        echo "KEYMAP: $KEYMAP"
        echo
    else
        echo "KEYMAP: $KEYMAP"
        echo
    fi
    
if [ -z "$LAPTOP" ]; then
        echo "Is this computer a Laptop? (TRUE/FALSE)"
        stty -echo
        read LAPTOP
        stty echo
        echo "LAPTOP: $LAPTOP"
        echo
    else
        echo "LAPTOP: $LAPTOP"
        echo
    fi

if [ -z "$TIMEZONE" ]; then
        echo "Enter the desired Time Zone ( e.g. US/EASTERN ):"
        stty -echo
        read TIMEZONE
        stty echo
        echo "TIMEZONE: $TIMEZONE"
        echo
    else
        echo "TIMEZONE: $TIMEZONE"
        echo
    fi

if [ -z "$LOCALE" ]; then
        echo "Enter the desired locale ( e.g. en_US ):"
        stty -echo
        read LOCALE
        stty echo
        echo "LOCALE: $LOCALE"
        echo
    else
        echo "LOCALE: $LOCALE"
        echo
    fi

if [ -z "$HOSTNAME" ]; then
        echo "Enter the desired Hostname:"
        stty -echo
        read HOSTNAME
        stty echo
        echo "HOSTNAME: $HOSTNAME"
        echo
    else
        echo "HOSTNAME: $HOSTNAME"
        echo
    fi

if [ -z "$ROOT_PASSWORD" ]; then
        echo "Enter the root password:"
        stty -echo
        read ROOT_PASSWORD
        stty echo
        echo "ROOT_PASSWORD: $ROOT_PASSWORD"
        echo
    else
        echo "ROOT_PASSWORD: $ROOT_PASSWORD"
        echo
    fi

if [ -z "$USER_NAME" ]; then
        echo "Enter the desired Username:"
        stty -echo
        read USER_NAME
        stty echo
        echo "USER_NAME: $USER_NAME"
        echo
    else
        echo "USER_NAME: $USER_NAME"
        echo
    fi

if [ -z "$USER_PASSWORD" ]; then
        echo "Enter the users password:"
        stty -echo
        read USER_PASSWORD
        stty echo
        echo "USER_PASSWORD: $USER_PASSWORD"
        echo
    else
        echo "USER_PASSWORD: $USER_PASSWORD"
        echo
    fi

## BEGIN INSTALL
if [ ping -c5 unix.com &>/dev/null ]; then
        echo "Offline - Connect to the internet and restart"
        exit
    else
            echo "Online - Continuing with install"
    fi


mount -o remount,size=2G /run/archiso/cowspace

umount /mnt/boot
umount /mnt
swapoff /dev/lvm/arch-swap
vgchange -an
vgremove lvm

loadkeys $KEYMAP

echo "Setting NTP Time"
timedatectl set-ntp true

if [ $PARTITION = 'TRUE' ]; then
        # PARTITIONS
            # Create 512 MB /boot partition, 
        if [ $BOOT = 'UEFI' ]; then
                parted --script --align=optimal "$DRIVE" mklabel gpt mkpart primary fat32 1MiB 512MiB set 1 esp on
            else
                parted --script --align=optimal "$DRIVE" mklabel msdos mkpart primary ext2 1MiB 512MiB set 1 boot on
            fi
        
        parted --script --align=optimal "$DRIVE" mkpart primary ext4 512MiB 100%  && parted --script --align=optimal "$DRIVE" set 2 LVM on

        pvcreate "$DRIVE"2
        vgcreate "lvm" "$DRIVE"2

        # Create a 4GiB swap partition
        # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/storage_administration_guide/ch-swapspace#s1-swap-what-is
        lvcreate -C y -L 4GiB "lvm" -n arch-swap

        # Create a 30GiB root partition
        lvcreate -L 30GiB "lvm" -n arch-root

        # Use the rest of the space for home
        lvcreate -l '+100%FREE' "lvm" -n home

        # Enable the new volumes
        modprobe dm_mod
        vgscan
        vgchange -ay

        # Format the Partitions
        if [ $BOOT = 'UEFI' ]; then
                mkfs.fat -F 32 -L efi "$DRIVE"1
            else
                mkfs.ext4 -F 32 -L boot "$DRIVE"1
        fi
        mkswap -L arch-swap /dev/lvm/arch-swap
        mkfs.btrfs -L arch-root /dev/lvm/arch-root
        mkfs.btrfs -L home /dev/lvm/home
    fi

# Mount the filesystems
mkdir /mnt/boot
mount "$DRIVE"1 /mnt/boot
swapon /dev/lvm/arch-swap
mount /dev/lvm/arch-root /mnt
mount /dev/lvm/home /home

# Format the Partitions
if [ $BOOT = 'UEFI' ]; then
        mkfs.fat -F 32 -L efi "$DRIVE"1
    else
        mkfs.ext4 -F 32 -L boot "$DRIVE"1
    fi
mkswap -L swap /dev/lvm/arch-swap
mkfs.btrfs -L root /dev/lvm/arch-root
mkfs.btrfs -L home /dev/lvm/home

# Mount the filesystems
mkdir /mnt/boot
mount "$DRIVE"1 /mnt/boot
swapon /dev/lvm/arch-swap
mount /dev/lvm/arch-root /mnt
mount /dev/lvm/home /home
    
# Install Base Arch System
pacman -Syyu --noconfirm reflector
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base linux-headers base-devel btrfs-progs sudo grub efibootmgr dosfstools ntfsprogs os-prober git NetworkManager ifplugd dialog pacman-contrib
if [ -z "$WIRELESS_DEVICE"]; then
        pacstrap /mnt iwd
    fi

## CONFIGURE THE SYSTEM
    # Generate Fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # chroot into system
#    arch-chroot /mnt

    # Set the TimeZone
    #arch-chroot ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    ln -sf /usr/share/zoneinfo/$TIMEZONE /mnt/etc/localtime
    arch-chroot hwclock --systohc --localtime

    # Set the Locale
    echo 'LANG="'"$LOCALE".UTF-8'"' > /mnt/etc/locale.conf
    #arch-chroot sed -i 's/#\('${LOCALE_UTF8}'\)/\1/' /etc/locale.gen
    sed -i 's/#\('$LOCALE.UTF-8'\)/\1/' /mnt/etc/locale.gen
    arch-chroot locale-gen
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
    
    # Set the Hostname
    echo "$HOSTNAME" > /mnt/etc/hostname
    #arch-chroot sed -i '/127.0.0.1/s/$/ '{$HOSTNAME}'/' /etc/hosts
    sed -i '/127.0.0.1/s/$/ '{$HOSTNAME}'/' /mnt/etc/hosts
    #arch-chroot sed -i '/::1/s/$/ '{$HOSTNAME}'/' /etc/hosts
    sed -i '/::1/s/$/ '{$HOSTNAME}'/' /mnt/etc/hosts

    # Recreate initramfs
    #arch-chroot sed -i '/^HOOK/s/filesystems/sd-lvm2 filesystems/' /etc/mkinitcpio.conf
    sed -i 's/filesystems /sd-lvm2 filesystems /' /mnt/etc/mkinitcpio.conf
    sed -i 's/base udev /base systemd /' /mnt/etc/mkinitcpio.conf
    sed -i 's/base systemd /base systemd btrfs /' /mnt/etc/mkinitcpio.conf
    arch-chroot mkinitcpio -p linux

    # Set the root Password
    arch-chroot passwd $ROOT_PASSWORD

    # Create Bootloader
    arch-chroot grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    arch-chroot grub-mkconfig -o /boot/grub/grub.cfg

    # Enable Multilib Repo
    sed -i '/^#\[multilib]/{n;s/^#//}' /mnt/etc/pacman.conf
    sed -i 's/^#\[multilib]/[multilib]/' /mnt/etc/pacman.conf

    # Update repos
    arch-chroot pacman -Sy --noconfirm
    arch-chroot pacman -S --noconfirm reflector
    arch-chroot reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
    arch-chroot pacman -Syu --noconfirm

    # Install Intel or AMD Microcode
    [[ -n $( lscpu | grep GenuineIntel ) ]] && arch-chroot pacman -S --noconfirm intel-ucode
    [[ -n $( lscpu | grep AuthenticAMD ) ]] && arch-chroot pacman -S --noconfirm amd-ucode

    # Enable Networking
    arch-chroot systemctl enable NetworkManager.service
    if [ -z "$WIRELESS_DEVICE" ]; then
            arch-chroot systemctl enable iwd.service
            arch-chroot echo '[device]' > /etc/NetworkManager/conf.d/wifi_backend.conf
            arch-chroot echo \"wifi.backend=iwd\" >> /etc/NetworkManager/conf.d/wifi_backend.conf
        fi

    # Create User
    arch-chroot useradd -m -s /bin/bash -G adm,ftp,games,http,log,rfkill,sys,systemd-journal,users,uucp,wheel "$USER_NAME"
    arch-chroot echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd "$USER_NAME"

    # Add Wheel to Sudoers
    echo -e "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/99_wheel

    # Install Packages
        # Utilities
        arch-chroot pacman -S --noconfirm catfish unimatrix irssi curl fish aspell-en lsd gvim ntp openssh p7zip pkgfile python rfkill unrar unzip wget zip systemd-sysvcompat zsh grml-zsh-config apparmor vifm ranger vlc feh gpicview-gtk3 gimp cmus clementine handbrake handbrake-cli termite libreoffice-fresh hunspell hyphen-en mythes-en code neofetch libqalculate bleachbit
        arch-chroot systemctl enable apparmor.service

        # Video Drivers
        [[ -n $( lscpu | grep GenuineIntel ) ]] && arch-chroot pacman -S --noconfirm xf86-video-intel
        [[ -n $( lscpu | grep AuthenticAMD ) ]] && arch-chroot pacman -S --noconfirm xf86-video-amdgpu xf86-video-ati
        arch-chroot pacman -S --noconfirm mesa lib32-mesa $VIDEO_DRIVER

        # Model Specific Packages
        arch-chroot pacman -S --noconfirm $MODEL_PACKAGES

        # GUI
        arch-chroot pacman -S --noconfirm xorg
        arch-chroot pacman -S --noconfirm network-manager-applet nm-connection-editor qtile dmenu rofi budgie-desktop gnome dconf dconf-editor lightdm lightdm-gtk-greeter pavucontrol pasystray awesome-terminal-fonts xautolock i3lock scrot imagemagick compton galculator qalculate-gtk gnome-screenshot adapta-gtk-theme papirus-icon-theme
        arch-chroot pacman -R --noconfirm epiphany
        arch-chroot config_xinitrc "export XDG_CURRENT_DESKTOP=Budgie:GNOME \n budgie-desktop"
        arch-chroot systemctl enable lightdm.service

        # Internet
        arch-chroot pacman -S --noconfirm lynx firefox chromium qbittorrent neomutt geary newsboat feedreader

        # Games
        arch-chroot pacman -S --noconfirm steam lutris


        # Laptop Packages
        if [ $LAPTOP = 'TRUE' ]; then
                arch-chroot pacman -S --noconfirm tlp tlp-rdw
                arch-chroot systemctl enable tlp.service
                arch-chroot systemctl enable tlp-sleep.service
                arch-chroot systemctl enable NetworkManager-dispatcher.service
                arch-chroot systemctl mask systemd-rfkill.service
                arch-chroot systemctl mask systemd-rfkill.socket
            fi
        if [ $MODEL = 'T420s' ]; then
                echo -e "SATA_LINKPWR_ON_BAT=max_performance" >> /mnt/etc/default/tlp
            fi

        # Sound
        arch-chroot pacman -S --noconfirm alsa-utils alsa-plugins pulseaudio pulseaudio-alsa

    # install yay
#    arch-chroot cd /home/$USER_NAME
#    arch-chroot sudo -u $USER_NAME git clone https://aur.archlinux.org/yay.git
#    arch-chroot cd yay
#    arch-chroot sudo -u $USER_NAME makepkg -si
#
#    arch-chroot yay -Syy --noconfirm tlpui-git snapd etcher-bin vscodium-bin linux-steam-integration
#
#    arch-chroot sudo snap install pick-colour-picker snap-store
#
#    arch-chroot sudo -u $USER_NAME git clone https://github.com/vmavromatis/absolutely-proprietary.git
#
read -p "Press [Enter] key to reboot..."

    systemctl reboot
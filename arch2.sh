#!/bin/bash

echo -e HISTSIZE=-1 >> .bashrc
echo -e HISTFILESIZE=-1 >> .bashrc

## CONFIGURE THESE VARIABLES
## ALSO LOOK AT THE install_packages FUNCTION TO SEE WHAT IS ACTUALLY INSTALLED

# Is this computer a laptop? (TRUE/FALSE)
LAPTOP='FALSE'

# Computer Model ( e.g Thinkpad T420s )
MODEL=''

# Drive to install to (leave blank to be prompted).
DRIVE='/dev/sda'
PARTITION='FALSE'
LVM_VOL_GROUP='lvm' #Leave blank to disable
SWAP='arch-swap'
SWAP_SIZE='4' # in GiB
ROOT='arch-root'
ROOT_FS='btrfs'
ROOT_SIZE='30' # in GiB
HOME='home'
HOME_FS='ext4'
HOME_SIZE='100%FREE' # in GiB

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

KEYMAP='us'
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

echo -e "\e[34m\e[1mPrepping\e[0m"

# DETECT
if [ -d /sys/firmware/efi ]; then
        BOOT='efi'
        echo "UEFI Boot Detected"
        echo
    else
        BOOT=boot
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

if [ "$MODEL" = 'T420s' ]; then
        HOSTNAME='thinkpad-arch'
        WIRELESS_DEVICE='wlp3s0'
        KEYMAP='US'
        VIDEO_DRIVER='nvidia-390xx'
        LAPTOP='TRUE'
        MODEL_PACKAGES='bumblebee lib32-virtualgl lib32-nvidia-340xx-utils bbswitch'
    elif [ "$MODEL" = 'HP ZBook 14u G5' ]; then
        HOSTNAME='zbook-arch'
        WIRELESS_DEVICE='wlp3s0'
        KEYMAP='US'
        VIDEO_DRIVER='vulkan-intel'
        LAPTOP='TRUE'
        MODEL_PACKAGES='bolt'
    elif [ "$MODEL" = 'Z97X-UD5H-BK' ]; then
        HOSTNAME='phantom-arch'
        WIRELESS_DEVICE=''
        KEYMAP='US'
        VIDEO_DRIVER='nvidia'
        LAPTOP='TRUE'
        MODEL_PACKAGES='python-pip libappindicator-gtk3'
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

#umount -fq /mnt/boot
#umount -fq /mnt/efi
umount -fq /mnt
umount -fq /home
swapoff -a 
vgchange -an
vgremove -y -ff $LVM_VOL_GROUP
pvremove -y -ff "$DRIVE"2
pvremove -y -ff "$DRIVE"3
pvremove -y -ff "$DRIVE"4
wipefs --all --force $DRIVE
parted --script --align=optimal "$DRIVE" mklabel gpt
parted --script --align=optimal "$DRIVE" mklabel msdos

loadkeys $KEYMAP

echo "Setting NTP Time"
timedatectl set-ntp true

read -p "Press [Enter] key to Begin Partitioning..."
echo -e "\e[34m\e[1mPartitioning\e[0m"

if [ $PARTITION = 'TRUE' ]; then
    # PARTITIONS
    # Create 512 MB /boot partition, 
        if [ $BOOT = 'efi' ]; then
                parted --script --align=optimal "$DRIVE" mklabel gpt mkpart primary fat32 1MiB 512MiB set 1 esp on
            else
                parted --script --align=optimal "$DRIVE" mklabel msdos mkpart primary ext2 1MiB 512MiB set 1 boot on
        fi
        
        if [ -n "$LVM_VOL_GROUP" ]; then
                parted --script --align=optimal "$DRIVE" mkpart primary ext4 512MiB 100% set 2 LVM on
                
                pvcreate "$DRIVE"2
                vgcreate "$LVM_VOL_GROUP" "$DRIVE"2

                # Create a 4GiB swap partition
                # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/storage_administration_guide/ch-swapspace#s1-swap-what-is
                lvcreate -y -C y -L "$SWAP_SIZE"GiB "$LVM_VOL_GROUP" -n $SWAP

                # Create a 30GiB root partition
                lvcreate -y -L "$ROOT_SIZE"GiB "$LVM_VOL_GROUP" -n $ROOT

                # Use the rest of the space for home
                lvcreate -y -l "$HOME_SIZE" "$LVM_VOL_GROUP" -n $HOME

                # Enable the new volumes
                modprobe dm_mod
                vgscan
                vgchange -ay

                # Format the Partitions
                if [ $BOOT = 'efi' ]; then
                        mkfs.fat --force -F 32 -L $BOOT "$DRIVE"1
                    else
                        mkfs.ext4 -F -L $BOOT "$DRIVE"1
                fi
                mkswap -L $SWAP /dev/$LVM_VOL_GROUP/$SWAP
                mkfs.$ROOT_FS --force -L $ROOT /dev/$LVM_VOL_GROUP/$ROOT
                mkfs.$HOME_FS -F -L $HOME /dev/$LVM_VOL_GROUP/$HOME

            else
                parted --script --align=optimal "$DRIVE" mkpart primary ext4 512MiB "$SWAP_SIZE".5GiB mkpart primary "$ROOT_FS" "$SWAP_SIZE".5 "$( "$ROOT_SIZE" + $SWAP_SIZE.5 )" mkpart primary "$HOME_FS" "$( "$ROOT_SIZE" + "$SWAP_SIZE".5 )" "$HOME_SIZE"

                # Format the Partitions
                if [ $BOOT = 'efi' ]; then
                        mkfs.fat --force -F 32 -L $BOOT "$DRIVE"1
                    else
                        mkfs.ext4 -F -F 32 -L $BOOT "$DRIVE"1
                fi
                mkswap -L $SWAP "$DRIVE"2/$SWAP
                mkfs.$ROOT_FS --force -L $ROOT "$DRIVE"3/$ROOT
                mkfs.$HOME_FS -F -L $HOME "$DRIVE"4/$HOME

        fi

if [ -n "$LVM_VOL_GROUP" ]; then
        # Mount the filesystems
        swapon /dev/$LVM_VOL_GROUP/$SWAP
        mount /dev/$LVM_VOL_GROUP/$ROOT /mnt
        mount /dev/$LVM_VOL_GROUP/$HOME /home
        mkdir /mnt/$BOOT
        mount "$DRIVE"1 /mnt/$BOOT
    else
        # Mount the filesystems
        swapon "$DRIVE"2/$SWAP
        mount "$DRIVE"3/$ROOT /mnt
        mount "$DRIVE"4/$HOME /home
        mkdir /mnt/$BOOT
        mount "$DRIVE"1 /mnt/$BOOT
fi

read -p "Press [Enter] key to start Pacstrap..."
stty
echo -e "\e[34m\e[1mPacstrap\e[0m"

fi

# Install Base Arch System
pacman -Sy --noconfirm reflector
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

if [ -z "$WIRELESS_DEVICE"]; then
        PACSTRAP_WIRELESS='iwd'
fi
if [ $BOOT = 'efi' ]; then
        PACSTRAP_EFI='efibootmgr'
fi
if [ $ROOT_FS = 'btrfs' ]; then
        PACSTRAP_FS='btrfs-progs'
    elif [ $HOME_FS = 'btrfs' ]; then
        PACSTRAP_FS='btrfs-progs'
fi
pacstrap /mnt base base-devel linux-headers sudo grub dosfstools ntfsprogs os-prober git networkmanager ifplugd dialog pacman-contrib $PACSTRAP_EFI $PACSTRAP_FS $PACSTRAP_WIRELESS


read -p "Press [Enter] key to start Chroot..."
stty
echo -e "\e[34m\e[1mChroot\e[0m"

## CONFIGURE THE SYSTEM
    # Generate Fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # chroot into system
    #arch-chroot /mnt

    # Set the TimeZone
    #arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    ln -sf /usr/share/zoneinfo/$TIMEZONE /mnt/etc/localtime
    arch-chroot /mnt hwclock --systohc --localtime

    # Set the Locale
    echo 'LANG="'"$LOCALE".UTF-8'"' > /mnt/etc/locale.conf
    #arch-chroot /mnt sed -i 's/#\('${LOCALE_UTF8}'\)/\1/' /etc/locale.gen
    sed -i 's/#\('$LOCALE.UTF-8'\)/\1/' /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
    
    # Set the Hostname
    echo "$HOSTNAME" > /mnt/etc/hostname
    #arch-chroot /mnt sed -i '/127.0.0.1/s/$/ '{$HOSTNAME}'/' /etc/hosts
    sed -i '/127.0.0.1/s/$/ '{$HOSTNAME}'/' /mnt/etc/hosts
    #arch-chroot /mnt sed -i '/::1/s/$/ '{$HOSTNAME}'/' /etc/hosts
    sed -i '/::1/s/$/ '{$HOSTNAME}'/' /mnt/etc/hosts

    # Recreate initramfs
    #arch-chroot /mnt sed -i '/^HOOK/s/filesystems/sd-lvm2 filesystems/' /etc/mkinitcpio.conf
    sed -i 's/base udev /base systemd /' /mnt/etc/mkinitcpio.conf
    if [ -n "$LVM_VOL_GROUP" ]; then
            sed -i 's/filesystems /sd-lvm2 filesystems /' /mnt/etc/mkinitcpio.conf
    fi
    if [ $ROOT_FS = 'btrfs' ]; then
            sed -i 's/base systemd /base systemd btrfs /' /mnt/etc/mkinitcpio.conf
        elif [ $HOME_FS = 'btrfs' ]; then
            sed -i 's/base systemd /base systemd btrfs /' /mnt/etc/mkinitcpio.conf
    fi
    arch-chroot /mnt mkinitcpio -p linux

    # Set the root Password
    arch-chroot /mnt passwd $ROOT_PASSWORD

    # Enable Multilib Repo
    sed -i '/^#\[multilib]/{n;s/^#//}' /mnt/etc/pacman.conf
    sed -i 's/^#\[multilib]/[multilib]/' /mnt/etc/pacman.conf

    # Update repos
    arch-chroot /mnt pacman -Sy --noconfirm
    arch-chroot /mnt pacman -S --needed --noconfirm reflector
    arch-chroot /mnt reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
    arch-chroot /mnt pacman -Syu --noconfirm

    # Install Intel or AMD Microcode
    [[ -n $( lscpu | grep GenuineIntel ) ]] && arch-chroot /mnt pacman -S --needed --noconfirm intel-ucode
    [[ -n $( lscpu | grep AuthenticAMD ) ]] && arch-chroot /mnt pacman -S --needed --noconfirm amd-ucode

    # Enable Networking
    arch-chroot /mnt systemctl enable NetworkManager.service
    arch-chroot /mnt systemctl enable ifplugd.service
    if [ -z "$WIRELESS_DEVICE" ]; then
            arch-chroot /mnt systemctl enable iwd.service
            arch-chroot /mnt echo '[device]' > /etc/NetworkManager/conf.d/wifi_backend.conf
            arch-chroot /mnt echo \"wifi.backend=iwd\" >> /etc/NetworkManager/conf.d/wifi_backend.conf
    fi

    # Create User
    arch-chroot /mnt useradd -m -s /bin/bash -G adm,ftp,games,http,log,rfkill,sys,systemd-journal,users,uucp,wheel "$USER_NAME"
    arch-chroot /mnt echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd "$USER_NAME"

    # Add Wheel to Sudoers
    echo -e "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/99_wheel

    read -p "Press [Enter] key to install Packages..."
stty
echo -e "\e[34m\e[1mPackages\e[0m"

    # Install Packages
        # Utilities
        arch-chroot /mnt pacman -S --needed --noconfirm catfish cmatrix irssi curl fish aspell-en lsd gvim ntp openssh p7zip pkgfile python python-pip libappindicator-gtk3 rfkill unrar unzip wget zip systemd-sysvcompat zsh grml-zsh-config  vifm ranger vlc feh gpicview-gtk3 gimp cmus clementine handbrake handbrake-cli termite libreoffice-fresh hunspell hyphen-en mythes-en code neofetch libqalculate bleachbit

        # Video Drivers
        [[ -n $( lscpu | grep GenuineIntel ) ]] && arch-chroot /mnt pacman -S --needed --noconfirm xf86-video-intel
        [[ -n $( lscpu | grep AuthenticAMD ) ]] && arch-chroot /mnt pacman -S --needed --noconfirm xf86-video-amdgpu xf86-video-ati
        arch-chroot /mnt pacman -S --needed --noconfirm mesa lib32-mesa $VIDEO_DRIVER

        # GUI
        arch-chroot /mnt pacman -S --needed --noconfirm xorg
        arch-chroot /mnt pacman -S --needed --noconfirm network-manager-applet nm-connection-editor qtile dmenu rofi budgie-desktop gnome dconf dconf-editor lightdm lightdm-gtk-greeter pavucontrol pasystray awesome-terminal-fonts xautolock i3lock scrot imagemagick compton galculator qalculate-gtk gnome-screenshot adapta-gtk-theme papirus-icon-theme
        arch-chroot /mnt pacman -R --noconfirm epiphany
        arch-chroot /mnt config_xinitrc "export XDG_CURRENT_DESKTOP=Budgie:GNOME \n budgie-desktop"
        arch-chroot /mnt systemctl enable lightdm.service

        # Internet
        arch-chroot /mnt pacman -S --needed --noconfirm lynx firefox chromium qbittorrent neomutt geary newsboat feedreader

        # Games
        arch-chroot /mnt pacman -S --needed --noconfirm steam lutris
        
        # Model Specific Packages
        arch-chroot /mnt pacman -S --needed --noconfirm $MODEL_PACKAGES

read -p "Press [Enter] key to run Model specific packages and tweaks..."
stty
echo -e "\e[34m\e[1mModel Specific\e[0m"

        # Laptop Packages
        if [ $LAPTOP = 'TRUE' ]; then
                arch-chroot /mnt pacman -S --noconfirm tlp tlp-rdw
                arch-chroot /mnt systemctl enable tlp.service
                arch-chroot /mnt systemctl enable tlp-sleep.service
                arch-chroot /mnt systemctl enable NetworkManager-dispatcher.service
                arch-chroot /mnt systemctl mask systemd-rfkill.service
                arch-chroot /mnt systemctl mask systemd-rfkill.socket
        fi

        # Model Specific Tweaks
        if [ $MODEL = 'T420s' ]; then
                echo -e "SATA_LINKPWR_ON_BAT=max_performance" >> /mnt/etc/default/tlp
            elif [ $MODEL = 'Z97X-UD5H-BK' ]; then
                arch-chroot /mnt pip3 install gkraken
                arch-chroot /mnt sudo `which gkraken` --udev-add-rule
                arch-chroot /mnt gkraken --application-entry 
        fi
read -p "Press [Enter] key to install Sound..."
stty
echo -e "\e[34m\e[1mSound\e[0m"

        # Sound
        arch-chroot /mnt pacman -S --needed --noconfirm alsa-utils alsa-plugins pulseaudio pulseaudio-alsa


read -p "Press [Enter] key to install AUR..."
stty
echo -e "\e[34m\e[1mAur\e[0m"

    # install yay
    arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
    arch-chroot /mnt bash -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n\" | su $USER_NAME -c \"cd /home/$USER_NAME && git clone https://aur.archlinux.org/$AUR.git && (cd $AUR && makepkg -si --noconfirm) && rm -rf $AUR\""

    #arch-chroot /mnt yay -Syy --noconfirm tlpui-git snapd etcher-bin vscodium-bin linux-steam-integration

        if [ $LAPTOP = 'TRUE' ]; then
                 bash -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n\" | su $USER_NAME -c \"$AUR -Syu --noconfirm --needed tlpui-git\""
        fi

    arch-chroot /mnt yay -Syy --noconfirm snapd yadm-git linux-steam-integration
    arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

    # Snap
    arch-chroot /mnt apparmor
    arch-chroot /mnt systemctl enable apparmor.service && systemctl restart apparmor.service

    arch-chroot /mnt sudo snap install snap-store onlyoffice-desktopeditors discord pick-colour-picker

    # Create Bootloader
    if [ $BOOT = 'efi' ]; then
            arch-chroot /mnt pacman -S efibootmgr
            arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/$BOOT --bootloader-id=GRUB
        else
            grub-install --target=i386-pc $DRIVE
    fi
    arch-chroot /mnt grub-mkconfig -o /$BOOT/grub/grub.cfg


    arch-chroot /mnt curl https://raw.githubusercontent.com/sinderan/nanorc/master/install.sh | sh
    arch-chroot /mnt echo "set constantshow" >> /home/$USER_NAME/.nanorc
    arch-chroot /mnt echo "set constantshow" >> ~/.nanorc
    arch-chroot /mnt echo "set linenumbers" >> /home/$USER_NAME/.nanorc
    arch-chroot /mnt echo "set linenumbers" >> ~/.nanorc

    # Check Proprietary Packages
    arch-chroot /mnt bash -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n\" | su $USER_NAME -c \"cd /home/$USER_NAME && git clone https://github.com/vmavromatis/absolutely-proprietary.git && (cd absolutely-proprietary && python main.py)\""

read -p "Press [Enter] key to reboot..."

    systemctl reboot
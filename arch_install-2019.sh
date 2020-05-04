## CONFIGURE THESE VARIABLES
## ALSO LOOK AT THE install_packages FUNCTION TO SEE WHAT IS ACTUALLY INSTALLED

# Drive to install to (leave blank to be prompted).
DRIVE=''

# Hostname of the installed machine (leave blank to be prompted).
HOSTNAME=''

# Encrypt everything (except /boot).  Leave blank to disable.
ENCRYPT_DRIVE='TRUE'

# Passphrase used to encrypt the drive (leave blank to be prompted).
DRIVE_PASSPHRASE=''

# Root password (leave blank to be prompted).
ROOT_PASSWORD=''

# Main user to create (by default, added to wheel group, and others). (leave blank to be prompted)
USER_NAME=''

# The main user's password (leave blank to be prompted).
USER_PASSWORD=''

# System timezone.
TIMEZONE='America/New_York'

KEYMAP='us'
# KEYMAP='dvorak'

# Choose your video driver
# For Intel
VIDEO_DRIVER="i915"
# For nVidia
#VIDEO_DRIVER="nouveau"
# For ATI
#VIDEO_DRIVER="radeon"
# For generic stuff
#VIDEO_DRIVER="vesa"

# Wireless device, leave blank to not use wireless and use DHCP instead.
#  (leave blank to be prompted)
WIRELESS_DEVICE=""
# For tc4200's
#WIRELESS_DEVICE="eth1"

prompt(){
    if [ -z "$DRIVE" ]
    then
        echo 'Enter the drive to install to:'
        stty -echo
        read DRIVE
        stty echo
    fi
    echo "Installing to $DRIVE"

    if [ -z "$HOSTNAME" ]
    then
        echo 'Enter the Hostname to set:'
        stty -echo
        read HOSTNAME
        stty echo
    fi
    echo "HOSTNAME: $HOSTNAME"

    if [ -z "$ROOT_PASSWORD" ]
    then
        echo 'Enter the root password:'
        stty -echo
        read ROOT_PASSWORD
        stty echo
    fi
    echo "ROOT_PASSWORD: $ROOT_PASSWORD"

    if [ -z "$USER_NAME" ]
    then
        echo 'Enter the desired Username:'
        stty -echo
        read USER_NAME
        stty echo
    fi
    echo "USER_NAME: $USER_NAME"

    if [ -z "$USER_PASSWORD" ]
    then
        echo 'Enter the users password:'
        stty -echo
        read USER_PASSWORD
        stty echo
    fi
    echo "USER_PASSWORD: $USER_PASSWORD"

    if [ -z "$WIRELESS_DEVICE" ]
    then
        echo 'Enter the wireless network device to use,'
        echo ' leave blank to not use wireless and use DHCP instead.'
        echo ' T420s = wlp3s0'
        stty -echo
        read WIRELESS_DEVICE
        stty echo
    fi
    echo "WIRELESS_DEVICE: $WIRELESS_DEVICE"
}

setup() {
    local boot_dev="$DRIVE"1
    local lvm_dev="$DRIVE"2

    echo 'Creating partitions'
    partition_drive "$DRIVE"

    if [ -n "$ENCRYPT_DRIVE" ]
    then
        local lvm_part="/dev/mapper/lvm"

        if [ -z "$DRIVE_PASSPHRASE" ]
        then
            echo 'Enter a passphrase to encrypt the disk:'
            stty -echo
            read DRIVE_PASSPHRASE
            stty echo
        fi

        echo 'Encrypting partition'
        encrypt_drive "$lvm_dev" "$DRIVE_PASSPHRASE" lvm

    else
        local lvm_part="$lvm_dev"
    fi

    echo 'Setting up LVM'
    setup_lvm "$lvm_part" arch

    echo 'Formatting filesystems'
    format_filesystems "$boot_dev"

    echo 'Mounting filesystems'
    mount_filesystems "$boot_dev"

    echo 'Installing base system'
    install_base

    echo 'Chrooting into installed system to continue setup...'
    cp $0 /mnt/setup.sh
    arch-chroot /mnt ./setup.sh chroot

    if [ -f /mnt/setup.sh ]
    then
        echo 'ERROR: Something failed inside the chroot, not unmounting filesystems so you can investigate.'
        echo 'Make sure you unmount everything before you try to run this script again.'
    else
        echo 'Unmounting filesystems'
        unmount_filesystems
        echo 'Done! Reboot system.'
    fi
}

configure() {
    local boot_dev="$DRIVE"1
    local lvm_dev="$DRIVE"2

    echo 'Installing additional packages'
    install_packages

    echo 'Installing packer'
    install_packer

    echo 'Installing AUR packages'
    install_aur_packages

    echo 'Clearing package tarballs'
    clean_packages

    echo 'Updating pkgfile database'
    update_pkgfile

    echo 'Setting hostname'
    set_hostname "$HOSTNAME"

    echo 'Setting timezone'
    set_timezone "$TIMEZONE"

    echo 'Setting locale'
    set_locale

    echo 'Setting console keymap'
    set_keymap

    echo 'Setting hosts file'
    set_hosts "$HOSTNAME"

    echo 'Setting fstab'
    set_fstab "$TMP_ON_TMPFS" "$boot_dev"

    echo 'Setting initial modules to load'
    set_modules_load

    echo 'Configuring initial ramdisk'
    set_initcpio

    echo 'Setting initial daemons'
    set_daemons "$TMP_ON_TMPFS"

    echo 'Configuring bootloader'
    set_syslinux "$lvm_dev"

    echo 'Configuring sudo'
    set_sudoers

    echo 'Configuring slim'
    set_slim

    if [ -n "$WIRELESS_DEVICE" ]
    then
        echo 'Configuring netcfg'
        set_netcfg
    fi

    if [ -z "$ROOT_PASSWORD" ]
    then
        echo 'Enter the root password:'
        stty -echo
        read ROOT_PASSWORD
        stty echo
    fi
    echo 'Setting root password'
    set_root_password "$ROOT_PASSWORD"

    if [ -z "$USER_PASSWORD" ]
    then
        echo "Enter the password for user $USER_NAME"
        stty -echo
        read USER_PASSWORD
        stty echo
    fi
    echo 'Creating initial user'
    create_user "$USER_NAME" "$USER_PASSWORD"

    echo 'Building locate database'
    update_locate

    rm /setup.sh
}

partition_drive() {
    local dev="$1"; shift

    # 100 MB /boot partition, everything else under LVM
    parted -s "$dev" \
        mklabel gpt \
        mkpart primary ext2 1MiB 512MiB \
        mkpart primary ext2 512MiB 100% \
        set 1 esp on \
        set 2 LVM on
}

encrypt_drive() {
    local dev="$1"; shift
    local passphrase="$1"; shift
    local name="$1"; shift

    echo -en "$passphrase" | cryptsetup -c aes-xts-plain -y -s 512 luksFormat "$dev"
    echo -en "$passphrase" | cryptsetup luksOpen "$dev" lvm
}

setup_lvm() {
    local partition="$1"; shift
    local volgroup="$1"; shift

    pvcreate "$partition"
    vgcreate "$volgroup" "$partition"

    # Create a 1GB swap partition
    lvcreate -C y -L1G "$volgroup" -n swap

    # Create a 30GiB root partition
    lvcreate -l 30GiB "$volgroup" -n root

    # Use the rest of the space for home
    lvcreate -l '+100%FREE' "$volgroup" -n home

    # Enable the new volumes
    vgchange -ay
}

format_filesystems() {
    local boot_dev="$1"; shift

    mkfs.fat -F 32 -L efi "$boot_dev"
    mkfs.btrfs -L root /dev/arch/root
    mkfs.btrfs -L home /dev/arch/home
    mkswap /dev/arch/swap
}

mount_filesystems() {
    local boot_dev="$1"; shift

    mount /dev/arch/root /mnt
    mount /dev/arch/home /home

    mkdir /mnt/boot
    mount "$boot_dev" /mnt/boot
    swapon /dev/arch/swap
}

install_base() {
#    echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' >> /etc/pacman.d/mirrorlist
    pacman -Sy --noconfirm reflector

    reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

    pacstrap /mnt base base-devel
    pacstrap /mnt syslinux
}

unmount_filesystems() {
    umount /mnt/boot
    umount /mnt
    umount /home
    swapoff /dev/arch/swap
    vgchange -an
    if [ -n "$ENCRYPT_DRIVE" ]
    then
        cryptsetup luksClose lvm
    fi
}

install_packages() {
    local packages=''

    # General utilities/libraries
    packages+=' lvm2 sudo  alsa-utils pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavolume pa-applet aspell-en firefox gvim mlocate ntp openssh p7zip pkgfile powertop python python2 rfkill rsync sudo unrar unzip wget zip systemd-sysvcompat zsh grml-zsh-config'

    # Development packages
    packages+=' git'

    # Netcfg
    if [ -n "$WIRELESS_DEVICE" ]
    then
        packages+=' iwd networkmanager network-manager-applet nm-connection-editor ifplugd dialog'
    fi

    # Java stuff
    packages+=' icedtea-web-java7 jdk7-openjdk jre7-openjdk'

    # Libreoffice
    packages+=' libreoffice-calc libreoffice-en-US libreoffice-gnome libreoffice-impress libreoffice-writer hunspell-en hyphen-en mythes-en'

    # Misc programs
    packages+=' mplayer pidgin vlc xscreensaver gparted dosfstools ntfsprogs'

    # Xserver
    packages+=' xorg xorg-server xorg-apps qtile budgie-desktop gnome awesome-terminal-fonts xautolock i3lock scrot imagemagick compton'

    # lightdm login manager
    packages+=' lightdm lightdm-gtk-greeter'

    # Fonts
    packages+=' ttf-dejavu ttf-liberation awesome-terminal-fonts'

    # On Intel processors
    packages+=' intel-ucode'

    # For laptops
    packages+=' tlp'

    # For T420s
    packages+=' nvidia-340xx lib32-nvidia-340xx-utils lib32-virtualgl xf86-video-intel mesa bumblebee '


    if [ "$VIDEO_DRIVER" = "i915" ]
    then
        packages+=' xf86-video-intel libva-intel-driver'
    elif [ "$VIDEO_DRIVER" = "nouveau" ]
    then
        packages+=' xf86-video-nouveau'
    elif [ "$VIDEO_DRIVER" = "radeon" ]
    then
        packages+=' xf86-video-ati'
    elif [ "$VIDEO_DRIVER" = "vesa" ]
    then
        packages+=' xf86-video-vesa'
    fi

    pacman -Sy --noconfirm reflector

    reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

    pacman -Sy --noconfirm $packages
}

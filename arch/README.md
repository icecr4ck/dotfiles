# Arch Linux setup for Libreboot x200

## Keyboard

By default, the keyboard is set to English (US) but it can be changed with `loadkeys <layout_abbreviation>`.

It is possible to list the available keymaps with `localectl list-keymaps`.

## Establish an Internet connection

The `dhcpcd` network daemon starts automatically during boot to start a wired connection.

Wireless chipset firmware packages are pre-installed under `/usr/lib/firmware` in the live environment.

To connect to a wireless network, execute the following command.

```bash
iw list # to list the wireless interfaces
wifi-menu wlp2s0 # or replace it by the name of your interface
```

## Wipe storage device

1. If the drive was not previously encrypted, it can be securely wiped with the `dd` command, either with zeroes or random data.

```bash
dd if=/dev/urandom of=/dev/sdX
sync
```

2. If the drive was encrypted, it is only necessary to wipe the LUKS header. The default LUKS header takes 1052672 bytes (a little more than 1MB). Having 2 key-slots enabled extend the header almost twice, so overwriting the first 3MB is sufficient.

```bash
cryptsetup -v isLuks /dev/sdXY # to identify a LUKS filesystem
head -c 3145728 /dev/urandom > /dev/sdXY
sync
```

## Full-disk encryption (optional)

### Format the storage device

1. (optional) Load the `device-mapper` kernel module.
```bash
modprobe dm_mod
```

2. Create the partitions.
```bash
cfdisk /dev/sdX
```
* **Delete** the old partition(s)
* Select **New** to create it
* Leave the size as the default
* Choose **Primary** and make sure that the partition type is Linux (83)
* Select **Write** and **Quit**
* If the installation is not encrypted, the swap volume needs to be created with `cfdisk` (type 82)

3. (optional) Create the encrypted volume.
```bash
cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --iter-time 500 --use-random --verify-passphrase --type luks1 luksFormat /dev/sdXYa
```

4. (optional) Create the volume group and logical volumes (on for the main installation and the other for the swap)
```bash
cryptsetup luksOpen /dev/sdXY lvm # open the LUKS partition at /dev/mapper/lvm
pvcreate /dev/mapper/lvm # create the LVM partition
pvdisplay # check if the partition was well created
vgcreate matrix /dev/mapper/lvm # create the volume group (needs to be called matrix as it is hardcoded in libreboot's grub.cfg in the flash)
vgdisplay # to make sure that the group was created
lvcreate -L 4G matrix -n swapvol # create swap volume of 4GB
lvcreate -l +100%FREE matrix -n rootvol # create a single partition in the rest of the space
lvdisplay # to check if the logical volumes were created correctly
```

5. Make the partitions ready for installation
```bash
mkswap /dev/mapper/matrix-swapvol # or /dev/sdX2 if no encryption
swapon /dev/matrix/swapvol # activate the Swap
mkfs.ext4 /dev/mapper/matrix-rootvol # or /dev/sdX1 if no encryption
mount /dev/matrix/rootvol /mnt
```

## Installation

### Select the mirrors

Change (eventually) the order of the mirrors used by pacman in `/etc/pacman.d/mirrorlist`.

### Install the base packages

Use `pacstrap` to install the base packages (+ the packages needed for setting up the internet connection).
```bash
pacstrap /mnt base base-devel iw wpa_supplicant dialog openssh zsh vim git
```

### Generate an fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## Configure the system

Chroot into the new system.
```bash
arch-chroot /mnt
```

Set the timezone.
```bash
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc 
```

Uncomment `en_US.UTF-8` locale in /etc/locale.gen and generate it with `locale-gen`.

Create the `/etc/locale.conf` and set the `LANG` variable as follows.
```bash
LANG=en_US.UTF-8
```

Set the hostname in `/etc/hostname` and add matching entries to `hosts`.
```bash
# /etc/hosts
127.0.0.1 localhost.localdomain localhost myhostname
::1       localhost.localdomain localhost myhostname
```

Change the root password with `passwd`.

Add a normal user with `useradd`.
```bash
useradd -m -g users -G wheel -s /usr/bin/zsh icecr4ck
passwd icecr4ck
visudo # uncomment the wheel group as sudo
```

## Install AUR repository

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

## Setting up the kernel modules

Edit the file `/etc/mkinitcpio.conf` and add the following values:
* uncomment `MODULES` line and add `i915` to it
* (if disk encryption) change the value of the `HOOKS` line and add `encrypt` and `lvm2` before `filesystems` and `shutdown` at the end of the line.

Optionally you can install the LTS kernel as a backup, in the event you encounter problems with the default kernel (continually updated).
```bash
pacman -S linux-lts grub
```

Finally, both kernels are updated with `mkinitcpio`.
```bash
mkinitcpio -p linux
mkinitcpio -p linux-lts
```

## Modifying the GRUB configuration file

### Get the Libreboot utility archive

```bash
curl -O https://www.mirrorservice.org/sites/libreboot.org/release/stable/20160907/libreboot_r20160907_util.tar.xz
tar -xf libreboot_r20160907_util.tar.xz
mv libreboot_r20160907_util libreboot_util
```

### Dump the Flash

First, you need to add `iomem=relaxed` to your Linux cmdline so you can dump the ROM. You have to reboot and go to the GRUB shell by pressing `c` when the GRUB menu shows up. Then you can boot manually on your new installation in executing the following commands.

```
grub> set root=(ahci0,1) # to get the correct identifier run ls in the GRUB shell
grub> linux /boot/vmlinuz-linux root=/dev/sda1 iomem=relaxed
grub> initrd /boot/initramfs-linux.img
grub> boot
```

Good reference for GRUB rescuing: https://www.linux.com/tutorials/how-rescue-non-booting-grub-2-linux/

```bash
cd libreboot_util/flashrom/x86_64/
./flashrom -p internal -r ../../cbfstool/x86_64/libreboot.rom # the chip can be specified with the -c MX25L6405 option
```

### Extract the grubtest.cfg file from the ROM

```bash
cd ../../cbfstool/x86_64
./cbfstool libreboot.rom extract -n grubtest.cfg -f grubtest.cfg
```

### Modify the Grub configuration file

Look for the following line: `Load Operating Sytem [o]' --hotkey='o' [...]` and change the code after the opening bracket.

1. Disk fully-encrypted with LUKS (needs to add a keyfile for the LUKS volume in `/etc/keyfile`)
```
cryptomount -a
set root='lvm/matrix-rootvol'
linux /boot/vmlinuz-linux root=/dev/matrix/rootvol cryptdevice=/dev/sda1:root cryptkey=rootfs:/etc/keyfile
initrd /boot/initramfs-linux.img
```

2. No disk encryption
```
set root=(ahci0,1)
linux /boot/vmlinuz-linux root=/dev/sda1
initrd /boot/initramfs-linux.img
```

Then, you can remove the `grubtest.cfg` file from the ROM and add the new one.
```bash
./cbfstool libreboot.rom remove -n grubtest.cfg
./cbfstool libreboot.rom add -n grubtest.cfg -f grubtest.cfg -t raw
```

### Change the MAC address in ROM

Every Libreboot ROM image contains a generic MAC address, it is important to modify it before flashing the ROM.

Run `ifconfig` to get the MAC address, and run `ich9gen` as follows.
```bash
mv libreboot.rom ../../ich9deblob/x86_64
./ich9gen --macaddress XX:XX:XX:XX:XX:XX # it will create different ich9fdgbe_Xm.bin files
```

Choose the one corresponding to the size of your ROM image and insert it with `dd` into the ROM image.

```bash
dd if=ich9fdgbe_Xm.bin of=libreboot.rom bs=1 count=12k conv=notrunc
```

### Flash the updated ROM image

```bash
mv libreboot.rom ../../
./flash update libreboot.rom
# if flashrom complains about a board mismatch and you are sure that you chose the correct ROM image run
./flash forceupdate libreboot.rom
```

If it says `VERFIED` then it's good.

### Replace the grubtest.cfg by grub.cfg

If it boots correctly, you can replace the `grub.cfg` in the ROM.

```bash
cd libreboot_util/cbfstool/x86_64
cp grubtest.cfg grub.cfg
sed -e 's:(cbfsdisk)/grub.cfg:(cbfsdisk)/grubtest.cfg:g' -e 's:Switch to grub.cfg:Switch to grubtest.cfg:g' < grubtest.cfg > grub.cfg
mv ../../libreboot.rom .
./cbfstool libreboot.rom remove -n grub.cfg
./cbfstool libreboot.rom add -n grub.cfg -f grub.cfg -t raw
mv libreboot.rom ../../ && cd ../..
./flash update libreboot.rom
```

## Post-installation

Add configurations files and run the `setup.sh` script.

Almost all the dotfiles are from here: https://www.reddit.com/r/unixporn/comments/ak2u11/i3_solarized_for_life/

## References

* https://libreboot.org/docs/gnulinux/encrypted_parabola.html
* https://wiki.archlinux.org/index.php/installation_guide
* https://libreboot.org/docs/gnulinux/grub_cbfs.html

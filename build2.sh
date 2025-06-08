set -uexo pipefail

sudo ./kiwi-build --kiwi-file=Fedora-Mobility.kiwi --image-type=oem --image-profile=SDM845-Disk --output-dir ./outdir

mkdir artifacts/

sudo kpartx -vafs ./outdir-build/Fedora-Mobility.aarch64-Rawhide.raw
sudo dd if=/dev/mapper/loop0p1 of=efipart.vfat bs=1M
sudo dd if=/dev/mapper/loop0p2 of=artifacts/Fedora-Mobility-Remix-SDM845-boot.raw bs=1M
sudo dd if=/dev/mapper/loop0p3 of=artifacts/Fedora-Mobility-Remix-SDM845-root.raw bs=1M

# The ESP that kiwi generated for us has the wrong sector size,
# so we recreate it.
VOLID=$(file efipart.vfat | grep -Eo "serial number 0x.{8}" | cut -d\  -f3)

truncate -s 268435456 artifacts/Fedora-Mobility-Remix-SDM845-esp.raw
mkfs.vfat -F 32 -S 4096 -n EFI -i $VOLID artifacts/Fedora-Mobility-Remix-SDM845-esp.raw

mkdir -p esp.old esp.new
sudo mount -o loop efipart.vfat esp.old
sudo mount -o loop artifacts/Fedora-Mobility-Remix-SDM845-esp.raw esp.new

sudo cp -a esp.old/. esp.new/
sudo umount esp.old/ esp.new/

# Push firmware blobs into the rootfs.
git clone https://gitlab.com/sdm845-mainline/firmware-oneplus-sdm845

mkdir rootfs
sudo mount -o loop,subvol=root artifacts/Fedora-Mobility-Remix-SDM845-root.raw rootfs

sudo cp --update -a firmware-oneplus-sdm845/usr rootfs/
sudo cp --update -a firmware-oneplus-sdm845/lib rootfs/usr

# Hide ipa-fws.mbn. Somehow loading this firmware drops the phone into Crashdump mode
sudo mv rootfs/usr/lib/firmware/qcom/sdm845/oneplus6/ipa_fws.mbn{,.disabled}

# Some blobs from firmware-oneplus-sdm845 need to be preferred over
# the stuff that comes from linux-firmware
sudo mv rootfs/usr/lib/firmware/postmarketos/* rootfs/usr/lib/firmware/updates
sudo rmdir rootfs/usr/lib/firmware/postmarketos

sudo umount rootfs

# Clean out libdnf5 cache (800M+)
mkdir var-subvol
sudo mount -o loop,subvol=var artifacts/Fedora-Mobility-Remix-SDM845-root.raw var-subvol
sudo rm -rf var-subvol/cache/libdnf5/*
sudo umount var-subvol


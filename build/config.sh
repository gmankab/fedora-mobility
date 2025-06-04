#!/bin/bash

set -euxo pipefail

test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

rm -f /etc/machine-id
echo 'uninitialized' > /etc/machine-id
# remove random seed, the newly installed instance should make its own
rm -f /var/lib/systemd/random-seed

# works around issues with grub-bls
# see: https://github.com/OSInside/kiwi/issues/2198
echo "GRUB_DEFAULT=saved" >> /etc/default/grub
# disable submenus to match fedora
echo "GRUB_DISABLE_SUBMENU=true" >> /etc/default/grub
# disable recovery entries to match fedora
echo "GRUB_DISABLE_RECOVERY=true" >> /etc/default/grub

systemctl set-default graphical.target

# Repart is segfaulting, so disable it
rm -rf /etc/repart.d/*.conf

passwd -d root
passwd -l root
echo 'root:147147' | chpasswd

groupadd -g 1000 user
useradd -g 1000 -G wheel -m -u 1000 user
echo 'user:147147' | chpasswd

systemctl enable phrog bootmac-bluetooth hexagonrpcd-sdsp pd-mapper rmtfs tqftpserv

# add hexagonrpc config, so that sensor hardware drivers will know where to get firmware from to initialize hardware.
mkdir -p /usr/share/hexagonrpcd/
echo 'hexagonrpcd_fw_dir="/usr/share/qcom/sdm845/OnePlus/oneplus6"' > /usr/share/hexagonrpcd/hexagonrpcd-sdsp.conf

# finalization steps
# inhibit the ldconfig cache generation unit, see rhbz2348669
touch -r "/usr" "/etc/.updated" "/var/.updated"

exit 0


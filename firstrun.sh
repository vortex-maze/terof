#!/bin/bash

set +e

CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname raspberrypiron
else
   echo raspberrypiron >/etc/hostname
   sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\traspberrypiron/g" /etc/hosts
fi
FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
if [ -f /usr/lib/userconf-pi/userconf ]; then
   /usr/lib/userconf-pi/userconf 'keraz.pi' '$5$X0zo4H6W2H$N5jiNwHnIN5Sm7RvI.rVf1F5uu7Z8ecZNpvddX2h5Q5'
else
   echo "$FIRSTUSER:"'$5$X0zo4H6W2H$N5jiNwHnIN5Sm7RvI.rVf1F5uu7Z8ecZNpvddX2h5Q5' | chpasswd -e
   if [ "$FIRSTUSER" != "keraz.pi" ]; then
      usermod -l "keraz.pi" "$FIRSTUSER"
      usermod -m -d "/home/keraz.pi" "keraz.pi"
      groupmod -n "keraz.pi" "$FIRSTUSER"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=keraz.pi/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/keraz.pi/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^$FIRSTUSER /keraz.pi /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_keymap 'sn'
   /usr/lib/raspberrypi-sys-mods/imager_custom set_timezone 'Asia/Dhaka'
else
   rm -f /etc/localtime
   echo "Asia/Dhaka" >/etc/timezone
   dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="sn"
XKBVARIANT=""
XKBOPTIONS=""

KBEOF
   dpkg-reconfigure -f noninteractive keyboard-configuration
fi
rm -f /boot/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
exit 0

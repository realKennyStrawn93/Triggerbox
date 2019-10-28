#!/bin/bash

kernel="$(ls /boot | grep kernel-genkernel | sort -rn | head -n1)"
initramfs="$(ls /boot | grep initramfs-genkernel | sort -rn | head -n1)"

kdenlive="https://files.kde.org/kdenlive/release/$(wget -O - https://files.kde.org/kdenlive/release/ | grep -Eo kdenlive-[0-9][0-9].[0-9][0-9].[0-9][a-z]-x86_64.appimage | sort -rn | head -n1)"

appimagelauncher_base=https://artifacts.assassinate-you.net/artifactory/AppImageLauncher
appimagelauncher_var1=$(wget -O - $appimagelauncher_base | grep -Eo travis-[0-9]{1,} | sort -rn | head -n1)
appimagelauncher_var2=$(wget -O - $appimagelauncher_base/$appimagelauncher_var1 | grep appimagelauncher-lite | grep x86_64 | cut -d "\"" -f2)
appimagelauncher=$appimagelauncher_base/$appimaglauncher_var1/$appimagelauncher_var2

#Overlays
layman -L
yes | layman -a snapd
yes | layman -a brave-overlay

#AppImage Daemon
mkdir /Applications
wget -O /usr/bin/appimaged https://github.com/AppImage/appimaged/releases/download/continuous/appimaged-x86_64.AppImage
chmod a+x /usr/bin/appimaged
wget -O /lib/systemd/system/appimaged.service https://raw.githubusercontent.com/AppImage/appimaged/master/resources/appimaged.service
systemctl enable appimaged.service

#AppImage Updater
wget -O /usr/bin/AppImageUpdate https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
chmod a+x /usr/bin/AppImageUpdate
wget -O /usr/share/applications/AppImageUpdate.desktop https://raw.githubusercontent.com/AppImage/AppImageUpdate/rewrite/resources/AppImageUpdate.desktop

#AppImageLauncher
wget -O /usr/bin/appimagelauncher-lite $appimagelauncher
chmod a+x /usr/bin/appimagelauncher-lite
appimagelauncher-lite --appimage-extract
cp squashfs-root/usr/share/applications/appimagelauncher-lite.desktop /usr/share/applications/appimagelauncher-lite.desktop
for i in $(ls /usr/share/icons); do
  if [ ! -d /usr/share/icons/$i/192x192 ]; then
    mkdir -p /usr/share/icons/$i/192x192/apps
  fi
  cp squashfs-root/usr/share/icons/hicolor/192x192/apps/AppImageLauncher.png /usr/share/icons/$i/192x192/apps/AppImageLauncher.png
done
rm -rf squashfs-root

#Install Kdenlive as AppImage
wget -O /Applications/Kdenlive.AppImage $kdenlive
chmod a+x /Applications/Kdenlive.AppImage
/Applications/Kdenlive.AppImage --appimage-extract
cp squashfs-root/org.kde.kdenlive.desktop /usr/share/applications/kdenlive.desktop
sed -i "s/Exec\=.*/Exec\=\/Applications\/Kdenlive.AppImage\ \%F/" /usr/share/applications/kdenlive.desktop
for i in $(ls /usr/share/icons); do
  if [ ! -d /usr/share/icons/$i/scalable ]; then
    mkdir -p /usr/share/icons/$i/scalable/apps
  fi
  cp squashfs-root/kdenlive.svg /usr/share/icons/$i/scalable/apps/kdenlive.svg
done
rm -rf squashfs-root

#Live media hostname
echo "livecd" > /etc/hostname

#Calamares-pkexec
sed -i "s/calamares-pkexec/pkexec\ \/usr\/bin\/calamares/g" /usr/share/applications/calamares.desktop

#Extended globbing by default
echo "shopt -s extglob" >> /etc/profile

#GRUB Plymouth entry
sed -i "s/.*GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash zram.num_devices=1\"/" /etc/default/grub
sed -i "s/.*GRUB_TIMEOUT.*/GRUB_TIMEOUT=0/" /etc/default/grub
sed -i "s/GRUB_TIMEOUT.*/GRUB_TIMEOUT=0/" /etc/calamares/modules/grubcfg.conf

#Root password
echo -e "triggerlinux\ntriggerlinux" | passwd

#Automatic login
systemctl enable gdm.service
sed -i "3a AutomaticLoginEnable=true" /etc/gdm/custom.conf
sed -i "4a AutomaticLogin=root" /etc/gdm/custom.conf

#Customize Dash-to-Panel
echo -e "[org.gnome.shell.extensions.dash-to-panel]" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "appicon-margin=3" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "hotkeys-overlay-combo='TEMPORARILY'" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "panel-size=40" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "animate-show-apps=false" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override

#Desktop Background
echo -e "[org.gnome.desktop.background:GNOME]" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-options='str/etched'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-uri='file:///usr/share/backgrounds/gnome/SeaSunset.jpg'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "primary-color='#ffffff'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "secondary-color='#000000'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Lock screen background
echo -e "[org.gnome.desktop.screensaver:GNOME]" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-options='str/etched'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-uri='file:///usr/share/backgrounds/gnome/SeaSunset.jpg'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "primary-color='#ffffff'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "secondary-color='#000000'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "idle-activation-enabled=false" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Enable GNOME Shell extensions by default
echo -e "[org.gnome.shell:GNOME]\nenabled-extensions=['dash-to-panel@jderose9.github.com', 'desktop-icons@csoriano', 'user-theme@gnome-shell-extensions.gcampax.github.com']" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Favorites
echo -e "favorite-apps=['calamares.desktop', 'org.gnome.Evolution.desktop', 'brave-bin.desktop', 'gnome-control-center.desktop', 'rhythmbox.desktop', 'shotwell.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.tweaks.desktop', 'org.gnome.Terminal.desktop', 'kdenlive.desktop']\n" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#More window controls than just "Close"
echo -e "[org.gnome.desktop.wm.preferences:GNOME]\nbutton-layout='appmenu:minimize,maximize,close'\n" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Arc Theme + Clock Prefs
echo -e "[org.gnome.desktop.interface:GNOME]\ngtk-theme='Arc'\nicon-theme='Arc'\nclock-show-date=true\nclock-show-seconds=true" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Recompile Schemas
glib-compile-schemas /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas
glib-compile-schemas /usr/share/glib-2.0/schemas

#Don't disadvantage those with slower hardware
sed -i "s/MAKEOPTS/\#MAKEOPTS/" /etc/portage/make.conf
sed -i "s/MAKEOPTS/\#MAKEOPTS/" /etc/genkernel.conf

#NetworkManager
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service

#Ensure that printing works out-of-the-box
systemctl enable cups.service

#Make Brave work when run as any user, including root
sed -i "s/Exec=.*/Exec=\/usr\/bin\/brave-bin\ \-\-no\-sandbox\ \%u/" /usr/share/applications/brave-bin.desktop

#Initialize gentoo git repos to prevent Calamares emerge --sync failure
cd /usr/livecd/db/repos/gentoo
git init
git remote add origin https://anongit.gentoo.org/git/repo/gentoo.git
git pull --depth 1 origin master

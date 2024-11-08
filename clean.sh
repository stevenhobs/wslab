apt purge -y cloud-init vim-tiny snapd x11-apps libx11-6 libdrm2 byobu mtr-tiny tcpdump telnet
apt autoremove --purge -y
apt autoclean -y
apt clean -y
rm -rf /var/lib/apt/lists/*
rm -rf /var/log/*
cd ..
rm -rf /wslab
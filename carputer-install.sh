#!/bin/bash

#Run APT Update
echo Running apt update...
sudo apt update

#Setting config file options
echo Setting config file options...
sudo sh -c "echo 'dtparam=i2c_arm=on \ndtparam=pwr_led_trigger=none \ndtparam=pwr_led_activelow=off \ndisable_splash=1 \ndtoverlay=i2c-rtc,pcf8523 \ndtoverlay=hifiberry-dacplushd \ngpu_mem=128 \ndtoverlay=gpio-poweroff,gpiopin=4,active_low' >> /boot/config.txt"
sudo sed -i '/^dtparam=audio=on$/s/^/#/' /boot/config.txt

#Setting cmdline file options
echo Setting cmdline file options...
sudo sed -i '$s/$/ logo.nologo/' /boot/cmdline.txt

#Install Python Modules
sudo pip install pyalsaaudio==0.8.4
pip3 install rpi-backlight==1.8.1


#Copy keymap file to triggerhappy service directory
echo copying keymap file...
sudo cp configuration files/keys.conf /etc/triggerhappy/triggers.d

#Change user nobody to pi in /etc/systemd/system/multi-user.target.wants/triggerhappy.service
echo configuring TriggerHappy service...
sudo sed -i 's/nobody/pi/' /etc/systemd/system/multi-user.target.wants/triggerhappy.service

#Configure RTC
echo configuring RTC...
sudo apt-get -y remove fake-hwclock
sudo update-rc.d -f fake-hwclock remove
sudo systemctl disable fake-hwclock
sudo sed -i -e '7,9s/^/#/' -e '29s/^/#/' -e '32s/^/#/' /lib/udev/hwclock-set
sudo hwclock -r
date
sudo hwclock -w

#Configure backlight udev rules
echo "SUBSYSTEM==\"backlight\",RUN+=\"/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power\"" | sudo tee /etc/udev/rules.d/backlight-permissions.rules

#Configure scripts and services
echo Configuring scripts and services...
sudo chmod +x scripts/*
sudo cp services/* /etc/systemd/user
sudo systemctl enable /etc/systemd/user/*

#Configure Host AP
echo Configuring host AP daemon...
#In order to work as an access point, the Raspberry Pi needs to have the hostapd access point software package installed:
sudo apt install -y hostapd

#Enable the wireless access point service and set it to start when your Raspberry Pi boots:
sudo systemctl unmask hostapd
sudo systemctl enable hostapd

#In order to provide network management services (DNS, DHCP) to wireless clients, the Raspberry Pi needs to have the dnsmasq software package installed:
sudo apt install -y dnsmasq

#Define the Wireless Interface IP Configuration
sudo sh -c "echo 'interface wlan0 \n    static ip_address=192.168.4.1/24 \n    nohook wpa_supplicant' >> /etc/dhcpcd.conf"

#Configure the DHCP and DNS services for the wireless network
#Rename the default configuration file and edit a new one:
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo touch /etc/dnsmasq.conf
sudo sh -c "echo 'interface=wlan0 \n# Listening interface \ndhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h \n# Pool of IP addresses served via DHCP \ndomain=puter \n# Local wireless DNS domain \naddress=/gw.puter/192.168.4.1 \n# Alias for this router' >> /etc/dnsmasq.conf"

#To ensure WiFi radio is not blocked on your Raspberry Pi, execute the following command:
sudo rfkill unblock wlan

#Configure the AP Software
#Create the hostapd configuration file, located at /etc/hostapd/hostapd.conf, to add the various parameters for your new wireless network.
sudo touch /etc/hostapd/hostapd.conf
sudo sh -c 'echo "country_code=US \ninterface=wlan0 \nssid=carputer \nhw_mode=a \nchannel=36 \ncountry_code=US \nieee80211d=1 \nmacaddr_acl=0 \nauth_algs=1 \nmax_num_sta=10 \nignore_broadcast_ssid=0 \nwmm_enabled=1 \nwpa=2 \nwpa_passphrase=SnakePenis!! \nwpa_key_mgmt=WPA-PSK \nwpa_pairwise=TKIP \nrsn_pairwise=CCMP \n \n \n \n# Use iw list to see which capabilities your WiFi card has \n# 80211ac: vht_oper_centr_freq_seg1_idx not working currently, problem using ch 149 \nieee80211n=1 \nieee80211ac=1 \nht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40][MAX-AMSDU-3839] \nvht_capab=[MAX-MPDU-3895][SHORT-GI-80][SU-BEAMFORMEE] \nvht_oper_chwidth=1 \nvht_oper_centr_freq_seg0_idx=42" >> /etc/hostapd/hostapd.conf'
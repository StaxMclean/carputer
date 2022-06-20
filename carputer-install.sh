#!/bin/bash

#Run APT Update
echo Running apt update...
sudo apt update

#Install Dash
cd

git clone https://github.com/openDsh/dash

cd dash

./install.sh

./rpi.sh -adi
./rpi.sh -asd

cd ~/carputer

sudo chmod +x configuration/rtc_config.sh

#Setting install run once flag
flag="install_flag"
#
# if there is no $flag, this is the 1st time
if [[ ! -f "$flag" ]] ; then
	touch "$flag"
	#write out current crontab
	crontab -l > mycron
	#echo new cron into cron file
	echo "@reboot ./home/pi/carputer/configuration/rtc_config.sh" >> mycron
	#install new cron file
	crontab mycron
	rm mycron
fi

#Setting config file options
echo Setting config file options...
sudo sh -c "echo '\
dtparam=i2c_arm=on\
\n\
dtparam=pwr_led_trigger=none\
\n\
dtparam=pwr_led_activelow=off\
\n\
disable_splash=1\
\n\
dtoverlay=i2c-rtc,pcf8523\
\n\
dtoverlay=hifiberry-dacplushd\
\n\
dtoverlay=gpio-poweroff,gpiopin=4,active_low\
' >> /boot/config.txt"
sudo sed -i '/^dtparam=audio=on$/s/^/#/' /boot/config.txt

#Setting cmdline file options
echo Setting cmdline file options...
sudo sed -i 's/quiet splash/logo.nologo/' /boot/cmdline.txt

#Install Python Modules
sudo pip install pyalsaaudio==0.8.4
pip3 install rpi-backlight==1.8.1


#Copy keymap file to triggerhappy service directory
echo copying keymap file...
sudo cp configuration/keys.conf /etc/triggerhappy/triggers.d

#Change user nobody to pi in /etc/systemd/system/multi-user.target.wants/triggerhappy.service
echo configuring TriggerHappy service...
sudo sed -i 's/nobody/pi/' /etc/systemd/system/multi-user.target.wants/triggerhappy.service


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
sudo sh -c "echo '\
interface wlan0\
\n\
    static ip_address=192.168.4.1/24\
\n\
    nohook wpa_supplicant\
' >> /etc/dhcpcd.conf"

#Configure the DHCP and DNS services for the wireless network
#Rename the default configuration file and edit a new one:
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo touch /etc/dnsmasq.conf
sudo sh -c "echo '\
interface=wlan0\
\n\
# Listening interface\
\n\
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h\
\n\
# Pool of IP addresses served via DHCP\
\n\
domain=puter\
\n\
# Local wireless DNS domain\
\n\
address=/gw.puter/192.168.4.1\
\n\
# Alias for this router\
' >> /etc/dnsmasq.conf"

#To ensure WiFi radio is not blocked on your Raspberry Pi, execute the following command:
sudo rfkill unblock wlan

#Configure the AP Software
#Create the hostapd configuration file, located at /etc/hostapd/hostapd.conf, to add the various parameters for your new wireless network.
sudo touch /etc/hostapd/hostapd.conf

if grep -q "Raspberry Pi 4" /proc/cpuinfo; then
	sudo sh -c 'echo "country_code=US\ninterface=wlan0\nssid=carputer\nhw_mode=a\nchannel=36\nieee80211d=1\nmacaddr_acl=0\nauth_algs=1\nmax_num_sta=10\nignore_broadcast_ssid=0\nwmm_enabled=1\nwpa=2\nwpa_passphrase=SnakePenis!!\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP\nrsn_pairwise=CCMP\n\n\n\n# Use iw list to see which capabilities your WiFi card has\n# 80211ac: vht_oper_centr_freq_seg1_idx not working currently, problem using ch 149\nieee80211n=1\nieee80211ac=1\nht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40][MAX-AMSDU-3839]\nvht_capab=[MAX-MPDU-3895][SHORT-GI-80][SU-BEAMFORMEE]\nvht_oper_chwidth=1\nvht_oper_centr_freq_seg0_idx=42" >> /etc/hostapd/hostapd.conf'
else
	#Pi 3 Wifi options
	#interface=wlan0
	#driver=nl80211
	#
	#hw_mode=g
	#channel=6
	#ieee80211n=1
	#wmm_enabled=1
	#ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
	#macaddr_acl=0
	#ignore_broadcast_ssid=0
	#country_code=US
	#
	#WPA2
	#auth_algs=1
	#wpa=2
	#wpa_key_mgmt=WPA-PSK
	#rsn_pairwise=CCMP
	#
	#SSID
	#ssid=carputer
	#wpa_passphrase=SnakePenis!!
	sudo sh -c 'echo "#Pi 3 Wifi options\ninterface=wlan0\ndriver=nl80211\n#\nhw_mode=g\nchannel=6\nieee80211n=1\nwmm_enabled=1\nht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]\nmacaddr_acl=0\nignore_broadcast_ssid=0\ncountry_code=US\n#\n#WPA2\nauth_algs=1\nwpa=2\nwpa_key_mgmt=WPA-PSK\nrsn_pairwise=CCMP\n#\n#SSID\nssid=carputer\nwpa_passphrase=SnakePenis!!" >> /etc/hostapd/hostapd.conf'
fi

sudo reboot


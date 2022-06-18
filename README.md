# carputer
Carputer Steps

1.	Install buster OS (legacy)
2.	Update
3.	Config


  a.	Add following lines to /boot/config.txt:
	
      dtparam=i2c_arm=on
      dtparam=pwr_led_trigger=none
      dtparam=pwr_led_activelow=off
      disable_splash=1
      dtoverlay=i2c-rtc,pcf8523
      dtoverlay=hifiberry-dacplushd
      #dtparam=audio=on
      gpu_mem=128
b.	Add logo.nologo to end of /boot/cmdline.txt

c.	Create /etc/asound.conf and ~/.asoundrc and set soundcard to default

d.	Add keys.conf to /etc/triggerhappy/triggers.d

e.	change user nobody to pi in /etc/systemd/system/multi-user.target.wants/triggerhappy.service

4.	Configure RTC (see rtc instructions.txt)
	
5.	Install scripts and services


  a.	Shutdown script
	
    i.	Copy latest version of script to ~/scripts
    ii.	Set script as executable
    iii.	Copy latest version of service file to ~/services
    iv.	Copy that to /etc/system/user
    v.	Add following line to /etc/udev/rules.d/backlight-permissions.rules
      SUBSYSTEM=="backlight",RUN+="/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"
    vi.	Enable service (sudo systemctl enable /etc/system/user/<service-file-name>
  b.	Rotary encoder script
	
    i.	Copy latest version of script to ~/scripts
    ii.	Set script as executable
    iii.	Copy latest version of service file to ~/services
    iv.	Copy that to /etc/system/user
    v.	Enable service (sudo systemctl enable /etc/system/user/<service-file-name>
  c.	Light Detect Script
	
    i.	Copy latest version of script to ~/scripts
    ii.	Set script as executable
    iii.	Copy latest version of service file to ~/services
    iv.	Copy that to /etc/system/user
    v.	Enable service (sudo systemctl enable /etc/system/user/<service-file-name>
  d.	Fan Speed script
	
    i.	Copy latest version of script to ~/scripts
    ii.	Set script as executable
    iii.	Copy latest version of service file to ~/services
    iv.	Copy that to /etc/system/user
    v.	Enable service (sudo systemctl enable /etc/system/user/<service-file-name>
6.	Configure Wireless Hotspot

  a.	Follow wirelessAA.txt guide
	
  b.	Use following settings for 80Mhz AC operation:
	
      ssid=Raspberry Net
      hw_mode=a
      channel=36
      country_code=US
      ieee80211d=1
      macaddr_acl=0
      max_num_sta=10
      ignore_broadcast_ssid=0
      wmm_enabled=1

      # 802.11n/ac (HT/VHT) Settings
      # Use iw list to see which capabilities your WiFi card has
      # 80211ac: vht_oper_centr_freq_seg1_idx not working currently, problem using ch 149
      ieee80211n=1
      ieee80211ac=1
      ht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40][MAX-AMSDU-3839]
      vht_capab=[MAX-MPDU-3895][SHORT-GI-80][SU-BEAMFORMEE]
      vht_oper_chwidth=1
      vht_oper_centr_freq_seg0_idx=42
7.	Install Dash
  a.	Clone repo at git clone https://github.com/openDsh/dash
  b.	Cd dash
  c.	./install.sh



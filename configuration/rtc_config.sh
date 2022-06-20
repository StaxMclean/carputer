cd ~/carputer

#Setting install run once flag
flag="install_flag"
#
# if there is no $flag, exit
if [[ ! -f "$flag" ]] ; then
  exit
else
	#Configure RTC
	echo configuring RTC...
	sudo apt-get -y remove fake-hwclock
	sudo update-rc.d -f fake-hwclock remove
	sudo systemctl disable fake-hwclock
	sudo sed -i -e '7,9s/^/#/' -e '29s/^/#/' -e '32s/^/#/' /lib/udev/hwclock-set
	sudo hwclock -r
	date
	sudo hwclock -w
	#
	#remove flag
	rm -f "$flag"
  	#remove cronjob
  	crontab -r pi
fi

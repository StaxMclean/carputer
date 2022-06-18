#! /usr/bin/python3

import RPi.GPIO as GPIO
import time
from time import time as timer
import os

gpio_acc=27

GPIO.setmode(GPIO.BCM)
GPIO.setup(gpio_acc, GPIO.IN, pull_up_down=GPIO.PUD_UP)

timeout = 1200
countdown = timeout

while True:
	time.sleep(1 - timer() % 1)
	countdown -= 1
	if GPIO.input(gpio_acc):
		os.system("sudo echo 1 > /sys/class/backlight/rpi_backlight/bl_power")
	if not GPIO.input(gpio_acc):
		countdown = timeout
		os.system("sudo echo 0 > /sys/class/backlight/rpi_backlight/bl_power")
		#print("reset")
	if countdown <= 0:
		#print("shutdown")
		os.system("sudo shutdown -h now")
		countdown = timeout

GPIO.cleanup()

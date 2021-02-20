#!/usr/bin/python3
#Output delay check test for TSL2561 Luminosity Sensor
#RaspberryConnect.com
import smbus
import time
import subprocess
import rpi_backlight as bl
#import math


TSLaddr = 0x39 #Default I2C address, alternate 0x29, 0x49 
TSLcmd = 0x80 #Command
chan0 = 0x0C #Read Channel0 sensor date
chan1 = 0x0E #Read channel1 sensor data
TSLon = 0x03 #Switch sensors on
TSLoff = 0x00 #Switch sensors off
#Exposure settings
LowShort = 0x00 #x1 Gain 13.7 miliseconds
LowMed = 0x01 #x1 Gain 101 miliseconds
LowLong = 0x02 #x1 Gain 402 miliseconds
LowManual = 0x03 #x1 Gain Manual
HighShort = 0x10 #LowLight x16 Gain 13.7 miliseconds
HighMed = 0x11	#LowLight x16 Gain 100 miliseconds
HighLong = 0x12 #LowLight x16 Gain 402 miliseconds
HighManual = 0x13 #LowLight x16 Gain Manual
# Get I2C bus
bus = smbus.SMBus(1)
writebyte = bus.write_byte_data
# Define ranges
oMin = 20
oMax = 600
nMin = 40
nMax = 255

def remap( x, oMin, oMax, nMin, nMax ):
	#range check
	if oMin == oMax:
		#console.log("Warning: Zero input range")
		return None

	if nMin == nMax:
		#console.log("Warning: Zero output range")
		return None
	
	if x > oMax:
		value = nMax
	elif x < oMin:
		value = nMin
	else:
		value = float(x/oMax) * (nMax-nMin)+nMin

	return int(value)


def translate(value, leftMin, leftMax, rightMin, rightMax):
    # Figure out how 'wide' each range is
    leftSpan = leftMax - leftMin
    rightSpan = rightMax - rightMin

    # Convert the left range into a 0-1 range (float)
    valueScaled = float(value - leftMin) / float(leftSpan)

    # Convert the 0-1 range into a value in the right range.
    return int(rightMin + (valueScaled * rightSpan))


def lightcheck():
	#Read Ch0 Word
	data = bus.read_i2c_block_data(TSLaddr, chan0 | TSLcmd, 2)
	#Read CH1 Word
	data1 = bus.read_i2c_block_data(TSLaddr, chan1 | TSLcmd, 2)
	# Convert the data to Integer
	ch0 = data[1] * 256 + data[0]
	ch1 = data1[1] * 256 + data1[0]
	vResults = ch0-ch1 #get visable light results
	translated = remap(vResults, oMin, oMax, nMin, nMax)
	print("Reading = ",vResults,"Mapped = ",translated)
	
	#subprocess.Popen(['echo {} > /sys/class/backlight/rpi_backlight/brightness'.format(translated)], shell=True)
	bl.set_brightness(translated, smooth=True, duration=2)
	time.sleep(5)
#	if vResults > 200: #check against reading threshold 
#		print("Light Level Detected")
#		#do something else
#		time.sleep(5)
#	else:
#		print("I will check again soon")
#		writebyte(TSLaddr, 0x00 | TSLcmd, TSLoff) #switch off
#		time.sleep(10) #delay before next check in seconds
#		writebyte(TSLaddr, 0x00 | TSLcmd, TSLon) #switch on
#		time.sleep(1) #time for sensor to settle

if __name__ == "__main__":
	writebyte(TSLaddr, 0x00 | TSLcmd, TSLon) #Power On
	#Gain x1 at 402ms is the default so this line not required 
	#but change for different sensitivity
	writebyte(TSLaddr, 0x01 | TSLcmd,LowLong) #Gain x1 402ms
	time.sleep(1) #give time sensor to settle
	#print("check Starting")
	while 1:
		lightcheck()
	writebyte(TSLaddr, 0x00 | TSLcmd, TSLoff) #Power Off

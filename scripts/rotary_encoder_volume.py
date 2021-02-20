#! /usr/bin/python

import RPi.GPIO as GPIO
from time import sleep
import alsaaudio


# Global constants & variables
# Constants
__author__ = 'Paul Versteeg'

m = alsaaudio.Mixer('Digital',0)

counter = m.getvolume()[0]

# GPIO Ports
CLK = 16  # Encoder input A: input GPIO 23 (active high)
DT = 26  # Encoder input B: input GPIO 24 (active high)


def init():
    '''
    Initializes a number of settings and prepares the environment
    before we start the main program.
    '''
    print ("Rotary Encoder Test Program")
    

    GPIO.setwarnings(True)

    # Use the Raspberry Pi BCM pins
    GPIO.setmode(GPIO.BCM)

    # define the Encoder switch inputs
    GPIO.setup(CLK, GPIO.IN, pull_up_down=GPIO.PUD_DOWN) # pull-ups are too weak, they introduce noise
    GPIO.setup(DT, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

    # setup an event detection thread for the A & B encoder switch
    GPIO.add_event_detect(CLK, GPIO.RISING, callback=rotation_decode, bouncetime=4)
    #
    return


def rotation_decode(CLK):
    
    global counter

    #sleep(0.001) # extra de-bounce time

    # read both of the switches
    CLK_R = GPIO.input(CLK)
    DT_R = GPIO.input(DT)

    if CLK_R != DT_R: # A then B ->
        counter += 2
        if counter > 100:
            counter = 100
        else:
            counter = max(0,counter)
        #print ("direction -> ", counter)
        m.setvolume(counter)
        return

    elif CLK_R == DT_R: # B then A <-
        counter -= 2
        if counter > 100:
            counter = 100
        else:
            counter = max(0,counter)
        #print ("direction <- ", counter)
        m.setvolume(counter)
        return
    
    else: # discard all other combinations
        return

    
    #m.setvolume(counter)
    #return



def main():
    '''
    The main routine.

    '''

    try:

        init()
        while True :
            #
            # wait for an encoder click
            sleep(0.5)

    except KeyboardInterrupt: # Ctrl-C to terminate the program
        GPIO.cleanup()


if __name__ == '__main__':
    main()

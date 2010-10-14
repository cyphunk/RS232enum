#!/usr/bin/python2.5
#    CHECK YOUR  ^^^  VERSION
#    THE vvvvvvvv LIB NEEDS TO BE INSTALLED
# http://pyserial.sourceforge.net/pyserial_api.html

import serial
import time

if __name__ == "__main__":
        import sys
        import glob
        device = glob.glob("/dev/tty.usbserial*")[0]
        if len(sys.argv) > 1:
                baud = sys.argv[1]
        else:
                print "provide baudrate as arguemnt"
                exit
                
        ser = serial.Serial(device, baud) #, timeout=0, parity=serial.PARITY_EVEN, rtscts=1)
        print "opened tty: %s"%ser.portstr
        print "valid baudrates:"
        print ser.BAUDRATES
        print "valid bytesizes:"
        print ser.BYTESIZES
        print "valid parities:"
        print ser.PARITIES
        print "valid stopbits:"
        print ser.STOPBITS
        i=0
        #9  = 0    9/10=0
        #10 = 1    10/10=1
        #100 = 2   10/10=10
        #1000 = 3
        
        while True:
                #i+=1
                #print '\x08\x08\x08\x08\x08x08\x08\x08\x08\x08\x08\x08\x08\x08x08\x08\x08\x08\x08x08\x08\x08\x08\x08x08\x08\x08\x08\x08x08\x08\x08\x08\x08',
                #sys.stdout.flush()
                ret = ""
                if ser.inWaiting():
                        ret = ser.read()
                        if ord(ret) == 0x0a or ord(ret) == 0x0d: # 0x10 == CR
                                print "recieved CR (0x10)"
                                ser.write("abcdefghijklmnopqrstuvwxyzABCDEFJHIJKLMNOPQRSTUVWXYZ")
                        else:
                                print ret

                #print "%12d"%(i),
                #time.sleep(1)

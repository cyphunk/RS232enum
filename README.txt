 RS232enum
 When you are presented with pins that you suspect provide Serial but
 you do not have access to the documentation.  Connect your Arduino
 to all of the pins (limited by the number of Ditial pins you have on
 your board) and this sketch will try every possible pin combination
 and baud rate to determine RX/TX. It will also try to send wakeup
 characters to stimulate the line, such as a carriage return or other
 txpatterns that you add. This code sends data using a custom
 SoftwareSerial library. 
      For the Parallel scans interpreting the return data would not be
 reliable. Instead the software just gives a good indication of 
 active lines (parallel scan) and specifically serial lines that 
 respond to wakeup patterns / stimulation (active parallel and active
 per pin scans). Where reports indicate likely serial the user should
 then plug up a serial cable and confirm with terminal software on
 their workstation using the indicated baud rate and wakeup patterns.

 Further documentation: http://deadhacker.com/tools/
 
 SETUP:
 1. set pins[] to the arduino pins being used for the scan
 2. set pinnames[] to the names for each pin (that better relate to
    your target)
 3. set baudrates[] to a list of baudrates we should use when
    sending txpattern wakeup signals on the TX line
 4. (optional) set txpatters[] to desired stimulation patterns
 5. (optional) if your board does not have enough memory uncomment
    the "#define SHRINK" line. Note: "information" function will be
    disabled as a result
 6. (optional) set Arduino CPU to 8MHZ if using 3.3v logic

 USAGE:
 -  load sketch and attach to arduino at 115200 baud
 -  type '?' or 'help' for command information

 TESTING:
 -  "clienttest.py" included with the code can be run for a virtual test.
    execute the script and connect your arduino to the RX/TX lines of your
    workstation. clienttest.py only prints out on the serial line when it
    receives a carriage return (at its baudrate)

 AUTHORS & CODE BRANCHES:
 cyphunk  http://github.com/cyphunk/RS232enum/

 DEVELOPER NOTES:
 -  pfmt() = local printf()
 -  ppgm() = print() which uses the FLASH memory of the board. Some 
    boards have limited SRAM so we use the FLASH ram where possible.
 -  Supports up to 64 pins atm (because report buffer stores pin state
    in 2 byte bit array)
 -  the arduino IDE tries to silently build and include function prototypes
    from companion sketch files, however it doesn't work when you return
    or have as arguments non standard arduino types. Hence, sometimes we
    we declare them, and sometimes not
 -  As of Arduino 1 the softserial delay required per baudrate definitions.
    Don't ask why. This means that only common buadrates are supported.
    Perhaps it was always this way. Also, with the new changes I did not
    test if older Arduino versions worked so just use Arduino >= v1
 This code is public domain, abuse as you wish and at your own risk

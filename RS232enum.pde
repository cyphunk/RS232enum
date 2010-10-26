/* 
 RS232enum  (v0.2.1 20101026)
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

 This code is public domain, abuse as you wish and at your own risk
 */

 
 

/*

   BEGIN USER DEFINITIONS
 
 */
 
// DEFINE PINS
// Arduino must use microcontroller pin numbers for pins[]:
byte         pins[]     = {      12,       13,      14 };
char    *    pinnames[] = {   "aaa",      "b", "ccccc" };
// Teensy can use board based names:
//byte       pins[]     = {  PIN_B7,   PIN_D0,   PIN_D1,    PIN_D2,    PIN_D3,   PIN_D4,   PIN_D5,   PIN_D6,
//                           PIN_D7,   PIN_E0,   PIN_E1,    PIN_C0};
//char  *    pinnames[] = {    "aa",    "bbb",     "cc",       "d",    "eeee",     "ff",     "gg",     "hh",
//                             "ii", "jjjjjj",     "kk",      "ll"};

// DEFINE BAUDRATES
//uint32_t  baudrates[] = { 300, 600, 1200, 1800, 2400, 4800, 7200, 9600, 14400, 19200, 38400, 57600, 115200 };
//uint32_t  baudrates[] = { 0, 100000}; // range from 1 to 100000  NOT IMPLEMENTED YET
//uint32_t  baudrates[] = { 9600 };     // dont search, assume 9600
uint32_t    baudrates[] = { 9600, 115200};

// DEFINE TX WAKEUP PATTERNS (LSB first):
//uint16_t txpatterns[] = { 0x0000, 0xFFFF, 0x0a00, ~0x0a00 };         // 10=0xA=CR
//byte     txpatterns[] = { B11111111,B00000000,B01010101,B10101010 }; // 10=0xA=CR, 0x41="A"
byte       txpatterns[] = { 0x0a, 0x0d, 0x41 };                        // 10=0xA=CR, 0x41="A"

//#define SHRINK        // uncomment to reduce size of program. information() 
                        // function will be disabled
#define   SHOWTXSTATUS  // creates longer reports for "active" scans but usefull
                        // just to see where the scan currently is



/*
   END OF USER DEFINITIONS
 */






//needed to put help strings into flash
#include <avr/pgmspace.h>

//#define DEBUGLOOPS    // count and show loops in test (slows down and reduces reliability)
//#define DEBUGSTATEBUF // print bit level info of state buf (slows down and reduces reliability)

boolean   printnames    = true;
byte      pinslen       = sizeof(pins);               
byte      baudrateslen  = sizeof(baudrates)/sizeof(uint32_t);
byte      txpatternslen = sizeof(txpatterns);

// default time required to poll for rx response (in us):
uint32_t  usperrx       = mstous(2000);

// Report buffer values
uint16_t  reserveram    = 500;                   // number of bytes to keep free - safty measure
                                                 // reportbuf will be malloc'ed in remaining free space
uint16_t  rambeforealloc;
byte      pinstatelen   = ((pinslen-1) / 8) + 1; // bitfield len. calc backwards, but im sleep deprived so im leavin it
byte     *pinstatebuf;                           // bitfield. alloc later, bit array
byte     *reportbuf;                             // size based on free ram
uint16_t  reportbuflen;
uint16_t  reportbuf_i   = 0;


// FROM UTILS
void         pfmt(char *fmt, ... );
void         ppgm(const char *str);
boolean      noprint    = 0; 
#ifndef SHRINK
uint32_t     timefunction(void (*function)(uint32_t), uint32_t arg);
uint32_t     timefunction(void (*function)(byte), byte arg);
uint32_t     timefunction(int (*function)());
#endif



void usage() 
{
        ppgm(PSTR("USAGE\r\n"
                "-----\r\n"
                "TESTS:\r\n"
                "All\r\n\truns all of the following tests in sequence\r\n"
                "Passive Parallel\r\n\tpoll all RX pins in parallel\r\n\tno active TX\r\n\tnotes: issues at high baud\r\n"
                "Active Parallel\r\n\tpoll all RX pins in parallel\r\n\tone TX pins used to print patterns\r\n\tnotes: issues at high baud\r\n"
                "Active Per Pin\r\n\tpoll RX pins incrementally (less error prone)\r\n\tone TX pins used to print patterns\r\n\r\n"
                //"Active Per Pin With Times\r\n\tpoll RX pins incrementally (less error prone)\r\n\tone TX pins used to print patterns\r\n\tstate change timing recorded (requires more memory)\r\n"
                "COMMANDS:\r\n\t"
                "(long form       [short form])\r\n\t"
                "passive parallel [pp]\r\n\t"
                "active parallel  [ap]\r\n\t"
                "active per pin   [apin]\r\n\t"
                "all              [all]\r\n\r\n\t"
                "information      [info]    shows the time required to complete each test and other info\r\n\t"
                "pin state        [state]   just shows current value on pins\r\n\t"
                "rx wait          [wait]    show or set number of milliseconds test wait when polling rx lines\r\n\t"
                "help             [?]       show this message\r\n\r\n"));
}

/* initialize pins to read or write depending on test */
void setup_pins (byte outpin_i=0) 
{
        for (int i=0; i<pinslen; i++) {
                pinMode(pins[i], INPUT);
                digitalWrite(pins[i], HIGH); // trigger intern pull-up resistor
                pinstatebuf[i/8] = 0xFF;     // init the buf
        }
}

void information () 
{
#ifndef SHRINK
        uint32_t us,ms;
        ppgm(PSTR("RESOURCE TESTS\r\n"));
        ppgm(PSTR("--------------\r\n"));
        ppgm(PSTR("MEMORY\r\n"));
        int freeram=getfreeram();
        pfmt("free ram:              \t%d bytes\r\n", freeram);
        pfmt("report buffer size:    \t%d (addr:%d)\r\n", reportbuflen, reportbuf);
        pfmt("ram before reportbuf:  \t%d bytes\r\n\r\n", rambeforealloc);

        ppgm(PSTR("BAUDRATES\r\nwill attempt active signales at:\r\n  "));
        for (int i=0; i<baudrateslen; i++) 
                pfmt("%lu ",baudrates[i]);
        ppgm(PSTR("\r\n\r\n"));

        ppgm(PSTR("FUNCTION RUN TIMING\r\n"));
        pfmt("pins to check:         \t%d\r\n", pinslen);
        pfmt("clocks per microsecond:\t%d\r\n", ustoclk(1));
        us = timefunction(&getfreeram);
        pfmt("getfreeram:            \t%lu us  %lu clk\r\n",us, ustoclk(us));

        us = timefunction(&setup_pins, 0);
        pfmt("setup_pins:            \t%lu us  %lu clk\r\n",us, ustoclk(us));

        us = timefunction(&passive_parallel_scan, 1);
        pfmt("passive_parallel_scan: \t%lu us  %lu clk  est. ",us, ustoclk(us));
        mstotime(ustoms(usperrx));

        us = timefunction(&active_parallel_scan, 1);
        pfmt(" active_parallel_scan: \t%lu us  %lu clk  est. ",us, ustoclk(us));
        mstotime( (sizeof(txpatterns)/sizeof(byte)) * pinslen * ustoms(usperrx) * baudrateslen);

                us = timefunction(&active_per_pin_scan, 1);
        pfmt("  active_per_pin_scan:\t%lu us  %lu clk  est. ",us, ustoclk(us));
        mstotime( (sizeof(txpatterns)/sizeof(byte)) * pinslen * ustoms(usperrx) * (pinslen-1) * baudrateslen);

        ppgm(PSTR("\r\n'us'/'clk' are based on signle loop test. 'est.' is\r\nthe estimated time for the complete test.\r\n\r\n"));
#endif
}

void set_rx_wait()
{
        char value[32];
        pfmt("Enter RX poll time in milliseconds [leave blank or enter \" \" to keep %dms]: ", ustoms(usperrx));
        // WAIT FOR VALUE
        while (!Serial.available()) { }

        // READ VALUE
        delay(5); // hoping read buffer is idle after 5 ms
        int i = 0;
        while (Serial.available() && i < 31) {
                value[i++] = Serial.read();
        }
        Serial.flush();
        value[i] = 0; // terminate string
        if (atoi(value))
                usperrx = mstous(atoi(value));
        pfmt("\r\nSet to %dms\r\n\r\n", ustoms(usperrx));
        
        
}




void setup() 
{
        Serial.begin(115200);
        
        // init pin state buf
        pinstatebuf  = (byte *) malloc( pinstatelen );
        
        // init report buf:
        rambeforealloc = getfreeram();
        reportbuflen = rambeforealloc - reserveram;
        reportbuf    = (byte *) malloc( reportbuflen );
        clear_report_buffer();

        // Init pins
        setup_pins();
        
        Serial.print("> ");
}

char command[20];
void loop() 
{
        // EMULATE DEBUG
        /*
        delay(10000); // wait 10 seconds before starting
        for (byte i=0; i < pinslen; i++) // toggles pin state to 01010101 for debug testing
                bitWrite(pinstatebuf[i/8], i%8, i&1); 
        passive_parallel_scan(4);
        for (byte i=0; i < pinslen; i++)
                bitWrite(pinstatebuf[i/8], i%8, i&1); 
        active_parallel_scan(4);
        for (byte i=0; i < pinslen; i++)
                bitWrite(pinstatebuf[i/8], i%8, i&1); 
        active_per_pin_scan(4);
        while (1) {} // endless loop
        */
        

        // WAIT FOR COMMAND
        if (Serial.available())
        {
        
        // READ COMMAND
        delay(5); // hoping read buffer is idle after 5 ms
        int i = 0;
        while (Serial.available() && i < 19) {
                command[i++] = Serial.read();
        }
        Serial.flush();
        command[i] = 0; // terminate string
        Serial.println(command); // echo back
        
        // EXECUTE COMMAND
        if     (strcmp(command, "information") == 0      || strcmp(command, "info") == 0)
                information();
        else if(strcmp(command, "pin state") == 0        || strcmp(command, "state") == 0)
                pins_state();
        else if(strcmp(command, "rx wait") == 0          || strcmp(command, "wait") == 0)
                set_rx_wait();
        else if(strcmp(command, "passive parallel") == 0 || strcmp(command, "pp") == 0)
                passive_parallel_scan(usperrx);
        else if(strcmp(command, "active parallel") == 0  || strcmp(command, "ap") == 0)
                active_parallel_scan(usperrx);
        else if(strcmp(command, "active per pin") == 0   || strcmp(command, "apin") == 0)
                active_per_pin_scan(usperrx);
        else if(strcmp(command, "run all") == 0          || strcmp(command, "all") == 0)
                { information(); passive_parallel_scan(usperrx); active_parallel_scan(usperrx); active_per_pin_scan(usperrx); }
        else
                usage();
        Serial.print("> ");
        }
}
















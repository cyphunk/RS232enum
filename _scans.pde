
// fyi, numer of runs to take for rx pins check
// nruns = passive parallel scan loops
// active parallel scan = sizeof(txpatterns) * sizeof(rxpins) * nruns
// active per pin scan = sizeof(txpatterns) * sizeof(txpins) * sizeof(rxpins-1 for current tx pin)



/* passive_parallel_scan
 * Assume there is an active RX line presenting data.
 * this is usefull only for tool verfication. An active RX
 * would negate the need to use a serial detection tool. You
 * could just use an oscilloscope. 
 */
void passive_parallel_scan (uint32_t usperrx) 
{
        pfmt(     "-> passive_parallel_scan(wait %lu microseconds for each iteration)\r\n",usperrx);
        pfmt(     "   listens to all pins in parallel for %lu microseconds\r\n",usperrx);
        ppgm(PSTR("   tx stimulation and baudrate check not needed\r\n"));
        ppgm(PSTR("   prints pins whose bits change at the end of test\r\n"));
        microsbegin();
         
        byte testmode = 0;
        if (usperrx <= 1) 
                testmode = 1;

        byte state;
        uint32_t usstop = micros() + usperrx;
#ifdef DEBUGLOOPS
        uint32_t loops = 0;
#endif
        while (micros() <= usstop || testmode) {
                for (byte rx = 0; rx < pinslen; rx++) {
#ifdef DEBUGLOOPS                       
                        loops++;
#endif                        
                        state = digitalRead(pins[rx]);
#ifdef DEBUGSTATEBUF     
                        pfmt("cmp: %d != bitRead(pinstatebuf[%d]=%d, %d)=%d\r\n",state, rx/8, pinstatebuf[rx/8], rx%8, bitRead(pinstatebuf[rx/8], rx%8) );
#endif
                        if (state != bitRead(pinstatebuf[rx/8], rx%8) ) {
                                append_to_report(rx, state);
                                bitWrite(pinstatebuf[rx/8], rx%8, state);  // need to check the efficiency of bitWrite

                        }
                }
                if(testmode) // run only one iteration
                        break;
        }
        print_report();
        ustotime(microselapsed());        
#ifdef DEBUGLOOPS        
        pfmt("loops: %lu\r\n",loops);
#endif
}

/* active_parallel_scan
 * Assume there is an active RX line presenting data.
 * will send a txpattern wakeup pattern hoping this will
 * stimulate the target to start printing to the console
 * (it is common that some terminals require you send a 
 *  carriage return before they present a login screen)
 * all non-tx pins are then scanned in parallel
 */
void active_parallel_scan (uint32_t usperrx) 
{
        ppgm(PSTR("-> active_parallel_scan\r\n"));
        pfmt(     "   listens to all non tx pins in parallel for %lu microseconds\r\n",usperrx);
        ppgm(PSTR("   sends wakeup stimulant to tx pin at defined baudrates\r\n"));
        ppgm(PSTR("   prints pins whose bits change during test\r\n"));
        microsbegin();

        byte testmode = 0;
        if (usperrx <= 1) 
                testmode = 1;

        uint32_t usstop;
        uint16_t baud_i;
        byte pat, tx, rx, state;
#ifdef DEBUGLOOPS        
        uint32_t loops=0;
#endif
        for (baud_i = 0; baud_i < baudrateslen; baud_i++) {
                pfmt("baud: %lu\r\n",baudrates[baud_i]);
                softserial_setup(baudrates[baud_i]);
                for (pat = 0; pat < txpatternslen; pat++) {
                        for (tx = 0; tx < pinslen; tx++) {
#ifdef SHOWTXSTATUS                             
                                pfmt("0x%02X -> %s\r\n",txpatterns[pat],pinnames[tx]);
#endif                        
                                pinMode(pins[tx], OUTPUT);
                                softserial_write(pins[tx], txpatterns[pat]);
                                usstop = micros() + usperrx;
                                while (micros() <= usstop || testmode){
                                        for (rx = 0; rx < pinslen; rx++) {
                                                if(rx == tx) continue;
#ifdef DEBUGLOOPS        
                                                loops++;
#endif
                                                state = digitalRead(pins[rx]);
                                                if (state != bitRead(pinstatebuf[rx/8], rx%8) ) {
                                                        append_to_report(rx, state);
                                                        bitWrite(pinstatebuf[rx/8], rx%8, state);
                                                }
                                        }
                                        if (testmode) 
                                                break; // run combined iterations only once
                                }
                                pinMode(pins[tx], INPUT); // reset    
                                digitalWrite(pins[tx], HIGH); // pull-up resistor
                                print_report(tx, txpatterns[pat]);           

                        }
                }
        }
        ustotime(microselapsed());
#ifdef DEBUGLOOPS        
        pfmt("loops: %lu\r\n",loops);
#endif
}

/* active_per_pin_scan
 * exactly the same as active_parallel_scan except that
 * the each RX pin is scanned individually
 */
void active_per_pin_scan (uint32_t usperrx) 
{
        ppgm(PSTR("-> active_per_pin_scan\r\n"));
        pfmt(     "   listens to 1 rx pin at a time for %lu microseconds\r\n",usperrx);
        ppgm(PSTR("   sends wakeup stimulant to tx pin at defined baudrates\r\n"));
        ppgm(PSTR("   prints pins whose bits change during test\r\n"));
        microsbegin();
        
        byte testmode = 0;
        if (usperrx <= 1) 
                testmode = 1;

        uint32_t usstop;        
        uint16_t baud_i;
        byte pat,tx,rx,state;
#ifdef DEBUGLOOPS        
        uint32_t loops=0;
#endif
        for (pat=0; pat < txpatternslen; pat++) {
                for (tx=0; tx < pinslen; tx++) {
#ifdef SHOWTXSTATUS                             
                        pfmt("0x%02X -> txpin %s\r\n",txpatterns[pat],pinnames[tx]);
#endif                        
                        pinMode(pins[tx], OUTPUT);
                        // no need to delay before read. just need to be sure we can 
                        // poll all pins long enough to detect low serial baud.
                        for (rx=0; rx < pinslen; rx++) {
                                if(rx==tx) continue; // no need to digitalRead(rxpin)
                                for (baud_i=0; baud_i < baudrateslen; baud_i++) {
                                        pfmt("tx:%s rx:%s baud:%lu \r\n",pinnames[tx],pinnames[rx],baudrates[baud_i]);
                                        softserial_setup(baudrates[baud_i]);
                                        softserial_write(pins[tx], txpatterns[pat]);
                                        usstop = usperrx+micros();
                                        while (micros() <= usstop || testmode) {
#ifdef DEBUGLOOPS        
                                                loops++;
#endif                                        
                                                state = digitalRead(pins[rx]);
#ifdef DEBUGSTATEBUF       
                                                pfmt("cmp: %d != bitRead(pinstatebuf[%d]=%d, %d)=%d\r\n",state, rx/8, pinstatebuf[rx/8], rx%8, bitRead(pinstatebuf[rx/8], pat%8) );
#endif
                                                if (state != bitRead(pinstatebuf[rx/8], rx%8) ) {
                                                        append_to_report(rx, state);
                                                        bitWrite(pinstatebuf[rx/8], rx%8, state);
                                                }
                                                if (testmode) 
                                                        break; // read pin once
                                        }
                                        print_report(tx,txpatterns[pat]);                  
                                }

                        }
                        pinMode(pins[tx], INPUT); // reset to INPUT   
                        digitalWrite(pins[tx], HIGH); //pull-up
                }
        }
#ifdef DEBUGLOOPS        
        pfmt("loops: %lu\r\n",loops);
#endif
}

/* pins_state
 * prints the current high/low state of all the pins
 */
void pins_state () 
{
        // align names and pin state columns by finding the max string length
        
        ppgm(PSTR("pin:      "));
        for (byte i = 0; i < pinslen; i++) { 
                pfmt("%s  ", pinnames[i]);
        }
        ppgm(PSTR("\r\nstate:    "));
        for (byte i = 0; i < pinslen; i++) {
                // align columns using space:
                for (byte j = 0; j < strlen(pinnames[i])-1; j++)
                        pfmt(" ");
                pfmt("%d  ", bitRead(pinstatebuf[i/8], i%8));
        }
        ppgm(PSTR("\r\n"));
}


void append_to_report(byte rxpin_i, byte state) 
{
        if ( reportbuf_i <= reportbuflen-2 ) {
                reportbuf[reportbuf_i++] = rxpin_i; 
                reportbuf[reportbuf_i++] = state;
        }
        else {
                pfmt("."); // indication that memory is full
        }
}

// return 1 if anything was reported
byte print_report(int16_t tx, uint16_t txpattern) 
{
        byte ret=0;
        if (reportbuf_i>0) {
                ret=1;
                if (tx >= 0) {
                        pfmt("\t0x%02X -> %s:\t", txpattern,pinnames[tx]);
                }
                for (uint16_t i=0; i<=reportbuf_i-2;) {
                        //                        if (i%(pinslen)==0)
                        if (i%16==0 && i!=0)
                                pfmt("\r\n        \t");
                        pfmt("%s=%d  ",pinnames[reportbuf[i++]],reportbuf[i++]);
                }
                pfmt("\r\n");
                //clear_report_buffer(); // resource intensive
                reportbuf_i=0;
        }
        return ret;
}
void print_report() 
{
        print_report(-1,0);
}


void clear_report_buffer() 
{
        for (uint16_t i=0; i<reportbuflen; i++) 
                reportbuf[i]=0;
        reportbuf_i=0;
}
/*
void print_report_buffer() 
{
        for (uint16_t i=0; i<reportbuflen; i++) {
                if (i%32==0) { 
                        pfmt("\r\n"); 
                }
                p ("%d ", reportbuf[i]);
        }
}
void print_all_pins () 
{
        pfmt("\r\n");
        for (int i=0; i<pinslen; i++) 
                pfmt("%d ", digitalRead(pins[i]));
        pfmt("\r\n");
}
*/

















uint32_t bitDelay;
uint32_t halfBitDelay;
uint32_t _baudRate;
uint32_t tx_delay;
void softserial_setup (uint32_t baud) 
{
        uint32_t _bitPeriod;
        _bitPeriod   = 1000000 / baud;
        _baudRate    = baud;
        // tx_delay dependent on baudrate. taken from NewSoftSerial
        switch (baud) {
#if F_CPU == 16000000
          case 300:    tx_delay = 7614; break;
          case 1200:   tx_delay = 1899; break;
          case 2400:   tx_delay = 947;  break;
          case 4800:   tx_delay = 471;  break;
          case 9600:   tx_delay = 233;  break;
          case 14400:  tx_delay = 153;  break;
          case 19200:  tx_delay = 114;  break;
          case 28800:  tx_delay = 74;   break;
          case 31250:  tx_delay = 68;   break;
          case 38400:  tx_delay = 54;   break;
          case 57600:  tx_delay = 33;   break;
          case 115200: tx_delay = 12;   break;
#elif F_CPU == 8000000
          case 300:    tx_delay = 9520; break;
          case 1200:   tx_delay = 2376; break;
          case 2400:   tx_delay = 1186; break;
          case 4800:   tx_delay = 592;  break;
          case 9600:   tx_delay = 294;  break;
          case 14400:  tx_delay = 194;  break;
          case 19200:  tx_delay = 145;  break;
          case 28800:  tx_delay = 95;   break;
          case 31250:  tx_delay = 88;   break;
          case 38400:  tx_delay = 70;   break;
          case 57600:  tx_delay = 41;   break;
          case 115200: tx_delay = 18;   break;
#else
#error RS232enum only support 16 and 8MHz processors
#endif
          default: Serial.println("unsupported baudrate"); return;
        }

        bitDelay     = _bitPeriod - clockCyclesToMicroseconds(12); // aprox time of digitalWrite?
        halfBitDelay = bitDelay / 2;
}
void softserial_write(uint8_t _transmitPin, uint8_t b)
{
        if (_baudRate == 0)
                return;

        //int bitDelay = _bitPeriod - clockCyclesToMicroseconds(50); // a digitalWrite is about 50 cycles
        byte mask;

        digitalWrite(_transmitPin, LOW);
        delayMicroseconds(bitDelay);

        for (mask = 0x01; mask; mask <<= 1) {
                if (b & mask){ // choose bit
                        digitalWrite(_transmitPin,HIGH); // send 1
                }
                else{
                        digitalWrite(_transmitPin,LOW); // send 1
                }
                delayMicroseconds(bitDelay);
        }

        digitalWrite(_transmitPin, HIGH);
        delayMicroseconds(bitDelay);
}



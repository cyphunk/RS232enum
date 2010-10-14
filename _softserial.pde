uint32_t bitDelay;
uint32_t halfBitDelay;
uint32_t _baudRate;
void softserial_setup (uint32_t baud) 
{
        uint32_t _bitPeriod;
        _bitPeriod   = 1000000 / baud;
        _baudRate    = baud;
        bitDelay     = _bitPeriod - clockCyclesToMicroseconds(50); // aprox time of digitalWrite?
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



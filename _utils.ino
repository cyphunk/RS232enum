
extern boolean noprint; // used to turn off p() entirelly when running information() timing tests
void pfmt(char *fmt, ... )
{
        if (noprint) { 
                return; 
        }
        char tmp[128];
        va_list args;
        va_start (args, fmt );
        vsnprintf(tmp, 128, fmt, args);
        va_end (args);
        Serial.print(tmp);
} 
// given a PROGMEM string, use Serial.print() to send it out
void ppgm(const char *str)
{
        if (noprint) { 
                return; 
        }
        char c;
        if(!str) return;
        while((c = pgm_read_byte(str++)))
                Serial.write(c);
}
extern int __bss_end;
extern int *__brkval;
int getfreeram()
{
        int free_memory;
        if((int)__brkval == 0)
                free_memory = ((int)&free_memory) - ((int)&__bss_end);
        else
                free_memory = ((int)&free_memory) - ((int)__brkval);
        return free_memory;
}

uint32_t us;
void microsbegin() 
{
        us=micros();
}
uint32_t microselapsed() 
{ 
        return micros() - us;
}
uint32_t ustoclk(uint32_t us) 
{
        return microsecondsToClockCycles(us);
}
uint32_t ustos(uint32_t us) 
{
        return us/1000000;
}
uint32_t ustoms(uint32_t us) 
{
        return us/1000;
}
uint32_t mstos(uint32_t ms) 
{
        return ms/1000;
}
uint32_t mstous(uint32_t ms) 
{
        return ms*1000;
}

#ifndef SHRINK
uint32_t milliseconds(uint32_t us) 
{
        return us % 1000000;
}
uint32_t timefunction(void (*function)(byte), byte arg) 
{
        noprint=1;
        microsbegin();   
        function(arg);
        noprint=0;
        return microselapsed(); 
}
uint32_t timefunction(void (*function)(uint32_t), uint32_t arg) 
{
        noprint=1;
        microsbegin();   
        function(arg);
        noprint=0;
        return microselapsed(); 
}
uint32_t timefunction(int (*function)()) 
{
        noprint=1;
        microsbegin();   
        function();
        noprint=0;
        return microselapsed(); 
}
void mstotime(uint32_t ms) 
{
        uint32_t s =  mstos(ms);
        uint32_t hours   =  s / 3600;
        uint32_t minutes = (s % 3600) / 60;
        uint32_t seconds = (s % 3600) % 60;
        pfmt("%02lu:%02lu:%02lu\r\n", hours, minutes, seconds);
}
#endif

void ustotime(uint32_t us) 
{
        uint32_t s =  ustos(us);
        uint32_t hours   =  s / 3600;
        uint32_t minutes = (s % 3600) / 60;
        uint32_t seconds = (s % 3600) % 60;
        pfmt("%02lu:%02lu:%02lu\r\n", hours, minutes, seconds);
}

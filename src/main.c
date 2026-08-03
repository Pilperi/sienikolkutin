#include <avr/io.h>
#include <stdint.h>
#include "pinnit.h"
#include "shiftreg.h"
#include "debug.h"

void main(void)
{
    __asm__("sei");
    shiftreg_init();
    for(;;){
        debug_print_koputukset();
    }
}

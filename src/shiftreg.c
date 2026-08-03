#include <stdint.h>
#include <util/delay.h>
#include "shiftreg.h"
#include "pinnit.h"


/* Aseta kommunikaatiopinnit ulostuloiksi ja alas jotta dataa voi siirtää. */
void shiftreg_init(void)
{
    PORTB &= ~((1<<PIN_SREG_CLK) | (1<<PIN_SREG_DAT));
    PORTB |= (1<<PIN_SREG_CLR);
    DDRB |= ((1<<PIN_SREG_CLK) | (1<<PIN_SREG_DAT) | (1<<PIN_SREG_CLR));
}


/* Lähetä kahdeksan bittiä dataa, MSB ensin */
void shiftreg_laheta(uint8_t data)
{
    for(uint8_t bitti=8; bitti; bitti--)
    {
        if(data & (1<<7)){PORTB &= ~(1<<PIN_SREG_DAT);}
        else{PORTB |= (1<<PIN_SREG_DAT);}
        PORTB |= (1<<PIN_SREG_CLK);
        PORTB &= ~(1<<PIN_SREG_CLK);
        data = (data << 1);
    }
    PORTB &= ~(1<<PIN_SREG_DAT);
    /* 595 vaatii yhden ekstrakello ennen kuin data tulee näkyviin */
    #ifdef SHIFTREG_595
    PORTB |= (1<<PIN_SREG_CLK);
    PORTB &= ~(1<<PIN_SREG_CLK);
    #endif
    //_delay_ms(500);
    return;
}


/* Lähetä tyhjäyspulssi. */
void shiftreg_clear(void)
{
    PORTB &= ~(1<<PIN_SREG_CLR);
    __asm__("nop");
    PORTB |= (1<<PIN_SREG_CLR);
}

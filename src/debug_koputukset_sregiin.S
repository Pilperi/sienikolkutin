#define __SFR_OFFSET 0
#include <avr/io.h>
#include "rekisterit.h"
#include "pinnit.h"

.global debug_print_koputukset
.global shiftreg_laheta

debug_print_koputukset:
    CLI
    SBI PORTB,PIN_SREG_OE
    MOV R24,REG_TULOS_KOPUTUKSET
    RCALL shiftreg_laheta
    CBI PORTB,PIN_SREG_OE
    RET

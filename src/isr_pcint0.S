#define __SFR_OFFSET 0
#include <avr/io.h>
#include "rekisterit.h"
#include "pinnit.h"

.global isr_pcint0
.section .text.isr


; Kopautuksen interrupt:
; Kun unitilassa tärinäanturiin tulee tärähdys, laitetaan
; tärinäinterrupti pois päältä TIMER_0 interruptiajan ajaksi:
; Anturi perustuu kontaktin muodostavaan jouseen, joka jää heilumaan,
; joten se tuottaisi useamman signaalipulssin yhdestä kopautuksesta.
; TIMER_1 intervallein sitten katsotaan, tuliko ajastimen aikana kopautusta
; vai ei (hitaampi kello, saa rytmin esim. puolen sekunnin tarkkuudella)
isr_pcint0:
interrupt_anturi_tarisee:
    CLI
    OUT GIMSK,R1                             ; pinnin interrupt pois päältä
    INC REG_TULOS_KOPUTUKSET                 ; Merkkaa LSB:hen kopautus
    CP REG_TULOS_KOPUTUKSET,REG_OIKEA_TAHTI  ; Tarkista onko saatu oikea rytmi
    BRNE _interrupt_anturi_tarisee_kellot
    CLR REG_TULOS_KOPUTUKSET
    LDI REG_TEMP1,1<<PIN_OIKEA
    OUT PORTB,REG_TEMP1
    LDI REG_TEMP1,1<<PCIE                    ; pinnin interruptit takas päälle
    OUT GIMSK,REG_TEMP1
    reti
_interrupt_anturi_tarisee_kellot:            ; Ei oikea rytmi, kellot käyntiin
    OUT TIMSK,R1                             ; Kellojen interruptit pois päältä
    OUT TCNT0,R1                             ; ajastimen 0 arvo nollaan
    OUT TCNT1,R1                             ; ajastimen 1 arvo nollaan
    LDI REG_TEMP1,1<<TOV0|1<<TOV1            ; putsaa flagit
    OUT TIFR,REG_TEMP1
    LDI REG_TEMP1,1<<TOIE0|1<<TOIE1          ; kellojen interruptit päälle
    OUT TIMSK,REG_TEMP1
    reti

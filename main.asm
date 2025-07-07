; Kääpäkolkutin
.include "tn85def.inc"
.equ ANTURI = PINB0           ; Anturin sisääntulopinni
.equ ULOSTULO_ANTURI = PINB1  ; Signaali siitä että luettiin anturin muutos (debug)
.equ ULOSTULO_KELLO = PINB2   ; Signaali siitä että kello pingasi täyteen (debug)
.equ VIIVE = 0x13             ; noin 16 ms x 19 = 304 ms

;===============================================================================
; Interruptit alkaa osoitteesta 0x0000
.cseg
.org 0x0000
rjmp pohjusta      ; RESET: Virta päälle -> mainloop
reti               ; INT0
rjmp nappi_muutos  ; PCINT0 pin change interrupt request
reti               ; TIMER1_COMPA
reti               ; TIMER1_OVF
rjmp kello_valmis  ; TIMER0_OVF
reti               ; EE_RDY
reti               ; ANA_COMP
reti               ; ADC
reti               ; TIMER1_COMPB
reti               ; TIMER0_COMPA
reti               ; TIMER0_COMPB
reti               ; WDT
reti               ; USI_START
reti               ; USI_OVF

;===============================================================================
; Pohjusta asetukset
pohjusta:
    CLI
    ; Lamppu ulostulona, kaikki muut sisääntulona
    LDI R16,1<<ULOSTULO_ANTURI|1<<ULOSTULO_KELLO
    OUT DDRB,R16
    LDI R18,VIIVE
    ; Keskeytysrekisterit
pohjusta_input:
    LDI R16,1<<PCIE
    OUT GIMSK,R16
    LDI R16,1<<ANTURI
    OUT PCMSK,R16
pohjusta_kello:
    LDI R16,0x00
    OUT TIMSK,R16 ; ei vielä päällä
    OUT TCCR0A,R16
    LDI R17,(1<<CS01|1<<CS00) ; 1 & 0 ~16 ms
    OUT TCCR0B,R17
    OUT TIFR,R16
    OUT TCNT0,R16


mainloop:
    SEI
    SLEEP
    rjmp mainloop


pulssi_anturi:
    CBI PORTB,ULOSTULO_ANTURI
    SBI PORTB,ULOSTULO_ANTURI
_pulssi_anturi_odota: ; Odota että pinni nousee
    SBIS PINB,ULOSTULO_ANTURI
    RJMP _pulssi_anturi_odota
    CBI PORTB,ULOSTULO_ANTURI
    RET


pulssi_kello:
    CBI PORTB,ULOSTULO_KELLO
    SBI PORTB,ULOSTULO_KELLO
_pulssi_kello_odota: ; Odota että pinni nousee
    SBIS PINB,ULOSTULO_KELLO
    RJMP _pulssi_kello_odota
    CBI PORTB,ULOSTULO_KELLO
    RET


nappi_muutos:
    CLI
    LDI R16,0x00 ; pinnin interrupt pois päältä
    OUT GIMSK,R16
    RCALL pulssi_anturi
    OUT TCNT0,R16    ; ajastimen arvo nollaan
    LDI R17,1<<TOV0  ; putsaa flagi
    OUT TIFR,R17
    LDI R16,1<<TOIE0 ; kellon interrupt päälle
    OUT TIMSK,R16
    reti


kello_valmis:
    CLI
    DEC R18 ; Yksi overflow liian lyhyt, otetaan muutama
    BREQ kello_valmis_valmis
    reti
kello_valmis_valmis:
    LDI R18,VIIVE
    RCALL pulssi_kello
    LDI R16,1<<PCIF ; Putsaa pinnin interruptflagi
    OUT GIFR,R16    ; (niitä kuitenkin tullut odotellessa)
    LDI R16,0x00
    OUT TIMSK,R16   ; kellon interruptit pois päältä
    LDI R16,1<<PCIE ; pinnin interruptit takas päälle
    OUT GIMSK,R16
    reti

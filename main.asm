; Testaa interrupteja.
.include "tn85def.inc"
.equ NAPPI = PINB0
.equ LAMPPU = PINB1
.equ KELLO = PINB2
.equ VIIVE = 0x15

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
    LDI R16,1<<LAMPPU|1<<KELLO
    OUT DDRB,R16
    LDI R18,VIIVE
    ; Keskeytysrekisterit
pohjusta_input:
    LDI R16,1<<PCIE
    OUT GIMSK,R16
    LDI R16,1<<NAPPI
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


pulssi:
    CBI PORTB,LAMPPU
    SBI PORTB,LAMPPU
_pulssi_odota: ; Odota että pinni nousee
    SBIS PINB,LAMPPU
    RJMP _pulssi_odota
    CBI PORTB,LAMPPU
    RET
    
pulssi_kello:
    CBI PORTB,KELLO
    SBI PORTB,KELLO
_pulssi_kello_odota: ; Odota että pinni nousee
    SBIS PINB,KELLO
    RJMP _pulssi_kello_odota
    CBI PORTB,KELLO
    RET


nappi_muutos:
    CLI
    LDI R16,0x00 ; pinnin interrupt pois päältä
    OUT GIMSK,R16
    RCALL pulssi
    OUT TCNT0,R16
    LDI R17,1<<TOV0 ; putsaa flagi
    OUT TIFR,R17
    LDI R16,1<<TOIE0 ; kellon interrupt päälle
    OUT TIMSK,R16
    reti

kello_valmis:
    CLI
    DEC R18
    BREQ kello_valmis_valmis
    reti
kello_valmis_valmis:
    LDI R18,VIIVE
    RCALL pulssi_kello
    LDI R16,1<<PCIF
    OUT GIFR,R16
    LDI R16,0x00
    OUT TIMSK,R16 ; pois päältä
    LDI R16,1<<PCIE ; takas päälle
    OUT GIMSK,R16
    reti

; Kääpäkolkutin
.include "tn85def.inc"
.equ ANTURI = PINB0           ; Anturin sisääntulopinni
.equ ULOSTULO_ANTURI = PINB1  ; Signaali siitä että luettiin anturin muutos (debug)
.equ ULOSTULO_KELLO = PINB2   ; Signaali siitä että kello pingasi täyteen (debug)
.equ ULOSTULO_KAJARI = PINB3  ; Kaiutin
.equ VIIVE_ANTURI = 0x12      ; noin 16 ms x 19 = 304 ms
.equ VIIVE_TARKISTUS = 0x1E   ; noin 17.4 ms x 29 = 505 ms
.equ OIKEA_RIVI = 0b00001101  ; koputusrytmi, puolen sekunnin intervalleissa
.def REG_VIIVE_ANTURI=R5      ; anturin cooldown
.def REG_VIIVE_TARKISTUS=R6   ; rytmin tarkistustahti
.def REG_TULOS_KOPUTUKSET=R7  ; Koputustulokset, bittinumero = intervalli-indeksi
.def REG_OIKEA_TAHTI=R8       ; referenssiarvo johon verrataan

;===============================================================================
; Interruptit alkaa osoitteesta 0x0000
.cseg
.org 0x0000
rjmp pohjusta      ; RESET: Virta päälle -> mainloop
reti               ; INT0
rjmp nappi_muutos  ; PCINT0 pin change interrupt request
reti               ; TIMER1_COMPA
rjmp toinen_kello_valmis  ; TIMER1_OVF
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
    CLI ; Ei vahingossakaan mene interruptiin
    LDI R16,1<<ULOSTULO_ANTURI|1<<ULOSTULO_KELLO|1<<ULOSTULO_KAJARI
    OUT DDRB,R16
    LDI R16,VIIVE_ANTURI
    MOV REG_VIIVE_ANTURI,R16
    LDI R16,VIIVE_TARKISTUS
    MOV REG_VIIVE_TARKISTUS,R16
    LDI R16,OIKEA_RIVI
    MOV REG_OIKEA_TAHTI,R16
    LDI R16,0x00
    MOV REG_TULOS_KOPUTUKSET,R16
pohjusta_input:
    LDI R16,1<<PCIE
    OUT GIMSK,R16
    LDI R16,1<<ANTURI
    OUT PCMSK,R16
pohjusta_kello:
    LDI R16,0x00
    OUT TCCR0A,R16
    LDI R17,(1<<CS01|1<<CS00) ; 1 & 0 ~16 ms
    OUT TCCR0B,R17
    OUT TIFR,R16
    OUT TCNT0,R16
pohjusta_kello2:
    LDI R17,1<<CS12|1<<CS11|1<<CS10 ; 2 & 1 & 0 ~17.4 ms
    OUT TCCR1,R17                   ; eli 29 on 0,5046 s
    LDI R17,1<<TOIE1
    OUT TCNT1,R16
    OUT TIMSK,R17


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
    LDI R16,0x00         ; pinnin interrupt pois päältä
    OUT GIMSK,R16
    OUT TIMSK,R16        ; Kellojen interruptit pois päältä
    RCALL pulssi_anturi
    OUT TCNT0,R16        ; ajastimen 0 arvo nollaan
    OUT TCNT1,R16        ; ajastimen 1 arvo nollaan
    LDI R17,1<<TOV0|1<<TOV1 ; putsaa flagit
    OUT TIFR,R17
    LDI R16,1<<TOIE0|1<<TOIE1  ; kellojen interruptit päälle
    OUT TIMSK,R16
    reti


kello_valmis:
    CLI
    DEC REG_VIIVE_ANTURI ; Yksi overflow liian lyhyt, otetaan muutama
    BREQ kello_valmis_valmis
    reti
kello_valmis_valmis:
    LDI R16,VIIVE_ANTURI
    MOV REG_VIIVE_ANTURI,R16
    RCALL pulssi_kello
    LDI R16,1<<PCIF ; Putsaa pinnin interruptflagi
    OUT GIFR,R16    ; (niitä kuitenkin tullut odotellessa)
    LDI R17,1<<TOV0|1<<TOV1 ; putsaa kellon flagit
    LDI R16,1<<TOIE1
    OUT TIMSK,R16
    LDI R16,1<<PCIE ; pinnin interruptit takas päälle
    OUT GIMSK,R16
    reti

toinen_kello_valmis:
    CLI
    DEC REG_VIIVE_TARKISTUS
    BREQ toinen_kello_valmis_valmis
    reti
toinen_kello_valmis_valmis:
    LDI R16,VIIVE_TARKISTUS
    MOV REG_VIIVE_TARKISTUS,R16
    SBI PINB,ULOSTULO_KAJARI
    reti

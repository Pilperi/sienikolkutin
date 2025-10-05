; Kääpäkolkutin
.include "tn85def.inc"
.equ ANTURI = PINB0             ; Anturin sisääntulopinni
.equ DEBUG_PIN_ANTURI = PINB1   ; Signaali siitä että luettiin anturin muutos (debug)
.equ DEBUG_PIN_KELLO_0 = PINB2  ; Signaali siitä että kello pingasi täyteen (debug)
.equ DEBUG_PIN_KELLO_1 = PINB3  ; Signaali siitä että hitaampi kello pingasi
.equ VIIVE_ANTURI = 0x12        ; noin 16 ms x 19 = 304 ms
.equ VIIVE_TARKISTUS = 0x1E     ; noin 17.4 ms x 29 = 505 ms
.equ OIKEA_RIVI = 0b00001101    ; koputusrytmi, puolen sekunnin intervalleissa
; Rekisterimääritykset
; Laskurit
.def REG_VIIVE_ANTURI=R5        ; anturin cooldownin arvo
.def REG_VIIVE_RYTMI=R6         ; rytmin tarkistustahdin arvo
; Tulosrekisterit
.def REG_TULOS_KOPUTUKSET=R7    ; Koputustulokset, bittinumero = intervalli-indeksi
; Vakioarvot
.def REG_OIKEA_TAHTI=R8         ; referenssiarvo johon tulosta verrataan
; Sekalaiset työrekisterit
.def REG_TEMP1 = R16
.def REG_TEMP2 = R17

;===============================================================================
; Interruptit alkaa osoitteesta 0x0000
.cseg
.org 0x0000
rjmp pohjusta                 ; RESET: Virta päälle -> mainloop
reti                          ; INT0
rjmp interrupt_anturi_tarisee ; PCINT0 pin change interrupt request
reti                          ; TIMER1_COMPA
rjmp interrupt_kello_1_valmis ; TIMER1_OVF
rjmp interrupt_kello_0_valmis ; TIMER0_OVF
reti                          ; EE_RDY
reti                          ; ANA_COMP
reti                          ; ADC
reti                          ; TIMER1_COMPB
reti                          ; TIMER0_COMPA
reti                          ; TIMER0_COMPB
reti                          ; WDT
reti                          ; USI_START
reti                          ; USI_OVF

;===============================================================================
; Pohjusta asetukset
pohjusta:
    CLI
    LDI REG_TEMP1,VIIVE_ANTURI           ; Cooldown-laskuri (timer 0)
    MOV REG_VIIVE_ANTURI,REG_TEMP1
    LDI REG_TEMP1,VIIVE_TARKISTUS        ; Rytmilaskuri (timer 1)
    MOV REG_VIIVE_TARKISTUS,REG_TEMP1
    LDI REG_TEMP1,OIKEA_RIVI             ; Oikea rytmi johon verrataan
    MOV REG_OIKEA_TAHTI,REG_TEMP1
    LDI REG_TEMP1,0x00                   ; Mitattu rytmi
    MOV REG_TULOS_KOPUTUKSET,REG_TEMP1
pohjusta_anturi_interrupt:               ; Anturipinnin muutos aiheuttaa interruptin
    LDI REG_TEMP1,1<<PCIE
    OUT GIMSK,REG_TEMP1
    LDI REG_TEMP1,1<<ANTURI
    OUT PCMSK,REG_TEMP1
timer_0_paalle:
    LDI REG_TEMP1,0x00
    OUT TCCR0A,REG_TEMP1
    LDI REG_TEMP2,(1<<CS01|1<<CS00)       ; 1 & 0 ~16 ms
    OUT TCCR0B,REG_TEMP2
    OUT TIFR,REG_TEMP1
    OUT TCNT0,REG_TEMP1
timer_1_paalle:
    LDI REG_TEMP2,1<<CS12|1<<CS11|1<<CS10 ; 2 & 1 & 0 ~17.4 ms
    OUT TCCR1,REG_TEMP2                   ; eli 29 on 0,5046 s
    LDI REG_TEMP2,1<<TOIE1
    OUT TCNT1,REG_TEMP1
    OUT TIMSK,REG_TEMP1                   ; Ei vielä interruptia, odota tärinää
    RJMP mainloop

mainloop:
    SEI
    SLEEP
    rjmp mainloop


debug_pulssi_anturi:
    IN REG_TEMP1,DDRB
    ORI REG_TEMP1,1<<ULOSTULO_ANTURI
    OUT DDRB,REG_TEMP1
    CBI PORTB,DEBUG_PIN_ANTURI
    SBI PORTB,DEBUG_PIN_ANTURI
_debug_pulssi_anturi_odota:
    SBIS PINB,DEBUG_PIN_ANTURI
    RJMP _debug_pulssi_anturi_odota
    CBI PORTB,DEBUG_PIN_ANTURI
    RET

; Timer 0 (cooldown) debug-pulssi fyysiseen pinniin
debug_pulssi_kello_0:
    CBI PORTB,DEBUG_PIN_KELLO_0
    SBI PORTB,DEBUG_PIN_KELLO_0
_debug_pulssi_kello_0_odota:
    SBIS PINB,DEBUG_PIN_KELLO_0
    RJMP _debug_pulssi_kello_0_odota
    CBI PORTB,DEBUG_PIN_KELLO_0
    RET

; Timer 1 (rytmi) debug-pulssi fyysiseen pinniin
debug_pulssi_kello_1:
    CBI PORTB,DEBUG_PIN_KELLO_1
    SBI PORTB,DEBUG_PIN_KELLO_1
_debug_pulssi_kello_1_odota:
    SBIS PINB,DEBUG_PIN_KELLO_1
    RJMP _debug_pulssi_kello_1_odota
    CBI PORTB,DEBUG_PIN_KELLO_1
    RET

; Kopautuksen interrupt:
; Kun unitilassa tärinäanturiin tulee tärähdys, laitetaan
; tärinäinterrupti pois päältä TIMER_0 interruptiajan ajaksi.
; Anturi jää heilumaan, joten muuten tulisi tosi monta interruptia
; yhdestä kopautuksesta.
; TIMER_1 intervallein sitten katsotaan, tuliko ajastimen aikana kopautusta
; vai ei (hitaampi kello, saa rytmin esim. puolen sekunnin tarkkuudella)
interrupt_anturi_tarisee:
    CLI
    INC REG_TULOS_KOPUTUKSET        ; Merkkaa LSB:hen kopautus
    LDI REG_TEMP1,0x00              ; pinnin interrupt pois päältä
    OUT GIMSK,REG_TEMP1
    OUT TIMSK,REG_TEMP1             ; Kellojen interruptit pois päältä
    RCALL debug_pulssi_anturi       ; (debug-pulssi)
    OUT TCNT0,REG_TEMP1             ; ajastimen 0 arvo nollaan
    OUT TCNT1,REG_TEMP1             ; ajastimen 1 arvo nollaan
    LDI REG_TEMP2,1<<TOV0|1<<TOV1   ; putsaa flagit
    OUT TIFR,REG_TEMP2
    LDI REG_TEMP1,1<<TOIE0|1<<TOIE1 ; kellojen interruptit päälle
    OUT TIMSK,REG_TEMP1
    reti

; Interruptrutiini TIMER 0:lle
; Odotetaan pieni hetki että tärinäanturi lakkaa tärisemästä.
interrupt_kello_0_valmis:
    CLI
    DEC REG_VIIVE_ANTURI          ; Yksi overflow liian lyhyt, otetaan muutama
    BREQ _kello_0_valmis
    reti
_kello_0_valmis:
    LDI REG_TEMP1,VIIVE_ANTURI
    MOV REG_VIIVE_ANTURI,REG_TEMP1
    RCALL debug_pulssi_kello_0
    LDI REG_TEMP1,1<<PCIF         ; Putsaa pinnin interruptflagi
    OUT GIFR,REG_TEMP1            ; (niitä kuitenkin tullut odotellessa)
    LDI REG_TEMP2,1<<TOV0|1<<TOV1 ; putsaa kellon flagit
    LDI REG_TEMP1,1<<TOIE1
    OUT TIMSK,REG_TEMP1
    LDI REG_TEMP1,1<<PCIE         ; pinnin interruptit takas päälle
    OUT GIMSK,REG_TEMP1
    reti

; Interruptrutiini TIMER 1:lle
; Katsotaan kerran rytmiaskeleessa, onko tullut kopautuksia
; ja siirrytään seuraavaan aika-askeleeseen.
interrupt_kello_1_valmis:
    CLI
    DEC REG_VIIVE_RYTMI
    BREQ _kello_1_valmis
    reti
_kello_1_valmis:
    LDI REG_TEMP1,VIIVE_RYTMI
    MOV REG_VIIVE_RYTMI,REG_TEMP1
    RCALL debug_pulssi_kello_1
    LSL REG_TULOS_KOPUTUKSET
    BREQ nollaa_koputukset
    reti
nollaa_koputukset:
    CLR REG_TULOS_KOPUTUKSET
    reti
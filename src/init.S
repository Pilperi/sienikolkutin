; Datan alustusrutiinit:
; rodata, data ja BSS alustukset kuten on tapana
#define __SFR_OFFSET 0
#include <avr/io.h>
#include "rekisterit.h"

.global init_data
.section .text.init

init_data:
    LDI R18,0xAA
    MOV REG_TULOS_KOPUTUKSET,R18
    ; Sekä FLASH että SRAM rodata ja data peräkanaa,
    ; joten voidaan kirjoittaa yhdessä pötkössä:
    ; aloitetaan rodata alusta ja lopetetaan data loppuun
    LDI ZL,lo8(pmem_rodata_start_la)  ; Lukuosoite (LPM vaatii Z)
    LDI ZH,hi8(pmem_rodata_start_la)
    LDI YL,lo8(sram_rodata_start)     ; Kirjoitusosoite
    LDI YH,hi8(sram_rodata_start)
    LDI XL,lo8(sram_data_end)         ; Kirjoituksen lopetusosoite
    LDI XH,hi8(sram_data_end)
    RJMP init_data_siirto_loop_check
init_data_siirto_loop:
    LPM R18,Z+                        ; Lue FLASH Z:sta
    ST Y+,R18                         ; Kirjoita SRAM Y:hyn
init_data_siirto_loop_check:          ; Jatka kunnes Y==X
    CP YL,XL
    CPC YH,XH
    BRNE init_data_siirto_loop
    ; BSS heti data jälkeen, jatketaan samalla pointterilla
    ; kirjoittamista BSS loppuun asti
init_data_sec_bss:                    ; Alustamaton (nollalla alustettu) data
    LDI XL,lo8(sram_bss_end)          ; Kirjoituksen lopetusosoite
    LDI XH,hi8(sram_bss_end)
    RJMP init_bss_fill_loop_check
init_bss_fill_loop:
    ST Y+,R1                          ; Kirjoita SRAM 0x00
init_bss_fill_loop_check:
    CP YL,XL
    CPC YH,XH
    BRNE init_bss_fill_loop
    RET                               ; init_data END

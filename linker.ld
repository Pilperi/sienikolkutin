/* Linkerfile attiny85 */

MEMORY
{
    /* Ohjelmamuisti ainoa johon voidaan kirjoittaa */
    program_memory : org = 0x0000, len = 0x0FFF
    /*
    SRAM hoidettu virtuaalisen offsetin kautta, laitteessa alkaa 0x0060.
    Vaikkei voida ohjelmoidessa kirjoittaa dataa, voidaan silti allokoida
    ja tarkistaa että mahtuuhan sinne mitä meinataan tuupata.
    Kaikki normaalit työkalut hoitaa homman niin että se on offsetilla
    0x800000 jolloin tiedetään että kyseessä on oma muistialueensa.
    Muille vastaaville hassumuisteille (EEPROM) on vastaavat offsetit.
     */
    sram : org = 0x00800060, len = 512
}

SECTIONS
{
    /* Suoritettava koodi */
	. = ORIGIN(program_memory);
        .text : {
            KEEP(*.o(.isr_vector)); /* Koodin alussa interrupt-jumpit */
            *.o(.text.isr);         /* Jumppien kohteet lähellä */
            *.o(.text.init);        /* Init-rutiini lähellä */
            *.o(.text*);            /* Kaikki muu suoritettava koodi */
        } >program_memory
	/* Datalohko, kopioidaan SRAM puolelle */
    /* pmem_XXX_start_la : osoite program_memory-puolella */
    /* sram_XXX_start    : osoite SRAM-puolella */
        /* Vakiot */
        .rodata : {
            pmem_rodata_start_la = LOADADDR(.rodata);
            sram_rodata_start = .;
	        *.o(.rodata);
            *.o(.rodata*);
            sram_rodata_end = .;
            } >sram AT >program_memory
        /* Alustetut muuttujat */
        .data : {
            pmem_data_start_la = LOADADDR(.data);
	        sram_data_start = .;
            *.o(.data);
            *.o(.data*);
            sram_data_end = .;
            } >sram AT >program_memory
        /* Alustamattomat muuttujat, ei tarvita program_memory-osoitetta */
        .bss : {
	        sram_bss_start = .;
            *.o(.bss);
            *.o(.bss*);
            sram_bss_end = .;
            } >sram
}
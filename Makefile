# 2026-08-03

#########################################################################
.PHONY: all
.PHONY: build
.PHONY: newbin
.PHONY: clean
.PHONY: clear
.PHONY: show
.PHONY: send


#########################################################################
#
# Perusmääritykset: kohdekansiot, käännösflagit ymv
#
#########################################################################
SHELL=/bin/bash

# Kohteen suoritinarkkitehtuuri
MMCU=attiny85
TARGET_ARCH=avr2

# Lähdekoodikansio
KOODIKANSIO=src

# Käännöksen tulokset
KOHDEKANSIO=build_artifacts
KOHDEBIN=$(KOHDEKANSIO)/ulos.bin
KOHDE_ELF=$(KOHDEKANSIO)/ulos.elf

# Assemblyn kääntäjä ja sen vaatimat argumentit (suorittimen tyyppi ymv)
# !! avr-as on olemassa mutta se tekee jotain ihan muuta älä käytä
COMP_AS=avr-gcc
COMPFLAGS_AS=-mmcu=$(MMCU) -Os -c -I lib -I include/**
# C-kääntäjä ja sen vaatimat argumentit
COMP_CC=avr-gcc
COMPFLAGS_C=-mmcu=$(MMCU) -Os -c -I lib -I include/**

# Binäärin pyörittely eri muodoissa (elf -> bin)
BINCOPY=avr-objcopy
BINFLAGS=-g -O binary

# Linkkeri ja linkkeriskripti
LINKERSCRIPT=linker.ld
LINKER=avr-ld
LINKERFLAGS=-T $(LINKERSCRIPT)

# Lista kaikesta C-lähdekoodista
C_SOURCES := $(shell find $(KOODIKANSIO) -name '*.c')
C_FILENAMES := $(notdir $(C_SOURCES))
# Lista assembly-lähdekoodista
S_SOURCES := $(shell find $(KOODIKANSIO) -name '*.S')
S_FILENAMES := $(notdir $(S_SOURCES))
# Käännetyt versiot
# C:stä käännetyt .c.o ja assemblystä .S.o ja nämä uudelleennimetään myöhemmin sitten .o
C_OBJECTS := $(addprefix $(KOHDEKANSIO)/,$(C_FILENAMES:%.c=%.c.o))
S_OBJECTS := $(addprefix $(KOHDEKANSIO)/,$(S_FILENAMES:%.S=%.S.o))

# Mitkä tulokset otetaan C-koodista ja mitkä assemblystä
O_OBJECTS_FROM_C = $(KOHDEKANSIO)/main.o $(KOHDEKANSIO)/shiftreg.o
O_OBJECTS_FROM_S = $(KOHDEKANSIO)/init.o $(KOHDEKANSIO)/isr.o $(KOHDEKANSIO)/isr_pcint0.o $(KOHDEKANSIO)/debug_koputukset_sregiin.o
# Kirjastot jotka otetaan mukaan
LIBS = 

#########################################################################

all: $(KOHDEKANSIO) newbin $(C_OBJECTS) $(S_OBJECTS) $(KOHDEBIN) $(LINKERSCRIPT)
build: all

#########################################################################
#
# Kohdetiedostojen hallinta: putsaus- ja printtioperaatiot ymv
#
#########################################################################

# Build-kansion luonti jos uupuu
$(KOHDEKANSIO):
	mkdir $(KOHDEKANSIO)

# "Poista" käännöstuotteet, jos olemassa.
# Linkataan joka kerta uudelleen.
newbin: $(KOHDEKANSIO)
ifneq ("$(wildcard $(KOHDEBIN))","")
	rm $(KOHDEBIN)
endif
ifneq ("$(wildcard $(KOHDE_ELF))","")
	rm $(KOHDE_ELF)
endif

# Poista väliaikatiedostot .o ja .elf
clean:
ifneq ("$(wildcard $(KOHDEKANSIO)/*.o)","")
	@echo
	@echo "Poistetaan .o"
	rm $(KOHDEKANSIO)/*.o
endif
ifneq ("$(wildcard $(KOHDEKANSIO)/*.elf)","")
	@echo
	@echo "Poistetaan .elf"
	rm $(KOHDEKANSIO)/*.elf
endif

# Poista kaikki kohdekansion sisältä
clear: $(KOHDEKANSIO)
ifneq ("$(wildcard $(KOHDEKANSIO)/*)","")
	@echo 
	@echo Tyhjätään $(KOHDEKANSIO)
	rm $(wildcard $(KOHDEKANSIO)/*)
else
	@echo 
	@echo $(KOHDEKANSIO) on jo tyhjä
endif

# Näytä mitä tuli
show:
	@echo 
	@echo C_SOURCES $(C_SOURCES)
	@echo C_OBJECTS $(C_OBJECTS)
	@echo S_SOURCES $(S_SOURCES)
	@echo S_OBJECTS $(S_OBJECTS)
	@echo O_OBJECTS_FROM_C $(O_OBJECTS_FROM_C)
	@echo O_OBJECTS_FROM_S $(O_OBJECTS_FROM_S)
	test -f $(KOHDE_ELF) && (echo; echo ELF; avr-objdump -D -m $(TARGET_ARCH) -s $(KOHDE_ELF))
	test -f $(KOHDEBIN) && (echo; echo BIN; od -A x --endian=big -t x1 $(KOHDEBIN))

# Lähetä avrdudella laitteelle
send: $(KOHDEBIN)
	@echo 
	avrdude -c usbtiny -p $(MMCU) -n -U signature:r:/dev/null
	avrdude -c usbtiny -p $(MMCU) -U flash:w:$(KOHDEBIN):a

#########################################################################
#
# Koodin kääntö ja linkkaustargetit
#
#########################################################################

# Binäärin muodostus elffistä kopiointiohjelmalla
$(KOHDEBIN): $(KOHDE_ELF)
	@echo 
	$(BINCOPY) $(BINFLAGS) $(KOHDE_ELF) $(KOHDEBIN)

# Linkkaa .o-tiedostot linkkeriskriptillä elffiksi.
# O_OBJECTS_FROM_C ja O_OBJECTS_FROM_S sovelluskohtaisia.
$(KOHDE_ELF): $(O_OBJECTS_FROM_C) $(O_OBJECTS_FROM_S) $(LIBS)
	@echo Link ELF
	@echo O_OBJECTS_FROM_C $(O_OBJECTS_FROM_C)
	@echo O_OBJECTS_FROM_S $(O_OBJECTS_FROM_S)
	$(LINKER) $(LINKERFLAGS) -o $(KOHDE_ELF) $(O_OBJECTS_FROM_C) $(O_OBJECTS_FROM_S) $(LIBS)

$(O_OBJECTS_FROM_C): $(C_OBJECTS)
	@echo 
	@echo C_OBJECTS $(C_OBJECTS)
	test "$@" != "" && cp $(patsubst %.o,%.c.o,$@) $@
$(O_OBJECTS_FROM_S): $(S_OBJECTS)
	@echo 
	@echo S_OBJECTS $(S_OBJECTS)
	test "$@" != "" && cp $(patsubst %.o,%.S.o,$@) $@

# Käännä kaikki .c-tiedostot .c.o-tiedostoiksi
$(C_OBJECTS): $(C_SOURCES)
	$(COMP_CC) $(COMPFLAGS_C) $(C_COMPILER_TARGET_FLAGS) -o $@ $(addprefix $(KOODIKANSIO)/,$(notdir $(patsubst %.c.o,%.c,$@)))
# Käännä kaikki .S-tiedostot .S.o-tiedostoiksi
$(S_OBJECTS): $(S_SOURCES)
	$(COMP_AS) $(COMPFLAGS_AS) -o $@ $(addprefix $(KOODIKANSIO)/,$(notdir $(patsubst %.S.o,%.S,$@)))

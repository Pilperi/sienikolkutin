/* Rekisterien määritykset.

Koko homma aika "herran haltuun", koska kaikki nojaa siihen ettei
ulkoiset kirjastofunktiot käytä kategoriaa "call-saved registers"
vaan oma koodi on ainoa joka sinne pistää mitään globaalien muuttujien
roolissa olevia arvoja...
*/
#ifndef REKISTERIT_H
#define REKISTERIT_H

#define REG_VIIVE_ANTURI     R5
#define REG_VIIVE_RYTMI      R6
#define REG_TULOS_KOPUTUKSET R7
#define REG_OIKEA_TAHTI      R8
#define REG_TEMP1            R18
#define REG_TEMP2            R19
#define REG_TEMP3            R20


#endif // REKISTERIT_H

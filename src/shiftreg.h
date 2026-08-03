/* Siirtorekisterioperaatiot */
#ifndef SHIFTREG_H
#define SHIFTREG_H

// Oletuksena 74595 mutta voi vaihtaa 74164
// 595 vaatii yhden kellotuksen enemmän.
#ifndef SHIFTREG_164
#define SHIFTREG_595
#endif

// Siirtorekisterien pinniconfigit ymv
void shiftreg_init(void);

// Tyhjää siirtorekisteri (74595)
void shiftreg_clear(void);

// Lähetä kahdeksan bittiä dataa, MSB ensin
void shiftreg_laheta(uint8_t data);

#endif // SHIFTREG_H

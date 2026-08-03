/* Fyysisten pinnien mäppäys toiminnallisuuksiin
 */
#ifndef PINNIT_H
#define PINNIT_H

#include <avr/io.h>

#define PIN_SREG_DAT PINB0
#define PIN_SREG_CLR PINB1 // Jompi kumpi, clr tai output enable
#define PIN_SREG_OE  PINB1 // Jompi kumpi, clr tai output enable
#define PIN_SREG_CLK PINB2
#define PIN_ANTURI   PINB3
#define PIN_OIKEA    PINB4 // Oikein: 1 (lähde)
#define PIN_VAARA    PINB4 // Väärin: 0 (nielu)

#endif // PINNIT_H

### 2025-07-07

# Käävistä tehdyt valaisimet

Nappasin metsästä muutaman käävän, verkkiksen alelaarista muutaman ledipolttimon, ja ajattelin yhdistää nämä toisiinsa. Leikkasin käävät auki, kaiversin ontoksi ja asensin niihin polttimokannat.
Ajatuksena pistää lisäksi mukaan ATtiny85 aivoiksi, lukemaan käävän sisään asennettua tärinäsensoria. Kun käävistä johonkuhun on koputettu oikeaan tahtiin, valot menee päälle/pois.

## Komponentit
- [ATtiny85](https://www.microchip.com/en-us/product/attiny85) suorittimena
- [Adafruitin tärinäsensori](https://www.adafruit.com/product/1766)
- Joku verkkiksen alelaarista noukittu G4-kantainen LED-polttimo (12 V / 230 lm / 2 W)
- Muutama kääpä metsästä, ei semmosia missä matoja
- [Rele](https://www.digikey.fi/fi/products/detail/omron-electronics-inc-emc-div/G5V-1-T90-DC5/6650355), matalan jännitteen triggeri ja matalahko maksimivirta. Katsoo kestääkö...

## Nootteja

### Tärinäsensorilla kestää
Tärinäsensori toimii niin, että putken sisällä on jousi jonka keskellä pinni. Kun kokonaisuus tärisee, jousi muodostaa kontaktin keskipinnin kanssa. Se on siitä sitten helppo kytkeä suorittimen pinniin ja jäädä odottelemaan pinnitilan muutosinterruptia.
Mutta mittarin rakenteesta johtuen jousi jatkaa huojumista jonkin aikaa, mikä muodostaa vähän haasteita tulkitsemiseen kun muutosinterrupteja tulee aika monta. Yritin aluksi joitain ratkaisuja joissa tärinän muodostama kontakti pumppaa kondensaattoria,
ja vasta kun tärinää on tullut tarpeeksi konkan jännite on riittävä interruptiin. Samaten koklasin laittaa väliin Zener-diodin, jotta saisi mukaan vain tärinän (tai kondensaattorin jännitteen) huippuarvot. Näistä kumpikaan ei oikein toiminut, kun signaaleja tuli silti kovin monta. Ois varmaan tarvinnu olla tosi tarkkaan mitoitettu RC-piiri, mutten jaksanut säätää.
Muutenkin ongelmana se, ettei käävän sisään kovin isoja komponentteja mahdu.

Tein nyt sitten niin, että pinnimuutos triggeröi interruptin, ja interruptin purkamisessa laitetaan pinni-interruptit pois päältä. Tällöin jousen huojunta ei aiheuta enempää tilamuutosten bongailuja.
Muutosinterruptin poislaiton yhteydessä laitetaan ajastin-interrupti päälle. Ajastin hyrrää oman aikansa, ja valmistuessaan aiheuttaa interruptin. Sen purkamisessa sitten vastaavasti laitetaan ajastimen interrupti pois päältä, ja pinnin interrupti takaisin päälle. Ajatuksena laittaa ajastimeen sellainen arvo, että jousi on sinä aikana lakannut huojumasta, ja voidaan bongata pelkät uudet koputukset.
Samalla saadaan määriteltyä pienin validi aika koputusten välissä (ts. turborummutus ei rämppää valoja ees taas nopeaan tahtiin tmv).

### Joissain käävissä on matoja
Yllättävän harvassa, mutta on kuitenkin. Aika äkkiä ne toukat tajuaa ettei kääpä enää ole missä pitäisi ja lähtee kömpimään käävästä ulos, onneksi pidin niitä omassa pienessä boksissa kuivamassa juuri tämmösten varalta. Tuuppasin niihin myös isopropanolia kaiken varalta.
Ehkä ne matoisatkin käävät ois ollut ok kunhan madot kömpiny veks, etenkin jos kemikaaleilla kyllästetty, mutten jaksanut ihmetellä. Valinnanvaraa kuitenkin on metsä täynnä.

Käävät ei kuulu jokamiehenoikeuksiin.

### Kääpä on ihan kiva työstettävä
Kääpä on kova vain ulkokuorestaan, sen kun saa dremelöityä katki niin kuivan käävän sisuskalut on tosi helppo kaivertaa veks kaiverrustaltalla. Semmoista huokoista massaa.

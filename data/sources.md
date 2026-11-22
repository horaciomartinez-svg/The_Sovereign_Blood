# Fuentes de datos — The Sovereign's Blood

| Campo | Valor |
|---|---|
| **Entregable** | `data/sources.md` (GDD §7.8 / §4.1) |
| **Autor** | AG-1 (Historian / Data) |
| **Fecha** | 2026-11-21 |
| **Alcance** | Fase 0: Escenario 1 «Dos Coronas» (1337); Fase 2: Mapa §10.1 (`map_borders.json`) y `portrait` §10.2; Fase 3: escenarios 1402/1453, 23 facciones, 3 años de regiones, eventos y fuentes (§11); Fase 4: mercancías y `recruit_goods` (§13) |
| **Datasets cubiertos** | `factions.json` (23), `regions.json` (47×3 años), `characters.json` (175), `units.json` (con `recruit_goods`), `trade_goods.json` (10), `events_1337/1402/1453.json`, `scenarios/scenario_1337/1402/1453.json`, `map_borders.json`, `schema/*.schema.json` |

## 1. Regla de oro y método

1. Cada cifra histórica de los datasets lleva `source` con URL estable (Wikipedia EN/ES/FR, preferentemente; las fichas de personaje y de evento incluyen su propia URL).
2. Si no existe una cifra publicada fiable, el valor es una **estimación de diseño** marcada con `"estimate": true` (población y riqueza de las 47 regiones; los stats 1-100 de los 86 personajes son siempre estimación de diseño, por eso todos llevan `"estimate": true`).
3. Las fronteras de 1337 son una **aproximación jugable** al mapa político de la época (fuentes cartográficas de dominio público y tablas de GDD §4.2), simplificada a 47 regiones con adyacencia terrestre/marítima; no pretenden exactitud cartográfica.
4. `died: null` significa «vivo al inicio del escenario (1337)», conforme al ejemplo de GDD §7.1 (Eduardo III nace en 1312 y figura con `died: null`). Las fechas de muerte históricas de los soberanos vivos en 1337 están en la URL de su ficha y se gestionan en partida por el sistema dinástico (§5.3); los personajes ya fallecidos antes de 1337 conservan su año de muerte.
5. Los textos `news` de los eventos son redacción **propia** en español (GDD §1.2): no se transcribe texto de terceros; las URLs solo documentan fechas y hechos.

## 2. Facciones y gobernantes (1337) — GDD §4.2

Las 14 facciones y sus gobernantes siguen la tabla de GDD §4.2; la URL de cada gobernante documenta nombre, fechas y casa. `playable=true` en las 8 primeras (GDD §2.1) — elección explícita de diseño (D-008). Las casas provienen de esa tabla **con dos excepciones de nomenclatura** (D-011, OBS-02) que se mantienen en `characters.json` porque el campo `house` identifica familia/casa histórica, no solo dinastía gobernante:

- **Benedicto XII → `house: "fournier"`**: la tabla de §4.2 marca «—» (el papado no es una dinastía). Se documenta su familia papal (Jacques Fournier, de ahí `fournier`), con el mismo criterio que `clemente_vi` (`roger`). No se inventa una dinastía: `house` = familia/casa.
- **An-Nasir Muhammad → `house: "qalawun"`**: la tabla de §4.2 lo etiqueta «Bahri». La dinastía qalawuní es la línea que encabeza el sultanato Bahri mameluco; `qalawun` es la dinastía concreta y «Bahri» la etiqueta amplia del GDD. Se mantiene `qalawun` y se documenta la equivalencia.

Resultado: 12/14 casas literalmente idénticas a §4.2 y 2/14 con equivalencia histórica documentada (D-011); la validación y la jugabilidad no se ven afectadas.

| # | Facción | Nombre | Gobernante 1337 | Capital | Dueño de la capital en 1337 | Jugable | Fuente del gobernante |
|---|---|---|---|---|---|---|---|
| 1 | `england` | Reino de Inglaterra | Eduardo III | `region_londres` | `england` | sí | https://en.wikipedia.org/wiki/Edward_III_of_England |
| 2 | `france` | Reino de Francia | Felipe VI de Valois | `region_ile_de_france` | `france` | sí | https://en.wikipedia.org/wiki/Philip_VI_of_France |
| 3 | `hre` | Sacro Imperio Romano Germánico | Luis IV de Baviera | `region_praga` | `bohemia` | sí | https://en.wikipedia.org/wiki/Louis_IV,_Holy_Roman_Emperor |
| 4 | `bohemia` | Reino de Bohemia | Juan I de Luxemburgo, rey de Bohemia | `region_praga` | `bohemia` | sí | https://en.wikipedia.org/wiki/John_of_Bohemia |
| 5 | `hungary` | Reino de Hungría | Carlos Roberto de Anjou | `region_buda` | `hungary` | sí | https://en.wikipedia.org/wiki/Charles_I_of_Hungary |
| 6 | `castile` | Reino de Castilla | Alfonso XI el Justiciero | `region_burgos` | `castile` | sí | https://en.wikipedia.org/wiki/Alfonso_XI_of_Castile |
| 7 | `aragon` | Corona de Aragón | Pedro IV el Ceremonioso | `region_barcelona` | `aragon` | sí | https://en.wikipedia.org/wiki/Peter_IV_of_Aragon |
| 8 | `poland` | Reino de Polonia | Casimiro III el Grande | `region_cracovia` | `poland` | sí | https://en.wikipedia.org/wiki/Casimir_III_the_Great |
| 9 | `scotland` | Reino de Escocia | David II de Escocia | `region_edimburgo` | `scotland` | no | https://en.wikipedia.org/wiki/David_II_of_Scotland |
| 10 | `papacy` | Papado de Aviñón | Benedicto XII (Jacques Fournier) | `region_avignon` | `papacy` | no | https://en.wikipedia.org/wiki/Pope_Benedict_XII |
| 11 | `granada` | Sultanato Nazarí de Granada | Yusuf I de Granada | `region_granada` | `granada` | no | https://en.wikipedia.org/wiki/Yusuf_I_of_Granada |
| 12 | `mamluks` | Sultanato Mameluco | An-Nasir Muhammad | `region_el_cairo` | `mamluks` | no | https://en.wikipedia.org/wiki/An-Nasir_Muhammad |
| 13 | `golden_horde` | Horda de Oro | Öz Beg Kan | `region_sarai` | `golden_horde` | no | https://en.wikipedia.org/wiki/%C3%96z_Beg_Khan |
| 14 | `byzantium` | Imperio Bizantino | Andrónico III Paleólogo | `region_constantinopla` | `byzantium` | no | https://en.wikipedia.org/wiki/Andronikos_III_Palaiologos |

**Capital dual Praga (decisión D-010).** GDD §4.2 asigna Praga como capital al Sacro Imperio (Luis IV, Wittelsbach) y a Bohemia (Juan de Luxemburgo). Ambas facciones apuntan a `region_praga`; en 1337 la región pertenece a **Bohemia** (`owner: "bohemia"`). Es históricamente correcto: el emperador residía con frecuencia en Múnich y Praga era la capital del reino de Bohemia. El validador solo exige que la capital exista como región (D-010).

## 3. Personajes (86)

Nombres en español del GDD §4.2; casas dinásticas y parentescos según las fichas de Wikipedia citadas. Los stats (Mando/Astucia/Carisma/Lealtad/Educación, 1-100) son estimaciones de diseño coherentes con el perfil histórico del personaje (GDD §5.3), no datos de fuente.

| id | Personaje | Casa | Facción | Nac. | Fall. | Rol | Fuente |
|---|---|---|---|---|---|---|---|
| `edward_iii_plantagenet` | Eduardo III | plantagenet | `england` | 1312 | — | ruler | https://en.wikipedia.org/wiki/Edward_III_of_England |
| `philippa_de_hainault` | Felipa de Hainault | hainault | `england` | 1314 | — | spouse | https://en.wikipedia.org/wiki/Philippa_of_Hainault |
| `eduardo_el_principe_negro` | Eduardo de Woodstock, el Príncipe Negro | plantagenet | `england` | 1330 | — | heir | https://en.wikipedia.org/wiki/Edward_the_Black_Prince |
| `edward_ii_plantagenet` | Eduardo II | plantagenet | `england` | 1284 | 1327 | relative | https://en.wikipedia.org/wiki/Edward_II_of_England |
| `isabel_de_francia` | Isabel de Francia | capeto | `england` | 1295 | — | relative | https://en.wikipedia.org/wiki/Isabella_of_France |
| `thomas_brotherton` | Thomas de Brotherton, conde de Norfolk | plantagenet | `england` | 1300 | — | relative | https://en.wikipedia.org/wiki/Thomas_of_Brotherton,_1st_Earl_of_Norfolk |
| `robert_morley` | Robert Morley | morley | `england` | 1290 | — | general | https://en.wikipedia.org/wiki/Robert_Morley,_2nd_Baron_Morley |
| `william_montagu` | William Montagu, conde de Salisbury | montagu | `england` | 1301 | — | general | https://en.wikipedia.org/wiki/William_Montagu,_1st_Earl_of_Salisbury |
| `henry_of_grosmont` | Enrique de Grosmont, duque de Lancaster | plantagenet | `england` | 1310 | — | general | https://en.wikipedia.org/wiki/Henry_of_Grosmont,_1st_Duke_of_Lancaster |
| `philippe_vi_de_valois` | Felipe VI de Valois | valois | `france` | 1293 | — | ruler | https://en.wikipedia.org/wiki/Philip_VI_of_France |
| `jeanne_de_bourgogne` | Juana de Borgoña, la Coja | borgona | `france` | 1293 | — | spouse | https://en.wikipedia.org/wiki/Joan_the_Lame |
| `jean_ii_de_france` | Juan II el Bueno | valois | `france` | 1319 | — | heir | https://en.wikipedia.org/wiki/John_II_of_France |
| `charles_de_valois` | Carlos de Valois | valois | `france` | 1270 | 1325 | relative | https://en.wikipedia.org/wiki/Charles_of_Valois |
| `philippe_d_orleans` | Felipe de Valois, duque de Orleans | valois | `france` | 1336 | — | relative | https://en.wikipedia.org/wiki/Philip_of_Valois,_Duke_of_Orl%C3%A9ans |
| `jean_de_marigny` | Jean de Marigny, arzobispo de Rouen | marigny | `france` | 1295 | — | general | https://en.wikipedia.org/wiki/Jean_de_Marigny |
| `raoul_de_brienne` | Raoul de Brienne, condestable de Francia | brienne | `france` | 1319 | — | general | https://en.wikipedia.org/wiki/Raoul_I_de_Brienne,_Count_of_Eu |
| `bertrand_du_guesclin` | Bertrand du Guesclin | guesclin | `france` | 1320 | — | general | https://en.wikipedia.org/wiki/Bertrand_du_Guesclin |
| `ludwig_iv_wittelsbach` | Luis IV de Baviera | wittelsbach | `hre` | 1282 | — | ruler | https://en.wikipedia.org/wiki/Louis_IV,_Holy_Roman_Emperor |
| `margareta_de_hainaut` | Margarita de Hainaut | hainault | `hre` | 1311 | — | spouse | https://en.wikipedia.org/wiki/Margaret_II,_Countess_of_Hainaut |
| `ludwig_v_de_baviera` | Luis V de Baviera | wittelsbach | `hre` | 1315 | — | heir | https://en.wikipedia.org/wiki/Louis_V,_Duke_of_Bavaria |
| `ludwig_ii_de_baviera` | Luis II de Baviera | wittelsbach | `hre` | 1229 | 1294 | relative | https://en.wikipedia.org/wiki/Louis_II,_Duke_of_Bavaria |
| `rupert_i_wittelsbach` | Roberto I del Palatinado | wittelsbach | `hre` | 1309 | — | relative | https://en.wikipedia.org/wiki/Rupert_I,_Elector_Palatine |
| `werner_von_urslingen` | Werner von Urslingen | urslingen | `hre` | 1308 | — | general | https://en.wikipedia.org/wiki/Werner_von_Urslingen |
| `jan_lucembursky` | Juan I de Luxemburgo, rey de Bohemia | luxembourg | `bohemia` | 1296 | — | ruler | https://en.wikipedia.org/wiki/John_of_Bohemia |
| `elisabeth_de_bohemia` | Isabel de Bohemia | premyslid | `bohemia` | 1292 | 1330 | spouse | https://en.wikipedia.org/wiki/Elizabeth_of_Bohemia_(1292%E2%80%931330) |
| `charles_iv_luxembourg` | Carlos IV de Luxemburgo | luxembourg | `bohemia` | 1316 | — | heir | https://en.wikipedia.org/wiki/Charles_IV,_Holy_Roman_Emperor |
| `heinrich_vii_luxembourg` | Enrique VII de Luxemburgo | luxembourg | `bohemia` | 1275 | 1313 | relative | https://en.wikipedia.org/wiki/Henry_VII,_Holy_Roman_Emperor |
| `margarethe_de_luxembourg` | Margarita de Luxemburgo | luxembourg | `bohemia` | 1313 | — | relative | https://en.wikipedia.org/wiki/Margaret_of_Bohemia,_Duchess_of_Bavaria |
| `bonne_de_luxembourg` | Bonne de Luxemburgo | luxembourg | `bohemia` | 1315 | — | relative | https://en.wikipedia.org/wiki/Bonne_of_Luxembourg |
| `jan_jindrich_luxembourg` | Juan Enrique de Luxemburgo, margrave de Moravia | luxembourg | `bohemia` | 1322 | — | relative | https://en.wikipedia.org/wiki/John_Henry,_Margrave_of_Moravia |
| `petr_z_rozmberka` | Petr I de Rožmberk | rozmberk | `bohemia` | 1300 | — | general | https://en.wikipedia.org/wiki/Peter_I_of_Rosenberg |
| `karoly_robert_anjou` | Carlos Roberto de Anjou | anjou | `hungary` | 1288 | — | ruler | https://en.wikipedia.org/wiki/Charles_I_of_Hungary |
| `erzsebet_lengyel` | Isabel de Polonia, reina de Hungría | piast | `hungary` | 1305 | — | spouse | https://en.wikipedia.org/wiki/Elizabeth_of_Poland,_Queen_of_Hungary |
| `lajos_i_anjou` | Luis I el Grande de Hungría | anjou | `hungary` | 1326 | — | heir | https://en.wikipedia.org/wiki/Louis_I_of_Hungary |
| `charles_martel_anjou` | Carlos Martel de Anjou | anjou | `hungary` | 1271 | 1295 | relative | https://en.wikipedia.org/wiki/Charles_Martel_of_Anjou |
| `andras_anjou` | Andrés de Anjou, duque de Calabria | anjou | `hungary` | 1327 | — | relative | https://en.wikipedia.org/wiki/Andrew,_Duke_of_Calabria |
| `miklos_zapolya` | Miklós Zápolya, ban de Croacia | zapolya | `hungary` | 1300 | — | general | https://en.wikipedia.org/wiki/Kingdom_of_Hungary_(1301%E2%80%931526) |
| `alfonso_xi_borgona` | Alfonso XI el Justiciero | borgona | `castile` | 1311 | — | ruler | https://en.wikipedia.org/wiki/Alfonso_XI_of_Castile |
| `maria_de_portugal` | María de Portugal, reina de Castilla | borgona | `castile` | 1313 | — | spouse | https://en.wikipedia.org/wiki/Maria_of_Portugal,_Queen_of_Castile |
| `pedro_i_de_castilla` | Pedro I el Cruel | borgona | `castile` | 1334 | — | heir | https://en.wikipedia.org/wiki/Peter_of_Castile |
| `fernando_iv_borgona` | Fernando IV el Emplazado | borgona | `castile` | 1285 | 1312 | relative | https://en.wikipedia.org/wiki/Ferdinand_IV_of_Castile |
| `constanza_de_portugal` | Constanza de Portugal, reina de Castilla | borgona | `castile` | 1290 | 1313 | relative | https://en.wikipedia.org/wiki/Constance_of_Portugal,_Queen_of_Castile |
| `leonor_de_guzman` | Leonor de Guzmán | guzman | `castile` | 1310 | — | relative | https://en.wikipedia.org/wiki/Leonor_de_Guzm%C3%A1n |
| `enrique_ii_de_castilla` | Enrique II de Trastámara | borgona | `castile` | 1334 | — | relative | https://en.wikipedia.org/wiki/Henry_II_of_Castile |
| `garci_lasso_de_la_vega` | Garci Lasso de la Vega, canciller de Castilla | lasso | `castile` | 1290 | — | general | https://es.wikipedia.org/wiki/Alfonso_XI_de_Castilla |
| `juan_manuel_de_castilla` | Juan Manuel, príncipe de Villena | manuel | `castile` | 1282 | — | advisor | https://en.wikipedia.org/wiki/Juan_Manuel,_Prince_of_Villena |
| `pere_iv_d_arago` | Pedro IV el Ceremonioso | barcelona | `aragon` | 1319 | — | ruler | https://en.wikipedia.org/wiki/Peter_IV_of_Aragon |
| `jaume_d_urgell` | Jaime de Aragón, conde de Urgel | barcelona | `aragon` | 1321 | — | heir | https://en.wikipedia.org/wiki/James_I,_Count_of_Urgell |
| `alfons_iv_d_arago` | Alfonso IV el Benigno | barcelona | `aragon` | 1299 | 1336 | relative | https://en.wikipedia.org/wiki/Alfonso_IV_of_Aragon |
| `bernat_de_cabrera` | Bernat de Cabrera | cabrera | `aragon` | 1298 | — | general | https://en.wikipedia.org/wiki/Bernat_de_Cabrera |
| `lope_de_luna` | Lope de Luna | luna | `aragon` | 1315 | — | general | https://en.wikipedia.org/wiki/Lope_de_Luna |
| `kazimierz_iii_piast` | Casimiro III el Grande | piast | `poland` | 1310 | — | ruler | https://en.wikipedia.org/wiki/Casimir_III_the_Great |
| `aldona_de_lituania` | Aldona de Lituania, reina de Polonia | gediminas | `poland` | 1309 | — | spouse | https://en.wikipedia.org/wiki/Aldona_of_Lithuania |
| `wladyslaw_i_piast` | Władysław I el Corto | piast | `poland` | 1261 | 1333 | relative | https://en.wikipedia.org/wiki/W%C5%82adys%C5%82aw_I_the_Elbow-High |
| `bolko_ii_opole` | Bolko II de Opole | piast | `poland` | 1300 | — | relative | https://en.wikipedia.org/wiki/Bolko_II_of_Opole |
| `spycimir_z_tarnowa` | Spycimir Leliwita, castellano de Cracovia | leliwita | `poland` | 1280 | — | general | https://en.wikipedia.org/wiki/Spycimir_Leliwita |
| `david_ii_bruce` | David II de Escocia | bruce | `scotland` | 1324 | — | ruler | https://en.wikipedia.org/wiki/David_II_of_Scotland |
| `joan_of_england` | Juana de Inglaterra, reina de Escocia | plantagenet | `scotland` | 1321 | — | spouse | https://en.wikipedia.org/wiki/Joan_of_the_Tower |
| `robert_ii_stewart` | Roberto II Estuardo | stewart | `scotland` | 1316 | — | heir | https://en.wikipedia.org/wiki/Robert_II_of_Scotland |
| `robert_i_bruce` | Roberto I Bruce | bruce | `scotland` | 1274 | 1329 | relative | https://en.wikipedia.org/wiki/Robert_the_Bruce |
| `andrew_murray` | Andrew Murray, regente de Escocia | murray | `scotland` | 1298 | — | general | https://en.wikipedia.org/wiki/Andrew_Murray_(died_1338) |
| `william_douglas` | William Douglas, señor de Liddesdale | douglas | `scotland` | 1300 | — | general | https://en.wikipedia.org/wiki/William_Douglas,_Lord_of_Liddesdale |
| `benedict_xii` | Benedicto XII (Jacques Fournier) | fournier | `papacy` | 1285 | — | ruler | https://en.wikipedia.org/wiki/Pope_Benedict_XII |
| `clemente_vi` | Clemente VI (Pierre Roger) | roger | `papacy` | 1291 | — | relative | https://en.wikipedia.org/wiki/Pope_Clement_VI |
| `hugues_roger` | Hugues Roger | roger | `papacy` | 1293 | — | relative | https://en.wikipedia.org/wiki/Hugues_Roger |
| `bertrand_du_pouget` | Bertrand du Pouget | pouget | `papacy` | 1280 | — | general | https://en.wikipedia.org/wiki/Bertrand_du_Pouget |
| `yusuf_i_nazari` | Yusuf I de Granada | nazari | `granada` | 1318 | — | ruler | https://en.wikipedia.org/wiki/Yusuf_I_of_Granada |
| `muhammad_v_nazari` | Muhammad V de Granada | nazari | `granada` | 1338 | — | heir | https://en.wikipedia.org/wiki/Muhammad_V_of_Granada |
| `ismail_i_nazari` | Ismail I de Granada | nazari | `granada` | 1279 | 1325 | relative | https://en.wikipedia.org/wiki/Ismail_I_of_Granada |
| `muhammad_iv_nazari` | Muhammad IV de Granada | nazari | `granada` | 1315 | 1333 | relative | https://en.wikipedia.org/wiki/Muhammad_IV_of_Granada |
| `an_nasir_muhammad` | An-Nasir Muhammad | qalawun | `mamluks` | 1285 | — | ruler | https://en.wikipedia.org/wiki/An-Nasir_Muhammad |
| `abu_bakr_al_mansur` | Al-Mansur Abu Bakr | qalawun | `mamluks` | 1321 | — | heir | https://en.wikipedia.org/wiki/Al-Mansur_Abu_Bakr |
| `qalawun` | Qalawun | qalawun | `mamluks` | 1222 | 1290 | relative | https://en.wikipedia.org/wiki/Qalawun |
| `ahmad_al_nasir` | An-Nasir Ahmad | qalawun | `mamluks` | 1316 | — | relative | https://en.wikipedia.org/wiki/An-Nasir_Ahmad |
| `qawsun` | Emir Qawsun | qawsun | `mamluks` | 1290 | — | general | https://en.wikipedia.org/wiki/Qawsun |
| `oz_beg` | Öz Beg Kan | borjigin | `golden_horde` | 1282 | — | ruler | https://en.wikipedia.org/wiki/%C3%96z_Beg_Khan |
| `taidula_katun` | Taidula Khatun | borjigin | `golden_horde` | 1290 | — | spouse | https://en.wikipedia.org/wiki/Taidula_Khatun |
| `jani_beg` | Jani Beg | borjigin | `golden_horde` | 1317 | — | heir | https://en.wikipedia.org/wiki/Jani_Beg |
| `togrilcha` | Togrilcha | borjigin | `golden_horde` | 1240 | 1290 | relative | https://en.wikipedia.org/wiki/Golden_Horde |
| `tinibeg_khan` | Tinibeg | borjigin | `golden_horde` | 1320 | — | relative | https://en.wikipedia.org/wiki/Tinibeg |
| `qutlugh_timur` | Qutlugh Timur | qutlugh | `golden_horde` | 1290 | — | general | https://en.wikipedia.org/wiki/Golden_Horde |
| `andronikos_iii_palaiologos` | Andrónico III Paleólogo | paleologo | `byzantium` | 1297 | — | ruler | https://en.wikipedia.org/wiki/Andronikos_III_Palaiologos |
| `anna_de_saboya` | Ana de Saboya | saboya | `byzantium` | 1306 | — | spouse | https://en.wikipedia.org/wiki/Anna_of_Savoy |
| `john_v_palaiologos` | Juan V Paleólogo | paleologo | `byzantium` | 1332 | — | heir | https://en.wikipedia.org/wiki/John_V_Palaiologos |
| `michael_ix_palaiologos` | Miguel IX Paleólogo | paleologo | `byzantium` | 1277 | 1320 | relative | https://en.wikipedia.org/wiki/Michael_IX_Palaiologos |
| `john_vi_kantakouzenos` | Juan VI Cantacuceno | kantakouzenos | `byzantium` | 1292 | — | general | https://en.wikipedia.org/wiki/John_VI_Kantakouzenos |

## 4. Regiones (47) — GDD §7.2 y §4.1

`population` (habitantes de la región, no solo de la ciudad) y `base_wealth` (1-100) son estimaciones de orden de magnitud para la Europa de 1337; todas las entradas llevan `"estimate": true`. La URL de cada región es el ancla de referencia (nombre, ciudad y contexto histórico), no la fuente exacta de la población. La lista de adyacencias forma un grafo **simétrico y conectado** (verificado).

| id | Región | Terreno | Ciudad | Dueño 1337 | Población (est.) | Riqueza (est.) | Ancla / fuente |
|---|---|---|---|---|---|---|---|
| `region_londres` | Londres | city | sí | `england` | 120.000 | 75 | https://en.wikipedia.org/wiki/London |
| `region_inglaterra_sur` | Sur de Inglaterra | plains | sí | `england` | 300.000 | 55 | https://en.wikipedia.org/wiki/Kingdom_of_England |
| `region_inglaterra_norte` | Norte de Inglaterra | forest | sí | `england` | 250.000 | 45 | https://en.wikipedia.org/wiki/Kingdom_of_England |
| `region_aquitania` | Aquitania y Gascuña | coast | sí | `england` | 300.000 | 60 | https://en.wikipedia.org/wiki/Duchy_of_Aquitaine |
| `region_ile_de_france` | Isla de Francia | city | sí | `france` | 700.000 | 85 | https://en.wikipedia.org/wiki/%C3%8Ele-de-France |
| `region_normandia` | Normandía | plains | sí | `france` | 520.000 | 60 | https://en.wikipedia.org/wiki/Duchy_of_Normandy |
| `region_flandes` | Flandes | coast | sí | `france` | 450.000 | 90 | https://en.wikipedia.org/wiki/County_of_Flanders |
| `region_bretana` | Bretaña | coast | sí | `france` | 300.000 | 45 | https://en.wikipedia.org/wiki/Duchy_of_Brittany |
| `region_borgona` | Borgoña | forest | sí | `france` | 300.000 | 60 | https://en.wikipedia.org/wiki/Duchy_of_Burgundy |
| `region_languedoc` | Languedoc | plains | sí | `france` | 400.000 | 55 | https://en.wikipedia.org/wiki/Languedoc |
| `region_avignon` | Aviñón y el Condado Venaissin | city | sí | `papacy` | 80.000 | 60 | https://en.wikipedia.org/wiki/Avignon |
| `region_baviera` | Baviera | forest | sí | `hre` | 350.000 | 55 | https://en.wikipedia.org/wiki/Duchy_of_Bavaria |
| `region_franconia` | Franconia | forest | sí | `hre` | 300.000 | 55 | https://en.wikipedia.org/wiki/Duchy_of_Franconia |
| `region_renania` | Renania | plains | sí | `hre` | 400.000 | 70 | https://en.wikipedia.org/wiki/Rhineland |
| `region_lorena` | Lorena | forest | sí | `hre` | 180.000 | 45 | https://en.wikipedia.org/wiki/Duchy_of_Lorraine |
| `region_austria` | Austria | mountain | sí | `hre` | 300.000 | 55 | https://en.wikipedia.org/wiki/Duchy_of_Austria |
| `region_praga` | Praga | city | sí | `bohemia` | 350.000 | 80 | https://en.wikipedia.org/wiki/Prague |
| `region_moravia` | Moravia | forest | sí | `bohemia` | 250.000 | 50 | https://en.wikipedia.org/wiki/Moravia |
| `region_buda` | Buda y la llanura húngara | plains | sí | `hungary` | 300.000 | 60 | https://en.wikipedia.org/wiki/Buda |
| `region_transilvania` | Transilvania | mountain | sí | `hungary` | 250.000 | 40 | https://en.wikipedia.org/wiki/Transylvania |
| `region_croacia` | Croacia | mountain | sí | `hungary` | 180.000 | 35 | https://en.wikipedia.org/wiki/Kingdom_of_Croatia_(1102%E2%80%931526) |
| `region_burgos` | Burgos y Castilla la Vieja | plains | sí | `castile` | 350.000 | 60 | https://en.wikipedia.org/wiki/Kingdom_of_Castile |
| `region_toledo` | Toledo y Castilla la Nueva | plains | sí | `castile` | 400.000 | 60 | https://en.wikipedia.org/wiki/Kingdom_of_Toledo |
| `region_sevilla` | Sevilla y el valle del Guadalquivir | plains | sí | `castile` | 380.000 | 65 | https://en.wikipedia.org/wiki/Seville |
| `region_barcelona` | Barcelona y Cataluña | coast | sí | `aragon` | 350.000 | 70 | https://en.wikipedia.org/wiki/Principality_of_Catalonia |
| `region_valencia` | Valencia | coast | sí | `aragon` | 300.000 | 55 | https://en.wikipedia.org/wiki/Kingdom_of_Valencia |
| `region_sicilia` | Sicilia | coast | sí | `aragon` | 300.000 | 55 | https://en.wikipedia.org/wiki/Kingdom_of_Sicily |
| `region_granada` | Granada | mountain | sí | `granada` | 300.000 | 55 | https://en.wikipedia.org/wiki/Emirate_of_Granada |
| `region_malaga` | Málaga y la costa nazarí | coast | sí | `granada` | 200.000 | 45 | https://en.wikipedia.org/wiki/M%C3%A1laga |
| `region_cracovia` | Cracovia y Pequeña Polonia | plains | sí | `poland` | 250.000 | 55 | https://en.wikipedia.org/wiki/Krak%C3%B3w |
| `region_gran_polonia` | Gran Polonia | plains | sí | `poland` | 220.000 | 45 | https://en.wikipedia.org/wiki/Greater_Poland |
| `region_edimburgo` | Edimburgo y Lothian | coast | sí | `scotland` | 200.000 | 35 | https://en.wikipedia.org/wiki/Edinburgh |
| `region_escocia_occidental` | Tierras Altas y costa occidental de Escocia | mountain | no | `scotland` | 150.000 | 25 | https://en.wikipedia.org/wiki/Scottish_Highlands |
| `region_roma` | Roma y el Lacio | city | sí | `papacy` | 300.000 | 60 | https://en.wikipedia.org/wiki/Papal_States |
| `region_napoles` | Nápoles | coast | sí | `papacy` | 350.000 | 65 | https://en.wikipedia.org/wiki/Kingdom_of_Naples |
| `region_lombardia` | Lombardía | plains | sí | `hre` | 500.000 | 80 | https://en.wikipedia.org/wiki/Lombardy |
| `region_toscana` | Toscana | plains | sí | `hre` | 400.000 | 80 | https://en.wikipedia.org/wiki/Tuscany |
| `region_el_cairo` | El Cairo | city | sí | `mamluks` | 500.000 | 90 | https://en.wikipedia.org/wiki/Cairo |
| `region_alejandria` | Alejandría | coast | sí | `mamluks` | 250.000 | 70 | https://en.wikipedia.org/wiki/Alexandria |
| `region_barqa` | Cirenaica (Barqa) | coast | no | `mamluks` | 80.000 | 25 | https://en.wikipedia.org/wiki/Cyrenaica |
| `region_damasco` | Damasco | plains | sí | `mamluks` | 300.000 | 70 | https://en.wikipedia.org/wiki/Damascus |
| `region_jerusalen` | Jerusalén y Palestina | plains | sí | `mamluks` | 150.000 | 40 | https://en.wikipedia.org/wiki/Jerusalem |
| `region_constantinopla` | Constantinopla | city | sí | `byzantium` | 200.000 | 65 | https://en.wikipedia.org/wiki/Constantinople |
| `region_tesalonica` | Tesalónica | coast | sí | `byzantium` | 150.000 | 50 | https://en.wikipedia.org/wiki/Thessaloniki |
| `region_anatolia_occidental` | Anatolia occidental | mountain | sí | `byzantium` | 250.000 | 45 | https://en.wikipedia.org/wiki/Byzantine_Empire |
| `region_sarai` | Sarai | plains | sí | `golden_horde` | 300.000 | 65 | https://en.wikipedia.org/wiki/Sarai_(city) |
| `region_crimea` | Crimea | coast | sí | `golden_horde` | 120.000 | 50 | https://en.wikipedia.org/wiki/Crimea |

Notas de modelado regional:
- `region_avignon`: Sede pontificia desde 1309.
- `region_praga`: Capital de Bohemia y sede imperial de los Wittelsbach (Luis IV residía en Múnich).
- `region_napoles`: Reino de Nápoles, feudo papal (simplificación de facción en 1337).
- `region_lombardia`: Italia imperial nominal; señoríos urbanos de facto.
- `region_toscana`: Italia imperial nominal; ciudades-Estado de facto.
- `region_barqa`: Costa del norte de África bajo influencia mameluca (estimación de alcance).

## 5. Unidades (17) — GDD §6.4

La tabla de unidades, sus épocas, tipos, fuerza, movimiento, coste y multiplicadores proviene literalmente de GDD §6.4 (documento vinculante); los valores numéricos de `cost` traducen las categorías cualitativas del GDD (bajo/medio/alto/muy alto) y son balance de diseño. `available_from` marca la aparición tecnológica aproximada citada en §6.4.

| id | Unidad | Época | Tipo | Fuerza | Mov. | Desde | Referencia histórica |
|---|---|---|---|---|---|---|---|
| `militia_spearman` | Milicia de lanza | 1-3 | infantry | 4 | 2 | — | https://en.wikipedia.org/wiki/Infantry_in_the_Middle_Ages |
| `scottish_schiltron` | Piquero escocés (schiltron) | 1-2 | infantry | 7 | 1 | — | https://en.wikipedia.org/wiki/Schiltron |
| `crossbowmen` | Ballesteros | 1-3 | ranged | 8 | 2 | — | https://en.wikipedia.org/wiki/Crossbow |
| `longbowman` | Arquero largo | 1-3 | ranged | 9 | 2 | — | https://en.wikipedia.org/wiki/English_longbow |
| `mounted_sergeants` | Sargentos a caballo | 1-2 | cavalry | 9 | 4 | — | https://en.wikipedia.org/wiki/Man-at-arms |
| `men_at_arms` | Hombres de armas | 1-3 | cavalry | 12 | 3 | — | https://en.wikipedia.org/wiki/Man-at-arms |
| `light_horseman` | Jinete (caballería ligera) | 1-3 | light_cavalry | 7 | 5 | — | https://en.wikipedia.org/wiki/Light_cavalry |
| `steppe_cavalry` | Caballería de estepa | 1-2 | light_cavalry | 8 | 6 | — | https://en.wikipedia.org/wiki/Mongol_military_tactics_and_organization |
| `almogavar` | Almogávar | 1-1 | infantry | 8 | 3 | — | https://en.wikipedia.org/wiki/Almogavars |
| `mamluk` | Mameluco | 1-3 | cavalry | 12 | 4 | — | https://en.wikipedia.org/wiki/Mamluk |
| `swiss_pikeman` | Piquero suizo/alemán | 2-3 | infantry | 11 | 2 | 1386 | https://en.wikipedia.org/wiki/Swiss_pike |
| `dismounted_men_at_arms` | Hombre de armas a pie | 2-3 | infantry | 11 | 2 | 1346 | https://en.wikipedia.org/wiki/Man-at-arms |
| `bombarda` | Bombarda | 2-3 | artillery | 16 | 1 | 1350 | https://en.wikipedia.org/wiki/Bombard_(weapon) |
| `arquebusier` | Arcabucero | 3-3 | ranged | 12 | 2 | 1440 | https://en.wikipedia.org/wiki/Arquebus |
| `hussite_war_wagon` | Carro bélico húsita | 3-3 | special | 9 | 2 | 1419 | https://en.wikipedia.org/wiki/War_wagon |
| `janissary` | Jenízaro | 3-3 | infantry | 13 | 3 | 1365 | https://en.wikipedia.org/wiki/Janissary |
| `teutonic_knights` | Caballeros teutónicos | 1-2 | cavalry | 13 | 3 | 1226 | https://en.wikipedia.org/wiki/Teutonic_Order |

## 6. Eventos (1337-1399) — GDD §7.6

Fechas contrastadas con las fichas de Wikipedia citadas; `news` es redacción propia. El evento `peste_negra_1348` aplica `population_modifier -0.35` con `scope: europe_west` según GDD §5.3/§7.6.

| id | Año | Disparador | Fuente |
|---|---|---|---|
| `guerra_cien_anos_1337` | 1337 | year_reached | https://en.wikipedia.org/wiki/Hundred_Years%27_War |
| `batalla_sluys_1340` | 1340 | war (england, france) | https://en.wikipedia.org/wiki/Battle_of_Sluys |
| `batalla_crecy_1346` | 1346 | war (england, france) | https://en.wikipedia.org/wiki/Battle_of_Cr%C3%A9cy |
| `sitio_calais_1347` | 1347 | war (england, france) | https://en.wikipedia.org/wiki/Siege_of_Calais_(1346%E2%80%931347) |
| `peste_negra_1348` | 1348 | year_reached | https://en.wikipedia.org/wiki/Black_Death |
| `peste_negra_rebrote_1350` | 1350 | year_reached | https://en.wikipedia.org/wiki/Black_Death |
| `batalla_poitiers_1356` | 1356 | war (england, france) | https://en.wikipedia.org/wiki/Battle_of_Poitiers |
| `jacquerie_1358` | 1358 | year_reached | https://en.wikipedia.org/wiki/Jacquerie |
| `paz_bretigny_1360` | 1360 | war (england, france) | https://en.wikipedia.org/wiki/Treaty_of_Br%C3%A9tigny |
| `guerra_civil_castellana_1366` | 1366 | year_reached | https://en.wikipedia.org/wiki/Castilian_Civil_War |
| `batalla_najera_1367` | 1367 | war (castile, england) | https://en.wikipedia.org/wiki/Battle_of_N%C3%A1jera |
| `guerra_cien_anos_reanuda_1369` | 1369 | year_reached | https://en.wikipedia.org/wiki/Hundred_Years%27_War |
| `batalla_maritsa_1371` | 1371 | year_reached | https://en.wikipedia.org/wiki/Battle_of_Maritsa |
| `cisma_occidente_1378` | 1378 | year_reached | https://en.wikipedia.org/wiki/Western_Schism |
| `revuelta_ciompi_1378` | 1378 | year_reached | https://en.wikipedia.org/wiki/Ciompi_Revolt |
| `revuelta_campesina_1381` | 1381 | year_reached | https://en.wikipedia.org/wiki/Peasants%27_Revolt |
| `batalla_kosovo_1389` | 1389 | year_reached | https://en.wikipedia.org/wiki/Battle_of_Kosovo |
| `cruzada_nicopolis_1396` | 1396 | year_reached | https://en.wikipedia.org/wiki/Battle_of_Nicopolis |

## 7. Estimaciones y supuestos declarados

1. **Stats de personaje**: los 86 personajes tienen `"estimate": true` (estimación de diseño 1-100, GDD §5.3).
2. **Población y riqueza regional**: 47/47 regiones con `"estimate": true`; redondeos por orden de magnitud (GDD §14, riesgo «datos históricos incompletos»).
3. **Fechas aproximadas** (marcadas en la nota del personaje): Robert Morley (n. 1290), Werner von Urslingen (n. 1308), Petr I de Rožmberk (n. 1300), Miklós Zápolya (n. 1300), Garci Lasso de la Vega (n. 1290), Lope de Luna (n. 1315), Spycimir Leliwita (n. 1280), William Douglas (n. 1300), Bertrand du Pouget (n. 1280), Qawsun (n. 1290), Taidula Khatun (n. 1290), Tinibeg (n. 1320), Qutlugh Timur (n. 1290), Togrilcha (n. 1240).
4. **Heredero nacido después del inicio**: `muhammad_v_nazari` (n. 1338) figura como heredero de Granada para que la sucesión nazarí sea jugable desde 1337; su nacimiento real es posterior al inicio del escenario (documentado en `note`).
5. **Cónyuge no documentado**: `yusuf_i_nazari` tiene `family.spouse: null` porque no hay nombre fiable en fuentes abiertas.
6. **Personajes ya fallecidos antes de 1337** (16 fichas de padres/abuelos) se incluyen solo como referencias genealógicas (`died` con año); todos los vivos llevan `died: null`.
7. **Bertrand du Guesclin** (n. 1320) figura como general con nota: en 1337 era un noble joven sin mando efectivo (que llegó en los años 1350).
8. **Simplificaciones de facción** (necesarias para un mapa con 14 facciones):
   - `region_napoles` (Reino de Nápoles) se asigna al Papado como feudo papal (1302-1343 bajo Roberto de Anjou, aliado papal); documentado en `note`.
   - `region_lombardia` y `region_toscana` se asignan al Sacro Imperio (soberanía imperial nominal sobre Italia; señoríos urbanos de facto).
   - `region_barqa` (Cirenaica) se asigna a los mamelucos como zona de influencia en el norte de África costero; no existe facción hafsí/magrebí en el Escenario 1, por lo que el Magreb occidental (Túnez, Argel, Marruecos) queda fuera del mapa jugable.
   - Sin facción otomana ni veneciana en 1337 (aparecen en escenarios 2-3): las unidades `janissary` y `teutonic_knights` tienen `faction_tags: []` y época III/II respectivamente.
9. **Perfiles de IA** (Agresor/Comerciante/Dinástico/Superviviente/Equilibrado, GDD §5.6) son asignación de diseño coherente con la historia de cada facción.
10. **Tesorerías y ejércitos iniciales** del escenario son balance de diseño (no cifras históricas): se derivan de la riqueza relativa de cada facción en 1337.

## 8. Alineación con `docs/rea/gk2_data_lessons.md` (D-003)

_Informe leído el 2026-11-21 en su versión publicada por AG-REA (no se reescribe; D-002/D-003). Esta sección solo documenta cómo los datasets de AG-1 aplican sus lecciones. Informe: `docs/rea/gk2_data_lessons.md`._

| Lección del informe REA (§4) | Aplicación en `data/` (este dataset) |
|---|---|
| **1. Escenario y guardado comparten esquema**; el guardado de GK2 sobrescribe las mismas tablas | `scenario_1337.json` es inmutable (facciones, `initial_state`, `victory`, `events_script`); el guardado futuro (§7.7) será un snapshot versionado aparte, no una variante de los datasets. |
| **2. Capacidad fija + huecos** (99 ranuras de personaje, 66 de región, 32 de facción, mayoría vacías) | Sin capacidad fija ni ranuras vacías: listas JSON dispersas con IDs estables — 14 facciones, 47 regiones, 86 personajes, 17 unidades, 18 eventos. Nada depende de índices posicionales. |
| **3. Duplicación deliberada** (el roster de `GENDATA1.DAT` se copia byte a byte en `SCENARIO.GK2`) | Una única fuente canónica `characters.json`; `scenario_1337.initial_state.characters` la referencia por nombre de fichero. No hay dos verdades genealógicas. |
| **4. Atributos empaquetados de 4 bits** (16 atributos en 8 B, escala 0–15) | `stats{command,intrigue,charisma,loyalty,education}` en escala 1–100 (GDD §5.3), legibles y validables, con `"estimate": true` en las 86 fichas; no se empaqueta ni se copia la conversión de GK2. |
| **5. Centinelas explícitos y dispersos** (`0x00`, `0xFF`, `0xC8` = sin región) | Sin centinelas numéricos: `died: null` y `family.*: null` explícitos; `year_data["1337"].owner` siempre es un id de facción validado; `terrain` y `buildings` usan enums cerrados. |
| **6. Nombres en tabla aparte con índice implícito** (`ZNAME.DAT`) | IDs explícitos (`region_*`, personajes snake_case) y validación cruzada de todas las referencias (capital, adyacencia, `owner`, familia, `claims`): el nombre se guarda junto a la entidad por legibilidad, pero la identidad es el id. |
| **7. Mapa/hex de GK2 no determinable** (`MAPDATA.DAT`, `HEXKG.DAT`, `HEXSG.DAT`) | El mapa jugable es un **grafo de regiones propio** (47 nodos; 130 entradas de adyacencia dirigidas = 65 pares no dirigidos), no derivado de los binarios: `adjacency` simétrica y conectada, validada por `tools/validate_data.gd` y por el chequeo de AG-1. |
| **8. Registros de tamaño fijo con campos de texto acolchados** | JSON UTF-8 legible sin acolchado; `additionalProperties: false`, `required`, `pattern`, `enum` y `minItems` actúan como validador de registros incompletos (D-004/D-009). |
| **9. Determinismo y orden estables** | Listas con orden estable e IDs estables → mismo JSON, mismo estado inicial; validación reproducible (0 errores) y base para los tests de determinismo de §13. |
| **10. `SCENARIO.GK2` = datos inmutables + estado inicial** | `scenario_1337.json` separa `factions`/`events_script` (datos) de `initial_state` (tesorerías, ejércitos, personajes, año de regiones), replicando esa separación conceptual. |

_El informe REA no determinó relaciones familiares, matrimonios ni pretensiones (requeriría analizar ejecutables, prohibido por GDD §3): el árbol genealógico de `characters.json` es una **construcción histórica propia** a partir de las fichas de Wikipedia citadas en §3 de este documento, no una copia del modelo de GK2. Ningún nombre, texto, cifra ni offset del informe REA se ha copiado a `data/`: solo se aplican ideas estructurales (IDs explícitos, entidad-personaje con atributos, región con origen/destino, escenario = datos + estado inicial, sin duplicación), conforme a GDD §3._

---

## 9. Fronteras del mapa (Fase 2 — GDD §10.1, contrato §1, D-024/D-025/D-028)

`data/map_borders.json` contiene **3 años (1337, 1402, 1453) × 47 regiones** de `regions.json`:
`region_id`, `owner` del año, `ring` (anillo abierto de puntos normalizados [0..1], 4 decimales),
`center` y `estimate: true`. La misma geometría se reutiliza en los tres años; solo cambia `owner`
(ahorra tamaño y garantiza que las tres vistas encajen). Todas las entradas llevan
`"estimate": true` (fronteras aproximadas de diseño, no cartografía catastral; regla §7.8).

### 9.1 Método de generación (reproducible)

| Paso | Detalle |
|---|---|
| Lienzo | `canvas` 4096×3072 (4:3), origen arriba-izquierda, `projection: equirectangular_stylized`. Proyección lineal lon ∈ [−8°, 52°], lat ∈ [24°, 62°] sobre [0..1]. |
| Tierra | Natural Earth 1:50m *land* (dominio público) intersectado con una ventana estilizada propia que limita el mundo jugable (Europa occidental/central, Iberia, Italia, Balcanes, Anatolia, Levante y costa de Libia/Egipto); rasterizado a 2048×1536. Las islas sin región asociada se descartan (quedan mar). |
| Centros | Coordenadas geográficas reales de la ciudad/capital de cada región (`center` final). `map_layout.json` (deprecado, D-024) se consultó solo como referencia de anclaje; la geometría **no** deriva de él. |
| Asignación | Voronoi por **distancia geodésica sobre la tierra** (BFS multi-fuente) restringido a la componente terrestre de cada centro: celdas contiguas y sin reclamar tierra al otro lado del mar. 47 celdas no vacías. |
| Contornos | Trazado por aristas de píxel (región a la izquierda), anillo exterior mayor; islotes sueltos sin center se descartan. |
| Simplificación | Douglas-Peucker circular con tolerancia **ε = 0.0006** en coordenadas normalizadas (≈2,5 px a 4096 de ancho), aplicada a cada anillo; se conservan 3–400 puntos; redondeo final a 4 decimales. |
| Resultado | 132.962 bytes (≤147.456), 141 entradas (3×47), puntos/región: mín. 11, media 52,55, máx. 183 (objetivo medio ≤55; límite duro 400). |

### 9.2 Fuentes de fronteras (abiertas y citables)

| Año | Fuente | Licencia | Uso |
|---|---|---|---|
| 1337 | [Wikimedia Commons — File:Europe 1337.jpg](https://commons.wikimedia.org/wiki/File:Europe_1337.jpg) (autor: Petolaszlo; «Political map of Europe in 1337») | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0), verificada vía API Commons el 2026-11-21 | Referencia política del año exacto. |
| 1402 | [Wikimedia Commons — File:Europa 1400.jpg](https://commons.wikimedia.org/wiki/File:Europa_1400.jpg) (H. Kiepert, *Historischer Schulatlas*, 1879; «Europa im Jahre 1400») | **Dominio público**, verificada vía API Commons el 2026-11-21 | No existe mapa anual libre exacto de 1402 en Commons; se usa 1400 (2 años antes) como referencia. |
| 1453 | [Wikimedia Commons — File:Europe 1444.jpg](https://commons.wikimedia.org/wiki/File:Europe_1444.jpg) (autor: Petolaszlo; «Political map of Europe in 1444») | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0), verificada vía API Commons el 2026-11-21 | No existe mapa anual libre exacto de 1453 en Commons; se usa 1444 (9 años antes) como referencia; la caída de Constantinopla (mayo 1453) se documenta en `owner` 1453. |
| Referencia general | William R. Shepherd, *Historical Atlas* (1923-26), dominio público — [Internet Archive](https://archive.org/details/HistoricalAtlasWilliamR.Shepherd) | Dominio público | Atlas histórico de referencia (D-028) para contraste de fronteras aproximadas; no se versiona ninguna imagen. |
| Costa base | [Natural Earth 1:50m Physical Vectors — land](https://www.naturalearthdata.com/downloads/50m-physical-vectors/) | Dominio público | Silueta costera (solo datos vectoriales de dominio público; sin assets de terceros en el repo). |

Los mapas de Wikimedia se usan **solo como referencia visual**: no se copia ni se versiona ninguna
imagen ni sus polígonos; los `ring` son una aproximación vectorial original y simplificada. Se
atribuye la autoría CC BY-SA de las dos obras usadas (Petolaszlo) aunque no se redistribuyan.

### 9.3 Propietarios por año y entidades sin facción

- **1337**: `owner` idéntico a `regions.json` (`year_data["1337"].owner`); 14 facciones de
  `factions.json`, reparto 4/6/7/2/3/3/3/2/2/3/2/5/2/3 (Inglaterra 4, Francia 6, HRE 7, Bohemia 2,
  Hungría 3, Castilla 3, Aragón 3, Polonia 2, Escocia 2, Papado 3, Granada 2, Mamelucos 5,
  Horda de Oro 2, Bizancio 3).
- **1402** (GDD §4.3): se reutilizan ids de `factions.json` donde aplica y se añaden ids de entidad
  histórica no presentes en 1337 (permitidos por contrato §1 y pintados como neutrales por AG-3):
  `brittany` (Bretaña, ducado independiente), `burgundy` (Borgoña/Flandes, Felipe el Temerario),
  `naples` (Nápoles, Ladislao), `milan` (Lombardía, Visconti), `florence` (Toscana, Florencia),
  `tamerlane` (Damasco, esfera timúrida tras la campaña de Siria de 1400-01; aproximación),
  `ottoman` (Anatolia occidental, Interregno otomano). `hre` cubre las tierras imperiales y
  `hungary` las húngaras; `papacy` cubre Aviñón y Roma (se documenta la simplificación del Cisma).
- **1453** (GDD §4.4): `brittany`, `burgundy`, `milan` (Sforza), `florence` (Médici), `venice`
  (Croacia/Dalmacia veneciana; aproximación), `genoa` (Crimea/Caffa genovesa; aproximación),
  `ottoman` (Tesalónica y Anatolia occidental); `aragon` incluye Nápoles (Alfonso V);
  `byzantium` conserva Constantinopla al inicio del escenario (la caída se produce en mayo de 1453);
  `mamluks` incluye Damasco y Jerusalén; `golden_horde` conserva Sarai.
- Ningún `owner` se inventa sin referencia: cada año está contrastado con el mapa de su fila en
  §9.2 y la tabla GDD §4.3/§4.4; los desvíos (Tamerlán en Damasco, Venecia en Croacia, Génova en
  Crimea, Nápoles en 1402) están marcados como aproximación de diseño.

### 9.4 Limitaciones y comprobaciones

- **47/47/47** entradas; ids únicos e idénticos a `regions.json`; coords en [0..1]; anillo abierto;
  área > 0; sin autointersecciones; `center` dentro de su polígono en 47/47 (Málaga y Constantinopla
  se reajustaron al píxel de tierra más cercano antes de generar).
- **Adyacencias** (`regions.json`, 65 pares): 5 pares son marítimos y por diseño no comparten
  frontera terrestre (`aquitania–inglaterra_sur`, `inglaterra_sur–normandia`, `barcelona–sicilia`,
  `barqa–sicilia`, `napoles–sicilia`); 53/60 pares terrestres comparten borde en la geometría;
  los 7 restantes son **abstracciones del grafo** separadas por una región intermedia o por mar
  (`austria–lombardia`, `lombardia–renania`, `cracovia–praga`, `croacia–transilvania`,
  `croacia–tesalonica` [cuasi-contiguas], `granada–sevilla`, `constantinopla–crimea`).
  Además hay 30 pares geométricamente vecinos que no están en `adjacency` (la teselación del mapa
  es continua; la adyacencia de juego sigue siendo la de `regions.json`). Se documenta como
  limitación conocida de una aproximación estilizada.
- **Cobertura**: la unión rasterizada de los 47 polígonos conserva el 100,5 % de la tierra asignada
  (solapamientos mínimos por simplificación independiente de anillos compartidos, ≤ ε); no hay
  huecos internos grandes.
- **Aproximaciones históricas**: mapas de referencia 1400 (para 1402) y 1444 (para 1453); las
  fronteras políticas son jugables, no catastrales. El mapa no incluye Escandinavia, Irlanda,
  Magreb occidental, Arabia ni Cáucaso como tierra (quedan fuera del mundo jugable).

## 10. Retratos de soberanos (GDD v1.5 §10.2, D-027)

- **14 retratos finales** de los gobernantes de 1337 en `assets/art/portraits/<character_id>.png`
  (256×256, PNG, fondo pergamino plano). Diseñados por **Kimi** por encargo del usuario, integrante
  del equipo del proyecto: obra propia del proyecto, sin material de terceros.
- `data/characters.json` añade `"portrait": "res://assets/art/portraits/<character_id>.png"` **solo
  a los 14 personajes con `role: "ruler"`** (14/14 verificados contra los ficheros de disco):
  `edward_iii_plantagenet`, `philippe_vi_de_valois`, `ludwig_iv_wittelsbach`, `jan_lucembursky`,
  `karoly_robert_anjou`, `alfonso_xi_borgona`, `pere_iv_d_arago`, `kazimierz_iii_piast`,
  `david_ii_bruce`, `benedict_xii`, `yusuf_i_nazari`, `an_nasir_muhammad`, `oz_beg`,
  `andronikos_iii_palaiologos`.
- Los **72 personajes restantes no llevan `portrait`** y usan el **fallback heráldico** de
  `portrait_frame.gd` (escudo generativo de la casa + silueta genérica), nunca un hueco vacío.
- `data/schema/characters.schema.json` mantiene `portrait` como propiedad **opcional**; el `pattern`
  admite la ruta `res://assets/art/portraits/<id>.png`, un id de asset simple
  (`^[a-z][a-z0-9_]*$`) o `null`.
- Hoja de contacto del set final: `docs/screenshots/portraits_contact_sheet_final.png`.
- Atribución: retratos por Kimi (encargo del usuario, proyecto propio); no se usa material de Koei
  ni de terceros. Coherente con GDD §10 y §1.2.

## 11. Escenarios 1402 y 1453 (Fase 3 — GDD §4.3/§4.4/§4.5, D-057/D-058/D-060)

### 11.1 Datos añadidos

| Dataset | Recuento | Cambio |
|---|---|---|
| `factions.json` | 23 facciones | +9 nuevas (`brittany`, `burgundy`, `florence`, `genoa`, `milan`, `naples`, `ottoman`, `tamerlane`, `venice`); las 14 de 1337 no cambian |
| `characters.json` | 175 personajes | +89 nuevos (42 gobernantes de 1402/1453 + 47 herederos/regentes/generales/pretendientes); los 86 de 1337 no se alteran |
| `regions.json` | 47 regiones × 3 años | `year_data` de 1402 y 1453 añadidos con owner de `map_borders.json`; 1337 intacto |
| `scenarios/scenario_1402.json` | 21 facciones, 8 jugables | inicio 1402, fin 1460 (D-060) |
| `scenarios/scenario_1453.json` | 21 facciones, 8 jugables | inicio 1453, fin 1480 (D-060) |
| `events_1402.json` | 10 eventos | Ankara, Tamerlán, Carlos VI, Armagnac-Borgoña, Constanza, husitas, Orleans, Juana de Arco, Arrás, Tours |
| `events_1453.json` | 8 eventos | Constantinopla, Castillon, fin de los Cien Años, Dos Rosas, Hunyadi, Belgrado, Trebisonda, Caffa |

### 11.2 Facciones nuevas

| id | Nombre | Capital (región existente) | Gobierno | Perfil | start_year |
|---|---|---|---|---|---|
| `brittany` | Ducado de Bretaña | `region_bretana` | monarchy | survivor | 1402 |
| `burgundy` | Ducado de Borgoña | `region_borgona` | monarchy | dynastic | 1402 |
| `florence` | República de Florencia | `region_toscana` | republic | merchant | 1402 |
| `genoa` | República de Génova | `region_crimea` | republic | merchant | 1453 |
| `milan` | Ducado de Milán | `region_lombardia` | monarchy | dynastic | 1402 |
| `naples` | Reino de Nápoles | `region_napoles` | monarchy | dynastic | 1402 |
| `ottoman` | Imperio Otomano | `region_anatolia_occidental` | sultanate | aggressor | 1402 |
| `tamerlane` | Imperio de Tamerlán | `region_damasco` | empire | aggressor | 1402 |
| `venice` | República de Venecia | `region_croacia` | republic | merchant | 1453 |

`playable: false` en las 9 nuevas; las 8 jugables de 1337 siguen con `playable: true` (D-057).
Capitales especiales: Génova usa `region_crimea` (Caffa, única región genovesa del mapa) y Venecia
usa `region_croacia` (Dalmacia veneciana); no existen regiones de Liguria/Venecia en el mapa de 47.

### 11.3 Gobernantes por escenario (fuente en cada ficha)

| Escenario | Facción | Gobernante | Nac.-Fall. | Reinado | Fuente |
|---|---|---|---|---|---|
| 1402 | `england` | Enrique IV de Inglaterra | 1367-1413 | 1399-1413 | https://en.wikipedia.org/wiki/Henry_IV_of_England |
| 1402 | `france` | Carlos VI de Francia | 1368-1422 | 1380-1422 | https://en.wikipedia.org/wiki/Charles_VI_of_France |
| 1402 | `hre` | Ruperto de Baviera, rey de romanos | 1352-1410 | 1400-1410 | https://en.wikipedia.org/wiki/Rupert,_King_of_Germany |
| 1402 | `bohemia` | Wenceslao IV de Bohemia | 1361-1419 | 1378-1419 | https://en.wikipedia.org/wiki/Wenceslaus_IV_of_Bohemia |
| 1402 | `hungary` | Segismundo de Luxemburgo | 1368-1437 | 1387-1437 | https://en.wikipedia.org/wiki/Sigismund,_Holy_Roman_Emperor |
| 1402 | `castile` | Enrique III de Castilla | 1379-1406 | 1390-1406 | https://en.wikipedia.org/wiki/Henry_III_of_Castile |
| 1402 | `aragon` | Martín I de Aragón | 1356-1410 | 1396-1410 | https://en.wikipedia.org/wiki/Martin_of_Aragon |
| 1402 | `poland` | Władysław II Jagiełło | 1362-1434 | 1386-1434 | https://en.wikipedia.org/wiki/W%C5%82adys%C5%82aw_II_Jagie%C5%82%C5%82o |
| 1402 | `scotland` | Roberto III de Escocia | 1337-1406 | 1390-1406 | https://en.wikipedia.org/wiki/Robert_III_of_Scotland |
| 1402 | `papacy` | Bonifacio IX | 1356-1404 | 1389-1404 | https://en.wikipedia.org/wiki/Pope_Boniface_IX |
| 1402 | `granada` | Muhammad VII de Granada | 1370-1408 | 1392-1408 | https://en.wikipedia.org/wiki/Muhammad_VII_of_Granada |
| 1402 | `mamluks` | Al-Faraj | 1389-1412 | 1399-1412 | https://en.wikipedia.org/wiki/Al-Faraj |
| 1402 | `golden_horde` | Edigu | 1352-1419 | 1399-1419 | https://en.wikipedia.org/wiki/Edigu |
| 1402 | `byzantium` | Manuel II Paleólogo | 1350-1425 | 1391-1425 | https://en.wikipedia.org/wiki/Manuel_II_Palaiologos |
| 1402 | `brittany` | Juan VI de Bretaña | 1389-1442 | 1399-1442 | https://en.wikipedia.org/wiki/John_VI,_Duke_of_Brittany |
| 1402 | `burgundy` | Felipe II el Temerario | 1342-1404 | 1363-1404 | https://en.wikipedia.org/wiki/Philip_the_Bold |
| 1402 | `florence` | Maso degli Albizzi | 1343-1417 | 1382-1417 | https://en.wikipedia.org/wiki/Maso_degli_Albizzi |
| 1402 | `milan` | Gian Galeazzo Visconti | 1351-1402 | 1395-1402 | https://en.wikipedia.org/wiki/Gian_Galeazzo_Visconti |
| 1402 | `naples` | Ladislao de Nápoles | 1377-1414 | 1386-1414 | https://en.wikipedia.org/wiki/Ladislaus_of_Naples |
| 1402 | `ottoman` | Bayezid I | 1360-1403 | 1389-1403 | https://en.wikipedia.org/wiki/Bayezid_I |
| 1402 | `tamerlane` | Tamerlán | 1336-1405 | 1370-1405 | https://en.wikipedia.org/wiki/Timur |
| 1453 | `england` | Enrique VI de Inglaterra | 1421-1471 | 1422-1461 | https://en.wikipedia.org/wiki/Henry_VI_of_England |
| 1453 | `france` | Carlos VII de Francia | 1403-1461 | 1422-1461 | https://en.wikipedia.org/wiki/Charles_VII_of_France |
| 1453 | `hre` | Federico III de Habsburgo | 1415-1493 | 1440-1493 | https://en.wikipedia.org/wiki/Frederick_III,_Holy_Roman_Emperor |
| 1453 | `bohemia` | Jorge de Poděbrady | 1420-1471 | 1452-1471 | https://en.wikipedia.org/wiki/George_of_Pod%C4%9Bbrady |
| 1453 | `hungary` | Ladislao V el Póstumo | 1440-1457 | 1444-1457 | https://en.wikipedia.org/wiki/Ladislaus_the_Posthumous |
| 1453 | `castile` | Juan II de Castilla | 1405-1454 | 1406-1454 | https://en.wikipedia.org/wiki/John_II_of_Castile |
| 1453 | `aragon` | Alfonso V el Magnánimo | 1396-1458 | 1416-1458 | https://en.wikipedia.org/wiki/Alfonso_V_of_Aragon |
| 1453 | `poland` | Casimiro IV Jagellón | 1427-1492 | 1447-1492 | https://en.wikipedia.org/wiki/Casimir_IV_Jagiellon |
| 1453 | `scotland` | Jacobo II de Escocia | 1430-1460 | 1437-1460 | https://en.wikipedia.org/wiki/James_II_of_Scotland |
| 1453 | `papacy` | Nicolás V | 1397-1455 | 1447-1455 | https://en.wikipedia.org/wiki/Pope_Nicholas_V |
| 1453 | `granada` | Muhammad XI de Granada (Sa'd) | 1396-1462 | 1453-1462 | https://en.wikipedia.org/wiki/Muhammad_XI_of_Granada |
| 1453 | `mamluks` | Al-Ashraf Inal | 1380-1461 | 1453-1461 | https://en.wikipedia.org/wiki/Al-Ashraf_Inal |
| 1453 | `golden_horde` | Küchük Muhammad | 1391-1459 | 1435-1459 | https://en.wikipedia.org/wiki/K%C3%BC%C3%A7%C3%BCk_Muhammad |
| 1453 | `byzantium` | Constantino XI Paleólogo | 1405-1453 | 1449-1453 | https://en.wikipedia.org/wiki/Constantine_XI_Palaiologos |
| 1453 | `brittany` | Pedro II de Bretaña | 1418-1457 | 1450-1457 | https://en.wikipedia.org/wiki/Peter_II,_Duke_of_Brittany |
| 1453 | `burgundy` | Felipe III el Bueno | 1396-1467 | 1419-1467 | https://en.wikipedia.org/wiki/Philip_the_Good |
| 1453 | `florence` | Cosimo de' Medici | 1389-1464 | 1434-1464 | https://en.wikipedia.org/wiki/Cosimo_de%27_Medici |
| 1453 | `genoa` | Pietro Fregoso | 1417-1459 | 1450-1458 | https://en.wikipedia.org/wiki/Pietro_Fregoso |
| 1453 | `milan` | Francesco Sforza | 1401-1466 | 1450-1466 | https://en.wikipedia.org/wiki/Francesco_I_Sforza |
| 1453 | `ottoman` | Mehmed II | 1432-1481 | 1451-1481 | https://en.wikipedia.org/wiki/Mehmed_II |
| 1453 | `venice` | Francesco Foscari | 1373-1457 | 1423-1457 | https://en.wikipedia.org/wiki/Francesco_Foscari |

### 11.4 Eventos

| Fichero | id | Año | Fuente |
|---|---|---|---|
| `events_1402.json` | `batalla_ankara_1402` | 1402 | https://en.wikipedia.org/wiki/Battle_of_Ankara |
| `events_1402.json` | `muerte_tamerlan_1405` | 1405 | https://en.wikipedia.org/wiki/Timur |
| `events_1402.json` | `locura_carlos_vi_1405` | 1405 | https://en.wikipedia.org/wiki/Charles_VI_of_France |
| `events_1402.json` | `guerra_civil_armagnac_borgona_1407` | 1407 | https://en.wikipedia.org/wiki/Armagnac%E2%80%93Burgundian_Civil_War |
| `events_1402.json` | `concilio_constanza_1414` | 1414 | https://en.wikipedia.org/wiki/Council_of_Constance |
| `events_1402.json` | `guerras_husitas_1420` | 1420 | https://en.wikipedia.org/wiki/Hussite_Wars |
| `events_1402.json` | `sitio_orleans_1429` | 1429 | https://en.wikipedia.org/wiki/Siege_of_Orl%C3%A9ans |
| `events_1402.json` | `ejecucion_juana_arco_1431` | 1431 | https://en.wikipedia.org/wiki/Joan_of_Arc |
| `events_1402.json` | `paz_arras_1435` | 1435 | https://en.wikipedia.org/wiki/Congress_of_Arras |
| `events_1402.json` | `tregua_tours_1444` | 1444 | https://en.wikipedia.org/wiki/Truce_of_Tours |
| `events_1453.json` | `caida_constantinopla_1453` | 1453 | https://en.wikipedia.org/wiki/Fall_of_Constantinople |
| `events_1453.json` | `batalla_castillon_1453` | 1453 | https://en.wikipedia.org/wiki/Battle_of_Castillon |
| `events_1453.json` | `fin_guerra_cien_anos_1453` | 1453 | https://en.wikipedia.org/wiki/Hundred_Years%27_War |
| `events_1453.json` | `guerra_dos_rosas_1455` | 1455 | https://en.wikipedia.org/wiki/Wars_of_the_Roses |
| `events_1453.json` | `muerte_hunyadi_1456` | 1456 | https://en.wikipedia.org/wiki/John_Hunyadi |
| `events_1453.json` | `sitio_belgrado_1456` | 1456 | https://en.wikipedia.org/wiki/Siege_of_Belgrade_(1456) |
| `events_1453.json` | `caida_trebisonda_1461` | 1461 | https://en.wikipedia.org/wiki/Siege_of_Trebizond_(1461) |
| `events_1453.json` | `caida_caffa_1475` | 1475 | https://en.wikipedia.org/wiki/Feodosia |

### 11.5 Owners, jugables y fuente de fronteras

- Owners de 1402 y 1453 tomados **exactamente** de `data/map_borders.json` (misma geometría y
  licencias documentadas en §9); las 47 regiones tienen owner válido en los tres años.
- Facciones por escenario = conjunto de owners de ese año: **21** en 1402 (base + brittany,
  burgundy, florence, milan, naples, ottoman, tamerlane) y **21** en 1453 (base + brittany,
  burgundy, florence, genoa, milan, ottoman, venice).
- `playable_factions` (elección de diseño de AG-1; ajustable por AG-0, el validador solo exige 8 ⊆ factions):
  - 1402: `ottoman`, `tamerlane`, `england`, `france`, `hre`, `hungary`, `castile`, `aragon`.
  - 1453: `ottoman`, `byzantium`, `england`, `france`, `burgundy`, `aragon`, `hre`, `hungary`.
- Fuentes históricas de fronteras: William R. Shepherd, *Historical Atlas* 1923-26 (PD), y mapas
  anuales de Wikimedia Commons verificados en §9.2 (1337, 1400 para 1402, 1444 para 1453).

### 11.6 Esquemas actualizados (Fase 3)

- `factions.schema.json`: enum de 23 ids; `government` admite `republic`; `start_year` ∈ {1337,1402,1453}.
- `characters.schema.json`: enum de facción y de `claims.target` de 23 ids; `born` ≤ 1460; `died`
  histórico real hasta 1520 o `null`; campos opcionales `reign_start`/`reign_end` (D-058).
- `regions.schema.json`: `year_data` exige 1337/1402/1453; owner de los 23 ids; mismos campos e
  `estimate`/`source` por año.
- `scenario.schema.json`: genérico para los 3 escenarios; `playable_factions` (8 exactos),
  `initial_state.regions` ∈ {1337,1402,1453}, `victory.control_pct` opcional (70 en 1402/1453).
- `events.schema.json`: año 1337-1500, facciones de 23 ids, `source` obligatorio; aplica a los 3 ficheros.

### 11.7 Estimaciones, correcciones históricas y limitaciones

1. **Población, riqueza y edificios 1402/1453**: estimaciones de diseño (`estimate: true`) obtenidas
   escalando los valores de 1337 y con ajustes por región (Constantinopla 70.000 en 1453, París
   550.000-600.000, El Cairo 450.000-500.000, Lombardía/Toscana/Flandes al alza); no son censos.
2. **Tesorerías y ejércitos iniciales**: balance de diseño derivado de la riqueza relativa; todos los
   ejércitos están en regiones propias de su facción ese año y usan unidades existentes de era III.
3. **Correcciones históricas a las tablas del GDD** (se prioriza exactitud de gobernante en el año):
   - HRE 1402: Ruperto de Baviera (el GDD cita a Segismundo por la corona dual; Segismundo queda
     como rey de Hungría y se le asigna claim al HRE).
   - Aragón 1402: Martín I (el GDD cita a Fernando I como regente; Fernando I se incluye como
     regente de Castilla y futuro rey de Aragón).
   - Castilla 1453: Juan II (el GDD cita a Enrique IV; en 1453 Enrique era aún heredero y se incluye
     como tal; reina desde 1454).
   - Otomanos 1402: Bayezid I (capturado en Ankara) con el interregno representado por sus hijos
     Mehmed I, Süleyman y Musa como herederos/pretendientes.
   - Mamelucos 1453: Al-Ashraf Inal (el GDD cita a Qaitbay, que no es sultán hasta 1468; Qaitbay
     figura como general de alto rango).
   - Hungría 1453: Ladislao V el Póstumo con Juan Hunyadi como regente/gobernador.
   - Bohemia 1453: Jorge de Poděbrady como regente/administrador (rey desde 1458).
4. **Personajes de 1337 con `died: null`** no se modifican (D-057): D-058 debe priorizar los nuevos
   `reign_start`/`reign_end` al seleccionar gobernante por año; aviso a AG-2 para el filtro de vivos.
5. **Valaquia** (GDD §4.4) no se incluye: no tiene región ni owner en el mapa de 47; futura Fase 4.
6. **Repúblicas**: Florencia, Génova y Venecia usan como gobernante a su líder/dogo (no dinastía),
   marcado en `note`; Milán y Nápoles son monarquías.
7. **Eventos**: fechas y contenidos contrastados con Wikipedia (URL por evento en la tabla §11.4);
   `news` es redacción propia; los efectos usan los tipos admitidos por el esquema §7.6.
8. **Muerte futura**: todos los personajes nuevos usan `died` histórico real (no `null`), salvo que
   no haya dato fiable; el motor filtra vivos por año con D-058.
9. **Facciones por año**: Génova y Venecia solo aparecen como facción/owner en 1453; Nápoles y
   Tamerlán solo en 1402 (no tienen región en el otro año según `map_borders.json`). El GDD §4.3
   menciona a Venecia/Génova en 1402, pero el mapa de contratos no les asigna región: se excluyen
   de `scenario_1402` para no inventar territorios.

## 12. Auditoría MVP-1337 (D-066) — eventos y balance

Auditoría de solo lectura de `data/events_1337.json`, `data/regions.json` (year_data 1337),
`data/characters.json` y `data/scenarios/scenario_1337.json` (2026-11-23). **No se modificaron
datos de 1337 en esta auditoría**; no fue necesaria ninguna decisión D-067. Se documentan aquí
los resultados para AG-4/AG-0.

### 12.1 Eventos 1337: 18/18 válidos

Todos los eventos tienen `year` en 1337-1399, `source` https, tipos de efecto soportados por
`EventResolver` y objetivos (facción/región/scope) existentes. Las pruebas `[SUITE] events` pasan
(12/12) y la Peste Negra se aplica una sola vez.

| Evento | Año | Trigger | Efectos (resumen) |
|---|---|---|---|
| `guerra_cien_anos_1337` | 1337 | year_reached | casus_belli England→France; relación -60 |
| `batalla_sluys_1340` | 1340 | war England/France | prestige England +15; relación -10 |
| `batalla_crecy_1346` | 1346 | war England/France | army_loss France 15 %; prestige England +25; relación -20 |
| `sitio_calais_1347` | 1347 | war England/France | prestige England +20; gold France -30 |
| `peste_negra_1348` | 1348 | year_reached | población -35 % (europe_west); apoyo -10 (europe) |
| `peste_negra_rebrote_1350` | 1350 | year_reached | población -10 % (europe_west) |
| `batalla_poitiers_1356` | 1356 | war England/France | army_loss France 20 %; prestige England +25; gold France -40 |
| `jacquerie_1358` | 1358 | year_reached | apoyo France -20; población France -5 %; gold France -20 |
| `paz_bretigny_1360` | 1360 | war England/France | paz England/France; prestige England +20; relación +20 |
| `guerra_civil_castellana_1366` | 1366 | year_reached | apoyo Castile -15; army_loss Castile 5 % |
| `batalla_najera_1367` | 1367 | war Castile/England | army_loss Castile 10 %; prestige England +10 |
| `guerra_cien_anos_reanuda_1369` | 1369 | year_reached | casus_belli England→France; relación -30 |
| `batalla_maritsa_1371` | 1371 | year_reached | apoyo Balkans -15; prestige Byzantium -10 |
| `cisma_occidente_1378` | 1378 | year_reached | prestige Papacy -100; relación Papacy/France -40; apoyo Europe_west -10 |
| `revuelta_ciompi_1378` | 1378 | year_reached | apoyo Toscana -20; gold Toscana -20 |
| `revuelta_campesina_1381` | 1381 | year_reached | apoyo England -20; gold England -15 |
| `batalla_kosovo_1389` | 1389 | year_reached | apoyo Balkans -20; prestige Hungary -10 |
| `cruzada_nicopolis_1396` | 1396 | year_reached | army_loss Hungary 20 %; prestige Hungary -20 |

**Verificado:** la Peste Negra 1348 aplica `population_modifier -0.35` a las regiones de las
facciones `europe_west` (población, mano de obra y pool de reclutas se escalan; suelo de 1.000
habitantes y 4 trabajadores), y `stability_modifier -10`; el ingreso bruto cae ~35 % y el neto
sigue siendo positivo con los ejércitos iniciales. No se repite (`fired_events`).
**Limitaciones detectadas:** (a) el evento no tiene efecto dinástico específico — `DynastySystem`
solo aplica enfermedad aleatoria (2 %/año a mayores de 50), no mortalidad de Peste Negra; (b) los
8 eventos con trigger `war` solo disparan si England/France o Castile/England están en guerra
declarada; el evento de 1337 crea casus belli y tensión (-60) pero no declara la guerra, así que
Sluys/Crécy/Calais/Poitiers/Brétigny/Nájera dependen de que el jugador o la IA declaren la guerra
(existe test de Sluys/Crécy con guerra forzada). Recomendación a AG-2: añadir efecto/estado inicial
de guerra anglo-francesa o garantizar que la IA la declare en 1338-1340.

### 12.2 Balance económico 1337 (40 trimestres sin órdenes, cosecha media 1,0)

| Facción jugable | Tesoro inicial | Ingreso bruto/q | Mantenimiento/q | Neto/q | Tesoro a 10 años |
|---|---:|---:|---:|---:|---:|
| Aragón | 7.000 | 1.356,7 | 13 | +1.343,7 | 60.804 |
| Bohemia | 9.000 | 863,9 | 14 | +849,9 | 43.000 |
| Castilla | 6.500 | 1.664,3 | 21 | +1.643,3 | 72.464 |
| Inglaterra | 8.000 | 1.311,3 | 24 | +1.287,3 | 59.520 |
| Francia | 12.000 | 3.935,0 | 30 | +3.905,0 | 168.536 |
| Sacro Imperio | 6.000 | 3.661,5 | 16 | +3.645,5 | 152.320 |
| Hungría | 7.000 | 931,7 | 17 | +914,7 | 43.536 |
| Polonia | 5.000 | 612,5 | 16 | +596,5 | 28.920 |

**Hallazgo crítico (inflación trivial):** con los ejércitos iniciales el mantenimiento es
13-30 oro/trimestre frente a 597-3.935 de ingreso; todas las jugables multiplican su tesoro por
5-14 en 10 años sin gastar. El reclutamiento de era I es igualmente trivial: pools iniciales de
47.000-267.000 hombres y 11 unidades disponibles (coste 20-130 oro por bloque de 200), mientras
el ingreso permite reclutar decenas de bloques por trimestre. **No es un bug de datos**: los
valores de región son estimaciones coherentes; el desequilibrio está en constantes de diseño de
`utils/game_constants.gd` (mantenimiento 2 oro/200 hombres/trimestre, divisor fiscal 100.000).
Recomendación a AG-2 (fuera de mi scope): subir `ARMY_UPKEEP_PER_200_MEN` a ~20-40 y/o bajar
ingresos fiscales/comerciales; simular 10 años × 8 facciones con AG-4. No se tocaron
`regions.json` ni `events_1337.json`.

### 12.3 Apoyo popular: descontento estructural en montaña

Simulación por región (sin revueltas) de los 40 trimestres: Austria (HRE), Transilvania y Croacia
(Hungría) tienen `terrain=mountain`, riqueza 35-55 y delta de apoyo **-2/trimestre** (déficit de
comida con el reparto inicial 55 % granjeros + sin bonus de riqueza); tras 4-5 años su apoyo llega
a 0 y provocan revueltas recurrentes (la Peste Negra -10 acelera el proceso). Las demás jugables
se mantienen en 60-100. Es un problema de la fórmula de apoyo/terreno (código), no de un valor
puntual de dato; cambiarlo a `forest` o subir la riqueza falsearía la geografía histórica.
Recomendación a AG-2: revisar `TERRAIN_FOOD`/`FOOD_NEED_PER_WORKER`/bonus de apoyo para montaña.

### 12.4 Coherencia de personajes, herencias y capitales (8 jugables)

- Los 8 gobernantes seleccionados para 1337 son los correctos (Edward III, Philip VI, Louis IV,
  John of Bohemia, Charles Robert, Alfonso XI, Peter IV, Casimir III); las 8 capitales existen.
  7/8 capitales son propias; Praga (HRE) pertenece a Bohemia (D-010, documentado).
- Sin referencias familiares rotas en las 8 casas; herederos seleccionados correctamente salvo
  **Polonia**: no hay ficha `role=heir` viva en 1337 y el fallback de `GameState._find_heir` elige
  a la esposa `aldona_de_lituania` (rol `spouse`) en lugar de un pariente varón; conviene que
  AG-2 excluya `spouse` del fallback o que se añada un heredero explícito en Fase 4 (cambio de
  `characters.json`, fuera del scope de esta auditoría).
- `validate_data` sin errores; suite completa `1469 pasados, 0 fallidos, 1 omitido` (incluye
  `[SUITE] events` 12/12).

## 13. Mercancías y `recruit_goods` (Fase 4 — D-069/D-070)

`data/trade_goods.json` (envelope D-009, objeto keyed por id) define las **10 mercancías** pedidas
en D-069. Los precios son **valores de diseño normalizados** (unidades de oro por unidad de bien,
con grano=10 como referencia), no cotizaciones históricas exactas: todas las fichas llevan
`"estimate": true`, y las URLs son referencias temáticas de la mercancía/producción, no tablas de
precios de época. La producción depende de `produced_by.terrain` y/o `produced_by.buildings`
(enum de terreno/edificios del juego); `used_by`/`consumption` son informativos para el
`TradeSystem` de AG-2, que calcula la producción por región.

| id | Nombre | Precio base | Producido por (terreno / edificios) | Uso | Consumo | Fuente temática |
|---|---|---|---|---|---|---|
| `especias` | Especias | 80 | coast/city · market | trade, consumption | luxury | https://en.wikipedia.org/wiki/Spice_trade |
| `pieles` | Pieles | 30 | forest · market | trade, consumption | luxury | https://en.wikipedia.org/wiki/Fur_trade |
| `lana` | Lana | 25 | plains · workshops | trade | industrial | https://en.wikipedia.org/wiki/Wool_trade |
| `vino` | Vino | 35 | plains · market | trade, consumption | luxury | https://en.wikipedia.org/wiki/History_of_wine |
| `sal` | Sal | 20 | coast · mine | consumption, trade | food | https://en.wikipedia.org/wiki/Salt |
| `grano` | Grano | 10 | plains · granary | consumption | food | https://en.wikipedia.org/wiki/Grain |
| `armas` | Armas | 60 | city · workshops | recruitment | military | https://en.wikipedia.org/wiki/Weapon |
| `caballos` | Caballos | 70 | plains · — | recruitment, trade | military | https://en.wikipedia.org/wiki/Horse |
| `hierro` | Hierro | 50 | mountain · mine | trade, recruitment | industrial | https://en.wikipedia.org/wiki/Iron |
| `madera` | Madera | 15 | forest · — | trade, recruitment | industrial | https://en.wikipedia.org/wiki/Timber |

**Nota:** no se modifica `regions.json` ni ningún `year_data` 1402/1453; la producción de bienes
se deriva en el motor a partir del terreno/edificios existentes (D-069), no de datos por año.

### 13.1 `recruit_goods` de unidades (D-070)

Añadido a **9 de las 17 unidades**; el resto no consume mercancías. La cantidad es **por bloque de
200 hombres** (`UNIT_MEN_PER_BLOCK=200`, D-070); el motor multiplica por `blocks = ceil(amount/200)`
y descuenta del inventario. Si falta el bien, el reclutamiento falla con motivo `missing_goods`
(sin gastar oro ni crear ejército).

| Unidad | Tipo | `recruit_goods` por bloque |
|---|---|---|
| `mounted_sergeants` | caballería | `{"caballos": 1}` |
| `men_at_arms` | caballería | `{"caballos": 2}` |
| `light_horseman` | caballería ligera | `{"caballos": 1}` |
| `steppe_cavalry` | caballería ligera | `{"caballos": 1}` |
| `mamluk` | caballería | `{"caballos": 2}` |
| `teutonic_knights` | caballería | `{"caballos": 2}` |
| `dismounted_men_at_arms` | infantería pesada | `{"armas": 1}` |
| `bombarda` | artillería | `{"hierro": 2, "madera": 1}` |
| `hussite_war_wagon` | especial/artillería | `{"madera": 2, "hierro": 1}` |

Justificación de artillería: la bombarda consume hierro (cañón/proyectiles) y madera (afuste), y
el carro húsita madera/hierro (carro y herrajes); es una decisión de diseño de AG-2/D-070,
documentada aquí. Las unidades sin `recruit_goods` (milicia, arqueros, ballesteros, almogávares,
piqueros, arcabuceros, jenízaros, etc.) no consumen mercancías de reclutamiento.

### 13.2 Verificación

- `trade_goods.json`: 10/10 bienes, ids únicos, `base_price` entero > 0, `produced_by` con
  terreno/edificios válidos, `used_by`/`consumption` admitidos, `source` https y `estimate:true`.
- `units.json`: 9/17 unidades con `recruit_goods`; 8/17 sin campo (correcto). El resto de campos
  de unidades no se modifica.
- `data/schema/trade_goods.schema.json` y `data/schema/units.schema.json` actualizados (draft
  2020-12, subconjunto D-004); `validate_data` valida ambos.
- AG-2 reconoce `trade_goods` como dataset de juego en el validador (coordinación D-069); con ello
  `validate_data` queda **0 WARN/0 errores**.
- Sin cambios en `year_data` 1402/1453 ni en scenarios congelados.

### 13.3 Costes de reclutamiento por tipo de unidad (D-075)

Ajuste de UX/balance (bug del usuario: «todas las unidades parecen costar lo mismo y la caballería
ligera era más barata que un arquero»). Se modifica **solo `cost.gold`** de `data/units.json`;
`cost.recruits` y `recruit_goods` se mantienen intactos. El coste es **por bloque de 200 hombres**
(oro) y no pretende ser un precio histórico exacto: es una **estimación de diseño** que ordena el
coste relativo por tipo. Regla aplicada: **toda la caballería > arqueros e infantería ligera**;
caballería pesada > caballería ligera; **artillería > caballería**; élites > milicia.

| Unidad | Tipo | `gold`/bloque | `recruits`/bloque | `recruit_goods` |
|---|---|---:|---:|---|
| `militia_spearman` | infantería ligera | 20 | 200 | — |
| `scottish_schiltron` | infantería (picas) | 30 | 250 | — |
| `crossbowmen` | arqueros/ballesteros | 45 | 150 | — |
| `longbowman` | arqueros | 60 | 200 | — |
| `light_horseman` | caballería ligera | 65 | 100 | caballos 1 |
| `steppe_cavalry` | caballería ligera | 70 | 120 | caballos 1 |
| `mounted_sergeants` | caballería | 85 | 120 | caballos 1 |
| `men_at_arms` | caballería pesada | 140 | 80 | caballos 2 |
| `mamluk` | caballería pesada/élite | 150 | 90 | caballos 2 |
| `teutonic_knights` | caballería pesada/élite | 160 | 70 | caballos 2 |
| `almogavar` | infantería ligera/élite | 55 | 150 | — |
| `swiss_pikeman` | infantería pesada | 60 | 250 | — |
| `dismounted_men_at_arms` | infantería pesada a pie | 95 | 100 | armas 1 |
| `arquebusier` | infantería con pólvora | 90 | 120 | — |
| `janissary` | infantería de élite | 120 | 80 | — |
| `hussite_war_wagon` | especial/artillería | 80 | 60 | madera 2, hierro 1 |
| `bombarda` | artillería | 200 | 40 | hierro 2, madera 1 |

**Justificación (estimación de diseño):** un caballo de guerra, su equipo, forraje y la reposición
de bajas encarecen la caballería frente a la infantería; la caballería pesada (hombre de armas,
mameluco, caballero teutónico) suma armadura y entrenamiento, de ahí 140-160. Los arqueros son más
baratos que la caballería (45-60) pero el arco largo exige entrenamiento y reclutamiento selectivo
(60). La milicia y las picas son la base barata (20-60); la infantería de élite con pólvora o
jenizaros sube a 90-120. La artillería es la más cara (bombarda 200; carro húsita 80 por su
naturaleza de carro). No se citan precios de época porque el valor es una **estimación de
balance**, no una fuente histórica; la referencia de diseño es GDD §6.4 y D-070/D-075. Se evita el
efecto «todo cuesta igual» y la anomalía «caballería ligera más barata que un arquero».

**Verificación:** 17/17 unidades con `cost.gold` entero > 0 y ranking correcto; `cost.recruits` y
`recruit_goods` sin cambios; JSON válido; `validate_data` 14 datasets/10 schemas, 0 WARN/0 errores
(AG-2 expone el coste por unidad, AG-3 lo muestra en la UI). Sin tocar 1402/1453.

---

*Generado por AG-1. Fase 0: Escenario 1. Fase 2: `map_borders.json` (§9) y `portrait` (§10).
Fase 3: escenarios 1402/1453, 23 facciones, 3 años de regiones, eventos y fuentes (§11).
Fase 3.3 MVP-1337: auditoría de eventos/balance (§12). Fase 4: mercancías, `recruit_goods` y
costes de reclutamiento (§13). Cualquier corrección de dato debe mantener la URL de fuente o
marcar `"estimate": true`; las reglas de validación están en `tools/validate_data.gd`
(D-004/D-009/D-061) y los criterios en GDD §12-§13.*

# Fuentes de datos — The Sovereign's Blood

| Campo | Valor |
|---|---|
| **Entregable** | `data/sources.md` (GDD §7.8 / §4.1) |
| **Autor** | AG-1 (Historian / Data) |
| **Fecha** | 2026-11-21 |
| **Alcance** | Escenario 1 — «Dos Coronas», año 1337 (GDD §4.2), Fase 0 |
| **Datasets cubiertos** | `factions.json`, `regions.json`, `characters.json`, `units.json`, `events_1337.json`, `scenarios/scenario_1337.json`, `schema/*.schema.json` |

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

*Generado por AG-1 para la Fase 0 del proyecto. Cualquier corrección de dato debe mantener la URL de fuente o marcar `"estimate": true`; las reglas de validación están en `tools/validate_data.gd` (D-004/D-009) y los criterios en GDD §12-§13.*

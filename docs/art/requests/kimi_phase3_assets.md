# Petición de assets externos a Kimi — Fase 3

| Campo | Valor |
|---|---|
| **Documento** | `docs/art/requests/kimi_phase3_assets.md` |
| **Versión** | 1.1 — 2026-11-22 (v1.0: propuesta provisional; v1.1: IDs y reparto alineados con los datos reales de AG-1) |
| **Autor** | AG-5 (Art Pipeline) |
| **Coordina / aprueba** | AG-0 (Coordinator) |
| **Referencias** | GDD v1.7 §10.2 y §10.3; `docs/architecture_contracts_fase3_scenarios.md` §4; decisiones **D-049** (cuadros de combate) y **D-062** (assets externos) |
| **Destinatario** | **Kimi** (generador externo) — el usuario / AG-0 le traslada este documento |
| **Estado** | Emitido y **alineado con los datos reales de AG-1** (175 fichas, 23 facciones, scenarios 1402/1453). IDs exactos en las Tablas A.1–A.3; listo para generar (ver §0.3) |
| **Alcance de la entrega** | 2 paquetes: **A) 69 retratos 256×256** (42 gobernantes + 27 herederos/regentes/claimants) y **B) 184 PNG de animación de combate** (17 unidades × idle/ataque/impacto/muerte). Sin código, sin datos, sin git |

---

## 0. Cómo usar este documento

### 0.1 Resumen de lo que se pide

| Paquete | Contenido | Cantidad | Formato de entrega |
|---|---|---|---|
| **A · Retratos** | Gobernantes de los escenarios **1402** y **1453** (21 facciones cada uno = 42 personas, sin duplicados) + herederos/regentes/claimants | **69 PNG** | `256×256` PNG, fondo pergamino, escudo heráldico integrado |
| **B · Animaciones** | `idle` (2), `attack` (4–6), `impact` (2), `death` (2) de las **17 unidades** | **184 PNG** | Lienzo fuente 512×512 / 512×640 / 512×341, RGBA transparente |

Los **51 sprites de marcha** (`<unit_id>_march_{1,2,3}.png`) y los **3 proyectiles** ya están entregados e integrados (GDD v1.6 §10.3, 17/17 QA APROBADO). La [hoja de contacto v2](../../../docs/screenshots/sprites_contact_sheet_v2.png) y la [tira a tamaño real](../../../docs/screenshots/sprites_units_v2_1x.png) fijan el estilo y la escala que deben respetar las nuevas animaciones.

### 0.2 Prioridad de producción

1. **A.1 — Retratos de gobernantes 1402 y 1453** (42 personas). Es el bloque que desbloquea los 5 slots de retrato de los escenarios nuevos.
2. **B — Animaciones** (mismo pipeline/estilo que la marcha ya aprobada).
3. **A.2 — Herederos y figuras clave** (27 fichas; se pueden producir después de los gobernantes).

### 0.3 Sobre los `character_id` (importante)

- **AG-1 ya publicó los datos** de 1402/1453: `data/characters.json` tiene 175 fichas, `data/factions.json` 23 facciones y existen `scenario_1402.json` / `scenario_1453.json`. Las Tablas A.1–A.3 se han generado **directamente de esos datos** (gobernante seleccionado con la regla D-058), así que los `character_id` son los **reales** y el nombre de archivo debe ser exactamente `<character_id>.png`.
- **Baseline auditado** (2026-11-22): 175 fichas, 23 facciones, `scenario_1402`/`scenario_1453`; hashes en `.ui_check_f3/_ag5_scripts/fallback_audit_v2.json`. Si AG-1 cambia un id después de la entrega, **renombrar el archivo** (`mv`); no es necesario rehacer el arte.
- **Nunca** generar retratos de personajes que no estén en las tablas ni reutilizar el retrato de un personaje para otro.


---

## 1. Estado del proyecto y garantía de «nunca hueco»

- **Escenario 1337:** 14 retratos finales integrados (`assets/art/portraits/<character_id>.png`, 256×256, referenciados por el campo `portrait` de `characters.json`).
- **Escenarios 1402 / 1453:** **datos ya integrados por AG-1** — `data/factions.json` (23 facciones), `data/characters.json` (175 fichas: 56 `ruler`, 31 `heir`, 5 `claimant`, 3 `regent`, 23 `general`, 40 `relative`, 10 `spouse`, 7 `advisor`), `data/regions.json` con `year_data`, `data/scenarios/scenario_1402.json` y `scenario_1453.json`, `events_1402/1453.json`.
- **Cobertura de retratos hoy:** 14/175 con PNG (8 %). Los **42 gobernantes** de 1402/1453 y las **27 fichas** de herederos/regentes/claimants **no tienen retrato todavía** → el motor muestra el fallback.
- **Fallback (D-062):** mientras un personaje no tenga PNG, el widget `scripts/ui/widgets/portrait_frame.gd` compone **pergamino + escudo heráldico de la casa + silueta por sexo/edad + corona si es gobernante**. No hay huecos y no hay que tocar código al llegar los assets: basta con que el PNG exista en `assets/art/portraits/` y que `characters.json` tenga el `portrait` (ver §5 de auditoría).
- **Regla de oro:** esta petición **no bloquea** el resto de Fase 3 (escenarios, tech, victoria, QA). Hasta que Kimi entregue, el juego funciona con fallback.


---

## 2. PAQUETE A — Retratos 256×256

### 2.1 Objetivo y cobertura

- **Qué es:** un retrato-busto de miniatura pintada, por personaje, que se muestra en 5 ubicaciones: mapa principal (soberano), árbol familiar, diplomacia, informe de batalla y corte. El mismo PNG se usa en todas.
- **Cobertura de esta petición:** **42 gobernantes** (21 de 1402 + 21 de 1453, todos personas distintas) + **27 herederos/regentes/claimants** = **69 retratos nuevos**. (Los 14 de 1337 ya existen; **no** se regeneran. Tras la entrega, el juego tendrá 83 retratos.)
- **Sin duplicados:** ningún personaje aparece en dos filas de las tablas; cada `character_id` se pide una sola vez.
- **Fuera de alcance (no se piden ahora):** `general`, `advisor`, `spouse` y `relative` (datos con fallback heráldico). Si AG-0 quiere ampliarlos, se añadirían como una Tabla A.4 en una revisión posterior del documento.

### 2.2 Especificación técnica del PNG (obligatoria)

| Atributo | Valor |
|---|---|
| Formato | **PNG** de 8 bits, **sin canal alfa** (RGB opaco) o RGBA con alfa 255 en todo el lienzo |
| Dimensiones | **256 × 256 px exactos**, sin margen ni borde extra |
| Fondo | **Pergamino pintado** (no plano uniforme): ocres cálidos con textura de acuarela/manuscrito, viñeteado sutil en bordes; **sin transparencia** |
| Composición | Busto 3/4 (cabeza y hombros), cabeza en el tercio superior, hombros ocupando la mitad inferior; figura llenando ≥ 80 % del ancho |
| Escudo heráldico | **Integrado en la imagen**, abajo a la derecha, ~28–32 % del ancho, con filete dorado; es **parte del PNG** (no lo dibuja el motor) |
| Marco dorado | **NO incluir**: el marco y las esquinas ornamentadas los dibuja el motor (`PortraitFrame._draw_frame`). Dejar ≥ 4 px de fondo libre en los bordes |
| Texto / marcas | **Cero texto, letras, números, firmas, marcas de agua o logotipos** (el nombre se renderiza en la UI) |
| Color | sRGB, sin perfil ICC incrustado, sin posterizar; iluminación cálida coherente con los 14 retratos |
| Nomenclatura | `<character_id>.png`, exactamente el id de la tabla (minúsculas, `_`, sin acentos) |

### 2.3 Hoja de estilo (fijada por los 14 retratos entregados)

**Referencia directa:** `assets/art/portraits/*.png` (14) y `docs/screenshots/portraits_contact_sheet_final.png`. Consultar varias para calibrar.

- **Técnica:** miniatura de manuscrito iluminado franco-flamenco del s. XV pintada con realismo de época, no pixel-art, no cómic, no render 3D, no fotografía. Pincelada visible pero limpia; borde de figura definido; sombreado suave; sin dithering ni contornos negros gruesos.
- **Paleta base (§10):** pergamino `#C9B184` / `#B08A55`, marrón tinta `#4A3520`, azul tinta `#2A4D8F`, grana `#8F2A2A`, dorado `#C9A227` / `#B08D2F`, verde `#4A7A3A`, púrpura imperial `#6A2C70`. Usar el color de facción del personaje como acento dominante de su indumentaria.
- **Parecido:** cuando exista efigie/retrato histórico fiable (p. ej. Mehmed II, Enrique V, Carlos VII, Federico III), basar rasgos en ella. Si no existe, rasgos y color de pelo/barba coherentes con la región, la casa y la década; **sin caricaturizar** al personaje.
- **Indumentaria y atributos por región/década:** ver columna «Atuendo / notas de retrato» de las Tablas A.1 y A.2. Coronas, tocas, turbantes y tocados según rango; clero sin corona sino tiara/gorro; repúblicas (Venecia, Génova, Florencia) **sin corona** (atuendo civil/dogal).
- **Consistencia:** misma escala de cabeza entre los 69 retratos (~90–120 px de alto de cabeza) e igual encuadre que los 14 de referencia, para que la rejilla de la UI no parezca heterogénea.
- **Blasones:** ver **Anexo A.1** (9 facciones nuevas) y **Anexo A.2** (facciones existentes). El escudo debe ser **legible a ~70 px** aunque el PNG sea 256×256: simplificar detalles sin falsear el blasón (leones, flores de lis, bandas, cruces, media luna, etc.).

### 2.4 Tabla A.1 — Gobernantes del escenario 1402 (21 facciones)

> **Datos reales de AG-1** (`data/characters.json` + `scenario_1402.json`, baseline en §0.3): se listan los 21 gobernantes que el motor selecciona para 1402 con la regla de D-058 (vivos en el año + reinado que lo cubre). Usar estos `character_id` exactos como nombre de archivo.

| # | `faction_id` | Facción | Gobernante (`character_id`) | Nombre y fechas | Casa | Reinado | Notas de retrato |
|---|---|---|---|---|---|---|---|
| 1 | `england` | Reino de Inglaterra | `henry_iv_england` | Enrique IV de Inglaterra (1367–1413) | plantagenet | r. 1399–1413 | Ropa inglesa de corte, collar lancasteriano, corona; mirada firme. |
| 2 | `france` | Reino de Francia | `charles_vi_france` | Carlos VI de Francia (1368–1422) | valois | r. 1380–1422 | Manto real con flores de lis, corona; rostro cansado, mirada ausente (sin caricatura). |
| 3 | `hre` | Sacro Imperio Romano Germánico | `rupert_hre` | Ruperto de Baviera, rey de romanos (1352–1410) | wittelsbach | r. 1400–1410 | Rey de romanos: corona e insignias imperiales sobrias; escudo de Wittelsbach (como Luis IV en 1337). |
| 4 | `bohemia` | Reino de Bohemia | `wenceslaus_iv_bohemia` | Wenceslao IV de Bohemia (1361–1419) | luxembourg | r. 1378–1419 | Gorro bohemio, barba espesa, ropas oscuras; corona de Bohemia. |
| 5 | `hungary` | Reino de Hungría | `sigismund_hungary` | Segismundo de Luxemburgo (1368–1437) | luxembourg | r. 1387–1437 | Corona húngara, pelo largo gris claro, barba; ropa de corte húngara. |
| 6 | `castile` | Reino de Castilla | `henry_iii_castile` | Enrique III de Castilla (1379–1406) | trastamara | r. 1390–1406 | Ropa sobria castellana, corona; rostro enfermizo. |
| 7 | `aragon` | Corona de Aragón | `martin_i_aragon` | Martín I de Aragón (1356–1410) | barcelona | r. 1396–1410 | Corona aragonesa, oro y grana. |
| 8 | `poland` | Reino de Polonia | `wladyslaw_ii_poland` | Władysław II Jagiełło (1362–1434) | jagiellon | r. 1386–1434 | Rasgos lituano-polacos, corona y manto Jagellón. |
| 9 | `scotland` | Reino de Escocia | `robert_iii_scotland` | Roberto III de Escocia (1337–1406) | bruce | r. 1390–1406 | Rey escocés mayor, corona Stewart. |
| 10 | `papacy` | Papado de Aviñón | `boniface_ix_papacy` | Bonifacio IX (1356–1404) | tomacelli | r. 1389–1404 | Tiara papal (Roma), rojo/dorado; rostro enérgico. |
| 11 | `granada` | Sultanato Nazarí de Granada | `muhammad_vii_granada` | Muhammad VII de Granada (1370–1408) | nazari | r. 1392–1408 | Turbante nazarí, verdes y rojos. |
| 12 | `mamluks` | Sultanato Mameluco | `faraj_mamluks` | Al-Faraj (1389–1412) | burji | r. 1399–1412 | Indumentaria mameluca de amir, turbante, riqueza. |
| 13 | `golden_horde` | Horda de Oro | `edigu_golden_horde` | Edigu (1352–1419) | borjigin | r. 1399–1419 | Emir tártaro, gorro de piel, barba; sin corona europea. |
| 14 | `byzantium` | Imperio Bizantino | `manuel_ii_byzantium` | Manuel II Paleólogo (1350–1425) | paleologo | r. 1391–1425 | Púrpura imperial, stemma bizantino. |
| 15 | `brittany` | Ducado de Bretaña | `john_vi_brittany` | Juan VI de Bretaña (1389–1442) | montfort | r. 1399–1442 | Armiño ducal bretón, corona ducal. |
| 16 | `burgundy` | Ducado de Borgoña | `philip_ii_burgundy` | Felipe II el Temerario (1342–1404) | valois_bourgogne | r. 1363–1404 | Ropas borgoñonas suntuosas, corona ducal (sin Toisón: se funda en 1430). |
| 17 | `florence` | República de Florencia | `maso_albizzi_florence` | Maso degli Albizzi (1343–1417) | albizzi | r. 1382–1417 | Ropaje civil florentino (lucco), sin corona (república). |
| 18 | `milan` | Ducado de Milán | `gian_galeazzo_milan` | Gian Galeazzo Visconti (1351–1402) | visconti | r. 1395–1402 | Corona ducal, terciopelo, armas Visconti. |
| 19 | `naples` | Reino de Nápoles | `ladislaus_naples` | Ladislao de Nápoles (1377–1414) | anjou_durazzo | r. 1386–1414 | Corona napolitana, ropas angevinas. |
| 20 | `ottoman` | Imperio Otomano | `bayezid_i_ottoman` | Bayezid I (1360–1403) | osman | r. 1389–1403 | Kaftán y turbante otomanos tempranos, barba; caudillo en campaña (Ankara). |
| 21 | `tamerlane` | Imperio de Tamerlán | `timur_tamerlane` | Tamerlán (1336–1405) | timurid | r. 1370–1405 | Gorro de piel, barba canosa, sin corona (soberano no europeo). |

### 2.5 Tabla A.2 — Gobernantes del escenario 1453 (21 facciones)

| # | `faction_id` | Facción | Gobernante (`character_id`) | Nombre y fechas | Casa | Reinado | Notas de retrato |
|---|---|---|---|---|---|---|---|
| 1 | `england` | Reino de Inglaterra | `henry_vi_england` | Enrique VI de Inglaterra (1421–1471) | plantagenet | r. 1422–1461 | Rey piadoso, ropa sencilla, corona lancasteriana. |
| 2 | `france` | Reino de Francia | `charles_vii_france` | Carlos VII de Francia (1403–1461) | valois | r. 1422–1461 | Ropa oscura sobria, corona Valois. |
| 3 | `hre` | Sacro Imperio Romano Germánico | `frederick_iii_hre` | Federico III de Habsburgo (1415–1493) | habsburg | r. 1440–1493 | Corona imperial, ropas oscuras, labio Habsburgo; escudo de Austria. |
| 4 | `bohemia` | Reino de Bohemia | `george_podebrady_bohemia` | Jorge de Poděbrady (1420–1471) | podebrady | r. 1452–1471 | Rey electo bohemio, ropa de corte, corona; tocado checo. |
| 5 | `hungary` | Reino de Hungría | `ladislaus_v_hungary` | Ladislao V el Póstumo (1440–1457) | habsburg | r. 1444–1457 | Niño-rey Habsburgo, corona húngara. |
| 6 | `castile` | Reino de Castilla | `john_ii_castile` | Juan II de Castilla (1405–1454) | trastamara | r. 1406–1454 | Rey castellano maduro, corona Trastámara. |
| 7 | `aragon` | Corona de Aragón | `alfonso_v_aragon` | Alfonso V el Magnánimo (1396–1458) | trastamara | r. 1416–1458 | Corona aragonesa + estilo italiano (Nápoles), barba. |
| 8 | `poland` | Reino de Polonia | `casimir_iv_poland` | Casimiro IV Jagellón (1427–1492) | jagiellon | r. 1447–1492 | Corona y manto Jagellón. |
| 9 | `scotland` | Reino de Escocia | `james_ii_scotland` | Jacobo II de Escocia (1430–1460) | stewart | r. 1437–1460 | Joven Stewart, corona. |
| 10 | `papacy` | Papado de Aviñón | `nicholas_v_papacy` | Nicolás V (1397–1455) | parentucelli | r. 1447–1455 | Tiara papal, libros/humanismo. |
| 11 | `granada` | Sultanato Nazarí de Granada | `muhammad_xi_granada` | Muhammad XI de Granada (Sa'd) (1396–1462) | nazari | r. 1453–1462 | Turbante nazarí, ropas granadinas. |
| 12 | `mamluks` | Sultanato Mameluco | `inal_mamluks` | Al-Ashraf Inal (1380–1461) | burji | r. 1453–1461 | Indumentaria circasiana mameluca. |
| 13 | `golden_horde` | Horda de Oro | `kuchuk_muhammad_golden_horde` | Küchük Muhammad (1391–1459) | borjigin | r. 1435–1459 | Khan tártaro, gorro de piel. |
| 14 | `byzantium` | Imperio Bizantino | `constantine_xi_byzantium` | Constantino XI Paleólogo (1405–1453) | paleologo | r. 1449–1453 | Púrpura imperial, águila bicéfala, rostro enérgico (retrato histórico). |
| 15 | `brittany` | Ducado de Bretaña | `peter_ii_brittany` | Pedro II de Bretaña (1418–1457) | montfort | r. 1450–1457 | Armiño bretón, corona ducal. |
| 16 | `burgundy` | Ducado de Borgoña | `philip_iii_burgundy` | Felipe III el Bueno (1396–1467) | valois_bourgogne | r. 1419–1467 | Toisón de Oro, ropas fastuosas, corona ducal. |
| 17 | `florence` | República de Florencia | `cosimo_medici_florence` | Cosimo de' Medici (1389–1464) | medici | r. 1434–1464 | Ropa civil oscura, sin corona, gesto de banquero. |
| 18 | `genoa` | República de Génova | `pietro_fregoso_genoa` | Pietro Fregoso (1417–1459) | fregoso | r. 1450–1458 | Ropas dogales rojas, sin corona. |
| 19 | `milan` | Ducado de Milán | `francesco_sforza_milan` | Francesco Sforza (1401–1466) | sforza | r. 1450–1466 | Condottiero/duque: armadura parcial + manto. |
| 20 | `ottoman` | Imperio Otomano | `mehmed_ii_ottoman` | Mehmed II (1432–1481) | osman | r. 1451–1481 | Turbante blanco, kaftán, nariz aguileña (referencia Gentile Bellini). |
| 21 | `venice` | República de Venecia | `francesco_foscari_venice` | Francesco Foscari (1373–1457) | foscari | r. 1423–1457 | Corno ducal, rojo veneciano. |

**Notas de encuadre para todos los retratos:** busto 3/4, corona/tocado según la tabla, escudo heráldico de la **facción** abajo a la derecha (ver Anexos A.1/A.2), fondo pergamino, sin marco ni texto. Los 42 gobernantes son **personas distintas**: no hay duplicados entre 1402 y 1453, y no se reutiliza ningún retrato de 1337.

### 2.6 Tabla A.3 — Herederos, regentes y *claimants* de 1402/1453 (27 fichas)

> Personajes con `role` `heir`/`regent`/`claimant` vivos en el año del escenario con fecha de muerte conocida (los herederos de 1337 con `died = null` quedan fuera: pertenecen al reparto de 1337). Si AG-1 ajusta la lista, se renombran archivos; no se rehace el arte.

| # | `character_id` | Personaje | Rol | Facción | Año | Vínculo / notas |
|---|---|---|---|---|---|---|
| 1 | `john_the_fearless` | Juan I de Borgoña, el Temerario | heir | Ducado de Borgoña | 1402 | Duque de Borgoña, heredero de Felipe el Audaz. |
| 2 | `john_viii_palaiologos` | Juan VIII Paleólogo | heir | Imperio Bizantino | 1402 | Heredero bizantino (futuro Juan VIII). |
| 3 | `henry_v_england` | Enrique V de Inglaterra | heir | Reino de Inglaterra | 1402 | Príncipe de Gales, heredero de Enrique IV; armadura/circlet. |
| 4 | `louis_dauphin` | Luis de Valois, delfín de Francia | heir | Reino de Francia | 1402 | Delfín de Francia (Luis de Valois, m. 1415), heredero de Carlos VI. |
| 5 | `yusuf_iii_nazari` | Yusuf III de Granada | heir | Sultanato Nazarí de Granada | 1402 | Heredero nazarí (futuro Yusuf III). |
| 6 | `giovanni_maria_visconti` | Giovanni Maria Visconti | heir | Ducado de Milán | 1402 | Heredero y sucesor de Gian Galeazzo (1402). |
| 7 | `mehmed_i_ottoman` | Mehmed I | heir | Imperio Otomano | 1402 | Hijo de Bayezid I; futuro sultán (Interregno). |
| 8 | `james_i_scotland` | Jacobo I de Escocia | heir | Reino de Escocia | 1402 | Heredero de Roberto III (futuro Jacobo I). |
| 9 | `shah_rukh` | Shah Rukh | heir | Imperio de Tamerlán | 1402 | Hijo y sucesor de Timur. |
| 10 | `ferdinand_i_aragon` | Fernando I de Aragón | regent | Reino de Castilla | 1402 | Regente de Castilla; futuro rey de Aragón. |
| 11 | `tokhtamysh` | Tokhtamysh | claimant | Horda de Oro | 1402 | Khan rival de la Horda de Oro (*claimant*). |
| 12 | `musa_celebi` | Musa Çelebi | claimant | Imperio Otomano | 1402 | Príncipe rival del Interregno otomano. |
| 13 | `suleyman_celebi` | Süleyman Çelebi | claimant | Imperio Otomano | 1402 | Príncipe rival del Interregno otomano. |
| 14 | `benedict_xiii` | Benedicto XIII (antipapa de Aviñón) | claimant | Papado de Aviñón | 1402 | Antipapa de Aviñón: *claimant* del Papado en 1402. |
| 15 | `ferrante_naples` | Fernando I de Nápoles | heir | Corona de Aragón | 1453 | Heredero de Alfonso V (Fernando I de Nápoles). |
| 16 | `francis_ii_brittany` | Francisco II de Bretaña | heir | Ducado de Bretaña | 1453 | Heredero de Pedro II. |
| 17 | `charles_the_bold` | Carlos el Temerario | heir | Ducado de Borgoña | 1453 | Heredero de Felipe el Bueno. |
| 18 | `henry_iv_castile` | Enrique IV de Castilla | heir | Reino de Castilla | 1453 | Heredero de Juan II (futuro Enrique IV). |
| 19 | `edward_westminster` | Eduardo de Westminster | heir | Reino de Inglaterra | 1453 | Príncipe de Gales (n. 1453), heredero de Enrique VI. |
| 20 | `piero_medici` | Piero de' Medici | heir | República de Florencia | 1453 | Hijo y heredero de Cosme de Médici. |
| 21 | `louis_xi_france` | Luis XI de Francia | heir | Reino de Francia | 1453 | Delfín, heredero de Carlos VII (futuro Luis XI). |
| 22 | `galeazzo_maria_sforza` | Galeazzo Maria Sforza | heir | Ducado de Milán | 1453 | Heredero de Francesco Sforza. |
| 23 | `bayezid_ii` | Bayezid II | heir | Imperio Otomano | 1453 | Heredero de Mehmed II. |
| 24 | `james_iii_scotland` | Jacobo III de Escocia | heir | Reino de Escocia | 1453 | Heredero de Jacobo II. |
| 25 | `margaret_anjou` | Margarita de Anjou | regent | Reino de Inglaterra | 1453 | Regente de Inglaterra (esposa de Enrique VI). |
| 26 | `john_hunyadi` | John Hunyadi | regent | Reino de Hungría | 1453 | Regente/gobernador de Hungría. |
| 27 | `richard_york` | Ricardo de York | claimant | Reino de Inglaterra | 1453 | Duque de York, *claimant* al trono inglés. |

### 2.7 Anexo A.1 — Blasones de las 9 facciones nuevas

> Escudo integrado abajo a la derecha del retrato, legible a ~70 px. Los gobernantes de facciones **ya existentes en 1337** reutilizan el escudo exacto de su retrato de 1337 (ver Anexo A.2). Las 9 facciones nuevas ya existen en `data/factions.json` (colores por facción disponibles).

| Facción | Blasón (descripción para pintar) | Colores | Notas |
|---|---|---|---|
| `brittany` | Armiño llano (campo blanco sembrado de motas de armiño negras) | Plata/negro | Ducado de Bretaña; sin cuarteles |
| `burgundy` | Bandado de seis piezas de oro y azur con bordura de gules | Oro/azur/rojo | Casa Valois-Borgoña |
| `florence` | Flor de lis de gules sobre campo de plata (lirio florentino) | Plata/rojo | República; sin corona en el retrato |
| `genoa` | Cruz de gules sobre campo de plata (San Jorge) | Plata/rojo | República/dogo; sin corona |
| `milan` | Biscione: víbora de azur coronada devorando a un niño, sobre plata | Plata/azur | Visconti (1402); Sforza (1453): cuartelar con león rampante Sforza |
| `naples` | Armas de Anjou: campo de azur sembrado de flores de lis de oro, bordura de gules | Azur/oro/rojo | Solo 1402 (Ladislao de Anjou-Durazzo) |
| `ottoman` | Emblema dinástico osmanlí: campo de gules con media luna de oro | Rojo/oro | No es escudo europeo; mantenerlo simple y legible |
| `tamerlane` | Emblema timúrida: tres círculos de oro en triángulo sobre campo de azur (sello de Timur) | Azur/oro | **Sin** caligrafía/texto árabe |
| `venice` | León alado de San Marcos de oro sobre campo de gules (libro sin texto) | Rojo/oro | República; sin corona (dogo con corno en el retrato) |

### 2.8 Anexo A.2 — Notas para facciones ya existentes

- **Reutilizar** el diseño de escudo de los 14 retratos de 1337 para la misma facción (Inglaterra: cuartelado con leones; Francia: flores de lis; Castilla: cuartelado castillo/león; Aragón: barras; Hungría, Bohemia, Polonia, Escocia, Papado, Granada, Mamelucos, Horda de Oro, Bizancio: los ya usados; Sacro Imperio: armas ya usadas).
- **Sacro Imperio 1402 (Ruperto de Baviera, Wittelsbach):** reutilizar el escudo de Wittelsbach del retrato de Luis IV (1337), que ya está en el set.
- **Sacro Imperio 1453 (Federico III):** escudo de Austria (campo de gules con faja de plata) o águila imperial; elegir uno y documentarlo en el README de entrega.
- **Francia 1402/1453:** usar «France moderne» (tres flores de lis de oro sobre azul), cambio heráldico posterior a 1376; mantener el estilo del escudo de 1337.
- **Papado:** `factions.json` conserva el nombre «Papado de Aviñón» del set 1337, pero en 1402 el gobernante es **Bonifacio IX (Roma)**: pintar tiara/llaves papales y anotar la decisión en el README. El antipapa Benedicto XIII (Tabla A.3) puede llevar tiara + escudo de su casa (Luna).
- **Mamelucos / Horda de Oro / Granada / Bizancio / Polonia / Escocia / Castilla / Hungría / Bohemia:** el mismo escudo que sus retratos de 1337 de esa facción.
- El escudo debe ser **coherente entre los dos escenarios** para una misma facción.

### 2.9 Checklist de aceptación — Paquete A

- [ ] **69 PNG** (42 gobernantes + 27 herederos/regentes/claimants) con los `character_id` exactos de las tablas.
- [ ] 256×256 exactos, PNG sRGB, fondo pergamino pintado, sin transparencia, sin marco, sin texto/marcas.
- [ ] Busto 3/4 con escala de cabeza consistente; escudo heráldico integrado abajo a la derecha y legible.
- [ ] Sin duplicar personas (cada `character_id` aparece una sola vez en las tres tablas).
- [ ] `_hoja_contacto_retratos.png` con rejilla etiquetada por `character_id` + `README.md` de entrega.

---

## 3. PAQUETE B — Hojas de animación de combate (17 unidades)

### 3.1 Objetivo y conteo

Completar la animación de las 17 unidades de `data/units.json`, que hoy solo tienen el ciclo de **marcha** (3 cuadros, ya integrado). Animaciones pedidas (GDD §10.3, D-049):

| Animación | Cuadros | Bucle | Uso en el juego |
|---|---|---|---|
| `idle` | **2** | sí | unidad en reposo (respiración/oscilación mínima, arma en guardia) |
| `attack` | **4** (cuerpo a cuerpo) o **6** (a distancia/artillería) | no | acción de ataque; el proyectil lo dibuja el motor (capa aparte), no la hoja |
| `impact` | **2** | no | unidad golpeada: impacto + retroceso/stagger |
| `death` | **2** | no | caída/derribo y cuadro final en el suelo |

**Total: 184 PNG** (34 idle + 82 de ataque + 34 impact + 34 death).

### 3.2 Especificación técnica (obligatoria)

| Atributo | Valor |
|---|---|
| Formato | **PNG RGBA** (fondo transparente, sin sombra de suelo; la sombra la añade el motor si procede) |
| Lienzo fuente | Igual que el set de marcha ya entregado: **512×512** (infantería/ranged), **512×640** (caballería), **512×341** (bombarda y carro húsita) |
| Producción | AG-5 genera los 64 px por LANCZOS: **64×64 / 64×80 / 64×43**. Se puede incluir `_raw_1024` opcional (mismo criterio que la marcha: 1024×1024, 1024×1280, 1536×1024) |
| Dirección | **Todos los cuadros miran a E** (derecha). El motor espeja para O/NO/SO/N (convención GK2). No entregar versiones espejadas |
| Ancla | **Pies/ruedas en el borde inferior**, centro horizontal del cuerpo. Mantener en todos los cuadros de una unidad la **misma línea de suelo** y el **mismo centro del cuerpo** que sus 3 cuadros `march_*` (tolerancia ≤ 2 px): así las transiciones marcha→idle→ataque→impacto→muerte no saltan |
| Cámara/escala | Misma escala, encuadre y perspectiva que el set de marcha de esa unidad (comparar con `assets/art/sprites/units/<unit_id>_march_1.png`). La figura no debe cambiar de tamaño entre animaciones |
| Proyectil | **No dibujar el proyectil en vuelo** en la hoja. El motor lo dibuja con `proyectiles/*.png` y trayectoria balística. Solo el fogonazo/llama de la boca del cañón (1–2 cuadros) puede ir en la hoja, sin humo persistente |
| Estilo | Miniatura pintada del s. XV, coherente con la marcha y los retratos §10.2: silueta clara, arma legible, sin dithering, sin contorno negro grueso, sin pixel-art |
| Nomenclatura | `<unit_id>_<anim>_<n>.png` con `anim ∈ {idle, attack, impact, death}` y `n` = 1..N **sin ceros a la izquierda** (igual que `march_1/2/3`). Ej.: `crossbowmen_attack_4.png` |
| Texto/marcas | Ninguna letra, marca de agua ni logotipo |

### 3.3 Tabla B.1 — Animaciones por unidad

| # | `unit_id` | Tipo | Tamaño | idle | attack | impact | death | Total | Notas de la animación de ataque |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `militia_spearman` | infantry | 64×64 | 2 | 4 | 2 | 2 | 10 | estocada de pica: preparación → estocada → sostener → recuperar |
| 2 | `scottish_schiltron` | infantry | 64×64 | 2 | 4 | 2 | 2 | 10 | lanza en ristre tras el targe: acometer y recuperar |
| 3 | `almogavar` | infantry | 64×64 | 2 | 4 | 2 | 2 | 10 | lanzamiento de jabalina: armar brazo → apuntar → suelta → recuperar (la jabalina sale del lienzo, el motor dibuja el proyectil) |
| 4 | `swiss_pikeman` | infantry | 64×64 | 2 | 4 | 2 | 2 | 10 | estocada baja de pica suiza, dos manos |
| 5 | `dismounted_men_at_arms` | infantry | 64×64 | 2 | 4 | 2 | 2 | 10 | golpe descendente de alabarda a dos manos |
| 6 | `janissary` | infantry | 64×64 | 2 | 6 | 2 | 2 | 12 | arco compuesto: tensar → anclar → apuntar → soltar → retroceso → recuperar |
| 7 | `arquebusier` | ranged | 64×64 | 2 | 6 | 2 | 2 | 12 | arcabuz de mecha: encender/levantar → apuntar → disparo → retroceso → recargar (sin pólvora en la hoja) → recuperar |
| 8 | `crossbowmen` | ranged | 64×64 | 2 | 6 | 2 | 2 | 12 | ballesta: cargar/levantar → apuntar → disparo → retroceso → recargar con cranequín → recuperar |
| 9 | `longbowman` | ranged | 64×64 | 2 | 6 | 2 | 2 | 12 | arco largo: tensar → anclar → apuntar → soltar → retroceso → recuperar |
| 10 | `mounted_sergeants` | cavalry | 64×80 | 2 | 4 | 2 | 2 | 10 | lanza desde la silla: bracear → estocada → sostener → recuperar |
| 11 | `men_at_arms` | cavalry | 64×80 | 2 | 4 | 2 | 2 | 10 | lanza en ristre: bajar lanza → carga → impacto → recuperar |
| 12 | `light_horseman` | light_cavalry | 64×80 | 2 | 4 | 2 | 2 | 10 | jabalina a caballo: armar → apuntar → suelta → recuperar |
| 13 | `steppe_cavalry` | light_cavalry | 64×80 | 2 | 6 | 2 | 2 | 12 | arco compuesto a caballo: tensar → anclar → apuntar → soltar → giro → recuperar |
| 14 | `mamluk` | cavalry | 64×80 | 2 | 4 | 2 | 2 | 10 | lanza en ristre + sable; elegir lanza (más legible a 64 px) |
| 15 | `teutonic_knights` | cavalry | 64×80 | 2 | 4 | 2 | 2 | 10 | lanza con banderola: bajar → carga → impacto → recuperar |
| 16 | `bombarda` | artillery | 64×43 | 2 | 6 | 2 | 2 | 12 | cañón: cebar → apuntar → fuego (fogonazo) → retroceso de cureña → recargar → recuperar |
| 17 | `hussite_war_wagon` | special | 64×43 | 2 | 6 | 2 | 2 | 12 | houfnice del carro: preparar → apuntar → fuego → retroceso → recargar → recuperar; la yunta de mulas permanece en el encuadre |

**Resumen:** idle 34 · attack 82 · impact 34 · death 34 = **184 PNG**.

### 3.4 Semántica de `impact` y `death` (importante para la legibilidad a 64 px)

- `impact_1`: golpe recibido (cabeza/cuerpo hacia atrás, arma desviada; caballería: caballo retrocede o encabrita; artillería: cureña sacudida). `impact_2`: recuperación del equilibrio (vuelve a la pose de idle).
- `death_1`: colapso/derribo (infantería cae; caballería: jinete cae o caballo se desploma; artillería: sirvientes caen, cañón volcado; carro: ruedas/ejes rotos). `death_2`: cuadro final en el suelo (queda fijo como último cuadro del estado muerte).
- En unidades de varios elementos (bombarda con artilleros, carro con yunta y ballesteros), mantener **todos** los elementos en los cuadros y alineados al mismo ancla; no recortar la yunta ni la cureña.

### 3.5 Consistencia con la marcha

- Comparar cuadro a cuadro con `<unit_id>_march_1.png` (misma altura de figura, misma línea de pies, mismo tamaño de arma). Las siluetas deben reconocerse como la misma unidad.
- **No** incluir sombra de suelo, ni fondo, ni marco, ni UI.
- Mantener la paleta y el acabado del set §10.3 (hoja de estilo fijada por el paquete v2); mismas convenciones de espejo E.
- Los 3 proyectiles (`proyectil_virote/flecha/piedra.png`) ya existen; no se piden nuevos proyectiles.

### 3.6 Integración prevista (para AG-2/AG-3; no la ejecuta Kimi)

Cuando llegue el paquete, AG-5 integrará la producción 64 px y AG-2 ampliará el campo `sprite_sheet` (propuesta, pendiente de contrato de AG-0):

```json
"sprite_sheet": {
  "frames": [".../march_1.png", ".../march_2.png", ".../march_3.png"],
  "animations": {
    "idle":   {"frames": [".../idle_1.png", ".../idle_2.png"], "fps": 2, "loop": true},
    "march":  {"frames": [".../march_1.png", ".../march_2.png", ".../march_3.png"], "fps": 6, "loop": true},
    "attack": {"frames": [".../attack_1.png", "..."], "fps": 10, "loop": false},
    "impact": {"frames": [".../impact_1.png", ".../impact_2.png"], "fps": 8, "loop": false},
    "death":  {"frames": [".../death_1.png", ".../death_2.png"], "fps": 5, "loop": false}
  },
  "size": [64, 64], "anchor": "bottom_center", "facing": "E"
}
```

Destino propuesto de archivos: `assets/art/sprites/units/animations/<unit_id>_<anim>_<n>.png` (producción) y `assets/art/sprites/units/animations/src/` (fuentes raw + `.gdignore`). **AG-0 debe confirmar esta ruta** antes de la integración.

### 3.7 Checklist de aceptación — Paquete B

- [ ] 17 unidades × (2 idle + 2 impact + 2 death) + ataques = **184 PNG** con la nomenclatura exacta.
- [ ] Mismos tamaños por tipo (64×64 / 64×80 / 64×43) que la marcha; lienzo fuente 512/640/341.
- [ ] RGBA transparente, sin sombra, E base, ancla pies-centro estable entre cuadros.
- [ ] Las 7 unidades a distancia/artillería incluyen 6 cuadros de ataque coherentes con el proyectil que dibuja el motor.
- [ ] `_hoja_contacto_animaciones.png` por unidad (tira de todos sus cuadros) + `README.md` de entrega.

---

## 4. Instrucciones de entrega (formato del ZIP)

### 4.1 Estructura del paquete

```
TSB_Assets_Fase3_Kimi_v3.zip
├── README.md                          # inventario, decisiones de estilo, incidencias
├── _hoja_contacto_retratos.png        # rejilla 69 retratos etiquetada por character_id
├── _hoja_contacto_animaciones.png     # 17 tiras de animación (idle/attack/impact/death)
├── portraits/
│   └── <character_id>.png             # 69 PNG 256x256
└── units_anim/
    ├── <unit_id>_idle_{1,2}.png       # 184 PNG RGBA, lienzo 512/640/341
    ├── <unit_id>_attack_{1..N}.png
    ├── <unit_id>_impact_{1,2}.png
    ├── <unit_id>_death_{1,2}.png
    └── _raw_1024/                     # opcional: originales 1024/1536 (mismo criterio que marcha)
```

- **ZIP único**, sin carpetas vacías ni archivos temporales (`Thumbs.db`, `__MACOSX`, `.DS_Store`).
- **Manifest:** incluir en el `README.md` una tabla `archivo | dimensiones | animación | unidad/personaje` (o `manifest.csv`). AG-5 verificará el conteo y las dimensiones con Pillow.
- **Nombres exactos** (sin espacios, sin acentos, minúsculas). Si un `character_id` cambia, renombrar antes de entregar y anotarlo en el README.

### 4.2 Comprobaciones técnicas que hará AG-5 al recibir

1. **Conteos:** 69 retratos + 184 animaciones (o el subconjunto acordado); sin archivos extra.
2. **Pillow:** dimensiones exactas, modo (retratos RGB/RGBA opaco; animaciones RGBA con transparencia real), PNG íntegros; retratos 256×256; animaciones 512×512 / 512×640 / 512×341.
3. **Nombres contra datos:** `character_id` ∈ `characters.json`; `unit_id` ∈ `units.json`; patrones `<unit_id>_<anim>_<n>`.
4. **Alineación:** bbox alfa de cada cuadro con línea de pies y centro de cuerpo estables respecto a la marcha (tolerancia ≤ 2 px) y sin recortes en los bordes.
5. **Integración:** copia a `assets/art/portraits/` y generación LANCZOS de la producción 64 px; `portrait` en `characters.json` (AG-1) y `sprite_sheet` ampliado (AG-2); carga en Godot headless sin errores.
6. **QA visual:** hojas de contacto a tamaño real (64 px) y capturas de los 5 slots de retrato y de las animaciones en N2/N3 (AG-4).

### 4.3 Qué NO entregar

- No incluir marcos, sombras, fondos de escena, texto ni UI.
- No reescalar a 64 px (lo hace AG-5 con LANCZOS); no entregar JPG/WebP.
- No versiones espejadas (O/NO/SO/N): el motor las genera.
- No arte de otros juegos ni material de terceros: todo original (regla §1).

---

## 5. Auditoría del fallback de retratos (D-062)

### 5.1 Veredicto

**El fallback está implementado y es «nunca hueco» por construcción; auditado en código, datos y QA previa, y probado en runtime (Godot 4.7.2 headless) con personajes reales de 1402/1453.** Resultado de la sonda: `bayezid_i_ottoman` (1402), `mehmed_i_ottoman` (1402), `frederick_iii_hre` (1453) y `margaret_anjou` (1453) devuelven `is_fallback() == true` con el id correcto; `edward_iii_plantagenet` (1337, con PNG) devuelve `false` (textura cargada). **RESULT: OK** — ningún hueco.

### 5.2 Auditoría de código — `scripts/ui/widgets/portrait_frame.gd`

| Aspecto | Evidencia | Resultado |
|---|---|---|
| Fondo siempre pintado | `_draw()` dibuja primero `_draw_parchment(inner)` y después textura **o** fallback (líneas 166–181) | Nunca fondo vacío |
| Cuándo cae al fallback | `_resolve_texture()` (119–134): sin dict, sin campo `portrait`, ruta inexistente (`ResourceLoader.exists` falso) o carga que no es `Texture2D` → `_is_fallback = true` | Cubre PNGs pendientes |
| Contenido del fallback | `_draw_fallback()` (208–282): escudo heráldico de la casa (`Heraldry.draw_shield`) + silueta por sexo/edad (niño/adulto/mayor, barba, velo femenino) + corona si `is_ruler` + escudo pequeño de alianza en el pecho | Heráldica + silueta, nunca hueco |
| Marco | `_draw_frame()` (303–323): marco dorado + esquinas + divisa | Presente también en fallback |
| API de verificación | `get_portrait_character_id()` (65) e `is_fallback()` (69) | Testeable |
| Resolución de ruta | Acepta `res://…png` o id suelto → `PORTRAIT_DIR/<id>.png` (124–134) | Flexible para AG-1/AG-3 |
| Sexo/edad | `_infer_sex()` (139–160) y `TSBGame.character_age` | Silueta correcta por defecto |
| Facción desconocida | `TSBGame.faction_color()` (tsb_game.gd:328–334) usa color de `factions.json` o un HSV determinista de reserva | Sin crash ni hueco (hoy las 23 facciones ya están en `factions.json`) |
| Casa desconocida | `Heraldry.charge_for()`/`heraldic_metal()` usan un emblema/metal determinista por hash | Escudo siempre dibujable |

**Los 5 slots** usan el widget: mapa (`world_map.gd:349,480`), árbol familiar (`family_tree.gd:98,500`), diplomacia (`diplomacy_screen.gd:144`), informe de batalla (`battle_report.gd:196`), corte (`court_overview.gd:33,137`); además aparece en batalla táctica (`tactical_map.gd:135`) y combate cerrado (`close_combat.gd:369`).

### 5.3 Auditoría de datos (2026-11-22, con los datos reales de AG-1)

| Comprobación | Resultado |
|---|---|
| Personajes en `characters.json` | **175** (1337 + 1402 + 1453) |
| Personajes con `portrait` | **14**, todos `role: ruler` (solo 1337), con archivo existente |
| PNG 256×256 válidos y únicos | **14/14**; 0 rutas rotas; 0 archivos huérfanos en `assets/art/portraits/` |
| Personajes **sin** retrato → fallback | **161/175 = 92 %**: 42 `ruler` (1402/1453), 31 `heir`, 40 `relative`, 23 `general`, 10 `spouse`, 7 `advisor`, 5 `claimant`, 3 `regent` |
| Gobernantes 1402/1453 con retrato | **0/42** → todos usan fallback hasta que Kimi entregue |
| Herederos/regentes/claimants pedidos | **27**, ninguno con retrato |
| Escenarios / facciones | `scenario_1402` y `scenario_1453` presentes; **23 facciones** en `factions.json` (con color/heráldica para las 9 nuevas) |
| Baseline | hashes de `characters.json`, `factions.json` y los 2 `scenario_*.json` en `.ui_check_f3/_ag5_scripts/fallback_audit_v2.json` |

Evidencia completa: `.ui_check_f3/_ag5_scripts/fallback_audit_v2.json`. Hoja de referencia + huecos: `.ui_check_f3/ag5_portraits_reference_and_gaps.png` (14 retratos reales + 42 gobernantes etiquetados con sus `character_id`; **sin arte inventado**).

### 5.4 Evidencia QA existente (sin cambios de código)

- **Sonda runtime AG-5 (2026-11-22, Godot 4.7.2 headless):** `.ui_check_f3/_ag5_scripts/fallback_probe.gd` (log: `fallback_probe.log`) → 4 personajes reales sin PNG (`bayezid_i_ottoman` 1402, `mehmed_i_ottoman` 1402, `frederick_iii_hre` 1453, `margaret_anjou` 1453) devuelven `is_fallback() == true` con id correcto; `edward_iii_plantagenet` devuelve `false` (textura final). **RESULT: OK**.
- `scripts/ui/dev/phase2_probe.gd:49–60`: comprueba retrato del gobernante con textura (`is_fallback() == false`) y retrato sin personaje → `is_fallback() == true` («nunca hueco»).
- `tests/qa_acceptance_fase2.gd` F2-C4: 14/14 gobernantes con textura, fallback para heredero sin portrait, 5 slots y sucesión. Reportado **PASS** en `docs/qa/fase2_report.md`.
- `tests/qa_acceptance_fase3_final.gd` F3F-C5: texturas 1337 + fallback sintético (`qa_synthetic_no_portrait`) y revisión de slots nuevos; criterio ya presente en el plan de QA final (`docs/qa/fase3_final_plan.md`).

### 5.5 Comportamiento con los datos nuevos (sin tocar código)

1. **Los datos ya están**: 42 gobernantes de 1402/1453 y 27 herederos/regentes/claimants existen en `characters.json` y **ninguno tiene `portrait`** → el widget muestra fallback en todos los slots. No hay hueco.
2. AG-1 puede rellenar `portrait` en cualquier momento (`res://assets/art/portraits/<character_id>.png`): si el archivo falta, `_resolve_texture()` cae al fallback; **en cuanto Kimi entregue el PNG, se carga automáticamente sin cambios de datos ni de código**.
3. Las 9 facciones nuevas ya existen en `factions.json`, así que el fallback usa su color/heráldica real en lugar del color determinista de reserva.
4. Tras la entrega de Kimi: 42+27 retratos nuevos con textura; el resto de personajes (generales, consejeros, familiares, cónyuges) sigue con fallback.

### 5.6 Plan de verificación (ejecutable ya con los datos de AG-1)

| # | Paso | Comando / método | Aceptación |
|---|---|---|---|
| V1 | Auditoría de datos y PNG | `.ui_check_f3/_ag5_scripts/portrait_audit_sheet_v2.py` (solo lectura) | 14/14 retratos válidos 256×256; 42 gobernantes + 27 fichas sin retrato detectados; 0 rutas rotas |
| V2 | Fallback unitario con personajes reales de 1402/1453 | `.ui_check_f3/_ag5_scripts/fallback_probe.gd` (Godot headless; ya ejecutada) | **PASS 2026-11-22**: 4/4 fallback (`true`) + `edward_iii_plantagenet` textura (`false`) |
| V3 | Regresión retratos F2 (5 slots + sucesión) | `"C:\\Godot\\Godot_v4.7.2-stable_win64_console.exe" --headless --path C:\\Proyectos\\TSB\\sovereigns-blood --script tests/qa_acceptance_fase2.gd` | F2-C4 PASS |
| V4 | QA final F3 (retratos/fallback) | `... --script tests/qa_acceptance_fase3_final.gd` | F3F-C5 PASS |
| V5 | Con arte de Kimi | repetir V2 con el PNG presente → `is_fallback() == false`; capturas de los 5 slots en partida 1402 y 1453 (AG-3/AG-4) | 5/5 slots con retrato o fallback, nunca vacío |

Si un `character_id` no aparece en `characters.json` al integrar, el arte se conserva en staging y se avisa a AG-0/AG-1 (no se reasigna a otro personaje).

### 5.7 Riesgos residuales

1. **Datos en evolución:** AG-1 acaba de publicar 1402/1453; si cambia ids/roles, renombrar archivos (coste bajo, §0.3).
2. **Personajes con `died = null` de 1337:** el motor los considera vivos en años posteriores (regla D-058); por eso la Tabla A.3 excluye a los herederos de 1337 sin fecha de muerte. Si AG-1 corrige esas fechas, revisar si alguno debe añadirse (no bloquea el arte de gobernantes).
3. **Consistencia de estilo** entre los 14 retratos y los 69 nuevos: revisar la hoja de contacto completa y regenerar solo las piezas desviadas.
4. **Fallback sin retrato para generales/consejeros/familiares:** aceptado por D-062; no bloquea Fase 3.


---

## 6. Inventario de referencia actual

### 6.1 Los 14 retratos integrados (referencia de estilo)

| # | `character_id` | Personaje | Facción | Casa | Archivo |
|---|---|---|---|---|---|
| 1 | `edward_iii_plantagenet` | Eduardo III | `england` | plantagenet | `assets/art/portraits/edward_iii_plantagenet.png` |
| 2 | `philippe_vi_de_valois` | Felipe VI de Valois | `france` | valois | `assets/art/portraits/philippe_vi_de_valois.png` |
| 3 | `ludwig_iv_wittelsbach` | Luis IV de Baviera | `hre` | wittelsbach | `assets/art/portraits/ludwig_iv_wittelsbach.png` |
| 4 | `jan_lucembursky` | Juan I de Luxemburgo | `bohemia` | luxembourg | `assets/art/portraits/jan_lucembursky.png` |
| 5 | `karoly_robert_anjou` | Carlos Roberto de Anjou | `hungary` | anjou | `assets/art/portraits/karoly_robert_anjou.png` |
| 6 | `alfonso_xi_borgona` | Alfonso XI el Justiciero | `castile` | borgona | `assets/art/portraits/alfonso_xi_borgona.png` |
| 7 | `pere_iv_d_arago` | Pedro IV el Ceremonioso | `aragon` | barcelona | `assets/art/portraits/pere_iv_d_arago.png` |
| 8 | `kazimierz_iii_piast` | Casimiro III el Grande | `poland` | piast | `assets/art/portraits/kazimierz_iii_piast.png` |
| 9 | `david_ii_bruce` | David II de Escocia | `scotland` | bruce | `assets/art/portraits/david_ii_bruce.png` |
| 10 | `benedict_xii` | Benedicto XII | `papacy` | fournier | `assets/art/portraits/benedict_xii.png` |
| 11 | `yusuf_i_nazari` | Yusuf I de Granada | `granada` | nazari | `assets/art/portraits/yusuf_i_nazari.png` |
| 12 | `an_nasir_muhammad` | An-Nasir Muhammad | `mamluks` | qalawun | `assets/art/portraits/an_nasir_muhammad.png` |
| 13 | `oz_beg` | Öz Beg Kan | `golden_horde` | borjigin | `assets/art/portraits/oz_beg.png` |
| 14 | `andronikos_iii_palaiologos` | Andrónico III Paleólogo | `byzantium` | paleologo | `assets/art/portraits/andronikos_iii_palaiologos.png` |

### 6.2 Sprites de marcha ya integrados (referencia del Paquete B)

- 17 unidades × 3 cuadros = **51 PNG** en `assets/art/sprites/units/` (64×64 / 64×80 / 64×43), fuentes en `src/`.
- Hojas: `docs/screenshots/sprites_contact_sheet_v2.png`, `docs/screenshots/sprites_units_v2_1x.png`, `docs/screenshots/sprites_units_v2_x4.png`.
- QA: `docs/qa/fase3_sprites_report.md` (17/17 APROBADO).

### 6.3 Proyectiles ya integrados

`assets/art/sprites/projectiles/proyectil_virote.png` (256×256), `proyectil_flecha.png` (256×256), `proyectil_piedra.png` (128×128) — mapeo D-048. No se piden nuevos.

---

## 7. Resumen para el usuario (para trasladar a Kimi)

1. **Dos paquetes en un ZIP** (`TSB_Assets_Fase3_Kimi_v3.zip`):
   - **69 retratos** 256×256: 42 gobernantes (1402/1453) + 27 herederos/regentes/claimants (Tablas A.1–A.3), fondo pergamino y escudo heráldico integrado, estilo de los 14 retratos actuales.
   - **184 PNG de animación** para las 17 unidades: idle(2), ataque(4–6), impacto(2), muerte(2), lienzo 512/640/341 transparente, mirando a E, misma escala/ancla que la marcha.
2. **Los IDs son los reales de los datos de AG-1** (Tablas A.1–A.3): el nombre del archivo debe ser exactamente `<character_id>.png`; si AG-1 los ajusta, se renombra el archivo (no se rehace el arte).
3. **Prioridad:** retratos de gobernantes → animaciones → herederos.
4. **Mientras no lleguen:** el juego sigue funcionando con el fallback heráldico (auditado en código/datos y **probado en Godot headless con gobernantes reales de 1402/1453**, §5); no hay huecos.
5. **Dudas de estilo o de blasón:** consultar con AG-0 (puede aportar los 14 retratos de referencia y la hoja de contacto de sprites v2).

---

*Fin del documento. Versión 1.1 — AG-5, 2026-11-22. Cambios en este documento: solo AG-5 con aprobación de AG-0 (`docs/art/requests/**`).*

**Registro de cambios**

- **v1.0 (2026-11-22):** primera emisión con IDs propuestos (datos de 1402/1453 aún en producción por AG-1).
- **v1.1 (2026-11-22):** alineado con los datos reales de AG-1 (`characters.json` 175 fichas, `factions.json` 23, `scenario_1402/1453`): Tablas A.1–A.3 regeneradas con los `character_id` definitivos (42 gobernantes + 27 herederos/regentes/claimants = 69 retratos); auditoría del fallback actualizada a los datos nuevos; plan de verificación V1–V5 ejecutable ya.

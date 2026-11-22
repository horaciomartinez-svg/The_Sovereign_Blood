# Notas de método — REA economía/menús GK2 (Fase 4)

**AG-REA · Fase 4 · GDD §3/§3.2 · 2026-11-22.** Anexo de `docs/rea/gk2_economy_military_family.md`.
Solo lectura sobre el directorio GK2; ningún `.EXE` abierto; sin texto literal ni assets copiados.

## 1. Herramientas y comandos usados

- PowerShell 7 (`pwsh`): `[IO.File]::ReadAllBytes`, aritmética de bytes, histogramas, entropía de
  Shannon, autocorrelación de bytes, perfiles por bloques, dumps hex acotados.
- `Get-ChildItem`/`Get-Command` para inventario de archivos y verificación de DOSBox.
- No se usó `rea-mcp`: la inspección hexadecimal/estadística fue suficiente para este alcance preliminar.
- No se usó git (prohibido por D-005); escritura solo en `docs/rea/**`.

Comandos representativos:

```powershell
$dir = "C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf"
$b = [IO.File]::ReadAllBytes("$dir\SCENARIO.GK2")
$c = New-Object 'int[]' 256; foreach($x in $b){$c[$x]++}
$h = 0.0; foreach($k in $c){ if($k -gt 0){ $p=$k/$b.Length; $h -= $p*[Math]::Log($p,2) } }
for($p=2;$p -le 700;$p++){ $eq=0; for($i=0;$i -lt $b.Length-$p;$i++){ if($b[$i] -eq $b[$i+$p]){$eq++} } }
```

## 2. Verificación de DOSBox (D-038)

| Comprobación | Resultado |
|---|---|
| `Get-Command dosbox*` (PATH) | sin coincidencias |
| `C:\Tools` | `ghidra`, `rea`, `stripe`; 0 entradas `dosbox*` |
| `C:\Program Files` / `(x86)` (filtro dos/emul/retro/scumm/box) | sin coincidencias |
| `Downloads`, `AppData\Local\Programs`, `scoop`, `chocolatey`, `C:\Games`, `C:\Emulators` | sin coincidencias |
| Búsqueda recursiva `*dosbox*` en `C:\Proyectos\TSB` | sin coincidencias |
| Gestores | `winget` y `scoop` presentes (no se usan: escribirían fuera del workspace) |

Conclusión: **menús no observados**; cualquier afirmación de comportamiento del original queda marcada
*[no observado]*. La checklist de UX es contrato propio, no descripción del original. Se aplica D-038
(limitación aceptada) igual que en el REA de batalla.

## 3. Inventario de datos y clasificación

| Archivo | Bytes | H (bit/B) | Clasificación |
|---|---:|---:|---|
| `SCENARIO.GK2` | 49.841 | 2,70 | Estado de mundo (escenario 1) |
| `SAVEDATA.GK2` | 47.137 | 3,00 | Estado de mundo (partida guardada, mismo esquema) |
| `GENDATA1-4.DAT` | 7.827 c/u | 2,67–4,02 | Rosters de personajes por escenario |
| `ZNAME.DAT` | 1.122 | 2,60 | 66 nombres de región de 17 B |
| `MAPDATA.DAT` | 177.031 | 6,52 | Mapa (codificación no concluyente) |
| `HEXKG.DAT` | 46.624 | 5,44 | 1.457 × 32 B; no concluyente |
| `HEXSG.DAT` | 43.332 | 3,63 | Celdas 1 B, relleno 0xC8 |
| `SUNIT.DAT` / `KPAT.DAT` / `GRPDATA.DAT` | 49.152 / 45.450 / 45.475 | 4,74 / 2,22 / 4,95 | Sprites/patrones/tiles |
| `KGRP/SGRP/OPENGRP/ENDGRP` | 58.656 / 144.576 / 306.342 / 638.436 | 6,19 / 5,13 / 6,63 / 6,63 | Bancos gráficos de grupo |
| `KAODATA` / `QKAODATA` | 730.368 / 262.944 | 5,86 / 5,70 | Retratos/ilustración |
| `PACKDATA` / `KOEI.DAT` | 461.898 / 8.839 | 6,37 / 5,64 | Gráficos empaquetados/UI |
| `USDATA1-4.DAT` | 1.456 / 2.184 ×3 | 2,36–2,65 | Personajes extra: nombre `char[16]` + datos |
| `DA_LENCH.MOB` | 490 | 3,23 | Módulo musical |

Hallazgo: **ningún archivo dedicado a precios/mercancías/mercaderes**. La economía de GK2, por lo que
los datos permiten inferir, es parte del estado por región/facción dentro de `SCENARIO`/`SAVEDATA`
(estructura documentada en Fase 0: prólogo 181 B + roster 99×27 B + tablas de mundo; el save sobrescribe
campos mutables del mismo esquema).

## 4. Comprobaciones dirigidas (economía)

1. **Búsqueda de archivo dedicado:** inventario completo (tabla §3). No hay catálogo corto de bienes ni
   tabla con estructura de precios identificable.
2. **Búsqueda de tablas candidatas dentro del estado de mundo:** se probaron heurísticas de ventanas de
   enteros pequeños (u16 en 1..999 y u8 en 1..200) sobre `SCENARIO`/`SAVEDATA`; las coincidencias
   obtenidas corresponden a las zonas ya conocidas de estado (texto/relleno y tablas de mundo), no a un
   catálogo aislable. **No concluyente**: no se puede atribuir semántica a campos concretos sin
   observación o documentación externa.
3. **Búsqueda de términos de mercancías/comercio en los datos** (barrido ASCII de una lista cerrada de
   términos): el barrido completo por archivo resultó demasiado costoso en esta sesión y se detuvo; **no
   se usa como evidencia**. No se transcribe ningún texto encontrado.
4. **Menús:** el texto de UI reside previsiblemente en `MAIN.EXE`/`OPEN.EXE`/`END.EXE`, que están prohibidos;
   no se inspeccionaron.

## 5. Fuentes históricas usadas (abiertas)

- Especias: <https://en.wikipedia.org/wiki/Spice_trade>
- Pieles: <https://en.wikipedia.org/wiki/Fur_trade>
- Lana: <https://en.wikipedia.org/wiki/Wool_trade>
- Vino: <https://en.wikipedia.org/wiki/History_of_wine>
- Sal: <https://en.wikipedia.org/wiki/Salt>
- Grano / madera / Hansa: <https://en.wikipedia.org/wiki/Hanseatic_League>
- Caballos: <https://en.wikipedia.org/wiki/Horses_in_the_Middle_Ages>
- Hierro: <https://en.wikipedia.org/wiki/Blast_furnace>
- Herramientas/armas (contexto): <https://en.wikipedia.org/wiki/Blacksmith>
- Rutas de seda/lujo (contexto): <https://en.wikipedia.org/wiki/Silk_Road>

Regla GDD §7.8: AG-1 fija cifras finales con `source` (URL) y `"estimate": true` cuando proceda. Las
asignaciones de producción del informe son plausibles para el s. XIV, no cifras definitivas.

## 6. Modelo propuesto (detalle para AG-1/AG-2)

`data/trade_goods.json` (esquema propuesto):

```json
{"schema_version":1,"goods":[
 {"id":"spices","name_es":"Especias","name_en":"Spices","category":"luxury",
  "base_price":120,"unit":"saco","weight":1,
  "produced_by":{"terrain":["coast"],"buildings":["market"]},
  "used_by":{"recruit":[],"consume":["court"]}},
 {"id":"horses","name_es":"Caballos","name_en":"Horses","category":"strategic",
  "base_price":80,"unit":"cabeza","weight":1,
  "produced_by":{"terrain":["plains","steppe"],"buildings":["stable"]},
  "used_by":{"recruit":["knight","hobelar"],"consume":[]}}
]}
```

Precio determinista por trimestre:

```
D(g,r) = población/1000 + guarnición + demanda_edificios
S(g,r) = Σ trabajadores_asignados × factor_terreno × factor_edificio (+ importaciones)
P_t(g) = 0,7·P_{t−1} + 0,3·base(g)·clamp(1 + 0,6·(ΣD−ΣS)/max(ΣS,1), 0,5, 2,0) · ruido(±5 %, rng)
```

Comerciantes: capacidad 40 unidades/trimestre por comerciante; sin comerciantes no hay compra/venta;
pacto comercial +25 % volumen (GDD §5.4); expedición 2 PG, retorno 2 trimestres, riesgo de pérdida.
Cota: comercio ≤ ~20–25 % de la economía base (D-069), con sumideros de ejército/corte (D-068).
Save (§7.7): `inventory{g:qty}`, `merchants`, `market.prices{g}`, `trade_routes[]`, `expeditions[]`,
`save_version++` con migración (inventario vacío, precios base).

## 7. Plan de pruebas sugerido (QA Fase 4)

1. Determinismo: misma semilla + mismas acciones → mismo hash de save con mercado activo.
2. 10 años × 8 facciones: inventario nunca negativo; precios dentro de [0,5×base, 2,0×base]; comercio
   ≤ 25 % de ingresos.
3. Gate de comerciantes: 0 comerciantes → botones deshabilitados con motivo; con 1+ → volumen > 0.
4. Consumo de reclutamiento: caballería descuenta caballos, infantería pesada descuenta armas.
5. Save/load: inventarios/precios/comerciantes exactos tras cargar (hash).
6. UX: 12 checks de la tabla §4 del informe, con captura por pantalla.

## 8. Limitaciones declaradas

- **No observado:** menús Economía/Militar/Familia y comportamiento del original (DOSBox ausente, D-038).
- **No concluyente:** campos económicos de `SCENARIO`/`SAVEDATA`; existencia de sistema de mercancías o
  mercaderes en GK2. No se afirma que no exista: solo que no hay evidencia estructural aislable y no se
  persigue un port 1:1.
- **Legal:** sin `.EXE`, sin desensamblado, sin texto literal, sin assets; fuentes históricas abiertas
  citadas; el informe es consumible para C1 y para AG-1/AG-2/AG-3 sin material derivado de Koei.

## 9. Addendum D-074/D-075/D-076 — búsquedas de límites y costes

### 9.1 Qué se buscó y cómo

| Búsqueda | Comando/lógica | Archivos | Resultado |
|---|---|---|---|
| Secuencias ascendentes `u8` (ids o costes) | para `s` en {4,6,8,10,12,16,20,24,32}, inicio `o` con `b[o]≤3` y 13 valores estrictamente crecientes a paso `s` | `SCENARIO.GK2`, `SAVEDATA.GK2`, `GENDATA1.DAT`, `KGRP.DAT`, `KOEI.DAT` | **0 secuencias** |
| Secuencias ascendentes `u16` (costes/precios) | para los mismos pasos, inicio `o` con `u16≤100` y 11 valores estrictamente crecientes a paso `s` | `SCENARIO.GK2`, `SAVEDATA.GK2`, `GENDATA2.DAT`, `GRPDATA.DAT` | **0 secuencias** |
| Tablas de acciones/límites con banderas por facción | inventario + revisión de secciones por entropía/perfil (Fase 0/2) | todos los `.DAT`/`.GK2` | no hay tabla fija; `actions_used` es estado de turno (runtime) |
| Textos/secuencia de menús | búsqueda de texto de UI en datos | todos los `.DAT`/`.GK2` | no determinable: el texto de UI reside en los `.EXE` |

Evidencia de negativos: los barridos no devolvieron candidatos; no se conserva ningún artefacto. La
ausencia de tabla **no prueba** que GK2 carezca de costes o límites: prueba que no están en los datos
accesibles (probablemente constantes del ejecutable, protegido por §3). Por eso D-074/D-075 se documentan
como diseño propio y no como port.

### 9.2 Contratos y referencias usadas para el addendum

- `docs/architecture_contracts_fase4.md` §7.1 (D-074/D-075): `actions_used` por facción/turno, API
  `GameState.mark_action_used/is_action_used/reset_turn_actions`, motivos `action_used`; exenciones
  (reclutar/entrenar/disolver, trabajadores, mercado); costes diferenciados con caballería > arqueros/
  infantería y artillería > caballería; C13/C14 del QA.
- D-074/D-075/D-076 (`docs/decisions.md`) y D-038 (observación no disponible).
- Lecciones UX del addendum (ahora §10.1–§10.3 de este anexo): clasificación corte/logística, píldora
  "1/turno", motivos diferenciados, gate por objetivo, doble clic seguro, persistencia/migración, coste
  completo por tarjeta y regla de tier con test automático.

### 9.3 Límites del addendum

- **No observado:** secuencia exacta de menús y gating del original (DOSBox ausente, D-038).
- **No concluyente:** si GK2 limita estas acciones por turno y con qué costes; sin ejecutable no hay
  evidencia.
- **Sin material derivado:** sin `.EXE`/desensamblado, sin texto literal, sin assets; no se toca
  1402/1453; scope `docs/rea/**` y sin git.

## 10. Detalle del addendum D-074/D-075 (movido del informe para respetar ≤2 páginas)

### 10.1 Lecciones UX — acciones 1/turno frente a repetibles

- **Clasificar por naturaleza, no por pantalla:** órdenes de corte (diplomacia, familia, construcción,
  espionaje, expedición) = **1/turno**; logística (reclutar/entrenar/disolver, asignar trabajadores,
  comprar/vender) = **repetible**. La UI debe hacer visible la distinción sin que el jugador memorice reglas.
- **Marca persistente:** píldora "1/turno" en acciones gateadas; tras usarlas, botón deshabilitado con
  check y tooltip "Usado este turno" (y "para este objetivo" cuando aplique). Las repetibles no llevan
  píldora: muestran contador/cantidad.
- **Motivos de deshabilitado diferenciados:** usado vs sin PG vs requisito no cumplido vs objetivo ya
  usado. Un botón gris sin motivo es un bug de UX.
- **Diplomacia/espionaje por objetivo:** el gate es por acción **y** objetivo; la lista debe marcar cuáles
  se usaron este turno, no deshabilitar la pantalla entera.
- **Doble clic y carreras:** el motor rechaza el duplicado (`action_used`) aunque la UI falle, sin doble
  gasto de PG/oro; la UI puede ser optimista pero la autoridad es el estado.
- **Reinicio y persistencia:** al terminar turno los botones se rehabilitan; `actions_used` viaja en el
  save y las partidas antiguas migran a conjunto vacío.
- **Repetibles con control:** reclutar varias veces exige coste acumulado y límites (pool, oro, mercancías)
  visibles; "repetible" no debe significar "sin freno".

### 10.2 Lecciones UX — costes relativos por tipo de unidad

- **Tier visible:** infantería < arqueros < caballería ligera < caballería pesada < artillería. La
  caballería ligera no debe ser más barata que un arquero largo y la artillería debe superar a cualquier
  caballería (D-075).
- **Coste completo por tarjeta:** oro + hombres del pool + mercancías (`caballos`/`armas`) + PG si aplica;
  total para la cantidad seleccionada y tesoro proyectado. Comparación sin abrir fichas.
- **Comparación:** ordenar/filtrar por coste, secundario "oro por hombre" y etiquetas de tier con tooltip
  que explique el porqué (caballo + armadura + entrenamiento), no solo el número.
- **Nada oculto:** si la unidad consume caballos, se ve antes de reclutar; si falta el bien, botón
  deshabilitado con motivo. La IA paga la misma tabla (sin descuentos).
- **Validación de datos:** test que afirme `cost(caballería) > cost(arqueros/infantería ligera)` y
  `cost(artillería) > cost(caballería)`; los valores se cambian solo en `units.json` + `sources.md §13`.

### 10.3 Checklist verificable para D-074/D-075 (C13/C14)

| # | Criterio verificable |
|---:|---|
| 1 | El motor rechaza una segunda diplomacia (misma acción+objetivo) con motivo `action_used`; PG/estado intactos |
| 2 | Rechaza 2.º matrimonio/acción familiar, 2.ª construcción, 2.º espionaje por objetivo y 2.ª expedición en el turno |
| 3 | Reclutar/entrenar/disolver, asignar trabajadores y comprar/vender permiten **varias** operaciones por turno |
| 4 | `actions_used` se resetea al empezar turno, se conserva en save/load y migra en partidas antiguas |
| 5 | La UI deshabilita la acción usada con tooltip y distingue usado / sin PG / requisito no cumplido |
| 6 | Doble clic o reintento no produce doble gasto; el feedback explica el rechazo |
| 7 | Cada tarjeta de unidad muestra oro + hombres + mercancías, total para la cantidad y tesoro resultante |
| 8 | Los 17 tipos tienen coste diferenciado por tier (caballería > arqueros/infantería; artillería > caballería) |
| 9 | Reclutar deduce exactamente `cost.gold` y `recruit_goods`; si falta algo no hay deducción parcial y hay motivo |
| 10 | Se puede comparar/ordenar por coste; el tier se explica con tooltip; sin costes ocultos |
| 11 | Test automático de la regla de tiers y de costes distintos; `sources.md §13` documenta los valores |
| 12 | Sin regresión: `validate_data` 0 WARN/0 errores y C1–C14 del QA de Fase 4 en verde |

**Nota:** el informe `gk2_economy_military_family.md` conserva el resumen de §10 y remite aquí; este anexo
no tiene límite de páginas y es la referencia completa para C1 y para AG-1/AG-2/AG-3.

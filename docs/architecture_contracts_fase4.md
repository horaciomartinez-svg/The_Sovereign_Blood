# Contrato de integración — Fase 4: profundidad GK2 (MVP-1337)

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-23 |
| **Autoridad** | AG-0; directiva `prompt_DSH_fase4_profundidad_v1.md` + GDD v1.9 |
| **Partes** | AG-REA, AG-1, AG-2, AG-3, AG-4 |
| **Restricciones** | 1402/1453 congelados (D-066); sin arte externo (sprites existentes + generación por código); REA legal §3 (sin `.EXE`, sin texto transcrito, sin copiar assets); sin nuevas mecánicas fuera de esta lista |

## 1. Datos (AG-1)

### 1.1 `data/trade_goods.json` + schema (D-069)
Envelope D-009, 8-12 mercancías; campos mínimos:
```json
{"schema_version":1,"trade_goods":{
  "especias":{"name":"Especias","base_price":80,"produced_by":{"terrain":["coast"],"buildings":["market"]},"used_by":["consumption"],"consumption":"luxury","source":"..."},
  "...":{}
}}
```
Lista prevista (10): `especias`, `pieles`, `lana`, `vino`, `sal`, `grano`, `armas`, `caballos`, `hierro`, `madera`.
`produced_by` usa `terrain` (plains/forest/mountain/coast/city) y/o `buildings` (taller/mercado/granero…).
`used_by`: `recruitment` (armas/caballos), `consumption` (grano/sal), `trade` (resto). Fuentes en `data/sources.md` §13.
Schema en `data/schema/trade_goods.schema.json`; `validate_data` debe validarlo con 0 WARN (reconocerlo como dato de juego).

### 1.2 `data/units.json` — `recruit_goods`
Añadir a las 17 unidades un campo opcional `recruit_goods: {"caballos": N}` / `{"armas": N}`:
caballería (mounted_sergeants, men_at_arms, light_horseman, steppe_cavalry, mamluk, teutonic_knights) → `caballos`;
infantería pesada (dismounted_men_at_arms) → `armas`; artillería (bombarda/hussite) y pólvora → opcional `hierro`/`madera` si AG-2 lo decide y lo documenta. Schema actualizado; el resto de unidades sin campo (no consumen).

### 1.3 `data/tutorial_script.json` (D-073)
Envelope con `steps`: `[{id, title, text, objective, highlight, condition, order}]`; 8-10 pasos del primer año:
mapa, trabajadores, familia (educación/consorte), diplomacia, mercado, ejércitos (reclutar/entrenar), terminar turno, batalla N1, guardar.
`highlight` es un identificador de UI (`map_region`, `workers_panel`, `family_button`, `diplomacy_button`, `market_button`, `military_button`, `end_turn_button`, `battle_report`, `save_button`); `condition` un enum (`open_region`, `assign_workers`, `open_family`, `open_diplomacy`, `open_market`, `open_military`, `end_turn`, `battle_played`, `saved`). Textos en español, 2-3 líneas, sin hardcodear en GDScript.

### 1.4 Manual (D-072)
`docs/MANUAL_DEL_JUGADOR.md` (AG-1) con las 10 secciones del prompt §6, español claro, ejemplos concretos; AG-2/AG-3 aportan detalles técnicos/UI. Debe poder abrirse con `OS.shell_open` en ejecución desde proyecto y tener resumen «Ayuda» en el menú de consejo.

## 2. Estado y sistemas (AG-2)

### 2.1 Inventario y comercio (`TradeSystem` o extensión de `EconomySystem`, D-069)
Estado serializable en `GameState.state`:
```json
"trade": {"inventory": {"faccion": {"grano": 120.0, "caballos": 8.0, "...": 0.0}},
          "prices": {"region": {"grano": 1.1}}, "merchants_assigned": {"faccion": 12},
          "trade_pacts": [[a,b]], "expeditions": [{"faction","good","qty","return_turn"}]}
```
API: `get_inventory(faction_id)`, `get_good_price(faction_id/region_id, good_id)`, `can_trade(faction_id)` (requiere comerciantes asignados > 0), `buy(faction_id, region_id, good_id, qty)`, `sell(...)`, `get_merchants(faction_id)`, `send_expedition(faction_id, good_id, qty)` (2 PG, retorno N=2 trimestres, determinista), `produce_quarter(faction_id)`.
- Producción por región según `produced_by` (terreno/edificios) → inventario de facción cada trimestre.
- Precio `base_price × factor` con factor por inventario (escasez) y un multiplicador aleatorio pequeño del RNG de partida (determinista).
- Consumo: grano/sal sostienen apoyo; armas/caballos se descuentan al reclutar.
- Sin comerciantes asignados → compra/venta rechazadas con motivo.
- Comercio exterior: solo con pacto comercial o expedición; nunca con facción en guerra.
- Balance: ingreso de comercio ≤ ~20-25 % de la economía base; simulación 10 años ×8 sin inflación (métricas D-068).

### 2.2 Ejércitos (`MilitarySystem`, D-070)
- `recruit(..., goods=True)` consume `recruit_goods` del inventario (falla con motivo si falta); API `get_faction_army_summary(faction_id)` agrega por tipo: count, men, strength, avg morale/experience, unit sprite path (`<unit_id>_march_1.png`).
- `train_unit(faction_id, unit_id, amount)` / `train_army(army_id)`: +experiencia/media, coste oro + 1 PG, tope (p.ej. 100).
- `disband_unit(faction_id, unit_id, amount)` / `disband_army(army_id)`: libera pool regional (reparto determinista), devuelve 50 % del oro de reclutamiento; sin estados huérfanos.
- Reclutamiento por región existente se mantiene; la pantalla añade gestión global por tipo.

### 2.3 Familia (`DynastySystem`, D-071)
`spend_time_with_consort(faction_id)`: requisitos gobernante vivo + consorte válida (viva, no enferma, edad fértil); coste 2-3 PG; una vez por trimestre (`last_consort_turn`/`consort_cooldown`); efecto: `fertility_bonus_until_turn` (2-4 trimestres) que aumenta la probabilidad de nacimiento; +pequeño prestigio/relación; falla con motivo claro. La educación automática (D-020) se mantiene.

### 2.4 Dificultad y tutorial (`TutorialSystem`/`GameState`, D-073)
- `difficulty`: `"beginner"|"normal"` en `state`; Principiante = advisor activo + multiplicador de agresividad IA (constante tunable, p.ej. 0.75); Normal = advisor off + 1.0.
- `tutorial`: `{active, step_index, completed_steps[], skipped}` serializable; API `tutorial_advance(condition_id)`, `tutorial_skip()`, `get_tutorial_step()`, `is_tutorial_active()`; al iniciar partida en beginner con tutorial activo.
- Save/load: los campos `trade`, `tutorial`, `difficulty`, `consort` viajan en `to_dict/from_dict`; migración de `save_version` si procede (documentar; si se sube, migrar v1→v2 con defaults).
- IA: usa reglas de comercio/reclutamiento sin trampas; no rompe determinismo.

## 3. UI (AG-3)

- **Mercado** (ampliación de Economía o pantalla propia): inventario por bien, precio y factor, comerciantes, botones Comprar/Vender (cantidad), expedición de mercaderes, feedback de oro/volumen; sin comerciantes → estado deshabilitado con motivo.
- **Ejércitos:** rejilla por tipo con sprite `march_1` escalado, count, fuerza, moral/experiencia; Reclutar (oro+pool+mercancías), Entrenar (oro+1 PG), Disolver con confirmación; feedback; captura `army_management.png`.
- **Familia:** botón «Pasar tiempo con la consorte» con coste/cooldown, feedback de fertilidad/prestigio y motivo si no es válido.
- **Manual:** botón en menú principal (OS.shell_open al MD) y «Ayuda» en consejo (resumen); captura.
- **Dificultad:** selector Principiante/Normal en selección de escenario; Principiante activa Consejero.
- **Consejero:** panel lateral con avatar heráldico generado por código, nombre «El Consejero», paso actual, texto, botón Saltar; resaltado del elemento de UI (`highlight` target) y avance por condición; capturas `tutorial_consejero.png`, `tutorial_highlight.png`.
- Sin botones muertos; PG/feedback visibles; 1920×1080; capturas de todas las pantallas nuevas.

## 4. QA (AG-4) — C1-C12 del prompt

C1 REA legal (≤2 páginas, 0 `.EXE`, sin texto transcrito); C2 trade_goods+schema+fuentes, validate 0 WARN; C3 comercio solo con comerciantes, precios fluctúan, sim 10 años sin inflación; C4 pantalla ejércitos con imágenes/conteos y reclutar/entrenar/disolver efectivos; C5 reclutamiento consume mercancías (caballos/armas); C6 consorte bonus/cooldown/estados íntegros; C7 Manual 10 secciones y accesible; C8 tutorial JSON/resaltes/salto y Principiante vs Normal; C9 save/load con inventario y tutorial (migración si aplica); C10 no regresión (run_all ≥1742/0, validate 0, editor 0, F1/F2/F3/MVP/anim/tiles); C11 1402/1453 diff 0 y sin arte externo; C12 UX sin botones muertos, PG/feedback, capturas 1920×1080.
Veredicto en `docs/qa/fase4_report.md`; tag `fase-4` tras APROBADO 12/12.

## 5. Propiedad de archivos

| Owner | Write scopes |
|---|---|
| **AG-REA** | `docs/rea/gk2_economy_military_family.md`, `docs/rea/notes_economy.md` |
| **AG-1** | `data/trade_goods.json`, `data/schema/trade_goods.schema.json`, `data/units.json` (solo `recruit_goods`), `data/tutorial_script.json`, `data/sources.md`, `docs/MANUAL_DEL_JUGADOR.md` |
| **AG-2** | `scripts/autoload/**`, `scripts/utils/**`, `scripts/ai/**`, `scripts/battle/**`, `tools/validator_core.gd`, `tests/test_*.gd`, `tests/run_all.gd` |
| **AG-3** | `scenes/**`, `scripts/ui/**` |
| **AG-4** | `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd` |
| **AG-0** | `GDD_The_Sovereign's_Blood.md`, `docs/decisions.md`, `docs/STATUS.md`, `docs/architecture_contracts_fase4.md`, git |

## 6. Restricciones y cierre

- No modificar datos `1402/1453` (diff `fase-3.3..fase-4` = 0 archivos) ni pedir/generar arte externo.
- REA: solo estructuras `.DAT`/`.GK2` y observación DOSBox; prohibido `.EXE`, texto literal y copia de assets. Si no hay DOSBox, documentar la limitación (D-038) y entregar análisis estructural + lecciones.
- Cierre: commits por agente + `[AG-0]`, GDD v1.9, STATUS §19, QA `fase4_report.md`, tag **`fase-4`**, push y aviso a Kimi.

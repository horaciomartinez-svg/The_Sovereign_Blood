# Contrato de integración — Fase 3: escenarios 1402/1453, tecnología y QA final

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-22 |
| **Autoridad** | AG-0; complementa GDD v1.7 §4.3, §4.4, §4.5, §6.4 y §12 (Fase 3) |
| **Partes** | AG-1 (datos), AG-2 (motor/tecnología/victoria), AG-3 (UI), AG-5 (assets externos), AG-4 (QA) |
| **Regla** | Nadie edita este archivo; cambios vía AG-0 y `docs/decisions.md` |

Objetivo: que los **3 escenarios** (1337, 1402, 1453) arranquen desde selección y lleguen a su año final con
condiciones de victoria/derrota §4.5, con evolución tecnológica por año, y QA automatizado (partida de 10
años). Los sprites §10.3 y tiles §10.4 ya integrados deben seguir sin regresión.

---

## 1. Datos — adiciones (AG-1)

### 1.1 Facciones (`data/factions.json`, aditivo)

Añadir **9 facciones** necesarias para los owners de `map_borders.json` 1402/1453 (ids exactos):
`brittany`, `burgundy`, `florence`, `genoa`, `milan`, `naples`, `ottoman`, `tamerlane`, `venice`
(total 23). Campos: id, name, capital (región existente), government, color, `playable` (global: las 8 de
1337 siguen `true`; las nuevas `false`), profile, start_year. Los escenarios declaran qué 8 son jugables.

### 1.2 Personajes (`data/characters.json`, aditivo)

- Añadir gobernantes para **cada facción de cada escenario** (1402 y 1453), con `role: "ruler"`, `born`,
  `died` (fecha histórica real o `null` si vivo), `house`, `faction`, stats 1-100 (estimate:true) y
  `reign_start`/`reign_end` opcionales para desambiguar gobernantes de la misma facción.
- Añadir herederos (`role: "heir"`) y figuras clave (regentes/generales) para los escenarios, con
  `died` histórico; el motor filtra vivos por año (D-058).
- Los 1337 existentes no se alteran (solo se añaden fichas nuevas).
- Retratos: los nuevos personajes **sin PNG** usan fallback heráldico; se pedirán a Kimi (D-062).

### 1.3 Regiones (`data/regions.json`, aditivo)

Añadir `year_data."1402"` y `year_data."1453"` a las 47 regiones: `owner` = owner de `map_borders.json`
para ese año (ids de facción), `population`/`base_wealth`/`buildings` estimados (estimate:true o source)
coherentes con 1337. El `year_data.1337` no cambia.

### 1.4 Escenarios (`data/scenarios/`)

`scenario_1402.json` ("El Choque de Imperios") y `scenario_1453.json` ("El Ocaso y el Alba"):
- `id`: `scenario_1402` / `scenario_1453`; `start_year` 1402/1453; `end_year` **1460** / **1480**
  (D-060; §4.5 supervivencia).
- `factions`: lista exacta de facciones con regiones ese año (21 en ambos, ver owners).
- `playable_factions`: **8 ids jugables** por escenario (subconjunto de factions; validator lo exige).
- `initial_state`: `characters` (referencia), `regions` "1402"/"1453", `treasuries` y `armies` iniciales
  por facción (regiones propias; estimados de diseño).
- `victory`: `{crowns, prestige, years_held, control_pct}` coherentes con §4.5.
- `events_script`: `events_1402.json` / `events_1453.json`.

### 1.5 Eventos (`data/events_1402.json`, `data/events_1453.json`)

Con el esquema §7.6 y URLs: 1402 → Ankara (1402), muerte de Tamerlán (1405), locura de Carlos VI
(episodios), guerra civil Armagnac-Borgoñona, Concilio de Constanza, guerras husitas; 1453 →
asedio/caída de Constantinopla (1453), Castillon (1453), fin de la Guerra de los Cien Años, Guerra de las
Dos Rosas (1455+), caída de Trebisonda (1461, dentro de end_year 1480). `source` obligatorio.

## 2. Motor — cambios (AG-2)

### 2.1 Personajes vivos por año (D-058)

`GameState._build_characters(start_year)`: `alive = (died == null or died >= start_year) and born <= start_year`;
`age = start_year - born`. Selección de gobernante/heredero por año: filtrar vivos y, si hay
`reign_start`/`reign_end`, elegir el que cubre `start_year`; si varios, el de reinado más reciente.

### 2.2 Tecnología por año (D-059)

`scripts/utils/tech.gd` (o `TechSystem`): era `I` si year < 1350, `II` si 1350 ≤ year < 1400, `III` si
year ≥ 1400. Disponibilidad de unidad: `unit.era` contiene la era actual. Filtrar reclutamiento/AI/pool con
esa regla; exponer `GameState`/`MilitarySystem.get_available_units(faction)`; UI muestra era actual.

### 2.3 Victoria/derrota (§4.5, D-060)

- Derrota: extinción de casa o pérdida de última región (ya existe).
- Victoria al alcanzar **Prestigio Real** objetivo mantenido `years_held` (ya existe).
- Añadir **conquista**: controlar ≥ `victory.control_pct` (70%) de las regiones.
- Añadir **supervivencia**: al llegar a `end_year` sin derrota, victoria (facciones menores/partida cerrada).
- Coronas: si el estado no modela coronas aún, documentar como simplificación MVP (claims/crowns en Fase 4)
  y usar prestige+conquista+supervivencia para aceptación §4.5.
- Al alcanzar `end_year` se cierra la partida (victoria o derrota) sin turnos fantasma.

### 2.4 Validador (D-061)

`tools/validate_data.gd`/`validator_core.gd`: validar los **3 escenarios**: ids de facción existentes,
`playable_factions` exactamente 8 por escenario y ⊆ factions, `initial_state.regions` con year_data para el
año y owners válidos, `events_script` existente, eventos dentro de [start_year, end_year], 1337 intacto
(8 jugables). `validate_data` 0 WARN/0 errores con los nuevos datasets (schemas actualizados por AG-1 si
hace falta).

## 3. UI (AG-3)

- `scenario_select`: 3 tarjetas jugables (1337, 1402, 1453) con título/descripción/era; al elegir, listar
  las 8 `playable_factions` del escenario y arrancar `GameState.new_game("scenario_1402"/"scenario_1453", fid)`.
- El mapa principal arranca en la vista de año del escenario (1337/1402/1453) y muestra la **era** actual
  (I/II/III) junto al año.
- Pantalla de fin de partida: motivo de victoria/derrota (prestigio/conquista/supervivencia/extinción).
- Capturas: selección con 3 tarjetas, partida 1402 y 1453 iniciadas, era visible; en `.ui_check_f3/`.

## 4. Assets externos (AG-5, D-062)

No hay generador de arte IA en el equipo. AG-5 prepara `docs/art/requests/kimi_phase3_assets.md` con la
lista exacta y hoja de estilo para **Kimi**: retratos 256×256 de gobernantes/herederos de 1402/1453
(archivo = `character_id`), y hojas idle(2)/ataque(4-6)/impacto(2)/muerte(2) de las 17 unidades con el
estilo del set §10.3. Mientras no existan: fallback heráldico/silhouette (nunca hueco). La aceptación de
Fase 3 se documentará con esta dependencia externa; el resto de criterios se validan sin bloquear.

## 5. QA final de Fase 3 (AG-4)

- Los 3 escenarios: `new_game` + fast-forward trimestre a trimestre hasta `end_year` sin crash, con
  resultado de victoria/derrota coherente (o supervivencia al llegar al año final).
- Partida automatizada de **10 años** en cada escenario sin errores; determinismo (misma semilla).
- Validación de datos 3 escenarios (8 jugables, owners, eventos, tech).
- Retratos: 5 slots funcionan con fallback para personajes sin PNG (y textura para los 14 de 1337);
  capturas de 1402/1453.
- No regresión sprites 17/17, tiles, F1/F2.
- Informe `docs/qa/fase3_report.md` con veredicto y observaciones (incluida la dependencia externa de
  retratos/animaciones si sigue pendiente) y evidencia.

## 6. Propiedad de archivos

| Owner | Write scopes |
|---|---|
| **AG-1** | `data/factions.json`, `data/characters.json`, `data/regions.json`, `data/scenarios/**`, `data/events_1402.json`, `data/events_1453.json`, `data/schema/**`, `data/sources.md` |
| **AG-2** | `scripts/autoload/**`, `scripts/utils/**`, `scripts/ai/**`, `scripts/battle/**`, `tools/validator_core.gd`, `tests/test_*.gd`, `tests/run_all.gd` |
| **AG-3** | `scenes/**`, `scripts/ui/**` |
| **AG-4** | `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd` |
| **AG-5** | `docs/art/requests/**`, `assets/art/**` (solo cuando lleguen assets de Kimi) |
| **AG-0** | `docs/**` (salvo docs/art/requests de AG-5), git, STATUS, tag |

## 7. Aceptación de Fase 3 (§12 v1.7)

1. Los 3 escenarios empiezan desde selección y llegan a su año final sin crash.
2. Victoria/derrota según §4.5 (prestigio, conquista ≥70%, supervivencia al end_year, extinción/pérdida total).
3. Partida automatizada de 10 años sin errores en cada escenario.
4. Retratos 5 slots funcionan (textura 1337 + fallback en nuevos); retratos ilustrados completos pendientes de Kimi (observación si no llegan).
5. Sprites 17/17, tiles §10.4 y batallas N2/N3 sin regresión.
6. `run_all` verde, `validate_data` 0 errores/WARN, editor/headless 0.

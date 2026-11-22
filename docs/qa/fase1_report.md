# Informe de QA — Fase 1 (MVP jugable)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-21 |
| **Veredicto** | **QA Fase 1: APROBADO** |
| **Repo** | `C:\Proyectos\TSB\sovereigns-blood` (rama `main`) |
| **HEAD durante la verificación** | `7814dda` («[AG-4] Fase 1: harness de aceptación…»), con `722b778` ([AG-2] sistemas, 548 tests) y `73bff2f` ([AG-3] UI 16 escenas) por debajo. Leído de `.git/logs/HEAD` (AG-4 no ejecuta git, D-005). |
| **Referencias** | GDD §12 (criterios Fase 1), §13, §5, §6.1, §8.2; `docs/architecture_contracts_fase1.md` §1-§9; `docs/qa/fase1_plan.md` |
| **Harness** | `tests/qa_acceptance.gd` — 948 líneas, 36.890 B, `extends SceneTree`, sin GUT. Solo lectura de estado/API y `data/`; escribe y elimina un save temporal en `user://saves/qa_acceptance_ag4.json`. |
| **Alcance** | 6 criterios de aceptación §12/contrato §9 + no-regresión de datos Fase 0 + auditoría estática de UI-sin-mutación + determinismo |
| **Producción** | No modificada por AG-4 (solo `tests/qa_acceptance.gd`, `docs/qa/**`, `docs/issues.md`). |

---

## 1. Veredicto

> **QA Fase 1: APROBADO**

- **BLOQUEANTES: 0**
- **MAYORES: 0**
- **Menores / observaciones: 3** (ninguna bloquea el cierre de Fase 1; ver §6).
- Los **6/6 criterios** de aceptación de GDD §12 / contrato §9 pasan y el harness devuelve **exit 0**.
- La no-regresión de Fase 0 se mantiene: `validate_data.gd` 0 errores y `tests/run_all.gd` **548 pasados / 0 fallidos / 1 omitido**.

---

## 2. Evidencia de comandos (exit codes y resultados)

| # | Comando | Exit code | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance.gd` | **0** | **6 PASS / 0 FAIL / 0 SKIP**; `ACEPTACIÓN: OK` (2,65 s de pared) |
| 1-bis | repetición del harness ×2 (determinismo) | **0 / 0** | Salida normalizada **idéntica**; hash de save, población y captura idénticos; solo varían los ms medidos de C2 |
| 2 | `--script tests/run_all.gd` | **0** | **548 pasados, 0 fallidos, 1 omitido**; `CI: OK (exit 0)` (580 líneas) |
| 3 | `--script tools/validate_data.gd` | **0** | 6 datasets ↔ 6 schemas, **5.239 comprobaciones**, reglas §13 OK, **0 errores** (`data/map_layout.json` excluido por D-017) |
| 4 | `--editor --quit` | **0** | Importación completa (5 `[DONE]`, 80 líneas), **0 ERROR/WARNING/SCRIPT ERROR** |
| 5 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca (2 líneas de banner), **0 ERROR/WARNING** |

Comando 1, salida íntegra (ejecución canónica `2026-11-21T22:16:35`):

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==============================================================
 The Sovereign's Blood — QA Aceptación Fase 1 (GDD §12 / contrato §9)
 Godot 4.7.2-stable (official) · headless · 2026-11-21T22:16:35
==============================================================
[INFO] datasets esperados: 14 facciones, 47 regiones
[INFO] 10/10 autoloads montados
[INFO] GameState.state inicial: vacío
  [PASS] C1 — Partida Inglaterra 1337: new_game + 4 trimestres de órdenes válidas sin crash :: año 1337·T1 → 1338·T1 (4 trimestres); órdenes intentadas=8 aceptadas=8
  [PASS] C2 — IA de 13 facciones rivales en <2000 ms (medido) :: 13 facciones IA en 17 ms (< 2000 ms)
  [PASS] C3 — Save/load exacto: hash de to_dict() igual + continuidad del RNG :: hash 900976fefd4c7e01 idéntico; disco=96231 B, restaurado tras perturbación=true; RNG directo: next_int post-load reproducible (39012)
  [PASS] C4 — Peste Negra 1348 en event_log con population_modifier -0.35 (europe_west) :: año=1348 vía advance_year; event_log=true; fired_events=true; datos(1348 -0.35 europe_west)=true; regiones afectadas=32 (ratio 0.650–0.657), no afectadas=15, dueños occidentales con plaga=9/9, fuera de rango=0; población total 13931280 → 10318856 (-25.9%)
  [PASS] C5 — Batalla delegada: informe coherente y captura de región :: army=army_england_1 region_aquitania→region_burgos; owner castile→england; region_id=region_burgos; winner=england; region_captured=true; report.keys=["attacker_faction", "defender_faction", "region_id", "winner_faction", "attacker_losses", "defender_losses", "rounds", "region_captured", "loot_gold", "leader_killed", "leader_captured", "attacker_start_power", "defender_start_power", "notes", "attacker_army_id", "defender_army_id"]; coerente=true; capturada=true
  [PASS] C6 — Smoke UI: instanciar/free todas las escenas de scenes/** en headless :: 16/16 escenas instanciadas y liberadas
--------------------------------------------------------------
RESULTADO QA ACEPTACIÓN FASE 1: 6 PASS, 0 FAIL, 0 SKIP (de 6 criterios)
  C1: [PASS] Partida Inglaterra 1337: new_game + 4 trimestres de órdenes válidas sin crash (109 ms)
  C2: [PASS] IA de 13 facciones rivales en <2000 ms (medido) (36 ms)
  C3: [PASS] Save/load exacto: hash de to_dict() igual + continuidad del RNG (77 ms)
  C4: [PASS] Peste Negra 1348 en event_log con population_modifier -0.35 (europe_west) (204 ms)
  C5: [PASS] Batalla delegada: informe coherente y captura de región (13 ms)
  C6: [PASS] Smoke UI: instanciar/free todas las escenas de scenes/** en headless (749 ms)
--------------------------------------------------------------
ACEPTACIÓN: OK — 6/6 criterios PASS (exit 0)
```

---

## 3. Criterios §12 — evidencia y métricas

### C1 · Partida Inglaterra 1337 (4 trimestres, órdenes válidas, sin crash) — PASS
- `new_game("scenario_1337", "england", 1337)` construye `state` con **14 facciones / 47 regiones** (conteos leídos de `data/*.json`).
- 4 trimestres: `begin_turn("england")` + **8 órdenes** (4× `EconomySystem.allocate` y 4× `DiplomacySystem.propose`), **8/8 aceptadas**, `end_turn()` ×4.
- Reloj: **1337·T1 → 1338·T1** (4 trimestres, sin crash; proceso exit 0).
- Tiempo del criterio en la ejecución canónica: **109 ms**.

### C2 · IA de las 13 facciones rivales en <2.000 ms — PASS
- State con **13** facciones IA (`is_player != true`) + Inglaterra jugador = 14.
- `AIManager.run_all_ai()` medido con `Time.get_ticks_msec()`: **17 ms** en la ejecución canónica; **16–21 ms** en las 4 ejecuciones finales (margen ≈100× sobre el presupuesto de 2.000 ms).
- La IA produce cambio verificable de `GameState.state` (hash antes ≠ después).

### C3 · Save/load exacto (hash) + continuidad del RNG — PASS
- `to_dict()` antes de guardar → hash SHA-256 **`900976fefd4c7e01`** (primeros 16 hex).
- `save_game("qa_acceptance_ag4")` escribe **96.231 B** en `user://saves/qa_acceptance_ag4.json`.
- **Prueba de roundtrip real:** tras guardar se perturba el estado (`TurnManager.advance_quarter()`; hash cambia), se llama `load_game()` y el hash de `to_dict()` vuelve a **`900976fefd4c7e01`** → no es un no-op, restaura desde disco.
- RNG: `GameState.rng.next_int()` tras dos `load_game()` consecutivos devuelve **39012** de forma reproducible.
- El save temporal se elimina al final; no queda en `user://`.
- Tiempo del criterio: **77 ms**.

### C4 · Peste Negra 1348 con `population_modifier -0.35` (europe_west) — PASS
- Avance desde 1337 hasta **1348** (`advance_quarter`, camino `advance_year` en el tramo final).
- `peste_negra_1348` presente en **`event_log`** y en **`fired_events`**.
- Dataset: `population_modifier`, `value: -0.35`, `scope: "europe_west"` verificado en `data/events_1337.json`.
- **Verificación por región** (población 1347 → 1348): **32 regiones afectadas** con ratio **0,650–0,657** (≈ ×0,65 = −35 %), **15 regiones no afectadas**, **9/9 facciones occidentales** (Inglaterra, Francia, Castilla, Aragón, HRE, Bohemia, Escocia, Papado, Polonia) con regiones afectadas, **0 regiones fuera del rango** [0,60–0,70]. Población total **13.931.280 → 10.318.856 (−25,9 %**, coherente al aplicarse solo a Europa occidental).
- Tiempo del criterio: **204 ms**.

### C5 · Batalla delegada con informe coherente y captura de región — PASS
- Objetivo determinista: `army_england_1` (Aquitania) ataca **`region_burgos`** (Castilla, con ejército defensor) → batalla, no ocupación.
- `move_army` → `BattleManager.resolve_delegated` genera **BattleReport** de 16 campos: `attacker_faction`, `defender_faction`, `region_id`, `winner_faction`, `attacker_losses`, `defender_losses`, `rounds`, `region_captured`, `loot_gold`, `leader_killed`, `leader_captured`, `attacker_start_power`, `defender_start_power`, `notes`, `attacker_army_id`, `defender_army_id`.
- Coherencia verificada: bandos `england` vs `castile`, `region_id == region_burgos`, **winner=england**, **`region_captured=true`**, y prueba de estado: **`owner` de `region_burgos` pasa de `castile` a `england`** (el flag del informe coincide con el cambio real de propietario).
- Tiempo del criterio: **13 ms**.

### C6 · Smoke UI: instanciar/free todas las escenas `scenes/**` headless — PASS
- **16/16 escenas `.tscn`** cargadas, instanciadas y liberadas sin errores (contrato §7): `main_menu`, `scenario_select`, `world_map`, `region_node`, `region_panel`, `council_menu`, `family_tree`, `diplomacy_screen`, `battle_report`, `economy_screen`, `military_screen`, `court_overview`, `options_menu`, `tooltip`, `victory_screen`, `year_end_report`.
- Tiempo del criterio: **749 ms**.

---

## 4. Verificación independiente (no se confía en los scripts de AG-2/AG-3)

### 4.1 UI-sin-mutación (contrato §7)

Auditoría estática sobre los **25 archivos `.gd` de `scripts/ui/**`** (excluye `scripts/ui/dev/`, que es tooling de desarrollo y no escena de runtime):

| Patrón buscado | Resultado |
|---|---|
| Asignaciones a autoloads (`GameState.x =`, `DataLoader.x =`, `TurnManager.x =`, …) | **0** |
| Escrituras a `GameState.state` / `DataLoader.<índice>` | **0** |
| Escrituras a `state[...]` o a campos de estado (`owner`, `gold`, `population`, `support`, `buildings`, `workers`, …) | **0** |
| Setters de sistemas llamados desde UI (`set_relation`, `set_profile`, `set_seed`, `reset`) | **0** |
| Mutaciones de contenedores sobre datos devueltos (`.append/erase/clear` sobre `armies`/`region`/`event_log`) | **0** (solo sobre contenedores locales de presentación) |

- La UI centraliza el acceso en `scripts/ui/tsb_game.gd` mediante `_prop()`/`_call()`; las **31 llamadas dinámicas** observadas son métodos de la API §2 (`DataLoader.get_*`, `EconomySystem.allocate/recalculate/get_*`, `DynastySystem.marry/resolve_succession/get_*`, `DiplomacySystem.propose/get_*`, `MilitarySystem.create_army/recruit/move_army/disband_army/get_*`, `BattleManager.estimate_power`, `GameState.new_game/reset/save_game/load_game/has_save`, `TurnManager.begin_turn/end_turn/calculate_pg`, `DataLoader.get_events_for_year`). Las acciones que mutan lo hacen **a través de la API**, como exige el contrato.
- Los `.tscn` no contienen referencias directas a autoloads/estado.
- **Observación MENOR:** `tsb_game.gd` expone referencias vivas (`state()`, `faction_state()`, `armies()`, `armies_in()`, `battle_reports()`, `event_log()`) y `region()` comparte arrays anidados (`buildings`, `workers`) del estado. Hoy **no hay ninguna escritura** sobre ellas (auditoría: 0), pero conviene que la UI no las mutile por disciplina; ver M-F1-02.

### 4.2 `project.godot`
- `config_version=5` ✔
- `run/main_scene="res://scenes/main/main_menu.tscn"` ✔
- **10 autoloads** intactos (`EventBus`, `DataLoader`, `GameState`, `TurnManager`, `EconomySystem`, `DynastySystem`, `DiplomacySystem`, `MilitarySystem`, `BattleManager`, `AIManager`) ✔
- `display/window/size/viewport_width=1920`, `height=1080` ✔; tema global `assets/art/theme/tsb_global_theme.tres` existe (332 B) ✔
- `--headless --quit`: `main_scene` arranca sin ERROR/WARNING (exit 0) ✔

### 4.3 Capturas `docs/screenshots/` y cobertura del flujo §9
- **17 archivos PNG**, todos **1920×1080**, firma PNG válida, 112–473 KB (no placeholders vacíos).
- **16 capturas numeradas** (01–16) + `03b_tooltip.png` (extra solicitado por §9, tooltip del mapa).
- **16 únicas**: `14_after_end_turn.png` y `15_live_overlay_battle.png` son **byte-idénticas** (mismo SHA-256) → observación M-F1-01.
- Correspondencia pantalla→escena verificada: main menu, scenario select, world map, tooltip, region panel, corte, árbol familiar, diplomacia, militar, economía, opciones, informe de batalla, fin de año, victoria, overlay de batalla y estado tras overlay. Las capturas 14–16 representan **estados en vivo**, no escenas propias (correcto).
- Revisión visual independiente de `01_main_menu`, `03_world_map`, `06_family_tree` y `11_battle_report`: coinciden con el flujo §9 (menú con Nuevo Juego/Cargar/Opciones; mapa de 47 regiones con panel de consejo y fichas; árbol familiar con genealogía/stats; informe de batalla con asaltos, bajas, botín y captura).

### 4.4 No-regresión de datos Fase 0
Hashes SHA-256 (primeros 16 hex) **idénticos** a los aprobados en Fase 0:

```text
IGUAL  7724AFA91F6D8CF5  data/characters.json
IGUAL  004BF70AC0FD896A  data/events_1337.json
IGUAL  102AC897DA7530EB  data/factions.json
IGUAL  7F4E32AADE107C07  data/regions.json
IGUAL  075A35F64324AB54  data/scenarios/scenario_1337.json
IGUAL  0F726FCA0EBD2391  data/units.json
```

- `data/map_layout.json` (D-017, solo presentación): **47 regiones**, excluido de `validate_data.gd` por decisión D-017; no altera datos históricos.
- `validate_data.gd`: 5.239 comprobaciones, 0 errores.

### 4.5 Determinismo (§13)
- 4 ejecuciones del harness final: **6/6 PASS, exit 0** en todas; salida normalizada **idéntica** (solo varían los ms medidos de C2: 16–21 ms).
- Invariantes idénticos entre ejecuciones: hash de save **`900976fefd4c7e01`**, población **13.931.280 → 10.318.856**, batalla **`region_burgos` castile→england**, 16/16 escenas.
- No hay aleatoriedad en el veredicto del harness (semilla fija 1337).

### 4.6 Limpieza de efectos laterales
- Save de QA `user://saves/qa_acceptance_ag4.json`: eliminado tras C3 (verificado: no existe).
- La importación de Godot (`--editor --quit`) genera sidecars `*.png.import` para `docs/screenshots`; AG-4 los eliminó para no ensuciar el working tree de AG-0 (son regenerables). Ver observación informativa.

---

## 5. Cierre de riesgos R1–R8 del plan

| ID | Riesgo | Estado final | Evidencia |
|---|---|---|---|
| R1 | UI headless: `instantiate()` no ejecuta `_ready`/pintado | **Cerrado con limitación documentada** | C6 16/16 instanciadas; `main_scene` arranca en `--headless --quit`; 16 capturas reales 1920×1080 revisadas; auditoría estática UI-sin-mutación 0 violaciones. Persiste límite intrínseco: sin interacción real de usuario en headless. |
| R2 | Presupuesto IA sesgado por máquina compartida | **Cerrado** | 16–21 ms ×4 ejecuciones (≈100× margen); no hubo otro proceso Godot concurrente durante la batería final. |
| R3 | Hash de `to_dict` sensible a orden/flotantes | **Cerrado** | Hash idéntico en 4 ejecuciones y tras roundtrip con perturbación; RNG reproducible. |
| R4 | Peste Negra enmascarada por crecimiento | **Cerrado** | Verificación por región: 32 afectadas 0,650–0,657; 15 no afectadas; 9/9 dueños occidentales. |
| R5 | Batalla estocástica / objetivo sin defensores | **Cerrado y corregido en el harness** | El harness ahora prioriza un vecino enemigo **con defensores** (`aquitania→burgos`) y cruza el flag del informe con el `owner` real del estado. La versión inicial del baseline elegía `region_bretana` (sin defensores → ocupación); se detectó durante la verificación final y se corrigió **solo el harness** (no era defecto de producción). |
| R6 | Concurrencia AG-2/AG-3 | **Cerrado** | Verificación sobre el árbol integrado post-commits `722b778`/`73bff2f`; artefactos estables (mtimes ≤ 22:06; producción no modificada por QA). |
| R7 | Deriva de conteos de datos | **Cerrado** | 14/47 leídos del JSON; hashes de datos Fase 0 idénticos. |
| R8 | Escritura en `user://` | **Cerrado** | Slot único y limpieza verificada; no se escribe dentro del repo. |

---

## 6. Observaciones por severidad

### BLOQUEANTES
**Ninguno.** Los 6 criterios pasan y los 5 comandos obligatorios devuelven exit 0.

### MAYORES
**Ninguno.**

### MENORES

#### M-F1-01 · Capturas `14_after_end_turn.png` y `15_live_overlay_battle.png` idénticas
- **Archivos:** `docs/screenshots/14_after_end_turn.png` y `docs/screenshots/15_live_overlay_battle.png` (280.350 B cada una, mismo SHA-256 `4B3414E1…`).
- **Hecho:** 15 debía documentar el overlay de batalla en vivo; es la misma imagen que 14 (probablemente la captura se tomó después de cerrar el overlay).
- **Impacto:** solo evidencia documental; no afecta a los criterios §12 ni al código. **No bloqueante.**
- **Reproducción:** `Get-FileHash docs/screenshots/14_after_end_turn.png, docs/screenshots/15_live_overlay_battle.png -Algorithm SHA256` → hashes iguales. Corresponde a AG-3 (recapturar 15 con el overlay abierto o eliminar la duplicada).

#### M-F1-02 · La fachada UI expone referencias vivas del estado
- **Archivo:** `scripts/ui/tsb_game.gd` (`state()`, `faction_state()`, `armies()`, `armies_in()`, `battle_reports()`, `event_log()`, y `region()` que comparte `buildings`/`workers`).
- **Hecho:** no se encontró ninguna escritura de la UI sobre esas referencias (auditoría 0 violaciones), pero el diseño permite mutar `GameState.state` sin pasar por la API si un futuro cambio de UI lo hiciera.
- **Impacto:** riesgo de mantenimiento, no incumplimiento actual del contrato §7. **No bloqueante.**
- **Recomendación (AG-3):** devolver `duplicate(true)` en los getters de diccionarios/arrays o documentar explícitamente que son de solo lectura.

#### M-F1-03 · Tooling de desarrollo dentro de `scripts/ui/dev/`
- **Archivos:** `scripts/ui/dev/integration_probe.gd`, `ui_smoke.gd`, `ui_screenshots.gd` (+ `gen_map_layout.ps1`).
- **Hecho:** son herramientas de AG-3, no escenas de runtime; no se cargan desde `.tscn` (auditoría de escenas: 0 referencias) y no afectan a la UI enviada.
- **Impacto:** higiene del árbol; **no bloqueante.** Recomendación: moverlas a `tools/` o documentar su carácter de desarrollo en el README de AG-3.

### INFORMATIVO
- **Capturas:** 17 PNG para 16 pantallas numeradas: `03b_tooltip.png` es un extra de §9 (tooltip del mapa); las 14–16 son estados en vivo (sin escena propia). Correcto.
- **Sidecars `.import`:** ejecutar `--editor --quit` genera `docs/screenshots/*.png.import`. AG-4 los eliminó tras la verificación para no ensuciar el working tree de AG-0; si se desea evitar que reaparezcan, añadir `docs/screenshots/*.import` a `.gitignore` o commitearlos como assets (decisión de AG-0).
- **HEAD:** la verificación se hizo sobre `7814dda` (commit de AG-4) con `722b778`/`73bff2f` integrados; `docs/STATUS.md` y `docs/decisions.md` quedan pendientes de commit de AG-0 y AG-4 no los modificó.

---

## 7. Limitaciones de la verificación

1. Los criterios de UI se validan por instanciación headless y capturas estáticas; no se simula interacción de ratón/teclado (fuera del alcance automatizable en Fase 1).
2. La medición de IA (16–21 ms) es de esta máquina y de la semilla 1337; sirve como evidencia del presupuesto, no como benchmark universal.
3. El harness usa la API pública §2 y `GameState.state`; no inspecciona invariantes internos de los sistemas más allá de lo exigido por §12.
4. Los screenshots son evidencia de presentación; la revisión visual de QA cubrió 4 pantallas clave, no las 16 al detalle.

---

## 8. Artefactos de la verificación

| Artefacto | Ruta |
|---|---|
| Harness de aceptación Fase 1 | `tests/qa_acceptance.gd` (948 líneas) |
| Plan de QA | `docs/qa/fase1_plan.md` |
| Este informe | `docs/qa/fase1_report.md` |
| Registro acumulativo de QA | `docs/issues.md` (§7 baseline + §8 verificación final) |

*Fin del informe QA Fase 1 — AG-4.*

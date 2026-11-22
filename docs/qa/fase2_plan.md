# Plan de QA — Fase 2 (Profundidad militar + Mapa §10.1 + Retratos §10.2)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Versión** | 1.0 — 2026-11-21 |
| **Referencias** | GDD v1.4 §10.1, §10.2, §12 Fase 2, §13; `docs/architecture_contracts_fase2.md` §1-§9; `docs/qa/fase1_plan.md` |
| **Harness** | `tests/qa_acceptance_fase2.gd` — 1.596 líneas, `extends SceneTree`, sin GUT; complementa (no sustituye) a `tests/qa_acceptance.gd` de Fase 1 |
| **Entregables QA** | harness, este plan, `docs/issues.md` § «Fase 2 — baseline»; la verificación final (task-15) añadirá `docs/qa/fase2_report.md` |
| **Scopes** | `docs/issues.md`, `docs/qa/**`, `tests/qa_*.gd` (contrato fase2 §7). AG-4 no toca producción ni ejecuta git (D-005) |
| **Estado** | Baseline registrado (snapshot 2026-11-21 22:53): **2 PASS / 0 FAIL / 4 SKIP**, exit 1 → PENDIENTE por módulos en curso, no rechazo |

---

## 1. Puerta de aceptación

El harness evalúa **6 criterios** (GDD §12 Fase 2 + contrato §8). Semántica:

| Estado | Significado | Exit |
|---|---|---|
| `[PASS]` | Criterio verificado con evidencia | — |
| `[FAIL]` | Módulo presente pero incumple/regresión | **1** |
| `[SKIP]` | Módulo aún no integrado (pendiente AG-1/AG-2/AG-3), justificado | **1** (baseline) |

`quit(0)` **solo** si los 6 criterios son PASS. El harness **compila siempre**: no hace `preload` de archivos de Fase 2 que aún no existen, los detecta en runtime con `FileAccess.file_exists`/`load`/`has_method`. No muta producción; solo escribe un save temporal en `user://saves/qa_acceptance_fase2.json` (C6), que elimina.

Comandos oficiales (desde `C:\Proyectos\TSB`):

```powershell
$G = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$R = "C:\Proyectos\TSB\sovereigns-blood"
& $G --headless --path $R --script tests/qa_acceptance_fase2.gd  # harness Fase 2 (criterios 1-6)
& $G --headless --path $R --script tests/qa_acceptance.gd        # no regresión Fase 1 (6/6)
& $G --headless --path $R --script tests/run_all.gd              # 548+ tests
& $G --headless --path $R --script tools/validate_data.gd        # 0 errores
& $G --headless --path $R --editor --quit                        # importación/compilación
& $G --headless --path $R --quit                                 # arranque de main_scene
```

Nota de rendimiento (headless): el benchmark del mapa mide CPU de `_process` + `queue_redraw` (lógica/redibujado), **no GPU**: en headless no hay rasterizado real. Se documenta como límite aceptado por el contrato §2.

---

## 2. Matriz criterio §12/§10 → check → comando → evidencia → owner

| # | Criterio | Check en `tests/qa_acceptance_fase2.gd` | Comando | Evidencia que se registra | Depende de |
|---|---|---|---|---|---|
| F2-C1 | Crécy (Inglaterra vs Francia) jugable en Niveles 1, 2 y 3 con resultados coherentes | N1: `BattleManager.resolve_delegated` con ejércitos Crécy (Aquitania/Normandía); N2: `launch_tactical` → `TacticalBattle` (API §4), simulación `auto_resolve`/órdenes, `commit()` con bajas/rondas; N3: `launch_close_combat` → `CloseCombat`, cartas; cada nivel se ejecuta **2 veces** con semilla 1337 → determinismo | harness | `[PASS] F2-C1` + ganador/bajas/rondas por nivel y determinismo; N2/N3 con `N1=...; N2=...; N3=...` | AG-2 (task-12); sin UI (headless) |
| F2-C2 | Pérdida de líder sin herederos/nadie de la casa → `game_over` derrota inmediata, sin turnos fantasma | Mata en `GameState.state` al gobernante, heredero y vivos de su casa; `DynastySystem.resolve_succession`; exige `dynasty_extinct` + `EventBus.game_over(victory=false)`/`state.game_over`; después intenta `advance_quarter`/`end_turn` y exige reloj congelado | harness | `[PASS] F2-C2` + muertos, señal extinct, game_over, año/trimestre congelado | AG-2 (task-12); F1 deja interregno de 2 años → hay que distinguir «F2 no integrado» (SKIP) de «extinción marcada sin derrota» (FAIL) |
| F2-C3 | §10.1: 47/47 polígonos × 1337/1402/1453, ids, 0 huérfanas, coords, rings, área, ≤150 KB; hit-test 3 vistas; CPU <8 ms/frame; terreno y captura comparativa | Datos: `data/map_borders.json` (schema_version 1, canvas 4096×3072, 3 años × 47, ids de `regions.json`, duplicados/huérfanas, owner no vacío y 1337 ∈ factions, `source`/`estimate`, ring 3-400, coords [0,1], área shoelace >0, center). Hit-test: implementación propia de punto-en-polígono + test sintético; punto `center` (fallback centroide) de **141/141** regiones debe caer en su propio polígono. Integración: `world_map.gd` contiene `map_borders` y **no** `map_layout` (D-024). Terreno `assets/art/map/terrain_base.png` ≥4096×3072. Benchmark: instancia `world_map.tscn`, 120 frames con `_process`+`queue_redraw` y selector de año si existe; media <8,0 ms. Captura `docs/screenshots/map_comparison.png` (D-028) | harness | `[PASS] F2-C3` + bytes/puntos, 141/141 hit-test, media/máx ms, terreno, integración, captura | AG-1 (map_borders, task-11); AG-3 (mapa/captura, task-13). Si `map_borders` falta → SKIP |
| F2-C4 | §10.2: 5 slots de retrato con fallback nunca vacío; sucesión actualiza retrato del mapa; capturas | Datos: schema `characters` con `portrait` opcional (string/null). Widget `scripts/ui/widgets/portrait_frame.gd`: instanciable, API `get_portrait_character_id()`/`is_fallback()`; con personaje real `id != ""` y `is_fallback() == true` (F2 sin assets). Slots: referencias en `world_map.gd`, `family_tree.gd`, `diplomacy_screen.gd`, `battle_report.gd`, `court_overview.gd` (5/5). Sucesión: instancia `world_map.tscn`, localiza nodo con `get_portrait_character_id`, comprueba gobernante; fuerza muerte del gobernante + `resolve_succession`; refresca y exige retrato del **heredero**. Capturas: `map_portrait.png`/`17_map_portrait.png` + `map_comparison.png` en `docs/screenshots` | harness | `[PASS] F2-C4` + datos/widget/slots/sucesión/capturas | AG-1 (schema portrait); AG-3 (widget+5 slots, task-13); AG-2 (sucesión, ya en F1) |
| F2-C5 | Smoke de TODAS las escenas: nuevas `tactical_map.tscn`/`close_combat.tscn` + 16 previas | Escaneo `res://scenes/**/*.tscn`; cada escena `load().instantiate().free()`; además compila los `.gd` referenciados por cada `.tscn` (`can_instantiate`) y los scripts de `scripts/battle/**`; exige ≥16 escenas previas y las 2 nuevas; si hay scripts en edición con módulos F2 ausentes → SKIP justificado (no FAIL por escritura concurrente) | harness | `[PASS] F2-C5` + N/N escenas, scripts que no compilan, faltantes | AG-3 (task-13) |
| F2-C6 | No regresión Fase 1 embebida: save/load exacto, Peste Negra 1348, determinismo, UI sin mutaciones, 16 escenas | Save en disco + perturbar (`advance_quarter`) + load → hash `to_dict` idéntico; avance a 1348 → `peste_negra_1348` en `event_log`+`fired_events`; dos `new_game` con seed 1337 → mismo hash; auditoría estática de `scripts/ui/**` (regex de asignaciones a autoloads/`GameState.state`/`DataLoader`/`state[...]`, excluye `#` y `dev/`); ≥16 escenas | harness | `[PASS] F2-C6` + hash/save/reset/peste/hallazgos/escenas | AG-2/AG-3 (no romper F1); complementa los comandos externos |
| NR-1 | No regresión suite | `tests/run_all.gd` | comando | 548+ pass / 0 fail | AG-2 |
| NR-2 | No regresión datos | `tools/validate_data.gd` | comando | 0 errores | AG-1 |
| NR-3 | Fase 1 sigue aprobada | `tests/qa_acceptance.gd` | comando | 6/6 PASS exit 0 | QA |
| NR-4 | Compilación/arranque | `--editor --quit`, `--headless --quit` | comando | exit 0, sin ERROR/WARNING | AG-2/AG-3 |

---

## 3. Protocolo de ejecución y registro

1. Ejecutar el harness Fase 2 **dos veces** (determinismo del baseline) y luego la batería de no regresión (§1).
2. Registrar salidas íntegras y exit codes en `docs/issues.md` (baseline y verificación final) y, al cerrar, en `docs/qa/fase2_report.md`.
3. Un `FAIL` se reporta con reproducción y owner (AG-1/AG-2/AG-3); un `SKIP` de baseline se convierte en requisito de task-15 y **no** es aceptable en el veredicto final.
4. AG-4 no arregla producción: si un módulo está integrado pero incumple, se emite FAIL y se detalla.
5. En cada ejecución, comprobar que no se generan artefactos en el working tree: los sidecars `*.import` que `--editor --quit` crea bajo `docs/screenshots/` se retiran, salvo que AG-3 esté ejecutando el editor en paralelo (los regenera); en ese caso AG-0 decide la política (`.gitignore` o commit de assets) antes del cierre. AG-4 no borra archivos de producción de otros agentes.
6. Los screenshots de Fase 2 los produce AG-3 en `C:\Proyectos\TSB\.ui_check_f2\` y **AG-0 los copia** a `docs/screenshots/`; el harness evalúa la copia final (D-028/D-024).

---

## 4. Baseline (snapshot 2026-11-21 22:53)

**Estado del repo:** HEAD `059ae82`; AG-1/AG-2/AG-3 trabajando en paralelo (algunos archivos aparecieron/modificaron durante el baseline → snapshot puntual).

| Criterio | Baseline | Motivo |
|---|---|---|
| F2-C1 Crécy 3 niveles | `PASS` | N1: winner=england, bajas 703/724, 3 asaltos, determinista. N2: `TacticalBattle` presente, auto_resolve → winner=france, bajas 0/509, 5 rondas, determinista. N3: `CloseCombat` presente → winner=england, bajas 773/641, 5 rondas, determinista. Los tres niveles ejecutados sin crash |
| F2-C2 Extinción | `SKIP` | AG-2 aún no integra la extinción inmediata: `resolve_succession` devuelve `extinct=false`, sin `dynasty_extinct` ni `game_over` (comportamiento F1 → interregno). Evidencia: muertos 4 (casa plantagenet), héroe elegido `robert_morley` (casa distinta) |
| F2-C3 §10.1 Mapa | `SKIP` | `data/map_borders.json` ausente (AG-1); `terrain_base.png` ya presente; escenas tácticas y `map_comparison.png` ausentes |
| F2-C4 §10.2 Retratos | `SKIP` | `portrait_frame.gd` presente pero **aún no compila** (parse error en línea 216, `Vector2.grow`); schema de `characters` sin `portrait`; slots 4/5 (falta `world_map.gd`); capturas ausentes en `docs/screenshots` |
| F2-C5 Smoke escenas | `SKIP` | 16/16 escenas F1 instancian; faltan `tactical_map.tscn`/`close_combat.tscn`; 1 script en edición (`portrait_frame.gd`) |
| F2-C6 No regresión F1 | `PASS` | save 96.786 B / hash `db35e62a…` restaurado; Peste Negra 1348 en log/fired; determinismo OK; 0 mutaciones de UI; 16 escenas |

**Batería de no regresión en el baseline:** `run_all.gd` **557 pass / 0 fail / 1 skip** exit 0; `validate_data.gd` 5.239 comprobaciones / 0 errores exit 0; `qa_acceptance.gd` Fase 1 **6/6 PASS** exit 0; `--editor --quit` exit 0; `--headless --quit` exit 0. El baseline del harness Fase 2 se repitió y dio estados/detalles idénticos.

**Post-snapshot (22:54–22:56, informativo):** AG-1 entregó `data/map_borders.json` (118.898 B, 47/47/47, rings 7–186, media 46,3 pts/región) aún sin integrar; `data/map_layout.json` sigue presente y hay auxiliares temporales de AG-1 en `data/` (`_ag1_*.py`, `__pycache__`, `*.geojson`, `_map_debug_*.png`) que deben retirarse antes de task-15. AG-3 añadió capas de mapa (`map_borders_layer.gd`, `map_entities_layer.gd`). El snapshot canónico del harness precede a estos cambios; task-15 re-ejecutará todo sobre el árbol estable.

---

## 5. Riesgos de verificación y mitigación

| ID | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| R-F2-01 | **Geometría de fronteras**: hit-test de 141/141 puntos depende de que `center` caiga dentro del polígono; polígonos cóncavos o `center` de etiqueta fuera del ring pueden dar falsos fallos. No se automatiza la detección de autointersecciones ni la coherencia geométrica exacta con adyacencias (solo se valida área/forma básica). | Falso FAIL/SKIP de C3 | `center` + fallback a centroide; fallo se reporta con región/año; en task-15 se revisa si el fallo es de datos (AG-1) o del test. La coherencia con adyacencias queda como revisión visual/manual documentada. |
| R-F2-02 | **Benchmark headless**: no hay GPU ni rasterizado real; se mide solo CPU de `_process` + `queue_redraw` y, si existe, el selector de año. Un mapa que delegue el dibujo a `_draw` no será medido. | Falso PASS/FAIL de C3 | Se documenta la limitación (contrato §2); se mide `_process` del controlador y se imprime media/máx. Si no hay `_process` medible → FAIL explícito, no PASS silencioso. |
| R-F2-03 | **Nombres de API de retratos**: el contrato fija `get_portrait_character_id()`/`is_fallback()`, pero no el método de bind (`set_character`/`configure`/…). El test de sucesión busca el nodo por API en el árbol de `world_map.tscn`. | Falso FAIL de C4 | Se prueban varios nombres de bind; en task-15 se adapta el harness a la implementación real (sin relajar el criterio). La detección de slots es estática (grep de `portrait`/`portrait_frame` en los 5 archivos de UI). |
| R-F2-04 | **Crécy N2/N3**: el contrato no fija el ganador esperado por nivel (pueden diferir del N1); el harness usa `auto_resolve()` si existe y, si no, simula órdenes. Un motor que no termine en rondas puede dar falso FAIL. | Falso FAIL/PASS de C1 | Se exige coherencia por nivel (ganador válido, bajas >0, rondas) y determinismo (2 ejecuciones), no un ganador concreto. Si el motor no cierra batalla en el límite, FAIL con `rondas/acciones` para diagnóstico. |
| R-F2-05 | **Extinción inmediata**: Fase 1 deja interregno de 2 años; el criterio F2 exige derrota inmediata. Distinguir «aún no integrado» (SKIP baseline) de «integrado pero no derrota» (FAIL) exige marcadores de implementación. | SKIP indefinido que oculte un bug | En task-15, si sigue sin `game_over` inmediato tras integrar task-12, se emite **FAIL/observación bloqueante** (no se acepta SKIP en verificación final). |
| R-F2-06 | **Escritura concurrente de AG-1/AG-2/AG-3**: durante el baseline aparecieron scripts y cambiaron mtimes; un parse error transitorio (p.ej. `portrait_frame.gd`) no debe convertirse en rechazo de Fase 2. | Baseline ruidoso | El harness distingue `SKIP` por módulos F2 ausentes; en task-15 se ejecuta sobre commits integrados y estables. |
| R-F2-07 | **D-024**: al cerrar el módulo Mapa, `map_layout.json` debe desaparecer y `world_map.gd` no consumirlo. | SKIP/FAIL de C3 | Check estático `map_borders` sí / `map_layout` no + aviso informativo del archivo aún presente; AG-3/AG-0 confirman la retirada. |
| R-F2-08 | **Screenshots en staging**: AG-3 entrega en `.ui_check_f2/` y AG-0 copia a `docs/screenshots/`; el harness evalúa la copia final. | C3/C4 FAIL si la copia no se hizo | Se registra staging vs docs en el informe; el criterio final exige docs (D-028/D-024). |

---

## 6. Checklist para task-15 (verificación final — NO reclamada aún)

> Bloqueada hasta que AG-1/AG-2/AG-3 completen task-11/12/13; AG-0 avisará.

- [ ] `qa_acceptance_fase2.gd`: **6/6 PASS**, exit 0; repetido 2× (determinismo).
- [ ] C1: Crécy N1/N2/N3 coherentes y deterministas; documentar ganador/bajas/rondas de cada nivel.
- [ ] C2: extinción inmediata → `dynasty_extinct` + `game_over(false, "dinastía extinta")`; reloj congelado tras game_over.
- [ ] C3: 47/47 × 3 años, ≤150 KB, 141/141 hit-test, media CPU <8 ms/120 frames, terreno 4096×3072, `map_borders` integrado y `map_layout` retirado, `map_comparison.png`.
- [ ] C4: schema `portrait`, widget con fallback (id no vacío + `is_fallback`), 5/5 slots, sucesión actualiza el retrato del mapa al heredero, capturas de retrato y comparativa.
- [ ] C5: 18 escenas (16 F1 + tactical_map + close_combat) instancian y sus scripts compilan.
- [ ] C6 + NR: `run_all.gd` (548+), `validate_data.gd` 0 errores, F1 harness 6/6, save/load, Peste Negra, UI sin mutaciones, determinismo, `--editor --quit` y `--headless --quit` sin errores.
- [ ] Cierre de R-F2-01…08: documentar resultados y observaciones; emitir «QA Fase 2: APROBADO/RECHAZADO» en `docs/qa/fase2_report.md` + `docs/issues.md`, y reportar a AG-0.

---

*Plan vivo: se actualiza al integrar los módulos, sin cambiar los criterios del GDD/contrato (los cambios de criterio son de AG-0).*

# Plan de QA — Fase 1 (MVP jugable)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Versión** | 1.0 — 2026-11-21 |
| **Referencias** | GDD §12 (criterios Fase 1), §13 (QA), §5, §6.1, §8.2; `docs/architecture_contracts_fase1.md` §1-§9 |
| **Entregables QA** | `tests/qa_acceptance.gd` (harness), este plan, `docs/issues.md` (§ «Fase 1 — baseline»); el informe final de Fase 1 se añadirá en `docs/qa/fase1_report.md` al ejecutar task-9 |
| **Scopes de escritura** | `docs/issues.md`, `docs/qa/**`, `tests/qa_*.gd` (contrato §8 / D-016). AG-4 no toca producción ni ejecuta git (D-005) |
| **Estado** | Baseline registrado (sistemas AG-2/AG-3 en implementación; 0 PASS / 0 FAIL / 6 SKIP → pendiente, no rechazo) |

---

## 1. Puerta de aceptación

El harness `tests/qa_acceptance.gd` evalúa **6 criterios** (GDD §12 / contrato §9). Semántica de estados:

| Estado | Significado | Efecto en exit code |
|---|---|---|
| `[PASS]` | Criterio verificado con evidencia medible | — |
| `[FAIL]` | Criterio incumplido o regresión (el sistema existe pero no cumple) | Exit **1** |
| `[SKIP]` | Sistema aún stub/no disponible (pendiente de AG-2/AG-3), con justificación explícita | Exit **1** (baseline) |

**Regla:** `quit(0)` **solo** si los 6 criterios son `[PASS]`. Cualquier `FAIL` o `SKIP` devuelve 1. El harness **compila siempre** (se ejecutó con los stubs de Fase 0 sin errores de parseo) y no muta código de producción ni `data/`; solo escribe un save temporal en `user://saves/qa_acceptance_ag4.json` que elimina al terminar C3.

Comandos oficiales (desde `C:\Proyectos\TSB`):

```powershell
$G = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$R = "C:\Proyectos\TSB\sovereigns-blood"
& $G --headless --path $R --script tests/qa_acceptance.gd   # harness de aceptación Fase 1
& $G --headless --path $R --script tools/validate_data.gd   # no-regresión de datos Fase 0
& $G --headless --path $R --script tests/run_all.gd         # no-regresión suite Fase 0
& $G --headless --path $R --editor --quit                   # importación/compilación
```

---

## 2. Matriz criterio §12 → check del harness → comando → evidencia → dependencia

| # | Criterio GDD §12 / contrato §9 | Check en `tests/qa_acceptance.gd` | Comando | Evidencia que se registra | Depende de |
|---|---|---|---|---|---|
| 1 | Partida Inglaterra 1337 de principio a fin de año sin crash | `C1`: `new_game("scenario_1337","england",1337)`, state con 14 facciones/47 regiones, 4 trimestres con `begin_turn`/órdenes (`EconomySystem.allocate`, `DiplomacySystem.propose`)/`end_turn`, turno avanzado ≥4 sin crash | harness | `[PASS] C1` + año/trimestre inicial y final, nº de órdenes intentadas/aceptadas | AG-2: `GameState`, `TurnManager`, `DataLoader`, `EconomySystem`, `DiplomacySystem` |
| 2 | IA de las 13 facciones rivales completa en **<2.000 ms** | `C2`: contaje de facciones IA (`is_player != true` = 13), `AIManager.run_all_ai()` cronometrado con `Time.get_ticks_msec()`, cambio de estado verificable | harness | `[PASS] C2` + ms medidos, facciones IA, umbral 2000 | AG-2: `AIManager` (y los sistemas que use) |
| 3 | Guardar/cargar preserva el estado exacto (test automatizado) + determinismo §13 | `C3`: hash SHA-256 de `to_dict()` antes/después de `save_game`+`load_game`; continuidad RNG (vía `GameState.rng.next_int` o snapshot `rng` de `to_dict` restaurado en `SeededRNG`) | harness | `[PASS] C3` + hash (16 hex) y método de continuidad RNG | AG-2: `GameState` (`save/load/to_dict/from_dict`, `rng`), `SeededRNG` |
| 4 | Peste Negra dispara en 1348 (`event_log` + efecto −0.35 en Europa occidental) | `C4`: avance de años hasta 1348 (`advance_quarter`, fallback `advance_year`), `peste_negra_1348` en `event_log` y `fired_events`, `population_modifier -0.35`/`scope europe_west` en el dataset y descenso de población total observado | harness | `[PASS] C4` + año alcanzado, presencia en log/fired, delta de población | AG-2: `TurnManager`, eventos, `EconomySystem`; datos AG-1 (ya validados) |
| 5 | Batalla delegada produce informe coherente y captura regiones | `C5`: ejército del jugador en `state.armies`, vecino enemigo por adyacencia, `MilitarySystem.move_army` → resolución (`end_turn` si aplica), último `battle_reports`: ≥4 campos, bandos, bajas, y captura (declarada o `owner` de la región = Inglaterra) | harness | `[PASS] C5` + army/región, claves del informe, captura | AG-2: `MilitarySystem`, `BattleManager`, `BattleReport` |
| 6 | UI de §9 completa, instanciable headless sin errores | `C6`: escaneo recursivo `res://scenes/**/*.tscn`; `load().instantiate()` + `free()` por escena (contrato §7); informa fallos | harness | `[PASS] C6` + nº escenas OK/total y fallos | AG-3: `scenes/**` (main, scenario_select, map, council, family, diplomacy, battle, year_end, victory/defeat, componentes) |
| A4 | `tools/validate_data.gd` 0 errores (no-regresión Fase 0) | validación de datasets y reglas §13 | `validate_data.gd` | exit 0 + «6 datasets ↔ 6 schemas, 5.239 comprobaciones, 0 errores» | AG-1 (datos congelados en Fase 1) |
| A5 | CI headless sin errores críticos | suite de Fase 0 + importación | `tests/run_all.gd`, `--editor --quit` | 231 pass / 0 fail / 1 skip, exit 0; editor exit 0 sin ERROR/WARNING | AG-2 |
| §13 | Determinismo (misma semilla + acciones = mismo hash) | C3 + repetición del harness | harness ×2 | misma salida/código en ejecuciones repetidas | AG-2 |

---

## 3. Protocolo de ejecución y registro

1. Ejecutar los 4 comandos de §1 en orden y anotar **exit code** y salida íntegra.
2. Ejecutar el harness **dos veces** para determinismo; comparar salida y exit code.
3. Registrar en `docs/issues.md` (sección «Fase 1 — baseline» durante el desarrollo; sección de verificación final en task-9) y, si el volumen crece, en `docs/qa/fase1_report.md` (D-014).
4. Un `FAIL` se reporta con pasos de reproducción y no se corrige desde QA; un `SKIP` se justifica con el sistema/stub que falta y se convierte en requisito de la verificación final.
5. Repetir la no-regresión de datos (`validate_data.gd`) en cada ejecución: datos de Fase 0 no deben cambiar sin decisión de AG-0.
6. No se edita producción (`scripts/`, `scenes/`, `project.godot`, `data/`, `docs/STATUS.md`, `docs/decisions.md`) ni se ejecuta git.

---

## 4. Baseline actual (2026-11-21, arranque de Fase 1)

| Criterio | Estado baseline | Motivo registrado |
|---|---|---|
| C1 Partida Inglaterra 1337 | `SKIP` | `GameState.state` vacío tras `new_game()` (sistemas aún stub de Fase 0) |
| C2 IA <2 s | `SKIP` | Requiere partida (C1) y `AIManager` implementado |
| C3 Save/load exacto | `SKIP` | Requiere partida y `GameState` con `to_dict/save/load/rng` |
| C4 Peste Negra 1348 | `SKIP` | Requiere partida y `TurnManager` que avance años/eventos |
| C5 Batalla delegada | `SKIP` | `state.armies` vacío (MilitarySystem/BattleManager stub) |
| C6 Smoke UI | `SKIP` | `scenes/**` aún sin `.tscn` (AG-3 en curso) |

Resultado: **0 PASS / 0 FAIL / 6 SKIP**, exit 1 → **PENDIENTE** (no es rechazo: los sistemas están en implementación paralela). No-regresión Fase 0 en el baseline: `validate_data.gd` exit 0 (5.239 comprobaciones, 0 errores), `tests/run_all.gd` exit 0 (231/0/1), `--editor --quit` exit 0. Detalle íntegro en `docs/issues.md` § «Fase 1 — baseline».

---

## 5. Riesgos de verificación y mitigación

| ID | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| R1 | **UI headless**: el contrato §7 define el smoke como `load().instantiate() + free()`; no ejecuta `_ready` ni pintado real, así que una escena puede instanciarse y fallar en runtime (theme, viewport, señales). | Falso PASS de C6 | Mantener el smoke contractual; en task-9 añadir comprobación estática de `main_scene` y de que las escenas no mutan `GameState.state` (contrato §7), y una ejecución manual/con editor documentada. |
| R2 | **Presupuesto IA**: medición de una sola pasada en máquina compartida (AG-2/AG-3 compilando en paralelo) puede sesgar los 2.000 ms. | Falso FAIL/PASS de C2 | Usar `Time.get_ticks_msec()` (medido en el propio harness) y repetir el harness en la verificación final; reportar ms junto al resultado. Si el sistema no muta estado, se marca SKIP, no PASS. |
| R3 | **Determinismo de save**: `JSON.stringify` depende del orden de claves; si `to_dict()` reconstruye diccionarios con otro orden el hash puede diferir aunque el estado sea equivalente; flotantes pueden serializarse distinto. | Falso FAIL de C3 | El criterio es hash exacto (contrato §6); si aparece un falso positivo se documenta y se propone canonicalizar claves en AG-2 (nunca cambiar el criterio desde QA). RNG se comprueba por dos vías independientes. |
| R4 | **Peste Negra**: los eventos pueden dispararse en `end_turn`/`advance_year` y no en `advance_quarter`; el descenso de población puede quedar enmascarado por crecimiento económico del mismo año. | Falso FAIL/SKIP de C4 | El harness intenta `advance_quarter` y cae a `advance_year`; exige `event_log` + `fired_events` + modificador en el dataset; el delta de población se reporta como evidencia adicional, no como única condición si el log declara el efecto. |
| R5 | **Batalla estocástica**: el resultado depende de la tirada gaussiana (semilla 1337); la captura exige que venza el atacante y que el movimiento/resolución se dispare al mover el ejército. | Falso FAIL de C5 | Semilla fija 1337; el informe se imprime con sus claves para diagnosticar; si el sistema resuelve solo por `BattleManager.resolve_delegated` y no por movimiento, se pedirá a AG-0/AG-2 el punto de integración (QA no cambia producción). |
| R6 | **Concurrencia AG-2/AG-3**: el harness puede ejecutarse contra código a medio escribir (parse errors transitorios) o escenas parciales. | Baseline ruidoso | Ejecutar baseline en momentos estables, repetir al integrar; el harness reporta `[SKIP]`/`[FAIL]` con motivo, no aborta el proceso por stubs. |
| R7 | **Datos vivos**: los conteos esperados (14 facciones/47 regiones) se leen de `data/*.json`; un cambio de datos en Fase 3 alteraría el baseline. | Deriva | En Fase 1 los datos están congelados; `validate_data.gd` es la puerta de no-regresión. |
| R8 | **Escritura en `user://`**: C3 escribe un save temporal. | Contaminación de slots | Slot único `qa_acceptance_ag4` y limpieza al final de C3; nunca escribe dentro del repo. |

---

## 6. Checklist para task-9 (verificación final — NO reclamada aún)

> Task-9 está bloqueada hasta que AG-2/AG-3 declaren terminados sus módulos; AG-0 avisará para ejecutarla.

- [ ] 4 comandos de §1: exit code 0 (harness **6/6 PASS**, exit 0).
- [ ] Harness repetido 2×: misma salida/código (determinismo).
- [ ] C3: hash `to_dict()` idéntico y continuidad RNG demostrada.
- [ ] C4: `peste_negra_1348` en `event_log` y `fired_events`; `population_modifier -0.35`/`europe_west` verificado.
- [ ] C5: `battle_reports` con informe coherente y `owner` de la región capturada = Inglaterra.
- [ ] C6: `scenes/**` completo e instanciable; `main_scene` configurado (AG-3).
- [ ] No-regresión: `validate_data.gd` 0 errores; `run_all.gd` sin fallos; `--editor --quit` sin ERROR/WARNING.
- [ ] Contrato UI-sin-mutación (§7): comprobación estática de que `scripts/ui/**`/`scenes/**` no asignan `GameState.state`/`DataLoader` (grep documentado).
- [ ] Salida íntegra y códigos de salida en `docs/qa/fase1_report.md` + sección final en `docs/issues.md`; veredicto «QA Fase 1: APROBADO/RECHAZADO» a AG-0.

---

*Plan vivo: AG-4 lo actualiza al integrar los módulos de AG-2/AG-3, sin cambiar los criterios del GDD/contrato (los cambios de criterio son de AG-0).*

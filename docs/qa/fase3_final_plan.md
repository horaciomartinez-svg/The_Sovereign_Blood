# Plan de QA — Fase 3 final: 3 escenarios (1402/1453) y cierre de fase

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Fase / alcance** | Fase 3 final — GDD v1.7 §4.3/§4.4/§4.5/§6.4/§12; `docs/architecture_contracts_fase3_scenarios.md` §5; D-058..D-062 |
| **Harness** | `tests/qa_acceptance_fase3_final.gd` (`extends SceneTree`, sin GUT; compila siempre) |
| **Baseline** | HEAD `069a5e2`. Existen `scenario_1337`/`events_1337`; **aún no** `scenario_1402/1453`, `events_1402/1453`, ni retratos/capturas de los nuevos escenarios. AG-1/AG-2/AG-3 trabajan en paralelo. |
| **Veredicto** | Baseline: **PENDIENTE** (SKIP justificado, no es rechazo). Verificación final: **task-43**. |

---

## 1. Matriz criterio → test → comando → evidencia

| ID | Criterio (GDD §4.5/§12 + contrato §5) | Test en `qa_acceptance_fase3_final.gd` | Comando | Evidencia esperada |
|---|---|---|---|---|
| F3F-C1 | **3 escenarios arrancan y avanzan trimestre a trimestre hasta `end_year`** (1337→1399, 1402→1460, 1453→1480) sin crash; resultado de victoria/derrota coherente o supervivencia al año final. | `_criterion_1_scenarios()` | `godot --headless --script tests/qa_acceptance_fase3_final.gd` | PASS 3/3 con año final alcanzado |
| F3F-C2 | **Partida automatizada de 10 años por escenario**, sin errores y determinista (misma semilla → mismo hash de estado). | `_criterion_2_ten_years()` | ídem | PASS 3/3; hashes iguales |
| F3F-C3 | **Victoria/derrota §4.5**: prestigio (años mantenido), conquista ≥70%, supervivencia al `end_year`; derrota por extinción o pérdida de última región; cierre sin turnos fantasma. | `_criterion_3_victory()` | ídem | PASS motivos coherentes |
| F3F-C4 | **Datos**: 3 escenarios con 8 `playable_factions` cada uno, owners por año (`year_data` 1402/1453), eventos dentro de `[start_year, end_year]`, tech por era (I/II/III), validación 7+ datasets 0 WARN. | `_criterion_4_data()` + batería | ídem | PASS 3/3 datos; validate 0 |
| F3F-C5 | **Retratos §10.2**: 5 slots con textura para los gobernantes de 1337 y **fallback heráldico nunca vacío** para personajes nuevos sin PNG; sucesión de retrato. | `_criterion_5_portraits()` | ídem | PASS 5 slots/textura+fallback |
| F3F-C6 | **No regresión**: sprites 17/17 (F3 6/6), tiles §10.4 (7/7), F1 6/6, F2 6/6, 18 escenas, scripts compilando, determinismo. | `_criterion_6_no_regression()` + batería | ver §3 | PASS batería completa |
| F3F-C7 | **Capturas**: selección con 3 tarjetas + partida 1402 + partida 1453 (era visible), 1920×1080 en `docs/screenshots/`. | `_criterion_7_captures()` | ídem + visual | PASS 3/3 capturas |

**Semántica:** `[PASS]` cumplido; `[SKIP]` pendiente de módulo en curso (indica qué falta); `[FAIL]` módulo presente pero viola el contrato. **Exit 0 solo con 7/7 PASS**; baseline con SKIP sale 1 e imprime «PENDIENTE», no «rechazado».

---

## 2. Detalle de checks

### F3F-C1 — Arranque y avance hasta `end_year`
- `scenario_1337/1402/1453.json` existen; `GameState.new_game(id, faction_jugable)` arranca sin error.
- Bucle `TurnManager.advance_quarter` con guarda de seguridad; debe llegar a `end_year` de cada escenario (1399/1460/1480) o cerrar por victoria/derrota antes, sin crash ni años fuera de rango.
- Al final: `state.game_over` coherente; si no, `year == end_year` con supervivencia válida.

### F3F-C2 — 10 años automatizados y determinismo
- Por escenario: 40 trimestres desde `start_year`; ejecutar dos veces con la misma semilla y facción; comparar hash `GameState.to_dict()`; sin errores.
- No se exige que gane la partida; sí que el estado sea serializable, determinista y no haya crash.

### F3F-C3 — Victoria/derrota
- Leer `victory {crowns, prestige, years_held, control_pct}` del escenario y las APIs de `GameState`/`TurnManager`.
- Comprobar: prestigio mantenido → victoria; control ≥70% → victoria por conquista; `end_year` sin derrota → supervivencia; extinción/pérdida de última región → derrota; tras `game_over`, el reloj no avanza (sin turnos fantasma).
- Si AG-2 aún no expone motivo/estado de victoria → SKIP (módulo en curso).

### F3F-C4 — Datos
- 3 escenarios con `playable_factions` **exactamente 8** y ⊆ `factions`; owners de `map_borders.json` para 1402/1453 coinciden con `year_data` de regiones; eventos de `events_1402/1453` con años en rango y source; tech: eras de `units.json` coherentes con año (I <1350, II 1350-1399, III ≥1400).
- `validate_data.gd` externo: 0 WARN/0 errores (7+ datasets).

### F3F-C5 — Retratos
- 5 slots (mapa, familia, diplomacia, batalla, corte): gobernante de 1337 con `is_fallback=false`; personaje nuevo sin PNG → `is_fallback=true` e id no vacío; sucesión actualiza el retrato sin hueco.
- Dependencia externa Kimi (D-062) documentada: si no hay retratos nuevos, fallback es aceptable y se registra como observación, no bloqueo.

### F3F-C6 — No regresión
- 18 escenas, tests ≥26, harness F1/F2/F3-sprites/tiles presentes, artefactos §10.1-§10.4, 0 scripts sin compilar; batería externa.

### F3F-C7 — Capturas
- `scenario_select_1402_1453.png` (3 tarjetas), `scenario_1402_inicio.png`, `scenario_1453_inicio.png`; 1920×1080; revisión visual (era visible, mapa del año, retratos/fallback).

---

## 3. Comandos

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_fase3_final.gd   # harness final
& $g --headless --path $repo --script tests/qa_acceptance.gd               # F1
& $g --headless --path $repo --script tests/qa_acceptance_fase2.gd         # F2
& $g --headless --path $repo --script tests/qa_acceptance_fase3.gd         # sprites 17/17
& $g --headless --path $repo --script tests/qa_acceptance_tiles.gd         # tiles §10.4
& $g --headless --path $repo --script tests/run_all.gd                     # suite completa
& $g --headless --path $repo --script tools/validate_data.gd               # 0 errores
& $g --headless --path $repo --editor --quit                               # import + 0 ERROR/WARNING
& $g --headless --path $repo --quit                                        # 0 ERROR/WARNING
```

**Baseline esperado:** F3F-C6 PASS; C1-C5/C7 SKIP (sin datos/escenarios nuevos). Salida 1 con «PENDIENTE». Detalle en `docs/issues.md` §17.

---

## 4. Riesgos R-F3F

| ID | Riesgo | Mitigación QA |
|---|---|---|
| R-F3F-01 | Escenarios 1402/1453 no existen o no arrancan (`new_game` falla). | C1 detecta y da SKIP/FALLO con archivo ausente; no se aprueba sin los 3. |
| R-F3F-02 | Fast-forward largo (58/27 años) provoca crash o cuelgue. | Guardas de trimestres, timeout de proceso; C1 falla con reproducción. |
| R-F3F-03 | Estado no determinista o save no serializable en 10 años. | C2 dos ejecuciones mismo hash; C6 determinismo. |
| R-F3F-04 | Victoria/derrota mal evaluada (prestigio/conquista/supervivencia/extinción). | C3 motivos y cierre; comparar con `end_year` y `game_over`. |
| R-F3F-05 | Datos incoherentes (8 jugables, owners por año, eventos fuera de rango, tech). | C4 + `validate_data` 0 WARN. |
| R-F3F-06 | Retratos nuevos sin PNG dejan huecos en slots. | C5 fallback no vacío; dependencia Kimi documentada (D-062). |
| R-F3F-07 | Capturas ausentes o sin 1920×1080. | C7 nombres/tamaño y revisión visual. |
| R-F3F-08 | Regresión de sprites 17/17 o tiles §10.4 al añadir escenarios. | C6 + F3/tiles 6/6/7/7. |
| R-F3F-09 | Concurrencia AG-1/AG-2/AG-3 durante el baseline. | Snapshot HEAD; final sobre commits integrados. |
| R-F3F-10 | Tech por era no filtra unidades (p. ej. jenízaro antes de 1400). | C4 comprueba eras/tech y C3 no depende de unidades fuera de era. |

---

## 5. Verificación final (task-43)
Harness final 7/7 PASS exit 0; batería completa; capturas/revisión visual; veredicto **«QA Fase 3 final: APROBADO/RECHAZADO»** en `docs/qa/fase3_report.md` + `docs/issues.md`, con observaciones de la dependencia externa (retratos/animaciones Kimi) si sigue pendiente.

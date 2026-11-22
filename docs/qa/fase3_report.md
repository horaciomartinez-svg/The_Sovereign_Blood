# Informe de QA — Fase 3 completa (3 escenarios, 10 años, assets)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Veredicto** | **QA Fase 3: APROBADO CON OBSERVACIONES** |
| **Alcance** | GDD v1.7 §4.3/§4.4/§4.5/§6.4/§12; `docs/architecture_contracts_fase3_scenarios.md`; D-058..D-062 |
| **HEAD verificado** | `765e5fb` (AG-1 datos 1402/1453, AG-2 motor/tech/victoria, AG-3 UI 3 escenarios, AG-5 petición de assets externos) |
| **Harness** | `tests/qa_acceptance_fase3_final.gd` (7 criterios) + F1/F2/F3-sprites/tiles |
| **Scope** | Solo `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd`; sin producción ni git |

---

## 1. Veredicto y resumen

> **QA Fase 3: APROBADO CON OBSERVACIONES**

**7/7 criterios PASS**, 0 FAIL, 0 SKIP. Las observaciones no bloquean la aceptación: dependen de la entrega externa de arte de Kimi (D-062), con fallback auditado que garantiza que no haya huecos.

| Criterio | Estado | Evidencia principal |
|---|---|---|
| F3F-C1 3 escenarios hasta `end_year` | **PASS** | 1337→1399 (248 trimestres), 1402→1460 (232), 1453→1480 (108); `game_over=true` en los 3 |
| F3F-C2 10 años ×2 determinista | **PASS** | 1337 `947b790d1d56`; 1402 `f7c7fbb99bdd`; 1453 `23906401cd23` (hashes idénticos entre 2 ejecuciones) |
| F3F-C3 Victoria/derrota §4.5 | **PASS** | Prestigio, conquista ≥70%, supervivencia, derrota por pérdida total y por dinastía eliminada; reloj congelado |
| F3F-C4 Datos 3 escenarios | **PASS** | 8 playable por escenario, owners `year_data`, eventos en rango, tech I/II/III; validate 11/7, 0 WARN |
| F3F-C5 Retratos 5 slots | **PASS** | 14/14 gobernantes 1337 con textura 256×256; nuevos 1402/1453 con fallback id no vacío; 5/5 slots |
| F3F-C6 No regresión | **PASS** | Sprites 17/17, tiles 12/12, 18 escenas, 28 tests, F1/F2/F3/tiles verdes |
| F3F-C7 Capturas | **PASS** | `selection_3_scenarios.png`, `game_1402.png`, `game_1453.png` 1920×1080 (+`era_hud.png`) |

---

## 2. Evidencia de comandos

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase3_final.gd` (×2) | **0 / 0** | **7/7 PASS**; C1 6,2 s; C2 3,3 s; resto <1,4 s |
| 2 | `--script tests/qa_acceptance.gd` (F1) | **0** | **6/6 PASS** (save hash `8482c5503ef38f81`, 157.499 B) |
| 3 | `--script tests/qa_acceptance_fase2.gd` (F2) | **0** | **6/6 PASS** (ver §5, harness actualizado) |
| 4 | `--script tests/qa_acceptance_fase3.gd` (sprites) | **0** | **6/6 PASS** |
| 5 | `--script tests/qa_acceptance_tiles.gd` (tiles) | **0** | **7/7 PASS** |
| 6 | `--script tests/run_all.gd` | **0** | **1250 / 0 / 1**; `CI: OK` |
| 7 | `--script tools/validate_data.gd` | **0** | **11 datasets / 7 schemas, 11.069 comprobaciones, 0 errores/WARN** |
| 8 | `--editor --quit` | **0** | 6 `[DONE]`, 0 ERROR/WARNING |
| 9 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |
| 10 | save/load 1402 (sonda) | **OK** | hash `34efa412f2de66e8` idéntico antes/después |

Salida íntegra del harness final (extracto de la ejecución canónica):

```text
[INFO] Fase 3 final — presencia de artefactos:
  scenario_1337/1402/1453.json: true; events_1337/1402/1453.json: true
  docs/screenshots: 58 PNG; tests: 28; sprites: 51 PNG; tiles: 12 PNG
  [PASS] F3F-C1 — 3 escenarios arrancan y llegan a end_year sin crash :: scenario_1337=year=1399 end=1399 quarters=248 game_over=true; scenario_1402=year=1460 end=1460 quarters=232 game_over=true; scenario_1453=year=1480 end=1480 quarters=108 game_over=true
  [PASS] F3F-C2 — Partida automatizada de 10 años por escenario, sin errores y determinista :: scenario_1337 hash=947b790d1d56; scenario_1402 hash=f7c7fbb99bdd; scenario_1453 hash=23906401cd23
  [PASS] F3F-C3 — Victoria por prestigio/conquista≥70%/supervivencia y derrota por extinción/pérdida total :: motivos verificados: prestigio='Prestigio Real sostenido durante 10 años'; conquista='Conquista: controlas ≥70% de las regiones'; supervivencia='Supervivencia hasta el año final (1399)'; derrota-pérdida='El jugador ha perdido todas sus regiones'; derrota-extinción='dinastía extinta'; reloj congelado tras cierre
  [PASS] F3F-C4 — Datos: 3 escenarios, 8 playable, owners por año, eventos en rango y tech por era :: scenario_1337 playable=8 events=1399; scenario_1402 playable=8 events=1460; scenario_1453 playable=8 events=1480; owners/year_data y tech I/II/III OK; validate_data externo 0 errores
  [PASS] F3F-C5 — Retratos 5 slots: 14 de 1337 con textura y nuevos 1402/1453 con fallback heráldico :: 14/14 gobernantes 1337 con PNG 256x256 y textura; nuevo henry_iv_england con fallback id no vacío; 5/5 slots
  [PASS] F3F-C6 — No regresión: sprites 17/17, tiles §10.4, F1/F2, escenas y scripts :: 17/17 sprites; 12 tiles; 18 escenas; 28 tests; F1/F2/F3/tiles; scripts fallos=0
  [PASS] F3F-C7 — Capturas de selección 3 tarjetas y partidas 1402/1453 (1920x1080) :: 3/3 capturas: selection_3_scenarios.png, game_1402.png, game_1453.png
RESULTADO QA FINAL FASE 3: 7 PASS, 0 FAIL, 0 SKIP
ACEPTACIÓN FINAL FASE 3: OK — 7/7 criterios PASS (exit 0)
```

---

## 3. Criterio por criterio

### F3F-C1 · 3 escenarios hasta `end_year` — PASS
- 1337: 248 trimestres → 1399; 1402: 232 → 1460; 1453: 108 → 1480; todos con `game_over=true` y sin crash.
- Se ejecutó `new_game` con facción jugable real (8 `playable` por escenario).

### F3F-C2 · 10 años ×2 determinista — PASS
- 40 trimestres por escenario y repetición con misma semilla: hashes idénticos (`947b790d1d56`, `f7c7fbb99bdd`, `23906401cd23`).
- Estado serializable y sin errores en los 3 escenarios.

### F3F-C3 · Victoria/derrota §4.5 — PASS
- **Prestigio:** 500 sostenido 10 años → `end_game(true, "Prestigio Real sostenido…")`.
- **Conquista:** ≥70% de regiones → `Conquista: controlas ≥70%…`.
- **Supervivencia:** año final 1399 → `Supervivencia hasta el año final (1399)`.
- **Derrota por pérdida total:** 0 regiones → `El jugador ha perdido todas sus regiones`.
- **Derrota por dinastía extinta:** rama eliminada → `dinastía extinta` (la extinción real de casa se cubre además en F2-C2).
- Tras `game_over`, `advance_quarter` no cambia año/trimestre (sin turnos fantasma).

### F3F-C4 · Datos 3 escenarios — PASS
- 8 facciones jugables efectivas por escenario (1402/1453 explícitas; 1337 vía flags `playable` globales: fallback documentado).
- `year_data` 1402/1453 con owners válidos (≥40/47 por escenario, 0 inválidos); eventos de `events_1402/1453` con años dentro de `[start_year, end_year]`; 17 unidades con era I/II/III.
- `validate_data` 11 datasets/7 schemas, 11.069 comprobaciones, **0 WARN**.

### F3F-C5 · Retratos 5 slots — PASS
- 14/14 gobernantes de 1337 con PNG 256×256 (`is_fallback=false`).
- Gobernantes nuevos 1402/1453 sin PNG → fallback heráldico con id no vacío (p. ej. `henry_iv_england`); 5/5 slots con widget.
- La entrega ilustrada de Kimi (D-062) sigue pendiente; el fallback garantiza que nunca hay hueco (ver §6).

### F3F-C6 · No regresión — PASS
- Sprites 17/17 (6/6), tiles §10.4 (7/7), F1 6/6, F2 6/6, 18 escenas, 28 tests, 0 scripts sin compilar.

### F3F-C7 · Capturas — PASS
- `selection_3_scenarios.png` (3 tarjetas, casas jugables, objetivos), `game_1402.png` (Bayezid I, año 1402, Era III, fallback), `game_1453.png` (Mehmed II, año 1453, Era III, fallback); todas 1920×1080; `era_hud.png` adicional.
- Revisión visual: selección correcta, años/era visibles, gobernantes correctos, retratos fallback sin huecos.

---

## 4. Gobernantes por escenario (D-058)

Sonda independiente (coincide con las capturas):
- **1402:** England → `henry_iv_england` (Enrique IV, no Eduardo III); Ottoman → `bayezid_i_ottoman` (Bayezid I).
- **1453:** England → `henry_vi_england` (Enrique VI); Ottoman → `mehmed_ii_ottoman` (Mehmed II); Byzantium → `constantine_xi_byzantium` (Constantino XI; id real del dataset).
- Save/load 1402: hash `34efa412f2de66e8` idéntico tras `to_dict`/`from_dict`.

---

## 5. Actualización de harness históricos (F2/F1) para v1.7

El comportamiento vigente cambió con Fase 3; se adaptaron los harness sin relajar la aceptación:

- **F2-C2 (extinción):** ahora mata **toda la línea de la facción, incluidos nacimientos futuros** (`died=year`), porque D-058 considera línea viva a nacidos futuros; antes solo mataba vivos actuales y el motor elegía correctamente `joan_of_england` (faction escocia). Resultado: `extinct=true`, `dynasty_extinct`, game_over derrota, reloj congelado → PASS.
- **F2-C4 (retratos):** valida **14 retratos de 1337** (no 14 de 56 gobernantes globales), texturas 14/14 y **fallback** en los 42 gobernantes nuevos sin PNG → PASS.
- **F1-C1:** el estado inicial del escenario 1337 tiene **14 facciones**, no las 23 del dataset global (9 nuevas para 1402/1453); el check usa la lista de facciones del escenario → PASS.
- **F2** vuelve a **6/6** y **F1** a **6/6**; no se modificó producción.

---

## 6. Observaciones (no bloqueantes)

1. **Dependencia externa de arte (D-062):** AG-5 preparó `docs/art/requests/kimi_phase3_assets.md` con **69 retratos 256×256** (42 gobernantes + 27 herederos/regentes/claimants de 1402/1453) y **184 PNG de animación** (idle/attack/impact/death de las 17 unidades). Pendientes de Kimi. El fallback heráldico y los sprites de marcha actuales garantizan que **no haya huecos**; se documenta como observación, no como bloqueo.
2. **1337 `playable_factions` implícitas:** el JSON de 1337 no declara el array (los 1337 se mantienen intactos); la UI/motor derivan las 8 jugables de los flags globales `playable`. Efecto usuario correcto; se propone añadirlo en una limpieza futura.
3. **C3 extinción:** el cierre por "dinastía extinta" se prueba con la rama eliminada; la extinción real de casa (sin herederos vivos, incluidos futuros) está cubierta por **F2-C2**.
4. **REA §3.2:** la observación interactiva de N2/N3 sigue limitada por la ausencia de capturas del usuario (declarado en el informe REA, aceptado en Fase 2); no afecta a esta QA.
5. **Alcance de la simulación:** C1 llega a `end_year` real; C2 valida 10 años deterministas (no repite los 58/27 años completos dos veces por coste, ya cubiertos por C1).
6. **Tags:** existen `fase-0`, `fase-1`, `fase-2`; **`fase-3` aún no está creado** (lo hará AG-0 tras este informe).

---

## 7. Riesgos residuales

| ID | Riesgo | Estado |
|---|---|---|
| R-F3F-01 | Escenarios ausentes/no arrancan | **Mitigado/verificado** (3/3 llegan a end_year) |
| R-F3F-02 | Fast-forward largo con crash | **Mitigado** (C1 6,2 s, sin crash) |
| R-F3F-03 | No determinismo/save en 10 años | **Mitigado** (hashes idénticos; save/load 1402 OK) |
| R-F3F-04 | Victoria/derrota mal evaluada | **Mitigado** (5 motivos comprobados) |
| R-F3F-05 | Datos incoherentes | **Mitigado** (validate 11/7 0 WARN; owners/eventos/tech) |
| R-F3F-06 | Retratos nuevos sin PNG | **Abierto como observación** (fallback sin huecos, D-062) |
| R-F3F-07 | Capturas ausentes/sin 1920×1080 | **Mitigado** (3/3 + era_hud) |
| R-F3F-08 | Regresión sprites/tiles/F1/F2 | **Mitigado** (17/17, 12/12, 6/6, 6/6) |
| R-F3F-10 | Tech por era | **Mitigado** (eras I/II/III validadas) |
| R-F3F-11 | Arte externo incompleto | **Observación aceptada** (fallback auditado) |

---

## 8. Artefactos y estado

| Artefacto | Ruta |
|---|---|
| Harness final | `tests/qa_acceptance_fase3_final.gd` |
| Plan final | `docs/qa/fase3_final_plan.md` |
| Este informe | `docs/qa/fase3_report.md` |
| Registro | `docs/issues.md` §17 baseline, §18 final |
| Capturas | `selection_3_scenarios.png`, `game_1402.png`, `game_1453.png`, `era_hud.png` |
| Petición externa | `docs/art/requests/kimi_phase3_assets.md` (69 retratos + 184 animaciones) |

**Recomendación:** aceptar Fase 3 con observaciones, actualizar STATUS, crear tag `fase-3` y push; mantener la petición a Kimi (D-062) como deuda de arte externa no bloqueante.

*Fin del informe QA Fase 3 — AG-4. Veredicto: **APROBADO CON OBSERVACIONES**.*

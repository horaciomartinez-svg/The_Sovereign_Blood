# Plan de QA — Fase 4: profundidad GK2 (C1-C12)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Directiva** | D-069…D-073; GDD v1.9; contrato `docs/architecture_contracts_fase4.md`; prompt `prompt_DSH_fase4_profundidad_v1.md` |
| **Alcance** | REA economía/menús, mercancías/comercio, ejércitos y reclutamiento con bienes, consorte, Manual, tutorial/dificultad, save/load, no regresión, 1402/1453 congelados y UX/capturas |
| **Harness** | `tests/qa_acceptance_fase4.gd` (C1-C12; `extends SceneTree`; compila siempre; SKIP justificado; exit 0 solo con 12/12) |
| **Baseline** | HEAD `a5c22ff` (arranque Fase 4; módulos AG-REA/AG-1/AG-2/AG-3 en curso) |
| **Verificación final** | task-69 (bloqueada por AG-REA/AG-1/AG-2/AG-3: task-61/62/63/65/66/67/68) |

> **Semántica:** PASS = criterio cumplido; SKIP = pendiente de módulo en curso (no es rechazo); FAIL = incumplimiento. Baseline con SKIP sale 1 e imprime «PENDIENTE». **Exit 0 solo con C1-C12 PASS.**

---

## 1. Matriz C1-C12 → test → comando → evidencia

| # | Criterio (prompt F4 §9) | Test en `qa_acceptance_fase4.gd` | Evidencia |
|---|---|---|---|
| C1 | REA economía/menús entregado y legal: ≤2 páginas, 0 `.EXE`, sin texto transcrito | `_criterion_1_rea()` | `docs/rea/gk2_economy_military_family.md` + `notes_economy.md`; auditoría de patrones prohibidos |
| C2 | `trade_goods.json` + schema + fuentes; validate 0 WARN | `_criterion_2_trade_data()` | 8-12 bienes, campos, schema, `sources.md` §13, `validate_data` 12/8→13/9 |
| C3 | Comercio: solo con comerciantes, precios fluctúan, 10 años sin inflación | `_criterion_3_trade()` | API `TradeSystem`/Economía, rechazo sin comerciantes, precios, simulación |
| C4 | Pantalla ejércitos: imágenes/conteos y Reclutar/Entrenar/Disolver | `_criterion_4_armies()` | escena/API `get_faction_army_summary`, captura `army_management.png` |
| C5 | Reclutamiento consume caballos/armas | `_criterion_5_recruit_goods()` | `recruit_goods` en units + inventario descontado / fallo con motivo |
| C6 | Consorte: bonus fertilidad, cooldown, estados íntegros | `_criterion_6_consort()` | API `spend_time_with_consort`, estado `consort_cooldown`/`fertility_bonus_until_turn` |
| C7 | Manual completo (10 secciones) y accesible desde el juego | `_criterion_7_manual()` | `docs/MANUAL_DEL_JUGADOR.md`, acceso «Manual»/«Ayuda», captura |
| C8 | Tutorial JSON/resaltes/salto; Principiante con Consejero, Normal sin él | `_criterion_8_tutorial()` | `data/tutorial_script.json` 8-10 pasos, `TutorialSystem`, capturas `tutorial_*` |
| C9 | Save/load inventario+tutorial (+migración) | `_criterion_9_save_load()` | round-trip `trade`/`tutorial`/`difficulty`, hash y versión |
| C10 | No regresión: run_all ≥1742/0, validate 0, editor 0, F1/F2/F3/MVP/anim/tiles | `_criterion_10_regression()` | batería externa + artefactos |
| C11 | 1402/1453 diff 0; sin arte externo nuevo | `_criterion_11_frozen_art()` | hashes congelados + `git diff fase-3.3..fase-4` + petición arte |
| C12 | UX: 0 botones muertos, PG/feedback visibles, capturas 1920×1080 | `_criterion_12_ux()` | `ui_smoke`, capturas `market`/`army_management`/`manual`/`tutorial_*` |

---

## 2. Detalle de checks

### C1 — REA legal
- Existe `docs/rea/gk2_economy_military_family.md` (cuerpo ≤2 páginas / ≤2.000 palabras) + `notes_economy.md`.
- Sin evidencia de `.EXE`/desensamblado/Ghidra/IDA/objdump/dump; sin transcripción literal; sección de método/legal.
- Si falta → **SKIP**.

### C2 — Datos
- `data/trade_goods.json`: envelope D-009, **10 bienes** esperados (8-12), `base_price`, `produced_by` (terrain/buildings), `used_by`, `source`; schema `trade_goods.schema.json`; `sources.md` §13 con fuentes.
- `validate_data` debe reconocerlo y dar 0 WARN (13 datasets / 9 schemas esperados).

### C3 — Comercio
- `TradeSystem`/extensión de Economía: `get_inventory`, `get_good_price`, `can_trade`, `buy/sell`, `get_merchants`, `produce_quarter`.
- Sin comerciantes → compra/venta rechazada con motivo; con comerciantes → volumen/precio; precios fluctúan de forma determinista.
- Simulación 10 años ×8 con `tools/simulate_balance_1337.gd`: comercio ≤~25 % de economía base y sin inflación >D-068.

### C4 — Ejércitos
- `get_faction_army_summary` por tipo con count/men/strength/avg morale/experience y `sprite_path` `<unit_id>_march_1.png`; `train_unit`/`disband_unit`; UI/captura.
- Reclutar/Entrenar/Disolver efectivos y sin estados huérfanos.

### C5 — Reclutamiento con bienes
- `units.json.recruit_goods`: caballería→caballos, infantería pesada→armas; reclutar sin bienes falla con motivo; con bienes descuenta inventario; resto sin campo.

### C6 — Consorte
- `spend_time_with_consort`: 2-3 PG, 1/trimestre, consorte viva/no enferma/edad fértil; bonus 2-4 trimestres; rechazo claro sin consorte/cooldown; estado serializable.

### C7 — Manual
- `docs/MANUAL_DEL_JUGADOR.md` con 10 secciones (índice del prompt §6); acceso desde menú principal (`OS.shell_open`) y «Ayuda» en consejo; captura.

### C8 — Tutorial/dificultad
- `data/tutorial_script.json` 8-10 pasos con id/title/text/objective/highlight/condition/order; `TutorialSystem` advance/skip/step; `difficulty` beginner/normal; Principiante activa Consejero y agresividad reducida; capturas `tutorial_consejero.png`, `tutorial_highlight.png`.
- `state` serializa `tutorial` y `difficulty`; migración v1→v2 si aplica.

### C9 — Save/load
- `trade.inventory`, `prices`, `merchants_assigned`, `tutorial`, `difficulty`, `consort` en `to_dict/from_dict`; hash exacto; save_version/migración.

### C10 — No regresión
- `tests/run_all.gd` ≥1742/0; `validate_data` 0; editor/headless 0; F1/F2/F3/MVP/anim/tiles verdes; harness fase4 estático.

### C11 — Congelados/arte
- `git diff fase-3.3..fase-4` sobre `data/scenarios/scenario_1402/1453`, `data/events_1402/1453` = 0 archivos; hashes actuales de referencia.
- Sin nuevas peticiones/art externo; arte existente/código.

### C12 — UX/capturas
- `ui_smoke` sin errores; 0 botones muertos en Mercado/Ejércitos/Familia/Manual/Tutorial; PG/feedback visibles; capturas nuevas 1920×1080 (mercado, ejércitos, manual, consorte, tutorial, dificultad).

---

## 3. Comandos

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_fase4.gd       # C1-C12
& $g --headless --path $repo --script tests/qa_acceptance_mvp_1337.gd    # C10
& $g --headless --path $repo --script tests/qa_acceptance_fase3_anim.gd  # C10
& $g --headless --path $repo --script tests/qa_acceptance_fase3.gd
& $g --headless --path $repo --script tests/qa_acceptance_tiles.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase3_final.gd
& $g --headless --path $repo --script tests/qa_acceptance.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase2.gd
& $g --headless --path $repo --script tests/run_all.gd
& $g --headless --path $repo --script tools/validate_data.gd
& $g --headless --path $repo --script scripts/ui/dev/ui_smoke.gd
& $g --headless --path $repo --editor --quit
& $g --headless --path $repo --quit
```

**Baseline ejecutado (HEAD `a5c22ff`, arranque Fase 4; módulos en curso):** **3 PASS / 0 FAIL / 9 SKIP** — C2 (trade_goods 10 bienes/schema/§13), C5 (9 unidades con recruit_goods: 6 caballos/1 armas) y C11 (1402/1453 intactos + petición arte congelada) PASS; C1/C3/C4/C6/C7/C8/C9/C10/C12 SKIP. `validate_data` **13/9, 11.851 comprobaciones, 0 WARN**, editor 0; **`run_all` 1688/44 (transitorio)**: `military_system.gd` llama a `_recruit_goods_requirements()` aún inexistente → autoload MilitarySystem no monta y 9 líneas ERROR en headless. No es rechazo de QA: es compilación Fase 4 en curso (AG-2); el baseline se repetirá en task-69 sobre commits finales. Detalle en `docs/issues.md` §22.

---

## 4. Riesgos R-F4

| ID | Riesgo | Mitigación |
|---|---|---|
| R-F4-01 | REA con `.EXE`/texto transcrito o >2 páginas | C1 auditoría de patrones + conteo |
| R-F4-02 | trade_goods/schema no validados o sin fuentes | C2 + validate 0 WARN |
| R-F4-03 | Comerciantes ignorados o inflación por comercio | C3 rechazo/prueba de precios + simulación |
| R-F4-04 | Pantalla ejércitos incompleta o acciones sin efecto | C4 API + captura + estados |
| R-F4-05 | Reclutamiento no consume caballos/armas | C5 fallo/suceso e inventario |
| R-F4-06 | Consorte rompe cooldown/estado o fertilidad | C6 estados + save |
| R-F4-07 | Manual incompleto/inaccesible | C7 10 secciones + botón |
| R-F4-08 | Tutorial hardcodeado/sin resaltes o dificultad no aplica | C8 JSON/API + capturas |
| R-F4-09 | Save/load pierde inventario/tutorial o migración | C9 hash/versión |
| R-F4-10 | Regresión F1/F2/F3/MVP/anim/tiles | C10 batería completa |
| R-F4-11 | Se toca 1402/1453 o se pide arte externo | C11 hashes/diff/art |
| R-F4-12 | Botones muertos/capturas faltantes | C12 ui_smoke + capturas |
| R-F4-13 | Concurrencia AG-REA/1/2/3 durante baseline | snapshot HEAD; final sobre commits integrados |
| R-F4-14 | Comercio desbalancea la economía 1337 | D-068 + simulación 10 años |
| R-F4-15 | Tutorial no serializa o no migra partidas viejas | C9 con `save_version` |
| R-F4-16 | Compilación intermedia: `military_system.gd` referencia función ausente y bloquea autoloads/run_all | AG-2 debe cerrar compilación; task-69 exige run_all 1742/0 y headless 0 ERROR |

---

## 5. Verificación final (task-69)

Harness C1-C12 ×2 exit 0; batería completa; auditoría REA/legal; `git diff` 1402/1453 = 0; capturas revisadas; veredicto **«QA Fase 4: APROBADO/RECHAZADO»** en `docs/qa/fase4_report.md` + `docs/issues.md` §22.

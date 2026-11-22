# Plan de QA — Fase 5A: «El juego te explica» (C1-C11)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Directiva** | Prompt `prompt_DSH_fase5a_legibilidad_v1.md`; GDD v1.9.2; contrato `docs/architecture_contracts_fase5a.md`; D-079…D-083 |
| **Alcance** | HUD estación/año/tinte, boletín, Crónica e histórico, confirmación de órdenes, consejo comercial, ayuda «?», paneles N2/N3, save/load chronicle, no regresión, congelamientos, gobernanza y **Manual actualizado (C11)** |
| **Harness** | `tests/qa_acceptance_fase5a.gd` (C1-C11; `extends SceneTree`; compila siempre; SKIP justificado; exit 0 solo con 11/11) |
| **Baseline** | HEAD `ee6cf52a` (GDD v1.9.2 + D-079…D-083; módulos AG-1/AG-2/AG-3 + task-81 en curso) |
| **Verificación final** | task-80 (bloqueada por AG-1/AG-2/AG-3 y task-81) |

> **Semántica:** PASS = criterio cumplido; SKIP = pendiente de módulo en curso (no es rechazo); FAIL = incumplimiento. Baseline con SKIP sale 1 «PENDIENTE». **Exit 0 solo con C1-C11 PASS.**

---

## 1. Matriz C1-C11 → test → comando → evidencia

| # | Criterio (prompt 5A §8) | Test | Evidencia |
|---|---|---|---|
| C1 | HUD estación+año en mapa, tinte por código, capturas ×4 | `_criterion_1_hud()` | `GameState.get_season_name/index/label`, HUD, tintes, `season_*.png` |
| C2 | Boletín ≥5 categorías, texto propio, 0 botones muertos | `_criterion_2_bulletin()` | `data/legibility_texts.json`, UI boletín, `bulletin.png` |
| C3 | Crónica anual + histórico persistido (hash) y consultable | `_criterion_3_chronicle()` | `append/get_chronicle`, `to_dict/from_dict`, pestaña Crónica, `chronicle.png` |
| C4 | Confirmación con lista (incl. vacía) y Corregir/Confirmar; log determinista | `_criterion_4_orders()` | `turn_actions`/`record/clear`, modal, `confirm_*.png` |
| C5 | Consejo comercial correcto (precio alto/bajo), sin RNG, captura | `_criterion_5_advice()` | `TradeSystem.get_trade_advice`, determinismo, `market_advice.png` |
| C6 | Botón «?» en todas las pantallas §9, capturas ≥4 | `_criterion_6_help()` | `data/context_help.json` 18 pantallas, UI, `help_*.png` |
| C7 | N2/N3: hombres/armas/apoyo/moral/experiencia + comandante | `_criterion_7_unit_panels()` | estado+UI batalla, `unit_panel_n2/n3.png` |
| C8 | Save/load chronicle 3 puntos + defaults para partidas antiguas | `_criterion_8_save()` | hash/round-trip, defaults, tests |
| C9 | No regresión: run_all, validate 0 WARN, editor 0, IA<2 s, mapa<8 ms | `_criterion_9_regression()` | batería externa |
| C10 | diff 0 1402/1453, sin arte, GDD v1.9.2 + D-079…083 + STATUS | `_criterion_10_governance()` | hashes/diff, docs, petición arte |
| C11 | Manual actualizado con las 5 mejoras, coherente con datos/juego | `_criterion_11_manual()` | `docs/MANUAL_DEL_JUGADOR.md` + contraste con `context_help.json`/`legibility_texts.json` y capturas |

---

## 2. Detalle de checks

### C1 — HUD/estaciones
- `GameState.get_season_name(quarter_override)`, `get_season_index`, `get_season_label`: 1→Primavera, 2→Verano, 3→Otoño, 4→Invierno; año tras invierno; sin estado nuevo.
- HUD persistente «{Estación} {Año} — Tesoro/PG»; tinte por código (CanvasModulate/overlay) con parámetros constantes y opción de desactivar.
- Capturas `season_spring/summer/autumn/winter.png` 1920×1080.

### C2 — Boletín
- `data/legibility_texts.json` con plantillas propias (≥5 categorías: ingresos/gastos, apoyo, acciones, corte, mercaderes/expediciones, eventos).
- Modal al cerrar trimestre, 4-6 líneas, botón Continuar vivo; `bulletin.png`.

### C3 — Crónica
- `state.chronicle` lista `{year, season_or_year, kind, text}`; API `append_chronicle`, `get_chronicle(year?)`, `get_chronicle_text`; persistido `to_dict/from_dict`.
- Crónica anual con desglose/eventos/guerras/ranking; pestaña consultable; `chronicle.png`.

### C4 — Confirmación
- `state.turn_actions` lista `{action,target,pg}`; API `record_turn_action`, `get_turn_actions`, `clear_turn_actions`; reset al empezar turno/año; no serializado (D-081).
- Modal con lista o «No has dado órdenes…», botones Corregir/Confirmar, aviso de exenciones; capturas con/sin órdenes; log determinista (misma secuencia → mismo listado).

### C5 — Consejo comercial
- `TradeSystem.get_trade_advice(faction_id, region_id)` → `{ok, good_id, kind, price, base, margin, text}`, **sin RNG**; elige mayor/menor margen y contempla expediciones.
- Caso precio alto/bajo forzado en estado; captura `market_advice.png`.

### C6 — Ayuda «?»
- `data/context_help.json` para las 18 pantallas §9 (`main_menu`…`victory`); cada entrada 3-5 líneas propias.
- Botón «?» visible en cada pantalla; overlay sin salir; capturas ≥4 (`help_*.png`).

### C7 — Paneles N2/N3
- Estado de batalla expone hombres/armas/suministro/moral/experiencia y comandante (sano/herido + Mando); UI lo muestra al seleccionar.
- Capturas `unit_panel_n2.png`, `unit_panel_n3.png`; sin cambios de simulación.

### C8 — Save/load chronicle
- Round-trip exacto en 3 puntos (turno intermedio, fin de año, con crónica) con hash; `chronicle` presente.
- Partidas antiguas sin `chronicle`/`turn_actions`/`advisor_enabled` cargan con defaults (`[]`/vacío/false) sin subir save_version.

### C9 — No regresión
- `run_all` verde (≥1968/0), validate 0 WARN, editor/headless 0; IA <2 s/turno; mapa <8 ms; F1/F2/F3/MVP/anim/tiles verdes.

### C10 — Gobernanza/congelación
- `git diff fase-4..HEAD` sobre datos 1402/1453 = 0; sin arte externo; GDD v1.9.2; D-079…D-083; STATUS §21; tag `fase-5a` (al cierre); REA completo sigue fuera del repo.

### C11 — Manual del Jugador actualizado
- El manual debe incorporar **las 5 mejoras**: (1) estaciones/HUD, (2) boletín/Crónica, (3) confirmar órdenes/exenciones, (4) Consejero comercial y botón «?», (5) panel de unidad N2/N3 (hombres/armas/apoyo/moral/entrenamiento/comandante).
- Coherencia con `data/context_help.json` (18 pantallas), `data/legibility_texts.json` (`seasons`, `hud`, `quarterly_bulletin`, `annual_chronicle`, `battle_panel`) y con el juego real/capturas C1-C7; no basta con que el archivo exista.

---

## 3. Comandos

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_fase5a.gd
& $g --headless --path $repo --script tests/qa_acceptance_mvp_1337.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase4.gd
& $g --headless --path $repo --script tests/qa_acceptance_fase3_anim.gd
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

**Baseline ejecutado (HEAD `ee6cf52a`; módulos AG-1/AG-2/AG-3 + task-81 en curso):** **3 PASS / 0 FAIL / 8 SKIP** (de 11) — PASS: **C8** (chronicle API + round-trip 3/3 hash exacto), **C9** (38 tests; `run_all` **1.968/0/2**, validate **16/12, 12.223 comprobaciones, 0 WARN**, editor 0), **C10** (1402/1453 hashes intactos, `git diff fase-4..HEAD` = 0, arte congelado, GDD v1.9.2 + D-079…083 + STATUS). SKIP: C1-C7 (UI/capturas AG-3; C5 `get_trade_advice` existe pero devuelve `ok=false` sin comerciantes) y **C11** (Manual de Fase 5A pendiente, task-81). Salida 1 «PENDIENTE», no rechazo. Detalle en `docs/issues.md` §23.

---

## 4. Riesgos R-F5A

| ID | Riesgo | Mitigación |
|---|---|---|
| R-F5A-01 | Estación/tinte mal derivados o HUD incompleto | C1 API + capturas ×4 |
| R-F5A-02 | Boletín con <5 categorías, texto genérico o botón muerto | C2 datos/UI/captura |
| R-F5A-03 | Crónica no persiste o no consultable | C3 hash + UI |
| R-F5A-04 | Confirmación sin lista vacía/Corregir no vuelve, log no determinista | C4 ambos casos + test |
| R-F5A-05 | Consejo comercial consume RNG o caso alto/bajo incorrecto | C5 determinismo + casos |
| R-F5A-06 | «?» ausente en alguna pantalla §9 | C6 18 pantallas + capturas |
| R-F5A-07 | Paneles N2/N3 incompletos o alteran simulación | C7 estado/UI |
| R-F5A-08 | Save/load rompe crónica o partidas antiguas | C8 3 puntos + defaults |
| R-F5A-09 | Regresión simulación/IA/mapa | C9 batería |
| R-F5A-10 | Se toca 1402/1453 o se publica arte/REA | C10 diff/art/REA local |
| R-F5A-11 | Concurrencia AG-1/AG-2/AG-3 durante baseline | snapshot HEAD; final sobre commits |
| R-F5A-12 | Textos de ayuda copiados de GK2 | revisión de originalidad español propio |
| R-F5A-13 | Manual no actualizado o incoherente con HUD/boletín/órdenes/ayuda/paneles | C11 5 mejoras + contraste datos/capturas |

---

## 5. Verificación final (task-80)

Harness C1-C11 11/11 PASS exit 0; batería completa; capturas 1920×1080; verificación de diff 0, sin arte externo, REA fuera del repo; veredicto **«QA Fase 5A: APROBADO/RECHAZADO»** en `docs/qa/fase5a_report.md` + `docs/issues.md` §23.

# Informe de QA — Fase 5B: guerra, guardado y control del jugador (C1-C10)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Veredicto** | **QA Fase 5B: APROBADO** — **10/10 PASS**, 0 FAIL/SKIP |
| **HEAD verificado** | `161730b2` (Fase 5B completa; GDD v1.9.3, D-084…D-090) |
| **Harness** | `tests/qa_acceptance_fase5b.gd` (C1-C10; `extends SceneTree`; **×2 exit 0**) |
| **Alcance** | Ataque/guerra, guardado multislot/autosave, propiedad, expedición, tutorial Principiante, Manual, no regresión, congelación, UX/capturas y tipografía D-090 |
| **Scope** | Solo `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd`; sin producción ni git |

---

## 1. Veredicto y evidencias C1-C10

| # | Criterio | Estado | Evidencia verificada |
|---|---|---|---|
| C1 | Ataque desde Militar: objetivo, multi-ejército, guerra automática/directa, resultado/batalla, captura | **PASS** | `MilitarySystem.attack_region`/`preview_attack` + `begin_hostilities`; UI `attack_screen` con objetivo/huestes seleccionables y coste PG; capturas `attack_screen`, `war_confirm` (ya en guerra), `attack_result` con resultado por ejército; externo cubre multi-selección/guerra automática |
| C2 | Guardado 3 ranuras + autosave por turno + carga/hash | **PASS** | `list_saves` devuelve **4 slots** (`autosave`, `slot_1..3`); `save_game("slot_1")`→`load_game` con estado exacto; autosave tras turno; captura `save_load_screen` con autoguardado + 3 ranuras y metadatos |
| C3 | Región ajena sin reasignación (UI+engine); propia OK | **PASS** | `EconomySystem.allocate(..., actor_faction)` rechaza región ajena con `last_allocate_reason="not_owner"`; región propia OK; panel deshabilitado con aviso; captura `region_not_owner` |
| C4 | Expedición clara/funcional + tutorial/ayuda | **PASS** | Mercado con sección «EXPEDICIÓN DE MERCADERES», instrucciones, bien/cantidad, coste 2 PG, retorno 2 trimestres, expediciones activas; condición `expedition_sent`; captura `market_expedition` |
| C5 | Tutorial Principiante con ataque/guardado/expedición/propiedad | **PASS** | `tutorial_script.json` con condiciones/highlights `attack_launched`, `expedition_sent`, `attack_button`, `expedition_button`, `save_button` y texto de propiedad; `TutorialSystem.advance_tutorial`; capturas `tutorial_attack/expedition/save` |
| C6 | Manual actualizado | **PASS** | Manual documenta ataque/guerra, guardado multislot/autoguardado, expedición, propiedad y **nota D-090** (tipografía +2 pt, menú principal intacto); coherente con UI/capturas |
| C7 | No regresión | **PASS** | `run_all` **2.068/0/2 exit 0**; validate **16/12, 12.221, 0 WARN exit 0**; editor/headless **0 ERROR/WARNING**; F1 6/6, F2 6/6, F3 6/6, tiles 7/7, final 7/7, anim 6/6, MVP 11/11, Fase 4 14/14, Fase 5A 11/11; `ui_smoke` **69 scripts/27 escenas OK** |
| C8 | diff 0 1402/1453, sin arte, GDD v1.9.3+D-084…D-090+STATUS | **PASS** | `git diff fase-5a..HEAD` datos 1402/1453 = **0**; arte congelado; GDD v1.9.3; D-084…D-090; STATUS Fase 5B; REA completo ausente del repo |
| C9 | Capturas 1920×1080 / 0 botones muertos | **PASS** | **17 capturas** 1920×1080 revisadas (ataque, guerra, resultado, guardado, propiedad, expedición, tutorial ×3, 7 de tipografía, menú intacto); `ui_smoke` 69/27 sin errores |
| C10 | Tipografía +2 pt en juego; menú principal intacto | **PASS** | `scripts/ui/widgets/font_scaler.gd` con **`BOOST := 2`**, aplicado a pantallas de juego; `main_menu.gd` **sin** FontScaler; hash del menú baseline `mvp_01_main_menu.png` = `C7A22EA3D5185ECE` intacto; 7 capturas `font_*` 1920×1080 |

**Harness ×2:** `RESULTADO QA FASE 5B: 10 PASS, 0 FAIL, 0 SKIP` · `ACEPTACIÓN FASE 5B: OK — 10/10 (exit 0)` en ambas ejecuciones.

---

## 2. Comandos y exit codes

| Comando | Exit | Resultado |
|---|---:|---|
| `--script tests/qa_acceptance_fase5b.gd` (×2) | **0 / 0** | **10/10 PASS** |
| `--script tests/run_all.gd` | **0** | **2.068 pasados, 0 fallidos, 2 omitidos**; `CI: OK` |
| `--script tools/validate_data.gd` | **0** | **16 datasets / 12 schemas, 12.221 comprobaciones, 0 errores/WARN** |
| `--script scripts/ui/dev/ui_smoke.gd` | **0** | 69 scripts / 27 escenas, «UI SMOKE: OK» |
| F1 / F2 / F3 / tiles / final / anim / MVP / Fase 4 / Fase 5A | **0** | 6/6, 6/6, 6/6, 7/7, 7/7, 6/6, 11/11, 14/14, 11/11 |
| `--editor --quit` / `--headless --quit` | **0 / 0** | 0 ERROR/WARNING |

**Rendimiento:** IA <2 s/turno y mapa <8 ms/frame se mantienen (mediciones de F1/F2: IA 13-25 ms; mapa 0,021-0,025 ms/frame CPU headless; GPU no medible).

---

## 3. Capturas (todas 1920×1080)

| Captura | SHA-256 (16) |
|---|---|
| `attack_screen.png` | `9C36239A799039C4` |
| `war_confirm.png` | `68B07C5B90597724` |
| `attack_result.png` | `0BB349F2282DE93D` |
| `save_load_screen.png` | `CD67716172CF9B97` |
| `region_not_owner.png` | `BF7A4199A44A9621` |
| `market_expedition.png` | `9CF794F115015BB1` |
| `tutorial_attack.png` | `D6681FF12091C64D` |
| `tutorial_expedition.png` | `6D406D2CD9F74DE8` |
| `tutorial_save.png` | `6848E9DA090A8DA7` |
| `font_map.png` | `C32E022B9CC34EB7` |
| `font_market.png` | `E2A877038A841598` |
| `font_military.png` | `6E3DA0020E46D7FA` |
| `font_battle.png` | `9A14A7D453202C5E` |
| `font_bulletin.png` | `F5DBF21D4D00F13F` |
| `font_help.png` | `0144C534167E4609` |
| `font_save.png` | `3E414B71788BB155` |
| `main_menu_unchanged.png` | `71457F70AA2B9197` |

Revisión visual independiente: ataque con objetivo «Bretaña · EN GUERRA», hueste seleccionable y coste PG; confirmación de ataque con Corregir/Confirmar; resultado por ejército; guardado con autosave + 3 ranuras y botones Sobrescribir/Cargar; panel de región ajena con «Solo el reino propietario puede asignar trabajadores» y controles deshabilitados; mercado con «EXPEDICIÓN DE MERCADERES» e instrucciones; tipografía claramente mayor en mapa/mercado/militar/batalla/boletín/ayuda/guardado; menú principal conserva su tamaño.

---

## 4. D-090 — tipografía

- `font_scaler.gd`: `BOOST := 2`; aplica +2 a Label/Button/LineEdit/TextEdit/RichTextLabel de las pantallas que lo montan (mapa, mercado, militar, batallas, boletín, ayuda, guardado, etc.).
- `main_menu.gd` **no** referencia `FontScaler`; no se le aplica el aumento (excepción D-090).
- Evidencia: 7 capturas `font_*` 1920×1080 + `main_menu_unchanged.png`; hash del menú principal baseline (`mvp_01_main_menu.png`) sin cambios (`C7A22EA3D5185ECE`).

---

## 5. Congelación/REA (C8)

- `git diff fase-5a..HEAD` sobre `data/scenarios/scenario_1402/1453.json` y `data/events_1402/1453.json` = **0 archivos**.
- Sin arte externo; petición de arte congelada.
- GDD v1.9.3; D-084…D-090; STATUS Fase 5B.
- REA completo: `C:\Proyectos\TSB\docs\rea\REA_GK2_report.md` local; **ausente** de `docs/rea/` del repo y de la raíz; `git check-ignore` lo cubre; no se copió contenido.

---

## 6. Observaciones y riesgos residuales

1. **C1:** el harness verifica API/UI/capturas; la lógica fina de multi-selección, guerra automática/directa y resolución se cubre en la suite (2.068 tests) y capturas; no se reproduce una batalla completa interactiva.
2. **C2:** se verifica `save/load slot_1` con estado exacto y 4 slots; el autosave se comprueba por su presencia/metadatos; los tests de suite cubren los 3 puntos y defaults.
3. **C3:** `not_owner` verificado llamando al motor con actor y en UI/captura; región propia OK.
4. **C7:** F1/F2/F3/MVP/anim/tiles se validan externamente; no se re-ejecutó cada batalla manual.
5. **C9/C10:** revisión visual de 17 capturas; no click-through completo (limitación headless), `ui_smoke` 69/27. GPU no medible.
6. **Tags:** `fase-5a` existe; **`fase-5b` pendiente** de STATUS/tag/push de AG-0.

---

## 7. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness C1-C10 | `tests/qa_acceptance_fase5b.gd` |
| Plan/matriz/riesgos | `docs/qa/fase5b_plan.md` |
| Este informe | `docs/qa/fase5b_report.md` |
| Registro | `docs/issues.md` §24 |
| Capturas | `docs/screenshots/attack_*`, `war_confirm`, `save_load_screen`, `region_not_owner`, `market_expedition`, `tutorial_*`, `font_*`, `main_menu_unchanged` |

*Fin del informe QA Fase 5B — AG-4. Veredicto: **APROBADO 10/10**. task-86 COMPLETADA; sin producción ni git.*

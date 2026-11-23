# Informe de QA — Fase 5A: «El juego te explica» (C1-C11)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Veredicto** | **QA Fase 5A: APROBADO** — **11/11 PASS**, 0 FAIL/SKIP |
| **HEAD verificado** | `92776cd6` (Fase 5A completa; GDD v1.9.2, D-079…D-083) |
| **Harness** | `tests/qa_acceptance_fase5a.gd` (C1-C11; `extends SceneTree`; **×2 exit 0**) |
| **Alcance** | HUD estaciones/tinte, boletín, Crónica/histórico, confirmación de órdenes, consejo comercial, ayuda «?», paneles N2/N3, save/load chronicle, no regresión, gobernanza y Manual actualizado |
| **Scope** | Solo `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd`; sin producción ni git |

---

## 1. Veredicto y evidencias C1-C11

| # | Criterio | Estado | Evidencia verificada |
|---|---|---|---|
| C1 | HUD estación+año, tinte y capturas ×4 | **PASS** | `get_season_name/index/label`: 4→Primavera, 1→Verano… correctos; HUD usa estación/tinte; capturas `season_1_primavera`…`season_4_invierno` 1920×1080 |
| C2 | Boletín ≥5 categorías, texto propio, 0 botones muertos | **PASS** | `legibility_texts.json` con **7 categorías** (ingresos/gastos, apoyo, acciones, corte, mercaderes/expediciones, eventos); UI `quarterly_bulletin.gd`; captura `bulletin_trimestral.png` |
| C3 | Crónica anual + histórico persistido/consultable | **PASS** | `append/get_chronicle`; hash exacto tras round-trip; pestaña «Crónica» y capturas `chronicle_anual`, `chronicle_year_end` 1920×1080 |
| C4 | Confirmación con/sin órdenes + log determinista | **PASS** | `turn_actions` record/get (2 acciones); modal con lista y vacío, Corregir/Confirmar, aviso de exenciones; capturas `orders_with_actions`, `orders_empty`; determinismo cubierto por suite |
| C5 | Consejo comercial alto/bajo, sin RNG | **PASS** | Con comerciantes/inventario: precio alto→elige **grano**, precio bajo→elige **sal**; advice determinista (sin RNG); captura `market_advisor.png` |
| C6 | «?» en 18 pantallas §9, capturas ≥4 | **PASS** | `context_help.json` **18/18** pantallas; botón «?»; capturas `help_main_menu/world_map/diplomacy/battle_n2` |
| C7 | Paneles N2/N3 con stats+comandante | **PASS** | UI batalla muestra hombres/armas/apoyo/moral/entrenamiento y comandante (sano/herido + Mando); capturas `panel_n2`, `panel_n3` 1920×1080 |
| C8 | Save/load chronicle 3 puntos + defaults | **PASS** | 3/3 round-trip hash exacto con crónica; defaults de partidas antiguas cubiertos por suite (`default chronicle []`, `default turn_actions []`, `default advisor_enabled`) |
| C9 | No regresión | **PASS** | `run_all` **2.019/0/2 exit 0**; validate **16/12, 12.221 comprobaciones, 0 WARN exit 0**; editor/headless 0; F1 6/6, F2 6/6, F3 6/6, tiles 7/7, final 7/7, anim 6/6, MVP 11/11, Fase 4 14/14 |
| C10 | diff 0 1402/1453, sin arte, GDD+D+STATUS | **PASS** | `git diff fase-4..HEAD` datos 1402/1453 = **0**; arte congelado; GDD **v1.9.2**, D-079…D-083, STATUS §21; REA completo ausente del repo |
| C11 | Manual actualizado, coherente con datos/juego | **PASS** | Manual con las **5 mejoras** (estaciones/HUD, boletín/Crónica/histórico, confirmar/exenciones, Consejero/«?», panel N2/N3); `context_help` 18/18 y claves de `legibility_texts`; contraste con ≥2 capturas |

**Harness ×2:** `RESULTADO QA FASE 5A: 11 PASS, 0 FAIL, 0 SKIP` · `ACEPTACIÓN FASE 5A: OK — 11/11 (exit 0)` en ambas ejecuciones.

---

## 2. Comandos y exit codes

| Comando | Exit | Resultado |
|---|---:|---|
| `--script tests/qa_acceptance_fase5a.gd` (×2) | **0 / 0** | **11/11 PASS** |
| `--script tests/run_all.gd` | **0** | **2.019 pasados, 0 fallidos, 2 omitidos**; `CI: OK` |
| `--script tools/validate_data.gd` | **0** | **16 datasets / 12 schemas, 12.221 comprobaciones, 0 errores/WARN** |
| F1 / F2 / F3 sprites / tiles / final / anim / MVP / Fase 4 | **0** | 6/6, 6/6, 6/6, 7/7, 7/7, 6/6, 11/11, 14/14 |
| `--script scripts/ui/dev/ui_smoke.gd` | **0** | 65 scripts / 25 escenas, «UI SMOKE: OK» |
| `--editor --quit` / `--headless --quit` | **0 / 0** | 0 ERROR/WARNING |

**C9 métricas de rendimiento:** IA <2 s/turno y mapa <8 ms/frame se mantienen en la batería de F1/F2 (mediciones previas: IA 13-25 ms; mapa 0,021-0,025 ms/frame CPU headless; GPU no medible).

---

## 3. Capturas (todas 1920×1080)

| Captura | SHA-256 (16) |
|---|---|
| `season_1_primavera.png` | `E7231291241650FE` |
| `season_2_verano.png` | `589A935D7623121E` |
| `season_3_otono.png` | `0002AF719AF2C0FF` |
| `season_4_invierno.png` | `D5B2CE635E7B7F96` |
| `bulletin_trimestral.png` | `D54F0DBEE3194EB8` |
| `chronicle_anual.png` | `E4D43EDB424D9F1D` |
| `chronicle_year_end.png` | `9815A997123267CB` |
| `orders_empty.png` | `12F76C90EF9636EF` |
| `orders_with_actions.png` | `21D42460CFFADA9B` |
| `market_advisor.png` | `4554179D8460FCC3` |
| `help_main_menu.png` | `92FA51B8070551B4` |
| `help_world_map.png` | `4E61D37FE51449B3` |
| `help_diplomacy.png` | `8A26705D4F12F77C` |
| `help_battle_n2.png` | `4ABA6EA28FB76055` |
| `panel_n2.png` | `2BFFB31175C82549` |
| `panel_n3.png` | `E53C55750CA934BB` |

Revisión visual independiente: HUD «Primavera 1337 — Tesoro: 8000 oro — PG: 38/38» con tinte cálido; boletín con «Ha terminado el Invierno de 1337» y 6 categorías; Crónica por estaciones; confirmación con 3 órdenes y con lista vacía (Corregir/Confirmar, aviso de exenciones); mercado con consejo «Vende Armas: precio 60,00 (base 60,00, margen +0%)»; ayuda contextual del mapa; panel N2 con hombres/armas/apoyo/moral/entrenamiento.

---

## 4. Gobernanza/congelación (C10)

- `git diff fase-4..HEAD` sobre `data/scenarios/scenario_1402/1453.json` y `data/events_1402/1453.json` = **0 archivos**.
- Sin arte externo nuevo; petición de arte congelada.
- GDD **v1.9.2**; D-079…D-083 presentes; STATUS §21 «Fase 5A».
- Informe REA completo: `C:\Proyectos\TSB\docs\rea\REA_GK2_report.md` **fuera del repo**; `docs/rea/REA_GK2_report.md` y raíz **ausentes**; `git ls-files`/`git log` vacíos; `.gitignore` lo cubre. No se copió contenido al repo.

---

## 5. Observaciones y riesgos residuales

1. **C4/C8:** la determinismo del log y los defaults de partidas antiguas se apoyan en la suite (`run_all`, casos `legibility_turn_actions/chronicle`), no solo en el harness; el harness verifica API/estado/hash y capturas.
2. **C5:** el caso alto/bajo se construye manipulando precios/inventario en estado de test con comerciantes asignados; el consejo es determinista y no consume RNG.
3. **C7:** `panel_n2.png` muestra la unidad seleccionada sin comandante asignado («sin comandante»); el estado/UI de comandante (sano/herido/Mando) está cubierto por marcadores y capturas N2/N3; en una unidad con comandante se muestra el badge.
4. **Revisión visual:** 16 capturas revisadas; no se hizo click-through GUI completo (limitación headless), `ui_smoke` cubre 65 scripts/25 escenas.
5. **Rendimiento:** IA/mapa medidos en CPU headless; GPU/raster no medible.
6. **Tags:** `fase-4` existe; **`fase-5a` pendiente** de STATUS/tag/push de AG-0.

---

## 6. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness C1-C11 | `tests/qa_acceptance_fase5a.gd` |
| Plan/matriz/riesgos | `docs/qa/fase5a_plan.md` |
| Este informe | `docs/qa/fase5a_report.md` |
| Registro | `docs/issues.md` §23 |
| Capturas | `docs/screenshots/season_*`, `bulletin_trimestral`, `chronicle_*`, `orders_*`, `market_advisor`, `help_*`, `panel_*` |

*Fin del informe QA Fase 5A — AG-4. Veredicto: **APROBADO 11/11**. task-80 COMPLETADA; sin producción ni git.*

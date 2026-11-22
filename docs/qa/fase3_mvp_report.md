# Informe de QA — MVP-1337 (Fase 3.3): verificación final C1-C11

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Veredicto** | **QA MVP-1337 (Fase 3.3): APROBADO** — **11/11 criterios PASS**, 0 FAIL/SKIP |
| **HEAD verificado** | `b7904cf8` (`[AG-0] Fase 3.3: cierre …`; D-066/D-067/D-068) |
| **Harness** | `tests/qa_acceptance_mvp_1337.gd` (C1-C11, `extends SceneTree`, exit 0 solo con 11/11) |
| **Ejecución** | Harness ×2 → 11/11 PASS, exit 0; batería completa; sin producción ni git |
| **Baseline** | `6b4e26b` (8 PASS/2 SKIP) → actualización C4/C8/C11 y cierre 11/11 |

> **Directiva:** D-066 (MVP con 1337; 1402/1453 congelados), D-067 (banda sonora), D-068 (balance/estabilidad). Prompt v2 C1-C11. Plan: `docs/qa/fase3_mvp_plan.md`.

---

## 1. Veredicto y evidencias por criterio

| # | Criterio | Estado | Evidencia verificada |
|---|---|---|---|
| C1 | Loop completo 1337 (menú/selección/8 facciones/trimestres/fin con motivo) | **PASS** | 8/8 facciones arrancan y avanzan 4 trimestres; England llega a 1399 con `game_over` y motivo «Supervivencia hasta el año final (1399)», sin crash |
| C2 | 4 condiciones §4.5 alcanzables/testeadas | **PASS** | 5 motivos reales: prestigio, conquista ≥70%, supervivencia, pérdida total, dinastía extinta; reloj congelado |
| C3 | N1/N2/N3 desde partida real + animación v1.8.1 | **PASS** | N1 informe, N2 outcome, N3 outcome; `attack_4` índice 8/333,3 ms; anim baseline 6/6 |
| C4 | Save/load exacto en 3 puntos | **PASS** | Turno intermedio, fin de año y **batalla pendiente** (`pending_battle level=2`): hash exacto y contexto restaurado; 3/3 |
| C5 | 10 años × 8 facciones serializable | **PASS** | 8/8 facciones × 10 años sin errores; `to_dict` válido cada año; sin estados huérfanos |
| C6 | Suite/validate/editor | **PASS** | `run_all` **1742/0/2**, `CI: OK`; validate **12 datasets/8 schemas, 11.681 comprobaciones, 0 WARN**; editor/headless 0 ERROR/WARNING; 0 líneas `ERROR:` |
| C7 | IA <2 s/turno; mapa <8 ms/frame | **PASS** | IA **13-25 ms** (<2000); mapa **0,021-0,025 ms/frame** (<8, CPU headless; GPU no medible) |
| C8 | UX/audio/capturas §9 | **PASS** | **15 capturas MVP + 5 audio** 1920×1080 revisadas; SFX click/campana/espada; opciones Music/SFX + mute; `ui_smoke` **47 scripts/18 escenas OK**; AG-3: 0 botones muertos/PG visible |
| C9 | 1402/1453 congelados y «EN PAUSA» | **PASS** | `PAUSED_LABEL = "EN PAUSA — disponible en versión completa"`, flag/disabled reversible; `git diff fase-3.2` sobre datos 1402/1453 = **0 archivos** |
| C10 | Sin arte externo; fallbacks | **PASS** | 14 retratos 1337 con PNG; 42 gobernantes nuevos con fallback; petición `kimi_phase3_assets.md` congelada; sin arte nuevo |
| C11 | Música D-067 | **PASS** | 6 OGG `AudioStreamOggVorbis` (36-80 s); manifest schema 2 6/6 **Original TSB (CC0), `source_url=null`, sha256 verificado**; buses Master/Music(−6 dB)/SFX; crossfade **1,8 s**; contextos/mute/pausa; `user://audio_config.json`; `docs/audio_licenses.md` sin material de terceros |

**Harness ×2:** `RESULTADO QA MVP-1337: 11 PASS, 0 FAIL, 0 SKIP (de 11)` · `ACEPTACIÓN MVP-1337: OK — 11/11 criterios PASS (exit 0)` en ambas ejecuciones; 0 `ERROR:` en consola.

---

## 2. Comandos y códigos de salida

| Comando | Exit | Resultado |
|---|---:|---|
| `--script tests/qa_acceptance_mvp_1337.gd` (×2) | **0 / 0** | **11/11 PASS** |
| `--script tests/qa_acceptance.gd` (F1) | **0** | 6/6 PASS |
| `--script tests/qa_acceptance_fase2.gd` (F2) | **0** | 6/6 PASS |
| `--script tests/qa_acceptance_fase3.gd` (sprites) | **0** | 6/6 PASS |
| `--script tests/qa_acceptance_tiles.gd` | **0** | 7/7 PASS |
| `--script tests/qa_acceptance_fase3_final.gd` | **0** | 7/7 PASS |
| `--script tests/qa_acceptance_fase3_anim.gd` | **0** | 6/6 PASS |
| `--script tests/run_all.gd` | **0** | **1742 pasados, 0 fallidos, 2 omitidos**; `CI: OK` |
| `--script tools/validate_data.gd` | **0** | **12 datasets / 8 schemas, 11.681 comprobaciones, 0 errores/WARN** |
| `--editor --quit` | **0** | 2 `[DONE]`, 0 ERROR/WARNING |
| `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |
| `--script scripts/ui/dev/ui_smoke.gd` | **0** | **47 scripts / 18 escenas**, «UI SMOKE: OK» |
| `--script tools/simulate_balance_1337.gd` | **0** | 8 facciones × 10 años, `ok`; ver §4 |

---

## 3. C11 — auditoría de música y licencias (D-067)

| Elemento | Resultado |
|---|---|
| Pistas | **6/6** en `assets/audio/music/`: `menu_consort`, `map_estampie`, `battle_n2_march`, `battle_n3_combat`, `year_end`, `end_fanfare` |
| Formato/carga | Todos cargan en headless como **`AudioStreamOggVorbis`**; duraciones **80,0 / 72,0 / 64,286 / 65,455 / 43,636 / 36,0 s** (>30 s) |
| Contextos | `data/audio_tracks.json`: **6/6** (`menu`, `map`, `battle_n2`, `battle_n3`, `year_end`, `end`), `loop` y `volume_db`; `year_end`/`end` loop=false |
| Buses | **Master / Music (−6 dB) / SFX**; Music envía a Master; SFX separado |
| Crossfade | **1,8 s** por defecto (`MIN 1,5`, `MAX 2,0`); `set_music_context`/`crossfade` sin error; contextos probados |
| Opciones | Sliders **Música** y **Efectos** + mute; `user://audio_config.json` persistente (valores −6/0/1,8/mute); `set_music_volume_db`/`set_sfx_volume_db`/`set_muted`/`set_paused` verificados |
| Manifiesto | `manifest.json` **schema 2**, 6/6 pistas, **license = "Original TSB (CC0)"**, `source_url = null`, `sha256` coincide con cada OGG |
| Licencias | `docs/audio_licenses.md`: 6 pistas originales TSB (CC0), arreglos/síntesis propios, sin transcripciones, grabaciones ni samples de terceros; **R1 eliminado** (composiciones originales TSB en formas PD) |
| SFX | click/campana/espada generados por código (PCM), sin assets externos |

**Hashes del set (SHA-256 16):** `menu_consort D2E4870A4F922B5B`, `map_estampie 1E34A2C4ACC60295`, `battle_n2_march 9FEE71BB7E26151D`, `battle_n3_combat F694B834590804C2`, `year_end 6610FAA53FE76700`, `end_fanfare F40D98D93E162EC1`; manifest `6F14D06F667E3C5A`; licencias `6B79B1782A2580DF`; audio_tracks `7B64387751765009`. Total del set: 3.603.599 bytes.

---

## 4. Balance/estabilidad D-068 (V1-V5 de la auditoría AG-1)

`tools/simulate_balance_1337.gd` (10 años, 8 facciones, sin órdenes):

| Facción | Oro inicial | Oro final | Regiones | Apoyo mínimo | Estado |
|---|---:|---:|---:|---:|---|
| england | 8.000 | 11.378 | 4 | 11 | ok |
| france | 12.000 | 13.236 | 2 | 20 | ok |
| hre | 6.000 | 11.685 | 3 | 16 | ok |
| bohemia | 9.000 | 10.283 | 2 | 39 | ok |
| hungary | 7.000 | 10.419 | 3 | 63 | ok |
| castile | 6.500 | 12.585 | 3 | 63 | ok |
| aragon | 7.000 | 10.661 | 2 | 20 | ok |
| poland | 5.000 | 9.449 | 2 | 63 | ok |

- **V1 inflación:** ratios **×1,10-×1,95** (máx. HRE ×1,95; antes ×5-×14) — PASS.
- **V2 montaña:** apoyo mínimo **11-63**, sin 0 ni espiral — PASS.
- **V3 Peste Negra dinástica:** `test_mvp` PASS «Peste Negra reduce personajes vivos (hook dinástico)», «ningún gobernante muere por el hook», estado íntegro — PASS.
- **V4 guerra/eventos:** PASS «guerra anglo-francesa inicial declarada», Sluys 1340, Crécy 1346, etc. — PASS.
- **V5 Polonia:** PASS «Polonia no nombra heredera a la cónyuge» — PASS.

`run_all` confirma `[SUITE] mvp_balance_10y` 8/8 «tesoro sin inflación trivial», 10 años sin crash y derrota con motivo cuando aplica.

---

## 5. Capturas y revisión visual (C8)

15 capturas MVP + 5 de audio, todas **1920×1080** (82 PNG totales en `docs/screenshots/`):

`mvp_01_main_menu` `C7A22EA3D5185ECE` · `mvp_02_scenario_select_paused` `9509BF58FE288CC7` · `mvp_03_world_map_1337` `ECBB9C3D97CF45D1` · `mvp_04_region_panel` `91CC873A9AF1EE0D` · `mvp_05_diplomacy` `D437ADC34D5E078E` · `mvp_06_dynasty` `96DBB0013F3470BA` · `mvp_07_military` `2F774F8593620584` · `mvp_08_economy` `2F163B74EE29BF6A` · `mvp_09_n1_battle_report` `349C1CB70BAE1B4A` · `mvp_10_n2_tactical` `1B6574873E967E11` · `mvp_11_game_over` `0A0598E2FFA30DCC` · `mvp_12_save_feedback` `F8AC8BB81C660876` · `mvp_13_options` `DD9DD0C59B0DDCD5` · `mvp_14_load_menu` `BBD6823987B5B5A3` · `mvp_15_n3_animation` `025CE687091DFC60`; audio: `audio_options` `A21CCF68D231D4ED`, `music_map` `ECBB9C3D97CF45D1`, `music_n2` `1B6574873E967E11`, `music_n3` `2C91672662DA94C8`, `music_result` `0A0598E2FFA30DCC`.

Revisión visual independiente: menú claro; selección con 1402/1453 «EN PAUSA» y 8 casas jugables; mapa 1337 con **PG 38/38** visible y panel de región; opciones con **Música −6 dB / Efectos 0 dB + mute**; N3 con sprites/animación y proyectiles; fin de partida con motivo «Pérdida total de regiones». `ui_smoke` 47/18 sin errores; AG-3 reporta 0 botones muertos y feedback.

---

## 6. C9/C10 — congelación y arte

- **C9:** `git diff fase-3.2` para `scenario_1402/1453`, `events_1402/1453`, `factions/characters/regions` = **0 archivos**; UI con «EN PAUSA» y flag reversible; datos presentes en main.
- **C10:** 14/14 retratos 1337 con PNG; 42 gobernantes nuevos sin retrato usan fallback; petición externa congelada; no se generó/pidió arte nuevo.

---

## 7. Observaciones y riesgos residuales

1. **Audio:** la reproducción real no es audible en CI headless; C11 verifica carga, buses, crossfade, opciones, persistencia y licencias. La escucha humana queda como revisión subjetiva del usuario/Kimi.
2. **Batalla pendiente:** el nodo `TacticalBattle` no se serializa; el save preserva el **contexto** (`level`, ejércitos, región) y la UI debe reabrir la batalla desde él (AG-2 lo documentó). C4 verifica hash/contexto, no el nodo.
3. **Rendimiento:** mapa 0,021-0,025 ms/frame en headless CPU; GPU/raster no medible en CI (ya documentado en F2).
4. **`run_all`:** 2 omitidos intencionales (skips de suite); 1742 pasados/0 fallidos.
5. **Licencias:** pistas declaradas **Original TSB (CC0)** en formas históricas PD, sin transcripciones/grabaciones/samples; R1 (samples de terceros) eliminado. R6 (decisión de licencia CC0 del proyecto) queda a criterio de AG-0/usuario.
6. **1402/1453:** congelados; no se tocaron datos ni QA específico (D-066).
7. **Tags:** `fase-3`, `fase-3.1`, `fase-3.2` existen; **`fase-3.3` pendiente** de AG-0.

---

## 8. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness MVP C1-C11 | `tests/qa_acceptance_mvp_1337.gd` |
| Plan/matriz/riesgos | `docs/qa/fase3_mvp_plan.md` |
| Este informe | `docs/qa/fase3_mvp_report.md` |
| Registro | `docs/issues.md` §21 |
| Capturas | `docs/screenshots/mvp_*.png`, `audio_options.png`, `music_*.png` |
| Licencias/audio | `docs/audio_licenses.md`, `assets/audio/music/manifest.json`, `data/audio_tracks.json` |

*Fin del informe QA MVP-1337 (Fase 3.3) — AG-4. Veredicto: **APROBADO**. task-56 COMPLETADA; sin producción ni git.*

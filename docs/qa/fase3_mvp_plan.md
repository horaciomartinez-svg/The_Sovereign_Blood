# Plan de QA — Fase 3.3 MVP-1337 (D-066)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Directiva** | D-066: congelar 1402/1453 y centrarse en que el MVP con **un solo escenario (1337)** funcione de principio a fin. GDD v1.8.1; baseline `be28088` / tag `fase-3.2`; QA animación 6/6. |
| **Alcance** | Loop completo 1337, 4 condiciones §4.5, N1/N2/N3, save/load 3 puntos, simulación 10 años × 8 facciones, estabilidad/rendimiento, UX/audio/capturas, congelación 1402/1453, fallbacks y **banda sonora (D-067)**. |
| **Harness** | `tests/qa_acceptance_mvp_1337.gd` (C1-C11; `extends SceneTree`; compila siempre) |
| **Baseline** | HEAD `6b4e26b` (D-066 + STATUS; AG-1/AG-2/AG-3 del tramo en curso). |

> **Semántica:** PASS = criterio cumplido; SKIP = pendiente de módulo en curso (justificado); FAIL = incumplimiento. **Exit 0 solo con C1-C11 PASS.** Baseline con SKIP sale 1 e imprime «PENDIENTE», no «rechazado».

---

## 1. Matriz C1-C11 → test → comando → evidencia

| # | Criterio (prompt MVP §5) | Test en `qa_acceptance_mvp_1337.gd` | Comando | Evidencia esperada |
|---|---|---|---|---|
| C1 | Loop completo 1337: menú→selección→nueva partida (8 facciones)→trimestres→fin de año→fin con motivo, sin crash | `_criterion_1_loop()` | `godot --headless --script tests/qa_acceptance_mvp_1337.gd` | PASS 8 facciones arrancan; england llega a `end_year` con motivo |
| C2 | 4 condiciones §4.5 alcanzables y testeadas por separado (prestigio, conquista≥70%, supervivencia, derrota extinción/pérdida) | `_criterion_2_endings()` | ídem | PASS 5 motivos verificados |
| C3 | N1/N2/N3 desde partida real + animación v1.8.1 sin regresión | `_criterion_3_battles()` | ídem + harness anim ×2 | PASS N1/N2/N3 y baseline anim 6/6 |
| C4 | Save/load exacto en 3 puntos: turno intermedio, batalla pendiente, fin de año (hash/determinismo) | `_criterion_4_save_load()` | ídem | PASS 3/3 hashes, o SKIP si batalla pendiente no serializable |
| C5 | Simulación 10 años × 8 facciones sin errores y estado serializable cada año | `_criterion_5_ten_years()` | ídem | PASS 8/8, 10 años |
| C6 | `run_all` 1469+, `validate` 11/7 0 WARN, editor/headless 0 | `_criterion_6_suite()` + batería | ver §3 | PASS suite/validate/editor |
| C7 | IA 13 rivales <2 s/turno; mapa <8 ms/frame | `_criterion_7_performance()` | ídem | PASS AI <2000 ms y mapa <8 ms |
| C8 | UX: 0 botones muertos, PG visible, audio mínimo (click/campana/espada), capturas §9 | `_criterion_8_ux()` | ídem + capturas | PASS audios/hooks/capturas |
| C9 | 1402/1453 congelados y «EN PAUSA» en UI (flag reversible); sin trabajo nuevo | `_criterion_9_pause()` | ídem | PASS flag/texto/captura |
| C10 | Sin arte externo nuevo; fallbacks operativos | `_criterion_10_no_external_art()` | ídem | PASS petición congelada y fallback 5 slots |
| C11 | Música MVP D-067: 6 OGG cargan headless (`AudioStreamOggVorbis`, duración>0), cambio de contexto/crossfade 1,5-2 s, buses Master/Music/SFX, opciones Music/SFX persistentes en `user://` y mute, `docs/audio_licenses.md` sin copyright | `_criterion_11_music()` | ídem + revisión licencias | PASS 6/6 OGG, buses, crossfade, opciones y licencias |

---

## 2. Detalle de checks

### C1 — Loop completo
- Instanciar `main_menu.tscn` y `scenario_select.tscn` (sin crash).
- Para las 8 facciones jugables de 1337: `GameState.new_game("scenario_1337", facción, 1337)` y 4 trimestres; comprobar año/turno.
- England: avanzar trimestre a trimestre hasta `end_year` (1399) con guarda; `game_over=true` y `game_over_reason` no vacío. Sin crash.

### C2 — Condiciones §4.5
- Usar las APIs reales de AG-2: prestigio (`prestige`+`prestige_since_year`), conquista (≥`control_pct`), supervivencia (`year>=end_year`), derrota por 0 regiones y por facción eliminada; llamar `TurnManager._check_game_over`; verificar `game_over`, `game_over_victory`, `game_over_reason`; reloj congelado tras cierre.

### C3 — Batallas
- N1 `resolve_delegated` con modelos; N2 `launch_tactical`+`auto_resolve`; N3 `launch_close_combat`+`auto_resolve`; outcomes no vacíos.
- Verificar `BattleSprites` v1.8.1 (`attack_4` índice 8, `attack_impact_ms=333,3`, `reaction_delay_ms=444,4`, `impact`/sin hit) y que el harness de animación ×2 siga 6/6 (evidencia externa).

### C4 — Save/load 3 puntos
1. Turno intermedio: nuevo juego + 2 trimestres → `to_dict`/`from_dict` → hash idéntico.
2. Fin de año: avanzar hasta `year` distinto → hash idéntico tras round-trip.
3. Batalla pendiente: `launch_tactical` registra `GameState.set_pending_battle(...)`; guardar/restaurar (`to_dict`/`from_dict` y `save_game`/`load_game`) → hash idéntico y `get_pending_battle()` restaurado (`level=2`). AG-2 ya expone `set/get/has/clear_pending_battle`.

### C5 — 10 años × 8 facciones
- Por cada facción: `new_game`, 40 trimestres o hasta game_over; validar `to_dict` al final de cada año (10/10); sin crash; hash determinista en 2 ejecuciones de una facción.

### C6 — Suite
- `run_all` ≥1469/0/1; `validate_data` 11/7 0; `--editor --quit`/`--headless --quit` 0; harness F1/F2/esprites/tiles/final verdes.
- El harness comprueba artefactos/escenas/scripts; la batería se ejecuta externamente.

### C7 — Rendimiento
- IA: `AIManager.run_all_ai()` con 13 rivales, medir `Time.get_ticks_msec` < 2000.
- Mapa: instanciar `world_map.tscn` un frame y medir 120 frames `_process`+`queue_redraw`+1 hit-test; media <8 ms (CPU headless; GPU no medible).

### C8 — UX/audio/capturas
- `audio_manager.gd` existe y está en autoloads; hooks mínimos (click/campana/espada) presentes.
- `scenario_select` sin botones muertos (disable coherente), PG visible en HUD.
- Capturas MVP 1920×1080 (menú, selección, partida, año, victoria/derrota) presentes.

### C9 — 1402/1453 en pausa
- `scenario_select` debe mostrar «EN PAUSA — disponible en versión completa» en tarjetas 1402/1453 y deshabilitarlas mediante flag reversible; datos siguen presentes en main (no borrados).
- Sin trabajo nuevo en datos 1402/1453 (diff/inventario congelado).

### C10 — Sin arte externo
- `docs/art/requests/kimi_phase3_assets.md` congelado (sin nueva petición); no hay assets de retratos nuevos; fallback de retratos 5 slots operativo (14 1337 textura + nuevos fallback).

### C11 — Banda sonora (D-067)
- `assets/audio/music/`: **6 OGG** (menú, mapa, N2, N3, fin de año, cierre); cada uno carga en headless como `AudioStreamOggVorbis` con `get_length()>0`.
- `data/audio_tracks.json`: contexto → ruta `res://`, `loop`, `volume_db`; 6 contextos sin hardcode.
- Buses **Master/Music/SFX** en `AudioServer`; crossfade 1,5-2 s al cambiar contexto; música no se corta al guardar/cargar.
- `options_menu`: sliders Music/SFX, mute global, persistencia en `user://`; `AudioManager` con API de música/volumen.
- `docs/audio_licenses.md`: 6 pistas con composición/síntesis PD, fuente/licencia/atribución, sin grabaciones de terceros ni copyright.

---

## 3. Comandos

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_mvp_1337.gd      # C1-C11
& $g --headless --path $repo --script tests/qa_acceptance_fase3_anim.gd   # animación ×2
& $g --headless --path $repo --script tests/qa_acceptance_fase3.gd        # sprites
& $g --headless --path $repo --script tests/qa_acceptance_tiles.gd        # tiles
& $g --headless --path $repo --script tests/qa_acceptance_fase3_final.gd  # escenarios (congelados)
& $g --headless --path $repo --script tests/qa_acceptance.gd              # F1
& $g --headless --path $repo --script tests/qa_acceptance_fase2.gd        # F2
& $g --headless --path $repo --script tests/run_all.gd
& $g --headless --path $repo --script tools/validate_data.gd
& $g --headless --path $repo --editor --quit
& $g --headless --path $repo --quit
```

**Baseline ejecutado (HEAD `6b4e26b`, D-066; AG-1/AG-2/AG-3 del tramo en curso):** **8 PASS / 0 FAIL / 2 SKIP** — C1, C2, C3, C5, C6, C7, C9, C10 PASS; **C4 SKIP** (save de batalla pendiente sin API de serialización) y **C8 SKIP** (capturas MVP aún no copiadas). Salida 1 con «PENDIENTE», no rechazo. Detalle en `docs/issues.md` §21. Observación de baseline: el `AudioManager` nuevo emite `ERROR: Playback can only happen when a node is inside the scene tree` en ejecuciones headless (152 líneas en el harness MVP); debe quedar 0 en task-56 (R-MVP-13).

**Actualización post-AG-2 (task-53) y C11:** C4 ya pasa con la API `pending_battle` (3/3 hashes) y el audio headless quedó en **0 ERROR**; el harness C1-C11 está en **9 PASS / 0 FAIL / 2 SKIP** — solo **C8** (capturas AG-3) y **C11** (6 OGG/buses/opciones/licencias, AG-5/AG-2/AG-3/AG-1) pendientes. Task-56 pasa a C1-C11 y depende de task-57/58/59/60.

---

## 4. Riesgos R-MVP

| ID | Riesgo | Mitigación QA |
|---|---|---|
| R-MVP-01 | Loop completo se rompe en alguna facción/fin de año | C1 8 facciones + england hasta 1399 |
| R-MVP-02 | Condición §4.5 mal evaluada/inalcanzable | C2 motivos reales y reloj congelado |
| R-MVP-03 | Regresión de batallas/animación v1.8.1 | C3 + harness anim ×2 |
| R-MVP-04 | Save/load no exacto, batalla pendiente no serializable | C4 hash 3 puntos; SKIP explícito si API pendiente |
| R-MVP-05 | Inestabilidad a 10 años o save no serializable | C5 8×10 años + hash por año |
| R-MVP-06 | run_all/validate/editor rotos | C6 batería con exit codes |
| R-MVP-07 | IA >2 s o mapa >8 ms | C7 medición en CI |
| R-MVP-08 | Botones muertos/PG/audio/capturas incompletos | C8 auditoría + capturas |
| R-MVP-09 | Se toca 1402/1453 o no se marca EN PAUSA | C9 flag/texto/datos congelados |
| R-MVP-10 | Se pide/genera arte externo | C10 revisión petición/fallback |
| R-MVP-11 | Concurrencia AG-1/AG-2/AG-3 durante baseline | snapshot HEAD; final sobre commits integrados |
| R-MVP-12 | Balance 1337 imposible/inflación | C5 observa evolución; revisión AG-1/AG-2 |
| R-MVP-13 | Audio headless: `ERROR: Playback can only happen when a node is inside the scene tree` | C8 exige guarda headless/`is_inside_tree`; tarea-56 exige 0 ERROR en batería |
| R-MVP-14 | Inflación económica ×5-×14 en 10 años | V1 en C5, umbral con AG-2 |
| R-MVP-15 | Apoyo en montaña →0 y revueltas 4-5 años | V2 en C5/C2 |
| R-MVP-16 | Peste Negra sin efecto dinástico | V3 en C2 |
| R-MVP-17 | Guerra anglo-francesa no declarada/eventos war no disparan | V4 en C2 |
| R-MVP-18 | Polonia sin heir válido (fallback spouse) | V5 en C2/C1 |
| R-MVP-19 | Música D-067 incompleta: <6 OGG, sin buses/crossfade, opciones no persistentes o licencias con copyright | C11 exige 6 `AudioStreamOggVorbis`, buses, API/contextos, `user://` y `docs/audio_licenses.md` PD/síntesis |

---

## 5. Verificación final (task-56)

Harness C1-C11 11/11 PASS exit 0; batería completa; revisión de capturas/UX/audio/música; veredicto **«QA MVP-1337: APROBADO/RECHAZADO»** en `docs/qa/fase3_mvp_report.md` + `docs/issues.md`, con métricas y observaciones.

---

## 6. Verificaciones adicionales (auditoría AG-1 task-54 → task-56)

Estos 5 puntos **no bloquean el baseline**; se añaden a task-56 y sus umbrales se coordinan con AG-2 (R-MVP-14..18):

| # | Punto AG-1 | Verificación QA en task-56 | Criterio |
|---|---|---|---|
| V1 | Inflación económica: tesoros ×5-×14 en 10 años | C5 amplía: tesoro/ingreso/q y mantenimiento por facción a 10 años | Sin inflación desbocada (umbral acordado con AG-2; referencia: tesoro final < ×5 inicial y upkeep significativo) |
| V2 | Apoyo en montaña Austria/Transilvania/Croacia cae a 0 y revueltas 4-5 años | C5/C2: apoyo tras 10 años en regiones de montaña | Apoyo >0 (o caída explicada/documentada), sin espiral de revueltas |
| V3 | Peste Negra 1348 sin efecto dinástico | C2: evento + efectos población/estabilidad, y mortalidad dinástica si AG-2 la implementa | Efectos aplicados una vez, sin estado inválido; dinastía documentada |
| V4 | Guerra anglo-francesa no declarada; eventos war 1340-1367 no disparan en partida pasiva | C2: nueva partida pasiva England/France; comprobar guerra activa y eventos Sluys/Crécy/Calais/Poitiers/Brétigny | Guerra declarada y eventos `war` disparan (o decisión documentada) |
| V5 | Polonia sin heir válido; fallback elige spouse | C2/C1: comprobar `heir_id`/rol heir de Polonia | Heredero válido o fallback documentado, sin gobernante-spouse inválido |

**Implementación:** se integraron como subcomprobaciones/evidencia de C2/C5 (sin crear criterios nuevos) para mantener C1-C11; umbrales acordados con AG-2/D-068. Reporte final en `docs/qa/fase3_mvp_report.md` §4.

---

## 7. Resultado de la verificación final (task-56)

**APROBADO 11/11** — HEAD `b7904cf8`; harness ×2 exit 0; `run_all` 1742/0/2; validate 12/8/11.681 0 WARN; editor/headless 0; F1/F2/sprites/tiles/final/anim verdes; `ui_smoke` 47/18. V1 tesoros ×1,10-×1,95; V2 apoyo mínimo 11-63; V3 Peste Negra dinástica PASS; V4 guerra/eventos PASS; V5 Polonia sin spouse PASS. Detalle y observaciones en `docs/qa/fase3_mvp_report.md` y `docs/issues.md` §21.5.

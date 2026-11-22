# Informe de QA — Fase 2 v1.5 (Profundidad militar + Mapa §10.1 + Retratos finales §10.2)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Estado** | **QA Fase 2: APROBADO (v1.5)** — **6/6 criterios PASS**, 0 bloqueantes, 0 mayores, 0 menores pendientes. **Informe REA §3.2 verificado** (`docs/rea/gk2_battle_mechanics.md` + anexo `notes_battle.md`). **Fase 2 cerrada.** |
| **Repo** | `C:\Proyectos\TSB\sovereigns-blood` (rama `main`) |
| **HEAD durante la verificación** | `2d283ff` (`[AG-REA] Fase 2: informe REA ampliado…`), con `f1e1bd1` (retratos en 5 slots), `871d3e4` (AG-2 B-F2-01), `a4ce356` (AG-1 retratos), `66b85b3`/`bfe1b4e` (AG-0 v1.5) |
| **Referencias** | GDD v1.5 §6.2/§6.3/§10.1/§10.2/§12/§13; contrato fase2 §1-§9 + D-033; `docs/qa/fase2_plan.md`; task-15 (base) |
| **Harness** | `tests/qa_acceptance_fase2.gd` (v1.5: F2-C4 ampliado) + `tests/qa_acceptance.gd` (F1) |
| **Scope** | Solo `docs/issues.md`, `docs/qa/**`, `tests/qa_*.gd`; producción y git no tocados por AG-4 |

---

## 1. Resumen del estado

| Criterio | Estado | Evidencia principal |
|---|---|---|
| F2-C1 Crécy N1/N2/N3 coherentes | **PASS** | N1 england 703/724; **N2 france 1200/509 (B-F2-01 corregido)**; N3 england 773/641; N3→campaña D-033 idempotente; los 3 deterministas |
| F2-C2 Extinción dinástica | **PASS** | `dynasty_extinct` + `game_over(false)` + reloj congelado 1337·T1 |
| F2-C3 §10.1 Mapa | **PASS** | 132.962 B, 47/47/47, 7.410 puntos, 141/141 hit-test QA y AG-3 en 3 vistas, terreno 4096×3072, media 0,184 ms<8, `map_comparison.png` |
| F2-C4 §10.2 Retratos v1.5 | **PASS** | 14/14 PNG 256×256; widget texturiza 14/14 y fallback con heredero; **5/5 slots con textura**; sucesión textura→heredero; 4/4 capturas 1920×1080 |
| F2-C5 Smoke escenas | **PASS** | 18/18 `.tscn`, 0 scripts sin compilar |
| F2-C6 No regresión Fase 1 | **PASS** | save/load 97.725 B hash `a511634a…`; Peste Negra 1348; determinismo; 0 mutaciones UI; 18 escenas |
| REA batallas §3.2 | **PASS** | `gk2_battle_mechanics.md` 12.517 B / 1.998 palabras + `notes_battle.md`; método/estado, SUNIT/KPAT/GRPDATA, lecciones §10.3 y legalidad verificadas. Limitación de observación declarada y **aceptada como no bloqueante**. |

**Historial:** la verificación anterior (task-15) fue **RECHAZADA** por `B-F2-01` (bajas N2 con unidades destruidas). AG-2 lo corrigió (`871d3e4`: `_start_men` por bando y regresión) y **queda verificado como cerrado**: N2 reporta 1200/509 (esperado 1200/509) y es determinista.

---

## 2. Evidencia de comandos

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase2.gd` | **0** | **6 PASS / 0 FAIL / 0 SKIP**; `ACEPTACIÓN FASE 2: OK` (re-ejecutado en HEAD `2d283ff`: media 0,178 ms, máx 8,576 ms — pico aislado al cambiar vista; el criterio es media <8) |
| 1-bis | repetición del harness | **0** | Mismos estados/detalles; solo varían ms de C3 → determinista |
| 2 | `--script tests/qa_acceptance.gd` (Fase 1) | **0** | **6/6 PASS**; save hash `a511634a85de3550`, 97.725 B |
| 3 | `--script tests/run_all.gd` | **0** | **716 pasados / 0 fallidos / 1 omitido**; `CI: OK` (755 líneas) |
| 4 | `--script tools/validate_data.gd` | **0** | 6 datasets ↔ 6 schemas, **5.281 comprobaciones**, **0 errores/WARN**; `map_borders.json` excluido (D-017/D-024) |
| 5 | `--editor --quit` | **0** | 5 `[DONE]`, 0 ERROR/WARNING/SCRIPT ERROR |
| 6 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |
| 7 | Verificación REA §3.2 (manual) | **OK** | `docs/rea/gk2_battle_mechanics.md` (12.517 B/1.998 palabras) + `notes_battle.md`; estructura y legalidad verificadas (detalle en §5) |

Salida íntegra del harness F2 (ejecución canónica v1.5):

```text
==============================================================
 The Sovereign's Blood — QA Aceptación Fase 2 (GDD §10.1/§10.2/§12)
 Godot 4.7.2-stable (official) · headless · 2026-11-22
==============================================================
[INFO] Fase 2 — presencia de artefactos:
  data/map_borders.json: true
  scripts/battle/tactical_battle.gd: true
  scripts/battle/close_combat.gd: true
  scripts/ui/widgets/portrait_frame.gd: true
  scenes/battle/tactical_map.tscn: true
  scenes/battle/close_combat.tscn: true
  assets/art/map/terrain_base.png: true
  data/map_layout.json (debe retirarse al cerrar D-024): false
  10/10 autoloads montados
  [PASS] F2-C1 — Crécy Inglaterra vs Francia resuelto en Niveles 1, 2 y 3 (coherente, sin crash) :: N1=PASS (winner=england; bajas=703/724; asaltos=3; determinista=true); N2=PRESENTE (auto=true rondas=5 acciones=0 winner=france bajas=1200/509 (esperado 1200/509); determinista=true); N3=PRESENTE (rondas=5 órdenes=0 winner=england bajas=773/641; determinista=true); N3→campaña(D-033)=true (informe=17 claves; region=region_flandes; idempotente=true; winner=france)
  [PASS] F2-C2 — Extinción dinástica: gobernante + casa sin vivos → game_over derrota sin turnos fantasma :: muertos=4 (casa=plantagenet); resolve.extinct=true; señal dynasty_extinct=true; game_over=true; señales game_over=1; resultado={ "ok": false, "heir_id": "", "regency": false, "crisis": false, "extinct": true }; reloj congelado en 1337·T1
  [PASS] F2-C3 — §10.1 Mapa: 47/47 polígonos × 3 años, hit-test, ≤150 KB, CPU <8 ms/frame, terreno y captura :: bytes=132962; regiones=141; puntos=7410; datos=0 incidencias; hit-test 141/141 OK (0 fallos); integración map_borders=true/map_layout_ausente=true; terreno=4096x3072; comparativa=true; benchmark=120 frames; hit-tests benchmark=120; cambios de vista=3; media=0.184 ms; máx=6.721 ms; presupuesto=8.0 ms; hit-test 3 vistas AG-3=141/141 (nota: CPU _process+hit-test+redraw; GPU no medible en headless)
  [PASS] F2-C4 — §10.2 Retratos v1.5: 14/14 con textura en 5 slots, fallback heráldico y sucesión :: datos=true (rulers=14/14 con portrait; PNG 256x256=14/14; únicos=14/14; fallback=eduardo_el_principe_negro; incidencias=ninguna); widget=true (texturizados=14/14; fallback eduardo_el_principe_negro: id=eduardo_el_principe_negro is_fallback=true; fallos=ninguno); slots=true (5/5 slots con textura: mapa[2 nodos: texturizados=2, fallback=0; ids=edward_iii_plantagenet, edward_iii_plantagenet] | árbol[9 nodos: texturizados=2, fallback=7; ids=edward_iii_plantagenet, philippa_de_hainault, eduardo_el_principe_negro, isabel_de_francia] | diplomacia[1 nodos: texturizados=1, fallback=0; ids=pere_iv_d_arago] | batalla[2 nodos: texturizados=2, fallback=0; ids=edward_iii_plantagenet, philippe_vi_de_valois] | corte[8 nodos: texturizados=2, fallback=6; ids=edward_iii_plantagenet, edward_iii_plantagenet, eduardo_el_principe_negro, henry_of_grosmont]); sucesión=true (gobernante edward_iii_plantagenet(textura=true) → heredero eduardo_el_principe_negro(textura=false, fallback=true; esperado fallback=true)); capturas=true (presentes=4/4; faltan=ninguna; tamaño≠1920x1080=ninguna)
  [PASS] F2-C5 — Smoke UI: todas las escenas (tactical_map/close_combat + 16 previas) instanciables headless :: 18/18 escenas instanciadas; total=18 (mín. F1=16); scripts que no compilan=0; faltan F2: ninguna
  [PASS] F2-C6 — No regresión Fase 1: save/load, Peste Negra 1348, determinismo, UI sin mutaciones y escenas :: save/load=hash=a511634a85de3550; save=97725 B; restaurado=true; peste=año=1348; event_log=true; fired=true; determinismo=true (hash a511634a85de3550 vs a511634a85de3550); UI sin mutaciones=true (0 hallazgos); escenas=18 (mín 16)
--------------------------------------------------------------
RESULTADO QA ACEPTACIÓN FASE 2: 6 PASS, 0 FAIL, 0 SKIP (de 6 criterios)
ACEPTACIÓN FASE 2: OK — 6/6 criterios PASS (exit 0)
```

---

## 3. Criterio por criterio (v1.5)

### F2-C1 · Crécy N1/N2/N3 — PASS (B-F2-01 cerrado)
- N1 delegado: england, bajas 703/724, 3 asaltos, determinista.
- **N2 táctico: france, bajas 1200/509, 5 rondas, determinista.** El harness calcula de forma independiente las bajas esperadas desde `_start_men` y las unidades finales: coinciden exactamente. Se verificó el escenario del bug anterior (unidad atacante destruida) → ahora contabiliza los 1200 hombres.
- N3 cerrado: england, 773/641, 5 rondas; determinista; `apply_close_combat_outcome` aplica a campaña (informe de 17 claves, idempotente).
- 2 ejecuciones del harness → mismos resultados (determinismo).

### F2-C2 · Extinción dinástica — PASS
- Gobernante + heredero + vivos de la casa → `extinct=true`, `dynasty_extinct`, `state.game_over=true` y `EventBus.game_over(victory=false)` (1 señal); reloj congelado 1337·T1 tras intentar avanzar (sin turnos fantasma).

### F2-C3 · §10.1 Mapa — PASS
- 132.962 B ≤147.456; 47/47/47; 7.410 puntos; 0 ids inválidos/duplicados/huérfanas; coords [0,1]; área >0; 1337 owners válidos; source/estimate completo.
- Hit-test: 141/141 QA en su polígono y 141/141 resueltos por la implementación real de AG-3 en 3 vistas.
- `world_map.gd` consume `map_borders`; `map_layout.json` eliminado con 0 referencias en `scripts/`/`scenes/` (solo comentarios/constante en `tools/validator_core.gd`).
- Terreno 4096×3072; benchmark headless 120 frames con 120 hit-tests y 3 cambios de vista: **media 0,153–0,190 ms**, máx 5,9–6,9 ms (media <8; GPU no medible en headless).
- `map_comparison.png` presente y **1920×1080** (M-F2-01 resuelta).

### F2-C4 · §10.2 Retratos v1.5 — PASS
- **Datos:** los 14 gobernantes tienen `portrait` `res://assets/art/portraits/<id>.png`; **14/14 PNG 256×256**, únicos, sin incidencias; schema con patrón res://|null; 72 personajes sin portrait (heredan fallback).
- **Widget:** `setup(ruler)` → `get_portrait_character_id()` correcto e **`is_fallback()=false` en 14/14**; con el heredero sin portrait → `id` no vacío y **`is_fallback()=true`**.
- **5/5 slots con textura** (instanciación real con `_ready` + configuración): mapa 2/2 textura; árbol 2 textura + 7 fallback; diplomacia 1/1; batalla 2/2; corte 2 textura + 6 fallback. Los fallback corresponden a miembros sin `portrait` (no hay huecos vacíos).
- **Sucesión:** el slot del mapa muestra al gobernante con **textura**; tras muerte y `resolve_succession`, muestra al heredero `eduardo_el_principe_negro` con **fallback heráldico** (no tiene portrait), como exige la regla «nunca hueco vacío».
- **Capturas:** `map_portrait.png`, `map_comparison.png`, `portraits_contact_sheet_final.png` y `succession_portrait.png` presentes y **1920×1080** (4/4). Revisión visual: hoja de contacto con los 14 retratos finales, mapa con retrato+escudo y captura de sucesión con el heredero en fallback. M-F2-01 cerrada.

### F2-C5 · Smoke de escenas — PASS
- 18/18 `.tscn` instancian/liberan (16 previas + `tactical_map` + `close_combat`); 0 scripts de escena/battle sin compilar.

### F2-C6 · No regresión Fase 1 — PASS
- save/load 97.725 B, hash `a511634a85de3550` restaurado tras perturbar; Peste Negra 1348 en log/fired; determinismo; **0 mutaciones de UI**; 18 escenas. F1 harness 6/6; `run_all` 716/0/1; `validate_data` 5.281 comprobaciones/0 errores; editor/headless exit 0.

---

## 4. Verificación independiente

- **14/14 retratos**: PowerShell — 14 PNG 256×256, 14 campos `res://` válidos y únicos, 0 incidencias; 14 PNG en `assets/art/portraits/`.
- **5 slots**: `PortraitFrame` presente en `world_map.gd`, `family_tree.gd`, `diplomacy_screen.gd`, `battle_report.gd`, `court_overview.gd`; comportamiento verificado por el harness (arriba).
- **Capturas:** 38 PNG, **38 únicas**, todas las clave a 1920×1080 (`map_atlas_1337/1402/1453`, `map_portrait`, `map_comparison`, `portraits_contact_sheet_final`, `succession_portrait`, `tactical_map`, `close_combat`).
- **UI sin mutaciones:** 30 `.gd` de `scripts/ui/**` (excl. `dev/`): **0** asignaciones a autoloads/estado, **0** escrituras `state[...]`, **0** setters.
- **project.godot:** `config_version=5`, `main_scene=main_menu.tscn`, **10 autoloads**, 1920×1080.
- **D-024:** `data/map_layout.json` ausente; **0** referencias en `scripts/`/`scenes/`.
- **Datos:** `characters.json` cambió por los 14 `portrait` (esperado v1.5, hash `907E201B…`); los otros 5 datasets conservan hash de Fase 0; `map_borders.json` 132.962 B.
- **Espionaje** (§5.4, fuera de los 6 criterios del contrato §8): verificado en task-15 (intel persistente, 6 PG); sin cambios en v1.5.
- **B-F2-01:** corregido y re-verificado por el harness con cálculo independiente de bajas.
- **§10.3 sprites de unidades:** **NO es criterio de Fase 2** (Fase 3, D-037); se documenta y no se evalúa aquí.

---

## 5. Informe REA §3.2 — VERIFICADO

`docs/rea/gk2_battle_mechanics.md` (commit `2d283ff`; **12.517 B, 155 líneas, 1.998 palabras**) + anexo `docs/rea/notes_battle.md` (8.065 B, 1.322 palabras). Verificación:

| Requisito GDD v1.5 §3.2 | Estado | Evidencia |
|---|---|---|
| **Método/estado de observación** | **OK** | §1: DOSBox verificado ausente (PATH, Program Files, chocolatey, scoop, búsqueda recursiva: 0 ejecutables); mecánicas N2/N3 **declaradas NO observadas** aspecto por aspecto en §2 (8 aspectos), sin inventar; protocolo de 3–5 capturas por punto para una reactivación posterior. Limitación **aceptada como no bloqueante** por AG-0. |
| **`SUNIT.DAT`** | **OK** | §3: 49.152 B = 96×512 B; entropía/nulos, periodicidad 512, coherencia vertical, sin paleta VGA; interpretación 512 B/cuadro; límites declarados (dimensiones/profundidad no concluyentes). |
| **`KPAT.DAT`** | **OK** | §4: 45.450 B; 83,3 % binario; cabecera 8 B; coherencia W=21/42/101; hipótesis de banco de máscaras/patrones, sin copiar contenido. |
| **`GRPDATA.DAT`** | **OK** | §5: 45.475 B; secciones de densidad, filas ~40/80 B, tramados, sin paleta; hipótesis de banco raster/teselas; límites declarados. |
| **Lecciones §10.3** | **OK** | §6: 8 lecciones de diseño propio (silueta primero, arma define unidad, poses clave, espejo, proyectiles en capa aparte, contraste, escala, datos/QA) — alimentan Fase 3, no reimplementación. |
| **Legalidad** | **OK** | §7: sin desensamblado/descompilación de `.EXE`, sin copia de píxeles/paletas/assets de Koei, sin transcripción de texto del juego; previsualizaciones internas eliminadas; ningún binario/imagen derivada en `docs/rea/` (solo 4 `.md`). |
| **Formato/entregable** | **OK** | Markdown, referencia a `notes_battle.md` (reproducibilidad + limpieza/legalidad), sin citas largas del juego; 2 menciones de `.EXE` son ambas declaraciones de no-análisis. |

**Resultado: REA §3.2 PASS.** La falta de observación interactiva de N2/N3 queda documentada con transparencia y protocolo de cierre; no compromete el entregable ni la Fase 2 (los criterios §12/§10.1/§10.2 se validaron por código/datos/harness, no por el REA). **task-21 cerrada.**

---

## 6. Observaciones por severidad

- **BLOQUEANTES: 0** (B-F2-01 cerrado).
- **MAYORES: 0.**
- **MENORES: 0.**
- **INFORMATIVO:** REA §3.2 con observación de batalla pendiente de capturas del usuario (declarado y aceptado); `§10.3 sprites` es Fase 3 (D-037), fuera del alcance de Fase 2.

---

## 7. Limitaciones

1. La UI se valida por instanciación headless real (con `_ready`, configuración y capturas); no se simula interacción completa de usuario.
2. El benchmark mide CPU de `_process` + `hit_test` + `queue_redraw`; no incluye GPU/rasterizado real ni el coste completo de dibujo.
3. El hit-test se valida en los `center` de las 47 regiones por vista, no en todos los píxeles del polígono.
4. La revisión visual cubrió hoja de contacto de retratos, mapa con retrato, sucesión y capturas clave; las 38 capturas se validaron por existencia/tamaño/unicidad.
5. REA §3.2: las mecánicas N2/N3 no fueron observadas (DOSBox ausente); el informe lo declara y aporta protocolo de capturas. Aceptado como no bloqueante.

---

## 8. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness Fase 2 v1.5 | `tests/qa_acceptance_fase2.gd` |
| Harness Fase 1 | `tests/qa_acceptance.gd` |
| Plan QA | `docs/qa/fase2_plan.md` |
| Informe REA batallas | `docs/rea/gk2_battle_mechanics.md` (+ `notes_battle.md`) |
| Registro acumulativo | `docs/issues.md` (§9 baseline, §10 task-15, §11 v1.5 final) |

**Veredicto final: «QA Fase 2: APROBADO (v1.5)» — 6/6 criterios PASS + REA §3.2 verificado.** Fase 2 apta para tag `fase-2`.

*Fin del informe QA Fase 2 v1.5 — AG-4 (task-21 COMPLETADA).*

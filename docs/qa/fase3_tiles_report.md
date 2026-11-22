# Informe de QA — Tiles del campo de batalla N3 (GDD v1.7 §10.4)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Veredicto** | **QA Tiles Fase 3: APROBADO** — 7/7 criterios PASS, 0 FAIL, 0 SKIP |
| **Fase / alcance** | Fase 3 §10.4 (GDD v1.7), `docs/architecture_contracts_fase3_tiles.md`, D-051..D-056 |
| **HEAD verificado** | `2c1857d` (módulo tiles integrado: AG-2/AG-3) |
| **Harness** | `tests/qa_acceptance_tiles.gd` (7 criterios; API real de AG-2/AG-3) |
| **Scope** | Solo `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd`; sin producción ni git |

---

## 1. Veredicto y resumen

> **QA Tiles Fase 3: APROBADO**

- Harness tiles **×2 → 7/7 PASS, exit 0** (`ACEPTACIÓN TILES FASE 3: OK`).
- **12/12 tiles** de producción 512×512 cargan en headless como `Texture2D`; 12 PNG en `assets/art/battle/tiles/`; 12 raw `_raw_1024` en `src/` con `.gdignore`.
- **`battle_tiles`** (7º dataset) validado: 12 claves con valores/flags exactos D-053; `validate_data` 7 datasets/7 schemas, **5.722 comprobaciones, 0 errores/WARN**.
- **Río y montaña intransitables** (`passable=false`, `move_cost=-1`); en N2 un hex impasable adyacente rechaza `can_move_unit`/`move_unit`; **puente adyacente transitable**.
- **Bonus §6.4**: colina 2/1; camino 0,5 + `move_bonus`; villa_calle 0,5 + bonus; villa/puente_villa defense 1 (×1,2 al daño); bosque 2/1 + `cavalry_penalty` (caballería coste 3,0); fallback legado OK.
- **Generador N3** cableado a `battlefield_generator.gd::generate`: campo **coast+villa → 24 tiles, 2 puentes, villa (5,2)**, campo **plains → 24 tiles sin río**; determinista con la misma semilla.
- **3 capturas 1920×1080**: río vertical + puente + villa; campo de llanura; hoja de contacto de los 12 tiles. Continuidad del río y rotación vertical revisadas.
- **No regresión**: F1 6/6, F2 6/6, F3 sprites 6/6, `run_all` **1194/0/1**, editor/headless sin ERROR/WARNING.

---

## 2. Evidencia de comandos

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_tiles.gd` (×2) | **0 / 0** | **7 PASS / 0 FAIL / 0 SKIP**; `ACEPTACIÓN TILES FASE 3: OK`; métricas idénticas |
| 2 | `--script tests/qa_acceptance.gd` (F1) | **0** | **6/6 PASS** |
| 3 | `--script tests/qa_acceptance_fase2.gd` (F2) | **0** | **6/6 PASS** |
| 4 | `--script tests/qa_acceptance_fase3.gd` (sprites) | **0** | **6/6 PASS** |
| 5 | `--script tests/run_all.gd` | **0** | **1194 / 0 / 1**; `CI: OK` |
| 6 | `--script tools/validate_data.gd` | **0** | 7 datasets/7 schemas, **5.722 comprobaciones**, 0 errores/WARN |
| 7 | `--editor --quit` | **0** | 5 `[DONE]`, 0 ERROR/WARNING |
| 8 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |

Salida íntegra del harness tiles:

```text
==============================================================
 The Sovereign's Blood — QA Aceptación Fase 3 §10.4 (tiles N3)
 Godot 4.7.2-stable (official) · headless · 2026-11-22
==============================================================
[INFO] Fase 3 §10.4 — presencia de artefactos:
  data/battle_tiles.json: true
  data/schema/battle_tiles.schema.json: true
  res://assets/art/battle/tiles: true (12 PNG)
  scripts/battle/tiles*.gd o reglas: 4
  scripts/ui/battle/battlefield_generator.gd: true
  docs/screenshots: true
  staging tiles: true
  10/10 autoloads montados
  [PASS] F3T-C1 — 12 tiles cargan en headless: PNG 512x512 y rutas de battle_tiles :: 12/12 tiles 512x512 cargados como Texture2D; 12 PNG producción; 12 raw src con .gdignore
  [PASS] F3T-C2 — battle_tiles: 12 claves con move_cost/defense/passable/flags exactos (D-053) :: 12/12 claves y valores/flags D-053; schema presente; validate_data externo 0 errores
  [PASS] F3T-C3 — Río y montaña intransitables en N2/N3; puente transitable :: BattleTiles: rio/montana passable=false y cost=-1; puente passable/cost1; N2: 1 entradas a rio/montana bloqueadas (can_move/move_unit false); 1 puentes adyacentes transitables
  [PASS] F3T-C4 — Bonus §6.4: colina/camino/villa/bosque aplican en fórmulas de movimiento/defensa :: colina 2/1; camino 0.5+bonus; villa_calle 0.5+bonus; villa defense1×1.2; bosque 2/1 cavalry_penalty (cab 3.0); fallback legado OK; N2 get_battle_tile_keys=12; colina 2/1; 61 hexes con tile válido
  [PASS] F3T-C5 — Generador N3: campo con río+puente+villa y campo de llanura desde 2 regiones :: coast+villa: 24 tiles, 2 puentes, villa=(5, 2); plains: 24 tiles; determinista=true
  [PASS] F3T-C6 — Capturas tiles_n3_rio_puente_villa, tiles_n3_llanura y hoja de contacto (1920x1080) :: 3/3 capturas 1920x1080: tiles_n3_rio_puente_villa.png, tiles_n3_llanura.png, tiles_contact_sheet.png
  [PASS] F3T-C7 — No regresión: 18 escenas, harness F1/F2/F3, artefactos previos y scripts compilando :: 18 escenas; 26 tests; F1/F2/F3 presentes; artefactos F2/sprites; scripts fallos=0
--------------------------------------------------------------
RESULTADO QA TILES FASE 3: 7 PASS, 0 FAIL, 0 SKIP (de 7 criterios)
ACEPTACIÓN TILES FASE 3: OK — 7/7 criterios PASS (exit 0)
```

---

## 3. Criterio por criterio

### F3T-C1 · 12 tiles cargan — PASS
- `assets/art/battle/tiles/`: 12 PNG (**512×512**, `Texture2D`) con las rutas del contrato/`battle_tiles`; `src/` con 12 `_raw_1024` + `.gdignore` (D-054, no importados).
- Cada tile de la tabla carga sin error; 12/12.

### F3T-C2 · Tabla `battle_tiles` — PASS
- `data/battle_tiles.json` + `data/schema/battle_tiles.schema.json`; 12 claves con `move_cost`/`defense`/`passable` y flags exactos (D-053): pastizal 1/0, pastizal_arbustos 1/0, pradera 1/0, rio null/0/no, puente 1/0, puente_villa 1/1, colina 2/1, bosque 2/1+`cavalry_penalty`, montana null/0/no, villa 1/1, villa_calle 1/0+`move_bonus`, camino 0,5/0+`move_bonus`.
- `validate_data` reconoce el dataset como juego: **7/7, 5.722 comprobaciones, 0 WARN/0 errores**.

### F3T-C3 · Intransitabilidad y puentes — PASS
- `BattleTiles` puro: `is_passable(rio/montana)=false`; `get_move_cost(rio/montana)=-1`; puente `passable=true`, coste 1.
- N2: hex de río/montaña adyacente a unidad → `can_move_unit=false` y `move_unit=false` (1 caso); puente adyacente → `can_move_unit=true` (cruce posible). N3 expone API de tiles (12 claves).

### F3T-C4 · Bonus de terreno — PASS
- `colina` coste 2/defensa 1; `camino` coste 0,5 + `move_bonus`; `villa_calle` coste 0,5 + bonus; `villa`/`puente_villa` defensa 1 (`get_defense_multiplier=1.2`); `bosque` coste 2/defensa 1 + `cavalry_penalty` → caballería **3,0** (×1,5) y penalización de combate ×0,6 en N3 (código AG-2); fallback sin tabla: passable/cost -1/defense 0.
- N2: `get_battle_tile_keys=12`, colina 2/1, 61 hexes con `tile`; N3: `get_state()` preserva `tile` en ambos bandos.

### F3T-C5 · Generador N3 — PASS
- `scripts/ui/battle/battlefield_generator.gd::generate` cableado en `_probe_generator`:
  - `coast` con `has_city=true`, semilla 1337 → **24 tiles, 2 puentes, villa (5,2)**, río continuo (vertical).
  - `plains` → **24 tiles sin río**, campo distinto.
  - Misma semilla/región → misma rejilla (determinista).

### F3T-C6 · Capturas — PASS
- `tiles_n3_rio_puente_villa.png`, `tiles_n3_llanura.png`, `tiles_contact_sheet.png`: **1920×1080**, presentes en `docs/screenshots`.
- Revisión visual: campo N3 con **río vertical continuo, puente de piedra y villa**; campo de llanura sin río con caminos/villa; hoja de contacto con los 12 tiles etiquetados. Rotación vertical del río/puente/camino correcta; tiles legibles a 128 px.

### F3T-C7 · No regresión — PASS
- 18 escenas, 26 tests, harness F1/F2/F3, artefactos F2 y sprites 17/17 presentes; 0 scripts sin compilar.
- Batería: F1 6/6, F2 6/6, F3 sprites 6/6, run_all **1194/0/1**, validate 7/7 0 WARN, editor/headless 0 ERROR/WARNING.

---

## 4. Observaciones y límites

- C3 prueba el cruce de puente cuando existe un puente adyacente a una unidad (1 caso en el mapa analizado); la API pura valida `puente`/`puente_villa` transitables en cualquier caso.
- C4 valida las fórmulas en `BattleTiles`/API N2/N3 y la penalización de caballería en bosque; la aplicación exacta del ×0,6 de combate N3 está cubierta por los tests de AG-2 (harness F3 no invade esa fórmula).
- C5 prueba el generador 8×3 con `coast+villa` y `plains`; la composición visual se revisó en las capturas.
- El módulo §10.4 está integrado por AG-2/AG-3; AG-4 no ha modificado producción ni git.
- **Fuera de este módulo:** escenarios 1402/1453, retratos/animaciones y QA final de Fase 3 (siguiente tramo).

---

## 5. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness tiles | `tests/qa_acceptance_tiles.gd` |
| Plan QA tiles | `docs/qa/fase3_tiles_plan.md` |
| Este informe | `docs/qa/fase3_tiles_report.md` |
| Capturas | `docs/screenshots/tiles_n3_rio_puente_villa.png`, `tiles_n3_llanura.png`, `tiles_contact_sheet.png` |
| Registro | `docs/issues.md` (§15 baseline, §16 verificación final) |

*Fin del informe QA Tiles Fase 3 — AG-4. Veredicto: **APROBADO**.*

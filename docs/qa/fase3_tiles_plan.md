# Plan de QA — Fase 3 §10.4: tiles del campo de batalla N3 (baseline)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Fase** | Fase 3 §10.4 (GDD v1.7) + `docs/architecture_contracts_fase3_tiles.md` + D-051..D-056 |
| **Alcance** | Integración de los **12 tiles 512×512** de Kimi, tabla `battle_tiles`, reglas tácticas N2/N3 (río/montaña intransitables; colina/camino/bosque) y generador de campos N3 derivado de la región. |
| **Harness** | `tests/qa_acceptance_tiles.gd` (`extends SceneTree`, sin GUT; compila siempre) |
| **Baseline** | HEAD actual (`09796a6` + docs v1.7). Los 12 tiles están **solo en staging** (`C:\Proyectos\TSB\.tiles_staging\tiles_batalla\`); aún no hay `assets/art/battle/tiles/`, ni `data/battle_tiles.json`, ni reglas/generador/render/capturas. AG-3/AG-2 trabajan en paralelo. |
| **Veredicto** | Baseline: **PENDIENTE** (SKIP justificado, no es rechazo). Verificación final: **task-37**. |

---

## 1. Matriz criterio → test → comando → evidencia

| ID | Criterio (GDD §10.4 / contrato addendum 3.1) | Test en `qa_acceptance_tiles.gd` | Comando | Evidencia esperada |
|---|---|---|---|---|
| F3T-C1 | **12 tiles cargan en headless**: 12 claves en `battle_tiles`, rutas `res://assets/art/battle/tiles/tile_*.png` existentes y `Texture2D` 512×512; 12/12 PNG de producción; `src/` con 12 raw `_raw_1024` + `.gdignore` (sin importar). | `_criterion_1_tiles()` | `godot --headless --script tests/qa_acceptance_tiles.gd` | PASS 12/12 texturas 512×512; 12 PNG; src 12 |
| F3T-C2 | **`battle_tiles` validado**: 12 claves con `move_cost`/`defense`/`passable`/flags exactos del contrato (D-053); schema presente; `validate_data` 0 WARN/0 errores. | `_criterion_2_table()` + batería | ídem | PASS 12/12 valores; schema; validate 0 |
| F3T-C3 | **Río/montaña intransitables** en N2/N3: una unidad no puede entrar ni cruzar fuera de puente; puente sí transitable. | `_criterion_3_impassable()` | ídem | PASS con movimiento rechazado en rio/montana |
| F3T-C4 | **Bonus §6.4**: `move_cost`/`defense` de colina, `move_bonus` de camino/villa_calle, `defense` de villa/puente_villa; bosque penaliza caballería (`cavalry_penalty`); determinismo intacto. | `_criterion_4_bonuses()` | ídem | PASS fórmulas/costes/flags |
| F3T-C5 | **Generador de campos N3** derivado de la región: un campo con **río+puente+villa** y otro de **llanura**, desde 2 regiones de terreno distinto; determinista. | `_criterion_5_generator()` | ídem | PASS 2 campos coherentes |
| F3T-C6 | **Capturas**: `tiles_n3_rio_puente_villa.png` y `tiles_n3_llanura.png` + hoja de contacto, 1920×1080 en `docs/screenshots/`; revisión visual de continuidad del río y legibilidad a 128 px. | `_criterion_6_captures()` | ídem + visual | PASS 3/3 capturas |
| F3T-C7 | **No regresión**: `run_all` 1074+, F1/F2/F3-sprites 6/6, `validate_data` 0, editor/headless sin ERROR/WARNING, 18 escenas, scripts compilando, artefactos previos intactos. | `_criterion_7_no_regression()` + batería | ver §3 | PASS batería completa |

**Semántica:** `[PASS]` criterio cumplido; `[SKIP]` pendiente de módulo en curso (baseline; indica qué falta); `[FAIL]` módulo presente pero viola el contrato. **Exit 0 solo con 7/7 PASS**; baseline con SKIP sale 1 e imprime «PENDIENTE», no «rechazado».

---

## 2. Detalle de checks

### F3T-C1 — Assets y carga
- `assets/art/battle/tiles/` con **12 PNG** (tile_pastizal, tile_pastizal_arbustos, tile_pradera, tile_rio, tile_puente, tile_puente_villa, tile_colina, tile_bosque, tile_montana, tile_villa, tile_villa_calle, tile_camino), cada uno `ResourceLoader.exists` + `load()` `Texture2D` **512×512**.
- `src/` con los **12 raw `_raw_1024`** y `.gdignore` (D-054); no se importan.
- Rutas exactas del contrato: `res://assets/art/battle/tiles/<tile>.png`.

### F3T-C2 — Tabla `battle_tiles`
- `data/battle_tiles.json` (envelope D-009) + `data/schema/battle_tiles.schema.json`.
- Valores exactos (D-053/GDD §6.4): pastizal/pastizal_arbustos/pradera 1/0/passable; rio null/0/no; puente 1/0/sí; puente_villa 1/1/sí; colina 2/1/sí; bosque 2/1/sí + `cavalry_penalty`; montana null/0/no; villa 1/1/sí; villa_calle 1/0/sí + `move_bonus`; camino 0,5/0/sí + `move_bonus`.
- `validate_data.gd` reconoce el dataset como juego y da 0 WARN/0 errores (batería).

### F3T-C3 — Intransitabilidad
- En N2/N3 (o reglas de AG-2): una unidad no puede entrar a `rio`/`montana`; el puente permite cruzar; no se puede «rodear» el río fuera del puente. Test con movimiento/`move_unit`/reglas de coste.
- Si no existen aún APIs de tiles → SKIP (AG-2/AG-3).

### F3T-C4 — Bonus de terreno
- `move_cost` y `defense` de `colina`; `move_bonus` de `villa_calle`/`camino`; `defense` de `villa`/`puente_villa`; `cavalry_penalty` de `bosque` aplicada a caballería; comparar con fórmulas §6.4.
- Sin RNG adicional: el determinismo del combate no cambia.

### F3T-C5 — Generador
- Busca `battlefield_generator.gd` (o equivalente) y comprueba que con una región `mountains`/`forest`/`plains` produce una rejilla con río continuo de orilla a orilla + 1–2 puentes + villa, y otra de llanura sin río obligatorio; determinista (misma semilla → misma rejilla).

### F3T-C6 — Capturas (D-056)
- `tiles_n3_rio_puente_villa.png`, `tiles_n3_llanura.png`, hoja de contacto (`*hoja_contacto_tiles*`), todas 1920×1080; revisión visual de continuidad del agua/puente y legibilidad a 128 px.

### F3T-C7 — No regresión
- 18 escenas, 24 tests, harness F1/F2/F3-sprites presentes, artefactos F2/F3, 0 scripts sin compilar; batería externa.

---

## 3. Comandos

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_tiles.gd        # harness tiles
& $g --headless --path $repo --script tests/qa_acceptance.gd             # F1
& $g --headless --path $repo --script tests/qa_acceptance_fase2.gd       # F2
& $g --headless --path $repo --script tests/qa_acceptance_fase3.gd       # F3 sprites
& $g --headless --path $repo --script tests/run_all.gd                   # 1074+
& $g --headless --path $repo --script tools/validate_data.gd             # 0 errores
& $g --headless --path $repo --editor --quit                             # import + 0 ERROR/WARNING
& $g --headless --path $repo --quit                                      # 0 ERROR/WARNING
```

**Baseline esperado:** F3T-C1..C6 SKIP (no hay assets/data/reglas/generador/capturas en repo), F3T-C7 PASS; salida 1 con «PENDIENTE». Detalle en `docs/issues.md` §15.

---

## 4. Riesgos

| ID | Riesgo | Mitigación QA |
|---|---|---|
| R-T-01 | Rutas de tiles (`assets/art/battle/tiles/`) distintas a las del contrato/README. | C1 exige la ruta exacta del addendum 3.1; falla si no coincide. |
| R-T-02 | Tiles 512 sin importar → `ResourceLoader.exists=false`. | C1 exige `load()`+`Texture2D`; `--editor --quit` antes del harness final. |
| R-T-03 | Tabla con flags incoherentes (`passable=false` con `move_cost` numérico, `cavalry_penalty` en tile libre). | C2 valida valores/flags exactos y `validate_data`. |
| R-T-04 | Río/montaña mal aplicados en movimiento (se puede entrar). | C3 test de movimiento real; C5 campo con río. |
| R-T-05 | Bonus de colina/camino no aplicados o no deterministas. | C4 compara fórmulas §6.4; C7 determinismo. |
| R-T-06 | Generador no deriva de la región (campos idénticos). | C5 exige 2 regiones distintas → 2 campos distintos. |
| R-T-07 | Capturas ausentes o sin 1920×1080. | C6 exige los 2 nombres + hoja de contacto a 1920×1080. |
| R-T-08 | Regresión de sprites/F2 al tocar escena N3. | C7 + harness F1/F2/F3 6/6. |

---

## 5. Verificación final (task-37)

Harness tiles 7/7 PASS exit 0; batería completa; revisión visual de continuidad del río/puente y legibilidad a 128 px; veredicto **«QA Tiles Fase 3 (12/12): APROBADO/RECHAZADO»** en `docs/qa/fase3_tiles_report.md` + `docs/issues.md`.

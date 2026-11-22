# Plan de QA — Fase 3 (baseline y prioridad 1: sprites de unidades)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Fase** | Fase 3 — GDD v1.6 §10.3 / §12, contrato `docs/architecture_contracts_fase3.md` |
| **Alcance de este plan** | **PRIORIDAD 1:** integración de los sprites núcleo de Kimi (6 unidades + 3 proyectiles). El resto de Fase 3 (escenarios 1402/1453, retratos nuevos, tiles, música) se planifica de forma somera al final. |
| **Harness** | `tests/qa_acceptance_fase3.gd` (`extends SceneTree`, sin GUT; compila siempre) |
| **Baseline** | Snapshot en HEAD **`72b3aee`** (GDD v1.6 + contrato F3/D-039..D-043 + STATUS P1). AG-5 ya copió los assets a `assets/art/sprites/` (**18 PNG de unidades + 3 proyectiles**, `src/` no importado; staging original en `C:\Proyectos\TSB\.sprites_staging\sprites_unidades\`); **aún no** hay `sprite_sheet` en `units.json` (0/6), ni APIs/render de animación/proyectiles. Por eso el baseline da **PASS en lo ya existente + SKIP/PENDIENTE justificado en lo que falta** (no es un rechazo). |
| **Veredicto** | Baseline: **PENDIENTE** (datos/código de AG-2/AG-3 en curso; assets AG-5 presentes); la verificación final es **task-28**. |

---

## 1. Criterios y matriz criterio → test → comando → evidencia

| ID | Criterio (contrato §5 / GDD §10.3) | Test en `qa_acceptance_fase3.gd` | Comando | Evidencia esperada |
|---|---|---|---|---|
| F3-C1 | Las **6 unidades núcleo** (`militia_spearman`, `swiss_pikeman`, `crossbowmen`, `longbowman`, `men_at_arms`, `light_horseman`) tienen `sprite_sheet` válido: 3 frames `res://` existentes, `size` 64×64/64×80, `anim.march=[0,1,2]`, fps 6, loop true, `anchor=bottom_center`, `facing=E`; cargan en headless (`ResourceLoader.exists` + `load()` + `Texture2D`); 18 PNG de unidades y 3 proyectiles presentes. | `_criterion_1_sprites()` | `godot --headless --script tests/qa_acceptance_fase3.gd` | PASS con detalle 6/6, 18/18 PNG, 3/3 proyectiles, texturas 64×64/64×80 |
| F3-C2 | Las **11 unidades restantes** NO tienen `sprite_sheet` y usan fallback heráldico (sin huecos). El dataset tiene 17 unidades: 6 núcleo + 11 sin sprite. | `_criterion_2_fallback()` | ídem | PASS con 11/11 sin campo y nota de fallback existente |
| F3-C3 | **Crécy N1/N2/N3** con unidades nuevas sin crash; `get_units()` expone `sprite_sheet`, `facing`, `mirror`, `moving`, `march_frame`, `sprite_frame_path`; animación march 6 fps/3 frames, facing/mirroring coherentes (base E/SE/S; espejo W/SW/NW/N); proyectiles `virote`/`flecha`/`piedra` desde `get_projectiles()` (o señal) con sprite, tiempos 350/500/700 ms y arcos 24/40/56 px. | `_criterion_3_battle_sprites()` | ídem | PASS con unidades/anim/proyectiles verificados |
| F3-C4 | **Determinismo de combate intacto** (misma semilla + mismas entradas → mismo informe; activar animación/proyectiles no altera resultados). | `_criterion_4_determinism()` | ídem | PASS con hashes iguales (N1 baseline; N2/N3 en final) |
| F3-C5 | **Capturas** de `militia_spearman`, `crossbowmen` y `longbowman` a 64 px (arma legible) + una N2 y una N3 con sprites/proyectiles en `docs/screenshots/`, 1920×1080. | `_criterion_5_captures()` | ídem + revisión visual | PASS con 5 capturas encontradas a 1920×1080 |
| F3-C6 | **No regresión:** `run_all` 716+, F1 6/6, F2 6/6, `validate_data` 0 errores, editor/headless sin ERROR/WARNING, 18 escenas, 17 unidades, scripts compilando, artefactos F2 intactos (`map_borders`, retratos). | `_criterion_6_no_regression()` + batería externa | ver §3 | PASS con batería completa |

**Semántica del harness:** `[PASS]` criterio cumplido; `[SKIP]` pendiente de módulo (baseline; justificado con qué falta); `[FAIL]` módulo presente pero viola el contrato. **Exit 0 solo si 6/6 PASS**; en baseline con SKIP sale 1 e imprime «PENDIENTE», **no** «rechazado».

---

## 2. Detalle de comprobaciones del harness

### F3-C1 — Sprites núcleo
- Lee `data/units.json`; exige 17 unidades y los 6 IDs núcleo.
- Para cada núcleo: `sprite_sheet` Dictionary; `frames` array de 3 strings `res://`; cada `ResourceLoader.exists` y `load()` es `Texture2D` con ancho/alto esperados (infantería/ranged 64×64; caballería 64×80: `men_at_arms`, `light_horseman`).
- `anim.march` == [0,1,2], `fps` == 6, `loop` == true; `size` == [64,64] o [64,80]; `anchor` == `bottom_center`; `facing` == `E`.
- Cuenta 18 PNG en `assets/art/sprites/units/` y 3 en `assets/art/sprites/projectiles/`; verifica PNG válido (cabecera) y dimensiones de producción.

### F3-C2 — Fallback
- 17 unidades; 11 no núcleo sin `sprite_sheet`; si alguna no-núcleo tiene el campo → FAIL.
- Con 0 núcleos integrados, el fallback es universal (estado actual): se registra PASS de datos con nota de que la verificación visual se completa en F3-C5/task-28.

### F3-C3 — Batalla y proyectiles
- Si no hay `sprite_sheet` en las 6 núcleo o faltan APIs (`get_projectiles`, campos nuevos en `get_units`), **SKIP** con lista de lo que falta.
- Con integración: N1 `resolve_delegated` (longbowman vs men_at_arms; Crécy), N2 `launch_tactical` + `auto_resolve`/movimiento y N3 `launch_close_combat` + `auto_resolve`; inspección de `get_units()` (campos), `facing`/`mirror` válidos y coherentes, `march_frame` 0..2, `sprite_frame_path` cargable; `get_projectiles()` existe; se comprueban payloads si hay proyectiles (tipo sprite/tiempo/arco).
- No se instancian nodos de UI para la lógica: se usan los modelos `Army`/`RegionState` y `BattleManager`, como en F2.

### F3-C4 — Determinismo
- N1 con `BattleManager.resolve_delegated` dos veces con la misma semilla/estado → mismo hash de informe y estado.
- En task-28 se ampliará a N2/N3 y a la activación de animación/proyectiles (deben ser función solo del tiempo, sin RNG de combate).

### F3-C5 — Capturas
- Patrones flexibles en `docs/screenshots/`: 3 capturas de unidad (`militia`/`crossbow`/`longbow` + `64` o `sprite`); N2 (`tactical`/`n2` + sprite/unidad); N3 (`close`/`n3` + proyectil/virote/flecha/piedra).
- Cada captura debe ser 1920×1080. Revisión visual de legibilidad del arma (REA §6): lanza/pica, ballesta, arco.
- Nombres de referencia que AG-3/AG-0 pueden usar: `units_militia_spearman_64px.png`, `units_crossbowmen_64px.png`, `units_longbowman_64px.png`, `battle_n2_sprites.png`, `battle_n3_projectiles.png`.

### F3-C6 — No regresión
- 17 unidades, 6 núcleo / 11 fallback; ≥18 escenas; ≥22 tests; harness F1/F2 presentes; artefactos F2 (`map_borders.json`, `assets/art/map/terrain_base.png`, retratos) presentes; escaneo de scripts `.gd` sin fallos de compilación.
- La batería externa se ejecuta además en el baseline y en task-28 (ver §3).

---

## 3. Comandos de baseline/final

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_fase3.gd      # harness F3
& $g --headless --path $repo --script tests/qa_acceptance.gd           # F1
& $g --headless --path $repo --script tests/qa_acceptance_fase2.gd     # F2
& $g --headless --path $repo --script tests/run_all.gd                 # 716+/0/1
& $g --headless --path $repo --script tools/validate_data.gd           # 0 errores
& $g --headless --path $repo --editor --quit                           # import + 0 ERROR/WARNING
& $g --headless --path $repo --quit                                    # 0 ERROR/WARNING
```

**Evidencia del baseline (a rellenar al ejecutar):** ver `docs/issues.md` §12 «Fase 3 — Baseline». Estado esperado: F3-C2/C4/C6 PASS; F3-C1/C3/C5 SKIP (módulos en curso); exit 1 con «PENDIENTE».

---

## 4. Riesgos identificados (P1)

| ID | Riesgo | Mitigación QA |
|---|---|---|
| R-F3-01 | **Ruta de assets contradictoria:** GDD v1.6 §10.3 menciona `assets/art/units/<unit_id>.png` en una línea heredada, pero el contrato F3 §1 y el bloque de entrega usan `assets/art/sprites/units/`. | La fuente de verdad es `docs/architecture_contracts_fase3.md` §1 + D-039; el harness exige `res://assets/art/sprites/units/` y lo reporta si AG-5 usa otra ruta. |
| R-F3-02 | Sprites en staging pero no importados por Godot (falta `.import`/editor): `ResourceLoader.exists=false` en headless. | F3-C1 exige `ResourceLoader.exists` + `Texture2D`; el comando `--editor --quit` debe ejecutarse antes del harness final (import). |
| R-F3-03 | Regresión del fallback (11 unidades) al añadir sprites. | F3-C2 falla si alguna no-núcleo recibe `sprite_sheet`; F3-C5 revisa capturas con fallback. |
| R-F3-04 | Animación/proyectiles alteran el resultado determinista (RNG o tiempo no determinista). | F3-C4 compara hashes con misma semilla; contrato §3 exige proyectiles deterministas solo por tiempo. |
| R-F3-05 | `get_units()` extendido rompe tests de F2/consumidores. | F3-C6 + harness F2 6/6; campos aditivos obligatorios. |
| R-F3-06 | Capturas de staging no copiadas a `docs/screenshots` o tamaño incorrecto. | F3-C5 exige nombres/patrones y 1920×1080; AG-0 copia desde `.ui_check_f3/`. |
| R-F3-07 | Concurrencia AG-5/AG-2/AG-3 sobre datos/scripts/escenas. | Baseline sobre HEAD estable; final sobre commits integrados; F3-C6 detecta scripts sin compilar. |
| R-F3-08 | Nombres de frames/anim no coinciden (3 frames de marcha vs GDD idle/march/attack de fases futuras). | El contrato P1 acota `anim.march` [0,1,2], fps 6, loop; idle/attack quedan pendientes y se documentan como fuera de P1. |

---

## 5. Resto de Fase 3 (somero, para task-28+)

- Escenarios 1402/1453: datos + eventos (Ankara, locura de Carlos VI, caída de Constantinopla, Dos Rosas); 3 escenarios inician y llegan a su año final; partida de 10 años sin errores.
- Retratos de herederos/nuevos escenarios (§10.2): set completo y slot funcional en las 5 ubicaciones.
- Tiles/música/balance final; `§10.3` completo (idle/attack/impact/death + 11 unidades restantes) es una ampliación posterior, **no** criterio de esta P1.
- QA task-28: harness F3 6/6, batería F1/F2/run_all/validate/editor, capturas e inspección visual; veredicto final «QA Fase 3: APROBADO/RECHAZADO».

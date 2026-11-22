# Plan de QA — Fase 3 PRIORIDAD 1: sprites 17/17 (paquete v2)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Fase** | Fase 3 — GDD v1.6 §10.3 (paquete v2, 17 unidades) y D-044..D-050 |
| **Alcance de este plan** | **PRIORIDAD 1:** integración de los **17 sprites de unidad** (51 cuadros de marcha) + 3 proyectiles. El resto de Fase 3 se planifica de forma somera al final. |
| **Harness** | `tests/qa_acceptance_fase3.gd` (`extends SceneTree`, sin GUT; compila siempre) |
| **Baseline** | Snapshot en HEAD **`8d4ae36`** (inicial `9ee52c6`; GDD v1.6 actualizado `464faff` + D-044..D-050). AG-5 ya copió **51 PNG de unidades + 3 proyectiles** a `assets/art/sprites/`; `data/units.json` tiene **6/17** `sprite_sheet` y AG-2/AG-3 siguen integrando las 11 restantes, el mapeo D-048 y las capturas de almogávar/jenízaro. AG-5/AG-2/AG-3 en curso. |
| **Veredicto** | Baseline: **PENDIENTE** (3 PASS / 0 FAIL / 3 SKIP; no es rechazo). Verificación final: **task-33**. |

---

## 1. Matriz criterio → test → comando → evidencia (17/17)

| ID | Criterio (GDD §10.3 / D-044..D-050) | Test en `qa_acceptance_fase3.gd` | Comando | Evidencia esperada |
|---|---|---|---|---|
| F3-C1 | **17/17** unidades con `sprite_sheet` válido: 3 frames `res://` existentes, **51 PNG** de producción, `size`/dimensiones reales **64×64** (infantería/ranged), **64×80** (caballería/light_cavalry), **64×43** (bombarda, hussite_war_wagon), `anim.march=[0,1,2]`, fps 6, loop, `anchor=bottom_center`, `facing=E`; cargan en headless (`ResourceLoader.exists`+`load()`+`Texture2D`); 3 proyectiles cargan. | `_criterion_1_sprites()` | `godot --headless --script tests/qa_acceptance_fase3.gd` | PASS 17/17, 51/51 PNG, 3/3 proyectiles, 51 texturas con dims reales |
| F3-C2 | **Fallback vivo con unidad sintética SIN `sprite_sheet`** (ya no hay "11 sin sprite"): `frames_of({})=[]`, `frame_path({},0)=""`, `march_frame({})=0`, sin proyectil; camino de fallback presente en `TacticalBattle`/`CloseCombat`; nunca hueco vacío. | `_criterion_2_fallback()` | ídem | PASS con unidad sintética y marcadores de fallback |
| F3-C3 | **Crécy N1 + N2/N3 con las 17 unidades**, sin crash; `get_units()` expone `sprite_sheet`/`facing`/`mirror`/`moving`/`march_frame`/`sprite_frame_path`; facing/mirroring coherentes (base E/SE/S; espejo W/SW/NW/N); **mapeo D-048**: virote→crossbowmen; flecha→longbowman/janissary/steppe_cavalry; piedra→bombarda (350/500/700 ms; arcos 24/40/56). | `_criterion_3_battle_sprites()` | ídem | PASS con N1/N2/N3, animación/facing/mirroring y los 5 proyectiles |
| F3-C4 | **Determinismo de combate intacto** (misma semilla/entradas → mismo informe; animación/proyectiles no consumen RNG). | `_criterion_4_determinism()` | ídem | PASS hashes iguales (N1; N2/N3 en final) |
| F3-C5 | **Capturas mínimas**: `militia_spearman`, `crossbowmen`, `longbowman`, `almogavar`, `janissary` a **64 px reales** (legibilidad del arma, REA §6) + una N2 y una N3 con sprites/proyectiles, 1920×1080, en `docs/screenshots/`. | `_criterion_5_captures()` | ídem + revisión visual | PASS 7/7 capturas |
| F3-C6 | **No regresión:** `run_all` **932+/0/1**, F1 6/6, F2 6/6, `validate_data` 0 errores, editor/headless sin ERROR/WARNING, 17 unidades, 18 escenas, scripts compilando, artefactos F2 intactos. | `_criterion_6_no_regression()` + batería externa | ver §3 | PASS con batería completa |

**Semántica:** `[PASS]` criterio cumplido; `[SKIP]` pendiente de módulo en curso (baseline; justificado con qué falta); `[FAIL]` módulo presente pero viola el contrato. **Exit 0 solo con 6/6 PASS**; baseline con SKIP sale 1 e imprime «PENDIENTE», **no** «rechazado».

---

## 2. Detalle de comprobaciones

### F3-C1 — 17/17 sprites
- Lee `data/units.json`; deben existir **17 unidades** y las 17 con `sprite_sheet`.
- Para cada unidad: `frames` array de 3 strings `res://`; cada `ResourceLoader.exists` + `load()` es `Texture2D`; dimensiones según `type`: **infantería/ranged 64×64**, **cavalry/light_cavalry 64×80**, **artillery/special 64×43** (D-047); `size` coincide con la dimensión real.
- `anim.march` == [0,1,2], fps 6, loop true; `anchor=bottom_center`; `facing=E`.
- **51 PNG** en `assets/art/sprites/units/` (D-044; 17×3) y **3** en `projectiles/`, cargando como `Texture2D`; `src/` contiene las fuentes `_raw_1024` con `.gdignore` y no se cuenta como producción (D-046).

### F3-C2 — Fallback sintético
- Carga el módulo puro `scripts/battle/battle_sprites.gd` y comprueba con un `sprite_sheet` vacío (unidad sintética `qa_synthetic_no_sprite`, no presente en `units.json`): `frames_of` devuelve `[]`, `frame_path` `""`, `march_frame` 0 y no hay proyectil.
- Verifica que `TacticalBattle`/`CloseCombat` conservan el camino de fallback (`frames_of`, `sprite_frame_path`, `_sprite_or_null`): una unidad sin hoja no debe producir hueco vacío.
- No depende de que queden unidades sin sprite (todas tendrán); el fallback sigue disponible por si un `unit_id` no tiene hoja.

### F3-C3 — Crécy 17 unidades, animación y proyectiles
- Si no están las 17 hojas integradas → **SKIP** con lista de faltantes (baseline).
- Comprueba el **mapeo D-048** en `battle_sprites.gd` (tipo/duración/arco) para los 5 disparos; si falta → SKIP «mapeo D-048 pendiente» (AG-2).
- N1 `resolve_delegated` (Crécy), N2 `launch_tactical`+`auto_resolve`/movimiento y N3 `launch_close_combat`+`auto_resolve`; `get_units()` con campos nuevos; `facing`/`mirror` válidos y coherentes; `march_frame` 0..2; `sprite_frame_path` cargable; `get_projectiles()` existente y payloads coherentes (si hay proyectiles activos).
- No se instancian nodos de UI para la lógica; se usan modelos `Army`/`RegionState` y `BattleManager`, como en F2.

### F3-C4 — Determinismo
- N1 `resolve_delegated` dos veces con misma semilla/estado → hash de informe idéntico; en task-33 se amplía a N2/N3 y a la animación/proyectiles (deterministas por tiempo, sin RNG de combate).

### F3-C5 — Capturas (D-050)
- Busca en `docs/screenshots/`: **5** capturas de unidad (`militia_spearman`, `crossbowmen`, `longbowman`, `almogavar`, `janissary`, con `64`/`sprite`/`unit` en el nombre), **N2** con sprites y **N3** con proyectiles; todas 1920×1080.
- Revisión visual de legibilidad del arma (lanza/pica, ballesta, arco, jabalina/escudo, cimitarra/arco compuesto).
- Nombres de referencia: `units_militia_spearman_64px.png`, `units_crossbowmen_64px.png`, `units_longbowman_64px.png`, `units_almogavar_64px.png`, `units_janissary_64px.png`, `battle_n2_sprites.png`, `battle_n3_projectiles.png`.

### F3-C6 — No regresión
- 17 unidades, 18 escenas, 24 tests, harness F1/F2/run_all presentes, artefactos F2 (`map_borders`, terreno, retratos), 0 scripts sin compilar.
- La batería externa se ejecuta en baseline y task-33: `run_all` **932+**, F1/F2 6/6, `validate_data` 0, editor/headless 0 ERROR/WARNING.

---

## 3. Comandos de baseline/final

```powershell
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$repo = "C:\Proyectos\TSB\sovereigns-blood"
& $g --headless --path $repo --script tests/qa_acceptance_fase3.gd      # harness F3 17/17
& $g --headless --path $repo --script tests/qa_acceptance.gd           # F1
& $g --headless --path $repo --script tests/qa_acceptance_fase2.gd     # F2
& $g --headless --path $repo --script tests/run_all.gd                 # 932+/0/1
& $g --headless --path $repo --script tools/validate_data.gd           # 0 errores
& $g --headless --path $repo --editor --quit                           # import + 0 ERROR/WARNING
& $g --headless --path $repo --quit                                    # 0 ERROR/WARNING
```

**Baseline 2026-11-22 (HEAD `9ee52c6`):** harness F3 **3 PASS / 0 FAIL / 3 SKIP** (exit 1, «PENDIENTE»); F1 **6/6**, F2 **6/6**, run_all **932/0/1**, validate **5.383 comprobaciones/0 errores**, editor/headless exit 0. Assets 51+3 presentes; datos 6/17; capturas 3/5+2 pendientes. Detalle en `docs/issues.md` §13.

---

## 4. Riesgos (v2, 17/17)

| ID | Riesgo | Mitigación QA |
|---|---|---|
| R-F3-01 | Ruta de assets (GDD heredado `assets/art/units/` vs contrato `assets/art/sprites/units/`). | El harness exige `res://assets/art/sprites/units/` (contrato/D-044); a fecha baseline ya hay 51 PNG en esa ruta. |
| R-F3-02 | Assets sin importar: `ResourceLoader.exists=false` en headless. | F3-C1 exige `load()`+`Texture2D`; ejecutar `--editor --quit` antes del harness final. |
| R-F3-03 | Fallback roto al integrar sprites en las 17. | F3-C2 prueba unidad sintética sin hoja y marcadores en batalla. |
| R-F3-04 | Animación/proyectiles alteran el determinismo. | F3-C4 hash doble; proyectiles deterministas por tiempo (D-042/D-048). |
| R-F3-05 | `get_units()` extendido rompe tests de F2/consumidores. | F3-C6 + F2 6/6; campos aditivos. |
| R-F3-06 | Capturas incompletas o no 1920×1080 (5 unidades + N2 + N3). | F3-C5 patrones + tamaño; AG-0 copia desde `.ui_check_f3/`. |
| R-F3-07 | Concurrencia AG-5/AG-2/AG-3 durante baseline. | Snapshot con HEAD estable; final sobre commits integrados; C6 detecta scripts sin compilar. |
| R-F3-08 | **64×43** en bombarda/carro húsita (panorámico) recortado o con padding incorrecto. | C1 compara dimensiones reales y `size`; revisión visual de capturas. |
| R-F3-09 | **D-045** `bombard`→`bombarda`: archivos o `sprite_sheet` con id erróneo. | C1 exige 3 frames de `bombarda` existentes y `unit_id` del dataset. |
| R-F3-10 | **D-048** mapeo ampliado (janissary/steppe_cavalry → flecha) no implementado. | C3 comprueba `projectile_for_unit` para los 5 disparos; SKIP si pendiente, FAIL si mal. |
| R-F3-11 | `src/` con 51 `_raw_1024` versionados e importados por error. | C1 cuenta solo 51 PNG de producción; `.gdignore` en `src/` (D-046). |
| R-F3-12 | Nombres/anim: P1 solo marcha 3 frames; idle/attack/impact/death quedan para petición a Kimi (D-049). | Documentado como fuera de P1; no bloquea task-33. |

---

## 5. Resto de Fase 3 (somero)

- Escenarios 1402/1453 y eventos (Ankara, locura de Carlos VI, caída de Constantinopla, Dos Rosas); 3 escenarios inician y llegan a su año final; partida de 10 años sin errores.
- Retratos de herederos/nuevos escenarios (§10.2): set completo y slot funcional en las 5 ubicaciones.
- Tiles/música/balance; cuadros idle/ataque/impacto/muerte (D-049) y ampliaciones de arte.
- QA task-33: harness F3 6/6, batería completa, capturas/legibilidad, veredicto final «QA Fase 3: APROBADO/RECHAZADO».

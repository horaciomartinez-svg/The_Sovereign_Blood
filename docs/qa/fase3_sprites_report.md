# Informe de QA — Sprites Fase 3 (17/17)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Veredicto** | **QA Sprites Fase 3 (17/17): APROBADO** — 6/6 criterios PASS, 0 bloqueantes |
| **Fase / alcance** | Fase 3 PRIORIDAD 1 — GDD v1.6 §10.3 (paquete v2, 17 unidades) + D-044..D-050 |
| **HEAD verificado (código)** | `131147a` (`[AG-3] Fase 3 v2: render 17/17…`); el HEAD actual `09796a6` solo añade GDD v1.7/§10.4 y D-051..D-056 (docs, sin cambios de sprites) |
| **Harness** | `tests/qa_acceptance_fase3.gd` (17/17), `tests/qa_acceptance.gd` (F1), `tests/qa_acceptance_fase2.gd` (F2) |
| **Scope** | Solo `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd`; sin producción ni git |

---

## 1. Veredicto y resumen

> **QA Sprites Fase 3 (17/17): APROBADO**

- **6/6 criterios PASS**, 0 FAIL, 0 SKIP. Harness F3 **×2** → `ACEPTACIÓN FASE 3: OK — 6/6`, exit 0.
- **17/17** unidades con `sprite_sheet` válido y **51/51 PNG** de producción cargando en headless como `Texture2D`, con dimensiones reales **64×64** (infantería/ranged), **64×80** (caballería), **64×43** (bombarda/carro húsita).
- **Fallback sintético** verificado: una unidad sin `sprite_sheet` devuelve `frames_of=[]`, `frame_path=''`, `march_frame=0` y no deja hueco; el camino de fallback sigue vivo en `TacticalBattle`/`CloseCombat`.
- **Crécy N1/N2/N3:** N1 coherente (england 703/724); N2 con sprites (2/2 texturizadas en el harness y **17/17 en la sonda independiente**), marcha/facing/mirroring correctos y 5 proyectiles activos; N3 resuelto (england 214/149).
- **Proyectiles D-048** verificados por unidad real: `crossbowmen`→**virote** (350 ms/24 px), `longbowman`/`janissary`/`steppe_cavalry`→**flecha** (500 ms/40 px), `bombarda`→**piedra** (700 ms/56 px).
- **Determinismo intacto:** N1 mismo hash `08cc7cee592e343b` en 2 ejecuciones; F2 harness 6/6 (incluye N2/N3 deterministas).
- **Capturas 7/7** a 1920×1080: 5 unidades a 64 px reales + N2 con sprites + N3 con proyectiles; revisión visual de legibilidad del arma OK.
- **No regresión:** F1 6/6, F2 6/6, `run_all` **1074/0/1**, `validate_data` **5.570 comprobaciones/0 errores**, editor/headless sin ERROR/WARNING.

---

## 2. Evidencia de comandos

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase3.gd` (×2) | **0 / 0** | **6 PASS / 0 FAIL / 0 SKIP**; `ACEPTACIÓN FASE 3: OK`; mismas métricas salvo ms |
| 2 | `--script tests/qa_acceptance.gd` (F1) | **0** | **6/6 PASS** |
| 3 | `--script tests/qa_acceptance_fase2.gd` (F2) | **0** | **6/6 PASS** (N2/N3 deterministas incluidos) |
| 4 | `--script tests/run_all.gd` | **0** | **1074 pasados / 0 fallidos / 1 omitido**; `CI: OK` |
| 5 | `--script tools/validate_data.gd` | **0** | **5.570 comprobaciones**, 0 errores/WARN |
| 6 | `--editor --quit` | **0** | 5 `[DONE]`, 0 ERROR/WARNING |
| 7 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |
| 8 | Sonda independiente 17 unidades | **0** | N2 17/17 texturizadas; mirror oeste; proyectiles N3 por unidad |

Salida íntegra del harness F3 (ejecución canónica):

```text
==============================================================
 The Sovereign's Blood — QA Aceptación Fase 3 (GDD v1.6 §10.3)
 Godot 4.7.2-stable (official) · headless · 2026-11-22
==============================================================
[INFO] Fase 3 — presencia de artefactos:
  data/units.json: true
  res://assets/art/sprites/units: true (51 PNG)
  res://assets/art/sprites/projectiles: true (3 PNG)
  scripts/battle/tactical_battle.gd: true
  scripts/battle/close_combat.gd: true
  scenes/battle/tactical_map.tscn: true
  docs/screenshots: true (51 PNG)
  staging Kimi: true
  10/10 autoloads montados
  [PASS] F3-C1 — Sprites 17/17: 51 PNG de unidades + 3 proyectiles cargan en headless con dimensiones reales :: 17/17 sprite_sheet; 51 PNG; 3 proyectiles; 51 texturas reales (64x64 infantería/ranged, 64x80 caballería, 64x43 bombarda/hussite_war_wagon); anim march [0,1,2] fps=6 loop; anchor=bottom_center facing=E
  [PASS] F3-C2 — Fallback: una unidad sintética SIN sprite_sheet nunca deja hueco (camino vivo) :: unidad sintética SIN sprite_sheet: frames_of=[]; frame_path=''; march_frame=0; projectile={}; marcadores de fallback vivos en TacticalBattle/CloseCombat
  [PASS] F3-C3 — Crécy N1/N2/N3 con sprites: animación/facing/mirroring y proyectiles virote/flecha/piedra :: N1=N1 winner=england bajas=703/724; N2=N2 unidades=2 texturizadas=2; movido attacker_u1_0 → facing=SE mirror=false; auto_resolve OK; proyectiles activos=5; N3=N3 winner=england bajas=214/149
  [PASS] F3-C4 — Determinismo de combate intacto (misma semilla/entradas → mismo informe) :: N1 determinista: hash=08cc7cee592e343b; winner=england bajas=703/724 (2 ejecuciones)
  [PASS] F3-C5 — Capturas 64 px de milicia/ballesteros/arqueros/almogávar/jenízaro + N2/N3 con proyectiles :: 7/7 capturas: sprites_64_milicia.png, sprites_64_ballesteros.png, sprites_64_arqueros.png, sprites_64_almogavar.png, sprites_64_jenizaro.png, sprites_n2.png, sprites_n3.png
  [PASS] F3-C6 — No regresión: 17 unidades, 18 escenas, tests y artefactos F2, scripts compilando :: 17 unidades; 18 escenas; 24 tests; F1/F2/run_all presentes; F2 map_borders/retratos presentes; scripts fallos=0
--------------------------------------------------------------
RESULTADO QA ACEPTACIÓN FASE 3: 6 PASS, 0 FAIL, 0 SKIP (de 6 criterios)
ACEPTACIÓN FASE 3: OK — 6/6 criterios PASS (exit 0)
```

---

## 3. Criterio por criterio

### F3-C1 · 17/17 sprites — PASS
- 17/17 unidades de `units.json` con `sprite_sheet`: 3 frames `res://` cada una (51), `Texture2D` cargadas en headless.
- Dimensiones reales verificadas por tipo: **infantería/ranged 64×64** (militia, scottish_schiltron, almogavar, swiss_pikeman, dismounted_men_at_arms, janissary, arquebusier, crossbowmen, longbowman), **caballería/light_cavalry 64×80** (mounted_sergeants, men_at_arms, light_horseman, steppe_cavalry, mamluk, teutonic_knights), **artillery/special 64×43** (bombarda, hussite_war_wagon).
- `anim.march=[0,1,2]`, fps=6, loop=true; `size` coincide; `anchor=bottom_center`; `facing=E`.
- 51 PNG de producción; 3 proyectiles cargan; `src/` contiene 51 fuentes `_raw_1024` y `.gdignore` (sin importar, D-046).
- Comprobación independiente (PowerShell): 17/17 con `sprite_sheet`, **0 incidencias**; reparto exacto de frames: infantería 18, ranged 9, caballería 12, light_cavalry 6, artillery 3, special 3 = **51**.

### F3-C2 · Fallback sintético — PASS
- `battle_sprites.gd` con `sprite_sheet` vacío: `frames_of=[]`, `frame_path('')`, `march_frame=0`, sin proyectil.
- Marcadores de fallback vivos en `TacticalBattle`/`CloseCombat` (`frames_of`, `sprite_frame_path`, `_sprite_or_null`): una unidad sin hoja no produce hueco vacío.

### F3-C3 · Crécy N1/N2/N3 + animación/mirroring/proyectiles — PASS
- N1: winner=england, bajas 703/724.
- N2: unidades con `sprite_sheet`/`facing`/`mirror`/`moving`/`march_frame`/`sprite_frame_path`; 2/2 texturizadas; movimiento → `facing=SE`, `mirror=false`; `get_projectiles()` con 5 activos; `auto_resolve` OK.
- N3: winner=england, bajas 214/149.
- **Sonda independiente con las 17 unidades** (armadas en un solo combate N2): `unidades=17/17`, `texturizadas=17/17`, `campos_ok=17/17`; movimiento al oeste de `swiss_pikeman` → `facing=W`, `mirror=true`; `auto_resolve=true`.
- **Proyectiles reales N3 por unidad:** crossbowmen → `virote/proyectil_virote.png/350ms/arc24`; longbowman, janissary y steppe_cavalry → `flecha/proyectil_flecha.png/500ms/arc40`; bombarda → `piedra/proyectil_piedra.png/700ms/arc56` (D-048). Coincide con `PROJECTILE_BY_UNIT` y las capturas N2/N3.

### F3-C4 · Determinismo — PASS
- N1 `resolve_delegated` 2 ejecuciones → hash idéntico `08cc7cee592e343b` (england 703/724).
- F2 harness 6/6 (N2/N3 deterministas); activar animación/proyectiles no altera el resultado (proyectiles deterministas por tiempo, sin RNG de combate).

### F3-C5 · Capturas 7/7 — PASS
- Presentes a **1920×1080**: `sprites_64_milicia.png`, `sprites_64_ballesteros.png`, `sprites_64_arqueros.png`, `sprites_64_almogavar.png`, `sprites_64_jenizaro.png`, `sprites_n2.png`, `sprites_n3.png`.
- Revisión visual (REA §6): a 64 px reales se distinguen lanza/pica (milicia), ballesta con gafa (ballesteros), arco largo (arqueros), espada y escudo (almogávar), arco compuesto (jenízaro); cada captura incluye detalle 8× NEAREST. N2 muestra sprites sobre hexes (arqueros/piquero escocés); N3 muestra bombarda y arquero con proyectil (piedra/virote) en vuelo.

### F3-C6 · No regresión — PASS
- 17 unidades, 18 escenas, 24 tests, F1/F2/run_all presentes, artefactos F2 (mapa/retratos) intactos, 0 scripts sin compilar.
- Batería externa: F1 6/6, F2 6/6, run_all **1074/0/1**, validate **5.570/0**, editor/headless exit 0 sin ERROR/WARNING.

---

## 4. Observaciones y límites

- **C3 del harness** usa N1/N2 representativos (longbowman/men_at_arms) y comprueba el mapeo D-048 de los 5 disparos; la cobertura de las **17 unidades en N2** se hizo con **sonda independiente** (17/17 texturizadas/campos). No es un fallo; se documenta la separación harness/sonda.
- **Idle/ataque/impacto/muerte** no forman parte de esta P1 (paquete v2 solo marcha; D-049): no se evalúan; quedan solicitados a Kimi.
- **64×43** panorámico de bombarda/carro verificado por dimensiones reales y capturas; el render ancla `bottom_center`/centra la celda (contrato §4), sin recortes observados.
- Benchmark GPU/raster no aplica a esta verificación de assets; el render se validó con capturas reales 1920×1080.
- `staging` conserva la entrega original; la producción vive en `assets/art/sprites/` (51+3) y `src/` (51 raw, no importado).

---

## 5. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness F3 17/17 | `tests/qa_acceptance_fase3.gd` |
| Plan QA F3 | `docs/qa/fase3_plan.md` |
| Este informe | `docs/qa/fase3_sprites_report.md` |
| Registro acumulativo | `docs/issues.md` (§13 baseline, §14 verificación final) |
| Capturas | `docs/screenshots/sprites_64_*.png`, `sprites_n2.png`, `sprites_n3.png` |

*Fin del informe QA Sprites Fase 3 (17/17) — AG-4. Veredicto: **APROBADO**.*

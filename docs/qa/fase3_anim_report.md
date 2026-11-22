# Informe de QA — Fase 3.1: Animación de combate (17×13, N3, capturas)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Veredicto** | **QA Animación Fase 3.1: APROBADO** — 6/6 criterios PASS, 0 FAIL/SKIP |
| **Alcance** | GDD v1.8 §10.3; addendum 4.1 (`docs/architecture_contracts_fase3.md`); D-049/D-064 |
| **HEAD verificado** | `8ae9621` (AG-5 anim assets, AG-2 datos/motor, AG-3 render N3) |
| **Harness** | `tests/qa_acceptance_fase3_anim.gd` (6 criterios) + sprites/tiles/final Fase 3/F1/F2 |
| **Scope** | Solo `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd`; sin producción ni git |

---

## 1. Veredicto y resumen

> **QA Animación Fase 3.1: APROBADO**

| Criterio | Estado | Evidencia |
|---|---|---|
| A1 17×13 frames cargan | **PASS** | 221 PNG producción (51 march + 170 anim) y 221 raw; 221 `Texture2D`; metadata 13 frames por unidad |
| A2 Timing | **PASS** | `attack_2` índice 6 a **111,1 ms**; reacción hit/dead a **222,2 ms**; attack→idle; dead persiste (`death_hold`); mirror W/E |
| A3 Secuencia N3 real | **PASS** | idle→attack→attack_2(111,1)→hit(222,2) y →dead(222,2)+death_hold; proyectil virote con timing; mirroring |
| A4 Determinismo | **PASS** | Dos secuencias idénticas (mismos estados/tiempos); sin RNG |
| A5 Capturas | **PASS** | `anim_idle.png`, `anim_n3_attack_sequence.png`, `anim_n3_hit_death.png` 1920×1080 |
| A6 No regresión | **PASS** | Sprites 17/17, tiles 12/12, escenarios, F1/F2, 18 escenas, scripts |

**Harness de animación ×2 → 6/6 PASS exit 0.** La secuencia se probó en **CloseCombat real** (no mock), con `play_order`+`enemy_respond`+`tick_animation`; la reacción se programa en `attack_2` y el daño lógico no se retrasa (D-064).

---

## 2. Evidencia de comandos

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase3_anim.gd` (×2) | **0 / 0** | **6/6 PASS** |
| 2 | `--script tests/qa_acceptance_fase3.gd` (sprites 13 frames) | **0** | **6/6 PASS** (C1/C2 actualizados) |
| 3 | `--script tests/qa_acceptance_tiles.gd` | **0** | **7/7 PASS** |
| 4 | `--script tests/qa_acceptance_fase3_final.gd` | **0** | **7/7 PASS** |
| 5 | `--script tests/qa_acceptance.gd` (F1) | **0** | **6/6 PASS** |
| 6 | `--script tests/qa_acceptance_fase2.gd` (F2) | **0** | **6/6 PASS** |
| 7 | `--script tests/run_all.gd` | **0** | **1438 / 0 / 1**; `CI: OK` |
| 8 | `--script tools/validate_data.gd` | **0** | **11 datasets / 7 schemas, 11.545 comprobaciones, 0 errores/WARN** |
| 9 | `--editor --quit` | **0** | 6 `[DONE]`, 0 ERROR/WARNING |
| 10 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |

Salida resumida del harness de animación:
```text
[INFO] Fase 3.1 — presencia de artefactos:
  PNG unidades: 221; raw src: 221
  scripts/battle/close_combat.gd: true
  docs/screenshots: 61 PNG
  [PASS] A1 — 17/17 unidades × 13 frames = 221 texturas; 221 producción + 221 raw; anim march/idle/attack/hit/death + fps_attack=9/hit=8/death=6/death_hold
  [PASS] A2 — attack_2 index=6 a 111,1 ms; ataque=111,1 ms; reacción=222,2 ms; dead persiste/death_hold; attack→idle; mirror W=true/E=false
  [PASS] A3 — hit: idle→attack→attack_2(111,1)→hit(222,2), proyectil virote, mirroring; dead: idle→attack→attack_2(111,1)→dead(222,2)+death_hold
  [PASS] A4 — 2 secuencias idénticas
  [PASS] A5 — 3/3 capturas 1920x1080
  [PASS] A6 — 12 tiles; 18 escenas; harness F3/tiles/final presentes; scripts fallos=0
RESULTADO QA ANIMACIÓN FASE 3.1: 6 PASS, 0 FAIL, 0 SKIP
ACEPTACIÓN ANIMACIÓN FASE 3.1: OK — 6/6 criterios PASS (exit 0)
```

---

## 3. Criterio por criterio

### A1 · 17×13 frames
- `data/units.json`: 17/17 unidades con `frames` de **13 entradas** (0-2 march, 3-4 idle, 5-8 attack, 9-10 hit, 11-12 death).
- **221 PNG** de producción: **51 march + 170 animación** (idle 2, attack 4, hit 2, death 2 por unidad = 10×17=170).
- **221 raw** en `src/` con `.gdignore`; 221 `Texture2D` cargan en headless; dimensiones **64×64 / 64×80 / 64×43** por tipo.
- `anim` con arrays exactos, `fps_attack=9`, `fps_hit=8`, `fps_death=6`, `death_hold=true`, loop en marcha/idle.

### A2 · Timing y estados
- `attack_impact_index=6`, `attack_impact_ms=111,1`, `attack_frame_ms=111,1`, `reaction_delay_ms=222,2`.
- `state_frame_path(attack,112 ms)` → `attack_2` (el límite exacto 111,1 cae en el borde de frame por `floor`, ventana [111,1;222,2] correcta).
- `state_after_elapsed(dead, 5 s)` = dead (death_hold); attack agotado → idle; `mirror_for("W")=true`, `("E")=false`.

### A3 · Secuencia real N3 (CloseCombat)
- **idle** inicial (frame idle), **attack** tras `play_order`+`enemy_respond`, **attack_2** a 111,1 ms, **hit** a 222,2 ms en defensor superviviente; **dead** a 222,2 ms en defensor que muere, **death_hold** tras 5 s con frame `_death_`.
- Proyectil **virote** presente con `started_ms` + `impact_ms=111,1` (timing N3); sprite `proyectil_virote.png`; mirroring atacante E=false, defensor W=true.
- Observación de API: N3 `CloseCombat` expone `started_ms`+`impact_ms` en vez de un único `launch_ms`; el harness acepta ambos y verifica el timing de impacto. N2 `TacticalBattle` sí expone `launch_ms`.

### A4 · Determinismo
- La secuencia se ejecutó 2 veces con misma semilla/cartas: estados y tiempos idénticos; la animación no consume RNG (`tick_animation` solo avanza reloj).

### A5 · Capturas
- `anim_idle.png`: N3 con unidades en idle, campo de tiles, HUD/cartas.
- `anim_n3_attack_sequence.png`: unidades en pose de ataque y **proyectil visible** entre ambas, ronda 2, daño resuelto.
- `anim_n3_hit_death.png`: impacto/muerte con resultado de ronda y bajas.
- Todas **1920×1080**; hashes abajo.

### A6 · No regresión
- Sprites 17/17 (F3 6/6, ahora 13 frames), tiles 12/12 (7/7), escenarios 7/7, F1/F2 6/6, run_all 1438, validate 11/7 0 WARN, editor/headless 0.

---

## 4. Conteos y hashes

| Elemento | Valor |
|---|---|
| Animación producción | **170 PNG** (17×10) |
| Animación raw | **170 PNG** |
| Marcha producción/raw | 51 / 51 |
| Total unidades producción/raw | **221 / 221** |
| `scenes/battle/close_combat.tscn` | `7D77DC29E98B6234` (SHA-256 16) |
| `scenes/battle/tactical_map.tscn` | `3719D3966F7ABB0D` |
| `data/units.json` | `3B44B4066998452A` |
| `data/schema/units.schema.json` | `E3CA6E5F31970BC4` |
| `anim_idle.png` | `57D3AE78CF1E04D6` |
| `anim_n3_attack_sequence.png` | `532E5D473044D116` |
| `anim_n3_hit_death.png` | `BD2DB9A12271FEB1` |

---

## 5. Harness de sprites actualizado (13 frames)

`tests/qa_acceptance_fase3.gd` F3-C1/C2 se actualizaron al contrato 4.1 sin relajar la aceptación:
- C1 exige **13 frames/animación completa/fps/death_hold**, **221 producción + 221 raw**, dimensiones reales y `Texture2D`.
- C2 mantiene el fallback con unidad sintética sin hoja; se sustituyeron los marcadores de código obsoletos (`frames_of`/`sprite_frame_path`) por los vigentes (`_sprite_or_null`, `anim_state`, `state_frame_path`).
- Resultado: **6/6 PASS**, sin regresión.

---

## 6. Observaciones y riesgos residuales

1. **N3 vs N2 timing de proyectil:** N3 expone `started_ms`+`impact_ms` (equivalente funcional a `launch_ms`); N2 expone `launch_ms`. Documentado; no requiere cambio de producción.
2. **Ventana exacta de `attack_2`:** el límite 111,1 ms cae en el borde de frame por `floor`; la ventana contractual [111,1;222,2] es correcta y el harness pruebe 112 ms + `impact_ms` exacto. No es defecto.
3. **Render N3:** verificado con sonda real y capturas; no se mide GPU/raster en headless (limitación conocida).
4. **Assets externos:** la animación de combate ya está entregada (170+170); no quedan dependencias de Kimi para este módulo. Estado de tags: `fase-0/1/2` existen; **`fase-3.1` pendiente** de AG-0.

---

## 7. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness animación | `tests/qa_acceptance_fase3_anim.gd` |
| Harness sprites actualizado | `tests/qa_acceptance_fase3.gd` |
| Este informe | `docs/qa/fase3_anim_report.md` |
| Registro | `docs/issues.md` §19 |
| Capturas | `docs/screenshots/anim_idle.png`, `anim_n3_attack_sequence.png`, `anim_n3_hit_death.png` |

*Fin del informe QA Animación Fase 3.1 — AG-4. Veredicto: **APROBADO**.*

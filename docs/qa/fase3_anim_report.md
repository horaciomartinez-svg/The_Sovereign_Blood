# Informe de QA — Animación de combate v1.8.1 (Fase 3.2, delta)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-22 |
| **Veredicto** | **QA Animación Fase 3.2 (v1.8.1): APROBADO** — 6/6 criterios PASS, 0 FAIL/SKIP |
| **Alcance** | GDD v1.8.1 §10.3; addendum 4.2 (`architecture_contracts_fase3.md`); D-065 |
| **HEAD verificado** | `9e97a06` (AG-5 delta assets, AG-2 datos/motor 13/15, AG-3 render N3/capturas) |
| **Harness** | `tests/qa_acceptance_fase3_anim.gd` actualizado a v1.8.1 (×2) + `qa_acceptance_fase3.gd` (C1 235 frames) |
| **Scope** | Solo `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd`; sin producción ni git |

---

## 1. Veredicto y resumen

> **QA Animación Fase 3.2 (v1.8.1): APROBADO**

| Criterio | Estado | Evidencia |
|---|---|---|
| A1 13/15 frames, 235 assets | **PASS** | 10×13 + 7×15 = **235** `Texture2D`; **235 producción + 235 raw**; 82 attack (10×4+7×6), 34 impact, **0 hit** |
| A2 Timing v1.8.1 | **PASS** | `attack_4` índice **8** a **333,3 ms**; reacción **impact 444,4 ms**; ranged **6 cuadros = 666,7 ms**; death_hold; mirror |
| A3 N3 real | **PASS** | idle→attack(6)→attack_4(333,3)→**impact(444,4)**/dead; proyectil **launch_ms=333,3**; mirroring |
| A4 Determinismo | **PASS** | 2 secuencias idénticas; sin RNG |
| A5 Capturas | **PASS** | 4/4 1920×1080: idle, attack_sequence (6 cuadros+proyectil), impact_death, death_hold |
| A6 No regresión | **PASS** | Sprites 6/6, tiles 7/7, final Fase 3 7/7, F1/F2 6/6, escenas/scripts |

---

## 2. Evidencia de comandos

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase3_anim.gd` (×2) | **0 / 0** | **6/6 PASS** |
| 2 | `--script tests/qa_acceptance_fase3.gd` (C1/C2 v1.8.1) | **0** | **6/6 PASS**; C1 235 frames |
| 3 | `--script tests/qa_acceptance_tiles.gd` | **0** | **7/7 PASS** |
| 4 | `--script tests/qa_acceptance_fase3_final.gd` | **0** | **7/7 PASS** |
| 5 | `--script tests/qa_acceptance.gd` (F1) | **0** | **6/6 PASS** (save/load) |
| 6 | `--script tests/qa_acceptance_fase2.gd` (F2) | **0** | **6/6 PASS** |
| 7 | `--script tests/run_all.gd` | **0** | **1469 / 0 / 1**; `CI: OK` |
| 8 | `--script tools/validate_data.gd` | **0** | **11 datasets / 7 schemas, 11.641 comprobaciones, 0 errores/WARN** |
| 9 | `--editor --quit` | **0** | 6 `[DONE]`, 0 ERROR/WARNING |
| 10 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |

Salida resumida del harness de animación v1.8.1:
```text
[INFO] Fase 3.1 — PNG unidades: 235; raw src: 235; docs/screenshots: 62 PNG
  [PASS] A1 — 10×13 + 7×15 = 235 texturas; 235 producción + 235 raw; anim march/idle/attack/impact/death (sin hit) + fps_attack=9/impact=8/death=6/death_hold
  [PASS] A2 — attack_4 index=8 a 333,3 ms; ataque=111,1 ms/cuadro; reacción=444,4 ms; ranged 6 cuadros=666,7 ms; impact/death_hold; mirror W/E
  [PASS] A3 — impact: idle→attack(6 cuadros)→attack_4(333,3)→impact(444,4); proyectil virote launch_ms=333,3; mirroring OK; dead: …→dead(444,4)+death_hold
  [PASS] A4 — 2 secuencias idénticas
  [PASS] A5 — 4/4 capturas 1920x1080
  [PASS] A6 — 12 tiles; 18 escenas; harness F3/tiles/final presentes; scripts fallos=0
RESULTADO QA ANIMACIÓN FASE 3.1: 6 PASS, 0 FAIL, 0 SKIP
ACEPTACIÓN ANIMACIÓN FASE 3.1: OK — 6/6 criterios PASS (exit 0)
```

---

## 3. Pillow sobre el paquete delta (`Anim_Combate_Rango_Artilleria_TSB.zip`)

Ejecutado con Python 3 + **Pillow 12.3.0** (zipfile + Image), sin modificar el ZIP:

| Comprobación | Resultado |
|---|---|
| PNG totales en el ZIP | **119** (76 producción + 42 raw + 1 hoja de contacto) |
| **76 delta de producción** | **42 `attack_1..6`** (7 unidades ranged/artillería) + **34 `impact_1/2`** (17 unidades) |
| Raw | **42** `attack_1..6` (originales 1024/1536 del delta de ataque) |
| Modo/alfa | **76 RGBA**; alfa real con `alpha_min=0` en 76/76; hoja de contacto RGB excluida |
| Dimensiones 512-wide | **42× 512×512**, **18× 512×640**, **16× 512×341**; 0 dims inesperadas |
| Hoja de contacto | `_hoja_contacto_rango_artilleria.png` 1218×1222 RGB |

**Conclusión Pillow:** los 76 archivos delta cumplen 512-wide, RGBA con transparencia y conteos 42 attack / 34 impact; 42 raw presentes. Coincide con lo integrado en `assets/art/sprites/units/` (**235 producción = 76 delta + 159 previos; 235 raw**).

---

## 4. Criterio por criterio

### A1 · 13/15 frames y 235 assets
- `units.json`: **10 unidades 13 frames** (shock) + **7 unidades 15 frames** (ranged/artillería: crossbowmen, longbowman, janissary, steppe_cavalry, arquebusier, bombarda, hussite_war_wagon).
- 13f: attack [5,6,7,8], impact [9,10], death [11,12]; 15f: attack [5..10] (6 cuadros), impact [11,12], death [13,14].
- **Sin `hit`**; `impact` con `fps_impact=8`; `fps_attack=9`, `fps_death=6`, `death_hold=true`.
- **235 PNG producción + 235 raw**; 235 `Texture2D` cargan en headless; 82 attack prod (10×4+7×6), 34 impact, 0 hit; dims 64×64/64×80/64×43.
- F3-C1 actualizado a 13/15 y 235; sigue 6/6.

### A2 · Timing
- `attack_impact_index=8` (attack_4), `attack_impact_ms=333,3`, `attack_frame_ms=111,1`, `reaction_delay_ms=444,4`.
- `state_duration_ms(attack)` = **666,7 ms** en ranged (6 cuadros), **444,4 ms** en shock (4 cuadros); ataque→idle; dead persiste (`death_hold`); impacto frame `_impact_1`.
- Ventana exacta: 333,3 cae en borde de frame por floor; el harness usa 334 ms + `impact_ms` exacto; ventana [333,3;444,4] correcta.

### A3 · N3 real (CloseCombat, sin mocks)
- idle→attack con **6 cuadros** → **attack_4 a 333,3 ms** → **impact a 444,4 ms** (superviviente) o **dead(444,4)+death_hold** (muere).
- Proyectil **virote** con `launch_ms=333,3` (D-065: sale en attack_4); defensor impact/dead en 444,4; mirroring atacante E=false/defensor W=true.
- Sonda ejecutada dos veces con misma secuencia: estados/tiempos idénticos.

### A4 · Determinismo
- Animación/proyectiles consumen solo reloj (`tick_animation`), sin RNG; dos ejecuciones idénticas.

### A5 · Capturas
- `anim_idle.png` (idle), `anim_n3_attack_sequence.png` (**6 cuadros + proyectil en vuelo**), `anim_n3_impact_death.png` (impact/death + resultado), `anim_n3_death_hold.png` (death_hold). Todas 1920×1080; revisadas visualmente.

### A6 · No regresión
- Sprites 6/6 (235 frames), tiles 7/7, final Fase 3 7/7, F1/F2 6/6, 18 escenas, 0 scripts sin compilar, save/load F1/F2 OK.

---

## 5. Conteos y hashes

| Elemento | Valor |
|---|---|
| Producción / raw unidades | **235 / 235** |
| Attack producción | **82** (10×4 + 7×6) |
| Impact producción | **34** (17×2) |
| Hit producción | **0** (eliminado en v1.8.1) |
| Delta ZIP | 119 PNG: 76 prod (42 attack +34 impact) +42 raw +hoja |
| `scenes/battle/close_combat.tscn` | `7D77DC29E98B6234` |
| `scenes/battle/tactical_map.tscn` | `3719D3966F7ABB0D` |
| `data/units.json` | `3EE18D31286ABD32` |
| `data/schema/units.schema.json` | `64DDB41E43A6EC96` |
| `anim_idle.png` | `57D3AE78CF1E04D6` |
| `anim_n3_attack_sequence.png` | `E038950146D32EF3` |
| `anim_n3_impact_death.png` | `3E9799BFA1B213AC` |
| `anim_n3_death_hold.png` | `E4E2C80A675CA155` |

---

## 6. Observaciones y riesgos residuales

1. **Sin `hit`:** v1.8.1 sustituye `hit` por `impact`; el harness verifica que no queden claves `hit` ni frames `_hit_`.
2. **Ranged 6 cuadros:** `attack_4` (índice 8) es el disparo; ataque completo 666,7 ms; shock 4 cuadros/444,4 ms. Correcto.
3. **Ventana de frame:** 333,3/444,4 caen en bordes por `floor`; se verifica con 334 ms y `impact_ms` exacto. No es defecto.
4. **Pillow:** el ZIP se inspeccionó sin modificar; la hoja de contacto es RGB y se excluye del cómputo RGBA.
5. **Tags:** `fase-0/1/2/3/3.1` existen; **`fase-3.2` pendiente** de AG-0.

---

## 7. Artefactos

| Artefacto | Ruta |
|---|---|
| Harness animación v1.8.1 | `tests/qa_acceptance_fase3_anim.gd` |
| Harness sprites actualizado | `tests/qa_acceptance_fase3.gd` |
| Este informe | `docs/qa/fase3_anim_report.md` |
| Registro | `docs/issues.md` §20 |
| Capturas | `docs/screenshots/anim_idle.png`, `anim_n3_attack_sequence.png`, `anim_n3_impact_death.png`, `anim_n3_death_hold.png` |

*Fin del informe QA Animación Fase 3.2 (v1.8.1) — AG-4. Veredicto: **APROBADO**.*

# Contratos de integración — Fase 3 (sprites de unidades núcleo)

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-22 |
| **Autoridad** | AG-0 (Coordinator). Complementa GDD v1.6 §10.3, §10.2 y §12; ante conflicto manda el GDD |
| **Partes** | AG-5 (assets), AG-2 (datos+lógica), AG-3 (render N2/N3), AG-4 (QA) |
| **Regla** | Ningún agente edita este archivo; cambios vía AG-0 y `docs/decisions.md` |

Alcance: **PRIORIDAD 1 de Fase 3** — integrar el paquete de sprites de Kimi (6 unidades núcleo + 3
proyectiles) en datos, lógica de batalla N2/N3 y render, con fallback heráldico intacto para las 11
unidades sin sprite. El resto de Fase 3 (escenarios 1402/1453, retratos nuevos, animaciones completas,
tiles, música) tiene su plan en `docs/STATUS.md` §11 y se ejecuta después.

---

## 1. Assets (AG-5)

```
assets/art/sprites/
├── units/
│   ├── <unit_id>_march_1.png    # producción 64×64 (infantería) o 64×80 (caballería), RGBA
│   ├── <unit_id>_march_2.png
│   ├── <unit_id>_march_3.png
│   └── src/                     # fuentes 512×512 / 512×640 (originales Kimi), NO importadas
│       ├── .gdignore            # evita que Godot importe src/
│       └── <unit_id>_march_{1,2,3}.png
└── projectiles/
    ├── proyectil_virote.png     # 256×256 (entrega Kimi; se escala en render)
    ├── proyectil_flecha.png
    └── proyectil_piedra.png
```

- Reescalado **LANCZOS** a 64×64 (infantería/ranged) y 64×80 (caballería: `men_at_arms`,
  `light_horseman`). El ancla es pies en borde inferior y centro horizontal: la figura debe quedar
  centrada al reescalar (no recortar pies).
- `src/` contiene los PNG 512 entregados; **no se importan al proyecto** (`.gdignore`). Los originales
  1024 no se versionan (permanecen en el paquete del usuario).
- Fondo RGBA transparente, sin sombra de suelo; facing E.
- Verificación obligatoria: dimensiones, modo RGBA, 18 PNG de producción, 18 fuentes, 3 proyectiles.

## 2. `data/units.json` — campo opcional `sprite_sheet` (AG-2)

Formato exacto (GDD v1.6 §10.3), solo en las 6 unidades núcleo:

```json
"sprite_sheet": {
  "frames": ["res://assets/art/sprites/units/militia_spearman_march_1.png",
             "res://assets/art/sprites/units/militia_spearman_march_2.png",
             "res://assets/art/sprites/units/militia_spearman_march_3.png"],
  "anim": {"march": [0, 1, 2], "fps": 6, "loop": true},
  "size": [64, 64],            // [64, 80] en men_at_arms y light_horseman
  "anchor": "bottom_center",
  "facing": "E"
}
```

- Solo las 6 unidades núcleo (`militia_spearman`, `swiss_pikeman`, `crossbowmen`, `longbowman`,
  `men_at_arms`, `light_horseman`). Las 11 restantes **sin** `sprite_sheet` → fallback heráldico.
- `data/schema/units.schema.json`: `sprite_sheet` opcional con `frames` (array 1-3 strings `res://`),
  `anim` (march array de enteros, fps número, loop bool), `size` (array 2 enteros), `anchor`/`facing`
  strings. No requerido. `validate_data.gd` sigue en 0 errores.

## 3. Lógica de batalla N2/N3 (AG-2)

`TacticalBattle`/`CloseCombat` exponen estado de animación y proyectiles **sin instanciar nodos de UI**:

- `get_units()` (entradas aditivas por unidad):
  - `sprite_sheet`: el dict de `units.json` o `null` (fallback).
  - `facing`: `"E" | "SE" | "S" | "SW" | "W" | "NW" | "N"` según último movimiento/ataque.
  - `mirror`: bool — true si el sprite debe espejarse horizontalmente.
  - `moving`: bool; `march_frame`: int 0..2 (ciclo de marcha mientras `moving`).
  - `sprite_frame_path`: ruta `res://` del cuadro actual (o `""` si fallback).
- Regla de orientación: **base E/SE/S**; **espejo W/SW/NW/N** (convención GK2 por mirroring; el
  asset base mira a E). Al moverse, `march_frame` avanza a 6 fps con ciclo 3 y `loop=true`; en reposo,
  cuadro 0.
- Proyectiles (capa de render aparte): al atacar una unidad a distancia se emite un proyectil
  `{type, sprite, from, to, duration_ms, arc_height, ballistic}` desde el atacante al defensor:
  - `virote` → `crossbowmen` (`proyectil_virote.png`, 350 ms, arco 24 px),
  - `flecha` → `longbowman` (`proyectil_flecha.png`, 500 ms, arco 40 px),
  - `piedra` → `bombarda` (`proyectil_piedra.png`, 700 ms, arco 56 px).
  - Trayectoria paramétrica `t∈[0,1]`: x lineal, `y = y0 + (y1-y0)·t − arc_height·sin(π·t)`.
    Solo determinista por tiempo (no consume RNG de combate).
- API de consulta: `get_projectiles() -> Array[Dictionary]` (proyectiles activos con `t`/`elapsed_ms`)
  y/o señal `projectile_fired(payload)`. La UI interpola posiciones.
- Los test de batalla deben seguir verdes (716+) y el combate determinista no cambia resultados por
  activar animación.

## 4. Render en N2/N3 (AG-3)

- `scenes/battle/tactical_map.tscn` y `close_combat.tscn`: por unidad, si `sprite_sheet` existe →
  `Sprite2D` con `texture` del cuadro actual, `centered=false` + `offset` para ancla
  **bottom_center**, `flip_h = mirror`; si no → marcador heráldico existente (fallback).
- Animación de marcha desde `moving/march_frame` (6 fps, ciclo 3); al atacar, cuadro de marcha 0 +
  proyectil.
- **Proyectiles en `Node2D` separado por encima de las unidades** (z_index superior), con los sprites
  de `assets/art/sprites/projectiles/`, tamaño legible (virote/flecha ≈ 12-20 px, piedra ≈ 8-12 px a
  zoom 1) y trayectoria balística del §3.
- Capturas obligatorias a tamaño real 64 px (sin zoom) de `militia_spearman`, `crossbowmen` y
  `longbowman` demostrando que el arma se reconoce en silueta; además una captura N2 y una N3 con
  sprites y proyectiles. Guardar en `C:\Proyectos\TSB\.ui_check_f3\` (AG-0 copia a docs).
- Smoke: 18 escenas instanciables; fallback para las 11 unidades sin sprite.

## 5. QA (AG-4)

Criterios para esta integración (se suman a los de Fase 3 §12):
1. Las 6 unidades tienen `sprite_sheet` válido (3 frames existentes, `size` y `anim` correctos) y
   cargan sin error en headless (`ResourceLoader.exists` + `load()` + textura != null).
2. Las 11 restantes no tienen `sprite_sheet` y siguen usando fallback (sin huecos).
3. Crécy N1 y simulación N2/N3 con las unidades nuevas sin crash; animación/facing/mirroring y
   proyectiles coherentes; determinismo de combate intacto.
4. Capturas de milicia/ballesteros/arqueros a 64 px + N2/N3 con proyectiles; revisión de legibilidad
   del arma (criterio REA §6).
5. `run_all.gd` verde, `validate_data.gd` 0 errores, editor/headless sin ERROR/WARNING, no regresión.

## 6. Propiedad de archivos (PRIORIDAD 1)

| Owner | Write scopes |
|---|---|
| **AG-5** | `assets/art/sprites/**` |
| **AG-2** | `data/units.json`, `data/schema/units.schema.json`, `scripts/battle/**`, `scripts/autoload/**`, `tests/test_*.gd`, `tests/run_all.gd` |
| **AG-3** | `scenes/**`, `scripts/ui/**` |
| **AG-4** | `docs/issues.md`, `docs/qa/**`, `tests/qa_*.gd` |
| **AG-0** | `docs/**`, commits/push, capturas/copia desde `.ui_check_f3/` |

## 7. Aceptación (GDD §10.3 v1.6)

- Cada unidad del Escenario 1 con sprite integrado es identificable en silueta a 64 px (milicia con
  lanza/pica, ballesteros con ballesta visible, arqueros con arco).
- Animación de ataque con proyectil visible para ballesteros/arqueros/bombardas (capa separada).
- Todas las hojas referenciadas en `units.json` cargan sin error en CI headless.
- Capturas de las 3 unidades de ejemplo en `docs/screenshots/`.

---

## 8. Addendum 2.1 — Paquete v2: 17 unidades (2026-11-22, D-044)

Este addendum **sustituye los conteos y tamaños de §1-§2** tras la entrega del paquete v2 de Kimi
(106 MB). GDD v1.6 §10.3 actualizado y decisiones D-044…D-050 son la referencia.

- **Producción:** 51 PNG (`17 unidades × march_1/2/3`) en `assets/art/sprites/units/`:
  - infantería/ranged (9 unidades) → **64×64**;
  - caballería (6) → **64×80**;
  - `bombarda` y `hussite_war_wagon` → **64×43** (panorámico 512×341 / 1536×1024 raw; proporción).
- **Fuentes:** `assets/art/sprites/units/src/` = **51 originales `_raw_1024`** (1024², 1024×1280,
  1536×1024) con `.gdignore`; ya no se almacenan los 512 como fuente (D-046). Tamaño ~91,6 MB.
- **ID:** archivos `bombard_*` del paquete renombrados a `bombarda_*` (dataset `bombarda`, D-045).
- **`sprite_sheet`:** las **17** unidades de `units.json`; `size` [64,64] / [64,80] / [64,43];
  resto igual (frames 3, anim march [0,1,2] fps 6 loop, anchor bottom_center, facing E).
- **Proyectiles:** virote→`crossbowmen`; flecha→`longbowman`/`janissary`/`steppe_cavalry`;
  piedra→`bombarda` (D-048).
- **Fallback:** todas las unidades del dataset tienen sprite; el fallback se prueba con una unidad
  sintética sin `sprite_sheet` y debe seguir sin huecos.
- **QA:** 17/17 hojas con frames cargando headless (64×64/64×80/64×43 reales), Crécy N1 + N2/N3,
  capturas a 64 px de `militia_spearman`, `crossbowmen`, `longbowman`, `almogavar` y `janissary`,
  más N2/N3 con proyectiles (D-050).
- **Nota de entrega:** el README v2 de Kimi omite `crossbowmen`/`longbowman` en sus tablas pero los
  archivos existen (51 = 17×3); se integran igualmente. Varias fuentes llegan con el arma/figura
  tocando el borde del lienzo (recorte del artista); no hay margen recuperable sin regenerar y no
  bloquea el render.

---

## 9. Addendum 4.1 — Animación de combate (GDD v1.8 §10.3, D-049/D-064)

Set entregado por Kimi: `Anim_Combate_TSB.zip` — **170 PNG** (17 unidades × 10 cuadros) + 170 `_raw`
1024/1536 + `_hoja_contacto_anim.png` + README.

- **Cuadros:** `<unit_id>_idle_{1,2}`, `<unit_id>_attack_{1,2,3,4}`, `<unit_id>_hit_{1,2}`,
  `<unit_id>_death_{1,2}`; RGBA 512-wide (512×512 / 512×640 / 512×341), ancla `bottom_center`, facing E
  con espejo en motor; reescalado LANCZOS 64×64/64×80/64×43.
- **`sprite_sheet.frames`:** 13 entradas — índices 0-2 marcha, 3-4 idle, 5-8 ataque (attack_2 = impacto),
  9-10 hit, 11-12 death.
- **`sprite_sheet.anim`:** `{"march":[0,1,2],"idle":[3,4],"attack":[5,6,7,8],"hit":[9,10],
  "death":[11,12],"fps":6,"loop":true,"fps_attack":9,"fps_hit":8,"fps_death":6,"death_hold":true}`.
  `loop` aplica a marcha/idle; ataque/impacto/muerte una vez; `death_hold` persiste el último cuadro.
- **Motor N3:** estado por unidad `idle|march|attack|hit|dead`; ataque dispara una vez y el impacto
  (`attack_2`) se sincroniza con la resolución de daño D-048 y el proyectil separado; `hit` al recibir
  daño; `death` + `death_hold` al morir; mirroring oeste; sin consumir RNG.
- **QA:** 17/17 unidades × 13 frames cargan en headless; secuencia ataque/impacto/muerte visible en una
  batalla N3; capturas en `docs/screenshots/`; `run_all`/`validate_data` verdes; informe
  `docs/qa/fase3_anim_report.md`.
- **Ownership:** AG-5 assets (`assets/art/sprites/**`), AG-2 datos/motor (`data/units.json`, schema,
  `scripts/battle/**`, tests), AG-3 render N3 (`scenes/**`, `scripts/ui/**`), AG-4 QA, AG-0 docs/git.

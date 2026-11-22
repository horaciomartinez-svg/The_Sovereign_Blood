# Addendum 3.1 — Tiles del campo de batalla N3 (GDD v1.7 §10.4)

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-22 |
| **Autoridad** | AG-0; complementa GDD v1.7 §10.4 y el contrato fase3 |
| **Partes** | AG-3 (assets+render+generador), AG-2 (tabla+reglas), AG-4 (QA) |

## A. Assets (AG-3)

```
assets/art/battle/tiles/
├── tile_pastizal.png, tile_pastizal_arbustos.png, tile_pradera.png
├── tile_rio.png, tile_puente.png, tile_puente_villa.png
├── tile_colina.png, tile_bosque.png, tile_montana.png
├── tile_villa.png, tile_villa_calle.png, tile_camino.png   # 12 PNG 512×512 (importar 512)
└── src/                      # 12 originales _raw_1024 (1024×1024), con .gdignore (NO importar)
```

- Producción a **512×512** (los maestros del paquete); en pantalla N3 se dibujan a **128×128**
  (sprites de unidad 64×64 a ×2), escalables ×2/×3 sin pérdida.
- `src/` con los 12 `_raw_1024` + `.gdignore`.
- Hoja de contacto `_hoja_contacto_tiles.png` → copia a `C:\Proyectos\TSB\.ui_check_f3\` (AG-0 la
  lleva a docs).
- Rotación: `tile_rio`, `tile_puente`, `tile_puente_villa` y `tile_camino` se dibujan con banda
  **horizontal**; el motor las rota **90°** para el sentido vertical (no duplicar assets).

## B. Tabla `battle_tiles` (AG-2)

Fichero `data/battle_tiles.json` (envelope D-009) + `data/schema/battle_tiles.schema.json`, validado por
`tools/validate_data.gd` (reconocer el dataset como juego, no presentación; sin WARN). Claves y valores
de balance (GDD §6.4 + README v1.7):

| clave | tile | move_cost | defense | passable | flags |
|---|---|---|---|---|---|
| pastizal | tile_pastizal | 1 | 0 | true | — |
| pastizal_arbustos | tile_pastizal_arbustos | 1 | 0 | true | — |
| pradera | tile_pradera | 1 | 0 | true | — |
| rio | tile_rio | null | 0 | **false** | — |
| puente | tile_puente | 1 | 0 | true | — |
| puente_villa | tile_puente_villa | 1 | 1 | true | — |
| colina | tile_colina | 2 | 1 | true | — |
| bosque | tile_bosque | 2 | 1 | true | `cavalry_penalty: true` |
| montana | tile_montana | null | 0 | **false** | — |
| villa | tile_villa | 1 | 1 | true | — |
| villa_calle | tile_villa_calle | 1 | 0 | true | `move_bonus: true` |
| camino | tile_camino | 0.5 | 0 | true | `move_bonus: true` |

Reglas tácticas N3/N2 (AG-2): río y montaña **intransitables** (ni entrar ni cruzar fuera de puente);
colina/bosque aplican `defense` y `move_cost`; bosque aplica penalización de caballería (§6.4 ×0,6 vs
formación/piqueros ya existe; en movimiento/defensa aplicar `cavalry_penalty`); `move_bonus` reduce el
coste de movimiento; villa/puente_villa dan `defense` al ocupante. Sin alterar el determinismo del
combate. Tests: 12 tiles cargan, impassable, costes/bonus, rotación lógica (misma geometría).

## C. Generador de campos N3 (AG-3)

`scripts/ui/battle/battlefield_generator.gd` (o equivalente) deriva el terreno de la región estratégica
(`region.terrain`): llanura → mayoría pastizal/pradera; bosque → fracción de bosque; colinas → colinas
dispersas; montaña → franja de montaña intransitable; costa/río → banda de río. Composición:
- río de **orilla a orilla** (fila/columna continua) con **1-2 puentes** (`tile_puente`/`tile_puente_villa`)
  sustituyendo casillas de río en los cruces; misma geometría de agua;
- villa en el asentamiento sitiado (región con `has_city`/capital);
- caminos conectando despliegue con villa/puente;
- orientación de banda: horizontal por defecto; vertical rotada 90°.
El campo se deriva de forma **determinista** (semilla de la partida/región) y expone la rejilla de tiles
para el render de N3; AG-2 aporta la tabla y las reglas de movimiento/defensa.

## D. QA (AG-4)

Criterios §10.4: los 12 tiles cargan sin error en CI headless; unidad no puede entrar a `rio`/`montana`
(test); bonus de `colina`/`camino` aplican en las fórmulas §6.4 (test); capturas de un campo con
**río+puente+villa** y uno de **llanura** en `docs/screenshots/`; el generador deriva el terreno de la
región estratégica (test con dos regiones de terreno distinto). Sin capturas no se cierra la integración.

## E. Propiedad de archivos

| Owner | Write scopes |
|---|---|
| **AG-3** | `assets/art/battle/tiles/**` (extracción), `scenes/battle/**`, `scripts/ui/**`, `tools/generate_battle_tiles*` si aplica |
| **AG-2** | `data/battle_tiles.json`, `data/schema/battle_tiles.schema.json`, `tools/validator_core.gd` (reconocimiento), `scripts/battle/**`, `scripts/autoload/**`, `tests/test_*.gd`, `tests/run_all.gd` |
| **AG-4** | `docs/qa/**`, `docs/issues.md`, `tests/qa_*.gd` |
| **AG-0** | `docs/**`, capturas, git |

## F. Coordinación

- Sprites §10.3 ya integrados (17/17, QA 6/6): AG-5 no toca la escena N3 mientras AG-3 trabaja tiles
  (orden tiles → unidades ya cumplido: unidades primero, tiles ahora).
- Un solo owner por archivo: AG-3 no edita `data/`; AG-2 no edita escenas.

# Contratos de integración — Fase 2

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-21 |
| **Autoridad** | AG-0 (Coordinator). Complementa el GDD v1.4 §10.1, §10.2, §6.2-6.3 y §8.2; ante conflicto manda el GDD |
| **Partes** | AG-1 (datos), AG-2 (sistemas), AG-3 (UI/mapa/retratos), AG-4 (QA) |
| **Regla** | Ningún agente edita este archivo; cambios vía AG-0 y entrada en `docs/decisions.md` |

Alcance Fase 2: (A) profundidad militar — Nivel 2 táctico y Nivel 3 cerrado, espionaje, extinción
dinástica; (B) módulo **Mapa** §10.1; (C) módulo **Retratos** §10.2.

---

## 1. `data/map_borders.json` — formato (AG-1)

Envelope (D-009 style). Coordenadas **normalizadas [0..1]** sobre lienzo de aspecto 4:3 (4096×3072),
origen arriba-izquierda (y hacia abajo). Anillo **abierto** (el último punto se une al primero; no repetir).

```jsonc
{
  "schema_version": 1,
  "canvas": { "width_px": 4096, "height_px": 3072, "projection": "equirectangular_stylized" },
  "years": {
    "1337": [
      {
        "region_id": "region_londres",
        "owner": "england",
        "ring": [[0.1842, 0.2871], [0.1901, 0.2840], /* ... */ [0.1798, 0.2902]],
        "center": [0.1850, 0.2880],
        "source": "https://en.wikipedia.org/wiki/...",
        "estimate": true
      }
      // ... 47 entradas
    ],
    "1402": [ /* 47 entradas */ ],
    "1453": [ /* 47 entradas */ ]
  }
}
```

Reglas de datos (criterios §10.1):
- **47 regiones exactas por año**, `region_id` de `regions.json`; 0 huérfanas; 0 duplicadas.
- `ring`: 3–400 puntos, coords en [0,1]; anillo simple (sin autointersecciones graves); área > 0.
- **≤ 150 KB** de archivo (147.456 B). Coordenadas redondeadas a 4 decimales; simplificación
  Douglas-Peucker con tolerancia fija documentada en `sources.md`; presupuesto medio ≤ 55 puntos/región.
- `center` = posición de etiqueta/icono (idealmente ciudad capital de la región o centroide).
- `owner` por año: facción dueña según fuentes históricas; si la entidad no existe en `factions.json`
  (p. ej. Venecia en 1402), usar el id de la entidad histórica y AG-3 la coloreará como neutral.
- Toda entrada lleva `source` (URL) o `estimate: true`; entradas de `data/sources.md` para Shepherd
  1923-26 y cada mapa de Wikimedia usados (licencia verificada una a una).
- Coherencia: los polígonos deben ser contiguos con las adyacencias de `regions.json` (regiones
  adyacentes comparten frontera aproximada) y el conjunto debe cubrir el mundo jugable sin huecos
  internos grandes.

## 2. Mapa §10.1 — arquitectura por capas (AG-3)

Escena `scenes/map/world_map.tscn` (raíz `Node2D` + `Camera2D`). Capas en orden de dibujo:
1. **Terreno** `assets/art/map/terrain_base.png` — 4096×3072 px generado una vez por
   `tools/generate_map_terrain.gd` (AG-3), determinista, estilo pergamino/acuarela: mar azul-tinta con
   retícula náutica, tierra ocre con relieve sutil, costas con línea de tinta, ríos y bosques/montañas
   indicativos. **Prohibido** estilo satélite o fantasía. Versionado en el repo (peso objetivo ≤ 8 MB).
2. **Fronteras** por año: líneas de tinta (ancho 1,5–2 px a zoom 1) desde `map_borders.json`, color
   oscuro; relleno de región con color de facción al 18–25 % de opacidad. Selector de vista de año
   `1337 / 1402 / 1453` (solo cambia la capa política; no altera la partida).
3. **Interactiva:** hit-test de punto-en-polígono (`Geometry2D.is_point_in_polygon`) por frame de ratón;
   hover resalta con tinta dorada ~18 % + tooltip (nombre, dueño, terreno); click → panel de región.
   Cobertura 47/47 en las 3 vistas.
4. **Entidades:** banderas de facción (escudo generado, color de `factions.json`), ejércitos con número,
   iconos de ciudad, nombres de región y etiquetas de mar (`MARE SEPTENTRIONALE`, `MARE NOSTRUM`,
   `LEGUES`…). Elisión anti-solape en **3 niveles de zoom** (país < 0,9; región 0,9–1,5; detalle > 1,5).

Cámara: zoom rueda 0,5–3,0, pan con arrastre y bordes del mundo; HUD del consejo/panel independiente.
Año por defecto = año del escenario activo (1337). `map_layout.json` queda **deprecado** al cerrar el
módulo (D-024): la UI deja de usarlo y se elimina del repo en el commit de cierre del módulo.

**Rendimiento (criterio §10.1):** el coste CPU del controlador del mapa (`_process`/redibujado y
hit-test) debe ser **< 8 ms/frame** de media, medido en CI con `Time.get_ticks_usec()` sobre ≥120
frames (headless: mide lógica/redibujado CPU, no GPU; documentar la limitación). AG-4 implementa el
benchmark en `tests/qa_*`.

**Comparativa visual:** `docs/screenshots/map_comparison.png` lado a lado con el mapa de referencia de
GK2 (§10.1). La captura de GK2 no está en el workspace y el material de Koei no se versiona; se solicita
al usuario. Mientras no exista, se entrega la comparativa con el atlas histórico de dominio público
(Shepherd 1923-26) y se documenta (D-024/D-025). Nunca se incluye material de Koei en el repo.

## 3. Retratos §10.2 (AG-1 datos, AG-3 UI, AG-2 sucesión)

- `data/characters.json` y su schema: campo **opcional** `"portrait"` (string con id de asset, o null).
  En Fase 2 no existen assets finales: todos los personajes usan fallback. AG-1 actualiza schema y, si
  procede, documenta ids previstos; no inventa binarios.
- `assets/art/portraits/<portrait_id>.png` (256×256, cuando exista en Fase 3). Fondo pergamino plano;
  el marco dorado lo genera el código, no el asset.
- Widget `scripts/ui/widgets/portrait_frame.gd` (AG-3): recibe `character_id`/dict y tamaño; si hay
  `portrait` y el asset existe → textura; si no → **fallback**: heráldica generativa de su `house`
  (colores + carga) + silueta genérica por sexo/edad. **Nunca hueco vacío.** API de test:
  `get_portrait_character_id() -> String`, `is_fallback() -> bool`.
- **5 slots obligatorios:** (1) esquina del mapa (soberano del jugador, sincronizado; muestra heredero
  tras sucesión), (2) árbol familiar (cada miembro vivo), (3) diplomacia (gobernante rival), (4) informe
  de batalla (líderes de ambos bandos), (5) pantalla de corte.
- Sincronización con sucesión: la UI escucha `EventBus.succession_resolved`/`character_died` y refresca;
  el slot del mapa debe mostrar al nuevo gobernante sin recargar partida. Test de regresión obligatorio
  (AG-4): forzar muerte del gobernante → comprobar que el widget muestra al heredero.

## 4. Batallas Nivel 2 y 3 (AG-2; escenas AG-3)

`BattleManager.launch_tactical(attacker_army: Army, defender_army: Army, region: RegionState) -> Node`
(se mantiene la firma §8.2). Devuelve un nodo `TacticalBattle` (`scripts/battle/tactical_battle.gd`,
`class_name TacticalBattle extends Node`) ya configurado; el llamador (UI) lo añade al árbol. Emite
`EventBus.tactical_battle_started`.

API de `TacticalBattle` (pública, consumida por la UI; la UI no muta estado directamente):
- `get_state() -> Dictionary` — `{battle_id, attacker_faction, defender_faction, region_id, round, side, winner, finished, objectives, hexes[], units[], commander_bonus}`.
- `get_hexes() -> Array[Dictionary]` — celdas axiales `{q, r, terrain, objective}` (radio 4–5).
- `get_units() -> Array[Dictionary]` — `{id, faction, unit_id, size, morale, commander, q, r, moves_left, orders_left}`.
- `select_unit(unit_id)`, `move_unit(unit_id, q, r) -> bool`, `attack_unit(attacker_id, defender_id) -> Dictionary`,
  `end_round()`, `resolve_duel(attacker_unit_id, defender_unit_id, order_id) -> Dictionary`,
  `get_objectives() -> Array[Dictionary]`, `is_finished() -> bool`, `get_winner() -> String`,
  `commit() -> Dictionary` (BattleReport dict), `apply_outcome()` (aplica captura/bajas vía MilitarySystem).
- Determinismo: toda tirada con `GameState.rng`; simulaciones con semilla fija reproducibles.
- AI del bando no jugador: mueve/ataca con utilidad simple por hex (objetivos > choque > ciudad).

`BattleManager.launch_close_combat(attacker_unit: Dictionary, defender_unit: Dictionary) -> Node` —
nodo `CloseCombat` (`scripts/battle/close_combat.gd`) para el Nivel 3: grupos unidad-a-unidad y **cartas
de orden**: `carga`, `disparo`, `formacion`, `finta`, `retirada`. Reglas mínimas: disparo daña antes del
choque; carga ×1,4 vs infantería en llano y ×0,6 vs formación/piqueros; formación reduce daño de carga;
finta permite reposicionar; retirada ordenada reduce bajas. El comandante con mayor Mando obtiene
**+1 orden por ronda** (mano de 3 en vez de 2). API: `get_state()`, `play_order(order_id)`,
`enemy_respond()`, `is_finished()`, `get_outcome() -> Dictionary`.

**Aplicación a campaña (addendum 1.1, D-033):** cuando el Nivel 3 se juega en el contexto de una batalla
de campaña, AG-3 invoca
`BattleManager.apply_close_combat_outcome(attacker_army_id, defender_army_id, region_id, outcome) -> Dictionary`,
que traduce el duelo a bajas/captura vía `MilitarySystem.apply_battle_outcome` (idempotente). El selector
directo de nivel en la UI es vista previa y no muta la partida.

**Crécy (1346) jugable en 3 niveles:** debe existir un escenario de prueba (no UI obligatoria) que cree
ejércitos Inglaterra/Francia en la región correspondiente y resuelva Nivel 1, Nivel 2 (táctico) y Nivel 3
(cerrado) con resultados coherentes; AG-4 lo añade a `qa_acceptance.gd`. La escena UI `tactical_map.tscn`
ofrece "resolver automáticamente" (Nivel 1), "jugar táctico" (Nivel 2) y "combate cerrado" (Nivel 3)
cuando hay choque, sin bloquear el resto del juego.

## 5. Espionaje (AG-2)

Acción de diplomacia `espia` (coste 6 PG, tabla §5.4). `DiplomacySystem.propose(actor, target, {"action": "espia"})`
devuelve `{ok, accepted, cost_pg, intel}`; en éxito `intel` incluye `armies` (resumen), `treasury`,
`regent_id`, `at_war` y el objeto se expone para la UI en `GameState.state.factions[actor].intel[target]`
(estado serializable). UI de diplomacia muestra el informe de espionaje. Determinista con `GameState.rng`.

## 6. Extinción dinástica (AG-2)

Si muere el gobernante y **no queda ningún miembro vivo de su casa** (sin heredero ni parientes),
`DynastySystem` emite `dynasty_extinct`; `TurnManager` declara **derrota inmediata** de esa facción
(`EventBus.game_over(player_faction, false, "dinastía extinta")` si es el jugador; eliminación si es IA).
Si hay parientes pero no heredero directo, se mantiene la crisis/interregno ya implementada. Test de
regresión: matar gobernante y todos los herederos → partida termina correctamente (sin crash, sin turnos
fantasma). GDD §5.3 y §4.5.

## 7. Propiedad de archivos (Fase 2)

| Owner | Write scopes |
|---|---|
| **AG-1** | `data/map_borders.json`, `data/schema/characters.schema.json` (campo `portrait`), `data/sources.md` |
| **AG-2** | `scripts/autoload/**`, `scripts/ai/**`, `scripts/model/**`, `scripts/utils/**`, `scripts/battle/**`, `tests/test_*.gd`, `tests/run_all.gd` |
| **AG-3** | `scenes/**`, `scripts/ui/**`, `assets/art/**`, `project.godot`, `tools/generate_map_terrain.gd`, `data/map_layout.json` (eliminación al cierre) |
| **AG-4** | `docs/issues.md`, `docs/qa/**`, `tests/qa_*.gd` |
| **AG-0** | `docs/STATUS.md`, `docs/decisions.md`, este archivo, git |

## 8. Aceptación Fase 2 (harness AG-4)

1. **Crécy en 3 niveles:** escenario de prueba con Inglaterra vs Francia; Nivel 1, Nivel 2 y Nivel 3
   resueltos sin crash y con resultado coherente (bajas/vencedor).
2. **Extinción dinástica:** pérdida de líder sin herederos → `game_over` de derrota correcto.
3. **§10.1:** 47/47 polígonos por año (1337/1402/1453), 0 huérfanas, IDs válidos, ≤150 KB; hover/click en
   las 3 vistas (hit-test unitario); benchmark CPU del mapa < 8 ms/frame; captura comparativa presente.
4. **§10.2:** 5 slots con fallback 100 % funcional (nunca vacío); test de sucesión actualiza el retrato
   del mapa al heredero; captura del mapa con retrato+escudo.
5. **No regresión:** `run_all.gd` (548+ tests), `validate_data.gd` 0 errores, save/load, Peste Negra,
   determinismo, UI sin mutaciones, 16 escenas previas + nuevas instanciables.

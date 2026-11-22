# Contratos de integración — Fase 1 (MVP jugable)

| Campo | Valor |
|---|---|
| **Versión** | 1.0 — 2026-11-21 |
| **Autoridad** | AG-0 (Coordinator). Este documento complementa el GDD §8.2; ante conflicto manda el GDD |
| **Partes** | AG-2 (sistemas), AG-3 (UI), AG-4 (QA) |
| **Regla** | Ni AG-2 ni AG-3 modifican este archivo; cualquier cambio de contrato se pide a AG-0 (entrada en `docs/decisions.md`) |

Objetivo: permitir que AG-2 (sistemas) y AG-3 (UI) trabajen **en paralelo** sin bloquearse,
con un estado serializable único y una API congelada (§8.2).

---

## 1. Estado canónico — `GameState.state`

Estado **puro JSON** (Dictionary/Array/primitivos; nada de `Object`, `Vector2` ni nodos). Todo el
estado de partida vive aquí; los sistemas lo leen/mutan y la UI **solo lo lee**.

```jsonc
{
  "save_version": 1,
  "scenario_id": "scenario_1337",
  "player_faction": "england",
  "rng": { "seed": 1337, "state": 0 },          // snapshot SeededRNG (D-015: se guarda con la partida)
  "year": 1337, "quarter": 1, "turn": 1,
  "game_over": false,
  "factions": {
    "england": {
      "gold": 1200, "prestige": 50, "pg": 30,
      "profile": "balanced", "is_player": true,
      "ruler_id": "edward_iii_plantagenet", "heir_id": "black_prince",
      "relations": { "france": -40, "scotland": -70 },   // -100..100, claves = faction_id
      "allies": [], "at_war": []
    }
    // ... 13 facciones más
  },
  "regions": {
    "region_londres": {
      "owner": "england", "support": 60,
      "workers": { "farmers": 400, "artisans": 150, "merchants": 100, "recruits": 50 },
      "buildings": ["castle", "market"], "population": 120000, "base_wealth": 75,
      "terrain": "city", "has_city": true
    }
    // ... 46 regiones más
  },
  "characters": {
    "edward_iii_plantagenet": { /* campos §7.1 de characters.json + */ "alive": true, "age": 25 }
    // ... 85 más (vivos y fallecidos; alive=false y died=año si murió)
  },
  "armies": {
    "army_england_1": {
      "id": "army_england_1", "faction_id": "england", "region_id": "region_londres",
      "leader_id": "edward_iii_plantagenet", "morale": 1.0, "movement_left": 2,
      "units": [ { "id": "u1", "unit_id": "longbowman", "size": 400, "strength": 9, "morale": 1.0, "experience": 0 } ]
    }
  },
  "event_log": [ { "year": 1337, "quarter": 1, "event_id": "founded", "text": "..." } ],
  "fired_events": ["guerra_cien_anos_1337"],
  "battle_reports": [ /* últimas N BattleReport.to_dict(), la UI muestra la última */ ]
}
```

**Convenciones:** IDs string; diccionarios indexados por id; oro/población/efectivos enteros; moral y
factores float; `year/quarter/turn` espejo del reloj de `TurnManager` (autoridad del reloj: **TurnManager**).
El snapshot `rng` se escribe al guardar y se restaura al cargar (determinismo, GDD §13).

**Nota de serialización (addendum 1.1):** `GameState.to_dict()` canonicaliza enteros y floats, y
serializa `rng.state` (64 bits) **como texto** para no perder precisión al pasar por JSON; consumidores
deben usar `GameState.rng`/`from_dict()`, no leer ese campo como número. `to_dict()` es la referencia
canónica del save (criterio A4: hash estable). Los sistemas pueden exponer helpers aditivos y señales
nuevas (p. ej. `EventBus.recruitment_completed`) siempre que no se rompan las firmas de §2.

## 2. API congelada (autoloads; implementar exactamente las firmas ya declaradas)

| Autoload | Métodos que implementa Fase 1 | Semántica |
|---|---|---|
| `GameState` | `new_game(scenario_id, faction_id, seed=1337)`, `reset()`, `to_dict()`, `from_dict(data)`, `save_game(slot="autosave")`, `load_game(slot)`, `has_save(slot)` | `new_game` construye `state` desde `scenario_1337` + `DataLoader`; `save_game` escribe `user://saves/<slot>.json` con `save_version:1`; `from_dict` valida estructura y restaura; `to_dict` devuelve copia serializable (**incluye `rng.snapshot()`**) |
| `TurnManager` | `begin_turn(faction_id)`, `end_turn()`, `spend_pg(n) -> bool`, `can_spend_pg(n) -> bool`, `calculate_pg(faction_id) -> int`, `advance_quarter()`, `advance_year()` | PG = `30 + Prestigio/10 + bonus_líder − penalización` (§5.1), mínimo 0; `end_turn` cierra órdenes del jugador, ejecuta IA, avanza trimestre y resoluciones; en trimestre 4 → `advance_year` |
| `EconomySystem` | `recalculate(faction_id)`, `allocate(region_id, worker_class, amount) -> bool`, `get_treasury(faction_id)`, `get_region_output(region_id)`, `resolve_harvest(faction_id)`, `get_support(region_id)` | Fórmulas §5.2; `allocate` cuesta **1 PG por orden** y reasigna mano de obra validando población trabajadora; apoyo 0-100; revuelta si apoyo <20 |
| `DynastySystem` | `marry(a,b) -> Dictionary`, `advance_year() -> Array[Dictionary]`, `get_ruler(faction_id)`, `get_heir(faction_id)`, `resolve_succession(faction_id)`, `get_family_tree(faction_id)` | Nacimientos 12% por consorte fértil (<40), enfermedad 2% (>50), muerte en batalla 15%; sucesión con regencia si heredero <14; extinción = derrota (§5.3) |
| `DiplomacySystem` | `propose(actor,target,action) -> Dictionary`, `get_relation(a,b)`, `set_relation(a,b,v)`, `are_at_war(a,b)`, `are_allied(a,b)`, `get_action_cost(action_id)` | 7 acciones §5.4 con costes PG; aceptación por puntuación de IA + Astucia; `propose` devuelve `{ok, cost_pg, accepted, reason}` |
| `MilitarySystem` | `create_army(faction_id, region_id)`, `recruit(faction_id, region_id, unit_id, amount)`, `move_army(army_id, to_region)`, `disband_army(army_id)`, `get_army(id)`, `get_armies_in(region_id)`, `get_recruitment_pool(region_id)`, `get_move_cost(army_id,to_region)` | Movimiento por adyacencia (1 PG/ejército + coste terreno), reclutamiento consume pool+oro, límite de ejércitos por región según edificios |
| `BattleManager` | `resolve_delegated(attacker, defender, region, stance) -> BattleReport`, `estimate_power(army, region, is_attacker) -> float`, `launch_tactical(...)` (stub Fase 2) | Fórmulas §6.1; ≤5 asaltos; retirada <25% o moral rota; captura de región si vence el atacante; informe `BattleReport` |
| `AIManager` | `take_turn(faction_id)`, `run_ai_turns(ids)`, `run_all_ai()`, `get_profile(id)`, `set_profile(id, profile)` | Utilidad §5.6; 2-4 órdenes/facción; **presupuesto <2000 ms para las 13 facciones IA** (medido y emitido en `ai_turn_finished`) |
| `DataLoader` | API existente (ya implementada) | Carga `data/*.json` y helpers `get_*` |
| `EventBus` | señales ya declaradas | Los sistemas emiten; la UI escucha (no hay acoplamiento directo UI-sistemas) |

## 3. Flujo del turno (orden obligatorio)

`TurnManager.begin_turn("england")` → UI habilita órdenes (cada una descuenta PG) → botón
"Terminar turno" → `end_turn()`:

1. Cierra fase de jugador (emite `turn_ended`).
2. `AIManager.run_all_ai()` para las 13 facciones IA (medir tiempo; <2 s).
3. Resoluciones pendientes (batallas delegadas iniciadas al mover ejércitos a región enemiga).
4. `advance_quarter()`: si `quarter < 4`, `quarter += 1`, `begin_turn(player)`; si `quarter == 4`:
   `advance_year()` → `EconomySystem.resolve_harvest`, `DynastySystem.advance_year`,
   eventos del año (`events_1337.json`, incluida **Peste Negra 1348**), autosave (`user://saves/autosave.json`).
5. Emite `EventBus.turn_started` del nuevo trimestre (la UI repinta).

## 4. Economía — fórmulas mínimas (§5.2)

- `trabajadores = población × (1 − tasa_reclutamiento)`; asignación por región: `farmers/artisans/merchants/recruits`.
- `alimento = farmers × factor_terreno × clima_trimestre` (clima del RNG; cosecha anual en trimestre 1).
- `bienes = artisans × talleres(1.0 en Fase 1) × tecnología(1.0)`.
- `comercio = merchants × rutas(1.0) × (1 + prosperidad/100)`.
- `tesoro += impuestos(riqueza × tasa) + comercio − mantenimiento`; tasas y mantenimiento con valores de diseño documentados.
- Apoyo: sube con superávit de alimentos, baja con impuestos altos/reclutamiento forzoso; <20 → evento de revuelta; >80 → bonus de crecimiento.
- `base_wealth` y `population` iniciales proceden de `regions.json`; el estado guarda los valores vivos.

## 5. Batalla delegada (§6.1)

`Poder = Σ(fuerza × moral × veteranía × terreno × comandante)`; comandante = `1+(Mando−50)/200`;
moral = `0.5+apoyo/200` (clampeada); terreno defensor llanura 1.0 / bosque 1.15 / ciudad 1.4 / río +0.2;
tirada gaussiana μ=1 σ=0.15 desde `GameState.rng`; hasta 5 asaltos; retirada <25% o moral rota;
15% muerte/cautiverio del líder derrotado. Informe: bajas por bando, asaltos, captura de región, botín.
Al mover un ejército a una región enemiga con defensores se resuelve la batalla y la UI muestra el
informe; sin defensores, la región se ocupa (si hay adyacencia y PG).

## 6. Guardado/carga

`save_game` escribe `user://saves/<slot>.json` (JSON legible, `save_version:1`); `from_dict` valida
claves mínimas y rechaza versiones desconocidas. **Criterio A4:** `to_dict()` → JSON → `from_dict()` →
`to_dict()` produce el mismo hash (test automatizado) y el RNG continúa exacto.

## 7. UI — reglas para AG-3

- Escenas en `scenes/**`, lógica de UI en `scripts/ui/**`, datos de presentación opcionales en
  `data/map_layout.json` (coordenadas por región para el mapa; **solo presentación**, no estado de
  simulación — decisión D-017).
- **La UI nunca muta `GameState.state`, `DataLoader` ni diccionarios de sistemas.** Solo llama a la
  API §2 y se repinta escuchando `EventBus`/señales de autoloads. Toda acción devuelve resultado y la
  UI lo muestra; el estado se relee con los getters.
- Pantallas mínimas §9: menú principal, selección de escenario, mapa principal (regiones + ejércitos),
  panel de región (asignar mano de obra/edificios/reclutar), menú de consejo, árbol familiar,
  diplomacia, informe de batalla, fin de año, victoria/derrota.
- Resolución de diseño 1920×1080 escalable; placeholders generados por código (colores por facción,
  escudos heráldicos simples, tipografía por defecto): sin assets externos.
- `project.godot` (main_scene, tema) es de AG-3 en Fase 1. AG-2 no lo toca.
- Smoke test headless: cada `.tscn` debe instanciarse sin errores (`load(...).instantiate()` + `free()`).

## 8. Propiedad de archivos (Fase 1)

| Owner | Write scopes |
|---|---|
| **AG-2** | `scripts/autoload/**`, `scripts/ai/**`, `scripts/model/**`, `scripts/utils/**`, `tests/test_*.gd` |
| **AG-3** | `scenes/**`, `scripts/ui/**`, `scripts/ui/theme/**`, `assets/art/**`, `project.godot`, `data/map_layout.json` |
| **AG-4** | `docs/issues.md`, `docs/qa/**`, `tests/qa_*.gd` (regresión y aceptación) |
| **AG-0** | `docs/STATUS.md`, `docs/decisions.md`, este archivo, git |

Cualquier archivo fuera del scope se pide a AG-0. Un archivo = un owner a la vez.

## 9. Aceptación Fase 1 (harness de AG-4, GDD §12)

`tests/qa_acceptance.gd` (headless, `extends SceneTree`) debe poder ejecutar:
1. **Partida Inglaterra 1337:** `new_game` + 4 trimestres con órdenes válidas sin crash.
2. **IA <2 s:** `run_all_ai()` de 13 facciones, medir `Time.get_ticks_msec()`; assert <2000 ms.
3. **Save/load exacto:** guardar, cargar, comparar hash de `to_dict()` y continuidad del RNG.
4. **Peste Negra 1348:** avanzar años hasta 1348 y verificar `peste_negra_1348` en `event_log` con
   `population_modifier -0.35` aplicado.
5. **Batalla delegada:** ≥1 resolución con informe coherente y captura de región.
6. **Smoke UI:** instanciar todas las escenas de `scenes/**` headless sin errores.

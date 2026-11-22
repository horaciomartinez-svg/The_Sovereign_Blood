# QA Fase 0 — The Sovereign's Blood

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-21 |
| **Repo** | `C:\Proyectos\TSB\sovereigns-blood` (rama `main`) |
| **HEAD local durante la QA** | `c0f236eb6136d6bff7bc7f867135fc8d1a03ad50` («[AG-REA] informe…»). El contexto de la tarea indicaba `6c31464`; durante la QA AG-0 añadió los commits `[AG-2]`, `[AG-1]` y `[AG-REA]` encima. No afecta al veredicto: los artefactos quedaron estables (mtimes ≤ 21:03:30; ejecuciones ≥ 21:04). AG-4 no ejecuta git (regla D-005); dato obtenido leyendo `.git/logs/HEAD`. |
| **Alcance** | Criterios A1/A4/A5/A6 de GDD §12 y reglas de GDD §13; datasets AG-1; scaffold/CI AG-2; informe REA; regla de oro §7.8 |
| **Límites** | No se editó `data/**`, `scripts/**`, `tools/**`, `project.godot` ni `docs/STATUS.md`; no se ejecutó git; no se accedió a la carpeta GK2 (prohibida para AG-4, GDD §3.1.2). Solo se escribió este archivo. |

---

## 1. Veredicto

> **QA Fase 0: APROBADO**

- **BLOQUEANTES: 0**
- **MAYORES: 0**
- **Menores / observaciones: 5** (ninguna impide cerrar Fase 0; ver §5).

---

## 2. Evidencia de comandos (salida íntegra + exit code)

Ejecutados exactamente desde `C:\Proyectos\TSB` con `C:\Godot\Godot_v4.7.2-stable_win64_console.exe` y `--path C:\Proyectos\TSB\sovereigns-blood`.

| # | Comando | Exit code | Resultado |
|---|---|---:|---|
| 1 | `godot --headless --path <repo> --script tools/validate_data.gd` | **0** | 6 datasets ↔ 6 schemas, 5.239 comprobaciones, reglas §13 OK, **0 errores** |
| 1-bis | repetición del comando 1 (determinismo) | **0** | Salida **byte-idéntica** a la anterior |
| 2 | `godot --headless --path <repo> --script tests/run_all.gd` | **0** | **231 pasados, 0 fallidos, 1 omitido**; "CI: OK (exit 0)" |
| 2-bis | repetición del comando 2 (verificación extra de determinismo) | **0** | Idéntico: 231/0/1, 251 líneas de salida |
| 3 | `godot --headless --path <repo> --editor --quit` | **0** | Importación completa del proyecto, sin `ERROR`/`WARNING`/`SCRIPT ERROR` |

### 2.1 Comando 1 — `tools/validate_data.gd` (ejecución 1)

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[INFO] validate_data — datasets=6 schemas=6 comprobaciones=5239
[INFO] raíz de datos: data/ (res://data)
[INFO] schema aplicado: data/characters.json ↔ data/schema/characters.schema.json
[INFO] schema aplicado: data/events_1337.json ↔ data/schema/events.schema.json
[INFO] schema aplicado: data/factions.json ↔ data/schema/factions.schema.json
[INFO] schema aplicado: data/regions.json ↔ data/schema/regions.schema.json
[INFO] schema aplicado: data/scenarios/scenario_1337.json ↔ data/schema/scenario.schema.json
[INFO] schema aplicado: data/units.json ↔ data/schema/units.schema.json
[OK] validate_data — 6 dataset(s) validado(s) contra 6 schema(s); reglas cruzadas §13 OK; 0 errores.
```

Exit code medido con `$LASTEXITCODE`: **0**.

### 2.2 Comando 1 — repetición (determinismo)

Misma salida, línea a línea, y mismo exit code **0**:

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[INFO] validate_data — datasets=6 schemas=6 comprobaciones=5239
[INFO] raíz de datos: data/ (res://data)
[INFO] schema aplicado: data/characters.json ↔ data/schema/characters.schema.json
[INFO] schema aplicado: data/events_1337.json ↔ data/schema/events.schema.json
[INFO] schema aplicado: data/factions.json ↔ data/schema/factions.schema.json
[INFO] schema aplicado: data/regions.json ↔ data/schema/regions.schema.json
[INFO] schema aplicado: data/scenarios/scenario_1337.json ↔ data/schema/scenario.schema.json
[INFO] schema aplicado: data/units.json ↔ data/schema/units.schema.json
[OK] validate_data — 6 dataset(s) validado(s) contra 6 schema(s); reglas cruzadas §13 OK; 0 errores.
```

**Conclusión:** salida y código deterministas; ninguna diferencia entre ejecuciones.

### 2.3 Comando 2 — `tests/run_all.gd` (salida íntegra)

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==============================================================
 The Sovereign's Blood — CI headless Fase 0 (criterios A3/A5)
 Godot 4.7.2-stable (official)
==============================================================
[SUITE] scaffold
  [PASS] application/config/name
  [PASS] display/window/size/viewport_width
  [PASS] display/window/size/viewport_height
  [PASS] sin main_scene en Fase 0 (se añade en Fase 1)
  [PASS] config/features incluye Godot 4.7
  [PASS] ProjectSettings registra autoload/EventBus
  [PASS] ProjectSettings registra autoload/DataLoader
  [PASS] ProjectSettings registra autoload/GameState
  [PASS] ProjectSettings registra autoload/TurnManager
  [PASS] ProjectSettings registra autoload/EconomySystem
  [PASS] ProjectSettings registra autoload/DynastySystem
  [PASS] ProjectSettings registra autoload/DiplomacySystem
  [PASS] ProjectSettings registra autoload/MilitarySystem
  [PASS] ProjectSettings registra autoload/BattleManager
  [PASS] ProjectSettings registra autoload/AIManager
  [PASS] autoload montado y es Node: EventBus
  [PASS] autoload EventBus extends Node
  [PASS] autoload montado y es Node: DataLoader
  [PASS] autoload DataLoader extends Node
  [PASS] autoload montado y es Node: GameState
  [PASS] autoload GameState extends Node
  [PASS] autoload montado y es Node: TurnManager
  [PASS] autoload TurnManager extends Node
  [PASS] autoload montado y es Node: EconomySystem
  [PASS] autoload EconomySystem extends Node
  [PASS] autoload montado y es Node: DynastySystem
  [PASS] autoload DynastySystem extends Node
  [PASS] autoload montado y es Node: DiplomacySystem
  [PASS] autoload DiplomacySystem extends Node
  [PASS] autoload montado y es Node: MilitarySystem
  [PASS] autoload MilitarySystem extends Node
  [PASS] autoload montado y es Node: BattleManager
  [PASS] autoload BattleManager extends Node
  [PASS] autoload montado y es Node: AIManager
  [PASS] autoload AIManager extends Node
  [PASS] 10/10 autoloads montados en el árbol
  [PASS] DataLoader.load_all()
  [PASS] DataLoader.load_json()
  [PASS] DataLoader.load_dataset()
  [PASS] DataLoader.get_faction()
  [PASS] DataLoader.get_region()
  [PASS] DataLoader.get_character()
  [PASS] DataLoader.get_unit()
  [PASS] DataLoader.get_scenario()
  [PASS] DataLoader.get_events_for_year()
  [PASS] DataLoader.has_faction()
  [PASS] DataLoader.has_region()
  [PASS] DataLoader.reset()
  [PASS] GameState.new_game()
  [PASS] GameState.reset()
  [PASS] GameState.to_dict()
  [PASS] GameState.from_dict()
  [PASS] GameState.save_game()
  [PASS] GameState.load_game()
  [PASS] GameState.has_save()
  [PASS] TurnManager.begin_turn()
  [PASS] TurnManager.end_turn()
  [PASS] TurnManager.spend_pg()
  [PASS] TurnManager.can_spend_pg()
  [PASS] TurnManager.calculate_pg()
  [PASS] TurnManager.advance_quarter()
  [PASS] TurnManager.advance_year()
  [PASS] EconomySystem.recalculate()
  [PASS] EconomySystem.allocate()
  [PASS] EconomySystem.get_treasury()
  [PASS] EconomySystem.get_region_output()
  [PASS] EconomySystem.resolve_harvest()
  [PASS] EconomySystem.get_support()
  [PASS] DynastySystem.marry()
  [PASS] DynastySystem.advance_year()
  [PASS] DynastySystem.get_ruler()
  [PASS] DynastySystem.get_heir()
  [PASS] DynastySystem.resolve_succession()
  [PASS] DynastySystem.get_family_tree()
  [PASS] DiplomacySystem.propose()
  [PASS] DiplomacySystem.get_relation()
  [PASS] DiplomacySystem.set_relation()
  [PASS] DiplomacySystem.are_at_war()
  [PASS] DiplomacySystem.are_allied()
  [PASS] DiplomacySystem.get_action_cost()
  [PASS] MilitarySystem.create_army()
  [PASS] MilitarySystem.recruit()
  [PASS] MilitarySystem.move_army()
  [PASS] MilitarySystem.disband_army()
  [PASS] MilitarySystem.get_army()
  [PASS] MilitarySystem.get_armies_in()
  [PASS] MilitarySystem.get_recruitment_pool()
  [PASS] MilitarySystem.get_move_cost()
  [PASS] BattleManager.resolve_delegated()
  [PASS] BattleManager.launch_tactical()
  [PASS] BattleManager.estimate_power()
  [PASS] AIManager.take_turn()
  [PASS] AIManager.run_ai_turns()
  [PASS] AIManager.run_all_ai()
  [PASS] AIManager.get_profile()
  [PASS] AIManager.set_profile()
  [PASS] EventBus signal turn_started
  [PASS] EventBus signal turn_ended
  [PASS] EventBus signal year_advanced
  [PASS] EventBus signal pg_changed
  [PASS] EventBus signal character_born
  [PASS] EventBus signal character_died
  [PASS] EventBus signal war_declared
  [PASS] EventBus signal peace_made
  [PASS] EventBus signal battle_resolved
  [PASS] EventBus signal game_over
  [PASS] GameState signal game_initialized
  [PASS] GameState signal game_saved
  [PASS] GameState signal game_loaded
  [PASS] TurnManager signal turn_started
  [PASS] TurnManager signal pg_changed
  [PASS] TurnManager signal turn_ended
  [PASS] EconomySystem signal treasury_changed
  [PASS] EconomySystem signal region_output_changed
  [PASS] DynastySystem signal character_born
  [PASS] DynastySystem signal character_died
  [PASS] DynastySystem signal marriage_formed
  [PASS] DynastySystem signal succession_resolved
  [PASS] DiplomacySystem signal proposal_sent
  [PASS] DiplomacySystem signal war_declared
  [PASS] DiplomacySystem signal peace_made
  [PASS] DiplomacySystem signal relation_changed
  [PASS] MilitarySystem signal army_created
  [PASS] MilitarySystem signal army_moved
  [PASS] MilitarySystem signal army_destroyed
  [PASS] BattleManager signal battle_resolved
  [PASS] AIManager signal ai_turn_started
  [PASS] AIManager signal ai_turn_finished
  [PASS] autoload compila: event_bus.gd
  [PASS] autoload instanciable: EventBus
  [PASS] autoload compila: data_loader.gd
  [PASS] autoload instanciable: DataLoader
  [PASS] autoload compila: game_state.gd
  [PASS] autoload instanciable: GameState
  [PASS] autoload compila: turn_manager.gd
  [PASS] autoload instanciable: TurnManager
  [PASS] autoload compila: economy_system.gd
  [PASS] autoload instanciable: EconomySystem
  [PASS] autoload compila: dynasty_system.gd
  [PASS] autoload instanciable: DynastySystem
  [PASS] autoload compila: diplomacy_system.gd
  [PASS] autoload instanciable: DiplomacySystem
  [PASS] autoload compila: military_system.gd
  [PASS] autoload instanciable: MilitarySystem
  [PASS] autoload compila: battle_manager.gd
  [PASS] autoload instanciable: BattleManager
  [PASS] autoload compila: ai_manager.gd
  [PASS] autoload instanciable: AIManager
  [PASS] modelo compila: character.gd
  [PASS] modelo instanciable: Character
  [PASS] modelo Character expone to_dict()
  [PASS] modelo compila: region_state.gd
  [PASS] modelo instanciable: RegionState
  [PASS] modelo RegionState expone to_dict()
  [PASS] modelo compila: army.gd
  [PASS] modelo instanciable: Army
  [PASS] modelo Army expone to_dict()
  [PASS] modelo compila: unit_instance.gd
  [PASS] modelo instanciable: UnitInstance
  [PASS] modelo UnitInstance expone to_dict()
  [PASS] modelo compila: battle_report.gd
  [PASS] modelo instanciable: BattleReport
  [PASS] modelo BattleReport expone to_dict()
  [PASS] utilidad compila: rng.gd
  [PASS] rng expone snapshot()/restore()
  [PASS] data/ existe y es accesible
  [PASS] data/schema/ accesible
[SUITE] rng
  [PASS] misma semilla → misma secuencia
  [PASS] semilla distinta → secuencia distinta
  [PASS] reset() reproduce la semilla inicial
  [PASS] next_int respeta el rango [5, 9]
  [PASS] next_int alcanza ambos extremos
  [PASS] next_float_range respeta el rango [2.0, 3.0]
  [PASS] roll_d100 respeta [1, 100]
  [PASS] pick() sobre array vacío devuelve null
  [PASS] shuffled() no muta el array original
  [PASS] shuffled() conserva los elementos
  [PASS] snapshot() contiene seed y state
  [PASS] snapshot/restore reproduce el flujo exacto
  [PASS] duplicate_rng() continúa el mismo flujo
  [PASS] gaussian μ=1.0 (media muestral ≈ 1.0)
  [PASS] commander_modifier(85) ≈ 1.175
  [PASS] commander_modifier(0) = 0.75
  [PASS] commander_modifier(100) = 1.25
[SUITE] validator
  [PASS] objeto válido → 0 errores
  [PASS] campo requerido ausente → [FAIL]
  [PASS] el error incluye archivo y campo ($.count)
  [PASS] tipo incorrecto → [FAIL] tipo esperado
  [PASS] integer acepta 2.0 (semántica JSON Schema)
  [PASS] integer rechaza 2.5
  [PASS] enum/const/pattern válidos → 0 errores
  [PASS] enum fuera de lista → [FAIL]
  [PASS] const distinto → [FAIL]
  [PASS] pattern incumplido → [FAIL]
  [PASS] minimum/maximum válidos → 0 errores
  [PASS] minimum incumplido → [FAIL]
  [PASS] maximum incumplido → [FAIL]
  [PASS] objeto anidado válido → 0 errores
  [PASS] additionalProperties=false → [FAIL]
  [PASS] propiedad anidada requerida → [FAIL]
  [PASS] additionalProperties con schema válido → 0 errores
  [PASS] additionalProperties con schema inválido → [FAIL]
  [PASS] array válido → 0 errores
  [PASS] minItems → [FAIL]
  [PASS] uniqueItems → [FAIL]
  [PASS] items con tipo incorrecto → [FAIL]
  [PASS] el error de items incluye el índice ($.adjacency[0])
  [PASS] oneOf válido (string) → 0 errores
  [PASS] oneOf válido (integer) → 0 errores
  [PASS] oneOf inválido → [FAIL]
  [PASS] type como lista acepta null
  [PASS] type como lista acepta string
  [PASS] type como lista rechaza integer
  [PASS] $ref local válido → 0 errores
  [PASS] $ref local detecta tipo incorrecto
  [PASS] envelope D-009 válido → 0 errores
  [PASS] envelope D-009 detecta id con pattern
  [PASS] envelope D-009 detecta playable no booleano
  [PASS] integración: dataset roto NO pasa la validación
  [PASS] integración: capital inexistente detectada
  [PASS] integración: adyacencia asimétrica detectada
  [PASS] integración: adyacencia a región inexistente detectada
  [PASS] integración: owner inexistente detectado
  [PASS] integración: personaje referenciado inexistente detectado
  [PASS] integración: facción de escenario inexistente detectada
  [PASS] integración: fichero de personajes referenciado inexistente detectado
  [PASS] integración: events_script inexistente detectado
  [PASS] integración: playable ≠ 8 detectado
  [PASS] integración: aviso por dataset sin schema
  [PASS] integración: errores con formato [FAIL] archivo :: campo
  [SKIP] data/ sin datasets: 6 dataset(s) presentes: lo cubre la suite data_validation
[SUITE] data_validation
[INFO] schema aplicado: data/characters.json ↔ data/schema/characters.schema.json
[INFO] schema aplicado: data/events_1337.json ↔ data/schema/events.schema.json
[INFO] schema aplicado: data/factions.json ↔ data/schema/factions.schema.json
[INFO] schema aplicado: data/regions.json ↔ data/schema/regions.schema.json
[INFO] schema aplicado: data/scenarios/scenario_1337.json ↔ data/schema/scenario.schema.json
[INFO] schema aplicado: data/units.json ↔ data/schema/units.schema.json
  [PASS] data/: validación §13 (6 dataset(s), 6 schema(s), 5239 comprobaciones)
--------------------------------------------------------------
RESULTADO: 231 pasados, 0 fallidos, 1 omitidos
CI: OK (exit 0)
```

Exit code medido con `$LASTEXITCODE`: **0**. Repetición del comando: idéntica (231/0/1, exit 0, 251 líneas).

### 2.4 Comando 3 — `--editor --quit` (salida íntegra, ANSI eliminado)

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[   0% ] first_scan_filesystem | Started Inicialización del proyecto (5 steps)
[   0% ] first_scan_filesystem | Escaneando la estructura del archivo...
[  16% ] first_scan_filesystem | Cargando nombres de clases globales...
[  33% ] first_scan_filesystem | Verificando GDExtensions...
[  50% ] first_scan_filesystem | Creando scripts de carga automática...
[  66% ] first_scan_filesystem | Inicializando plugins...
[  83% ] first_scan_filesystem | Iniciando escaneo de archivos...
[ DONE ] first_scan_filesystem

[   0% ] loading_editor_layout | Started Cargando editor (5 steps)
[   0% ] loading_editor_layout | Cargando diseño del editor...
[  16% ] loading_editor_layout | Cargando docks...
[ DONE ] loading_editor_layout
```

Exit code: **0**. Sin `ERROR`, `WARNING`, `SCRIPT ERROR` ni trazas de fallo.

---

## 3. Verificación independiente de datos (PowerShell, sin confiar en los scripts de AG-1/AG-2)

### 3.1 Integridad de archivos

| Comprobación | Resultado | Evidencia |
|---|---|---|
| JSON válido en `data/**/*.json` | **12/12** | 6 datasets + 6 schemas; parseo `ConvertFrom-Json` sin errores |
| Archivos de datos | **7** | 6 JSON (`factions`, `regions`, `characters`, `units`, `events_1337`, `scenarios/scenario_1337`) + `sources.md` (Markdown, no JSON) |
| Schemas | **6** | `data/schema/*.schema.json` |
| UTF-8 estricto (sin BOM) | **13/13** | 12 JSON + `sources.md`; además `project.godot` UTF-8 estricto (1.404 B, sin BOM) |
| `schema_version` | 1 en los 5 datasets con envelope (D-009) | `factions`, `regions`, `characters`, `units`, `events_1337` |

### 3.2 Reglas §13 y conteos

| Regla | Resultado | Detalle |
|---|---|---|
| 14 facciones | **OK** | 14 exactas |
| Exactamente 8 `playable` | **OK** | 8 `true` / 6 `false` |
| IDs únicos | **OK** | facciones 14/14, regiones 47/47, personajes 86/86, unidades 17/17, eventos 18/18 |
| Toda capital existe como región | **OK** | 14/14 (`region_londres`, `region_ile_de_france`, `region_praga`, `region_buda`, `region_burgos`, `region_barcelona`, `region_cracovia`, `region_edimburgo`, `region_avignon`, `region_granada`, `region_el_cairo`, `region_sarai`, `region_constantinopla`, `region_praga`) |
| Capital poseída por su facción | 13/14 | HRE → `region_praga` es de `bohemia`: **conforme al GDD §4.2** y documentado en D-010/`sources.md`. No es defecto (ver OBS-01). |
| `year_data."1337"` en toda región | **OK** | 47/47 regiones |
| Todo `owner` de 1337 existe como facción | **OK** | 47/47; reparto: francia 6, HRE 7, mamelucos 5, inglaterra 4, castilla 3, aragón 3, hungría 3, bizancio 3, bohemia 2, escocia 2, granada 2, polonia 2, horda 2, papado 3 (= 47) |
| Adyacencias simétricas | **OK** | 0 asimétricas |
| Adyacencias a regiones inexistentes | **OK** | 0 |
| Auto-adyacencias / duplicadas | **OK** | 0 / 0 |
| Grafo conectado | **OK** | 47/47 alcanzables desde `region_londres` |
| Enlaces de adyacencia | 130 entradas dirigidas = **65 pares** no dirigidos | `sources.md` dice «130 enlaces» contando entradas del JSON (ver OBS-03) |
| `scenario.factions` existe en `factions.json` | **OK** | 14/14 |
| `start_year` / `end_year` | **OK** | 1337 / 1399 |
| `initial_state` referencias | **OK** | `characters: "characters.json"` existe; `regions: "1337"` existe; `events_script: "events_1337.json"` existe |
| Ejércitos iniciales: unidades/regiones/facciones | **OK** | 0 referencias rotas; **todos** los ejércitos están en regiones propias de su facción |
| Tesorerías | **OK** | 14/14 facciones existentes, valores no negativos |
| Personajes referenciados existen (father/mother/spouse/children) | **OK** | 0 referencias rotas; 0 inconsistencias de reciprocidad spouse; 0 de padre/madre→children |
| `faction` de cada personaje existe | **OK** | 86/86 |
| `claims.target` existe | **OK** | 6 personajes con claims, 0 destinos rotos |
| Stats 1–100 | **OK** | 0 fuera de rango |
| Eventos dentro de 1337–1399 | **OK** | 18/18; 0 fuera |
| Referencias de eventos (faction/target/region) | **OK** | 0 rotas |
| **Peste Negra 1348** | **OK** | `peste_negra_1348`: `population_modifier` `value: -0.35`, `scope: "europe_west"`; único evento de 1348 |
| Gobernantes (role=ruler) | **OK** | 14 exactos, 1 por facción |
| Reparto global de personajes | — | 86: aragón 5, bohemia 8, bizancio 5, castilla 9, inglaterra 9, francia 8, horda 6, granada 4, HRE 6, hungría 6, mamelucos 5, papado 4, polonia 5, escocia 6 |

### 3.3 Regla de oro §7.8 (`source` / `"estimate": true`)

| Comprobación | Resultado |
|---|---|
| Regiones: toda entrada `year_data` con `source` **y** `estimate: true` | **47/47** (0 sin source, 0 sin estimate) |
| Personajes: `source` | **86/86** |
| Personajes: `"estimate": true` | **86/86** |
| Eventos: `source` | **18/18** |
| URLs de datasets presentes en `data/sources.md` | **0 ausentes** (se comprobó cada URL de personaje, evento y región) |
| `sources.md` cubre todas las entidades | personajes 86/86, regiones 47/47, unidades 17/17, eventos 18/18 (filas de tabla comparadas por id) |
| Conteos declarados en `sources.md` | 86 personajes, 47 regiones, 17 unidades, 18 eventos → **coinciden** |
| **Muestra de 14 datos históricos** `sources.md` ↔ JSON (≥10 exigidos) | **14/14 OK**: poblaciones/riqueza/owners de Londres, Île-de-France, Praga, Granada, Aviñón, Cracovia; nacimientos/muertes de Eduardo III, Eduardo II, Andrónico III; años de Peste Negra 1348, Kosovo 1389, Nicópolis 1396; capital de HRE; `playable` de Bohemia. Cada uno lleva `source` o `estimate: true` en el JSON. |
| Inconsistencias de cifras | **0** en la muestra |

### 3.4 Coherencia GDD §4.2 (14 gobernantes y casas)

| Facción | Gobernante en datos | GDD §4.2 | Casa datos | Casa GDD | Estado |
|---|---|---|---|---|---|
| england | Eduardo III | Eduardo III | plantagenet | Plantagenet | OK |
| france | Felipe VI de Valois | Felipe VI | valois | Valois | OK |
| hre | Luis IV de Baviera | Luis IV | wittelsbach | Wittelsbach | OK |
| bohemia | Juan I de Luxemburgo, rey de Bohemia | Juan de Luxemburgo | luxembourg | Luxemburgo | OK (nombre ampliado) |
| hungary | Carlos Roberto de Anjou | Carlos Roberto | anjou | Anjou | OK |
| castile | Alfonso XI el Justiciero | Alfonso XI | borgona | Trastámara/Borgoña | OK |
| aragon | Pedro IV el Ceremonioso | Pedro IV | barcelona | Barcelona-Aragón | OK |
| poland | Casimiro III el Grande | Casimiro III | piast | Piast | OK |
| scotland | David II de Escocia | David II | bruce | Bruce | OK |
| papacy | Benedicto XII (Jacques Fournier) | Benedicto XII | fournier | — | **OBS-02** |
| granada | Yusuf I de Granada | Yusuf I | nazari | Nazarí | OK |
| mamluks | An-Nasir Muhammad | An-Nasir Muhammad | qalawun | Bahri | **OBS-02** |
| golden_horde | Öz Beg Kan | Özbeg | borjigin | Borjigin | OK (transliteración) |
| byzantium | Andrónico III Paleólogo | Andrónico III | paleologo | Paleólogo | OK |

**Resultado:** 14/14 gobernantes identifican a la misma persona del GDD (2 con ampliación de nombre/transliteración); **12/14 casas literalmente alineadas**, 2 con nomenclatura distinta (OBS-02, no bloqueante).

### 3.5 Higiene

| Comprobación | Resultado |
|---|---|
| Archivos auxiliares dentro de `data/` (`_ag1_*.py`, `_ag1_check.ps1`, etc.) | **0** (incluidos ocultos) |
| `.uid` huérfanos sin `.gd` | **0** (se verificó todo el repo salvo `.godot/`) |
| `.gd` sin `.uid` | **0** (23 `.gd` ↔ 23 `.uid`) |
| Archivos temporales/logs/strays en el repo | **0** (solo `tools/ci_headless.ps1`, esperado) |

### 3.6 Determinismo

| Comprobación | Resultado |
|---|---|
| Comando 1 ejecutado 2 veces | Salida **idéntica**, exit 0 ambas |
| `tests/run_all.gd` ejecutado 2 veces | **231 pasados / 0 fallidos / 1 omitido** ambas, exit 0 |
| Estabilidad de artefactos | Hashes SHA-256 de `data/**` estables; mtimes de datos ≤ 21:02:23, informe REA 21:03:30, ejecuciones ≥ 21:04 → los resultados corresponden a los artefactos finales |

Hashes SHA-256 (primeros 16 hex) de los datos verificados:

```text
7724AFA91F6D8CF5  data/characters.json
004BF70AC0FD896A  data/events_1337.json
102AC897DA7530EB  data/factions.json
7F4E32AADE107C07  data/regions.json
075A35F64324AB54  data/scenarios/scenario_1337.json
1171D4940D052ED8  data/schema/characters.schema.json
AE8E654B9C0BE5F6  data/schema/events.schema.json
F663A706E9BFCFC0  data/schema/factions.schema.json
2C0093D73128951A  data/schema/regions.schema.json
DC78937D364F580B  data/schema/scenario.schema.json
2E4506991BE0FF3B  data/schema/units.schema.json
EC2626EDA89FE922  data/sources.md
0F726FCA0EBD2391  data/units.json
```

---

## 4. Verificación del informe REA (`docs/rea/gk2_data_lessons.md`)

| Criterio | Resultado | Evidencia |
|---|---|---|
| Existe | **Sí** | `docs/rea/gk2_data_lessons.md`, 10.887 B, 143 líneas, 1.721 palabras |
| ≤ 2 páginas (umbral operativo ≈ ≤ 1.800 palabras) | **CUMPLE** | 1.721 palabras ≤ 1.800. Nota: medida como A4 densa (~500 palabras/página) daría ~3,4 páginas; con el formato real (tablas compactas) ≈ 2 páginas. El criterio operativo dado se cumple; se deja constancia por si AG-0 exige medición tipográfica exacta. |
| Tabla de equivalencias GK2 → JSON (GDD §7) | **Sí** | §3 «Equivalencias GK2 → JSON del GDD §7», 1 tabla de 8 filas (personaje, roster, facciones, ZNAME, escenario, guardado, cabecera, celdas) |
| Declaración legal | **Sí** | §5 «Declaración legal»: uso personal/estudio, sin código derivado ni material transcrito |
| Método y límites | **Sí** | §5 «Método» + lista «No concluyente» (a)–(f) |
| Sin análisis de `.EXE` | **CUMPLE** | Únicas menciones: línea 6 «No se abrió ningún ejecutable (`MAIN.EXE`, `OPEN.EXE`, `END.EXE`)» y línea 25 «Los `.EXE` y `.COM` no se abrieron (prohibición §3)». Son declaraciones de prohibición, no análisis. Búsqueda de `desensambl|decompil|disassembl|dump`: **0 coincidencias**. |
| Sin listas de nombres del juego transcritas | **CUMPLE** | Heurística de listas de nombres propios: 0 listas; el único match fue una fila técnica de campos (`stats{command,...}`). El informe declara expresamente «sin listar nombres de regiones, personajes ni facciones». |
| Sin texto de Koei transcrito | **CUMPLE** | Solo longitudes, offsets, tamaños y recuentos; nombres de archivo de datos (permitido por GDD §3). |
| Alcance permitido (§3) | **CUMPLE** | Documenta estructura de `.DAT`/`.GK2` (permitido) y extrae lecciones de modelado; no especifica reimplementación 1:1. |

**Anexo adicional:** `docs/rea/notes.md` (180 líneas, 11.452 B) es un anexo técnico de método. Se revisó: sin análisis de `.EXE`, sin nombres/textos del juego, sin material transcrito. Ver OBS-04.

---

## 5. Hallazgos por severidad

### BLOQUEANTES

**Ninguno.** Los tres comandos obligatorios terminan con exit code 0; `validate_data.gd` reporta 0 errores; la suite reporta 0 fallos; las reglas §13 y la regla de oro §7.8 se cumplen de forma independiente.

### MAYORES

**Ninguno.**

### MENORES / OBSERVACIONES

#### OBS-01 · (Informativo) Capital del HRE no poseída — conforme al GDD y decidido en D-010
- **Archivo:** `data/factions.json` (`hre.capital = region_praga`), `data/regions.json` (`region_praga.year_data."1337".owner = "bohemia"`).
- **Hecho:** la capital del Sacro Imperio (Praga) pertenece a Bohemia en 1337. El GDD §4.2 asigna Praga como capital a **ambas** facciones; el validador solo exige que la capital exista como región. Está documentado en `docs/decisions.md` D-010 y en `data/sources.md` línea 40.
- **Severidad:** informativo, **no es defecto** (fidelidad al GDD). Fase 1 debe tolerar capital no propia en UI.
- **Reproducción:** `(Get-Content data/factions.json | ConvertFrom-Json).factions | ? id -eq 'hre'`; `(Get-Content data/regions.json | ConvertFrom-Json).regions | ? id -eq 'region_praga'`.

#### OBS-02 · (MENOR) Dos casas de gobernantes no coinciden literalmente con GDD §4.2
- **Archivos/líneas:** `data/characters.json` → `benedict_xii.house = "fournier"` y `an_nasir_muhammad.house = "qalawun"`.
- **GDD §4.2:** Benedicto XII casa «—» (sin dinastía); An-Nasir Muhammad casa «Bahri».
- **Valoración:** históricamente defendible (Fournier es la familia de Benedicto XII; Qalawunid es una dinastía dentro de los mamelucos Bahri) y coherente con el uso del campo `house` para familias papales (p. ej. `clemente_vi.house = "roger"`). No afecta a validación, tests ni jugabilidad. `data/sources.md` afirma que las casas «provienen de la tabla de GDD §4.2», lo que no es literal para estas dos.
- **Recomendación (para AG-0, sin arreglar por AG-4):** alinear ambos valores con el GDD o documentar la decisión de nomenclatura en `docs/decisions.md`/`sources.md` en Fase 1.
- **Reproducción:** comparar `characters.json` (ids `benedict_xii`, `an_nasir_muhammad`) con GDD líneas 126–128.

#### OBS-03 · (MENOR) «130 enlaces» en `sources.md` cuenta entradas dirigidas
- **Archivo:** `data/sources.md` línea 275: «grafo de regiones propio (47 nodos, 130 enlaces)».
- **Hecho:** el JSON contiene **130 entradas de adyacencia dirigidas** (cada arista aparece en ambos sentidos) = **65 pares no dirigidos**. No hay error de datos (simetría verificada), solo ambigüedad de redacción.
- **Recomendación:** aclarar en `sources.md` («130 entradas / 65 enlaces no dirigidos») cuando AG-1 retome el documento.
- **Reproducción:** sumar `@($r.adjacency).Count` de las 47 regiones → 130.

#### OBS-04 · (MENOR) Anexo REA adicional `docs/rea/notes.md`
- **Archivo:** `docs/rea/notes.md` (180 líneas, 11.452 B), declarado «anexo de `gk2_data_lessons.md`; no forma parte del entregable de 2 páginas».
- **Hecho:** añade detalle de método, offsets, entropías y preguntas abiertas. Revisado: **no** contiene análisis de `.EXE`, no transcribe nombres ni texto del juego y no incluye código derivado del binario.
- **Riesgo:** GDD §3 dice del entregable REA «tabla de equivalencias… **Nada más**». El anexo amplía la documentación REA más allá de esa frase. A criterio de AG-0 si se acepta como apéndice técnico interno o se debe recortar/fusionar.
- **Reproducción:** `docs/rea/notes.md`; búsqueda de `MAIN.EXE|OPEN.EXE|END.EXE|desensambl|decompil`.

#### OBS-05 · (Informativo) HEAD del repo distinto del indicado en el contexto de la tarea
- **Hecho:** el contexto decía «commit `6c31464` + trabajo sin commitear de AG-1/AG-2»; durante la QA el HEAD local pasó a `c0f236eb` («[AG-REA] informe…») con los commits `[AG-2]`, `[AG-1]` y `[AG-REA]` encima de `6c31464`. Los artefactos verificados no cambiaron después de las ejecuciones (mtimes ≤ 21:03:30; ejecuciones ≥ 21:04).
- **Severidad:** informativo; no afecta a la verificación. AG-4 no ejecuta git (D-005); dato leído de `.git/logs/HEAD`.
- **Reproducción:** leer `.git/logs/HEAD` (solo lectura).

---

## 6. Nota de alcance

- No se detectaron bugs de código ni de datos que requieran **tests de regresión**; por ello no se añadió ningún test nuevo en `tests/` (los tests existentes de AG-2 ya cubren los casos de fallo del validador y el determinismo del RNG).
- No se modificó ningún archivo fuera de `docs/issues.md`. No se ejecutó git.

*Fin del informe QA Fase 0 — AG-4.*

---

## 7. Fase 1 — Baseline (task-8, 2026-11-21)

**Contexto:** arranque de Fase 1 (objetivo MVP jugable, GDD §12 / contrato `docs/architecture_contracts_fase1.md` §9). AG-2 (sistemas) y AG-3 (UI) están implementando en paralelo; en el momento del baseline el repo seguía en el estado stub de Fase 0 (autoloads declarados sin lógica y `scenes/**` sin `.tscn`). Este baseline **no es un veredicto de rechazo**: los `[SKIP]` son «pendiente de implementación» y se convertirán en la verificación final (task-9) cuando AG-2/AG-3 terminen.

**HEAD registrado:** `f11b09f3fba8b0258c7105d4c4ac9494f3a4fb36` («[AG-0] Fase 1: contrato de integracion…»), leído de `.git/logs/HEAD` (AG-4 no ejecuta git, D-005). `scripts/` no se modificó por QA; los mtimes de producción posteriores al baseline corresponden a AG-2/AG-3 trabajando en paralelo.

**Archivos creados por QA (task-8):**

| Archivo | Líneas | Propósito |
|---|---:|---|
| `tests/qa_acceptance.gd` | 812 | Harness de aceptación Fase 1 (6 criterios, `extends SceneTree`, sin GUT), compila y se ejecuta contra stubs |
| `docs/qa/fase1_plan.md` | 112 | Plan de QA: puerta de aceptación, matriz criterio §12 → check → comando → evidencia, protocolo, baseline y riesgos |

### 7.1 Comandos y códigos de salida (baseline)

| # | Comando | Exit code | Resultado baseline |
|---|---|---:|---|
| 1 | `godot --headless --path <repo> --script tests/qa_acceptance.gd` | **1** | **0 PASS / 0 FAIL / 6 SKIP** → PENDIENTE (sistemas aún stub); harness ejecutado sin errores de parseo |
| 1-bis | repetición del harness | **1** | Misma tabla (0/0/6), mismos motivos; solo varían el timestamp y los ms de C6 (3→4 ms) |
| 2 | `godot --headless --path <repo> --script tools/validate_data.gd` | **0** | 6 datasets ↔ 6 schemas, **5.239 comprobaciones**, reglas §13 OK, **0 errores** (no-regresión Fase 0) |
| 3 | `godot --headless --path <repo> --script tests/run_all.gd` | **0** | **231 pasados, 0 fallidos, 1 omitido**; «CI: OK (exit 0)» (no-regresión Fase 0) |
| 4 | `godot --headless --path <repo> --editor --quit` | **0** | Importación completa (2 `[DONE]`), sin `ERROR`/`WARNING`/`SCRIPT ERROR` |

### 7.2 Salida íntegra del harness (ejecución baseline 1, 21:29:08)

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==============================================================
 The Sovereign's Blood — QA Aceptación Fase 1 (GDD §12 / contrato §9)
 Godot 4.7.2-stable (official) · headless · 2026-11-21T21:29:08
==============================================================
[INFO] datasets esperados: 14 facciones, 47 regiones
[INFO] 10/10 autoloads montados
[INFO] GameState.state inicial: vacío
  [SKIP] C1 — Partida Inglaterra 1337: new_game + 4 trimestres de órdenes válidas sin crash :: GameState.state vacío tras new_game() (pendiente: sistema aún stub/no disponible)
  [SKIP] C2 — IA de 13 facciones rivales en <2000 ms (medido) :: GameState.state vacío tras new_game() (pendiente: sistema aún stub/no disponible)
  [SKIP] C3 — Save/load exacto: hash de to_dict() igual + continuidad del RNG :: GameState.state vacío tras new_game() (pendiente: sistema aún stub/no disponible)
  [SKIP] C4 — Peste Negra 1348 en event_log con population_modifier -0.35 (europe_west) :: GameState.state vacío tras new_game() (pendiente: sistema aún stub/no disponible)
  [SKIP] C5 — Batalla delegada: informe coherente y captura de región :: GameState.state vacío tras new_game() (pendiente: sistema aún stub/no disponible)
  [SKIP] C6 — Smoke UI: instanciar/free todas las escenas de scenes/** en headless :: scenes/** no contiene .tscn todavía (AG-3 en curso) (pendiente: sistema aún stub/no disponible)
--------------------------------------------------------------
RESULTADO QA ACEPTACIÓN FASE 1: 0 PASS, 0 FAIL, 6 SKIP (de 6 criterios)
  C1: [SKIP] Partida Inglaterra 1337: new_game + 4 trimestres de órdenes válidas sin crash (0 ms)
  C2: [SKIP] IA de 13 facciones rivales en <2000 ms (medido) (0 ms)
  C3: [SKIP] Save/load exacto: hash de to_dict() igual + continuidad del RNG (0 ms)
  C4: [SKIP] Peste Negra 1348 en event_log con population_modifier -0.35 (europe_west) (0 ms)
  C5: [SKIP] Batalla delegada: informe coherente y captura de región (0 ms)
  C6: [SKIP] Smoke UI: instanciar/free todas las escenas de scenes/** en headless (3 ms)
--------------------------------------------------------------
ACEPTACIÓN: PENDIENTE — 6 criterio(s) SKIP por sistemas aún stub (baseline; exit 1)
```

Segunda ejecución (21:30:17): misma cabecera/INFO, los mismos 6 `[SKIP]` con idénticos motivos, mismo resultado 0/0/6 y exit 1; solo cambian el timestamp y el tiempo de C6 (4 ms). **Comportamiento determinista del baseline.**

### 7.3 Baseline por criterio y qué falta de cada agente

| Criterio §12 | Baseline | Motivo registrado | Requisito para pasar en task-9 (owner) |
|---|---|---|---|
| C1 Partida Inglaterra 1337 (4 trimestres, órdenes válidas, sin crash) | `SKIP` | `GameState.state` vacío tras `new_game()` | AG-2: `GameState.new_game/reset` con §1; `TurnManager` (loop trimestre/año, PG); `EconomySystem.allocate`; `DiplomacySystem.propose`; `DataLoader` cargando `data/` |
| C2 IA 13 facciones <2.000 ms | `SKIP` | Depende de C1; `AIManager.run_all_ai()` sin lógica | AG-2: `AIManager` con 13 facciones IA, mutación observable de `state` y medición <2000 ms |
| C3 Save/load exacto + RNG continuo | `SKIP` | Depende de C1; `to_dict/save/load` devuelven vacío/false | AG-2: `GameState.to_dict/from_dict/save_game/load_game` (§6 contrato) con `rng.snapshot()` |
| C4 Peste Negra 1348 (−0.35, `europe_west`) | `SKIP` | Depende de C1; `TurnManager` no avanza años ni dispara eventos | AG-2: `TurnManager.advance_quarter/advance_year` + disparo de `events_1337.json` y registro en `event_log`/`fired_events` |
| C5 Batalla delegada + captura | `SKIP` | `state.armies` vacío; `MilitarySystem`/`BattleManager` stub | AG-2: `MilitarySystem.move_army`, `BattleManager.resolve_delegated`, `battle_reports` y captura de región |
| C6 Smoke UI `scenes/**` | `SKIP` | `scenes/**` solo tiene carpetas, sin `.tscn` | AG-3: escenas §9 en `scenes/**` + `main_scene` en `project.godot` |

**No-regresión Fase 0 verificada en el baseline:** `validate_data.gd` 0 errores (5.239 comprobaciones) y `tests/run_all.gd` 231/0/1, ambos exit 0; importación `--editor --quit` exit 0. Los datos de Fase 0 no se han alterado.

### 7.4 Incidencias del harness y notas

- Durante la creación del harness se corrigieron **2 avisos de parseo** de GDScript 4.7 tratados como error («tipo inferido desde Variant»): `var report := _last_report(...)` y `var regions_data := ...`. Tras el cambio a tipo explícito (`Variant`), el harness compila y ejecuta (verificado también con `--editor --quit`, exit 0).
- El harness **no toca producción**: solo llama a la API pública §2, lee `GameState.state` y los JSON de `data/`; el único efecto lateral es el save temporal `user://saves/qa_acceptance_ag4.json`, eliminado al final de C3.
- Semántica de aceptación implementada: `exit 0` **solo** con 6/6 `[PASS]`; `[FAIL]` o `[SKIP]` → exit 1. En baseline, los 6 criterios son `SKIP` (no `FAIL`): **pendiente por implementación, no rechazo**.
- Riesgos de verificación (UI headless, presupuesto IA, determinismo de save, evento 1348, batalla estocástica, concurrencia AG-2/AG-3) detallados en `docs/qa/fase1_plan.md` §5.
- **task-9 no reclamada:** la verificación final queda bloqueada hasta que AG-2/AG-3 declaren terminados sus módulos (AG-0 avisará). Checklist preparada en `docs/qa/fase1_plan.md` §6.

*Fin de la sección Fase 1 — baseline (task-8).*

---

## 8. Fase 1 — Verificación final (task-9, 2026-11-21)

**Contexto:** verificación de aceptación de Fase 1 sobre el árbol integrado (`722b778` [AG-2] sistemas + 548 tests, `73bff2f` [AG-3] UI 16 escenas, HEAD `7814dda`). Informe completo con evidencia íntegra y métricas: **`docs/qa/fase1_report.md`**.

> **Veredicto: QA Fase 1: APROBADO** — 6/6 criterios PASS, **0 BLOQUEANTES, 0 MAYORES, 3 MENORES**.

### 8.1 Comandos y códigos de salida

| # | Comando | Exit code | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance.gd` | **0** | **6 PASS / 0 FAIL / 0 SKIP**; `ACEPTACIÓN: OK`; pared ≈2,65 s |
| 1-bis | repetición del harness ×2 | **0 / 0** | Salida normalizada **idéntica**; hash, población y captura idénticos (solo varían los ms de C2) |
| 2 | `--script tests/run_all.gd` | **0** | **548 pasados, 0 fallidos, 1 omitido**; `CI: OK (exit 0)` |
| 3 | `--script tools/validate_data.gd` | **0** | 6 datasets ↔ 6 schemas, **5.239 comprobaciones**, reglas §13 OK, **0 errores**; `map_layout.json` excluido por D-017 |
| 4 | `--editor --quit` | **0** | Importación completa (5 `[DONE]`), **0 ERROR/WARNING** |
| 5 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, **0 ERROR/WARNING** |

### 8.2 Criterios §12 — resultado y métricas

| Criterio | Estado | Evidencia (ejecución canónica) |
|---|---|---|
| C1 Partida Inglaterra 1337 (4 trimestres, órdenes, sin crash) | `PASS` | 1337·T1 → 1338·T1; órdenes 8/8 aceptadas; 109 ms |
| C2 IA 13 facciones <2.000 ms | `PASS` | **17 ms** (16–21 ms en 4 ejecuciones; ≈100× margen); 13 facciones IA |
| C3 Save/load exacto + RNG continuo | `PASS` | hash `900976fefd4c7e01` idéntico; save en disco 96.231 B; restaurado tras perturbación; RNG next=39012 reproducible; 77 ms |
| C4 Peste Negra 1348 (−0,35 `europe_west`) | `PASS` | `event_log` + `fired_events`; **32 regiones afectadas ratio 0,650–0,657**, 15 no afectadas, 9/9 dueños occidentales; población total 13.931.280 → 10.318.856 (−25,9 %); 204 ms |
| C5 Batalla delegada + captura | `PASS` | `army_england_1` Aquitania→**Burgos**; informe de 16 campos coherente; winner=england; `region_captured=true`; **owner castile→england**; 13 ms |
| C6 Smoke UI `scenes/**` | `PASS` | **16/16** escenas instanciadas/liberadas; 749 ms |

### 8.3 Verificación independiente

- **UI-sin-mutación (contrato §7):** auditoría estática de los 25 `.gd` de `scripts/ui/**` (excluye `scripts/ui/dev/`): **0** asignaciones a autoloads/`GameState.state`/`DataLoader.*`/campos de estado, **0** setters de sistemas, **0** mutaciones de contenedores sobre datos de estado; las 31 llamadas dinámicas observadas son métodos de la API §2. Los `.tscn` no referencian autoloads/estado. (Observación M-F1-02: la fachada `tsb_game.gd` expone referencias vivas, sin escrituras detectadas.)
- **`project.godot`:** `config_version=5`, `main_scene=res://scenes/main/main_menu.tscn`, **10 autoloads** intactos, 1920×1080, tema global existente.
- **Capturas `docs/screenshots/`:** **17 PNG 1920×1080** (16 numeradas + `03b_tooltip`), **16 únicas** — `14_after_end_turn` y `15_live_overlay_battle` son byte-idénticas (M-F1-01); correspondencia con §9 verificada y revisión visual de menú, mapa, árbol familiar e informe de batalla.
- **No-regresión de datos:** hashes SHA-256 de los 6 datasets **idénticos** a Fase 0; `data/map_layout.json` = 47 regiones (D-017).
- **Determinismo:** 4 ejecuciones finales con 6/6 PASS y exit 0; invariantes idénticos (hash, población, captura); salida normalizada idéntica.
- **Limpieza:** save QA `user://saves/qa_acceptance_ag4.json` eliminado; sidecars `*.png.import` generados por la importación de Godot retirados para no ensuciar el working tree de AG-0.

### 8.4 Hallazgos (sin bloqueantes)

| ID | Severidad | Hallazgo | Owner sugerido |
|---|---|---|---|
| M-F1-01 | MENOR | `14_after_end_turn.png` y `15_live_overlay_battle.png` son la misma imagen (SHA-256 idéntico) | AG-3 (recapturar 15 o eliminar duplicada) |
| M-F1-02 | MENOR | `tsb_game.gd` expone referencias vivas del estado (`state()`, `armies()`, `region()` comparte arrays); hoy 0 escrituras, riesgo futuro | AG-3 (copias defensivas o documentar solo-lectura) |
| M-F1-03 | MENOR | Tooling de desarrollo en `scripts/ui/dev/` (3 `.gd` + `gen_map_layout.ps1`); no se carga desde escenas | AG-3/AG-0 (mover a `tools/` o documentar) |
| — | INFORMATIVO | 17 capturas para 16 pantallas: `03b_tooltip` es extra de §9 y 14–16 son estados en vivo | — |
| — | INFORMATIVO | `--editor --quit` regenera `docs/screenshots/*.png.import`; retirados por QA. Considerar `.gitignore` o commit de assets | AG-0 |

### 8.5 Riesgos R1–R8 del plan

Todos **cerrados o cerrados con limitación documentada** (detalle en `docs/qa/fase1_report.md` §5). Nota de transparencia: durante la verificación final se **reforzó el harness** en tres puntos (C3 prueba de roundtrip real a disco con perturbación; C5 exige batalla contra región **con defensores** y cruza el flag del informe con el `owner` real; C4 verifica el −35 % **por región**). La versión inicial de C5 del baseline aceptaba una ocupación sin batalla; el fallo era del harness, **no de producción**, y quedó corregido antes del veredicto.

**Limitaciones:** el criterio de UI se valida por instanciación headless + capturas estáticas (sin interacción real), y la medición de IA corresponde a esta máquina y semilla 1337.

*Fin de la sección Fase 1 — verificación final (task-9).*

---

## 9. Fase 2 — Baseline (task-14, 2026-11-21)

**Contexto:** arranque de Fase 2 (GDD v1.4 §10.1/§10.2/§12; contrato `docs/architecture_contracts_fase2.md`). Snapshot **2026-11-21 22:53–22:55**, HEAD `059ae82`. AG-1 (map_borders/portrait), AG-2 (N2/N3, espionaje, extinción) y AG-3 (mapa/retratos/escenas) trabajando en paralelo: durante la ventana de baseline aparecieron y cambiaron archivos de producción, por lo que este baseline es un **snapshot puntual**, no un veredicto.

**Archivos creados por QA (task-14):**

| Archivo | Tamaño | Propósito |
|---|---:|---|
| `tests/qa_acceptance_fase2.gd` | 66.049 B / 1.596 líneas | Harness de aceptación Fase 2 (6 criterios, `extends SceneTree`, sin GUT); compila contra módulos ausentes y los reporta SKIP |
| `docs/qa/fase2_plan.md` | — | Plan QA Fase 2: puerta, matriz criterio→check→comando→evidencia→owner, baseline, riesgos R-F2-01…08 y checklist task-15 |

### 9.1 Comandos y códigos de salida (baseline canónico)

| # | Comando | Exit | Resultado baseline |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase2.gd` | **1** | **2 PASS / 0 FAIL / 4 SKIP** → PENDIENTE (módulos F2 en curso); compila y ejecuta sin cuelgues |
| 1-bis | repetición del harness | **1** | Mismos estados y detalles (sin tiempos): baseline determinista |
| 2 | `--script tests/run_all.gd` | **0** | **557 pasados / 0 fallidos / 1 omitido**; `CI: OK` (durante la ventana se observó transitoriamente 545/3/1 mientras AG-2 editaba tests; el valor canónico del snapshot es 557/0/1) |
| 3 | `--script tools/validate_data.gd` | **0** | 6 datasets ↔ 6 schemas, **5.239 comprobaciones**, **0 errores** (no-regresión de datos) |
| 4 | `--script tests/qa_acceptance.gd` (Fase 1) | **0** | **6/6 PASS** (no regresión de aceptación F1) |
| 5 | `--editor --quit` | **0** | Importación completa (6 `[DONE]`), sin ERROR/WARNING en la salida capturada |
| 6 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, sin ERROR/WARNING |

### 9.2 Salida íntegra del harness (snapshot 22:53:37)

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

==============================================================
 The Sovereign's Blood — QA Aceptación Fase 2 (GDD §10.1/§10.2/§12)
 Godot 4.7.2-stable (official) · headless · 2026-11-21T22:53:37
==============================================================
[INFO] Fase 2 — presencia de artefactos:
  data/map_borders.json: false
  scripts/battle/tactical_battle.gd: true
  scripts/battle/close_combat.gd: true
  scripts/ui/widgets/portrait_frame.gd: true
  scenes/battle/tactical_map.tscn: false
  scenes/battle/close_combat.tscn: false
  assets/art/map/terrain_base.png: true
  data/map_layout.json (debe retirarse al cerrar D-024): true
  10/10 autoloads montados
  [PASS] F2-C1 — Crécy Inglaterra vs Francia resuelto en Niveles 1, 2 y 3 (coherente, sin crash) :: N1=PASS (winner=england; bajas=703/724; asaltos=3; determinista=true); N2=PRESENTE (auto=true rondas=5 acciones=0 winner=france bajas=0/509; determinista=true); N3=PRESENTE (rondas=5 órdenes=0 winner=england bajas=773/641; determinista=true)
  [SKIP] F2-C2 — Extinción dinástica: gobernante + casa sin vivos → game_over derrota sin turnos fantasma :: extinción inmediata F2 aún no integrada (AG-2 task-12 en curso): muertos=4 (casa=plantagenet); resolve.extinct=false; señal dynasty_extinct=false; game_over=false; señales game_over=0; resultado={ "ok": true, "heir_id": "robert_morley", "regency": false, "crisis": false, "extinct": false } (pendiente: módulo Fase 2 aún no integrado)
  [SKIP] F2-C3 — §10.1 Mapa: 47/47 polígonos × 3 años, hit-test, ≤150 KB, CPU <8 ms/frame, terreno y captura :: data/map_borders.json ausente (AG-1 task-11); terreno=true; tactical=false; comparativa=false (pendiente: módulo Fase 2 aún no integrado)
  [SKIP] F2-C4 — §10.2 Retratos: fallback nunca vacío, 5 slots, sucesión en el mapa y capturas :: AG-1/AG-3 aún integrando §10.2 (schema sin 'portrait'; widget no instanciable): datos=false (schema sin propiedad 'portrait'); widget=false (no evaluado: AG-1 aún no añade 'portrait' al schema); slots=4/5 (world_map.gd=false, family_tree.gd=true, diplomacy_screen.gd=true, battle_report.gd=true, court_overview.gd=true); sucesión=false (pendiente); capturas retrato=false comparativa=false (pendiente: módulo Fase 2 aún no integrado)
  [SKIP] F2-C5 — Smoke UI: todas las escenas (tactical_map/close_combat + 16 previas) instanciables headless :: escenas instancian pero scripts en edición (AG-2/AG-3): portrait_frame.gd (no compila); 16/16 escenas instanciadas; total=16 (mín. F1=16); scripts que no compilan=1; faltan F2: tactical_map.tscn, close_combat.tscn (pendiente: módulo Fase 2 aún no integrado)
  [PASS] F2-C6 — No regresión Fase 1: save/load, Peste Negra 1348, determinismo, UI sin mutaciones y escenas :: save/load=hash=db35e62a84e60599; save=96786 B; restaurado=true; peste=año=1348; event_log=true; fired=true; determinismo=true (hash db35e62a84e60599 vs db35e62a84e60599); UI sin mutaciones=true (0 hallazgos); escenas=16 (mín 16)
--------------------------------------------------------------
RESULTADO QA ACEPTACIÓN FASE 2: 2 PASS, 0 FAIL, 4 SKIP (de 6 criterios)
  F2-C1: [PASS] Crécy Inglaterra vs Francia resuelto en Niveles 1, 2 y 3 (coherente, sin crash) (52 ms)
  F2-C2: [SKIP] Extinción dinástica: gobernante + casa sin vivos → game_over derrota sin turnos fantasmas (15 ms)
  F2-C3: [SKIP] §10.1 Mapa: 47/47 polígonos × 3 años, hit-test, ≤150 KB, CPU <8 ms/frame, terreno y captura (1 ms)
  F2-C4: [SKIP] §10.2 Retratos: fallback nunca vacío, 5 slots, sucesión en el mapa y capturas (15 ms)
  F2-C5: [SKIP] Smoke UI: todas las escenas (tactical_map/close_combat + 16 previas) instanciables headless (665 ms)
  F2-C6: [PASS] No regresión Fase 1: save/load, Peste Negra 1348, determinismo, UI sin mutaciones y escenas (450 ms)
--------------------------------------------------------------
ACEPTACIÓN FASE 2: PENDIENTE — 4 criterio(s) SKIP por módulos Fase 2 en curso (baseline; exit 1)
```

*(La salida contiene además los `SCRIPT ERROR: Parse Error … portrait_frame.gd:216` de la línea 216 mientras AG-3 edita el widget; el harness los trata como «script en edición» y no como rechazo. Se omiten aquí por brevedad; el detalle está en `docs/qa/fase2_plan.md` §5/R-F2-06.)*

### 9.3 Baseline por criterio y qué falta

| Criterio | Baseline | Motivo / evidencia | Requisito task-15 (owner) |
|---|---|---|---|
| F2-C1 Crécy N1/N2/N3 | `PASS` | N1 winner=england 703/724 (3 asaltos); N2 `TacticalBattle` auto-resolve winner=france 0/509 (5 rondas); N3 `CloseCombat` winner=england 773/641 (5 rondas); los 3 deterministas y sin crash | AG-2: validar coherencia fina de N2 (un ganador con 0 bajas propias se revisará en la verificación final) |
| F2-C2 Extinción inmediata | `SKIP` | F1 deja interregno; `resolve_succession` devuelve `extinct=false`, sin `dynasty_extinct` ni `game_over`; héroe elegido de otra casa (`robert_morley`) | AG-2: extinción inmediata sin miembros vivos de la casa → `dynasty_extinct` + `game_over(false)` |
| F2-C3 §10.1 Mapa | `SKIP` | `data/map_borders.json` ausente (AG-1); 16 escenas sin tácticas; `terrain_base.png` ya presente (4,1 MB); `map_comparison.png` y capturas de vistas ausentes; `map_layout.json` aún presente | AG-1: `map_borders.json` 3×47 `≤150 KB`; AG-3: integrar 4 capas, hover/click 3 vistas, benchmark `<8 ms`, `map_comparison.png`, retirar `map_layout` (D-024) |
| F2-C4 §10.2 Retratos | `SKIP` | `portrait_frame.gd` presente pero no compila aún; schema sin `portrait`; slots 4/5 (falta `world_map.gd`); capturas ausentes | AG-1: `portrait` en schema; AG-3: widget + 5 slots + sincronía de sucesión + capturas; AG-2: sucesión (ya F1) |
| F2-C5 Smoke escenas | `SKIP` | 16/16 escenas F1 OK; faltan `tactical_map.tscn` y `close_combat.tscn`; 1 script en edición | AG-3: crear las 2 escenas y que sus scripts compilen |
| F2-C6 No regresión F1 | `PASS` | Save/load 96.786 B hash `db35e62a…` restaurado; Peste Negra 1348; determinismo; 0 mutaciones de UI; 16 escenas | — (mantener) |

**No regresión de la batería externa:** `run_all.gd` 557/0/1 exit 0, `validate_data.gd` 0 errores exit 0, `qa_acceptance.gd` (F1) 6/6 exit 0, `--editor --quit` y `--headless --quit` exit 0.

### 9.4 Notas y riesgos registrados

- **Concurrencia:** AG-1/AG-2/AG-3 estaban escribiendo durante el baseline (aparecieron `scripts/battle/*.gd`, `terrain_base.png`, `portrait_frame.gd`; se observó transitoriamente `run_all` 545/3/1 y el parse error de `portrait_frame.gd:216`). El snapshot no se trata como rechazo; la verificación final se hará sobre commits estables.
- **C1/N2:** el `auto_resolve` de N2 devuelve ganador `france` con 0 bajas del atacante y 509 del defensor; el harness lo acepta por coherencia básica (ganador válido, bajas totales >0, rondas, determinismo), pero **se revisará la coherencia de balance en task-15** antes de dar por bueno el criterio.
- **Harness:** durante la construcción se adaptaron las comprobaciones a la API real (`auto_resolve`, `play_order -> bool`, `commit()`/`get_outcome()`), se añadió verificación de compilación de scripts de escena y de `scripts/battle/**`, y se evitó cargar el widget si el schema aún no tiene `portrait` (evita ruido por escritura concurrente).
- **Riesgos R-F2-01…08** (geometría/hit-test, benchmark headless sin GPU, nombres de API de retratos, simulación N2/N3, extinción inmediata, concurrencia, D-024, capturas staging): detalle y mitigación en `docs/qa/fase2_plan.md` §5.
- **task-15 no reclamada:** bloqueada hasta que AG-1/AG-2/AG-3 terminen task-11/12/13; checklist preparada en `docs/qa/fase2_plan.md` §6.
- **Post-snapshot (22:54–22:56, informativo):** AG-1 entregó `data/map_borders.json` — **118.898 B (116,1 KB ≤150 KB)**, schema_version 1, canvas 4096×3072, **47/47/47** regiones, rings 7–186 puntos (media 46,3/región) — aún **sin integrar** en `world_map.gd` (el snapshot 22:53:37 lo vio ausente). AG-3 añadió `scripts/ui/map/map_borders_layer.gd` y `map_entities_layer.gd`; `data/map_layout.json` sigue presente (D-024 pendiente). AG-1 mantiene **auxiliares temporales dentro de `data/`** (`_ag1_boundary.py`, `_ag1_mapgen.py`, `_ag1_pipeline.py`, `__pycache__/`, `_ne_*.geojson`, `_map_debug_*.png`): no son entregables y deben retirarse antes de task-15 (observación provisional MENOR, owner AG-1).

*Fin de la sección Fase 2 — baseline (task-14).*

---

## 10. Fase 2 — Verificación final (task-15, 2026-11-21)

**Contexto:** verificación final de Fase 2 sobre el árbol integrado, HEAD **`5c3aa93`** (`dbfce73` N3→campaña, `f560a40` extinción/N3, `ef25d98` capturas/D-032/D-033, `f302a3c` contrato, `8451304` mapa/retratos/escenas). Informe completo con evidencia íntegra y métricas: **`docs/qa/fase2_report.md`**.

> **Veredicto: QA Fase 2: RECHAZADO** — 5/6 criterios PASS, **1 BLOQUEANTE (B-F2-01)**, 0 MAYORES, 2 MENORES.

### 10.1 Comandos y códigos de salida

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase2.gd` | **1** | **5 PASS / 1 FAIL / 0 SKIP** — `FAIL F2-C1`; 2,5–3,1 s de pared |
| 1-bis | repetición del harness | **1** | Mismos estados/detalles (solo varían ms de C3) → fallo determinista |
| 2 | `--script tests/run_all.gd` | **0** | **709 pasados / 0 fallidos / 1 omitido**; `CI: OK` |
| 3 | `--script tools/validate_data.gd` | **0** | 5.239 comprobaciones, **0 errores/WARN**; `map_borders.json` excluido (D-017/D-024) |
| 4 | `--script tests/qa_acceptance.gd` (Fase 1) | **0** | **6/6 PASS** (no regresión F1) |
| 5 | `--editor --quit` | **0** | 5 `[DONE]`, 0 ERROR/WARNING |
| 6 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |

### 10.2 Criterios §12/§10 — resultado

| Criterio | Estado | Evidencia (ejecución canónica) |
|---|---|---|
| F2-C1 Crécy N1/N2/N3 coherentes | **FAIL** | N1 PASS (england, 703/724, 3 asaltos); **N2 incoherente: informe 0/509 vs esperado 1200/509** (unidad atacante destruida no contabilizada); N3 PASS (england, 773/641, 5 rondas) y N3→campaña D-033 PASS (17 claves, idempotente) |
| F2-C2 Extinción inmediata | `PASS` | `resolve.extinct=true`; `dynasty_extinct`; `game_over=true` (1 señal de derrota); reloj congelado 1337·T1 |
| F2-C3 §10.1 Mapa | `PASS` | 132.962 B ≤147.456; 47/47/47; 7.410 puntos; 0 incidencias; hit-test QA 141/141 + AG-3 141/141 en 3 vistas; terreno 4096×3072; `map_layout` ausente; benchmark 120 frames media **0,153 ms** (máx 5,895 ms) <8 ms; `map_comparison.png` |
| F2-C4 §10.2 Retratos | `PASS` | schema con `portrait` opcional; widget `id != ""` + `is_fallback()=true`; **5/5 slots**; sucesión en el slot hijo del mapa: `edward_iii_plantagenet` → `eduardo_el_principe_negro`; capturas presentes |
| F2-C5 Smoke escenas | `PASS` | **18/18** `.tscn` instancian/liberan; 0 scripts sin compilar (16 previas + tactical_map + close_combat) |
| F2-C6 No regresión F1 | `PASS` | save/load 96.786 B hash `db35e62a…`; Peste Negra 1348; determinismo; 0 mutaciones UI; 18 escenas |

### 10.3 BLOQUEANTE B-F2-01 — N2 no contabiliza bajas de unidades destruidas

- **Reproducción:** `& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path C:\Proyectos\TSB\sovereigns-blood --script tests/qa_acceptance_fase2.gd` → `F2-C1 [FAIL] … N2=PRESENTE (bajas N2 incoherentes: informe=0/509, esperado=1200/509 …)`.
- **Evidencia (sonda):** antes 2 unidades (atacante 1200, defensor 900); después solo defensor 391; `commit()` → `winner=france, attacker_losses=0, defender_losses=509`; `_start_men={"attacker_u1_0":1200,"defender_u1_0":900}`.
- **Causa raíz (AG-2):** `scripts/battle/tactical_battle.gd` — `commit()` (L404-405) calcula bajas con `_side_start_men()` (L975-983), que itera solo `_units` **actuales**; `_remove_destroyed_unit()` (L946-953) elimina las unidades destruidas → sus hombres iniciales no cuentan. Impacto: informe de N2 incoherente y, al aplicar a campaña vía `apply_outcome()`, pérdidas subaplicadas.
- **Owner:** AG-2. **Criterio afectado:** §12 Fase 2 «resultados coherentes (bajas/vencedor)» / contrato §8.1.
- **Re-verificación:** tras el fix (sumar `_start_men` de todas las unidades iniciales por bando o conservar bando inicial), ejecutar harness F2 ×2 → debe dar **6/6 PASS exit 0**; recomendado añadir test de regresión que aniquile una unidad y compare bajas con hombres iniciales (los tests actuales solo exigen «alguna baja >0» / «>=0», por eso no lo detectan).

### 10.4 Observaciones menores e informativos

| ID | Severidad | Hallazgo |
|---|---|---|
| M-F2-01 | MENOR | `map_comparison.png` (2834×1042) y `map_portrait.png` (1620×760) no son 1920×1080 aunque §10.1 pide capturas 1920×1080; el resto sí. 35 capturas únicas y todas las clave presentes. Owner AG-3/AG-0: documentar o reexportar. |
| M-F2-02 | MENOR (harness) | `determinista=false` en el detalle de N2 es artefacto del harness al fallar la coherencia (no se calcula firma); ambas ejecuciones dan 0/509 → el fallo es determinista, no de RNG. |
| M-F2-03 | INFORMATIVO | Se corrigió un bucle de fast-forward del **harness F1** (`tests/qa_acceptance.gd` C4) que paraba a los 8 trimestres y saltaba años; con el fix simula el flujo real y F1 vuelve a 6/6. Cambio solo de tests, no de producción/criterio. |

- **Espionaje** (§5.4, no listado en contrato §8): sonda independiente — `propose(...,{"action":"espia"})` → `ok=true, accepted=true, cost_pg=6`, intel con armies/treasury/regent/at_war/ruler/heir/prestige, persistido en `state.factions.england.intel.france`. PASS.
- **D-024:** `data/map_layout.json` ausente; 3 menciones solo en `tools/validator_core.gd` (comentarios/`NON_SIMULATION_DATASETS`), 0 consumo. PASS.
- **Datos Fase 0:** hashes SHA-256 idénticos; `data/` sin auxiliares de AG-1; `map_borders.json` es el único dataset nuevo. PASS.
- **UI-sin-mutaciones:** 30 `.gd` de `scripts/ui/**` (excl. `dev/`): 0 asignaciones a autoloads/estado, 0 escrituras `state[...]`, 0 setters. `project.godot`: config_version=5, main_scene, 10 autoloads, 1920×1080. PASS.
- **Determinismo:** harness F2 repetido con estados/detalles idénticos; hash/población/captura invariantes; N1/N3 deterministas y N2 con valores reproducibles (el FAIL es determinista).

### 10.5 Riesgos R-F2-* cerrados

R-F2-01 cerrado (141/141 hit-test; autointersecciones/adyacencias geométricas solo revisión visual, documentado) · R-F2-02 cerrado con limitación headless (CPU, no GPU; media 0,153 ms) · R-F2-03 cerrado (widget real + 5 slots + sucesión en slot hijo) · **R-F2-04 FALLO en N2 (B-F2-01)**, N3 PASS · R-F2-05 cerrado (extinción inmediata) · R-F2-06 cerrado (árbol integrado, auxiliares limpiados) · R-F2-07 cerrado (D-024) · R-F2-08 cerrado (capturas en docs).

**Artefactos:** `docs/qa/fase2_report.md` (informe completo), `tests/qa_acceptance_fase2.gd` (harness), `tests/qa_acceptance.gd` (fix de bucle C4), este registro.

*Fin de la sección Fase 2 — verificación final (task-15).*

---

## 11. Fase 2 — Verificación final v1.5 (task-21, cerrada)

**Contexto:** verificación final definitiva de Fase 2 con GDD v1.5, HEAD **`2d283ff`** (informe REA de batallas), con `f1e1bd1` (retratos en los 5 slots), `871d3e4` (B-F2-01), `a4ce356` (AG-1 retratos), `66b85b3`/`bfe1b4e` (AG-0 v1.5) integrados. Informe completo: **`docs/qa/fase2_report.md`** (veredicto final).

> **Estado: QA Fase 2: APROBADO (v1.5)** — **6/6 criterios PASS**, 0 bloqueantes, 0 mayores, 0 menores pendientes; **REA §3.2 verificado** (`docs/rea/gk2_battle_mechanics.md` + `notes_battle.md`). **task-21 COMPLETADA; Fase 2 cerrada.**

### 11.1 Comandos y códigos de salida

| # | Comando | Exit | Resultado |
|---|---|---:|---|
| 1 | `--script tests/qa_acceptance_fase2.gd` | **0** | **6 PASS / 0 FAIL / 0 SKIP**; `ACEPTACIÓN FASE 2: OK` |
| 1-bis | repetición del harness | **0** | Mismos estados/detalles (solo varían ms de C3) → determinista |
| 2 | `--script tests/qa_acceptance.gd` (Fase 1) | **0** | **6/6 PASS**; hash `a511634a85de3550`, save 97.725 B |
| 3 | `--script tests/run_all.gd` | **0** | **716 / 0 / 1**; `CI: OK` |
| 4 | `--script tools/validate_data.gd` | **0** | **5.281 comprobaciones**, 0 errores/WARN; `map_borders.json` excluido (D-017/D-024) |
| 5 | `--editor --quit` | **0** | 5 `[DONE]`, 0 ERROR/WARNING |
| 6 | `--headless --path <repo> --quit` | **0** | `main_scene` arranca, 0 ERROR/WARNING |

### 11.2 Criterios §12/§10 — resultado v1.5

| Criterio | Estado | Evidencia |
|---|---|---|
| F2-C1 Crécy N1/N2/N3 | **PASS** | N1 england 703/724; **N2 france 1200/509 (B-F2-01 cerrado; esperado 1200/509)**; N3 england 773/641; N3→campaña D-033 idempotente; 3 niveles deterministas |
| F2-C2 Extinción | **PASS** | `dynasty_extinct` + `game_over(false)` + reloj congelado 1337·T1 |
| F2-C3 §10.1 Mapa | **PASS** | 132.962 B; 47/47/47; 7.410 puntos; hit-test 141/141 QA + 141/141 AG-3 en 3 vistas; terreno 4096×3072; media 0,184 ms<8; `map_comparison.png` 1920×1080; `map_layout` ausente |
| F2-C4 §10.2 Retratos v1.5 | **PASS** | 14/14 rulers con `portrait` `res://`; **14/14 PNG 256×256**; widget texturiza **14/14** (`is_fallback=false`) y fallback con heredero sin portrait (`is_fallback=true`, id no vacío); **5/5 slots con textura** (mapa 2, árbol 2+7 fallback, diplomacia 1, batalla 2, corte 2+6 fallback); sucesión textura→heredero fallback; 4/4 capturas 1920×1080 |
| F2-C5 Smoke escenas | **PASS** | 18/18 `.tscn`; 0 scripts sin compilar |
| F2-C6 No regresión F1 | **PASS** | save/load 97.725 B hash `a511634a…`; Peste Negra 1348; determinismo; 0 mutaciones UI; 18 escenas |

**Independiente:** 14 PNG 256×256 y 14 campos `res://` válidos/únicos (PowerShell); `PortraitFrame` en los 5 archivos de slot; 38 capturas PNG **únicas** (todas las clave a 1920×1080: map_atlas_1337/1402/1453, map_portrait, map_comparison, portraits_contact_sheet_final, succession_portrait, tactical_map, close_combat); UI 30 `.gd` con 0 mutaciones; `project.godot` config 5/main_scene/10 autoloads/1920×1080; D-024 con 0 referencias; `characters.json` cambia solo por los 14 `portrait` (esperado v1.5) y los otros 5 datasets mantienen hash Fase 0. **§10.3 sprites = Fase 3 (D-037), no criterio Fase 2.**

### 11.3 REA batallas §3.2 — VERIFICADO y cierre

- `docs/rea/gk2_battle_mechanics.md` (commit `2d283ff`; **12.517 B, 155 líneas, 1.998 palabras**) + anexo `notes_battle.md` (8.065 B, 1.322 palabras).
- **Método/estado:** §1 verifica DOSBox ausente y declara las mecánicas N2/N3 **NO observadas** aspecto por aspecto (§2, 8 aspectos), sin inventar; incluye protocolo de capturas para reactivación. Limitación **aceptada como no bloqueante** por AG-0.
- **Estructura:** §3 `SUNIT.DAT` (49.152 B = 96×512 B; periodicidad, sin paleta; límites declarados), §4 `KPAT.DAT` (45.450 B; máscaras/patrones binarios), §5 `GRPDATA.DAT` (45.475 B; banco raster/teselas); §6 lecciones §10.3 (8 criterios de diseño propio).
- **Legalidad:** §7 declara sin desensamblado/descompilación de `.EXE`, sin copia de píxeles/paletas/assets ni texto del juego; previsualizaciones eliminadas; `docs/rea/` solo contiene 4 `.md` (sin binarios/imágenes/base64). Las 2 menciones de `.EXE` son declaraciones de no-análisis.
- **Resultado: REA PASS.** **task-21 COMPLETADA**; Fase 2 cerrada y apta para tag `fase-2`.

*Fin de la sección Fase 2 — verificación final v1.5 (task-21 cerrada).*

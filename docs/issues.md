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

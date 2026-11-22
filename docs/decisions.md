# Registro de decisiones — The Sovereign's Blood

Decisiones del Coordinator (AG-0) ante ambigüedad del GDD, conforme a Sección 11.2.
Formato ADR abreviado: contexto → decisión → consecuencias.

---

## D-001 · Base del repositorio local (2026-11-21)
**Contexto:** el remoto `origin/main` ya contiene un historial previo (README + initial commit).
**Decisión:** el repo local se crea por `git clone` del remoto y el primer commit del equipo (`[AG-0] init`) se añade **encima** del historial existente. Nunca se reescribe historia ni se hace force-push (GDD §3.2).
**Consecuencia:** primer push = commit `[AG-0] init` con GDD en la raíz, sin alterar commits previos.

## D-002 · Paralelización de Fase 0 (2026-11-21)
**Contexto:** GDD §11.3 propone flujo secuencial `AG-REA → AG-1`, pero §12 exige en Fase 0 el scaffold de AG-2 y §1.1 prioriza agilidad.
**Decisión:** AG-REA, AG-1 y AG-2 arrancan en paralelo con scopes de escritura disjuntos: AG-REA (`docs/rea/**`), AG-1 (`data/**`), AG-2 (`scripts/**`, `tests/**`, `tools/**`, `project.godot`). El schema del Escenario 1 está fijado por GDD §7; el informe REA aporta lecciones de modelado que AG-1 consume como entrada (no como precondición bloqueante).
**Consecuencia:** se reduce el tiempo de Fase 0; AG-0 verifica coherencia conceptual REA ↔ datasets al integrar.

## D-003 · Autoría del informe REA (2026-11-21)
**Contexto:** GDD §3 atribuye el entregable `docs/rea/gk2_data_lessons.md` a AG-REA; §11.2 (AG-1) dice que AG-1 lo redacta "a partir del informe de AG-REA". Ambigüedad.
**Decisión:** AG-REA escribe directamente `docs/rea/gk2_data_lessons.md` (entregable de §3 y Anexo A). AG-1 lo lee y aporta, si procede, notas de alineación en `data/sources.md`/data model, sin reescribir el informe. El resto del equipo no accede a la carpeta GK2.
**Consecuencia:** una sola fuente de verdad para el informe; se evita doble autoría y conflicto de archivos.

## D-004 · Implementación de `tools/validate_data.gd` (2026-11-21)
**Contexto:** GDD §7 exige JSON Schema draft 2020-12; no hay librería externa disponible y no se instalan dependencias fuera del workspace.
**Decisión:** `validate_data.gd` implementa un validador genérico del subconjunto de JSON Schema efectivamente usado por `data/schema/*.json` (`type`, `required`, `properties`, `additionalProperties`, `items`, `enum`, `const`, `minimum`, `maximum`, `oneOf`, `pattern`, `minItems`, `uniqueItems`) más reglas cruzadas de §13 (adyacencias simétricas, capital existente, dueño por año). Sin ejecutar en `--headless` desde CI: `tests/run_all.gd` lo invoca.
**Consecuencia:** validación reproducible sin dependencias; los schemas deben mantenerse dentro del subconjunto soportado.

## D-005 · Operaciones Git centralizadas en AG-0 (2026-11-21)
**Contexto:** varios agentes escriben en paralelo en el mismo working tree (GDD §14: riesgo "agentes pisando archivos").
**Decisión:** ningún subagente ejecuta comandos `git`. AG-0 hace commits/push por módulo, con prefijo `[AG-N]` y `docs/STATUS.md` actualizado. Un archivo = un owner a la vez.
**Consecuencia:** historial limpio y sin carreras de índice; los agentes entregan archivos, AG-0 commitea.

## D-006 · Criterio de "compila" para Fase 0 (2026-11-21)
**Contexto:** `run/main_scene` vacío en Fase 0; el proyecto no tiene escenas todavía.
**Decisión:** "compila" se verifica con `godot --headless --path <repo> --editor --quit` (importación de proyecto) y con `godot --headless --path <repo> --script tests/run_all.gd --quit` (CI). El criterio A5 se evalúa por salida sin errores críticos en ambos comandos.
**Consecuencia:** no se crean escenas placeholder solo para satisfacer main_scene; AG-3 las añadirá en Fase 1.

## D-007 · GDD en el repo (2026-11-21)
**Contexto:** GDD §3.2.6 exige que el GDD viva también en el repo.
**Decisión:** el GDD maestro se copia a la raíz del repo y se versiona; el original de `C:\Proyectos\TSB` sigue siendo la fuente de verdad. Cambios de alcance se registran como commit `[GDD]` + entrada en este archivo.
**Consecuencia:** cualquiera que revise el repo remoto ve el GDD completo.

## D-008 · Alcance de datos de Fase 0 (2026-11-21)
**Contexto:** el GDD exige 14 facciones y 8 jugables para 1337; definir el volumen de regiones/personajes sin inventar detalle excesivo.
**Decisión:** el Escenario 1 incluye las 14 facciones listadas en §4.2 (8 marcadas `playable: true` según §2.1), un mapa de ~40 regiones que cubre Europa Occidental/Central, Iberia, Italia, Balcanes, Anatolia, Levante y Norte de África costero, y personajes clave con genealogía suficiente para matrimonios/sucesión. Todo dato histórico lleva `source` (URL) o `"estimate": true`.
**Consecuencia:** volumen manejable y validable; ampliable en Fase 3.

## D-009 · Formato envelope de los datasets (2026-11-21)
**Contexto:** AG-1 propone envolver los arrays en un objeto con `schema_version`, y AG-2 debe construir `validate_data.gd`/`data_loader.gd` en paralelo.
**Decisión:** se adopta el envelope `{"schema_version": 1, "factions|characters|regions|units|events": [...]}` para `factions.json`, `characters.json`, `regions.json`, `units.json` y `events_1337.json`; `scenarios/scenario_1337.json` queda como objeto único §7.5 sin envelope. Los `data/schema/*.schema.json` validan el fichero completo, envelope incluido. `validate_data.gd` mapea por nombre de archivo y no asume arrays en la raíz.
**Consecuencia:** versionado de datos explícito y validación genérica; AG-2 debe respetarlo (prevalece sobre propuestas previas).

## D-010 · Capital dual Praga (HRE y Bohemia) (2026-11-21)
**Contexto:** GDD §4.2 asigna Praga como capital tanto al Sacro Imperio como a Bohemia; en 1337 el emperador Luis IV residía habitualmente en Múnich y el dueño de Praga es Bohemia.
**Decisión:** se respeta el GDD: ambas facciones usan `region_praga` como capital. La regla del validador es solo "la capital existe como región", no "la facción posee su capital". Se documenta en `data/sources.md`. Cualquier futura corrección se hará en el validador/datos con entrada en este registro.
**Consecuencia:** fidelidad al GDD sin inventar regiones; caso raro (capital no propia) que la Fase 1 debe tolerar en UI.

## D-011 · Nomenclatura de casas en `characters.json` (OBS-02) (2026-11-21)
**Contexto:** QA (OBS-02) detecta que Benedicto XII usa `house: "fournier"` (GDD §4.2: «—») y An-Nasir Muhammad `house: "qalawun"` (GDD: «Bahri»).
**Decisión:** se mantienen ambos valores: `fournier` es la familia papal documentada (el campo `house` identifica familia/casa, no solo dinastía gobernante) y `qalawun` es la dinastía qalawuní que encabeza la línea Bahri mameluca; el GDD §4.2 usa «Bahri» como etiqueta de dinastía amplia. Se documenta la equivalencia en `data/sources.md` §2 y no se altera el JSON (la validación y la jugabilidad no se ven afectadas; el patrón de `house` es `^[a-z][a-z0-9_]*$`).
**Consecuencia:** coherencia histórica sin forzar valores vacíos; si en Fase 1 el sistema dinástico exige distinguir «casa papal» de «dinastía», se añadirá un campo `dynasty`/`house_type` en vez de reutilizar `house`.

## D-012 · Anexo técnico REA `docs/rea/notes.md` (OBS-04) (2026-11-21)
**Contexto:** GDD §3 dice del entregable REA «tabla de equivalencias… Nada más»; AG-REA añadió un anexo de método (180 líneas) separado del informe de 2 páginas.
**Decisión:** el entregable de Fase 0 sigue siendo `docs/rea/gk2_data_lessons.md` (1.721 palabras ≈ 2 páginas). `docs/rea/notes.md` se acepta como apéndice interno de reproducibilidad/método, no como entregable adicional ni como especificación de reimplementación; no lo consume el equipo de desarrollo y cumple las prohibiciones de §3 (sin análisis de `.EXE`, sin texto transcrito, sin código derivado).
**Consecuencia:** se conserva la trazabilidad del método sin ampliar el alcance del informe.

## D-013 · CI de Fase 0 y GitHub Actions (2026-11-21)
**Contexto:** AG-2 implementó `tools/ci_headless.ps1` (importación + validador + suite) en lugar de un workflow `.github/workflows/ci.yml`.
**Decisión:** para Fase 0, «CI headless corriendo» se cumple con `tools/ci_headless.ps1` y los comandos de `§3.1` (verificado por AG-4, exit 0). El workflow de GitHub Actions se difiere a Fase 1 (no es requisito de §12; añade dependencia de red/runner Windows y mantenimiento).
**Consecuencia:** Fase 0 no depende de infraestructura remota; el workflow se añadirá con los tests de sistemas de Fase 1.

## D-014 · Registro de QA por fase (2026-11-21)
**Contexto:** AG-4 entregó `docs/issues.md` con el informe completo de QA (538 líneas) y veredicto.
**Decisión:** `docs/issues.md` es el registro de QA acumulativo: cada fase añade su sección o archivo `docs/qa/fase-N.md` si el volumen crece; el veredicto y la evidencia se enlazan desde `docs/STATUS.md`. El informe incluye salidas íntegras y códigos de salida para la verificación de Kimi.
**Consecuencia:** trazabilidad de QA por fase sin mezclar con `docs/decisions.md`.

## D-015 · `audio_manager.gd` como autoload al activar AG-5 (OBS-K1) (2026-11-21)
**Contexto:** verificación Kimi de Fase 0: APROBADO CON OBSERVACIONES (1 menor, OBS-K1). El GDD §8.1 lista `scripts/autoload/audio_manager.gd`, pero el scaffold de Fase 0 registró 10 autoloads y dejó audio para la fase de arte/audio.
**Decisión:** al activar AG-5 (Art Pipeline, Fase 3) se creará `scripts/autoload/audio_manager.gd` y se registrará como autoload en `project.godot` en el mismo commit de activación de AG-5; hasta entonces no se crea para no dejar autoloads vacíos sin uso. Se anota en `docs/STATUS.md` como pendiente de Fase 3.
**Consecuencia:** OBS-K1 queda registrada y trazable; no hay bloqueo para Fase 1/Fase 2.

## D-016 · Contrato de integración de Fase 1 (2026-11-21)
**Contexto:** AG-2 (sistemas) y AG-3 (UI) trabajan en paralelo y el GDD §8.2 solo fija firmas mínimas; sin un estado canónico compartido la integración fallaría.
**Decisión:** `docs/architecture_contracts_fase1.md` v1.0 es vinculante para Fase 1: define `GameState.state` (formato JSON exacto), la API congelada de los 10 autoloads, el orden del flujo de turno, las fórmulas mínimas, la regla «la UI no muta estado» y los scopes de escritura por agente. AG-2/AG-3 no lo editan; los cambios se solicitan a AG-0 y se registran aquí.
**Consecuencia:** integración paralela con un único punto de verdad; los desvíos se detectan en QA.

## D-017 · `data/map_layout.json` para el mapa principal (2026-11-21)
**Contexto:** `regions.json` no tiene coordenadas y el GDD §8.1 exige un mapa de regiones clickeable; la geografía precisa es Fase 3.
**Decisión:** AG-3 crea `data/map_layout.json` con coordenadas normalizadas por `region_id` (solo presentación, no estado de simulación ni dato histórico). No se modifica `regions.json` ni lo valida `validate_data.gd`. En Fase 3 AG-1 lo sustituirá por posiciones cartográficas con fuente.
**Consecuencia:** mapa funcional en Fase 1 sin tocar datasets históricos; separación limpia entre datos de juego y presentación.

## D-018 · Exclusión de datos de presentación en el validador (2026-11-21)
**Contexto:** AG-2 detectó que `tools/validator_core.gd` recorre `data/**/*.json` y emitía 2 `[WARN]` por `data/map_layout.json` (presentación de AG-3, D-017), que no tiene schema ni corresponde a datos de simulación.
**Decisión:** el validador excluye explícitamente `data/map_layout.json` (y futuros datos de presentación declarados) del conjunto de datasets de juego; los 6 datasets de simulación se siguen validando con sus schemas y reglas cruzadas. AG-2 aplica el cambio en `tools/validator_core.gd` (task-10).
**Consecuencia:** `validate_data.gd` sin warnings; los datos de presentación no se confunden con contenido de juego.

## D-019 · Semántica de `EconomySystem.allocate` (2026-11-21)
**Contexto:** el contrato §2 no precisaba si `allocate(region_id, worker_class, amount)` asigna un delta o un objetivo absoluto; AG-2 implementó objetivo absoluto (conservando el total de trabajadores) y AG-3 envió totales objetivo desde el panel de región.
**Decisión:** se fija la semántica **absoluta**: `amount` es el total de trabajadores de esa clase en la región; el sistema valida contra la población trabajadora y cobra 1 PG por orden. Documentado aquí y en el contrato; ambos componentes ya la usan de forma consistente.
**Consecuencia:** sin ambigüedad de integración; si en Fase 2 se necesita reasignación incremental, se añadirá un método específico en vez de cambiar este.

## D-020 · Educación familiar en el MVP (2026-11-21)
**Contexto:** GDD §5.3 describe educación con asignación de tutor (PG/turno) y §12 incluye «educación» entre las mecánicas familiares de Fase 1; el contrato §8.2 no define un método `educate`, solo `marry`/`advance_year`.
**Decisión:** en Fase 1 la educación de menores (6-16 años) es **automática**: `DynastySystem.advance_year` aplica educación a los menores de cada facción (1 PG/año por facción, crecimiento de stats por edad). La asignación explícita de tutor y el botón correspondiente en el árbol familiar quedan para Fase 2 (UI los muestra desactivados). La mecánica «educación» de §12 queda cubierta por el sistema.
**Consecuencia:** MVP sin acción adicional; si Kimi exige asignación explícita, se implementará `set_tutor(child_id, tutor_id)` en Fase 2 (cambio localizado en DynastySystem + family_tree).

## D-021 · Capturas de pantalla en el repo (2026-11-21)
**Contexto:** GDD §13 exige capturas de cada pantalla en `docs/screenshots/`; AG-3 generó 16 PNG 1920×1080 del flujo real + tooltip en `C:\Proyectos\TSB\.ui_check\` (fuera del repo).
**Decisión:** se copian las 16 capturas a `docs/screenshots/` y se versionan (≈4,8 MB) como evidencia de la checklist manual de Fase 1; `.ui_check/` queda como material bruto de trabajo y no se versiona.
**Consecuencia:** el repo remoto es autocontenido para la verificación de Kimi; el peso es aceptable para GitHub.

## D-022 · Referencias vivas en la fachada de UI (M-F1-02) (2026-11-21)
**Contexto:** QA final de Fase 1 detecta que `scripts/ui/tsb_game.gd` expone referencias vivas del estado (`state()`, `armies()`, `region()` comparte arrays); hoy hay **0 escrituras** (auditoría estática de 25 `.gd` de `scripts/ui/**`) y el contrato §7 prohíbe mutar.
**Decisión:** se acepta para el MVP: la fachada es de solo lectura por contrato y QA auditó 0 mutaciones; las copias defensivas (`duplicate(true)` en getters sensibles) se implementarán en Fase 2 junto con los pulidos de UI.
**Consecuencia:** riesgo futuro documentado y acotado; si aparece una mutación, se corrige en la fachada sin tocar sistemas.

## D-023 · Tooling de desarrollo en `scripts/ui/dev` (M-F1-03) (2026-11-21)
**Contexto:** AG-3 dejó en `scripts/ui/dev/` las herramientas `ui_smoke.gd`, `integration_probe.gd`, `ui_screenshots.gd` y `gen_map_layout.ps1`, no referenciadas por ninguna escena.
**Decisión:** se mantienen versionadas como tooling de desarrollo/QA (útiles para regresión visual y smoke), documentadas como no cargadas por el juego. Su migración a `tools/dev/` queda como mejora opcional de Fase 2, sin impacto funcional.
**Consecuencia:** trazabilidad de cómo se generaron capturas y layout; el binario del juego no las incluye salvo export selectivo (queda anotado para el pipeline de export).

## D-024 · Deprecación de `data/map_layout.json` (módulo Mapa §10.1) (2026-11-21)
**Contexto:** GDD v1.3 §10.1 sustituye el tablero hexagonal placeholder (`map_layout.json`, D-017) por un mapa atlas con fronteras vectoriales por año.
**Decisión:** `map_layout.json` queda **deprecado** al completar el módulo Mapa: la UI deja de consumirlo en `world_map.tscn`; las posiciones pasan a `data/map_borders.json` (`center`) y el terreno a `assets/art/map/terrain_base.png`. Se elimina del repo en el commit de cierre del módulo, junto con su exclusión en el validador (D-018), que puede retirarse entonces.
**Consecuencia:** una sola fuente de geometría (map_borders) y sin datos de presentación duplicados; la decisión se marca como ejecutada en `docs/STATUS.md` al cerrar Fase 2.
**Estado (2026-11-22): EJECUTADA.** `data/map_layout.json` eliminado en `[AG-3]` (`e748a71`); la UI usa `map_borders.json`; QA F2 confirma 0 referencias de consumo y captura de las 3 vistas de año.

## D-025 · Contrato de integración de Fase 2 (2026-11-21)
**Contexto:** AG-1 (fronteras), AG-2 (batallas N2/N3, espionaje, extinción) y AG-3 (mapa, retratos) trabajan en paralelo sobre las nuevas especificaciones §10.1/§10.2.
**Decisión:** `docs/architecture_contracts_fase2.md` v1.0 es vinculante para Fase 2: formato de `map_borders.json`, arquitectura de 4 capas del mapa, API `TacticalBattle`/`CloseCombat`, contrato de retratos y slots, semántica de espionaje/extinción y scopes por agente. Los agentes no lo editan; cambios vía AG-0.
**Consecuencia:** integración paralela con un único punto de verdad; los desvíos los detecta QA.

## D-026 · Terreno base del mapa generado por código (2026-11-21)
**Contexto:** §10.1 exige textura 4096×3072 estilo pergamino/acuarela de época, prohibido satélite/fantasía; no se versionan assets raster de terceros.
**Decisión:** AG-3 genera `assets/art/map/terrain_base.png` (4096×3072) de forma **determinista** con `tools/generate_map_terrain.gd` a partir de los polígonos de `map_borders.json` (tierra) y ruido procedural (relieve, ríos, bosques) + estilos de pergamino; se versiona una sola vez. La generación es reproducible y revisable (script en repo).
**Consecuencia:** arte propio, sin dependencias externas ni licencias dudosas; estilo consistente con §10; Fase 3 puede repintar el terreno sin cambiar el código de capas.

## D-027 · Retratos de soberanos en Fase 2 (2026-11-21)
**Contexto:** §10.2 exige 5 slots de retrato con fallback automático; los retratos ilustrados finales son de AG-5 en Fase 3.
**Decisión:** en Fase 2 el campo opcional `portrait` de `characters.json` queda vacío/ausente; AG-3 implementa `portrait_frame.gd` con fallback **heráldica generativa de la casa + silueta genérica por sexo/edad**, usado en los 5 slots (mapa, árbol, diplomacia, batalla, corte). El marco dorado y el fondo pergamino se generan por código. Nunca se muestra un hueco.
**Consecuencia:** requisito §10.2 funcional sin assets finales; AG-5 solo sustituirá PNGs en Fase 3.

## D-028 · Referencia comparativa del mapa (2026-11-21)
**Contexto:** §10.1 pide una captura comparativa lado a lado con el mapa de GK2; esa captura no existe en el workspace y la carpeta GK2 es de solo lectura y solo AG-REA. El material de Koei no puede versionarse en el repo (§1.2/§3).
**Decisión:** el repo incluirá `docs/screenshots/map_comparison.png` comparando nuestro mapa con el **atlas histórico de dominio público de William R. Shepherd (1923-26)** como referencia de calidad y de fronteras; se solicita al usuario una captura del mapa de GK2 para la comparativa directa (se incorporará si la aporta, sin versionar material de Koei). La limitación se documenta en `docs/qa/` y `docs/STATUS.md`.
**Consecuencia:** criterio §10.1 cubierto con una referencia visual legítima; la comparación directa con GK2 queda como aportación del usuario.

## D-029 · Batallas Nivel 2 y 3 — API (2026-11-21)
**Contexto:** §6.2/§6.3 y §8.2 (`launch_tactical` devuelve `Node`); se necesita una API concreta para que AG-3 pinte y AG-2 resuelva sin acoplar UI y lógica.
**Decisión:** `BattleManager.launch_tactical` devuelve un nodo `TacticalBattle` (lógica de batalla, no UI) con API de solo consulta + órdenes; el Nivel 3 se resuelve con `CloseCombat` y cartas de orden (`carga`, `disparo`, `formacion`, `finta`, `retirada`); el comandante con mayor Mando obtiene +1 orden por ronda. Toda tirada usa `GameState.rng` (determinismo). El `apply_outcome()` aplica bajas/captura vía `MilitarySystem`.
**Consecuencia:** la UI solo renderiza y envía órdenes; los tests de Crécy pueden ejecutarse headless sin escenas.

## D-030 · Espionaje (2026-11-21)
**Contexto:** §5.4 lista "Enviar espía" (Fase 2, 6 PG) y §12 Fase 2 exige espionaje.
**Decisión:** se implementa como acción `espia` de `DiplomacySystem.propose`, coste 6 PG, con éxito dependiente de Astucia/relación; el resultado (`armies`, `treasury`, `regent_id`, `at_war`) queda en `state.factions[actor].intel[target]` (serializable y mostrable en diplomacia). Determinista con `GameState.rng`.
**Consecuencia:** información persistente en la partida y testeable; sin UI nueva obligatoria salvo mostrar el informe.

## D-031 · Extinción dinástica como fin de partida (2026-11-21)
**Contexto:** §12 Fase 2 exige que la pérdida de líder sin herederos termine la partida; §5.3 describe crisis/interregno y extinción.
**Decisión:** si muere el gobernante y no queda ningún miembro vivo de su casa (sin heredero ni parientes), `DynastySystem` emite `dynasty_extinct` y `TurnManager` declara derrota inmediata (jugador: `game_over(false, "dinastía extinta")`; IA: eliminación). Si hay parientes sin heredero directo, se mantiene la crisis/interregno existente.
**Consecuencia:** condición de derrota §4.5 implementada y testeable; sin turnos fantasma tras la extinción.

## D-032 · `map_borders.json` como dato de presentación en el validador (2026-11-21)
**Contexto:** el validador detectaba `data/map_borders.json` como dataset sin schema y emitía 2 `[WARN]`; es geometría de presentación del mapa (§10.1), no estado de simulación, y QA la valida con criterios propios.
**Decisión:** `tools/validator_core.gd` excluye `map_borders.json` junto a `map_layout.json` (D-018) mediante `NON_SIMULATION_DATASETS`; los 6 datasets de juego siguen validándose con sus schemas y reglas cruzadas. QA valida `map_borders` por invariantes propios (47/47/47, ≥150 KB, anillos, hit-test).
**Consecuencia:** `validate_data.gd` vuelve a 0 `[WARN]`; la validación de simulación no se dispersa con datos de render.

## D-033 · Aplicación del Nivel 3 al estado de campaña (2026-11-21)
**Contexto:** AG-3 comprobó que el combate cerrado (Nivel 3) resolvía el duelo pero no aplicaba el resultado a la campaña (faltaba el mapeo unidad→ejército/región), a diferencia de N1/N2.
**Decisión:** AG-2 añade `BattleManager.apply_close_combat_outcome(attacker_army_id, defender_army_id, region_id, outcome) -> Dictionary`, que traduce el resultado del duelo a bajas/captura vía `MilitarySystem.apply_battle_outcome` (idempotente). AG-3 lo invoca cuando el jugador resuelve el combate cerrado en el contexto de una batalla de campaña; el acceso directo desde el selector de nivel se mantiene como vista previa. Contrato de Fase 2 actualizado en §4.
**Consecuencia:** jugar una batalla en Nivel 3 tiene efecto en la partida, igual que N1/N2; test de regresión en AG-2/AG-4.

## D-034 · Sincronización GDD v1.5 (2026-11-21)
**Contexto:** el GDD maestro pasó a v1.5 con tres cambios vinculantes: §3.2 REA ampliado (observación de batallas Nivel 2/3 en DOSBox y estructura de `SUNIT.DAT`/`KPAT.DAT`/`GRPDATA.DAT`), §10.2 retratos finales de los 14 soberanos diseñados por Kimi, §10.3 sprites de unidades (Fase 3).
**Decisión:** se sincroniza `GDD_The_Sovereign's_Blood.md` en el repo (commit `[GDD]`). Las nuevas especificaciones se incorporan al cierre de Fase 2: retratos integrados y REA ampliado son criterios de aceptación (§12 actualizado); §10.3 (sprites) queda planificado para Fase 3 con AG-5.
**Consecuencia:** la fuente de verdad remota coincide con la v1.5; el alcance de Fase 2 se amplía con estos dos entregables.

## D-035 · Integración de los 14 retratos finales (§10.2 v1.5) (2026-11-21)
**Contexto:** el usuario entregó `Retratos_Soberanos_TSB.zip` con 14 PNG 256×256 (estilo miniatura iluminada, escudo heráldico integrado) y hoja de contacto; sustituyen cualquier retrato previo.
**Decisión:** se copian a `assets/art/portraits/<character_id>.png` del repo; los 7 archivos con nombre corto se renombran al id real de `characters.json` (john_bohemia→jan_lucembursky, charles_robert→karoly_robert_anjou, alfonso_xi→alfonso_xi_borgona, peter_iv→pere_iv_d_arago, casimir_iii→kazimierz_iii_piast, david_ii→david_ii_bruce, oz_beg ya coincidía). AG-1 añade a cada `role: ruler` el campo `portrait: "res://assets/art/portraits/<id>.png"`. AG-3 acepta tanto id como ruta `res://` en el widget. El fallback heráldico se conserva para herederos/personajes sin retrato y la sucesión cambia el retrato al personaje vigente. Hoja de contacto final en `docs/screenshots/portraits_contact_sheet_final.png`.
**Consecuencia:** los 5 slots de §10.2 muestran los retratos finales; AG-5 solo producirá retratos de herederos/escenarios 1402-1453 en Fase 3.

## D-036 · REA ampliado de batallas Nivel 2/3 (§3.2 v1.5) (2026-11-21)
**Contexto:** el usuario autoriza reactivar a AG-REA para documentar mecánicas observadas de batalla en DOSBox y la estructura de `SUNIT.DAT`, `KPAT.DAT`, `GRPDATA.DAT`, con el fin de alimentar el estilo de sprites de §10.3.
**Decisión:** AG-REA produce `docs/rea/gk2_battle_mechanics.md` con: tipos de unidad y su distinción visual, animaciones de ataque y proyectiles, moral/fatiga en el mapa táctico, formación/movimiento de grupos y cadencias del combate cerrado; además de la estructura de los tres `.DAT` (dimensiones, cuadros, convenciones). Siguen prohibidos: descompilar ejecutables, copiar píxeles/paletas/assets y transcribir texto. Si el entorno no permite ejecutar DOSBox (no está instalado), AG-REA documenta la limitación y extrae lo observable de los datos + lecciones de diseño, solicitando capturas al usuario. El informe es criterio de aceptación de Fase 2 (GDD §12 v1.5).
**Consecuencia:** el diseño de sprites de Fase 3 tendrá referencia de legibilidad sin material derivado de Koei.

## D-037 · Sprites de unidades §10.3 — planificación Fase 3 (2026-11-21)
**Contexto:** §10.3 exige sprites 64×64/64×80 con hojas de animación, proyectiles visibles y campo opcional `units.json.sprite_sheet`; AG-5 se activa en Fase 3.
**Decisión:** en Fase 2 solo se entrega el REA de apoyo (D-036); la producción de sprites, la animación con proyectiles y el campo `sprite_sheet` en `units.json` se implementan en Fase 3 con AG-5 según la hoja de estilo derivada de §10.2/§10.3. No se añade aún el campo para no alterar datos sin assets.
**Consecuencia:** alcance de Fase 2 cerrado sin scope creep; Fase 3 arranca con la especificación y el informe REA listos.

## D-038 · REA ampliado sin observación DOSBox: limitación aceptada (2026-11-22)
**Contexto:** GDD v1.5 §3.2 autoriza observar batallas N2/N3 en DOSBox; el entorno no tiene DOSBox instalado (verificado en PATH, `C:\Tools`, Program Files ×2, scoop/choco, Downloads y workspace) y la observación interactiva no es viable en una sesión de agente sin emulador.
**Decisión:** el entregable `docs/rea/gk2_battle_mechanics.md` declara aspecto por aspecto (**no inventa**) qué mecánicas no se pudieron observar, documenta el método estructural usado (`SUNIT.DAT` 96×512 B, `KPAT.DAT` máscaras/patrones, `GRPDATA.DAT` raster/tiles, sin paleta embebida) y entrega las lecciones de diseño §10.3; incluye un protocolo de 6 bloques de capturas para que el usuario complete §2 en una reactivación. QA de Fase 2 lo verifica como PASS con la limitación aceptada como no bloqueante.
**Consecuencia:** el requisito de informe REA ampliado se cumple con rigor y trazabilidad; la observación real queda como aportación opcional del usuario.

## D-039 · Sincronización y normalización del GDD v1.6 (2026-11-22)
**Contexto:** el usuario indica que el GDD v1.6 ya está en el repo; el workspace tenía el contenido v1.6 (bloque §10.3 «Sprites núcleo ENTREGADOS» y plan Fase 3) pero el campo «Versión del documento» seguía en 1.5 y el repo tenía v1.5.
**Decisión:** se copia el GDD actualizado al repo y se normaliza el campo de versión a **1.6** (coherente con el campo «Estado», que ya describía v1.6); commit `[GDD]`. El contenido nuevo (§10.3 + plan Fase 3) se adopta como vinculante y se abre Fase 3.
**Consecuencia:** repo y workspace coinciden en v1.6; la verificación externa de Kimi se hará contra esta versión.

## D-040 · Reparto de la integración de sprites (PRIORIDAD 1 Fase 3) (2026-11-22)
**Contexto:** el usuario asigna la integración de sprites a AG-2 (datos + batalla) y AG-5 (assets); el render de N2/N3 vive en `scenes/**`/`scripts/ui/**`, cuya propiedad es de AG-3.
**Decisión:** reparto por capas: **AG-5** extrae/reescala/copia los assets y fuentes; **AG-2** añade `sprite_sheet` a `units.json` + schema y expone estado de animación/orientación/proyectiles desde `TacticalBattle`/`CloseCombat` (lógica, sin nodos de UI); **AG-3** renderiza sprites, mirroring y capa de proyectiles en `tactical_map.tscn`/`close_combat.tscn`; **AG-4** valida carga, simulaciones y capturas. Los datos de `units.json` se editan por AG-2 con excepción explícita a la propiedad habitual de AG-1 (D-005 se mantiene para git).
**Consecuencia:** sin pisar archivos ajenos y sin mezclar lógica de batalla con UI; los tests de AG-2 cubren datos/estado y los de AG-4 el conjunto.

## D-041 · Almacenamiento de fuentes y proyectiles de sprites (2026-11-22)
**Contexto:** GDD v1.6 §10.3 pide producción 64×64/64×80 y conservar los PNG 512 como fuente; Godot importa cualquier PNG dentro de `res://`.
**Decisión:** fuentes 512 en `assets/art/sprites/units/src/` con un archivo `.gdignore` que impide su importación; los originales 1024 del paquete no se versionan (quedan en el ZIP del usuario). Los proyectiles se guardan con el tamaño entregado en `assets/art/sprites/projectiles/` y se escalan en render; las hojas de contacto se copian a `docs/screenshots/` (AG-0).
**Consecuencia:** repo ligero y sin riesgos de importar duplicados; las fuentes quedan trazables para futuros reescalados.

## D-042 · Convención de orientación, ciclo de marcha y proyectiles (2026-11-22)
**Contexto:** el paquete de Kimi mira a E y el README indica espejar N/NW/O; el usuario pide base E + espejo al oeste y S/SE base.
**Decisión:** base para **E/SE/S**; espejo horizontal para **W/SW/NW/N** (convención GK2). Ciclo de marcha de 3 cuadros a **6 fps**, loop, cuadro 0 en reposo. Proyectiles en capa separada con trayectoria balística paramétrica: `virote→crossbowmen` (350 ms, arco 24 px), `flecha→longbowman` (500 ms, arco 40 px), `piedra→bombarda` (700 ms, arco 56 px); la animación no consume RNG de combate (determinismo intacto).
**Consecuencia:** criterio visual y comportamiento únicos para AG-2/AG-3/AG-4.

## D-043 · Pipeline para las 11 unidades restantes y cuadros de combate (2026-11-22)
**Contexto:** §10.3 contempla idle/ataque/impacto/muerte y las 11 unidades restantes; el equipo DSH no tiene generador de arte IA propio.
**Decisión:** se completa primero la integración de las 6 unidades núcleo; para el resto y para los cuadros de ataque se solicitará a Kimi la generación con el mismo pipeline (mediante el usuario/AG-0), registrando la petición en `docs/STATUS.md`/`docs/issues.md`. Mientras tanto, las unidades sin sprite mantienen el fallback heráldico.
**Consecuencia:** sin bloquear Fase 3 por capacidad de arte; la petición queda trazada y priorizada por escenario 1.

## D-044 · Paquete de sprites v2: las 17 unidades (2026-11-22)
**Contexto:** el usuario entregó un segundo `Sprites_Unidades_TSB.zip` (106 MB) que cubre las **17 unidades** de `units.json` × 3 cuadros de marcha (51 PNG) + 3 proyectiles + `_raw_1024/`, ampliando el paquete de 6 unidades integrado hasta ahora. El GDD v1.6 del repo todavía describía el bloque de 6; el usuario indica que el contrato completo de las 17 unidades es el vigente.
**Decisión:** el paquete v2 **sustituye** al de 6 unidades. Se actualiza el bloque §10.3 del GDD (repo y master del workspace) con el contrato de las 17 unidades, los 3 formatos (64×64/64×80/64×43) y el mapeo de proyectiles; se reabre la PRIORIDAD 1 para integrar las 17 y se mantienen los commits previos de 6 unidades como base. La verificación se hará contra GDD v1.6 tal y como queda actualizado.
**Consecuencia:** alcance de assets completo; los criterios §10.3 se evalúan sobre 17/17 unidades.

## D-045 · Normalización del id `bombard` ↔ `bombarda` (2026-11-22)
**Contexto:** `data/units.json` usa el id `bombarda` (referenciado en tests y datos del juego); el paquete de Kimi nombra los archivos `bombard_march_*.png`.
**Decisión:** se conserva el id del dataset (`bombarda`) y **AG-5 renombra los archivos** del paquete a `bombarda_march_{1,2,3}.png` en producción y en `src/`; no se renombran datos ni se tocan referencias del juego.
**Consecuencia:** `sprite_sheet` de `bombarda` apunta a archivos existentes; se evita romper `units.json`, escenarios o tests.

## D-046 · Fuentes `_raw_1024` en `src/` (actualiza D-041) (2026-11-22)
**Contexto:** el paquete v2 entrega los originales `_raw_1024/` (1024/1536 px, 51 archivos) y el usuario indica que se guarden en `assets/art/sprites/units/src/` como almacén sin importar. El paquete v1 usaba los 512 como fuente.
**Decisión:** `src/` pasa a contener los **51 originales `_raw_1024`** con `.gdignore` (sin importación); se retiran de `src/` los 18 PNG 512 del paquete anterior. Los 512 del paquete v2 no se versionan por separado (la producción 64 px se genera desde 1024 con LANCZOS). El peso se asume como almacén de fuentes.
**Consecuencia:** fuente de máxima calidad versionada para futuros reescalados; el proyecto sigue importando solo producción y proyectiles.

## D-047 · Formatos de producción: 64×64 / 64×80 / 64×43 (2026-11-22)
**Contexto:** el paquete v2 incluye artillería y vagón con lienzo panorámico 512×341; la reducción 8:1 da 64×42,6.
**Decisión:** producción a **64×64** (infantería), **64×80** (caballería) y **64×43** (bombarda y carro húsita), con LANCZOS y proporción mantenida (padding mínimo si el redondeo lo exige). El render ancla `bottom_center` y escala por radio de hex; los sprites panorámicos se centran en su celda.
**Consecuencia:** criterio de legibilidad uniforme; `units.json.size` refleja el tamaño real por tipo.

## D-048 · Mapeo de proyectiles ampliado (2026-11-22)
**Contexto:** el paquete v2 define proyectiles para más unidades de las inicialmente previstas.
**Decisión:** capa separada con trayectoria balística: **virote → `crossbowmen`; flecha → `longbowman`, `janissary` y `steppe_cavalry`; piedra → `bombarda`**. Duraciones/arcos: virote 350 ms/24 px, flecha 500 ms/40 px, piedra 700 ms/56 px (D-042 se mantiene para el resto).
**Consecuencia:** las unidades de arco compuesto disparan flecha; la bombarda dispara piedra; los tests cubren el mapeo.

## D-049 · Cuadros de combate idle/ataque/impacto/muerte (2026-11-22)
**Contexto:** §10.3 contempla hojas idle(2)/ataque(4-6)/impacto(2)/muerte(2); el paquete v2 entrega solo marcha (3 cuadros). El equipo DSH no tiene generador de arte IA.
**Decisión:** se completa la integración de marcha de las 17 unidades; para los cuadros de combate y cualquier ajuste de estilo se solicitará a Kimi la generación con este set como referencia de estilo (vía usuario/AG-0) y se registrará la petición en STATUS/issues. Mientras tanto se usan marcha 0 y los proyectiles.
**Consecuencia:** Fase 3 no se bloquea por animaciones adicionales; petición trazada.

## D-050 · Criterio de capturas de legibilidad (2026-11-22)
**Contexto:** el REA §6 exige que el arma se reconozca en silueta; el usuario pide mínimo milicia, ballesteros, arqueros, almogávar y jenízaro a 64 px reales.
**Decisión:** las capturas de aceptación serán a tamaño real 64 px (sin zoom) de `militia_spearman`, `crossbowmen`, `longbowman`, `almogavar` y `janissary`, además de una captura N2 y otra N3 con sprites/proyectiles; se guardan en `docs/screenshots/` y se revisan visualmente.
**Consecuencia:** criterio objetivo y mínimo para cerrar la integración de sprites.

## D-051 · Sincronización y normalización del GDD v1.7 (2026-11-22)
**Contexto:** el usuario indica que el GDD v1.7 ya está en main y añade §10.4 (tiles del campo de batalla N3); el fichero del workspace tenía el contenido v1.7 (incluido §10.4) pero el campo «Versión del documento» seguía marcando 1.5, y el repo estaba en v1.6.
**Decisión:** se copia el GDD al repo, se normaliza la versión a **1.7** (coherente con «Estado»), se sincroniza el master del workspace y se adopta §10.4 como vinculante; commit `[GDD]`.
**Consecuencia:** repo y master coinciden en v1.7; la verificación externa de Kimi se hará contra esta versión.

## D-052 · Reparto de la integración de tiles §10.4 (2026-11-22)
**Contexto:** el usuario asigna la extracción/render/generador de tiles a AG-3 y la tabla/reglas a AG-2; el scope habitual de assets es de AG-5, que acaba de cerrar los sprites.
**Decisión:** AG-3 extrae los 12 tiles (producción 512 y `src/` raw 1024), implementa el campo N3 y el generador; AG-2 crea `battle_tiles` (datos+schema+validación) y las reglas tácticas; AG-4 valida. AG-5 no toca la escena N3 durante este módulo (orden tiles→unidades ya satisfecho). Se sigue el reparto explícito del usuario sobre el scope genérico de AG-5.
**Consecuencia:** sin pisar archivos y con una sola fuente de verdad por capa.

## D-053 · `battle_tiles`: formato, validación y balance (2026-11-22)
**Contexto:** §10.4/README definen la tabla con `tile`, `move_cost`, `defense`, `passable` y flags `cavalry_penalty`/`move_bonus`; `validate_data.gd` debe validarla sin WARN.
**Decisión:** se crea `data/battle_tiles.json` (envelope D-009) + `data/schema/battle_tiles.schema.json`; AG-2 añade el reconocimiento del dataset en `tools/validator_core.gd` (dato de juego con reglas cruzadas: 12 claves, rutas `res://assets/art/battle/tiles/*.png` existentes, flags coherentes con passable). Valores de balance: pastizal/pradera 1/0, río y montaña impassable, puente 1/0, puente_villa 1/1, colina 2/1, bosque 2/1 + cavalry_penalty, villa 1/1, villa_calle 1/0 + move_bonus, camino 0,5/0 + move_bonus (GDD §6.4 + README v1.7).
**Consecuencia:** datos validados en CI y balance único; cualquier ajuste futuro se registra aquí.

## D-054 · Render de tiles: escala, rotación y fuentes (2026-11-22)
**Contexto:** los tiles llegan a 512×512 y el N3 se juega a sprites 64×64 ×2; río/puente/puente_villa/camino traen la banda horizontal.
**Decisión:** producción importada a **512** y dibujada a **128×128** en pantalla N3 (escalable ×2/×3); rotación **90° en motor** (sin assets duplicados) para el sentido vertical de río/puente/puente_villa/camino; `_raw_1024` en `src/` con `.gdignore`. La geometría del agua es idéntica en río/puente/puente_villa; las sustituciones de casillas son lógicas/render.
**Consecuencia:** un solo asset por tipo y continuidad visual del río.

## D-055 · Generador de campos N3 derivado de la región (2026-11-22)
**Contexto:** §10.4 exige que la distribución de terreno se derive de la región estratégica y que el río corte el campo con 1-2 puentes.
**Decisión:** AG-3 implementa un generador determinista (semilla de partida/región) que mapea `region.terrain` (plains/forest/mountain/coast/city) a proporciones de pastizal/pradera/bosque/colinas/montaña/río, traza un río continuo de orilla a orilla con 1-2 cruces (sustituyendo casillas por `puente`/`puente_villa`), coloca la villa en el asentamiento sitiado y caminos desde el despliegue a villa/puente. Expone la rejilla para el render N3; la lógica de movimiento/defensa la aporta AG-2.
**Consecuencia:** cada batalla tiene terreno coherente con el mapa estratégico y un obstáculo táctico realista.

## D-056 · Criterio de capturas de tiles (2026-11-22)
**Contexto:** §10.4 exige capturas de un campo con río+puente+villa y uno de llanura; sin ellas no se cierra.
**Decisión:** capturas 1920×1080 en `docs/screenshots/`: `tiles_n3_rio_puente_villa.png` y `tiles_n3_llanura.png`, más la hoja de contacto de tiles; revisión visual de continuidad del río y legibilidad a 128 px.
**Consecuencia:** criterio objetivo para el cierre del módulo de tiles.

## D-057 · Escenarios 1402/1453: modelo de datos (2026-11-22)
**Contexto:** el motor ya es genérico por escenario (`new_game(scenario_id)` + `initial_state`), pero solo existe `scenario_1337`; `map_borders.json` ya define owners 1402/1453 con 9 facciones sin entrada en `factions.json`.
**Decisión:** se añaden **9 facciones** (`brittany`, `burgundy`, `florence`, `genoa`, `milan`, `naples`, `ottoman`, `tamerlane`, `venice`; total 23) y `year_data` 1402/1453 en las 47 regiones, escenarios `scenario_1402`/`scenario_1453` (start 1402/1453; `playable_factions` = 8) y `events_1402/1453.json`. Las 8 facciones jugables del 1337 y sus datos no cambian. Contrato: `docs/architecture_contracts_fase3_scenarios.md`.
**Consecuencia:** los 3 escenarios comparten mapa y facciones base; el `playable` global de `factions.json` solo describe 1337 y cada escenario declara su propio set jugable.

## D-058 · Personajes vivos y gobernantes por año de escenario (2026-11-22)
**Contexto:** `GameState._build_characters` marca vivo = `died == null`, lo que rompe escenarios con personajes de muerte histórica futura; una facción tiene gobernantes distintos por año.
**Decisión:** `alive = (died == null or died >= start_year) and born <= start_year`; `age = start_year - born`. La selección de gobernante/heredero filtra por año y, si hay `reign_start`/`reign_end`, elige el reinado que cubre `start_year`; si hay varios, el más reciente. Los datos 1337 no cambian.
**Consecuencia:** 1402/1453 seleccionan a sus gobernantes históricos sin duplicar fichas ni romper partidas de 1337.

## D-059 · Evolución tecnológica por año (2026-11-22)
**Contexto:** §6.4 define eras I-III por unidad; Phase 3 exige evolución tecnológica por año.
**Decisión:** era **I** si year < 1350, **II** si 1350 ≤ year < 1400, **III** si year ≥ 1400; una unidad es reclutable/AI-usable si su `era` contiene la era actual. `TechSystem`/helper expone `era_for_year(year)` y `MilitarySystem.get_available_units(faction)`; UI muestra la era junto al año. Sin cambio de datos en units.
**Consecuencia:** 1337 solo permite unidades I; 1402 permite II-III; 1453 permite III; el balance de reclutamiento queda acotado históricamente.

## D-060 · Victoria/derrota §4.5 y años finales (2026-11-22)
**Contexto:** §4.5 exige coronas, prestigio, supervivencia y conquista; el motor solo implementa prestigio y derrota.
**Decisión:** victoria por **Prestigio Real** objetivo mantenido `years_held` (existente), **conquista ≥ control_pct (70%)** de regiones, o **supervivencia** al llegar a `end_year` (1402→1460, 1453→1480). Derrota por extinción/pérdida total (existente). Las coronas/claims se documentan como simplificación MVP (Fase 4) si el estado no las modela; no bloquean la aceptación de §4.5 en esta fase.
**Consecuencia:** los 3 escenarios tienen final automático claro y verificable.

## D-061 · Validación de los 3 escenarios (2026-11-22)
**Contexto:** el validador exige datos del 1337; hay que cubrir 1402/1453 sin regresiones.
**Decisión:** `tools/validator_core.gd` valida por escenario: facciones existentes, `playable_factions` exactamente 8 y ⊆ factions, `initial_state.regions` con `year_data` del año y owners válidos, `events_script` existente y eventos dentro de [start_year,end_year]; 1337 conserva 8 jugables. Schemas de scenario/characters/regions se amplían si hace falta (AG-1).
**Consecuencia:** `validate_data` 0 WARN/0 errores con 3 escenarios; cualquier inconsistencia de datos bloquea CI.

## D-062 · Assets externos: retratos de herederos/1402-1453 y animaciones de combate (2026-11-22)
**Contexto:** Phase 3 pide set completo de retratos y cuadros idle/ataque/impacto/muerte; el equipo DSH no tiene generador de arte IA.
**Decisión:** AG-5 prepara `docs/art/requests/kimi_phase3_assets.md` (lista exacta de character_id para 1402/1453 y herederos, hoja de estilo Kimi 256×256, y hojas de animación de las 17 unidades con referencia del set §10.3) para que el usuario la traslade a Kimi. Mientras no lleguen: fallback heráldico/silueta (nunca hueco). La aceptación de Fase 3 se documentará con esta dependencia externa; el resto de criterios (escenarios, tech, victoria, 10 años, QA) no se bloquea.
**Consecuencia:** Fase 3 puede cerrarse con observaciones de assets externos si Kimi aún no ha entregado; no se inventa arte.

## D-063 · UI de selección de escenario y era (2026-11-22)
**Contexto:** `scenario_select` muestra 1402/1453 como "PRÓXIMAMENTE" y el mapa arranca en 1337.
**Decisión:** las 3 tarjetas son jugables; al elegir escenario se listan sus 8 `playable_factions`; `new_game` usa el id del escenario; el mapa arranca en la vista del año del escenario y el HUD muestra la era I/II/III; pantalla de fin con motivo (prestigio/conquista/supervivencia/extinción).
**Consecuencia:** los 3 escenarios son accesibles desde la UI y la tecnología es visible para el jugador.

## D-064 · Integración de la animación de combate (GDD v1.8 §10.3, D-049) (2026-11-22)
**Contexto:** Kimi entregó `Anim_Combate_TSB.zip` (345,6 MB): 170 PNG = 17 unidades × 10 cuadros (idle 2, ataque 4, impacto 2, muerte 2) + 170 originales `_raw` + hoja de contacto/README. El GDD v1.8 §10.3 fija el contrato: los 10 cuadros se añaden a `frames` tras los 3 de marcha (índices 3-12) y `anim` se amplía con `idle/attack/hit/death/fps_attack/fps_hit/fps_death/death_hold`. La instrucción del usuario pedía registrar la decisión como D-057, pero D-057…D-063 ya están usadas (escenarios/tech/victoria/tiles); se registra como **D-064** para no reutilizar ids y se deja constancia de la desviación.
**Decisión:** el módulo de animación se integra sobre Fase 3 ya cerrada (tag `fase-3`). Producción: 170 PNG a `assets/art/sprites/units/` reescalados LANCZOS 64×64/64×80/64×43; 170 originales a `assets/art/sprites/units/src/` (`.gdignore`); `units.json` con 13 frames (march 0-2 + idle 3-4 + attack 5-8 + hit 9-10 + death 11-12) y `anim` extendido; schema actualizado. Motor N3: idle en guardia (bucle lento), ataque una vez con impacto en `attack_2` sincronizado con la resolución de daño D-048 y el proyectil de la capa separada, `hit` al recibir daño, `death` una vez con `death_hold` (cadáver persistente); espejo horizontal igual que marcha. QA: 17×13 cuadros cargan headless, secuencia visible en N3, capturas en `docs/screenshots/`, informe `docs/qa/fase3_anim_report.md`; sin regresión.
**Consecuencia:** se completa el alcance §10.3 de animación de combate; el arte de retratos (69 PNG) sigue pendiente de Kimi (D-062). El cierre de este módulo se registrará como `fase-3.1` si el QA es aprobado.

## D-065 · Delta de animación a distancia/artillería y contrato 13/15 frames (GDD v1.8.1) (2026-11-23)
**Contexto:** Kimi entregó `Anim_Combate_Rango_Artilleria_TSB.zip` (98 MB): 42 `attack_1..6` para las 7 unidades a distancia/artillería (`janissary`, `arquebusier`, `crossbowmen`, `longbowman`, `steppe_cavalry`, `bombarda`, `hussite_war_wagon`) + 34 `impact_1/2` para las 17 unidades (mismos píxeles que los `hit_*` renombrados) + 42 raws + hoja. El GDD v1.8.1 fija el contrato por tipo: 10 unidades de choque con 13 frames (`attack [5..8]`, `impact [9,10]`, `death [11,12]`) y 7 a distancia/artillería con 15 frames (`attack [5..10]`, `impact [11,12]`, `death [13,14]`); `attack_4` = cuadro de disparo/golpe pleno. La instrucción pedía registrar D-064, pero D-064 ya se usó para el set base v1; se registra **D-065** para no duplicar id (desviación documentada).
**Decisión:** integración sobre `fase-3.1` ya cerrada. Producción: sustituir `attack_1..4` de las 7 unidades por los `attack_1..6` del delta, añadir `impact_1/2` para las 17 (renombrando los `hit_*` de producción y de `src/` a `impact_*` para conservar los raws; sin `hit_*` huérfanos), LANCZOS 64×64/64×80/64×43; raws de los 42 ataques a `src/`. `units.json`: esquema plano `frames`+`anim` (NO el objeto `animations` de §3.6), 13 frames melee / 15 ranged, `anim {"march":[0,1,2],"idle":[3,4],"attack":[...],"impact":[...],"death":[...],"fps":6,"loop":true,"fps_attack":9,"fps_impact":8,"fps_death":6,"death_hold":true}`; schema con variantes 13/15. Motor: ataque una vez, impacto en `attack_4` (índice absoluto 8; t≈333,3 ms a 9 fps), proyectil lanzado en `attack_4`, reacción `impact` del defensor tras la ventana de `attack_4` (t≈444,4 ms), ataque a distancia completa sus 6 cuadros (recoil/recarga) y vuelve a idle, muerte con `death_hold`; espejo oeste. Se conservan las 51 marchas.
**Consecuencia:** animación de combate completa (184 PNG de combate + 51 de marcha = 235 frames finales; 235 producción + 235 raws), alineada con el Paquete B de la petición de AG-5; retratos (Paquete A) siguen pendientes de Kimi.

## D-066 · Suspensión de escenarios 1402/1453 y foco en MVP-1337 (2026-11-23)
**Contexto:** decisión directa del usuario (2026-11-23, verificada por Kimi): «Vamos a suspender actividades de los dos escenarios adicionales de la fase 3. Quiero que nos enfoquemos en que el MVP con 1 escenario esté completo y funcionando correctamente». El repo está en `be28088` / tag `fase-3.2`, con GDD v1.8.1, animación QA 6/6 y los escenarios 1402/1453 ya integrados (D-057…D-063).
**Decisión:** (1) **congelar** 1402/1453: sus datos (`data/factions.json`, `characters.json`, `regions.json`, `scenarios/scenario_1402/1453.json`, `events_1402/1453.json`), código y QA específicos **no se tocan ni se eliminan** de main; queda prohibido trabajar en su contenido, balance, eventos o QA. (2) En `scenario_select` solo el **Escenario 1 (1337 «Dos Coronas»)** es jugable; las tarjetas 1402/1453 se muestran **deshabilitadas** con la etiqueta **«EN PAUSA — disponible en versión completa»**, mediante un **flag reversible** en UI (no borrar datos ni tarjetas). (3) **arte externo suspendido**: no se solicitan ni generan retratos (Paquete A, 69 PNG) ni otro arte a Kimi; se mantienen y pulen los fallbacks heráldicos/silueta (D-062). (4) Se abre el tramo **fase-3.3 (MVP-1337)** de endurecimiento: loop completo, victoria/derrota §4.5, N1/N2/N3, save/load, eventos 1337, estabilidad, rendimiento, UX/audio mínimo y balance, sin nueva mecánica fuera del GDD.
**Consecuencias:** baseline de animación (QA 6/6) y del resto no se toca salvo bug demostrado; cualquier ambigüedad se resuelve con la decisión mínima registrada (D-067+). El tramo cierra con `docs/qa/fase3_mvp_report.md`, tag **`fase-3.3`**, push y verificación de Kimi contra GDD v1.8.1 + esta directiva. La reanudación de 1402/1453 y del Paquete A queda para una decisión posterior del usuario.

## D-067 · Banda sonora del MVP: set reducido de época, PD/libre (2026-11-23)
**Contexto:** el usuario amplía la directiva MVP-1337 (prompt v2): «Quiero agregar en el MVP música de fondo, tanto en la parte de estrategia como en las batallas. Un número reducido de melodías alusivas a la época»; además el MVP incluye los tres niveles de batalla. La directiva fija 5-6 pistas máximo, fuentes de dominio público (s. XIII-XV) o síntesis propia, buses Master/Music/SFX, `data/audio_tracks.json`, crossfade 1,5-2 s, loop limpio OGG, opciones persistentes y `docs/audio_licenses.md`.
**Decisión:** se integran **6 pistas OGG Vorbis** en `assets/audio/music/` — menú, mapa estratégico, batalla N2, batalla N3, fin de año y cierre (victoria/derrota) —, **sintetizadas por el propio equipo** a partir de melodías de **dominio público** (Cantigas de Santa María de Alfonso X, estampies del Chansonnier du Roy y danzas medievales) mediante un generador Python + ffmpeg versionado en `tools/`; no se descarga ni usa material con copyright y no se solicita nada a Kimi. `audio_manager.gd` (D-015) gestiona buses **Master/Music/SFX**, carga las pistas desde `data/audio_tracks.json` (contexto → ruta res://, loop, volume_db), loop continuo y **crossfade 1,5-2 s** al cambiar contexto, sin cortar música en guardar/cargar; opciones Music/SFX persistentes en `user://`. SFX mínimos generados (click, campana de fin de año, espada N3). Licencias y atribución en `docs/audio_licenses.md` (AG-1 redacta, AG-4 verifica). La numeración D-067 se reserva a esta banda sonora conforme a la directiva v2; los ajustes de balance derivados de la auditoría AG-1 se registran como D-068.
**Consecuencia:** MVP con música de estrategia y batalla, sin dependencia externa ni riesgo de licencia; QA C11 verifica carga headless, cambio de contexto/crossfade, persistencia y licencias. El set no se amplía en este tramo (máximo 6 pistas).

## D-068 · Ajustes de estabilidad/balance MVP-1337 (auditoría AG-1) (2026-11-23)
**Contexto:** la auditoría de AG-1 (task-54) detectó inflación económica, espiral de apoyo en montaña, Peste Negra sin efecto dinástico, guerra anglo-francesa no declarada y heredero inválido en Polonia. AG-2 los corrigió con código/constantes (su informe los etiqueta «D-067a-f»); como D-067 se reserva a la banda sonora (D-067), se consolidan aquí como **D-068**.
**Decisión:** (a) **economía**: `ARMY_UPKEEP_PER_200_MEN` 2→20 y gasto de corte progresivo (`TREASURY_SOFT_CAP=8000`, `TREASURY_OVERHEAD_RATE=0.35`/trimestre sobre el exceso); tesoros a 10 años pasan de ×5-×14 a ×1,10-×1,95 con 8/8 facciones vivas; (b) **montaña**: `TERRAIN_FOOD.mountain` 0,6→0,7 + `SUPPORT_MOUNTAIN_BONUS=3` (Austria/Transilvania/Croacia sin espiral a 0); (c) **Peste Negra**: hook `DynastySystem.apply_plague_mortality` (20 %, máximo 1 pariente/facción, nunca gobernante/heredero/cónyuge) invocado desde `EventResolver`; (d) **guerra anglo-francesa**: `at_war` inicial England↔France en 1337 para que Sluys/Crécy/Calais/Poitiers/Brétigny/Nájera disparen en partida pasiva; (e) **IA**: no invade facciones sin guerra declarada; (f) **herencia**: `_find_heir` excluye `spouse` del fallback (Polonia deja de nombrar a Aldona). Sin tocar datos de 1402/1453 ni los datasets históricos de 1337.
**Consecuencia:** loop y balance estables para el QA MVP (C2/C5); las métricas antes/después quedan en el informe de AG-2 y en `docs/qa/fase3_mvp_report.md`.

## D-069 · Mercancías y comercio con comerciantes (Fase 4) (2026-11-23)
**Contexto:** tras probar el MVP, el usuario pide «profundidad de GK2»: inventario de mercancías por reino (especias, pieles, armas…), comercio que exija comerciantes asignados y riqueza adicional para formar/entrenar ejércitos.
**Decisión:** se añaden **10 mercancías** (`data/trade_goods.json`: especias, pieles, lana, vino, sal, grano, armas, caballos, hierro, madera) con `base_price`, `produced_by` (terreno/edificios) y `used_by` (reclutamiento/consumo); inventario de facción agregado de sus regiones y serializable; producción trimestral según terreno/edificios; **sin Comerciantes asignados no se puede comprar/vender** y el volumen depende de ellos; mercado con precio `base × factor oferta/demanda` determinista; comercio exterior con pactos o **expedición de mercaderes (2 PG, retorno a los 2 trimestres)**; grano/sal sostienen apoyo y armas/caballos se consumen al reclutar; el comercio aporta ≤~20-25 % de la economía base y se valida con simulación 10 años ×8 sin inflación (D-068). Los bienes se definen por terreno/edificios, sin tocar `year_data` 1402/1453.
**Consecuencia:** pantalla Mercado y sistema `TradeSystem`/extensión de Economía; C2/C3 del QA de Fase 4; D-070 conecta el comercio con el reclutamiento.

## D-070 · Pantalla de ejércitos y reclutamiento/entrenamiento con mercancías (2026-11-23)
**Contexto:** el usuario pide una pantalla de ejércitos con imágenes del número de unidades de cada tipo y administración desde ahí.
**Decisión:** panel Militar global por facción con sprite `march_1` existente por tipo, conteo, fuerza y moral/experiencia medias; acciones **Reclutar** (oro + pool regional + mercancías: caballería→caballos, infantería pesada/hombres de armas→armas, definidas en `units.json.recruit_goods`), **Entrenar** (sube experiencia; oro + 1 PG) y **Disolver** (libera pool y devuelve 50 % del oro). La IA usa las mismas reglas sin trampas. Captura `army_management.png`.
**Consecuencia:** C4/C5 del QA; el reclutamiento por región se mantiene y la pantalla añade gestión global por tipo.

## D-071 · Acción «Pasar tiempo con la consorte» (2026-11-23)
**Contexto:** el usuario pide la acción familiar de pasar tiempo con la esposa para tener más hijos; la educación del hijo ya existe.
**Decisión:** acción en el árbol familiar, **una vez por trimestre**, coste 2-3 PG, requiere consorte válida (viva, no enferma, edad fértil); otorga **bonus de fertilidad durante los siguientes 2-4 trimestres** + pequeño prestigio/relación; sin consorte válida se rechaza con motivo claro sin estados rotos. La educación automática (D-020) se mantiene y se muestra en la ficha del hijo.
**Consecuencia:** C6 del QA; estado de cooldown/fertilidad serializable.

## D-072 · Manual del Jugador (2026-11-23)
**Contexto:** el usuario pide un manual detallado de cómo funciona el juego y qué hacer para ganar.
**Decisión:** `docs/MANUAL_DEL_JUGADOR.md` en español con 10 secciones (introducción/fantasía; cómo se gana y pierde §4.5 con ejemplos; turno/PG/fases; economía + mercancías/comercio; familia + consorte + Peste Negra; diplomacia/espionaje; militar + 3 niveles de batalla; IA/dificultades/eventos; consejos por las 8 facciones; glosario). Acceso desde el juego: botón «Manual» en menú principal (abre el MD vía `OS.shell_open`) y «Ayuda» en el menú de consejo con resumen.
**Consecuencia:** C7 del QA; AG-1 redacta con detalles de AG-2/AG-3.

## D-073 · Dificultad y tutorial con Consejero (2026-11-23)
**Contexto:** el usuario pide un tutorial en el juego con un Consejero que guíe paso a paso, activable en nivel principiante o antes de iniciar partida.
**Decisión:** selección **Principiante / Normal** al iniciar (en `scenario_select` o pantalla previa): Principiante = Consejero activo + IA con multiplicador de agresividad reducido (constante tunable); Normal = sin Consejero y agresividad 1.0. Consejero = panel lateral con avatar heráldico generado por código, nombre «El Consejero» y guion del primer año en **`data/tutorial_script.json`** (pasos con texto breve, objetivo, `highlight` de UI y condición verificable); resaltado del elemento, avance por condición y opción **Saltar** en cualquier momento. Estado del tutorial (`active`, `step_index`, `completed`, `skipped`) serializable en save/load y compatible con partidas antiguas (migración/defaults). Capturas `tutorial_consejero.png`, `tutorial_highlight.png`.
**Consecuencia:** C8/C9 del QA; sin arte nuevo (avatar por código).

## D-074 · Límite de acciones por turno (2026-11-23)
**Contexto:** al probar el juego, el usuario detectó que se puede pulsar varias veces la misma acción en un mismo turno (p. ej. proponer dos veces un pacto comercial). Las únicas acciones que deben poder repetirse en un turno son las militares (reclutar/entrenar/disolver), la asignación de trabajadores entre sectores y la compra/venta de mercancías en el mercado.
**Decisión:** el estado guarda `actions_used` por facción y turno (`GameState.spend_action/mark_action_used/is_action_used/reset_turn_actions`), reseteado al empezar turno/trimestre. Se gatean una vez por turno: todas las **acciones diplomáticas** (por acción y objetivo), **matrimonios/acciones familiares** (consorte ya era 1/trimestre), **construcciones** y **expedición de mercaderes**; espionaje por objetivo. Quedan **exentas** (múltiples): reclutar, entrenar, disolver, asignar trabajadores, comprar/vender mercancías. La UI deshabilita el botón tras usarlo con tooltip «Usado este turno» y feedback; el motor rechaza el duplicado con motivo (`action_used`) aunque la UI falle. Sin afectar a la IA (sus decisiones se limitan por su propia política) ni al determinismo.
**Consecuencia:** C13 del QA; el flujo de turno se siente como GK2 (cada orden de corte una vez, logística repetible).

## D-075 · Costes de reclutamiento diferenciados y visibles (2026-11-23)
**Contexto:** el usuario percibe que todas las unidades cuestan lo mismo. En datos ya hay `cost.gold` distinto (milicia 20 … caballeros 130, bombarda 200), pero la pantalla de ejércitos no muestra el coste y algunas unidades de caballería ligera (40-55) eran más baratas que un arquero largo (60), lo que contradice la lógica histórica y de diseño.
**Decisión:** se ajustan `cost.gold` en `units.json` para que **toda la caballería cueste más que arqueros/infantería ligera** (p. ej. caballería ligera 65-70, sargentos 85, hombres de armas 140, mamelucos 150, teutónicos 160; arqueros 45-60, infantería 20-95; artillería 200) y se mantiene `cost.recruits` por bloque. La pantalla de ejércitos muestra por tarjeta el coste en oro + hombres + mercancías y calcula el total para la cantidad; `MilitarySystem.recruit` ya usa `cost.gold` y `recruit_goods` (se verifica que deduzca el importe correcto por tipo). Fuentes/valores documentados en `sources.md` §13 y pruebas de coste distinto por unidad.
**Consecuencia:** C14 del QA; el jugador ve y paga costes distintos por tipo, con la caballería como inversión mayor.

## D-076 · Investigación adicional de menús/acciones de GK2 (2026-11-23)
**Contexto:** el usuario pide investigar más a fondo cómo funcionan los menús similares en GK2 y usarlo como base para el gating y los costes.
**Decisión:** AG-REA amplía `docs/rea/gk2_economy_military_family.md`/`notes_economy.md` con un addendum: estructuras/búsquedas de límites de acciones por turno, costes de reclutamiento por tipo y secuencias de menú Economía/Militar/Familia; sin `.EXE`, sin texto literal, sin copiar assets; si los menús no son observables (DOSBox ausente, D-038) se declara y se aportan las lecciones estructurales/UX verificables. El addendum se audita en C1 y sirve de base documental para D-074/D-075.
**Consecuencia:** la investigación queda registrada aunque la observación directa no sea posible; el diseño se documenta como extensión propia, no port 1:1.

## D-077 · Autorización temporal de ingeniería inversa completa de GK2 (2026-11-23)
**Contexto:** el director del proyecto autoriza explícitamente, para esta sesión y con fines de estudio/referencia de diseño, levantar las restricciones de alcance limitado del GDD §3 y `agents/AG-REA.md` **solo para AG-REA**. Se permite inspeccionar todos los archivos de `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` en **solo lectura** (incluidos `MAIN.EXE`, `OPEN.EXE`, `END.EXE`, overlays y todos los `.DAT`/`.GK2`), usar REA-MCP/Ghidra (`C:\tools\ghidra`), desensamblado/descompilación e inspección hexadecimal, y documentar arquitectura, fórmulas, tablas de constantes y flujos de lógica. El entregable es `docs/rea/REA_GK2_report.md` (y copia en la raíz del repo `REA_GK2_report.md`), sin límite de páginas, escrito incrementalmente por módulos.
**Decisión:** se concede la autorización temporal **exclusivamente a AG-REA**; AG-1/AG-2/AG-3/AG-4/AG-5 siguen sin acceso a la carpeta GK2 y solo consumirán lo que AG-0 apruebe integrar en fases futuras. La autorización cubre análisis técnico y extracción de mecánicas/fórmulas, pero **no** copiar assets, texto u otro contenido protegido a TSB; no se modifica código de producción ni datasets de TSB en este tramo. El informe debe incluir evidencia verificable (archivo+offset o dirección/función Ghidra), pseudocódigo/ecuaciones y un diagrama Mermaid del ciclo de partida; se documentarán limitaciones si una herramienta no está disponible. AG-0 registra D-077, versiona los informes en git y mantiene la regla de aislamiento.
**Consecuencia:** AG-REA se reactiva con autorización plena para esta investigación; el resto del equipo no cambia su alcance. El informe servirá de base documental para una eventual Fase 5, sin integración automática de mecánicas ni contenido.

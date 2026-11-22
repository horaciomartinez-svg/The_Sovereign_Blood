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

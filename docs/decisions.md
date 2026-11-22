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

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

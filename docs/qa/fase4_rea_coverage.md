# Cobertura del informe REA completo de GK2 para Fase 4 (D-077/D-078)

| Campo | Valor |
|---|---|
| **Autor** | AG-4 (QA independiente) |
| **Fecha** | 2026-11-23 |
| **Veredicto** | **Cobertura REA Fase 4: SUFICIENTE** — con vacíos documentados (M2/M4/M5/M7) que no bloquean Fase 4 |
| **Informe local auditado** | `C:\Proyectos\TSB\docs\rea\REA_GK2_report.md` — **29.577 B**, SHA-256 `32FDD2DF…FA15A87A`; **fuera del repo**, solo local |
| **Preliminar de Fase 4** | `docs/rea/gk2_economy_military_family.md` — 10.168 B, SHA-256 `CE2CDAA8…C90C4E70`; queda **cubierto** por el informe completo según D-078 |
| **HEAD** | `03a5438b` |
| **Scope** | Solo lectura del informe local y `docs/qa/**`; sin producción ni git |

> **Límite del documento:** este informe de cobertura **no reproduce** offsets, tablas, descompilación, pseudocódigo ni texto del binario. Solo resume a nivel de módulo, cita estados de cobertura y evidencia de no publicación/hashes.

---

## 1. Veredicto

> **Cobertura REA Fase 4: SUFICIENTE**

El informe completo cubre el entregable preliminar de Fase 4 (`gk2_economy_military_family.md`) y los criterios **C1, C3, C4, C5 y C14** del QA de Fase 4 con evidencia estructural y de comportamiento suficiente para la decisión de diseño de TSB. **C6 (consorte)** queda cubierto de forma **parcial** por M4 (se acredita la existencia de los sistemas de corte/familia, pero no se recuperaron fórmulas de fertilidad/sucesión); el diseño de C6 se apoya en D-071, no en una fórmula de GK2. Los vacíos M2/M4/M5/M7 están declarados sin inventar datos, por lo que no comprometen C1 (legalidad/consumibilidad) ni el resto del QA.

---

## 2. Cobertura de los módulos 3-6 frente al preliminar

| Preliminar Fase 4 | Informe completo | Cobertura | Observación |
|---|---|---|---|
| Mercancías e inventario; producción por terreno/edificios; precios | **M3 Economía/población/clima/comercio** | **Alta** | 12 mercancías y su relación con cultura/clima, requisito de comerciantes, mercado y precios; también costes de unidades. C3 y buena parte de C1 respaldados |
| Menús Economía/Militar/Familia y lecciones UX | **M3/M4/M6** (parcial) | **Media-alta** | M3 describe el flujo de mercado y M6 el panel de unidades; M4 acredita los menús de corte/familia, pero no detalla su UX/interacción completa |
| Familia: matrimonio, fertilidad, educación, sucesión, consorte | **M4 Dinastía/corte** | **Parcial** | Sistemas/campos identificados, pero fórmulas de matrimonio/fertilidad/educación/sucesión quedan como Unknowns. C6 es **parcial** desde REA; el comportamiento de juego se especifica en D-071 |
| Diplomacia: alianzas, tributo, vasallaje, soborno, espionaje | **M5 Diplomacia/espionaje** | **Parcial** | Alianzas/tributo/vasallaje/soborno identificados; espionaje no localizado y probabilidades no recuperadas. C13 se apoya en M2/D-074, no en M5 |
| Militar: unidades, conteos, costes, reclutamiento, N1/N2/N3 | **M6 Militar/batallas** | **Alta** | Tipos de unidad, factores/relación de coste, paneles y mecánicas N1/N2/N3 identificadas; fórmulas finas de choque pendientes. C4/C5/C14 respaldados |
| Límite de acciones por turno | **M2 Turnos/gobernadores** | **Parcial** | Evidencia de gating/órdenes por turno; Body no es un pool de acciones. C13 se cierra con D-074 y tests de TSB |
| IA | **M7 IA** | **Unknown** | No atribuida; no es criterio de Fase 4 |
| Save/comparación GK2↔TSB | **M8** | **Alta** | Tabla comparativa y estado persistente; respalda la decisión de `save_version`/snapshot de TSB |

### Criterios QA Fase 4 afectados
- **C1:** cobertura suficiente: el informe completo es el documento de referencia de diseño y sustituye al preliminar; legalidad revisada y sin publicación (D-078).
- **C3:** cobertura alta (M3): bienes, precios, comerciantes y mercado permiten justificar el modelo TSB; QA C3 14/14 PASS.
- **C4/C5/C14:** cobertura alta (M6): tipos, costes y paneles respaldan ejércitos/reclutamiento/costes; QA PASS.
- **C6:** cobertura parcial (M4): los sistemas familiares existen, pero las fórmulas no son concluyentes; C6 PASS se basa en D-071 y tests, no en la fórmula REA.
- **C13:** no depende de M5; M2 da contexto de órdenes/turno y D-074 cierra el diseño.

---

## 3. No publicación — evidencia

| Comprobación | Resultado |
|---|---|
| `Test-Path <repo>/docs/rea/REA_GK2_report.md` | **False** |
| `Test-Path <repo>/REA_GK2_report.md` | **False** |
| `git ls-files '*REA_GK2_report*'` | **vacío** |
| `git log --all -- '*REA_GK2_report*'` | **vacío** |
| `git status --short` | **limpio** (sin informe rastreado/untracked; solo este documento de QA tras crearlo) |
| `git check-ignore -v docs/rea/REA_GK2_report.md` | `.gitignore:44` (ruta ignorada) |
| `git check-ignore -v REA_GK2_report.md` | `.gitignore:43` (ruta raíz ignorada) |
| Informe local | `C:\Proyectos\TSB\docs\rea\REA_GK2_report.md` (fuera de `sovereigns-blood`) |
| Copia en el repo | **ninguna** |

`.gitignore` incluye el bloque «REA completa de GK2: material interno de estudio, NO publicar ni versionar (D-078)», con ambas rutas. El informe local no se copia al repo ni se publica; este documento de cobertura no reproduce su contenido.

---

## 4. D-077 / D-078 y no modificación

- **D-077** (autorización temporal de REA completa de GK2, solo lectura, herramientas REA/Ghidra, sin copiar assets/texto, sin modificar producción/datasets TSB) — **presente** en `docs/decisions.md`.
- **D-078** (informe completo solo local, fuera de git; rutas ignoradas; preliminar de Fase 4 cubierto por módulos 3-6; C1 satisfecho; nunca commitear/pushear) — **presente**.
- **Producción TSB:** `git diff` de producción (excluyendo docs/tests) **vacío**; `git status` sin cambios de producción; AG-REA trabajó solo en `docs/rea/**`.
- **GK2 sin modificar:** hashes de la sesión del informe coinciden con los actuales:
  - `MAIN.EXE` `172492947E240471`
  - `OPEN.EXE` `0963899C7F1412C4`
  - `END.EXE` `CD565539D05EF6FB`
  - `SCENARIO.GK2` `0C5E26E2E67DA828`
  - `SAVEDATA.GK2` `774377D0D41E9383`
  - Directorio GK2: fecha de modificación anterior a la sesión, análisis de solo lectura.
- **Sin contenido literal en producción:** el informe local no se ha copiado a código/datos/arte/texto de TSB; no hay assets ni strings de GK2 en el repo (el único entregable REA en repo es el preliminar de Fase 4, ya existente y en español propio).

---

## 5. Vacíos declarados (no bloqueantes)

| Módulo | Estado | Vacío | Impacto Fase 4 |
|---|---|---|---|
| M2 Turnos/gobernadores/Body | **Parcial** | Gating por estado/turno verificado; no hay pool numérico de acciones/Body | C13 se apoya en D-074/tests; no bloquea |
| M4 Dinastía/corte | **Parcial** | Matrimonio/fertilidad/educación/sucesión: fórmulas pendientes | C6 parcial desde REA; D-071 y tests cierran QA |
| M5 Diplomacia/espionaje | **Parcial** | Espionaje no localizado; probabilidades/umbrales pendientes | C13 no depende de M5; sin bloqueo |
| M7 IA | **Unknown** | Árboles/pesos no atribuidos | No es criterio de Fase 4 |
| M3/M6 fórmulas finas | Parcial-alto | Cosecha/clima y resolución táctica fina pendientes | Suficiente para diseño y QA actuales |

Los vacíos están explícitamente marcados como no concluyentes en el informe; no se inventaron coeficientes. Una segunda pasada (opcional) podría cerrarlos, pero **no es requisito de C1 ni de Fase 4**.

---

## 6. Observaciones

1. **C1 legal:** el informe local contiene material técnico sensible y **no se publica**; el repo mantiene solo el preliminar legible/legal y este resumen. La cobertura se acredita por auditoría de AG-4 + D-078, no por publicar el informe.
2. **C6:** conviene no presentar M4 como cobertura completa de consorte; es cobertura **parcial** y el criterio de juego se apoya en D-071.
3. **C13:** M2 da contexto de límite de órdenes, pero la implementación de TSB se especifica en D-074 y se verifica con tests; no se importó una fórmula de GK2.
4. **No hay bloqueo** para el cierre de Fase 4: C1 SUFICIENTE, C3/C4/C5/C14 respaldados, C6/C13 cubiertos por decisiones y tests propios, M2/M4/M5/M7 documentados como vacíos.

---

## 7. Evidencia de artefactos

| Artefacto | Ruta | Estado |
|---|---|---|
| Informe local (NO publicar) | `C:\Proyectos\TSB\docs\rea\REA_GK2_report.md` | 29.577 B; SHA-256 `32FDD2DF…FA15A87A`; fuera del repo |
| Preliminar Fase 4 | `docs/rea/gk2_economy_military_family.md` | 10.168 B; cubierto por D-078 |
| Este documento | `docs/qa/fase4_rea_coverage.md` | resumen sin offsets/tablas sensibles |
| Decisiones | `docs/decisions.md` D-077/D-078 | registradas |
| `.gitignore` | `.gitignore` líneas 42-44 | ignora ambas rutas |

*Fin del informe de cobertura REA Fase 4 — AG-4. Veredicto: **SUFICIENTE**. Sin producción ni git.*

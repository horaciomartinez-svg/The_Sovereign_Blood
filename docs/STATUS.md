# Estado del proyecto — The Sovereign's Blood

| Campo | Valor |
|---|---|
| **Fase actual** | **Fase 3 — Contenido y remaster (EN CURSO)**; PRIORIDAD 1: integración de sprites de Kimi (§10.3) |
| **Fase anterior** | **Fase 2 — CERRADA** (`fase-2`); QA APROBADO 6/6 (2026-11-22) |
| **Siguiente fase** | Fase 4 — no definida (tras tag `fase-3`) |
| **GDD** | **v1.6** — `GDD_The_Sovereign's_Blood.md` (§10.3 contrato de sprites de Kimi; hereda v1.5) |
| **Contrato Fase 3** | `docs/architecture_contracts_fase3.md` (sprites: assets, `sprite_sheet`, lógica N2/N3, render, QA) |
| **Contrato Fase 2** | `docs/architecture_contracts_fase2.md` (map_borders, batallas N2/N3, retratos, espionaje, extinción) |
| **Coordinador** | AG-0 |
| **Repo** | https://github.com/horaciomartinez-svg/The_Sovereign_Blood (rama `main`, sin force-push) |
| **Fecha de cierre Fase 2** | 2026-11-22 |
| **QA Fase 0** | **APROBADO** — 0 bloqueantes, 0 mayores, 5 observaciones menores (ver `docs/issues.md`) |
| **QA Fase 1** | **APROBADO** — 6/6 criterios §12, 0 bloqueantes, 3 menores (ver `docs/qa/fase1_report.md`) |
| **QA Fase 2** | **APROBADO (v1.5)** — 6/6 criterios §12/§10.1/§10.2 + REA §3.2 verificado; 0 bloqueantes (ver `docs/qa/fase2_report.md`) |
| **Contrato Fase 1** | `docs/architecture_contracts_fase1.md` (estado canónico + API congelada AG-2/AG-3) |

---

## 1. Resumen ejecutivo

Fase 0 completada en una sesión. Entregados: el informe REA de alcance limitado, los datasets
completos del Escenario 1 (1337) con schemas y fuentes, el scaffold Godot 4.7.2 con 10 autoloads y
CI headless, y la validación independiente de QA. Los tres comandos obligatorios terminan con
**exit code 0** y **0 errores**: `validate_data.gd` (5.239 comprobaciones), suite headless
(**231 tests pasados**) e importación del proyecto. El informe REA tiene **1.721 palabras (~2 páginas)**.

No hay bloqueos ni deuda técnica conocida para iniciar Fase 1.

**Verificación Kimi de Fase 0:** APROBADO CON OBSERVACIONES (1 menor, OBS-K1: registrar
`audio_manager.gd` como autoload al activar AG-5 en Fase 3 → decisión **D-015**). Luz verde dada para
Fase 1 el 2026-11-21.

**Fase 1 (MVP jugable) completada:** sistemas núcleo reales (10 autoloads), UI §9 completa (16 escenas),
integrada end-to-end y verificada por QA independiente. **QA Fase 1: APROBADO** — 6/6 criterios de §12
(Inglaterra 1337 jugable, IA de 13 rivales en **17 ms**, save/load exacto con hash, batalla delegada con
captura, Peste Negra 1348, UI headless) con 0 bloqueantes y 3 observaciones menores resueltas/documentadas.
Suite headless: **548 tests**; `validate_data.gd`: 0 errores. Tag anotado `fase-1`.

**Fase 2 (Profundidad militar + Mapa + Retratos) completada (GDD v1.5):** QA independiente **APROBADO (v1.5)** —
6/6 criterios, 0 bloqueantes:
- **Militar N2/N3:** `TacticalBattle` (hexes, objetivos, IA, determinismo), `CloseCombat` (5 cartas, +1 orden por
  Mando), espionaje (6 PG, intel persistente), extinción dinástica (derrota inmediata, reloj congelado) y N3
  aplicado a campaña (D-033). Crécy resuelto en los 3 niveles; N2 coherente (1200/509 tras B-F2-01).
- **Mapa §10.1:** 4 capas (terreno 4096×3072 determinista, fronteras 1337/1402/1453 — 47/47, 132.962 B, hit-test
  141/141, entidades con elisión por zoom, cámara), `map_layout.json` eliminado (D-024); benchmark CPU 0,178 ms
  de media (<8 ms).
- **Retratos §10.2 (v1.5):** los 14 retratos finales de Kimi integrados (`assets/art/portraits/<id>.png`,
  `portrait` res:// en los 14 gobernantes) y renderizados en los 5 slots; sucesión textura→heredero verificada;
  fallback heráldico intacto para el resto; hoja de contacto final.
- **REA ampliado §3.2 (v1.5):** `docs/rea/gk2_battle_mechanics.md` (1.998 palabras) + `notes_battle.md`;
  estructura `SUNIT`/`KPAT`/`GRPDATA` y lecciones §10.3; mecánicas N2/N3 no observadas por ausencia de DOSBox,
  limitación declarada y aceptada (D-036/D-038).
- **Tests:** `run_all.gd` **716 asserts**; harness F2 6/6; F1 6/6; `validate_data.gd` 0 errores (5.281 comprobaciones).
Tag anotado `fase-2`.

---

## 2. Entorno verificado

| Elemento | Resultado |
|---|---|
| Workspace `C:\Proyectos\TSB` | OK — GDD maestro + carpeta GK2 presentes; nada se creó fuera del workspace |
| GDD maestro | 44.341 B, 664 líneas, v1.2 — leído completo |
| Referencia GK2 (solo lectura; solo AG-REA) | 35 archivos `.DAT`/`.GK2`/`.EXE`; los `.EXE` **no** se abrieron |
| Godot | Editor `C:\Godot\Godot_v4.7.2-stable_win64.exe` · Consola/CI `..._console.exe` — 4.7.2.stable.official (`ed1daf0bf`) |
| Git | 2.56.0.windows.1; identidad `horaciomartinez-svg`; remoto `origin` operativo |
| Repo remoto | Historial previo conservado (2 commits); primer commit del equipo añadido encima (D-001) |
| MCP | `rea-mcp` usado por AG-REA; `godot-mcp` reservado para Fase 1 (AG-2/AG-3) |

---

## 3. Criterios de aceptación Fase 0 — GDD §12

| # | Criterio (§12) | Estado | Evidencia |
|---|---|---|---|
| A1 | Informe `docs/rea/gk2_data_lessons.md` | ✅ | 1.721 palabras, 143 líneas, tablas de campos + 8 equivalencias GK2→JSON §7 + 10 lecciones + método/límites + declaración legal |
| A2 | Schemas + datasets Escenario 1 validados | ✅ | 6 schemas draft 2020-12; 14 facciones / 8 playable / 47 regiones / 86 personajes / 17 unidades / 18 eventos; `validate_data.gd` → 0 errores |
| A3 | Repo Godot compilando, autoloads vacíos, CI headless | ✅ | `--editor --quit` exit 0; 10/10 autoloads registrados; `tools/ci_headless.ps1` (import + validación + suite) |
| A4 | `tools/validate_data.gd` 0 errores | ✅ | 6 datasets ↔ 6 schemas, **5.239 comprobaciones**, 0 `[FAIL]`, 0 `[WARN]`, exit 0 (repetido: determinista) |
| A5 | `godot --headless` sin errores críticos | ✅ | `--script tools/validate_data.gd`, `--script tests/run_all.gd` (**231 pass / 0 fail / 1 skip**) e `--editor --quit`: exit 0, sin `ERROR`/`WARNING` |
| A6 | Informe REA ≤ 2 páginas | ✅ | 1.721 palabras (umbral operativo ≤1.800) y formato compacto con tablas; QA lo valida |

**QA independiente (AG-4):** veredicto **APROBADO**, acciones de verificación reproducidas en
`docs/issues.md` §2-§4 (salidas íntegras, códigos de salida, hashes SHA-256, determinismo).

---

## 4. Entregables

| Entregable | Owner | Ruta | Tamaño |
|---|---|---|---|
| GDD en raíz del repo | AG-0 | `GDD_The_Sovereign's_Blood.md` | 44.341 B |
| Proyecto Godot | AG-0/AG-2 | `project.godot` (config_version 5, 10 autoloads, 1920×1080) | — |
| Autoloads (contratos §8.2) | AG-2 | `scripts/autoload/*.gd` (10) | — |
| RNG sembrado | AG-2 | `scripts/utils/rng.gd` (`SeededRNG`) | 3.121 B |
| Modelos | AG-2 | `scripts/model/*.gd` (5, incl. `BattleReport`) | — |
| Validador + CI | AG-2 | `tools/validate_data.gd`, `tools/validator_core.gd`, `tools/ci_headless.ps1` | 38,1 KB + 1,9 KB + 4,6 KB |
| Tests headless | AG-2 | `tests/run_all.gd` + 4 suites | **231 asserts** |
| Datasets 1337 | AG-1 | `data/factions.json`, `regions.json`, `characters.json`, `units.json`, `events_1337.json`, `scenarios/scenario_1337.json` | 196.632 B |
| Schemas | AG-1 | `data/schema/*.schema.json` (6) | — |
| Fuentes | AG-1 | `data/sources.md` | 182 URLs, 8 secciones |
| Informe REA | AG-REA | `docs/rea/gk2_data_lessons.md` (+ `notes.md` anexo, D-012) | 10.887 B |
| QA | AG-4 | `docs/issues.md` | 538 líneas |
| Gobernanza | AG-0 | `docs/STATUS.md`, `docs/decisions.md` (D-001…D-014) | — |
| Definiciones de agentes | AG-0 | `C:\Proyectos\TSB\agents\AG-*.md` (AG-0, AG-REA, AG-1, AG-2, AG-4) | — |

**Volumen de datos:** 14 facciones (8 jugables) · 47 regiones (130 entradas de adyacencia = 65 pares,
grafo conectado) · 86 personajes (14 gobernantes, 1 por facción) · 17 unidades · 18 eventos (1337-1399) ·
14 tesorerías y 14 ejércitos iniciales.

**Regla de oro §7.8 cumplida:** 47/47 regiones con `source` + `estimate:true`; 86/86 personajes con
`source` + `estimate`; 18/18 eventos con `source`; 0 URLs de datasets ausentes de `sources.md`.

---

## 5. Evidencia de ejecución (verificada por AG-0 y AG-4)

```
1) godot --headless --path <repo> --script tools/validate_data.gd        → exit 0
   [OK] 6 dataset(s) validado(s) contra 6 schema(s); reglas cruzadas §13 OK; 0 errores.
2) godot --headless --path <repo> --script tests/run_all.gd              → exit 0
   RESULTADO: 231 pasados, 0 fallidos, 1 omitidos   ·   CI: OK
3) godot --headless --path <repo> --editor --quit                        → exit 0
   first_scan_filesystem [DONE] · loading_editor_layout [DONE] · sin ERROR/WARNING
4) tools/ci_headless.ps1                                                 → exit 0 (3/3 pasos)
```

Repeticiones de (1) y (2): salida y códigos idénticos → **determinismo** de validación y tests.
`.godot/` está excluido de Git; `*.gd.uid` (23) se versionan como recomienda Godot 4.4+.

---

## 6. QA — observaciones menores y resolución

| ID | Severidad | Hallazgo | Resolución AG-0 |
|---|---|---|---|
| OBS-01 | Informativo | Capital del HRE (Praga) pertenece a Bohemia en 1337 | Conforme al GDD §4.2; decisión **D-010** y documentado en `sources.md` |
| OBS-02 | Menor | Casas `fournier` y `qalawun` no literales al GDD («—»/«Bahri») | **D-011**: se mantienen (familia papal / dinastía qalawuní dentro de Bahri); aclarado en `sources.md` |
| OBS-03 | Menor | `sources.md` decía «130 enlaces» (son 130 entradas dirigidas = 65 pares) | Corregido en `sources.md` (redacción) |
| OBS-04 | Menor | Anexo extra `docs/rea/notes.md` vs «Nada más» de §3 | **D-012**: aceptado como apéndice interno de método; el entregable sigue siendo el informe de 2 páginas |
| OBS-05 | Informativo | HEAD local avanzó durante la QA | Sin impacto; artefactos estables (hashes en `docs/issues.md`) |

Ningún hallazgo bloqueante ni mayor. No se requirieron tests de regresión nuevos.

---

## 7. Git — commits y tags

| Commit | Autor | Contenido |
|---|---|---|
| `c3d3f50` | usuario | Initial commit (previo) |
| `8ab5180` | usuario | README del proyecto y flujo de trabajo (previo) |
| `6c31464` | AG-0 | `init`: estructura, GDD en raíz, STATUS y decisions |
| `8a171e0` | AG-2 | Scaffold Godot 4.7.2, autoloads, RNG, validador, CI headless |
| `5532e2c` | AG-1 | Datasets Escenario 1 (1337), schemas y fuentes |
| `c0f236e` | AG-REA | Informe de lecciones de modelado de datos GK2 |
| `ddc8aad` | AG-4 | QA Fase 0 (APROBADO) |
| `874c709` | AG-1 | Aclaraciones `sources.md` (OBS-02/03) |
| `7f2a443` | AG-0 | Cierre Fase 0 + tag `fase-0` |
| `f11b09f` | AG-0 | Fase 1: contrato de integración, D-015…D-017, STATUS |
| `722b778` | AG-2 | Sistemas núcleo Fase 1 + 317 tests; validador excluye presentación |
| `73bff2f` | AG-3 | UI completa Fase 1 (16 escenas) integrada |
| `7814dda` | AG-4 | Harness de aceptación (6 criterios) + plan QA |
| `29bd635` | AG-0 | GDD v1.4 y contrato de integración Fase 2 (D-024…D-031) |
| `7746791` | AG-1 | `map_borders.json` (3×47, 132.962 B) + campo `portrait` en schema + fuentes |
| `064b09a` | AG-2 | Batallas N2/N3, espionaje, extinción + 138 tests |
| `8451304` | AG-2 | Validador excluye `map_borders` (presentación) |
| `e748a71` | AG-3 | Mapa atlas 4 capas, retratos 5 slots, escenas N2/N3, D-024 |
| `f302a3c` | AG-4 | Harness Fase 2 + plan QA |
| `ef25d98` | AG-0 | Capturas Fase 2, referencia PD Shepherd, D-032/D-033 |
| `f560a40` | AG-2 | Extinción F2-C2 + `apply_close_combat_outcome` (D-033) |
| `dbfce73` | AG-3 | N3 aplica a campaña + capturas |
| `5c3aa93` | AG-0 | Addendum contrato D-033 + `.gitignore` |
| `bfe1b4e` | AG-0 | GDD v1.5 (REA ampliado, retratos finales, sprites §10.3) |
| `66b85b3` | AG-0 | 14 retratos finales integrados + D-034…D-037 |
| `a4ce356` | AG-1 | `portrait` en los 14 gobernantes |
| `871d3e4` | AG-2 | B-F2-01: bajas N2 con unidades destruidas + regresión |
| `f1e1bd1` | AG-3 | Retratos finales renderizados en 5 slots + capturas |
| `2d283ff` | AG-REA | Informe REA ampliado de batallas + anexo de método |
| `731ce6c` | AG-4 | QA Fase 2 v1.5 APROBADA + cierre REA |
| cierre Fase 2 | AG-0 | STATUS/decisiones D-032…D-038, tag `fase-2` y push |

**Tags de fase:** `fase-0`, `fase-1` y `fase-2` (anotados) en los commits de cierre, tras push a `origin/main`.
Historia lineal, sin force-push (GDD §3.2).

---

## 8. Equipo de agentes

| Agente | Rol | Estado | Definición |
|---|---|---|---|
| AG-0 | Coordinator (chat principal) | ✅ activo | `C:\Proyectos\TSB\agents\AG-0.md` |
| AG-REA | Reverse Engineer (alcance §3 + §3.2) | ✅ Fases 0 y 2 (informe de batallas) | `agents\AG-REA.md` |
| AG-1 | Historian/Data | ✅ Fases 0 y 2 (fronteras/retratos); Fase 3 (escenarios 2-3) | `agents\AG-1.md` |
| AG-2 | Systems Dev | ✅ Fases 0-2 (N1/N2/N3, espionaje, extinción) | `agents\AG-2.md` |
| AG-3 | UI Dev | ✅ Fases 1-2 (UI §9, mapa §10.1, retratos §10.2) | `agents\AG-3.md` |
| AG-4 | QA | ✅ Fases 0-2 aprobadas | `agents\AG-4.md` |
| AG-5 | Art Pipeline | ⏸ no activado (Fase 3: sprites §10.3, retratos restantes, música) | pendiente de crear MD al activar |

---

## 9. Decisiones registradas

`docs/decisions.md`: D-001 base del repo · D-002 paralelización Fase 0 · D-003 autoría informe REA ·
D-004 validador GDScript (subconjunto JSON Schema) · D-005 git centralizado en AG-0 · D-006 criterio
de "compila" · D-007 GDD en repo · D-008 alcance de datos 1337 · D-009 envelope de datasets ·
D-010 capital dual Praga · D-011 nomenclatura de casas · D-012 anexo técnico REA · D-013 CI local y
GitHub Actions diferido · D-014 registro de QA por fase · D-015 audio_manager (OBS-K1) · D-016 contrato
Fase 1 · D-017 `map_layout` presentación · D-018 exclusión de presentación en el validador · D-019
`allocate` absoluto · D-020 educación automática en MVP · D-021 capturas versionadas · D-022 la fachada
de UI expone referencias vivas de solo lectura (auditado) · D-023 tooling dev en `scripts/ui/dev` ·
**D-024 deprecación de `map_layout.json` (ejecutada)** · D-025 contrato Fase 2 · D-026 terreno por código ·
D-027 retratos Fase 2 (fallback) · D-028 referencia comparativa del mapa · D-029 batallas N2/N3 ·
D-030 espionaje · D-031 extinción dinástica · D-032 `map_borders` dato de presentación · D-033 Nivel 3
aplica a campaña · **D-034 GDD v1.5** · **D-035 retratos finales integrados** · **D-036 REA ampliado de
batallas** · **D-037 sprites §10.3 en Fase 3** · **D-038 limitación DOSBox documentada (REA)**.

---

## 10. Bloqueos y riesgos

- **Bloqueos:** ninguno. Fases 0-2 cerradas; Fase 3 pendiente de luz verde del usuario.
- Riesgo residual (bajo): el REA ampliado **no pudo observar** las mecánicas N2/N3 (DOSBox no instalado).
  Limitación documentada y aceptada (D-036/D-038); el usuario puede aportar capturas para completar §2 en
  una reactivación de AG-REA. Las lecciones de diseño §10.3 sí están entregadas.
- Riesgo residual (bajo): `scripts/ui/dev` contiene tooling (smoke/probe/screenshots); no se carga desde
  escenas (M-F1-03, D-023).
- Riesgo residual (bajo): `tsb_game.gd` devuelve copias defensivas (`duplicate(true)`) desde Fase 2; la
  auditoría de QA confirma 0 mutaciones desde UI (D-022).
- Riesgo residual (bajo): el criterio de render del mapa es CPU lógica/redibujado en headless (no GPU);
  media 0,178 ms, pico aislado 8,58 ms al cambiar de vista (documentado en QA).
- Sprites de unidades §10.3 (64×64, proyectiles, hojas de animación) planificados para **Fase 3** con AG-5
  (D-037); no son criterio de Fase 2.
- Sin acceso a la carpeta GK2 por parte de AG-1/AG-2/AG-3/AG-4 (regla §3.1.2 respetada).

---

## 11. Próximos pasos — Fase 3 (Contenido y remaster, GDD §12 v1.5)

1. **AG-1:** datasets de los escenarios 1402 y 1453 (facciones, personajes, regiones/owners, eventos:
   Ankara, locura de Carlos VI, caída de Constantinopla, Dos Rosas) + fuentes.
2. **AG-2:** activación por año de escenario, evolución tecnológica (eras I-III), balance, partida
   automatizada de 10 años (QA §13).
3. **AG-3:** escenario select con 1402/1453, UI de evolución tecnológica, pulidos de mapa/retratos.
4. **AG-5 (nuevo):** sprites de unidades §10.3 (hojas de animación 64×64/64×80, proyectiles visibles,
   `units.json.sprite_sheet`), retratos de herederos/escenarios 1402-1453, música CC, tiles; hoja de
   estilo derivada de §10.2/§10.3 y del REA ampliado.
5. **AG-4:** QA de Fase 3 (3 escenarios completos, victoria/derrota §4.5, 10 años sin errores, sprites y
   retratos finales sin huecos).
6. **Pendiente del usuario:** luz verde para iniciar Fase 3. Tag `fase-3` al cumplir §12.

---

## 12. Verificación de Kimi (protocolo §3.2)

- Fase 0: entregables y criterios §12 verificados — **APROBADO CON OBSERVACIONES** (OBS-K1 → D-015).
- Fase 1: QA independiente **APROBADO** 6/6; UI auditada estáticamente (0 mutaciones); capturas 1920×1080.
- Fase 2: QA independiente **APROBADO (v1.5)** 6/6 + REA §3.2 verificado; mapa, retratos finales, N2/N3,
  espionaje y extinción; capturas 1920×1080 en `docs/screenshots/`.
- ¿Cumplimiento legal (sin material Koei/terceros)? → datos 100% originales con fuentes abiertas;
  informes REA limitados a estructura, sin nombres/textos del juego, sin análisis de `.EXE`, sin copia de
  píxeles/paletas/assets (§3, §3.2).
- Resultado esperado: **APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO**; hallazgos se corrigen
  antes de continuar (§3.2.5).

---

## 13. Fase 1 — MVP jugable (CERRADA, tag `fase-1`)

**Estado:** cerrada el 2026-11-21. **QA Fase 1: APROBADO** — 6/6 criterios §12, 0 bloqueantes,
0 mayores, 3 menores no bloqueantes (ver `docs/qa/fase1_report.md`).

**Entregado:**
- Sistemas núcleo reales (10 autoloads): turno/PG, economía con apoyo y revueltas, dinastía
  (nacimientos/matrimonios/educación automática/sucesión/regencia/extinción), diplomacia (7 acciones),
  militar (reclutamiento/movimiento/ocupación), batalla delegada Nivel 1 §6.1, IA de 13 rivales,
  eventos (incluida Peste Negra 1348), guardado/carga `save_version 1` con autosave.
- UI §9 completa: 16 escenas (menú, selección, mapa de 47 regiones, panel de región, consejo, familia,
  diplomacia, militar, economía, corte, opciones, tooltip, informe de batalla, fin de año, victoria).
  Tema pergamino/tinta/dorado, heráldica generativa, sin assets externos.
- 16 capturas 1920×1080 del flujo real en `docs/screenshots/` (duplicado M-F1-01 eliminado).
- Tests: `tests/run_all.gd` **548 asserts** (+317) y `tests/qa_acceptance.gd` (6 criterios).
- Contrato de integración `docs/architecture_contracts_fase1.md` y decisiones D-015…D-023.

**Evidencia de aceptación (QA independiente, no confía en AG-2/AG-3):**

| Criterio §12 | Resultado |
|---|---|
| Inglaterra 1337 jugable de inicio a fin de año | PASS — 1337·T1→1338·T1, 4 trimestres, 8/8 órdenes, sin crash |
| IA de 13 rivales <2 s | PASS — **17 ms** (16–21 ms en 4 ejecuciones; ~100× margen) |
| Guardar/cargar exacto | PASS — hash `900976fefd4c7e01` idéntico; save 96.231 B; restaurado tras perturbar el estado; RNG reproducible |
| Batalla delegada con informe y captura | PASS — Burgos con defensores; informe de 16 campos; owner castile→england |
| Peste Negra 1348 (−0.35 `europe_west`) | PASS — `event_log`+`fired_events`; 32 regiones ratio ≈0,65; 9/9 facciones occidentales |
| UI §9 headless | PASS — 16/16 escenas instanciadas; auditoría estática: 0 mutaciones de estado |

**Comandos de cierre (todos exit 0):** `qa_acceptance.gd` (6/6 PASS), `run_all.gd` (548/0/1),
`validate_data.gd` (0 errores), `--editor --quit`, `--headless --quit`. Repeticiones → determinismo.

**Observaciones menores y resolución:**

| ID | Hallazgo | Resolución |
|---|---|---|
| M-F1-01 | Capturas 14 y 15 byte-idénticas | Duplicada `15_live_overlay_battle.png` eliminada |
| M-F1-02 | `tsb_game.gd` expone refs vivas (0 escrituras) | Auditado por QA; contrato prohíbe mutar; D-022 (copias defensivas en Fase 2) |
| M-F1-03 | Tooling dev en `scripts/ui/dev/` | Documentado como tooling no cargado (D-023); migración opcional |

**Cierre:** commits `[AG-2]`/`[AG-3]`/`[AG-4]` y cierre `[AG-0]`, push a `origin/main`, tag anotado
`fase-1`. Listo para revisión de Kimi del repo remoto.

---

## 14. Fase 2 — Profundidad militar + Mapa §10.1 + Retratos §10.2 (CERRADA, tag `fase-2`)

**Estado:** cerrada el 2026-11-22. **QA independiente APROBADO (v1.5)** — 6/6 criterios §12/§10.1/§10.2
+ informe REA §3.2 verificado, **0 bloqueantes, 0 mayores** (ver `docs/qa/fase2_report.md`).
**GDD:** v1.5. **Contrato:** `docs/architecture_contracts_fase2.md`.

**Entregado:**
- **Militar N2/N3:** `TacticalBattle` (hex axial con terreno/objetivos, unidades desde Army, IA rival,
  determinismo); `CloseCombat` (cartas carga/disparo/formación/finta/retirada, +1 orden al mayor Mando);
  espionaje (acción `espia`, 6 PG, intel persistente); extinción dinástica (derrota inmediata, reloj
  congelado); Nivel 3 aplicado a la campaña (D-033, idempotente).
- **Mapa §10.1:** terreno 4096×3072 generado por código (`tools/generate_map_terrain.py`, determinista),
  fronteras vectoriales 1337/1402/1453 (`data/map_borders.json`), capa interactiva hover/click, entidades
  (banderas, ejércitos, nombres con elisión en 3 zoom, etiquetas de mar), cámara 2D zoom/pan;
  `map_layout.json` eliminado (D-024) y `map_borders` excluido del validador como presentación (D-032).
- **Retratos §10.2 (v1.5):** 14 retratos finales de Kimi (256×256) en `assets/art/portraits/<id>.png`,
  campo `portrait` res:// en los 14 gobernantes, renderizados en los **5 slots** (mapa, árbol, diplomacia,
  batalla, corte); fallback heráldico para el resto; sucesión textura→heredero verificada; hoja de
  contacto final en `docs/screenshots/portraits_contact_sheet_final.png`.
- **REA ampliado §3.2 (v1.5):** `docs/rea/gk2_battle_mechanics.md` (1.998 palabras) + `notes_battle.md`:
  estructura `SUNIT.DAT` (96×512 B), `KPAT.DAT` (máscaras/patrones), `GRPDATA.DAT` (raster/tiles) y
  8 lecciones de diseño para §10.3. Mecánicas N2/N3 **no observadas** por ausencia de DOSBox: limitación
  declarada, sin inventar, con protocolo de capturas para el usuario (D-036/D-038).
- **Tests:** `run_all.gd` **716 asserts** (+168 desde Fase 1); harness F2 6/6; harness F1 6/6;
  `validate_data.gd` **5.281 comprobaciones, 0 errores**; 38 capturas (clave 1920×1080).

**Evidencia de aceptación (QA independiente):**

| Criterio | Resultado |
|---|---|
| Crécy (1346) en los 3 niveles, coherente | PASS — N1 Inglaterra 703/724 (3 asaltos); N2 Francia **1200/509** (5 rondas); N3 Inglaterra 773/641; deterministas; N3→campaña idempotente |
| Pérdida de líder sin herederos → fin de partida | PASS — `extinct=true`, `dynasty_extinct`, `game_over(false,"dinastía extinta")`, reloj congelado (sin turnos fantasma) |
| 47/47 polígonos × 3 años, sin huérfanas, ≤150 KB | PASS — 132.962 B; 7.410 puntos; ids válidos; 1337 owners coherentes; `center` dentro del anillo |
| Hover/click 3 vistas + render <8 ms CPU | PASS — hit-test QA 141/141 y 141/141 con la implementación real; benchmark 120 frames: **media 0,178 ms** (<8), pico aislado 8,58 ms al cambiar vista (documentado) |
| Captura comparativa del mapa | PASS — `map_comparison.png` 1920×1080 (TSB vs Shepherd PD, D-028); M-F2-01 cerrada |
| Retratos 5 slots + fallback + sucesión | PASS — 14/14 PNG 256×256; **5/5 slots con textura**; fallback heráldico en heredero (nunca vacío); sucesión textura→heredero sin recargar |
| REA §3.2 | PASS — informe + anexo; legalidad verificada (sin `.EXE`, sin copia de píxeles/paletas, sin texto); limitación de observación aceptada |
| No regresión Fase 1 | PASS — F1 6/6, save/load, Peste Negra 1348, determinismo, UI 0 mutaciones, 18/18 escenas |

**Comandos de cierre (todos exit 0):** `qa_acceptance_fase2.gd` (6/6), `qa_acceptance.gd` (6/6, F1),
`run_all.gd` (716/0/1), `validate_data.gd` (0 errores), `--editor --quit`, `--headless --quit`.
Harness F2 repetido → determinista.

**Observaciones y resolución:**
| ID | Hallazgo | Resolución |
|---|---|---|
| B-F2-01 | N2 no contabilizaba bajas de unidades destruidas (0/509) | **Corregido** por AG-2: `_start_men_by_side` por bando + regresión (+7 asserts); N2 1200/509 |
| M-F2-01 | Comparativa/retrato no 1920×1080 | Reexportadas a 1920×1080; QA confirma 4/4 capturas de retrato |
| M-F2-02 | Artefacto del harness al fallar C1 | Resuelto al cerrar B-F2-01 |
| M-F2-03 | Bucle de fast-forward del harness F1 | Corregido en harness de QA (sin tocar producción) |
| REA-obs | DOSBox no disponible; mecánicas N2/N3 no observadas | Declarado en el informe; protocolo de capturas; aceptado como no bloqueante (D-038) |

**Cierre:** commits `[AG-1]`/`[AG-2]`/`[AG-3]`/`[AG-4]`/`[AG-REA]` y cierre `[AG-0]`, push a
`origin/main` y tag anotado **`fase-2`**. Fase 3 (escenarios 1402/1453, sprites §10.3 con AG-5, arte final)
queda planificada en §11 y pendiente de luz verde del usuario.

---

## 15. Fase 3 — Contenido y remaster (EN CURSO; PRIORIDAD 1: sprites)

**Luz verde:** 2026-11-22. **GDD:** v1.6. **Contrato de la prioridad 1:** `docs/architecture_contracts_fase3.md`.
**Paquete recibido:** `Sprites_Unidades_TSB.zip` (Kimi): 6 unidades núcleo × 3 cuadros de marcha + 3 proyectiles + README.

| Línea | Owner | Entregable | Estado |
|---|---|---|---|
| Assets de sprites núcleo | AG-5 | `assets/art/sprites/units/` (18 PNG 64×64/64×80), fuentes `src/`, proyectiles | ⏳ |
| Datos + lógica de batalla | AG-2 | `sprite_sheet` en `units.json` + schema; animación/mirroring/proyectiles en N2/N3 | ⏳ |
| Render N2/N3 | AG-3 | sprites, marcha 6 fps, espejo oeste, capa de proyectiles balísticos; capturas 64 px | ⏳ |
| QA de sprites | AG-4 | harness fase 3, carga headless, Crécy N1/N2/N3, capturas y legibilidad | ⏳ |
| Escenarios 1402/1453 | AG-1 | datos + eventos (Ankara, locura de Carlos VI, Constantinopla, Dos Rosas) + evolución tecnológica | ⏸ tras prioridad 1 |
| Retratos nuevos / animaciones completas / 11 unidades | AG-5 | hoja de estilo Kimi; petición de generación a Kimi si el equipo no tiene arte IA | ⏸ tras prioridad 1 |
| Tiles tácticos, relieve, música CC | AG-5/AG-3 | assets e integración | ⏸ fin de fase |
| QA final Fase 3 | AG-4 | 3 escenarios completos, victoria/derrota §4.5, partida automatizada 10 años, sprites/retratos | ⏸ |

**Criterio de aceptación de la PRIORIDAD 1 (GDD §10.3 v1.6):** 6 unidades núcleo con `sprite_sheet`
válido y carga en CI headless; silueta reconocible del arma a 64 px (milicia, ballesteros, arqueros);
marcha 6 fps con espejo al oeste; proyectiles virote/flecha/piedra en capa separada con trayectoria
balística; fallback heráldico en las 11 restantes; capturas en `docs/screenshots/`; no regresión.

**Decisiones:** D-039 (GDD v1.6), D-040 (reparto AG-5/AG-2/AG-3/AG-4), D-041 (fuentes `src/` +
`.gdignore`), D-042 (orientación/ciclo/proyectiles), D-043 (pipeline de las 11 restantes y cuadros de
combate vía Kimi).

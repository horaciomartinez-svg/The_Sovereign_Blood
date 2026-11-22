# Estado del proyecto — The Sovereign's Blood

| Campo | Valor |
|---|---|
| **Fase actual** | **Fase 4 — Profundidad GK2 (CERRADA)**; **QA Fase 4 14/14 APROBADO**; mercancías/comercio, ejércitos, consorte, Manual, tutorial/Consejero, acciones 1/turno y costes por tipo integrados; 1402/1453 siguen congelados (D-066); sin arte externo |
| **Fase anterior** | **Fase 3.3 — MVP-1337 (CERRADA)**; QA 11/11 APROBADO |
| **Siguiente fase** | Fase 5 — no definida (reanudar 1402/1453, Paquete A de retratos y ampliación de contenido es decisión del usuario) |
| **GDD** | **v1.9.1** — `GDD_The_Sovereign's_Blood.md` (Fase 4 §5.2/§5.3/§5.5/§9/§12 + D-074/D-075; hereda §10.2-§10.4 y v1.8.1) |
| **Contrato Fase 4** | `docs/architecture_contracts_fase4.md` (comercio, ejércitos, consorte, Manual, tutorial, acciones 1/turno, costes) |
| **Contrato Fase 3** | `docs/architecture_contracts_fase3.md` (sprites + animación base + delta 13/15), `docs/architecture_contracts_fase3_tiles.md` (tiles), `docs/architecture_contracts_fase3_scenarios.md` (escenarios/tech/victoria) |
| **Contrato Fase 2** | `docs/architecture_contracts_fase2.md` (map_borders, batallas N2/N3, retratos, espionaje, extinción) |
| **Coordinador** | AG-0 |
| **Repo** | https://github.com/horaciomartinez-svg/The_Sovereign_Blood (rama `main`, sin force-push) |
| **Fecha de cierre Fase 2** | 2026-11-22 |
| **Fecha de cierre Fase 3** | 2026-11-22 |
| **Fecha de cierre Fase 3.1** | 2026-11-22 |
| **Fecha de cierre Fase 3.2** | 2026-11-23 |
| **Fecha de cierre Fase 3.3** | 2026-11-23 |
| **Fecha de cierre Fase 4** | 2026-11-23 |
| **QA Fase 0** | **APROBADO** — 0 bloqueantes, 0 mayores, 5 observaciones menores (ver `docs/issues.md`) |
| **QA Fase 1** | **APROBADO** — 6/6 criterios §12, 0 bloqueantes, 3 menores (ver `docs/qa/fase1_report.md`) |
| **QA Fase 2** | **APROBADO (v1.5)** — 6/6 criterios §12/§10.1/§10.2 + REA §3.2 verificado; 0 bloqueantes (ver `docs/qa/fase2_report.md`) |
| **QA Sprites Fase 3** | **APROBADO 6/6 (17/17 unidades)** — `docs/qa/fase3_sprites_report.md` |
| **QA Tiles Fase 3** | **APROBADO 7/7** — `docs/qa/fase3_tiles_report.md` |
| **QA Final Fase 3** | **APROBADO CON OBSERVACIONES (7/7)** — `docs/qa/fase3_report.md`; solo retratos ilustrados Kimi pendientes |
| **QA Animación Fase 3.1** | **APROBADO 6/6 (17×13 frames, 170 sprites)** — `docs/qa/fase3_anim_report.md` |
| **QA Animación Fase 3.2** | **APROBADO 6/6 (235 frames; delta 76; attack_4/impact)** — `docs/qa/fase3_anim_report.md` |
| **QA MVP-1337 (Fase 3.3)** | **APROBADO 11/11** — `docs/qa/fase3_mvp_report.md` |
| **QA Fase 4** | **APROBADO 14/14** — `docs/qa/fase4_report.md` |
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

## 15. Fase 3 — Contenido y remaster (EN CURSO)

**Luz verde:** 2026-11-22. **GDD:** v1.7. **Contratos:** `docs/architecture_contracts_fase3.md` (sprites)
y `docs/architecture_contracts_fase3_tiles.md` (tiles §10.4).

| Línea | Owner | Entregable | Estado |
|---|---|---|---|
| **Sprites §10.3 (17/17)** | AG-5/AG-2/AG-3 | 51 PNG 64×64/64×80/64×43 + fuentes `src/`; `sprite_sheet` en 17/17; render N2/N3, marcha/mirroring/proyectiles; QA | ✅ **CERRADO — QA APROBADO 6/6** |
| **Tiles §10.4** | AG-3/AG-2 | 12 tiles 512 (raw en `src/`), campo N3 128 px con rotación, generador desde región; `battle_tiles` + reglas (río/montaña impassable, colina/bosque/camino/villa); QA | ✅ **CERRADO — QA APROBADO 7/7** |
| Escenarios 1402/1453 | AG-1 | datos + eventos (Ankara, locura de Carlos VI, Constantinopla, Dos Rosas) + evolución tecnológica | ⏸ siguiente |
| Retratos herederos/1402/1453 + cuadros idle/ataque/impacto/muerte | AG-5 | hoja de estilo Kimi; petición de generación a Kimi (D-049) | ⏸ siguiente |
| Relieve del mapa, música CC, efectos, balance | AG-5/AG-3 | assets e integración | ⏸ fin de fase |
| QA final Fase 3 | AG-4 | 3 escenarios completos, victoria/derrota §4.5, partida automatizada 10 años, sprites/retratos/tiles | ⏸ |

**Sprites §10.3 — aceptación superada (v1.6, 17/17):**
- 17/17 unidades con `sprite_sheet` válido y frames cargando headless (64×64 infantería/ranged, 64×80
  caballería, 64×43 bombarda/carro); 51 PNG de producción + 51 fuentes `_raw_1024` en `src/` (`.gdignore`).
- Render N2/N3: marcha 6 fps ciclo 3, espejo al oeste, proyectiles en capa separada (virote→ballesteros;
  flecha→arqueros/jenízaros/estepa; piedra→bombarda) con trayectoria balística.
- Fallback heráldico para unidades sin sprite (probado con unidad sintética).
- Capturas 64 px reales de milicia, ballesteros, arqueros, almogávar y jenízaro + N2/N3 con proyectiles.
- QA independiente: `docs/qa/fase3_sprites_report.md` — **APROBADO 6/6**; `run_all` **1074/0/1**;
  `validate_data` 5.570 comprobaciones, 0 errores; sin regresión F1/F2.
- Decisiones: D-039…D-050.

**Tiles §10.4 — aceptación superada (GDD v1.7):**
- 12 mosaicos 512×512 en `assets/art/battle/tiles/` (+12 `_raw_1024` en `src/` con `.gdignore`, sin importar);
  hoja de contacto en `docs/screenshots/tiles_contact_sheet.png`.
- `data/battle_tiles.json` + schema + validación en `validate_data.gd` como dato de juego: **7 datasets/7
  schemas, 5.722 comprobaciones, 0 WARN/0 errores**; 12 claves con balance D-053 (río/montaña impassable,
  colina 2/1, bosque 2/1 + `cavalry_penalty`, camino 0,5 + `move_bonus`, villa/puente_villa defensa).
- Reglas tácticas en N2/N3 (`BattleTiles`, `TacticalBattle`, `CloseCombat`): intransitables, costes
  fraccionarios, defensa por tile, penalización de caballería, bonus de camino; determinismo intacto.
- Render N3: rejilla 8×3 a 128 px (texturas 512), rotación 90° en motor de río/puente/puente_villa/camino;
  generador determinista derivado de `region.terrain` con río de orilla a orilla + 1-2 puentes, villa y
  caminos; capturas `tiles_n3_rio_puente_villa.png` y `tiles_n3_llanura.png` (1920×1080) revisadas.
- QA independiente: `docs/qa/fase3_tiles_report.md` — **APROBADO 7/7**; `run_all` **1194/0/1**; sin
  regresión sprites 17/17 ni F1/F2.

**Decisiones:** D-039 (GDD v1.6), D-040…D-043 (reparto/fuentes/orientación/pipeline), D-044…D-050
(17 unidades, id bombarda, fuentes raw, formatos, proyectiles, capturas), D-051…D-056 (GDD v1.7, reparto
tiles, `battle_tiles`, render/rotación, generador N3, capturas de tiles).

**Cierre de Fase 3 — aceptación (QA final 7/7 PASS, APROBADO CON OBSERVACIONES):**
- **3 escenarios completos:** 1337 "Dos Coronas" (→1399), 1402 "El Choque de Imperios" (→1460) y 1453
  "El Ocaso y el Alba" (→1480); arranque desde selección UI con 8 facciones jugables por escenario; mapa
  y HUD con año/era; final automático. Datos: 23 facciones (9 nuevas), 175 personajes, 47 regiones × 3
  años, 18 eventos históricos con fuentes; `validate_data` 11 datasets/7 schemas, **11.069 comprobaciones,
  0 WARN/0 errores**.
- **Tecnología por era:** I (<1350) / II (1350-1399) / III (≥1400); reclutamiento e IA limitados a la era;
  era visible en UI. **Victoria/derrota §4.5:** Prestigio Real sostenido, conquista ≥70%, supervivencia al
  año final, extinción de la casa o pérdida total; reloj congelado tras el fin.
- **QA final:** `tests/qa_acceptance_fase3_final.gd` **7/7** (3 escenarios recorridos hasta su año final
  sin crash; 10 años ×2 deterministas; gobernantes por año correctos: Enrique IV/Bayaceto I en 1402,
  Enrique VI/Mehmed II/Constantino XI en 1453; save/load exacto). Batería: `run_all` **1250/0/1**, F1 6/6,
  F2 6/6, sprites 6/6, tiles 7/7, editor/headless 0 ERROR/WARNING.
- **Arte:** sprites 17/17 (§10.3) y tiles 12/12 (§10.4) integrados; retratos nuevos y animaciones de
  combate **pendientes de entrega externa de Kimi** (petición `docs/art/requests/kimi_phase3_assets.md`:
  69 retratos 256×256 + 184 PNG idle/ataque/impacto/muerte). El fallback heráldico y la marcha actual
  garantizan que no haya huecos; se documenta como observación no bloqueante (D-062).
- **Observaciones menores:** `scenario_1337` aún deriva sus 8 jugables de flags globales (efecto correcto);
  REA §3.2 mantiene la limitación de observación aceptada (D-038); simulación de 10 años no duplica los
  recorridos completos (el harness C1 sí los recorre).
- **Cierre:** commits por agente + cierre `[AG-0]`, push a `origin/main` y tag anotado **`fase-3`**.
  Deuda externa abierta: entrega de arte de Kimi (retratos) para Fase 4; música CC, relieve y
  balance fino quedan para el siguiente ciclo. Verificación externa de Kimi contra GDD v1.7 pendiente de
  su informe.

---

## 16. Fase 3.1 — Animación de combate (D-049 v1.8, CERRADA)

**Luz verde:** 2026-11-22, tras verificación de Kimi de sprites §10.3 + tiles §10.4. **GDD:** v1.8.
**Paquete:** `Anim_Combate_TSB.zip` (Kimi): 170 PNG (17 unidades × idle2/attack4/hit2/death2) + 170
originales `_raw` + hoja de contacto + README. **Decisión:** D-064 (la instrucción pedía D-057, ya usada).

| Línea | Owner | Entregable | Estado |
|---|---|---|---|
| Assets de animación | AG-5 | 170 PNG LANCZOS 64×64/64×80/64×43 + 170 raw en `src/`; hoja de contacto | ✅ |
| Datos + estados de animación | AG-2 | `units.json` 13 frames/`anim` extendido + schema; estados idle/march/attack/hit/dead, timings y `death_hold`; tests | ✅ |
| Render N3 | AG-3 | idle, attack con `attack_2` (111-222 ms) sincronizado con proyectil, hit, death+hold; mirroring | ✅ |
| QA de animación | AG-4 | harness de animación, secuencias N3, capturas y veredicto | ✅ **APROBADO 6/6** |

**Contrato aplicado:** 13 frames por unidad — 0-2 marcha, 3-4 idle, 5-8 ataque (`attack_2` = impacto),
9-10 impacto, 11-12 muerte; `anim {march, idle, attack, hit, death, fps 6, loop, fps_attack 9, fps_hit 8,
fps_death 6, death_hold}`; `death_hold` persiste el último cuadro. Render N3: idle en guardia, ataque una
vez con impacto visual en `attack_2` y lanzamiento del proyectil en `launch_ms`/`attack_impact_ms`
(111,1 ms), reacción hit/dead programada a 222,2 ms, cadáver persistente; mirroring oeste.

**QA independiente (`docs/qa/fase3_anim_report.md`):** **APROBADO 6/6** — 17/17 × 13 frames = **221
texturas** (170 de animación + 51 de marcha) + 170 raw; `attack_2` en índice 6 a 111,1 ms, reacción
222,2 ms; sonda N3 real (idle→attack→attack_2→hit/dead + death_hold) y proyectil sincronizado; dos
secuencias deterministas; 3 capturas 1920×1080 revisadas; sin regresión sprites 6/6, tiles 7/7, QA final
Fase 3 7/7, F1/F2 6/6. `run_all` **1438/0/1**, `validate_data` **11 datasets/7 schemas, 11.545
comprobaciones, 0 WARN/0 errores**, editor/headless 0. Hashes de escenas/datos/capturas en el informe.
- **Observaciones no bloqueantes:** N3 expone `started_ms`+`impact_ms` (no un `launch_ms` único, equivalente
  verificado); límite de 111,1 ms en borde de frame por `floor` (ventana [111,1;222,2] correcta); arte de
  retratos (69 PNG) sigue pendiente de Kimi (D-062).
- **Cierre:** commits por agente + cierre `[AG-0]`, push a `origin/main` y tag anotado **`fase-3.1`**.
  El alcance §10.3 (marcha + combate) queda completo; Fase 4 puede centrarse en retratos ilustrados,
  música CC y balance/pulido.

---

## 17. Fase 3.2 — Delta de animación a distancia/artillería (GDD v1.8.1, CERRADA)

**Luz verde:** 2026-11-23 (Kimi verificó el cierre de Fase 3 y entregó el Paquete B completo).
**Paquete:** `Anim_Combate_Rango_Artilleria_TSB.zip` (Kimi, 98 MB): **76 PNG** = 42 `attack_1..6` para las
7 unidades a distancia/artillería (`janissary`, `arquebusier`, `crossbowmen`, `longbowman`,
`steppe_cavalry`, `bombarda`, `hussite_war_wagon`) + 34 `impact_1/2` para las 17 unidades (mismos píxeles
que los `hit_*`, renombrados) + 42 raws + hoja. **Decisión:** D-065 (la instrucción pedía D-064, ya usada).

| Línea | Owner | Entregable | Estado |
|---|---|---|---|
| Assets delta | AG-5 | 235 producción / 235 raws; 7×`attack_1..6`; 17×`impact_1/2`; `hit_*` eliminados; LANCZOS 64/80/43 | ✅ |
| Datos/schema/motor | AG-2 | 10×13 + 7×15 frames; `impact`/`fps_impact`; `attack_4` índice 8 (333,3 ms); reacción 444,4 ms; proyectil en `attack_4`; ranged 6 cuadros | ✅ |
| Render N3 | AG-3 | attack 4/6 cuadros, `attack_4` con proyectil, `impact`, `death_hold`; mirroring; tiles 12/12 | ✅ |
| QA delta | AG-4 | Pillow ZIP, 235 frames headless, N3 real, capturas y veredicto | ✅ **APROBADO 6/6** |

**Contrato aplicado (GDD v1.8.1 §10.3 líneas 561-563):** 10 unidades de choque con 13 frames
(`attack [5..8]`, `impact [9,10]`, `death [11,12]`) y 7 a distancia/artillería con 15 frames
(`attack [5..10]`, `impact [11,12]`, `death [13,14]`); `anim` con `impact`/`fps_impact:8`, `fps_attack:9`,
`fps_death:6`, `death_hold:true`; esquema plano `frames`+`anim` (no `animations`). `attack_4` es el disparo:
lanza el proyectil (virote/flecha/piedra) a t≈333,3 ms; `impact` del defensor a t≈444,4 ms; el ataque a
distancia completa 6 cuadros (666,7 ms) con recoil/recarga; muerte con `death_hold`; mirroring oeste.

**QA independiente (`docs/qa/fase3_anim_report.md`):** **APROBADO 6/6** — 235 frames producción + 235 raw
(82 attack, 34 impact, 0 hit) con Texture2D; Pillow del ZIP: 76/76 RGBA con alfa, 512-wide
(42×512×512, 18×512×640, 16×512×341); `attack_4` en 333,3 ms y reacción 444,4 ms; N3 real con proyectil
`launch_ms` 333,3 y death_hold; dos secuencias deterministas; 4 capturas 1920×1080; sin regresión sprites
6/6, tiles 7/7, QA final Fase 3 7/7, F1/F2 6/6. `run_all` **1469/0/1**, `validate_data` **11 datasets/7
schemas, 11.641 comprobaciones, 0 WARN/0 errores**, editor/headless 0. Hashes en el informe.
- **Observaciones:** `hit` desaparece del contrato (todo `impact`); borde de frame por `floor` en 333,3 ms
  (ventana [333,3;444,4] validada con 334 ms + `impact_ms` exacto); offsets de ancla del arte original
  (melee attack_2/3 aéreos, `death_2` 12–19 px) documentados para render futuro; retratos (69 PNG,
  Paquete A) siguen pendientes de Kimi (D-062) y no bloquean.
- **Cierre:** commits por agente + `[AG-0]`, push a `origin/main` y tag anotado **`fase-3.2`**. Animación de
  combate completa (184 PNG de combate + 51 de marcha = 235 frames finales); lista para la verificación
  de Kimi contra GDD v1.8.1 antes de abrir el Paquete A (retratos) o la siguiente línea.

---

## 18. Fase 3.3 — MVP-1337: endurecimiento del Escenario 1 (EN CURSO)

**Directiva del usuario (2026-11-23, verificada por Kimi):** suspender 1402/1453 y centrarse en que el
MVP con **un solo escenario (1337)** esté completo y funcione correctamente. Registrada en **D-066**.
**GDD de referencia:** v1.8.1. **Baseline:** `be28088` / tag `fase-3.2` (QA animación 6/6).

**Restricciones del tramo:** 1402/1453 **congelados** (datos en main, sin tocar contenido/balance/QA);
en `scenario_select` solo 1337 jugable y 1402/1453 con etiqueta **«EN PAUSA — disponible en versión
completa»** mediante flag reversible; **arte externo suspendido** (no se piden retratos ni arte a Kimi;
se mantienen/pulen fallbacks); nada de mecánicas fuera del GDD.

| Línea | Owner | Entregable | Estado |
|---|---|---|---|
| UI: pausa 1402/1453 + auditoría UX + capturas MVP | AG-3 | tarjetas deshabilitadas con etiqueta; pantallas §9 sin botones muertos; PG/tooltips; mensajes claros; capturas 1920×1080 del flujo | ⏳ |
| Sistemas: audio mínimo + robustez loop/save/perf/balance | AG-2 | `audio_manager` autoload + tonos generados (click, campana de fin de año, espada N3); victoria/derrota §4.5 robustas; save/load en 3 puntos; IA <2 s/turno; mapa <8 ms; balance 1337/era I | ⏳ |
| Datos: auditoría de eventos 1337 y balance | AG-1 | Peste Negra 1348 y todo `events_1337.json` disparan sin estado inválido; revisión de balance económico 1337 (sin tocar 1402/1453) | ⏳ |
| QA MVP-1337 | AG-4 | tests C1-C10, informe `docs/qa/fase3_mvp_report.md`, capturas, veredicto APROBADO | ⏳ |
| **Banda sonora MVP (D-067)** | AG-5/AG-1/AG-2/AG-3 | 6 pistas OGG PD/libres en `assets/audio/music/` (menú, mapa, N2, N3, fin de año, cierre); `data/audio_tracks.json`; buses Master/Music/SFX; crossfade 1,5-2 s; opciones persistentes; `docs/audio_licenses.md`; QA C11 | ⏳ |
| Gobernanza/cierre | AG-0 | D-066/D-067/D-068, STATUS, tag `fase-3.3`, push y aviso para verificación Kimi | ⏳ |

**Criterios de aceptación (C1-C11):** loop completo 1337 sin crash; 4 condiciones §4.5 alcanzables y
testeadas; N1/N2/N3 desde partida real con animación sin regresión; save/load exacto en 3 puntos; 10 años
× 8 facciones headless sin errores; `run_all` verde, `validate_data` 0, editor 0 warnings; IA <2 s/turno y
mapa <8 ms/frame; UX con 0 botones muertos, PG visible, audio mínimo y capturas §9; 1402/1453 congelados y
«EN PAUSA»; sin solicitudes de arte externo y fallbacks operativos; **C11 música:** 5-6 pistas PD/libres en
mapa y batallas, crossfade/loop limpio, opciones de volumen persistentes, `docs/audio_licenses.md` completo
y sin material con copyright.

**Cierre — Fase 3.3 CERRADA (QA MVP-1337: APROBADO 11/11).**
- **Loop completo 1337:** las 8 facciones jugables arrancan; trimestres completos; fin de año; fin de partida con
  motivo; England llega a 1399 con victoria por supervivencia. 4 condiciones §4.5 (prestigio, conquista ≥70%,
  supervivencia, extinción/pérdida total) alcanzables y testeadas.
- **Batallas N1/N2/N3** ejecutables desde partida real, con sprites/animación v1.8.1 sin regresión (QA anim 6/6).
- **Save/load exacto** en 3 puntos (turno intermedio, batalla pendiente con `pending_battle` level 2/3, fin de
  año) con hash/RNG; **10 años × 8 facciones** headless sin errores y estado serializable.
- **Estabilidad/rendimiento:** `run_all` **1742/0/2**, `validate_data` **12 datasets/8 schemas, 11.681
  comprobaciones, 0 WARN/0 errores**, editor/headless 0 ERROR/WARNING; IA **13-25 ms/turno** (<2 s), mapa
  **0,021-0,025 ms/frame** (<8 ms).
- **UX:** 15 capturas MVP + 5 de audio 1920×1080; PG siempre visible, tarjetas 1402/1453 «EN PAUSA — disponible
  en versión completa» (flag reversible), feedback de guardado/acciones, sin botones muertos; `ui_smoke` 47
  scripts/18 escenas.
- **Banda sonora (D-067):** 6 pistas OGG Vorbis **originales TSB (CC0)** en formas históricas PD — menú, mapa,
  N2, N3, fin de año y cierre; buses Master/Music(−6 dB)/SFX; `data/audio_tracks.json` (6 contextos);
  crossfade 1,8 s; opciones Música/SFX persistentes en `user://audio_config.json`; música no se corta en
  save/load; SFX click/campana/espada; `docs/audio_licenses.md` **sin material de terceros** (R1 eliminado).
- **Balance (D-068):** tesoros a 10 años ×1,10-×1,95 (antes ×5-×14), 8/8 facciones vivas; apoyo en montaña sin
  espiral; Peste Negra 1348 con mortandad dinástica; guerra anglo-francesa y eventos 1337 disparan; heredero de
  Polonia válido; reclutamiento solo era I.
- **Observaciones no bloqueantes:** escucha humana de la música pendiente (verificación técnica headless y
  licencias OK); el nodo de batalla no se serializa (solo `pending_battle`/contexto, la UI lo reabre); rendimiento
  GPU no medible en CI; 2 tests omitidos intencionales. 1402/1453 y Paquete A de retratos siguen congelados por
  decisión del usuario.
- **Cierre:** commits por agente + `[AG-0]`, push a `origin/main` y tag anotado **`fase-3.3`**. Se avisa al usuario
  para la verificación de Kimi contra GDD v1.8.1 + directiva v2; tras ella se decidirá Fase 4 (reanudar
  1402/1453, Paquete A y ampliación de contenido).

---

## 19. Fase 4 — Profundidad GK2: mercancías/comercio, ejércitos, familia, Manual y Consejero (CERRADA)

**Directiva del usuario (2026-11-23, verificada por Kimi):** tras probar el MVP falta «la profundidad de GK2». GDD **v1.9.1**. **Restricciones:** 1402/1453 congelados (D-066), sin arte externo, REA legal §3, sin mecánicas fuera de esta lista.

| Línea | Owner | Entregable | Estado |
|---|---|---|---|
| REA economía/menús + addendum D-076 | AG-REA | `docs/rea/gk2_economy_military_family.md` (1.286 palabras) + `notes_economy.md`: estructuras, UX y checklist | ✅ |
| Mercancías/comercio (D-069) | AG-1/AG-2/AG-3 | 10 bienes en `trade_goods.json` + schema/fuentes; producción por terreno/edificios; inventario; comerciantes obligatorios; mercado/precios; expedición; pantalla Mercado | ✅ |
| Ejércitos (D-070) | AG-2/AG-3 | pantalla global con sprite `march_1`, conteos, fuerza/moral/experiencia; Reclutar/Entrenar/Disolver; reclutamiento con caballos/armas | ✅ |
| Familia (D-071) | AG-2/AG-3 | «Pasar tiempo con la consorte» (3 PG, 1/trimestre, fertilidad 3 turnos, rechazo claro sin consorte) | ✅ |
| Manual del Jugador (D-072) | AG-1 | `docs/MANUAL_DEL_JUGADOR.md` (10 secciones) + acceso desde el juego + «Ayuda» | ✅ |
| Tutorial y dificultad (D-073) | AG-1/AG-2/AG-3 | `tutorial_script.json` (9 pasos); Consejero con avatar por código, resaltado y salto; Principiante/Normal; estado serializable | ✅ |
| Acciones 1/turno (D-074) | AG-2/AG-3 | `actions_used` por facción/turno; gating diplomacia/familia/construcción/espionaje/expedición; exenciones militar/trabajadores/mercado; UI «USADO» | ✅ |
| Costes por tipo (D-075) | AG-1/AG-2/AG-3 | `cost.gold` diferenciado (milicia 20 … caballería 65-160, hussite 170, bombarda 200), UI con oro+hombres+mercancías y deducción real | ✅ |
| QA Fase 4 (C1-C14) | AG-4 | tests, capturas, auditoría REA/legal/UX y `docs/qa/fase4_report.md` | ✅ **APROBADO 14/14** |

**Cierre — Fase 4 CERRADA (QA 14/14 APROBADO):**
- **Comercio (D-069):** 10 mercancías con `base_price`/`produced_by`/`used_by`; inventario de facción; producción trimestral; **sin Comerciantes no hay compra/venta**, volumen según ellos; precio dinámico (±35 %, clamp) verificado 10,0→10,35; expedición 2 PG/2 trimestres; grano/sal→apoyo, armas/caballos→reclutamiento; 10 años ×8 sin inflación (tesoros ×1,10-×1,94).
- **Ejércitos (D-070):** pantalla global con sprites `march_1`, conteos/fuerza/moral/experiencia; Reclutar/Entrenar/Disolver; reclutamiento consume `recruit_goods` (caballos/armas/hierro/madera) y falla con motivo.
- **Familia (D-071):** acción de consorte con 3 PG, 1/trimestre, fertilidad 3 turnos, +prestigio/lealtad y motivos claros.
- **Manual (D-072):** `docs/MANUAL_DEL_JUGADOR.md` (10 secciones) + botón en menú + «Ayuda».
- **Tutorial/dificultad (D-073):** Principiante (Consejero + IA×0.75) / Normal; 9 pasos en datos, resaltado, salto y estado serializable.
- **Acciones/costes (D-074/D-075):** solo militar, asignación de trabajadores y mercado permiten múltiples por turno; el resto una vez (motor+UI, motivo `action_used`); costes por unidad visibles y deducidos (milicia 20 < arqueros 45-60 < caballería 65-160 < artillería 170-200). REA addendum D-076 documenta que no hay tablas GK2 utilizables y las lecciones UX (legal, sin `.EXE`/texto/assets).
- **QA/estabilidad:** `run_all` **1968/0/2**, `validate_data` **14 datasets/10 schemas, 11.927 comprobaciones, 0 WARN**, editor/headless 0, F1/F2/F3/MVP/anim/tiles verdes; `ui_smoke` 55 scripts/21 escenas; 12 capturas 1920×1080; `git diff fase-3.3..HEAD` en datos 1402/1453 = 0 archivos.
- **Observaciones no bloqueantes:** revisión visual de capturas sin click-through GUI completo; simulación headless no sustituye partida manual; addendum REA en notes para respetar ≤2 páginas; 1402/1453 y Paquete A siguen congelados por el usuario.
- **Cierre:** commits por agente + `[AG-0]`, push a `origin/main` y tag anotado **`fase-4`**. Se avisa al usuario para la verificación de Kimi contra GDD v1.9.1 + directiva; después se decidirá Fase 5 (reanudar 1402/1453, Paquete A y ampliación).

---

## 20. REA completa de GK2 — material local, NO versionado (D-077/D-078)

- **Autorización:** D-077 (usuario) permite a **AG-REA** análisis completo en solo lectura de
  `C:\Proyectos\TSB\genghis-khan-ii-clan-of-the-grey-wolf` con REA-MCP/Ghidra y hex, temporalmente y sin
  cambiar el alcance de los demás agentes.
- **Informe:** `REA_GK2_report.md` (4.230 palabras / 29.577 B; 8 módulos, evidencia por offset/función,
  Mermaid, tabla comparativa GK2↔TSB) vive **solo en local**:
  `C:\Proyectos\TSB\docs\rea\REA_GK2_report.md` (fuera de la carpeta git). Las rutas
  `REA_GK2_report.md` y `docs/rea/REA_GK2_report.md` dentro del repo están en `.gitignore` y **nunca** se
  commitean ni publican (el repo es público; material interno de estudio).
- **Verificación de no publicación:** `git status` no muestra el informe como tracked/untracked; `git
  check-ignore` confirma ambas rutas; no hay copia en la raíz ni en `docs/rea` del repo.
- **Cobertura Fase 4:** D-078 da por **cubierto** el preliminar `gk2_economy_military_family.md`: los
  módulos 3-6 del informe completo son la entrada de diseño de Fase 4 (mercancías/comercio, dinastía,
  diplomacia/espionaje, militar/batallas); AG-4 audita la cobertura. No se duplica documentación y no
  entra contenido en producción.
- **Integridad:** GK2 solo lectura (hashes re-verificados); TSB sin cambios de producción por AG-REA; los
  artefactos temporales de descompilación se eliminaron.
- **Uso previsto:** referencia de diseño para una eventual Fase 5; cualquier integración requiere decisión
  de AG-0 y no copia literal de código/datos/arte/texto.

**Veredicto de cobertura (AG-4, `docs/qa/fase4_rea_coverage.md`):** **Cobertura REA Fase 4: SUFICIENTE** — M3 (economía/comercio) y M6 (militar/unidades) alta; M4 (dinastía) y M5 (diplomacia) parciales, M2 (gating) parcial y M7 (IA) unknown, documentados sin inventar datos. C3/C4/C5/C14 respaldados por M3/M6; C6/C13 se cierran con D-071/D-074 y tests propios. Ningún vacío bloquea la fase.

---

## 21. Fase 5A — «El juego te explica»: legibilidad y aprendizaje (EN CURSO)

**Directiva:** `prompt_DSH_fase5a_legibilidad_v1.md` (Kimi, a partir del REA completo D-077/D-078, uso interno no publicado). **GDD v1.9.2** (nuevo §5.6 Legibilidad y ayuda; §9 ampliado). **Baseline:** tag `fase-4` (HEAD `6e9f9764`). Solo presentación/flujo sobre sistemas existentes; sin cambios de simulación, balance ni IA; determinismo intacto.

| Línea | Owner | Entregable | Estado |
|---|---|---|---|
| Textos de ayuda, boletín y crónica | AG-1 | `data/context_help.json` (3-5 líneas por pantalla §9) + `data/legibility_texts.json` (plantillas de boletín/crónica, etiquetas de estación; español propio) | ⏳ |
| Estado/API: `turn_actions`, `chronicle`, estación, consejo comercial, `advisor_enabled` | AG-2 | registro transitorio de órdenes (D-081); `state.chronicle` persistido con defaults (D-080); `get_season_name/label` (D-079); `TradeSystem.get_trade_advice` determinista y conmutador (D-082); tests/save | ⏳ |
| UI: HUD estaciones/tinte, boletín, crónica+histórico, confirmación de órdenes, «?», Consejero, panel unidad N2/N3 | AG-3 | pantallas/modales y capturas 1920×1080 (D-079…D-083) | ⏳ |
| QA Fase 5A | AG-4 | harness C1-C10, capturas, informe `docs/qa/fase5a_report.md` | ⏳ |
| Gobernanza/cierre | AG-0 | GDD v1.9.2, D-079…D-083, STATUS, tag `fase-5a`, push y aviso a Kimi | ⏳ |

**Criterios C1-C10:** HUD estación+año+tinte con capturas ×4; boletín ≥5 categorías/texto propio/0 botones muertos; crónica anual + histórico persistido (hash) y consultable; confirmación de órdenes con lista (incl. vacía), Corregir/Confirmar y log determinista; consejo comercial correcto sin RNG; «?» en todas las pantallas §9 (capturas ≥4); paneles N2/N3 con hombres/armas/apoyo/moral/experiencia y comandante; save/load con chronicle (3 puntos) y defaults; no regresión (run_all, validate 0 WARN, editor 0, IA<2 s, mapa<8 ms); congelamientos 1402/1453 diff 0, sin arte externo, GDD v1.9.2 + D-079…D-083 + tag `fase-5a`.

**Cierre previsto:** QA APROBADO 10/10 → commits por agente + `[AG-0]`, tag anotado **`fase-5a`**, push y aviso para verificación de Kimi contra GDD v1.9.2 + esta directiva.

**Actualización de la directiva (C11):** el Manual del Jugador (`docs/MANUAL_DEL_JUGADOR.md`) debe actualizarse con las cinco mejoras de Fase 5A y verificarse contra capturas; añadido como criterio **C11** del QA (task-80 y task-81).

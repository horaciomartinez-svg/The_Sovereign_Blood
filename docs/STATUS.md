# Estado del proyecto — The Sovereign's Blood

| Campo | Valor |
|---|---|
| **Fase actual** | **Fase 0 — CERRADA** (criterios §12 cumplidos; tag `fase-0`) |
| **Siguiente fase** | Fase 1 — MVP jugable (pendiente de luz verde del usuario) |
| **GDD** | v1.2 — `GDD_The_Sovereign's_Blood.md` (raíz del repo) |
| **Coordinador** | AG-0 |
| **Repo** | https://github.com/horaciomartinez-svg/The_Sovereign_Blood (rama `main`, sin force-push) |
| **Fecha de cierre** | 2026-11-21 |
| **QA Fase 0** | **APROBADO** — 0 bloqueantes, 0 mayores, 5 observaciones menores (ver `docs/issues.md`) |

---

## 1. Resumen ejecutivo

Fase 0 completada en una sesión. Entregados: el informe REA de alcance limitado, los datasets
completos del Escenario 1 (1337) con schemas y fuentes, el scaffold Godot 4.7.2 con 10 autoloads y
CI headless, y la validación independiente de QA. Los tres comandos obligatorios terminan con
**exit code 0** y **0 errores**: `validate_data.gd` (5.239 comprobaciones), suite headless
(**231 tests pasados**) e importación del proyecto. El informe REA tiene **1.721 palabras (~2 páginas)**.

No hay bloqueos ni deuda técnica conocida para iniciar Fase 1.

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
| cierre Fase 0 | AG-4/AG-1/AG-0 | QA (`docs/issues.md`), aclaraciones `sources.md` (OBS-02/03), STATUS/decisions y tag `fase-0` |

**Tag de fase:** `fase-0` (anotado) en el commit de cierre, tras push a `origin/main`.
Historia lineal, sin force-push (GDD §3.2).

---

## 8. Equipo de agentes

| Agente | Rol | Estado | Definición |
|---|---|---|---|
| AG-0 | Coordinator (chat principal) | ✅ activo | `C:\Proyectos\TSB\agents\AG-0.md` |
| AG-REA | Reverse Engineer (alcance §3) | ✅ Fase 0 completada; no se reactiva salvo petición | `agents\AG-REA.md` |
| AG-1 | Historian/Data | ✅ Fase 0 completada; vuelve en Fase 3 (escenarios 2-3) | `agents\AG-1.md` |
| AG-2 | Systems Dev | ✅ scaffold completado; Fase 1 (sistemas núcleo) | `agents\AG-2.md` |
| AG-4 | QA | ✅ Fase 0 aprobada; continúa en Fase 1 | `agents\AG-4.md` |
| AG-3 | UI Dev | ⏸ no activado aún (Fase 1) | pendiente de crear MD al activar |
| AG-5 | Art Pipeline | ⏸ no activado (Fase 3) | pendiente de crear MD al activar |

---

## 9. Decisiones registradas

`docs/decisions.md`: D-001 base del repo · D-002 paralelización Fase 0 · D-003 autoría informe REA ·
D-004 validador GDScript (subconjunto JSON Schema) · D-005 git centralizado en AG-0 · D-006 criterio
de "compila" · D-007 GDD en repo · D-008 alcance de datos 1337 · D-009 envelope de datasets ·
D-010 capital dual Praga · D-011 nomenclatura de casas · D-012 anexo técnico REA · D-013 CI local y
GitHub Actions diferido · D-014 registro de QA por fase.

---

## 10. Bloqueos y riesgos

- **Bloqueos:** ninguno.
- Riesgo residual (bajo): el volumen de datos crece al añadir 1402/1453 (Fase 3) → el envelope
  `schema_version` y `validate_data.gd` ya soportan múltiples escenarios.
- Riesgo residual (bajo): `run/main_scene` vacío hasta Fase 1 (D-006); `godot --headless` sin `--script`
  no arranca partida, la CI usa `tests/run_all.gd`.
- Sin acceso a la carpeta GK2 por parte de AG-1/AG-2/AG-4 (regla §3.1.2 respetada y verificada por QA).

---

## 11. Próximos pasos — Fase 1 (MVP jugable, §12)

1. **AG-2:** sistemas núcleo — `turn_manager` (loop trimestre/año + PG), `economy_system`,
   `dynasty_system` (nacimientos/educación/sucesión/matrimonios), `diplomacia` (7 acciones),
   `battle_manager.resolve_delegated`, `ai_manager` (13 rivales <2 s), save/load `save_version=1`.
2. **AG-3:** UI de §9 consumiendo solo contratos §8.2 (mapa de regiones, consejo, familia,
   diplomacia, informe de batalla, fin de año, victoria/derrota), placeholders de arte.
3. **AG-4:** QA continuo: partida simulada headless de Inglaterra 1337, determinismo de save,
   Peste Negra 1348, presupuesto de IA <2 s, regresión de datos.
4. **AG-0:** revisión de diffs, `STATUS.md`/`decisions.md`, commits `[AG-N]` y push por módulo;
   tag `fase-1` al cumplir los criterios jugables de §12.
5. **Pendiente del usuario:** luz verde para iniciar Fase 1.

---

## 12. Verificación de Kimi (protocolo §3.2)

- ¿Existen los entregables de Fase 0 y cumplen §12? → sí (tabla §3 de este documento).
- ¿`validate_data.gd` y headless pasan con logs? → sí; logs íntegros en `docs/issues.md` §2 y aquí §5.
- ¿Contratos §8.2 y UI sin mutar estado? → scaffold con contratos declarados; UI no existe aún (Fase 1).
- ¿Cumplimiento legal (sin material Koei/terceros)? → datos 100% originales con fuentes abiertas;
  informe REA limitado a estructura, sin nombres/textos del juego ni análisis de `.EXE` (§3).
- Resultado esperado: **APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO**; hallazgos se corrigen
  antes de continuar (§3.2.5).

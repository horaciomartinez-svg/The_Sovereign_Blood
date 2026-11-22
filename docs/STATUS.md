# Estado del proyecto — The Sovereign's Blood

| Campo | Valor |
|---|---|
| **Fase actual** | Fase 0 — Cimientos (en curso) |
| **GDD** | v1.2 (raíz del repo) |
| **Coordinador** | AG-0 |
| **Repo** | https://github.com/horaciomartinez-svg/The_Sovereign_Blood (rama `main`) |
| **Última actualización** | 2026-11-21 (Fase 0, arranque) |

---

## 1. Entorno verificado

| Elemento | Resultado |
|---|---|
| Workspace `C:\Proyectos\TSB` | OK — contiene GDD maestro y carpeta GK2 |
| GDD maestro | `GDD_The_Sovereign's_Blood.md` — 44.341 bytes, 664 líneas, v1.2 — leído completo |
| Referencia GK2 (solo lectura, solo AG-REA) | OK — 35 archivos: `GENDATA1-4.DAT`, `ZNAME.DAT`, `MAPDATA.DAT`, `SCENARIO.GK2`, `SAVEDATA.GK2`, `HEXKG.DAT`, `HEXSG.DAT`, etc. |
| Godot editor | `C:\Godot\Godot_v4.7.2-stable_win64.exe` — 4.7.2.stable.official.ed1daf0bf |
| Godot consola/CI | `C:\Godot\Godot_v4.7.2-stable_win64_console.exe` — OK |
| Git | 2.56.0.windows.1; identidad `horaciomartinez-svg <horacio.martinez@cedconsultoria.com>` |
| Repo remoto | Existente con historial previo (README + initial commit). Base local creada por clon, sin force-push |
| Push remoto | Credenciales OK (test `git push --dry-run` → "Everything up-to-date") |
| `rea-mcp` | Disponible (herramientas de inspección binaria y entropía) |
| `godot-mcp` | Disponible para Fase 1 (AG-2/AG-3) |

---

## 2. Fase 0 — Criterios de aceptación (Sección 12)

| # | Criterio | Estado | Evidencia |
|---|---|---|---|
| A1 | `docs/rea/gk2_data_lessons.md` producido (≤2 páginas) | ⏳ En curso | AG-REA |
| A2 | Datasets del Escenario 1 con schemas, validados | ⏳ En curso | AG-1 |
| A3 | Repo Godot compilando, autoloads vacíos, CI headless corriendo | ⏳ En curso | AG-2 |
| A4 | `tools/validate_data.gd` → 0 errores | ⏳ Pendiente | AG-4 |
| A5 | `godot --headless` arranca sin errores críticos | ⏳ Pendiente | AG-2/AG-4 |
| A6 | Informe REA ≤ 2 páginas | ⏳ En curso | AG-REA |

---

## 3. Entregables de Fase 0

| Entregable | Owner | Ruta | Estado |
|---|---|---|---|
| Estructura de repo + `project.godot` + Git remoto | AG-0 | raíz repo | ✅ Hecho |
| GDD en raíz del repo | AG-0 | `GDD_The_Sovereign's_Blood.md` | ✅ Hecho |
| Este documento | AG-0 | `docs/STATUS.md` | ✅ Inicial |
| Registro de decisiones | AG-0 | `docs/decisions.md` | ✅ Inicial |
| Definiciones de agentes | AG-0 | `C:\Proyectos\TSB\agents\*.md` | ✅ Hecho |
| Informe REA GK2 | AG-REA | `docs/rea/gk2_data_lessons.md` | ⏳ En curso |
| Datasets Escenario 1 (1337) | AG-1 | `data/**` | ⏳ En curso |
| Scaffold Godot + CI headless | AG-2 | `scripts/`, `tests/`, `tools/` | ⏳ En curso |
| Validación QA Fase 0 | AG-4 | `docs/issues.md`, logs | ⏳ Pendiente |

---

## 4. Commits / tags

| Fecha | Commit | Descripción |
|---|---|---|
| — | — | Aún sin push |

---

## 5. Bloqueos y riesgos

- Sin bloqueos de entorno.
- Riesgo: volumen de datos históricos de 14 facciones → mitigado con `"estimate": true` y `source` obligatorio.
- Riesgo: validación JSON Schema sin dependencias externas → `validate_data.gd` implementará el subconjunto usado por los schemas (decisión D-004).

---

## 6. Próximos pasos

1. Cerrar informes paralelos: AG-REA (A1/A6), AG-2 (A3), AG-1 (A2).
2. Activar AG-4 al terminar AG-1/AG-2; ejecutar `validate_data.gd` y `tests/run_all.gd` headless (A4/A5).
3. Revisión de AG-0 contra criterios; tag `fase-0` y push de cierre si todo pasa.

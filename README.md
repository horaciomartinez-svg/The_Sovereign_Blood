# The Sovereign's Blood

Gran estrategia por turnos ambientada en la Guerra de los Cien Años y el ascenso de los estados dinásticos (1337–1453). Inspirado estructuralmente en los clásicos de Koei de la década de 1990, con contenido 100% original: datos, nombres, arte y código propios.

- **Motor:** Godot 4.7 (GDScript)
- **Desarrollo:** equipo multi-agente con DeepSeek Harness (DSH + deepseek-flash), supervisado por el autor y verificado por Kimi al cierre de cada módulo
- **Licencia:** código y datos de este repo, MIT. Proyecto personal, sin fines comerciales.

## Estructura

| Ruta | Contenido |
|---|---|
| `GDD_The_Sovereign's_Blood.md` | Game Design Document maestro (v1.2) — especificación vinculante para el equipo de agentes |
| `sovereigns-blood/` | Proyecto Godot (código, escenas, datos JSON, tests) — creado en Fase 0 |
| `agents/` | Definiciones (prompts) de los agentes DSH |
| `docs/` | STATUS, decisions, issues, informe REA |

## Flujo de trabajo

Desarrollo por fases (0–3) definidas en el GDD, Sección 12. Cada módulo cierra con push a `main`, `docs/STATUS.md` actualizado y —al completar fase— un tag (`fase-0` … `fase-3`). La verificación de cumplimiento del GDD la realiza Kimi revisando este repo.

## Aviso legal

Este proyecto es un homenaje no comercial a los juegos de estrategia clásicos. No contiene material de Koei Tecmo ni de ningún tercero. Todo el contenido histórico se obtiene de fuentes abiertas (Wikidata, Wikipedia, mapas históricos de dominio público), citadas en `data/sources.md`.

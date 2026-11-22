extends RefCounted
## D-072: acceso al Manual del Jugador desde la UI. El texto vive en el
## documento del repositorio; la UI no lo duplica ni lo hardcodea.

const MANUAL_RES := "res://docs/MANUAL_DEL_JUGADOR.md"

const SUMMARY := [
	"1. La fantasía: gobiernas una dinastía, no solo un ejército.",
	"2. Victoria y derrota: prestigio mantenido, conquista, supervivencia, extinción o pérdida total.",
	"3. Turnos y PG: cuatro trimestres por año; cada orden consume Puntos de Gobierno.",
	"4. Economía: regiones, trabajadores, edificios, apoyo y mercancías; el mercado exige comerciantes.",
	"5. Familia: matrimonios, herederos, educación, consorte y sucesión.",
	"6. Diplomacia: alianzas, pactos, treguas, tributos, guerra y espionaje.",
	"7. Militar: reclutar/entrenar, mantenimiento y los tres niveles de batalla.",
	"8. IA, dificultades y eventos históricos del escenario 1337.",
	"9. Consejos para cada una de las 8 facciones jugables.",
	"10. Glosario de términos y recursos.",
]


static func manual_path() -> String:
	return ProjectSettings.globalize_path(MANUAL_RES)


static func manual_exists() -> bool:
	return FileAccess.file_exists(MANUAL_RES)


static func open_manual() -> bool:
	if not manual_exists():
		return false
	return OS.shell_open(manual_path()) == OK


static func fallback_message() -> String:
	return "No se pudo abrir el Manual del Jugador. Está en docs/MANUAL_DEL_JUGADOR.md del proyecto."

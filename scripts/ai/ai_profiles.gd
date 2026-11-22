extends RefCounted
## Perfiles de IA (GDD §5.6) y sus pesos de utilidad esperada.
##
## Utilidad(acción) = Σ peso_perfil × (oro, territorio, seguridad dinástica,
## prestigio) − coste_PG − riesgo_estimado. Los pesos viven aquí para que el
## balance se ajuste en un solo sitio.

const ALL_PROFILES: Array[String] = ["aggressor", "merchant", "dynastic", "survivor", "balanced"]

const PROFILES: Dictionary = {
	"aggressor": {"gold": 0.4, "territory": 1.3, "security": 0.5, "prestige": 0.8},
	"merchant": {"gold": 1.3, "territory": 0.3, "security": 0.6, "prestige": 0.5},
	"dynastic": {"gold": 0.7, "territory": 0.5, "security": 1.2, "prestige": 0.9},
	"survivor": {"gold": 0.8, "territory": 0.2, "security": 1.3, "prestige": 0.4},
	"balanced": {"gold": 0.8, "territory": 0.8, "security": 0.8, "prestige": 0.8},
}


static func weights(profile: String) -> Dictionary:
	var found: Dictionary = PROFILES.get(profile, {})
	if found.is_empty():
		var fallback: Dictionary = PROFILES.get("balanced", {})
		return fallback
	return found


static func is_valid(profile: String) -> bool:
	return ALL_PROFILES.has(profile)

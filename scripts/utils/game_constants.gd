extends RefCounted
## Constantes de diseño de la simulación (Fase 1).
##
## Único lugar donde viven los números de diseño que no están en `data/`.
## GDD §5 (economía, dinastía, diplomacia), §5.1 (PG), §6.1 (batalla) y
## contrato de Fase 1 §4/§5. Si un valor cambia, se cambia aquí y se documenta.

# --- Economía (§5.2) ---
## Habitantes representados por una unidad de mano de obra.
const WORKER_POPULATION_PER_UNIT: int = 200
const SUPPORT_DEFAULT: int = 60
const SUPPORT_MIN: int = 0
const SUPPORT_MAX: int = 100
const TAX_RATE_DEFAULT: float = 0.5
## Reparto inicial de la mano de obra (% de unidades de trabajo por clase).
const WORKER_INITIAL_SPLIT: Dictionary = {
	"farmers": 0.55,
	"artisans": 0.20,
	"merchants": 0.15,
	"recruits": 0.10,
}
## Producción: bienes por artesano, comercio por comerciante, comida por granjero.
const GOODS_PER_ARTISAN: float = 0.6
const COMMERCE_PER_MERCHANT: float = 0.4
const FOOD_NEED_PER_WORKER: float = 0.5
const TERRAIN_FOOD: Dictionary = {
	"plains": 1.0,
	"forest": 0.85,
	"mountain": 0.6,
	"coast": 0.9,
	"city": 0.7,
}
## Impuestos = base_wealth × tasa × población / 100 000.
const TAX_POPULATION_DIVISOR: float = 100000.0
## Mantenimiento de ejércitos: oro por trimestre por cada 200 hombres.
const ARMY_UPKEEP_PER_200_MEN: float = 2.0
## Bonus de comercio si la facción tiene pactos comerciales activos.
const TRADE_PACT_COMMERCE_BONUS: float = 0.25
## Cosecha anual (§5.2, trimestre 1): clima aleatorio sesgado.
const HARVEST_MIN: float = 0.85
const HARVEST_MAX: float = 1.15
const HARVEST_GROWTH_SUPPORT: int = 80
const HARVEST_FAMINE_SUPPORT: int = 20
const HARVEST_GROWTH_RATE: float = 0.01
const HARVEST_FAMINE_RATE: float = 0.02
## Revuelta: apoyo < 20 (GDD §5.2).
const REVOLT_SUPPORT_THRESHOLD: int = 20
const REVOLT_CHANCE: float = 0.35
const REVOLT_SUPPORT_RESET: int = 30
const REVOLT_GOLD_LOSS: int = 100
const REVOLT_PRESTIGE_LOSS: int = 5
## allocate() cuesta 1 PG por orden.
const ALLOCATE_PG_COST: int = 1
## Coste de PG base de una orden de movimiento.
const MOVE_PG_COST: int = 1
const TERRAIN_MOVE_PENALTY: Dictionary = {
	"plains": 0,
	"coast": 0,
	"forest": 1,
	"mountain": 2,
	"city": 0,
}

# --- Turno y Puntos de Gobernanza (§5.1) ---
const QUARTERS_PER_YEAR: int = 4
const PG_BASE: int = 30
const PG_MAX: int = 120
## Penalización de PG por apoyo bajo (<30): puntos por región descontenta.
const PG_UNREST_PENALTY_PER_REGION: int = 2
const PG_UNREST_SUPPORT_THRESHOLD: int = 30
const PG_REGENCY_PENALTY: int = 3

# --- Dinastía (§5.3) ---
const BIRTH_CHANCE: float = 0.12
const FERTILE_AGE: int = 40
const MARRIAGE_MIN_AGE: int = 14
const DISEASE_CHANCE: float = 0.02
const DISEASE_AGE: int = 50
const BATTLE_DEATH_CHANCE: float = 0.15
const REGENCY_AGE: int = 14
const INTERREGNUM_YEARS: int = 2
const CRISIS_PRESTIGE_LOSS: int = 50
const EDUCATION_PG_COST: int = 1
const EDUCATION_MIN_AGE: int = 6
const EDUCATION_MAX_AGE: int = 16
const EDUCATION_STAT_GAIN: int = 1

# --- Diplomacia (§5.4) ---
const RELATION_MIN: int = -100
const RELATION_MAX: int = 100
const WAR_WITHOUT_CASUS_BELLI_PRESTIGE_LOSS: int = 25
const PEACE_RELATION_BONUS: int = 10
const ALLIANCE_RELATION_BONUS: int = 10
const MARRIAGE_RELATION_BONUS: int = 20
const TRADE_PACT_RELATION_BONUS: int = 5
const TRIBUTE_RELATION_BONUS: int = 15
const TRIBUTE_GOLD: int = 300
const DEMAND_TRIBUTE_GOLD: int = 500
const ACTION_PG_COSTS: Dictionary = {
	"alliance": 8,
	"marriage": 10,
	"trade_pact": 6,
	"demand_tribute": 5,
	"offer_tribute": 3,
	"declare_war": 0,
	"propose_peace": 4,
}

# --- Militar (§5.5, §7.4) ---
const ARMY_BASE_SLOTS_PER_REGION: int = 1
const ARMY_SLOT_CASTLE: int = 1
const ARMY_SLOT_WALLS: int = 1
## Los costes de unidad de units.json son por bloque de 200 hombres.
const UNIT_MEN_PER_BLOCK: int = 200
const SOLDIER_WAGE_GOLD: float = 0.0

# --- Batalla (§6.1) ---
const MAX_ASSAULTS: int = 5
const RETREAT_THRESHOLD: float = 0.25
const MORALE_BREAK: float = 0.3
const STANCE_OFFENSIVE: int = 2
const STANCE_BALANCED: int = 1
const STANCE_DEFENSIVE: int = 0
const STANCE_OFFENSIVE_COEF: float = 1.15
const STANCE_BALANCED_COEF: float = 1.0
const STANCE_DEFENSIVE_COEF: float = 0.85
const BATTLE_LOSS_COEF: float = 0.35
const BATTLE_MAX_LOSS_FRACTION: float = 0.45
const BATTLE_MORALE_LOSS_COEF: float = 0.5
const BATTLE_MIN_MORALE: float = 0.1
const BATTLE_COMMANDER_STAT_BASE: int = 50
const BATTLE_COMMANDER_STAT_RANGE: float = 200.0
const TERRAIN_DEFENSE: Dictionary = {
	"plains": 1.0,
	"forest": 1.15,
	"mountain": 1.3,
	"coast": 1.1,
	"city": 1.4,
}
const LOOT_GOLD_PER_WEALTH: int = 5
const MAX_BATTLE_REPORTS: int = 10

# --- IA (§5.6) ---
const AI_ORDER_MIN: int = 2
const AI_ORDER_MAX: int = 4
const AI_TIME_BUDGET_MS: int = 2000
const AI_RECRUIT_GOLD_MIN: int = 300
const AI_RECRUIT_MEN: int = 200

# --- Eventos (§7.6) ---
## Ámbito de un efecto de evento → facciones afectadas.
const SCOPE_FACTIONS: Dictionary = {
	"europe_west": [
		"england", "france", "castile", "aragon", "hre", "bohemia",
		"scotland", "papacy", "poland",
	],
	"europe": [
		"england", "france", "hre", "bohemia", "hungary", "castile",
		"aragon", "poland", "scotland", "papacy", "byzantium",
	],
	"balkans": ["hungary", "byzantium"],
	"italy": ["papacy", "hre", "aragon"],
	"iberia": ["castile", "aragon", "granada"],
}

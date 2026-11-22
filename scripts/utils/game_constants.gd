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
	# D-067 (MVP-1337): montaña 0.70 + bonus de apoyo evita la espiral de
	# descontento en Austria/Transilvania/Croacia sin falsear el resto de datos.
	"mountain": 0.7,
	"coast": 0.9,
	"city": 0.7,
}
## D-067: compensación de apoyo en regiones de montaña (subsistencia tradicional).
const SUPPORT_MOUNTAIN_BONUS: int = 3
## Impuestos = base_wealth × tasa × población / 100 000.
const TAX_POPULATION_DIVISOR: float = 100000.0
## Mantenimiento de ejércitos: oro por trimestre por cada 200 hombres.
const ARMY_UPKEEP_PER_200_MEN: float = 20.0
## D-067: gastos de corte progresivos para evitar inflación pasiva trivial.
## A partir de `TREASURY_SOFT_CAP` el exceso paga `TREASURY_OVERHEAD_RATE` por
## trimestre (dinero que el jugador debe gastar/reclutar para no acumularlo).
const TREASURY_SOFT_CAP: int = 8000
const TREASURY_OVERHEAD_RATE: float = 0.35
## D-067: mortalidad dinástica de la Peste Negra (una parte de la casa, no el
## gobernante ni el heredero, para no romper la sucesión jugable).
const PLAGUE_MORTALITY_CHANCE: float = 0.20

# --- Fase 4: comercio y ejércitos (D-069/D-070) ---
## Volumen máximo por comerciante asignado en cada compra/venta/expedición.
const TRADE_VOLUME_PER_MERCHANT: int = 5
const EXPEDITION_PG_COST: int = 2
const EXPEDITION_RETURN_TURNS: int = 2
const EXPEDITION_PROFIT_FACTOR: float = 1.2
## Entrenamiento: oro por bloque de 200 hombres + 1 PG; tope de experiencia.
const TRAIN_GOLD_PER_BLOCK: int = 10
const TRAIN_ARMY_GOLD: int = 50
const TRAIN_EXP_MAX: int = 100
const TRAIN_EXP_PER_ACTION: int = 10
const DISBAND_REFUND_RATIO: float = 0.5
## Stock inicial de mercancías por facción (permite el primer reclutamiento
## antes de la primera producción trimestral; se documenta en el informe D-069).
const TRADE_INITIAL_STOCK: int = 20
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

# --- Batalla Nivel 2 — mapa táctico (§6.2) ---
const TACTICAL_RADIUS: int = 4
const TACTICAL_RADIUS_CITY: int = 5
const TACTICAL_MAX_ROUNDS: int = 8
const TACTICAL_DEFAULT_MOVES: int = 2
const TACTICAL_MAX_MOVES: int = 3
const TACTICAL_RANGED_RANGE: int = 2
const TACTICAL_RANGED_PENALTY: float = 0.7
const TACTICAL_MOVE_COST: Dictionary = {
	"plains": 1,
	"forest": 2,
	"hills": 2,
	"river": 2,
	"city": 1,
}
const TACTICAL_DEFENSE_TERRAIN: Dictionary = {
	"plains": 1.0,
	"forest": 1.15,
	"hills": 1.2,
	"river": 1.25,
	"city": 1.4,
}
const TACTICAL_OBJECTIVE_CITY_VALUE: int = 3
const TACTICAL_OBJECTIVE_BRIDGE_VALUE: int = 2
const TACTICAL_OBJECTIVE_REAR_VALUE: int = 2

# --- Batalla Nivel 3 — combate cerrado (§6.3) ---
const CLOSE_COMBAT_CARDS: Array[String] = ["carga", "disparo", "formacion", "finta", "retirada"]
const CLOSE_COMBAT_HAND_BASE: int = 2
const CLOSE_COMBAT_HAND_BONUS: int = 1
const CLOSE_COMBAT_MAX_ROUNDS: int = 6
const CLOSE_COMBAT_CHARGE_VS_INFANTRY: float = 1.4
const CLOSE_COMBAT_CHARGE_VS_FORMATION: float = 0.6
const CLOSE_COMBAT_FORMATION_DAMAGE_REDUCTION: float = 0.5
const CLOSE_COMBAT_FAINT_DAMAGE_REDUCTION: float = 0.3
const CLOSE_COMBAT_RETREAT_LOSS_REDUCTION: float = 0.5
const CLOSE_COMBAT_SHOT_PRE_DAMAGE: float = 0.35
const CLOSE_COMBAT_RETREAT_THRESHOLD: float = 0.4
const CLOSE_COMBAT_MORALE_BREAK: float = 0.2

# --- Espionaje (§5.4, D-030) ---
const ESPIONAGE_PG_COST: int = 6
const ESPIONAGE_BASE_CHANCE: float = 0.35
const ESPIONAGE_INTRIGUE_DIVISOR: float = 200.0
const ESPIONAGE_RELATION_DIVISOR: float = 400.0
const ESPIONAGE_MIN_CHANCE: float = 0.15
const ESPIONAGE_MAX_CHANCE: float = 0.9

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

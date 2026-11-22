extends RefCounted
## Paleta y estilos base de The Sovereign's Blood (GDD §10).
##
## Direccion visual: "manuscrito iluminado + mapa de epoca". Azul tinta, ocre
## pergamino, dorado y rojo grana. Todo es generado por codigo: sin assets.
##
## Este script es puramente de presentacion (no conoce el estado de la partida).

const INK_DEEP := Color("0d1622")
const INK := Color("16243a")
const INK_SOFT := Color("1f3350")
const SEA := Color("24415f")
const SEA_DEEP := Color("19304a")
const PARCHMENT := Color("e9daba")
const PARCHMENT_LIGHT := Color("f5ead0")
const PARCHMENT_DARK := Color("cbb78c")
const PARCHMENT_SHADE := Color("b9a274")
const GOLD := Color("c9a227")
const GOLD_BRIGHT := Color("e8cf74")
const GOLD_DIM := Color("8a6f2a")
const GOLD_FAINT := Color(0.79, 0.64, 0.15, 0.35)
const CRIMSON := Color("7f1f26")
const CRIMSON_BRIGHT := Color("b03a44")
const GREEN := Color("3f6b3a")
const GREEN_BRIGHT := Color("6f9a5f")
const INK_TEXT := Color("2a2114")
const MUTED := Color("a99a78")
const DISABLED_TEXT := Color("6f6552")
const SHADOW := Color(0.0, 0.0, 0.0, 0.45)
const SEA_GRID := Color(0.55, 0.65, 0.72, 0.10)
const LAND := Color("b8a67e")
const LAND_DARK := Color("9c8a63")
const LAND_LIGHT := Color("cbb98f")

## Terreno -> tinte para el borde/relleno secundario de la region.
const TERRAIN_TINTS := {
	"plains": Color("8a9a52"),
	"forest": Color("4a6b3a"),
	"mountain": Color("7c7468"),
	"coast": Color("4a7f96"),
	"city": Color("a8894a"),
}


static func with_alpha(color: Color, alpha: float) -> Color:
	var out := color
	out.a = clampf(alpha, 0.0, 1.0)
	return out


## Crea un StyleBoxFlat listo para usar.
static func stylebox(
		bg: Color,
		border: Color = Color.TRANSPARENT,
		border_width: int = 1,
		radius: int = 4,
		margin_x: int = 0,
		margin_y: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = float(margin_x)
	box.content_margin_right = float(margin_x)
	box.content_margin_top = float(margin_y)
	box.content_margin_bottom = float(margin_y)
	box.anti_aliasing = true
	return box


## Fondo de panel pergamino con doble filete (estilo iluminado).
static func parchment_style(margin: int = 16, bordered: bool = true) -> StyleBoxFlat:
	var box := stylebox(PARCHMENT, GOLD_DIM, 2 if bordered else 0, 6, margin, margin)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 4)
	return box


## Fondo de panel tinta (pantallas oscuras y barras laterales).
static func ink_style(margin: int = 12, border_color: Color = GOLD_DIM, border_width: int = 1) -> StyleBoxFlat:
	var box := stylebox(INK, border_color, border_width, 4, margin, margin)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	return box


static func inset_style(margin: int = 10, bg: Color = INK_SOFT) -> StyleBoxFlat:
	return stylebox(bg, GOLD_FAINT, 1, 3, margin, margin)


## Color de una relacion -100..100 (grana -> ocre -> verde).
static func relation_color(value: int) -> Color:
	var t := clampf((float(value) + 100.0) / 200.0, 0.0, 1.0)
	if t < 0.5:
		return CRIMSON_BRIGHT.lerp(MUTED, t * 2.0)
	return MUTED.lerp(GREEN_BRIGHT, (t - 0.5) * 2.0)


## Color de apoyo popular 0..100 (revuelta -> estabilidad).
static func support_color(value: int) -> Color:
	var t := clampf(float(value) / 100.0, 0.0, 1.0)
	if t < 0.5:
		return CRIMSON_BRIGHT.lerp(GOLD, t * 2.0)
	return GOLD.lerp(GREEN_BRIGHT, (t - 0.5) * 2.0)


static func terrain_tint(terrain: String) -> Color:
	return TERRAIN_TINTS.get(terrain, MUTED)


## Deriva un segundo color estable a partir de un texto (casas/heraldica).
static func derived_color(seed_text: String, base: Color) -> Color:
	var h := absi(hash(seed_text))
	var r := float((h >> 8) & 0xFF) / 255.0
	var g := float((h >> 16) & 0xFF) / 255.0
	var b := float(h & 0xFF) / 255.0
	var tint := Color(r, g, b)
	return base.lerp(tint, 0.42).darkened(0.08)


## Metal heraldico estable: oro, plata o cobre segun la casa.
static func heraldic_metal(seed_text: String) -> Color:
	var metals: Array[Color] = [Color("e8cf74"), Color("e6e2d3"), Color("c98f4a")]
	var h := absi(hash(seed_text))
	return metals[h % metals.size()]


static func short_number(value: int) -> String:
	if absi(value) >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if absi(value) >= 10000:
		return "%.1fk" % (float(value) / 1000.0)
	return str(value)


static func signed_number(value: int) -> String:
	return ("+" if value > 0 else "") + str(value)

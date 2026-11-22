# gen_map_layout.ps1 — Genera data/map_layout.json (D-017: solo presentación).
# Coordenadas normalizadas 0..1 relativas al área del mapa (entre barras laterales).
# Uso: pwsh -File scripts/ui/dev/gen_map_layout.ps1
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$outPath = Join-Path $repo "data\map_layout.json"

# id => @(lon, lat, short label)
$geo = [ordered]@{
    "region_londres"              = @(0.0,   51.5, "Londres")
    "region_inglaterra_sur"       = @(-1.5,  51.0, "Ingl. Sur")
    "region_inglaterra_norte"     = @(-2.0,  54.0, "Ingl. Norte")
    "region_aquitania"            = @(-0.5,  44.5, "Aquitania")
    "region_ile_de_france"        = @(2.3,   48.8, "Isla Francia")
    "region_normandia"            = @(0.2,   49.2, "Normandia")
    "region_flandes"              = @(3.5,   51.0, "Flandes")
    "region_bretana"              = @(-3.0,  48.0, "Bretana")
    "region_borgona"              = @(4.5,   47.0, "Borgona")
    "region_languedoc"            = @(3.5,   44.0, "Languedoc")
    "region_avignon"              = @(4.8,   44.0, "Avignon")
    "region_baviera"              = @(11.5,  48.5, "Baviera")
    "region_franconia"            = @(10.5,  49.5, "Franconia")
    "region_renania"              = @(7.5,   50.0, "Renania")
    "region_lorena"               = @(6.0,   48.7, "Lorena")
    "region_austria"              = @(15.0,  47.5, "Austria")
    "region_praga"                = @(14.4,  50.0, "Praga")
    "region_moravia"              = @(17.0,  49.0, "Moravia")
    "region_buda"                 = @(19.0,  47.5, "Buda")
    "region_transilvania"         = @(23.5,  46.5, "Transilv.")
    "region_croacia"              = @(16.0,  45.5, "Croacia")
    "region_burgos"               = @(-3.7,  42.3, "Burgos")
    "region_toledo"               = @(-4.0,  39.8, "Toledo")
    "region_sevilla"              = @(-5.9,  37.4, "Sevilla")
    "region_barcelona"            = @(2.2,   41.5, "Barcelona")
    "region_valencia"             = @(-0.4,  39.5, "Valencia")
    "region_sicilia"              = @(14.0,  37.5, "Sicilia")
    "region_granada"              = @(-3.6,  37.2, "Granada")
    "region_malaga"               = @(-4.4,  36.7, "Malaga")
    "region_cracovia"             = @(19.9,  50.0, "Cracovia")
    "region_gran_polonia"         = @(17.0,  52.3, "G. Polonia")
    "region_edimburgo"            = @(-3.2,  56.0, "Edimburgo")
    "region_escocia_occidental"   = @(-5.5,  57.0, "Escocia O.")
    "region_roma"                 = @(12.5,  41.9, "Roma")
    "region_napoles"              = @(14.3,  40.8, "Napoles")
    "region_lombardia"            = @(9.5,   45.5, "Lombardia")
    "region_toscana"              = @(11.2,  43.7, "Toscana")
    "region_el_cairo"             = @(31.2,  30.05, "El Cairo")
    "region_alejandria"           = @(29.9,  31.2, "Alejandria")
    "region_barqa"                = @(20.0,  32.1, "Cirenaica")
    "region_damasco"              = @(36.3,  33.5, "Damasco")
    "region_jerusalen"            = @(35.2,  31.8, "Jerusalen")
    "region_constantinopla"       = @(28.9,  41.0, "Constantin.")
    "region_tesalonica"           = @(22.9,  40.6, "Tesalonica")
    "region_anatolia_occidental"  = @(29.5,  39.0, "Anatolia")
    "region_sarai"                = @(47.5,  47.5, "Sarai")
    "region_crimea"               = @(34.0,  45.0, "Crimea")
}

# Malla hexagonal de presentación: columnas/filas con offset (como un mapa de hexes).
$sx = 0.064      # separación de columnas (normalizada al ancho del mapa)
$sy = 0.078      # separación de filas (normalizada al alto del mapa)
$baseX = 0.05
$baseY = 0.05
$cols = 14
$rows = 12
$rx = 0.0295     # radio horizontal del hex (normalizado)
$ry = 0.0335     # radio vertical del hex (normalizado)

$cellPos = {
    param($col, $row)
    $x = $baseX + $col * $sx + (($row % 2) * ($sx / 2.0))
    $y = $baseY + $row * $sy
    return @($x, $y)
}

# Posición geográfica ideal -> celda de malla más cercana, resolviendo colisiones.
$regions = [ordered]@{}
$used = @{}
$order = $geo.Keys | Sort-Object { $g = $geo[$_]; (58.0 - $g[1]) } # norte -> sur
foreach ($id in $order) {
    $g = $geo[$id]
    $lon = [double]$g[0]; $lat = [double]$g[1]
    $ix = 0.06 + (($lon + 10.0) / 60.0) * 0.88
    $iy = 0.06 + ((58.0 - $lat) / 28.0) * 0.84
    $best = $null; $bestD = [double]::MaxValue
    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            $key = "$c,$r"
            if ($used.ContainsKey($key)) { continue }
            $p = & $cellPos $c $r
            $dx = ($p[0] - $ix) * 1.35   # peso: el ancho útil es mayor que el alto
            $dy = ($p[1] - $iy)
            $d = $dx * $dx + $dy * $dy
            if ($d -lt $bestD) { $bestD = $d; $best = @($c, $r, $p[0], $p[1]) }
        }
    }
    if ($null -eq $best) { throw "Sin celda libre para $id" }
    $used["$($best[0]),$($best[1])"] = $true
    $regions[$id] = [ordered]@{
        x     = [math]::Round($best[2], 4)
        y     = [math]::Round($best[3], 4)
        r     = @(0.0295, 0.0335)
        label = $g[2]
    }
}

# Siluetas de presentación (trazos gruesos, no cartografía real): continente,
# islas británicas, Escandinavia y Norte de África ya incluido en el continente.
$landmasses = @(
    @(
        @(-0.03,0.66),@(-0.02,0.55),@(0.02,0.48),@(0.05,0.40),@(0.10,0.34),
        @(0.14,0.27),@(0.20,0.22),@(0.25,0.16),@(0.30,0.13),@(0.34,0.17),
        @(0.38,0.24),@(0.42,0.22),@(0.46,0.19),@(0.51,0.17),@(0.56,0.20),
        @(0.60,0.24),@(0.64,0.21),@(0.69,0.25),@(0.75,0.22),@(0.82,0.27),
        @(0.87,0.33),@(0.90,0.42),@(0.88,0.50),@(0.86,0.57),@(0.83,0.62),
        @(0.80,0.68),@(0.77,0.75),@(0.73,0.83),@(0.70,0.88),@(0.64,0.90),
        @(0.58,0.88),@(0.52,0.86),@(0.46,0.88),@(0.40,0.87),@(0.34,0.84),
        @(0.28,0.80),@(0.23,0.74),@(0.18,0.66),@(0.14,0.60),@(0.10,0.63),
        @(0.07,0.68),@(0.03,0.70),@(-0.03,0.66)
    ),
    @(
        @(0.12,0.14),@(0.16,0.08),@(0.20,0.10),@(0.22,0.16),@(0.24,0.22),
        @(0.27,0.28),@(0.25,0.33),@(0.21,0.32),@(0.18,0.27),@(0.16,0.22),
        @(0.13,0.19),@(0.12,0.14)
    ),
    @(
        @(0.06,0.14),@(0.09,0.18),@(0.10,0.24),@(0.07,0.27),@(0.04,0.23),
        @(0.04,0.18),@(0.06,0.14)
    ),
    @(
        @(0.40,0.06),@(0.47,0.05),@(0.52,0.09),@(0.53,0.15),@(0.48,0.17),
        @(0.42,0.14),@(0.39,0.10),@(0.40,0.06)
    )
)

$layout = [ordered]@{
    schema      = "tsb.map_layout/1"
    description = "Coordenadas normalizadas por region_id para el mapa principal. SOLO PRESENTACION (D-017): no es estado de simulacion ni dato historico."
    canvas      = [ordered]@{
        width   = 1920
        height  = 1080
        note    = "x/y normalizados 0..1 relativos al area central del mapa; r = radios del hexagono en unidades normalizadas (x, y)."
    }
    regions     = $regions
    landmasses  = $landmasses
}

$json = $layout | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($outPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("Escrito {0} ({1} regiones)" -f $outPath, $regions.Count)

#!/usr/bin/env pwsh
<#
.SYNOPSIS
  CI headless de The Sovereign's Blood (Fase 0, criterios A3/A4/A5).

.DESCRIPTION
  Ejecuta los tres comandos obligatorios de la CI headless:
    1. Importacion del proyecto Godot -> --headless --editor --quit
    2. Validacion de datos seccion 13 -> --script tools/validate_data.gd
    3. Suite de tests + datos         -> --script tests/run_all.gd
  Devuelve exit code 0 solo si los tres pasan. Anade timeout para evitar que un
  script roto deje la CI colgada.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File tools/ci_headless.ps1
  pwsh -File tools/ci_headless.ps1 -GodotPath "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"

.NOTES
  Godot 4.7.2 stable. Sin dependencias externas. ASCII-only y sin Start-Process
  -PassThru (PowerShell 5.1 no expone ExitCode): funciona en PS 5.1 y PS 7.
#>
param(
    [string]$GodotPath = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe",
    [string]$ProjectPath = "",
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $ProjectPath = Split-Path -Parent $PSScriptRoot
}
$ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path

if (-not (Test-Path -LiteralPath $GodotPath)) {
    Write-Host "[FAIL] No existe el ejecutable de Godot: $GodotPath"
    exit 2
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
    Write-Host "[FAIL] No se encontro project.godot en: $ProjectPath"
    exit 2
}

function ConvertTo-QuotedArgument {
    param([string]$Value)
    if ($Value -match '[\s"]') {
        return '"' + $Value.Replace('"', '\"') + '"'
    }
    return $Value
}

function Invoke-GodotStep {
    param(
        [string]$Name,
        [string[]]$ArgList
    )

    Write-Host ""
    Write-Host "=============================================================="
    Write-Host "=== $Name"
    Write-Host "=== godot $($ArgList -join ' ')"
    Write-Host "=============================================================="

    $quotedArgs = @()
    foreach ($argument in $ArgList) {
        $quotedArgs += (ConvertTo-QuotedArgument $argument)
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $GodotPath
    $startInfo.Arguments = ($quotedArgs -join " ")
    $startInfo.WorkingDirectory = $ProjectPath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    $exited = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $exited) {
        try { $process.Kill() } catch { }
        [void]$process.WaitForExit()
    }

    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    if (-not [string]::IsNullOrEmpty($stdout)) { Write-Host $stdout }
    if (-not [string]::IsNullOrEmpty($stderr)) { Write-Host $stderr }

    if (-not $exited) {
        Write-Host "[FAIL] ${Name}: timeout tras $TimeoutSeconds s"
        return 1
    }
    Write-Host "[INFO] ${Name} -> exit code $($process.ExitCode)"
    return $process.ExitCode
}

$results = @()
$commonArgs = @("--headless", "--path", $ProjectPath)

$results += [pscustomobject]@{
    Step = "1. Importacion (--editor --quit)"
    Code = (Invoke-GodotStep "IMPORTAR PROYECTO" ($commonArgs + @("--editor", "--quit")))
}
$results += [pscustomobject]@{
    Step = "2. Validacion de datos (tools/validate_data.gd)"
    Code = (Invoke-GodotStep "VALIDAR DATOS" ($commonArgs + @("--script", "tools/validate_data.gd")))
}
$results += [pscustomobject]@{
    Step = "3. Suite headless (tests/run_all.gd)"
    Code = (Invoke-GodotStep "SUITE DE TESTS" ($commonArgs + @("--script", "tests/run_all.gd")))
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "RESUMEN CI HEADLESS"
Write-Host "=============================================================="
$failed = 0
foreach ($result in $results) {
    $status = if ($result.Code -eq 0) { "OK" } else { "FALLO" }
    Write-Host ("{0,-55} {1,4}  {2}" -f $result.Step, $result.Code, $status)
    if ($result.Code -ne 0) { $failed++ }
}

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "CI HEADLESS: FAIL ($failed paso(s) fallaron)"
    exit 1
}
Write-Host ""
Write-Host "CI HEADLESS: OK (A3/A4/A5 sin errores)"
exit 0

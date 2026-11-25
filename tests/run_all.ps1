param(
    [string]$Godot = "D:\2026-11-24-19-08-07\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
)

# Runs every headless suite and prints one summary line.
#   .\tests\run_all.ps1
#   .\tests\run_all.ps1 -Godot "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
# Exit code is 0 only when every suite reported failures=0 and none crashed.

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $Godot)) {
    $fallback = Get-Command godot -ErrorAction SilentlyContinue
    if ($fallback) {
        $Godot = $fallback.Source
    } else {
        Write-Host "Godot not found. Pass -Godot <path to godot executable>."
        exit 2
    }
}

$total = 0
$failures = 0
$broken = 0
$suites = 0

foreach ($file in Get-ChildItem "tests\test_*.gd" | Sort-Object Name) {
    $name = $file.BaseName
    $out = & $Godot --headless --path . --script "res://tests/$name.gd" 2>&1 | Out-String
    $match = [regex]::Match($out, "RESULT \S+ assertions=(\d+) failures=(\d+)")
    $suites++

    if (-not $match.Success) {
        Write-Host ("{0,-38} NO RESULT (crashed or failed to parse)" -f $name)
        $broken++
        continue
    }

    $assertions = [int]$match.Groups[1].Value
    $failed = [int]$match.Groups[2].Value
    $total += $assertions
    $failures += $failed

    if ($failed -eq 0) {
        Write-Host ("{0,-38} {1,3} ok" -f $name, $assertions)
    } else {
        Write-Host ("{0,-38} {1,3} FAIL({2})" -f $name, $assertions, $failed)
    }
}

Write-Host "-----"
Write-Host ("suites={0} assertions={1} failures={2} broken={3}" -f $suites, $total, $failures, $broken)

if ($failures -ne 0 -or $broken -ne 0) { exit 1 }
exit 0

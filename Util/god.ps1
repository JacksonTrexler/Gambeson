# god - run / debug Gambeson outside the Godot editor.   (gun = god run, gebug = god debug)
#
#   god [run]  [godot args]   run the main scene        god --scene res://Scenes/Battle.tscn
#   god debug  [godot args]   terminal debugger (-d)    god debug -b res://unit.gd:42 --debug-collisions
#   god editor                open the editor
#   god import                re-import assets / class_name cache after editing outside the editor
#   god test                  import, then run every Tests/*_test.gd headless
#
# Everything after the command goes straight to Godot (see `godot --help`); args after ++ go to the game.
# Set GODOT_BIN to use a specific Godot build (e.g. the .NET one for C#). Bash version: Util/god.

$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$root\project.godot")) { Write-Host "No project.godot in $root" -ForegroundColor Red; exit 1 }

$godot = $env:GODOT_BIN
if (-not $godot) {
    # The *_console.exe build keeps output (and the -d prompt) in this terminal.
    $godot = (Get-Command 'Godot*_console.exe', 'godot' -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1).Source
}
if (-not $godot) { Write-Host 'Godot not found on PATH; set $env:GODOT_BIN' -ForegroundColor Red; exit 1 }

$cmd = 'run'
$rest = @($args)
if ($rest.Count -and $rest[0] -notlike '-*' -and $rest[0] -ne '++') { $cmd, $rest = $rest[0], @($rest | Select-Object -Skip 1) }

# .godot/ is gitignored, so a fresh clone needs one import before assets load, and a script or asset
# added or changed outside the editor (a pull, a merge) leaves the class_name cache stale: parse errors
# like 'Could not find type "Modifiers"'. Re-import when anything is newer than the last import's stamp.
$stamp = "$root\.godot\god-import.stamp"
function Test-Stale {
    if (-not (Test-Path $stamp)) { return $true }
    $since = (Get-Item $stamp).LastWriteTime
    $skip = '\\(\.[^\\]*|docs|Util)(\\|$)'
    [bool](Get-ChildItem $root -Recurse -File -Include *.gd, *.tscn, *.tres, *.png, *.svg, project.godot |
        Where-Object { $_.FullName.Substring($root.Length) -notmatch $skip -and $_.LastWriteTime -gt $since } | Select-Object -First 1)
}
function Invoke-Import { & $godot --headless --path $root --import @args; if ($LASTEXITCODE -eq 0) { New-Item $stamp -ItemType File -Force | Out-Null } }
if ($cmd -in 'run', 'debug' -and (Test-Stale)) { Write-Host 'god: re-importing (files changed since the last import)'; Invoke-Import *> $null }

switch ($cmd) {
    'run'    { & $godot --path $root @rest }
    'debug'  { & $godot --path $root -d @rest }
    'import' { Invoke-Import @rest }
    'test'   { Invoke-Import *> $null; & $godot --headless --path $root -s res://Tests/run.gd @rest }
    'editor' { Start-Process ($godot -replace '_console', '') -ArgumentList (@('-e', '--path', "`"$root`"") + $rest); exit 0 }
    default  { Get-Content $PSCommandPath -TotalCount 10 | ForEach-Object { $_ -replace '^# ?', '' }; exit [int]($cmd -ne 'help') }
}
exit $LASTEXITCODE

# god - run / debug Gambeson outside the Godot editor.   (gun = god run, gebug = god debug)
#
#   god [run]  [godot args]   run the main scene        god --scene res://Scenes/Battle.tscn
#   god debug  [godot args]   terminal debugger (-d)    god debug -b res://unit.gd:42 --debug-collisions
#   god editor                open the editor
#   god import                re-import assets / class_name cache after editing outside the editor
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

# .godot/ is gitignored, so a fresh clone needs one import before assets load.
if ($cmd -in 'run', 'debug' -and -not (Test-Path "$root\.godot")) { & $godot --headless --path $root --import }

switch ($cmd) {
    'run'    { & $godot --path $root @rest }
    'debug'  { & $godot --path $root -d @rest }
    'import' { & $godot --headless --path $root --import @rest }
    'editor' { Start-Process ($godot -replace '_console', '') -ArgumentList (@('-e', '--path', "`"$root`"") + $rest); exit 0 }
    default  { Get-Content $PSCommandPath -TotalCount 9 | ForEach-Object { $_ -replace '^# ?', '' }; exit [int]($cmd -ne 'help') }
}
exit $LASTEXITCODE

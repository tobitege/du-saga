
$env:LUA_PATH = "$PWD/lua/?.lua;$PWD/util/?.lua;$PWD/lib/?.lua;$PWD/util/du-mocks/dumocks/?.lua"
& du-lua build release


$versionJson = Get-Content -Path "$PWD/project.json" | ConvertFrom-Json
$version = $versionJson.version
if (-not $version) {
    Write-Error "Version could not be found"
    exit
}

(Get-Content -Path "$PWD/out/release/Saga.conf" -Raw) `
    -replace "Saga Saga", "SagaHUD $version" |
    Out-File -Encoding UTF8 "$PWD/SagaHud.conf"
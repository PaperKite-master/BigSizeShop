param(
    [string]$Device = "edge",
    [string]$ApiBaseUrl = "http://localhost:4000",
    [switch]$SyncOnly
)

$ErrorActionPreference = "Stop"

function Read-DotEnvValue {
    param(
        [string]$FilePath,
        [string]$Key
    )

    foreach ($line in Get-Content $FilePath) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
            continue
        }

        if ($trimmed -match "^\s*$([regex]::Escape($Key))\s*=\s*(.+?)\s*$") {
            $value = $matches[1].Trim()
            if (
                ($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))
            ) {
                return $value.Substring(1, $value.Length - 2)
            }
            return $value
        }
    }

    return $null
}

$frontendDir = $PSScriptRoot
$backendEnv = Join-Path $frontendDir "..\backend\.env"
$definesFile = Join-Path $frontendDir "dart_defines.local.json"

if (-not (Test-Path $backendEnv)) {
    Write-Error "Khong tim thay backend/.env. Hay tao file env backend truoc."
}

$supabaseUrl = Read-DotEnvValue -FilePath $backendEnv -Key "SUPABASE_URL"
$supabaseAnonKey = Read-DotEnvValue -FilePath $backendEnv -Key "SUPABASE_ANON_KEY"

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
    Write-Error "backend/.env thieu SUPABASE_URL hoac SUPABASE_ANON_KEY."
}

$defines = [ordered]@{
    API_BASE_URL      = $ApiBaseUrl
    SUPABASE_URL      = $supabaseUrl
    SUPABASE_ANON_KEY = $supabaseAnonKey
}

$defines | ConvertTo-Json | Set-Content -Path $definesFile -Encoding UTF8
Write-Host "Da dong bo $definesFile tu backend/.env"

if ($SyncOnly) {
    exit 0
}

Push-Location $frontendDir
try {
    flutter run -d $Device --dart-define-from-file=dart_defines.local.json @args
}
finally {
    Pop-Location
}

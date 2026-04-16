# Watch-Reports.ps1
# Watcher raportów agentów → sync do impresja-knowledge
# Lokalizacja: gitomwtyczka/local-guardian/scripts/knowledge/Watch-Reports.ps1
#
# Uruchomienie:
#   .\Watch-Reports.ps1
# lub jako scheduled task (patrz: Install-ScheduledTask na dole)
#
# Wymagania:
#   - $env:GITHUB_TOKEN ustawiony (GitHub PAT z prawem repo:write do impresja-knowledge)
#   - PowerShell 7.x
#   - Dostęp do C:\Users\tomas2\.gemini\antigravity\playground\

param(
    [string]$WatchRoot   = "C:\Users\tomas2\.gemini\antigravity\playground",
    [string]$GithubOwner = "gitomwtyczka",
    [string]$GithubRepo  = "impresja-knowledge",
    [string]$GithubBranch = "main",
    [string]$DestPath    = "reports",
    [int]$IntervalSeconds = 60,
    [string]$LogFile     = "C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\logs\watch-reports.log"
)

# ─── Konfiguracja ─────────────────────────────────────────────────────────────

$pattern = ".agents\reports\*.md"
$apiBase  = "https://api.github.com"
$headers  = @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    "X-GitHub-Api-Version" = "2022-11-28"
    Accept        = "application/vnd.github+json"
}

# Stan — klucz: FullPath pliku, wartość: LastWriteTime kiedy ostatnio push
$pushed = @{}

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    if (-not (Test-Path (Split-Path $LogFile))) {
        New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
    }
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Get-FileSha {
    param([string]$repoPath)
    try {
        $url = "$apiBase/repos/$GithubOwner/$GithubRepo/contents/$repoPath?ref=$GithubBranch"
        $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        return $resp.sha
    } catch {
        return $null  # Plik nie istnieje jeszcze w repo
    }
}

function Push-FileToGithub {
    param(
        [string]$LocalPath,
        [string]$RepoPath
    )

    $content = Get-Content -Path $LocalPath -Raw -Encoding UTF8
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))

    $sha = Get-FileSha -repoPath $RepoPath

    $body = @{
        message = "auto-sync: $([System.IO.Path]::GetFileName($LocalPath)) [Watch-Reports]"
        content = $encoded
        branch  = $GithubBranch
    }
    if ($sha) { $body.sha = $sha }

    $url = "$apiBase/repos/$GithubOwner/$GithubRepo/contents/$RepoPath"

    try {
        $resp = Invoke-RestMethod -Uri $url -Headers $headers -Method Put `
            -Body ($body | ConvertTo-Json -Depth 5) `
            -ContentType "application/json" -ErrorAction Stop
        return $resp.commit.sha
    } catch {
        Write-Log "ERROR push $RepoPath : $_"
        return $null
    }
}

function Get-RepoSubdir {
    param([string]$LocalPath)
    # Wyciąga workspace z ścieżki i tworzy podkatalog w reports/
    # np. C:\...\playground\crimson-void\.agents\reports\2026-03-24_foo.md
    #  → reports/crimson-void/2026-03-24_foo.md
    $parts = $LocalPath -split [regex]::Escape([IO.Path]::DirectorySeparatorChar)
    $playgroundIdx = ($parts | Select-String -Pattern "^playground$" -SimpleMatch).LineNumber - 1
    if ($playgroundIdx -ge 0 -and $parts.Count -gt $playgroundIdx + 1) {
        $workspace = $parts[$playgroundIdx + 1]
        $fileName  = [System.IO.Path]::GetFileName($LocalPath)
        return "$DestPath/$workspace/$fileName"
    }
    return "$DestPath/$([System.IO.Path]::GetFileName($LocalPath))"
}

# ─── Main loop ────────────────────────────────────────────────────────────────

Write-Log "Watch-Reports started. Interval: ${IntervalSeconds}s | Root: $WatchRoot"
Write-Log "Target: github.com/$GithubOwner/$GithubRepo branch=$GithubBranch path=$DestPath/"

while ($true) {
    # Znajdź wszystkie pliki .md w .agents/reports/ każdego workspace
    $files = Get-ChildItem -Path $WatchRoot -Filter "*.md" -Recurse -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -match [regex]::Escape(".agents\reports\") }

    foreach ($file in $files) {
        $key     = $file.FullName
        $lastMod = $file.LastWriteTimeUtc

        if (-not $pushed.ContainsKey($key) -or $pushed[$key] -lt $lastMod) {
            $repoPath = Get-RepoSubdir -LocalPath $file.FullName

            Write-Log "Pushing: $($file.Name) → $repoPath"
            $commitSha = Push-FileToGithub -LocalPath $file.FullName -RepoPath $repoPath

            if ($commitSha) {
                $pushed[$key] = $lastMod
                Write-Log "OK: $($file.Name) → commit $commitSha"
            }
            # Throttle — unikaj rate limit GitHub API (5000 req/h)
            Start-Sleep -Milliseconds 500
        }
    }

    Start-Sleep -Seconds $IntervalSeconds
}

# ─── Opcjonalnie: instalacja jako Scheduled Task ──────────────────────────────
# Uruchom poniższy blok RĘCZNIE (jako admin) aby zarejestrować scheduled task:
<#
$scriptPath = "C:\Users\tomas2\.gemini\antigravity\playground\local-guardian\scripts\knowledge\Watch-Reports.ps1"
$action  = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NonInteractive -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings= New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "Antigravity-WatchReports" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force
#>

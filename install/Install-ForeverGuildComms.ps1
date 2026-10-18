# ForeverGuildComms integrated installer for Windows PowerShell 5.1+
# Place this script in the ForeverGuildComms\install folder (as packaged in the ZIP).
# Installs only the TOC and the .lua/.xml files listed inside it.
# Existing SavedVariables, unrelated files and addon directories are never modified.
# Usage (after Extract All):
#   Double-click ForeverGuildComms\install\Install-ForeverGuildComms.cmd (recommended).
#   .\ForeverGuildComms\install\Install-ForeverGuildComms.cmd -GamePath "D:\World of Warcraft\_classic_beta_"
#   Running this .ps1 directly may trigger a digital-signature policy error.
#   The .cmd launcher uses -ExecutionPolicy Bypass for its PowerShell process only.

[CmdletBinding()]
param(
    [string]$GamePath,
    [switch]$NonInteractive
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$addonName = 'ForeverGuildComms'
$addonSource = Split-Path -Path $PSScriptRoot -Parent
$stagingRoot = $null

function Write-Step {
    param([string]$Message)
    Write-Host ("[ForeverGuildComms] " + $Message) -ForegroundColor Cyan
}

function Resolve-ExistingDirectory {
    param([string]$InputPath)
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        throw 'No WoW Forever directory was selected.'
    }
    $expanded = [Environment]::ExpandEnvironmentVariables($InputPath.Trim().Trim('"'))
    $resolved = [System.IO.Path]::GetFullPath($expanded)
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw "Folder does not exist: $resolved"
    }
    return $resolved.TrimEnd([char[]]@('\', '/'))
}

function Resolve-AddOnsFolder {
    param([string]$InputPath)
    $folder = Resolve-ExistingDirectory -InputPath $InputPath
    $leaf = Split-Path -Path $folder -Leaf

    if ($leaf -ieq 'AddOns') {
        $interface = Split-Path -Path $folder -Parent
        if ((Split-Path -Path $interface -Leaf) -ine 'Interface') {
            throw 'The selected AddOns folder must be inside an Interface folder.'
        }
        return $folder
    }
    if ($leaf -ieq 'Interface') {
        return (Join-Path -Path $folder -ChildPath 'AddOns')
    }

    # The main World of Warcraft folder may contain several client variants.
    $beta = Join-Path -Path $folder -ChildPath '_classic_beta_'
    if (Test-Path -LiteralPath $beta -PathType Container) {
        return (Join-Path -Path $beta -ChildPath 'Interface\AddOns')
    }

    $looksLikeClient = ($leaf -match '^_.+_$') -or
        (Test-Path -LiteralPath (Join-Path -Path $folder -ChildPath 'Interface') -PathType Container) -or
        (Test-Path -LiteralPath (Join-Path -Path $folder -ChildPath 'Wow.exe') -PathType Leaf) -or
        (Test-Path -LiteralPath (Join-Path -Path $folder -ChildPath 'WowClassic.exe') -PathType Leaf)
    if ($looksLikeClient) {
        return (Join-Path -Path $folder -ChildPath 'Interface\AddOns')
    }
    throw 'Select the WoW Forever client folder (_classic_beta_), its Interface folder or its Interface\AddOns folder.'
}

function Find-ForeverClients {
    $roots = New-Object 'System.Collections.Generic.List[string]'
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {
        if (-not $drive.Root) { continue }
        foreach ($subpath in @(
            'World of Warcraft', 'Games\World of Warcraft',
            'Battle.net\World of Warcraft', 'Program Files\World of Warcraft',
            'Program Files (x86)\World of Warcraft'
        )) {
            $roots.Add((Join-Path -Path $drive.Root -ChildPath $subpath))
        }
    }
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:USERPROFILE)) {
        if ($base) { $roots.Add((Join-Path -Path $base -ChildPath 'World of Warcraft')) }
    }

    $found = New-Object 'System.Collections.Generic.List[string]'
    foreach ($root in @($roots | Sort-Object -Unique)) {
        $client = Join-Path -Path $root -ChildPath '_classic_beta_'
        if (Test-Path -LiteralPath $client -PathType Container) { $found.Add($client) }
    }
    return @($found | Sort-Object -Unique)
}

function Prompt-ForGameFolder {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.FolderBrowserDialog
        $picker.Description = 'Select the WoW Forever client folder, Interface, or Interface\AddOns'
        $picker.ShowNewFolderButton = $false
        if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            return $picker.SelectedPath
        }
    }
    catch {
        Write-Host 'Folder picker unavailable; please type the path.' -ForegroundColor Yellow
    }
    $path = Read-Host 'WoW Forever folder (blank to cancel)'
    if ([string]::IsNullOrWhiteSpace($path)) { throw 'Installation cancelled.' }
    return $path
}

function Get-AddOnsDestination {
    if (-not [string]::IsNullOrWhiteSpace($GamePath)) {
        return (Resolve-AddOnsFolder -InputPath $GamePath)
    }

    $clients = @(Find-ForeverClients)
    if ($clients.Count -eq 1) {
        Write-Step "Detected client: $($clients[0])"
        return (Resolve-AddOnsFolder -InputPath $clients[0])
    }
    if ($NonInteractive) {
        throw 'Could not locate exactly one WoW Forever client. Supply -GamePath.'
    }
    if ($clients.Count -gt 1) {
        Write-Host 'More than one WoW Forever beta client was found:' -ForegroundColor Yellow
        for ($i = 0; $i -lt $clients.Count; $i++) {
            Write-Host ("  {0}. {1}" -f ($i + 1), $clients[$i])
        }
        $choice = Read-Host 'Select a number, or press Enter to browse'
        if ($choice -match '^\d+$') {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $clients.Count) {
                return (Resolve-AddOnsFolder -InputPath $clients[$index])
            }
            throw 'Invalid game selection.'
        }
    }
    return (Resolve-AddOnsFolder -InputPath (Prompt-ForGameFolder))
}

function Get-InstallManifest {
    param([string]$SourceDir)
    $tocPath = Join-Path -Path $SourceDir -ChildPath 'ForeverGuildComms.toc'
    if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
        throw "Missing addon manifest: $tocPath"
    }
    $files = New-Object 'System.Collections.Generic.List[string]'
    $files.Add('ForeverGuildComms.toc')
    foreach ($rawLine in (Get-Content -LiteralPath $tocPath)) {
        $line = $rawLine.Trim().TrimStart([char]0xFEFF)
        if (-not $line -or $line.StartsWith('#')) { continue }
        # Current v0.3.0 addon uses simple file names only. Reject paths,
        # scripts other than Lua, traversal, and unrelated assets.
        if ($line -notmatch '^[A-Za-z0-9_-]+\.(lua|xml)$') {
            throw "Invalid entry in addon TOC: $line"
        }
        if ($files.Contains($line)) { throw "Duplicate TOC entry: $line" }
        $entryPath = Join-Path -Path $SourceDir -ChildPath $line
        if (-not (Test-Path -LiteralPath $entryPath -PathType Leaf)) {
            throw "Addon source is missing a required file: $line"
        }
        $files.Add($line)
    }
    if ($files.Count -lt 2) { throw 'The addon TOC contains no loadable files.' }
    return $files.ToArray()
}

function Test-SameContents {
    param([string]$First, [string]$Second)
    if (-not (Test-Path -LiteralPath $Second -PathType Leaf)) { return $false }
    $a = (Get-FileHash -LiteralPath $First -Algorithm SHA256).Hash
    $b = (Get-FileHash -LiteralPath $Second -Algorithm SHA256).Hash
    return ($a -eq $b)
}

$exitCode = 0
try {
    Write-Host ''
    Write-Host 'ForeverGuildComms 0.3.0-beta - integrated installer' -ForegroundColor Green
    Write-Host '---------------------------------------------------'

    if (-not (Test-Path -LiteralPath $addonSource -PathType Container)) {
        throw 'Cannot find the ForeverGuildComms addon folder. Extract the complete ZIP, then run ForeverGuildComms\install\Install-ForeverGuildComms.cmd.'
    }
    $fileNames = @(Get-InstallManifest -SourceDir $addonSource)
    $targetAddOns = Get-AddOnsDestination
    $targetAddon = Join-Path -Path $targetAddOns -ChildPath $addonName
    Write-Step "Source: $addonSource"
    Write-Step "Destination: $targetAddon"
    Write-Step "Loading $($fileNames.Count) addon files from the TOC."

    # Stage all needed files before touching the destination, allowing the
    # source folder to be the existing installed addon directory if desired.
    $stagingRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('FGC-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stagingRoot -ErrorAction Stop | Out-Null
    foreach ($file in $fileNames) {
        Copy-Item -LiteralPath (Join-Path -Path $addonSource -ChildPath $file) `
            -Destination (Join-Path -Path $stagingRoot -ChildPath $file) -ErrorAction Stop
    }

    $toCopy = @()
    foreach ($file in $fileNames) {
        $from = Join-Path -Path $stagingRoot -ChildPath $file
        $to = Join-Path -Path $targetAddon -ChildPath $file
        if (-not (Test-SameContents -First $from -Second $to)) { $toCopy += $file }
    }

    if ($toCopy.Count -eq 0) {
        Write-Host ''
        Write-Host 'Already up to date. No files needed copying.' -ForegroundColor Green
    }
    else {
        $interfacePath = Split-Path -Path $targetAddOns -Parent
        $previousFiles = @{}
        foreach ($file in $toCopy) {
            if (Test-Path -LiteralPath (Join-Path -Path $targetAddon -ChildPath $file) -PathType Leaf) {
                $previousFiles[$file] = $true
            }
        }

        $backup = $null
        if ($previousFiles.Count -gt 0) {
            $backupRoot = Join-Path -Path $interfacePath -ChildPath 'AddOnBackups'
            $backupName = '{0}-{1}-{2}' -f $addonName, (Get-Date -Format 'yyyyMMdd-HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0, 6))
            $backup = Join-Path -Path $backupRoot -ChildPath $backupName
            New-Item -ItemType Directory -Path $backup -Force -ErrorAction Stop | Out-Null
            foreach ($file in $previousFiles.Keys) {
                Copy-Item -LiteralPath (Join-Path -Path $targetAddon -ChildPath $file) `
                    -Destination (Join-Path -Path $backup -ChildPath $file) -ErrorAction Stop
            }
            Write-Step "Backed up replaced files to: $backup"
        }

        New-Item -ItemType Directory -Path $targetAddon -Force -ErrorAction Stop | Out-Null
        $attempted = @()
        try {
            foreach ($file in $toCopy) {
                $attempted += $file
                $from = Join-Path -Path $stagingRoot -ChildPath $file
                $to = Join-Path -Path $targetAddon -ChildPath $file
                Copy-Item -LiteralPath $from -Destination $to -Force -ErrorAction Stop
                if (-not (Test-SameContents -First $from -Second $to)) {
                    throw "Verification failed after copying $file"
                }
            }
        }
        catch {
            $copyError = $_.Exception.Message
            Write-Host 'Copy failed; restoring any affected files...' -ForegroundColor Yellow
            $rollbackIssues = @()
            for ($index = $attempted.Count - 1; $index -ge 0; $index--) {
                $file = $attempted[$index]
                $destinationFile = Join-Path -Path $targetAddon -ChildPath $file
                try {
                    if ($previousFiles.ContainsKey($file)) {
                        Copy-Item -LiteralPath (Join-Path -Path $backup -ChildPath $file) `
                            -Destination $destinationFile -Force -ErrorAction Stop
                    }
                    elseif (Test-Path -LiteralPath $destinationFile) {
                        Remove-Item -LiteralPath $destinationFile -Force -ErrorAction Stop
                    }
                }
                catch { $rollbackIssues += ('{0}: {1}' -f $file, $_.Exception.Message) }
            }
            if ($rollbackIssues.Count -gt 0) {
                throw ('Installation failed: ' + $copyError + '. Rollback was incomplete: ' + ($rollbackIssues -join '; '))
            }
            throw ('Installation failed and earlier files were restored: ' + $copyError)
        }

        Write-Host ''
        Write-Host ("SUCCESS: installed/updated {0} addon file(s)." -f $toCopy.Count) -ForegroundColor Green
        foreach ($file in $toCopy) { Write-Host ("  {0}" -f $file) }
        if ($backup) { Write-Host "Backup of replaced files: $backup" }
        Write-Host 'Other files, SavedVariables, templates and character preferences were left untouched.'
    }

    Write-Host ''
    Write-Host 'Restart WoW Forever (or type /reload). Open Settings > AddOns > Forever Guild Comms.'
}
catch {
    Write-Host ''
    Write-Host ('INSTALL FAILED: ' + $_.Exception.Message) -ForegroundColor Red
    $exitCode = 1
}
finally {
    if ($stagingRoot -and (Test-Path -LiteralPath $stagingRoot)) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
exit $exitCode

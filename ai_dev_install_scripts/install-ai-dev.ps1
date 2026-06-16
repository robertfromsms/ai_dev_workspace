<#
.SYNOPSIS
Installs the AI development environment into an existing project.

.DESCRIPTION
This script expects to be located at:

    <ai-dev-skeleton-root>/ai_dev_install_scripts/install-ai-dev.ps1

It installs the following resources into the selected target project:

    .devcontainer/ai_dev/
    .devcontainer/ai_dev_hot/
    .devcontainer/Dockerfile
    .vscode/extensions.json
    A_DEV_WORKSPACE_README.md
    compose.ai-dev.yml
    vs_code_ai_dev_workspace.code-workspace

If the target project already has .vscode/extensions.json, the script merges
the extension recommendations without deleting other properties.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Stop-Installation {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Error $Message
    exit 1
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    try {
        return Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json
    }
    catch {
        Stop-Installation @"
Could not parse JSON file:

    $Path

The file must contain valid JSON. Comments and trailing commas may need to be
removed before running this installer.

Parser error:
$($_.Exception.Message)
"@
    }
}

function Merge-ExtensionRecommendations {
    param(
        [Parameter(Mandatory)]
        [object] $ExistingConfiguration,

        [Parameter(Mandatory)]
        [object] $IncomingConfiguration
    )

    $existingProperty =
        $ExistingConfiguration.PSObject.Properties["recommendations"]

    if ($null -eq $existingProperty) {
        $ExistingConfiguration |
            Add-Member `
                -MemberType NoteProperty `
                -Name "recommendations" `
                -Value @()
    }

    $incomingProperty =
        $IncomingConfiguration.PSObject.Properties["recommendations"]

    if ($null -eq $incomingProperty) {
        Stop-Installation `
            "The skeleton .vscode/extensions.json has no recommendations array."
    }

    # Extension identifiers are treated case-insensitively.
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $mergedRecommendations =
        [System.Collections.Generic.List[string]]::new()

    foreach ($extensionId in @($ExistingConfiguration.recommendations)) {
        if ($null -eq $extensionId) {
            continue
        }

        $normalizedId = ([string] $extensionId).Trim()

        if (
            $normalizedId.Length -gt 0 -and
            $seen.Add($normalizedId)
        ) {
            $mergedRecommendations.Add($normalizedId)
        }
    }

    foreach ($extensionId in @($IncomingConfiguration.recommendations)) {
        if ($null -eq $extensionId) {
            continue
        }

        $normalizedId = ([string] $extensionId).Trim()

        if (
            $normalizedId.Length -gt 0 -and
            $seen.Add($normalizedId)
        ) {
            $mergedRecommendations.Add($normalizedId)
        }
    }

    $ExistingConfiguration.recommendations =
        @($mergedRecommendations)

    return $ExistingConfiguration
}

function Write-Utf8FileAtomically {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Content
    )

    $parentDirectory = Split-Path -Parent $Path
    $temporaryPath = Join-Path `
        $parentDirectory `
        (".{0}.{1}.tmp" -f `
            ([System.IO.Path]::GetFileName($Path)),
            ([guid]::NewGuid().ToString("N"))
        )

    $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

    try {
        [System.IO.File]::WriteAllText(
            $temporaryPath,
            $Content,
            $utf8WithoutBom
        )

        Move-Item `
            -LiteralPath $temporaryPath `
            -Destination $Path `
            -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}


# ---------------------------------------------------------------------------
# Locate the source skeleton
# ---------------------------------------------------------------------------

$installerDirectory = $PSScriptRoot
$sourceRoot = Split-Path -Parent $installerDirectory

Write-Step "Using AI development skeleton at: $sourceRoot"


# ---------------------------------------------------------------------------
# Prompt for and validate the target project
# ---------------------------------------------------------------------------

$targetInput = Read-Host `
    "Enter the full path of the target project"

if ([string]::IsNullOrWhiteSpace($targetInput)) {
    Stop-Installation "No target project path was provided."
}

# Remove accidental surrounding quotes, then expand variables such as
# %USERPROFILE%.
$targetInput = $targetInput.Trim().Trim('"')
$targetInput =
    [Environment]::ExpandEnvironmentVariables($targetInput)

if (-not (Test-Path -LiteralPath $targetInput -PathType Container)) {
    Stop-Installation `
        "The target project directory does not exist: $targetInput"
}

$targetRoot = (
    Resolve-Path -LiteralPath $targetInput
).Path

Write-Step "Target project found: $targetRoot"


# ---------------------------------------------------------------------------
# Define source paths
# ---------------------------------------------------------------------------

$sourceDevcontainerRoot =
    Join-Path $sourceRoot ".devcontainer"

$sourceAiDev =
    Join-Path $sourceDevcontainerRoot "ai_dev"

$sourceAiDevHot =
    Join-Path $sourceDevcontainerRoot "ai_dev_hot"

$sourceDockerfile =
    Join-Path $sourceDevcontainerRoot "Dockerfile"

$sourceVscodeRoot =
    Join-Path $sourceRoot ".vscode"

$sourceExtensions =
    Join-Path $sourceVscodeRoot "extensions.json"

$rootFilesToInstall = @(
    "AI_DEV_WORKSPACE_README.md",
    "compose.ai-dev.yml",
    "vs_code_ai_dev_workspace.code-workspace"
)


# ---------------------------------------------------------------------------
# Verify that the skeleton itself is complete
# ---------------------------------------------------------------------------

$requiredSourcePaths = @(
    $sourceAiDev,
    $sourceAiDevHot,
    $sourceDockerfile,
    $sourceExtensions
)

foreach ($rootFileName in $rootFilesToInstall) {
    $requiredSourcePaths += Join-Path $sourceRoot $rootFileName
}

$missingSourcePaths = @(
    $requiredSourcePaths |
        Where-Object {
            -not (Test-Path -LiteralPath $_)
        }
)

if ($missingSourcePaths.Count -gt 0) {
    $formattedMissingPaths =
        $missingSourcePaths -join [Environment]::NewLine

    Stop-Installation @"
The AI development skeleton is incomplete. These required source paths are
missing:

$formattedMissingPaths
"@
}


# ---------------------------------------------------------------------------
# Inspect the target project
# ---------------------------------------------------------------------------

$targetDevcontainerRoot =
    Join-Path $targetRoot ".devcontainer"

$targetAiDev =
    Join-Path $targetDevcontainerRoot "ai_dev"

$targetAiDevHot =
    Join-Path $targetDevcontainerRoot "ai_dev_hot"

$targetDockerfile =
    Join-Path $targetDevcontainerRoot "Dockerfile"

$targetVscodeRoot =
    Join-Path $targetRoot ".vscode"

$targetExtensions =
    Join-Path $targetVscodeRoot "extensions.json"

if (Test-Path -LiteralPath $targetDevcontainerRoot -PathType Container) {
    Write-Host `
        "Target already has a .devcontainer directory; it will be preserved." `
        -ForegroundColor Yellow
}
else {
    Write-Host `
        "Target has no .devcontainer directory; it will be created." `
        -ForegroundColor DarkGray
}

$devcontainerCandidates = @(
    $targetAiDev
    $targetAiDevHot
    $targetDockerfile
)

$devcontainerConflicts = @(
    $devcontainerCandidates | Where-Object {
        Test-Path -LiteralPath $_
    }
)

if ($devcontainerConflicts.Count -gt 0) {
    $formattedConflicts =
        $devcontainerConflicts -join [Environment]::NewLine

    Stop-Installation @"
Installation cannot continue because one or more AI development resources
already exist:

$formattedConflicts

No files were copied.
"@
}

if (Test-Path -LiteralPath $targetVscodeRoot -PathType Container) {
    Write-Host `
        "Target already has a .vscode directory; it will be preserved." `
        -ForegroundColor Yellow
}
else {
    Write-Host `
        "Target has no .vscode directory; it will be created." `
        -ForegroundColor DarkGray
}

$targetExtensionsAlreadyExists =
    Test-Path -LiteralPath $targetExtensions -PathType Leaf

if ($targetExtensionsAlreadyExists) {
    Write-Host @"
Target already has:

    $targetExtensions

Its extension recommendations will be merged with the AI development
recommendations.
"@ -ForegroundColor Yellow
}
else {
    Write-Host `
        "Target has no .vscode/extensions.json; it will be copied." `
        -ForegroundColor DarkGray
}


# ---------------------------------------------------------------------------
# Check root-file conflicts
# ---------------------------------------------------------------------------

$rootFileConflicts = @()

foreach ($rootFileName in $rootFilesToInstall) {
    $targetFilePath = Join-Path $targetRoot $rootFileName

    if (Test-Path -LiteralPath $targetFilePath) {
        $rootFileConflicts += $targetFilePath
    }
}

if ($rootFileConflicts.Count -gt 0) {
    $formattedConflicts =
        $rootFileConflicts -join [Environment]::NewLine

    Stop-Installation @"
Installation cannot continue because one or more target files already exist:

$formattedConflicts

No files were copied.
"@
}


# ---------------------------------------------------------------------------
# Validate and prepare the extensions.json merge before copying anything
# ---------------------------------------------------------------------------

$incomingExtensionsConfiguration =
    Read-JsonFile -Path $sourceExtensions

$mergedExtensionsJson = $null

if ($targetExtensionsAlreadyExists) {
    $existingExtensionsConfiguration =
        Read-JsonFile -Path $targetExtensions

    $mergedExtensionsConfiguration =
        Merge-ExtensionRecommendations `
            -ExistingConfiguration $existingExtensionsConfiguration `
            -IncomingConfiguration $incomingExtensionsConfiguration

    $mergedExtensionsJson =
        $mergedExtensionsConfiguration |
            ConvertTo-Json -Depth 100

    $mergedExtensionsJson += [Environment]::NewLine
}


# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

Write-Step "All preflight checks passed. Installing files."

New-Item `
    -ItemType Directory `
    -Path $targetDevcontainerRoot `
    -Force |
    Out-Null

New-Item `
    -ItemType Directory `
    -Path $targetVscodeRoot `
    -Force |
    Out-Null

Copy-Item `
    -LiteralPath $sourceAiDev `
    -Destination $targetAiDev `
    -Recurse

Copy-Item `
    -LiteralPath $sourceAiDevHot `
    -Destination $targetAiDevHot `
    -Recurse

Copy-Item `
    -LiteralPath $sourceDockerfile `
    -Destination $targetDockerfile

foreach ($rootFileName in $rootFilesToInstall) {
    Copy-Item `
        -LiteralPath (Join-Path $sourceRoot $rootFileName) `
        -Destination (Join-Path $targetRoot $rootFileName)
}

if ($targetExtensionsAlreadyExists) {
    Write-Utf8FileAtomically `
        -Path $targetExtensions `
        -Content $mergedExtensionsJson
}
else {
    Copy-Item `
        -LiteralPath $sourceExtensions `
        -Destination $targetExtensions
}


# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "AI development environment installation complete." `
    -ForegroundColor Green

Write-Host ""
Write-Host "Installed into:" -ForegroundColor Cyan
Write-Host "    $targetRoot"

Write-Host ""
Write-Host "Installed resources:" -ForegroundColor Cyan
Write-Host "    .devcontainer/ai_dev/"
Write-Host "    .devcontainer/ai_dev_hot/"
Write-Host "    .devcontainer/Dockerfile"
Write-Host "    .vscode/extensions.json"
Write-Host "    A_DEV_WORKSPACE_README.md"
Write-Host "    compose.ai-dev.yml"
Write-Host "    vs_code_ai_dev_workspace.code-workspace"

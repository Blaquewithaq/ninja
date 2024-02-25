# ------------
# FUNCTIONS

# Prompt user to clean previous build files
function Invoke-PromptCleanBuild {
    param (
        [string]$Auto,
        [string]$Build,
        [string]$Dist
    )

    # Clean up previous build files, if found
    if ((Test-Path "$Build") -or (Test-Path "$Dist")) {
        if ($AUTO -eq "false") {
            # Ask to clean
            Write-Host
            Write-Host "Clean previous build? [Y/n]"
            $Clean = Read-Host
        }
        else {
            $Clean = "Y"
        }
    
        if ($Clean -ne "N" -and $Clean -ne "n") {
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -Path "$BUILD"
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -Path "$Dist"
        }
    }
    
    # Create build and dist directories, if they don't exist
    if (!(Test-Path "$Build")) {
        New-Item -Path "$Build" -ItemType Directory | Out-Null
    }
    if (!(Test-Path "$Dist")) {
        New-Item -Path "$Dist" -ItemType Directory | Out-Null
    }
}

# Configure build
function Start-ConfigureBuild {
    param (
        [string]$Source,
        [string]$Build,
        [string]$Dist,
        [string]$BuildType
    )

     if (!$Env:VCPKG_ROOT) {
        Write-Host "VCPKG_ROOT environment variable not set"
        exit 1
    }

    cmake `
    -G "Visual Studio 17 2022" `
    -A "X64" `
    -S "$Source" `
    -B "$Build" `
    -DCMAKE_INSTALL_PREFIX="$Dist" `
    -DCMAKE_VERBOSE_MAKEFILE=NO
}

# Build project
function Start-Build {
    param (
        [string]$Build
    )

    cmake --build "$BUILD"  --target install --parallel
}

# ------------
# Main

# Set default values
$Auto = "false"

# Process command line arguments
foreach ($arg in $args) {
    switch -regex ($arg) {
        "--auto" {
            $Auto = "true"
            break
        }
        * {
            Write-Host "Invalid argument: $arg"
            exit 1
        }
    }
}

# Set current directory
$Root = Get-Location
$Build = "$Root\build"
$Dist = "$Root\dist"

Invoke-PromptCleanBuild -Auto $Auto -Build $Build -Dist $Dist
Start-ConfigureBuild -Source $Root -Build $Build -Dist $Dist
Start-Build -Build $Build

# Reliably get the project root
$ScriptDir = $PSScriptRoot
$ProjectRoot = (Resolve-Path "$ScriptDir\..").Path
$FirmwareDir = "$ProjectRoot\firmware"

Write-Host "Project Root: $ProjectRoot" -ForegroundColor Yellow

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " 1. Building Firmware in WSL" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Copy firmware.mem to the XSim working directory so relative path resolves
$xsimDir = "$ProjectRoot\sim_proj\sim_proj.sim\sim_1\behav\xsim"
if (Test-Path $xsimDir) {
    $destDir = "$xsimDir\firmware\build"
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir | Out-Null
    }
    Copy-Item "$FirmwareDir\build\firmware.mem" -Destination $destDir -Force
    Write-Host "Copied firmware.mem to XSim directory" -ForegroundColor Green
} else {
    Write-Host "Warning: XSim directory not found, skipping copy of firmware.mem" -ForegroundColor Yellow
}

$DriveLetter = $FirmwareDir.Substring(0, 1).ToLower()
$RestOfPath = $FirmwareDir.Substring(2).Replace('\', '/')
$WslFirmwareDir = "/mnt/$DriveLetter$RestOfPath"

# CHANGED: Compiles *.c so any C file in the directory gets compiled!
$gccCommand = "riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T$WslFirmwareDir/src/link.ld -O1 -o $WslFirmwareDir/build/firmware.elf $WslFirmwareDir/src/start.S $WslFirmwareDir/src/*.c"
wsl -e bash -c $gccCommand

if ($LASTEXITCODE -ne 0) { Write-Host "Error compiling C code!" -ForegroundColor Red; exit }

$objcopyCommand = "riscv64-unknown-elf-objcopy -O binary $WslFirmwareDir/build/firmware.elf $WslFirmwareDir/build/firmware.bin"
wsl -e bash -c $objcopyCommand

if ($LASTEXITCODE -ne 0) { Write-Host "Error running objcopy!" -ForegroundColor Red; exit }

$pythonCommand = "python3 $WslFirmwareDir/scripts/make_hex.py $WslFirmwareDir/build/firmware.bin $WslFirmwareDir/build/firmware.mem"
wsl -e bash -c $pythonCommand

if ($LASTEXITCODE -ne 0) { Write-Host "Error running make_hex.py!" -ForegroundColor Red; exit }

Write-Host "Firmware built successfully!" -ForegroundColor Green

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " 2. Running Vivado Simulation" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$vivadoPath = "vivado" 
Set-Location $ProjectRoot
& $vivadoPath -mode batch -source scripts\run_sim.tcl

if ($LASTEXITCODE -eq 0) {
    Write-Host "Simulation completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Simulation encountered an error." -ForegroundColor Red
}
Write-Host "Done."
# ========================================
# INFORMAÇÕES DO SISTEMA
# ========================================

param(
    [switch]$ModoReparo
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $ModoReparo) {
    Clear-Host
    Escrever-Titulo -Texto "INFORMAÇÕES DO SISTEMA"
}

# ===== SISTEMA OPERACIONAL =====
Write-Host "=== SISTEMA OPERACIONAL ===" -ForegroundColor Cyan
$os = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Host "  Nome:        $($os.Caption)" -ForegroundColor White
Write-Host "  Versão:      $($os.Version)" -ForegroundColor White
Write-Host "  Build:       $($os.BuildNumber)" -ForegroundColor White
Write-Host "  Arquitetura: $($os.OSArchitecture)" -ForegroundColor White
Write-Host "  Instalação:  $($os.InstallDate.ToString('dd/MM/yyyy'))" -ForegroundColor White
Write-Host "  Último boot: $($os.LastBootUpTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor White
Write-Host ""

# ===== PROCESSADOR =====
Write-Host "=== PROCESSADOR ===" -ForegroundColor Cyan
$cpu = Get-CimInstance -ClassName Win32_Processor
Write-Host "  Nome:       $($cpu.Name.Trim())" -ForegroundColor White
Write-Host "  Núcleos:    $($cpu.NumberOfCores)" -ForegroundColor White
Write-Host "  Threads:    $($cpu.NumberOfLogicalProcessors)" -ForegroundColor White
Write-Host "  Velocidade: $($cpu.MaxClockSpeed) MHz" -ForegroundColor White
Write-Host ""

# ===== MEMÓRIA RAM =====
Write-Host "=== MEMÓRIA RAM ===" -ForegroundColor Cyan
$ramTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$ramLivreGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$ramUsadaGB = [math]::Round($ramTotalGB - $ramLivreGB, 2)
$percentualRam = [math]::Round(($ramUsadaGB / $ramTotalGB) * 100, 1)

$corRam = if ($percentualRam -gt 85) { 'Red' } elseif ($percentualRam -gt 70) { 'Yellow' } else { 'Green' }

Write-Host "  Total:      $ramTotalGB GB" -ForegroundColor White
Write-Host "  Usada:      $ramUsadaGB GB ($percentualRam%)" -ForegroundColor $corRam
Write-Host "  Disponível: $ramLivreGB GB" -ForegroundColor White
Write-Host ""

# ===== DISCOS =====
Write-Host "=== DISCOS ===" -ForegroundColor Cyan
Get-PSDrive -PSProvider FileSystem |
Where-Object { $_.Used -ne $null } |
ForEach-Object {
    $percentual = [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 2)
    $cor = if ($percentual -gt 80) { 'Red' } elseif ($percentual -gt 60) { 'Yellow' } else { 'Green' }
    $usadoGB = [math]::Round($_.Used / 1GB, 2)
    $livreGB = [math]::Round($_.Free / 1GB, 2)
    Write-Host "  $($_.Name): Usado: ${usadoGB}GB / Livre: ${livreGB}GB ($percentual%)" -ForegroundColor $cor
}
Write-Host ""

# ===== REDE =====
Write-Host "=== REDE ===" -ForegroundColor Cyan
Write-Host "  Hostname:  $env:COMPUTERNAME" -ForegroundColor White
Write-Host "  Usuário:   $env:USERNAME" -ForegroundColor White

$adaptadores = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
    Where-Object { $_.IPEnabled -eq $true }

foreach ($adaptador in $adaptadores) {
    Write-Host "  Adaptador: $($adaptador.Description)" -ForegroundColor White
    if ($adaptador.IPAddress) {
        Write-Host "    IP:   $($adaptador.IPAddress -join ', ')" -ForegroundColor Gray
    }
    if ($adaptador.MACAddress) {
        Write-Host "    MAC:  $($adaptador.MACAddress)" -ForegroundColor Gray
    }
}
Write-Host ""

# ===== UPTIME =====
Write-Host "=== UPTIME ===" -ForegroundColor Cyan
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "  Tempo ligado: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor White
Write-Host ""

if (-not $ModoReparo) {
    Pausar
}
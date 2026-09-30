# ========================================
# SINCRONIZAR DATA E HORÁRIO DO WINDOWS
# ========================================

param(
    [switch]$ModoReparo
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Verifica permissões de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERRO] Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Read-Host "ENTER para sair"
    exit
}

# Só limpa tela se não estiver no painel
if (-not $ModoReparo) {
    Clear-Host
    Escrever-Titulo "SINCRONIZAR DATA E HORÁRIO"
}

Write-Host "Horário atual do sistema: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# ===== 1. Reiniciar serviço de horário =====
Write-Host "Reiniciando serviço Windows Time..." -ForegroundColor Gray -NoNewline

try {
    Stop-Service -Name "W32Time" -Force -ErrorAction Ignore
    Start-Service -Name "W32Time" -ErrorAction Ignore
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FALHA" -ForegroundColor Red
}

# ===== 2. Configurar servidor NTP =====
Write-Host "Configurando servidor NTP (time.windows.com)..." -ForegroundColor Gray -NoNewline

try {
    w32tm /config /manualpeerlist:"time.windows.com pool.ntp.org" /syncfromflags:manual /reliable:YES /update | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FALHA" -ForegroundColor Red
}

# ===== 3. Forçar sincronização =====
Write-Host "Forçando sincronização com servidor NTP..." -ForegroundColor Gray -NoNewline

try {
    w32tm /resync /force | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FALHA" -ForegroundColor Red
}

# ===== 4. Verificar resultado =====
Write-Host ""
Write-Host "Verificando status do serviço..." -ForegroundColor Gray -NoNewline

$status = w32tm /query /status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host " OK" -ForegroundColor Green
    
    # Extrai informações úteis
    $stratum = ($status | Select-String "Stratum") -replace "Stratum: ", ""
    $fonte = ($status | Select-String "Source") -replace "Source: ", ""
    $ultimaSync = ($status | Select-String "Last Successful Sync Time") -replace "Last Successful Sync Time: ", ""
    
    Write-Host ""
    Write-Host "Status da sincronização:" -ForegroundColor Cyan
    Write-Host "  • Fonte: $fonte" -ForegroundColor White
    Write-Host "  • Stratum: $stratum" -ForegroundColor White
    Write-Host "  • Última sync: $ultimaSync" -ForegroundColor White
} else {
    Write-Host " FALHA" -ForegroundColor Red
}

# ===== Horário final =====
Write-Host ""
Write-Host "Horário atualizado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Green
Write-Host ""
Write-Host "=== Sincronização concluída ===" -ForegroundColor Green

# Só pausa se não estiver no painel
if (-not $ModoReparo) {
    Pausar
}
# =========================================================
# ATUALIZADOR AVANÇADO DE PACOTES
# =========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Verifica se o winget está instalado
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Winget não encontrado!" -ForegroundColor Red
    Write-Host "Instale o App Installer da Microsoft Store." -ForegroundColor Yellow
    Read-Host "Pressione ENTER para sair"
    exit
}

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Atualizador Automático de Pacotes" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Mostra data e hora atual
Write-Host "Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Lista atualizações disponíveis antes de instalar
Write-Host "[1/3] Verificando atualizações disponíveis..." -ForegroundColor Yellow
$updates = winget upgrade --accept-source-agreements | Select-Object -Skip 3 | Where-Object { $_ -match '\S' }

if ($updates.Count -eq 0) {
    Write-Host "Nenhuma atualização disponível!" -ForegroundColor Green
    Read-Host "Pressione ENTER para sair"
    exit
}

Write-Host "Encontradas $($updates.Count) atualizações." -ForegroundColor Cyan
Write-Host ""

# Confirmação antes de atualizar
$confirmar = Read-Host "Deseja atualizar todos os pacotes? (S/N)"
if ($confirmar -ne 'S' -and $confirmar -ne 's') {
    Write-Host "Atualização cancelada pelo usuário." -ForegroundColor Yellow
    Read-Host "Pressione ENTER para sair"
    exit
}

Write-Host ""
Write-Host "[2/3] Instalando atualizações..." -ForegroundColor Yellow
winget upgrade --all --accept-source-agreements --accept-package-agreements

Write-Host ""
Write-Host "[3/3] Verificando pacotes fixados..." -ForegroundColor Yellow
winget pin list

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Atualização concluída com sucesso!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Read-Host "Pressione ENTER para sair"

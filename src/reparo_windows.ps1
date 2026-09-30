# =========================================================
# SCRIPT DE REPARO GERAL DO WINDOWS
# =========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Verificação de Permissões (Obrigatório ser Admin)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-NOT $isAdmin) {
    Write-Host "[ERRO] Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "Execute o script como administrador." -ForegroundColor Yellow
    pause
    exit
}

Clear-Host
Write-Host "=== INICIANDO SCRIPT DE REPARO DO WINDOWS ===" -ForegroundColor Cyan
Write-Host "Isso pode levar alguns minutos. Não feche a janela.`n" -ForegroundColor Gray

# 2. DISM: Repara a imagem do Windows (Baixa arquivos saudáveis da Microsoft)
Write-Host "[1/4] Executando DISM (Restauração de Imagem)..." -ForegroundColor Yellow
DISM.exe /Online /Cleanup-Image /RestoreHealth
Write-Host ""

# 3. SFC: Repara arquivos do sistema corrompidos usando a imagem do DISM
Write-Host "[2/4] Executando SFC (Verificação de Arquivos do Sistema)..." -ForegroundColor Yellow
sfc /scannow
Write-Host ""

# 4. Reset de Rede: Corrige problemas de internet/DNS
Write-Host "[3/4] Resetando configurações de Rede e DNS..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
netsh winsock reset | Out-Null
Write-Host "Rede resetada com sucesso." -ForegroundColor Green
Write-Host ""

# 5. Limpeza: Apaga arquivos temporários que podem estar causando lentidão
Write-Host "[4/4] Limpando Arquivos Temporários..." -ForegroundColor Yellow
# O 'ErrorAction SilentlyContinue' impede que o script pare se algum arquivo estiver em uso
& "$PSScriptRoot\limpa_arquivos_temp.ps1" -ModoReparo
Write-Host "Limpeza concluída." -ForegroundColor Green
Write-Host ""

# 6. Finalização
Write-Host "=== REPARO CONCLUÍDO COM SUCESSO! ===" -ForegroundColor Green
Write-Host "Recomenda-se REINICIAR o computador agora para aplicar as alterações." -ForegroundColor Cyan
pause
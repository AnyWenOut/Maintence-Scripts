# ========================================
# LIMPADOR DE ARQUIVOS TEMPORÁRIOS
# ========================================

param([switch]$ModoReparo)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $ModoReparo) {
	Clear-Host
	Escrever-Titulo -Texto "LIMPEZA DE ARQUIVOS TEMPORÁRIOS"
}

Write-Host "Limpando arquivos temporários..." -ForegroundColor Yellow
Write-Host ""
    
# ===== TEMP do usuário =====
Write-Host "Limpando TEMP do usuário..." -ForegroundColor Gray -NoNewline

try {
	Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction Ignore
} catch {
    	# Ignora erros de permissão silenciosamente
}
Progresso -Percentual 20 -Status "Limpando TEMP do usuário..."

# Verifica quantos arquivos realmente sobraram
$restantes = 0
try {
   	$restantes = (Get-ChildItem -Path "$env:TEMP" -ErrorAction Ignore | Measure-Object).Count
} catch {
    	# Se não conseguir contar, assume que foi limpo
}
Progresso -Percentual 40 -Status "Verificando arquivos restantes..."

if ($restantes -gt 0) {
    	Write-Host " OK ($restantes arquivos não puderam ser removidos)" -ForegroundColor Yellow
} else {
    	Write-Host " OK (completo)" -ForegroundColor Green
}

# ===== TEMP do Windows =====
Write-Host "Limpando TEMP do Windows..." -ForegroundColor Gray -NoNewline

try {
    	Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction Ignore
} catch {
    	# Ignora erros de permissão silenciosamente
}
Progresso -Percentual 60 -Status "Limpando TEMP do Windows..."

# Verifica quantos arquivos realmente sobraram
$restantesWin = 0
try {
    	$restantesWin = (Get-ChildItem -Path "C:\Windows\Temp" -ErrorAction Ignore | Measure-Object).Count
} catch {
    	# Se não conseguir contar, assume que foi limpo
}
Progresso -Percentual 80 -Status "Verificando arquivos restantes..."

if ($restantesWin -gt 0) {
    	Write-Host " OK ($restantesWin arquivos não puderam ser removidos)" -ForegroundColor Yellow
} else {
    	Write-Host " OK (completo)" -ForegroundColor Green
}
Progresso -Percentual 100 -Status "Concluído!"

# ===== Resumo =====
$totalRestantes = $restantes + $restantesWin
Write-Host ""
if ($totalRestantes -eq 0) {
    	Write-Host "=== Limpeza concluída sem problemas ===" -ForegroundColor Green
} else {
    	Write-Host "=== Limpeza concluída ($totalRestantes arquivos não puderam ser removidos) ===" -ForegroundColor Yellow
}
Progresso -Percentual 100 -Concluir

if(-not $ModoReparo) {
	Pausar
}
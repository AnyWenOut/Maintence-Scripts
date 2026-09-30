# ========================================
# LIMPADOR DE CACHE DE NAVEGADORES
# ========================================

param(
    [switch]$ModoReparo
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $ModoReparo) {
    Clear-Host
    Escrever-Titulo -Texto "LIMPAR CACHE DE NAVEGADORES"
}

Write-Host "Aviso: Feche os navegadores antes de continuar para melhor resultado." -ForegroundColor Yellow
Write-Host ""

# Função auxiliar para limpar cache
function Limpar-CacheNavegador {
    param(
        [string]$Nome,
        [string[]]$Caminhos
    )

    Write-Host "Limpando cache do $Nome..." -ForegroundColor Gray -NoNewline

    $totalLimpo = 0
    $totalIgnorado = 0

    foreach ($caminho in $Caminhos) {
        # Expande variáveis de ambiente no caminho
        $caminhoExpandido = [Environment]::ExpandEnvironmentVariables($caminho)

        if (Test-Path $caminhoExpandido) {
            try {
                Remove-Item -Path "$caminhoExpandido\*" -Recurse -Force -ErrorAction Ignore
                $totalLimpo++
            } catch {
                $totalIgnorado++
            }
        }
    }

    if ($totalLimpo -gt 0) {
        if ($totalIgnorado -gt 0) {
            Write-Host " OK (alguns arquivos em uso)" -ForegroundColor Yellow
        } else {
            Write-Host " OK" -ForegroundColor Green
        }
    } else {
        Write-Host " Não encontrado" -ForegroundColor DarkGray
    }
}

# ===== GOOGLE CHROME =====
Limpar-CacheNavegador -Nome "Google Chrome" -Caminhos @(
    "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache",
    "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache",
    "%LOCALAPPDATA%\Google\Chrome\User Data\Default\GPUCache",
    "%LOCALAPPDATA%\Google\Chrome\User Data\ShaderCache",
    "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Service Worker\CacheStorage"
)

# ===== MICROSOFT EDGE =====
Limpar-CacheNavegador -Nome "Microsoft Edge" -Caminhos @(
    "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache",
    "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache",
    "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\GPUCache",
    "%LOCALAPPDATA%\Microsoft\Edge\User Data\ShaderCache",
    "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage"
)

# ===== MOZILLA FIREFOX =====
$perfisFirefox = Get-ChildItem -Path "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction Ignore
if ($perfisFirefox) {
    $caminhosFirefox = $perfisFirefox | ForEach-Object { "$($_.FullName)\cache2" }
    Limpar-CacheNavegador -Nome "Mozilla Firefox" -Caminhos $caminhosFirefox
} else {
    Write-Host "Limpando cache do Mozilla Firefox..." -ForegroundColor Gray -NoNewline
    Write-Host " Não encontrado" -ForegroundColor DarkGray
}

# ===== RESUMO =====
Write-Host ""
Write-Host "=== Limpeza de cache concluída ===" -ForegroundColor Green
Write-Host "Dica: Reinicie os navegadores para aplicar as alterações." -ForegroundColor Yellow

if (-not $ModoReparo) {
    Pausar
}

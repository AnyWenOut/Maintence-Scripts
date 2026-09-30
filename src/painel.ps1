# =========================================================
# PAINEL DE MANUTENÇÃO DO SISTEMA v2.0
# =========================================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-NOT $isAdmin) {
    Write-Host "[ERRO] Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "Execute o script como administrador." -ForegroundColor Yellow
    pause
    exit
}

$baseUrl = "https://tinyurl.com/maintence-scripts"
irm "$baseUrl/lib/funcoes.ps1" | iex
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Função para limpar a tela e mostrar o menu
function Mostrar-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    PAINEL DE MANUTENÇÃO DO SISTEMA" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Data: $(Get-Date -Format 'dd/MM/yyyy')" -ForegroundColor Gray -NoNewline
    Write-Host "  |  " -ForegroundColor Gray -NoNewline
    Write-Host "Hora: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    Write-Host " 🔄 [1] Atualizar programas (winget)" -ForegroundColor White
    Write-Host " 🔧 [2] Reparo geral do Windows" -ForegroundColor White
    Write-Host " 🗃  [3] Limpar arquivos temporários" -ForegroundColor White
    Write-Host " 🗑  [4] Limpar cache de navegadores" -ForegroundColor White
	Write-Host " 💽 [5] Verificar integridade de disco" -ForegroundColor White
    Write-Host " 💻 [6] Informações do sistema" -ForegroundColor White
	Write-Host " ⌚ [7] Sincronizar data/horário" -ForegroundColor White
    Write-Host " ❎ [0] Sair" -ForegroundColor White
    Write-Host ""
}

# Loop principal
while ($true) {
    	Mostrar-Menu
    	$opcao = Read-Host "Escolha uma opção"

	switch ($opcao) {
        '1' { irm "$baseUrl/src/atualizar_pacotes.ps1" | iex }
        '2' { irm "$baseUrl/src/reparo_windows.ps1" | iex }
        '3' { irm "$baseUrl/src/limpa_arquivos_temp.ps1" | iex }
		'4' { irm "$baseUrl/src/limpar_cache_navegadores.ps1" | iex }
		'5' { irm "$baseUrl/src/verificar_integridade_disco.ps1" | iex }
        '6' { irm "$baseUrl/src/info_sistema.ps1" | iex }
		'7' { irm "$baseUrl/src/sincronizar_horario.ps1" | iex }
        '0' { Encerrar }
        default {
           	Write-Host "Opção inválida!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

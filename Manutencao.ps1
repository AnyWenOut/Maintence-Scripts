# =========================================================
# SCRIPTS DE MANUTENÇÃO WINDOWS - ARQUIVO ÚNICO
# Uso (PowerShell como administrador):
#   irm https://raw.githubusercontent.com/AnyWenOut/Maintence-Scripts/main/Manutencao.ps1 | iex
# =========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =========================================================
# UTILITÁRIOS
# =========================================================

function Test-Admin {
    $identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
    ([Security.Principal.WindowsPrincipal]$identidade).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Exigir-Admin {
    if (Test-Admin) { return $true }
    Write-Host "[ERRO] Esta opção precisa ser executada como Administrador!" -ForegroundColor Red
    Write-Host "Abra o PowerShell com 'Executar como Administrador' e rode o comando novamente." -ForegroundColor Yellow
    Pausar
    return $false
}

function Escrever-Titulo {
    param([Parameter(Mandatory)][string]$Texto)
    Write-Host ""
    Write-Host "=== $Texto ===" -ForegroundColor Cyan
    Write-Host ""
}

function Pausar {
    Read-Host "`nPressione ENTER para continuar" | Out-Null
}

function Confirmar {
    param([Parameter(Mandatory)][string]$Pergunta)
    (Read-Host "$Pergunta (S/N)") -match '^[sS]$'
}

function Progresso {
    param(
        [double]$Percentual,
        [string]$Status = "Processando...",
        [string]$Titulo = "Ferramenta de reparo do Sistema",
        [switch]$Concluir
    )

    if ($Concluir) {
        Write-Progress -Activity $Titulo -Completed -Id 1
        return
    }

    $limitado = [math]::Max(0, [math]::Min(100, $Percentual))
    Write-Progress -Id 1 -Activity $Titulo `
        -Status ("{0} ({1:N1}%)" -f $Status, $limitado) `
        -PercentComplete ([math]::Round($limitado))
}

# Remove o conteúdo de uma pasta e retorna quantos itens sobraram
function Limpar-Pasta {
    param([Parameter(Mandatory)][string]$Caminho)
    Remove-Item -Path "$Caminho\*" -Recurse -Force -ErrorAction Ignore
    @(Get-ChildItem -Path $Caminho -ErrorAction Ignore).Count
}

function Escrever-Resultado {
    param([int]$Restantes)
    if ($Restantes -gt 0) {
        Write-Host " OK ($Restantes arquivos não puderam ser removidos)" -ForegroundColor Yellow
    } else {
        Write-Host " OK (completo)" -ForegroundColor Green
    }
}

# =========================================================
# 1. ATUALIZAR PACOTES (WINGET)
# =========================================================

function Atualizar-Pacotes {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "[ERRO] Winget não encontrado!" -ForegroundColor Red
        Write-Host "Instale o App Installer da Microsoft Store." -ForegroundColor Yellow
        Pausar
        return
    }

    Clear-Host
    Escrever-Titulo "ATUALIZADOR AUTOMÁTICO DE PACOTES"
    Write-Host "Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""

    Write-Host "[1/3] Verificando atualizações disponíveis..." -ForegroundColor Yellow
    $atualizacoes = winget upgrade --accept-source-agreements | Select-Object -Skip 3 | Where-Object { $_ -match '\S' }

    if (-not $atualizacoes) {
        Write-Host "Nenhuma atualização disponível!" -ForegroundColor Green
        Pausar
        return
    }

    Write-Host "Encontradas $(@($atualizacoes).Count) atualizações." -ForegroundColor Cyan
    Write-Host ""

    if (-not (Confirmar "Deseja atualizar todos os pacotes?")) {
        Write-Host "Atualização cancelada pelo usuário." -ForegroundColor Yellow
        Pausar
        return
    }

    Write-Host "`n[2/3] Instalando atualizações..." -ForegroundColor Yellow
    winget upgrade --all --accept-source-agreements --accept-package-agreements

    Write-Host "`n[3/3] Verificando pacotes fixados..." -ForegroundColor Yellow
    winget pin list

    Write-Host "`n=== Atualização concluída ===" -ForegroundColor Green
    Pausar
}

# =========================================================
# 2. REPARO GERAL DO WINDOWS
# =========================================================

function Reparar-Windows {
    if (-not (Exigir-Admin)) { return }

    Clear-Host
    Escrever-Titulo "REPARO GERAL DO WINDOWS"
    Write-Host "Isso pode levar alguns minutos. Não feche a janela.`n" -ForegroundColor Gray

    Write-Host "[1/4] Executando DISM (Restauração de Imagem)..." -ForegroundColor Yellow
    DISM.exe /Online /Cleanup-Image /RestoreHealth
    Write-Host ""

    Write-Host "[2/4] Executando SFC (Verificação de Arquivos do Sistema)..." -ForegroundColor Yellow
    sfc /scannow
    Write-Host ""

    Write-Host "[3/4] Resetando configurações de Rede e DNS..." -ForegroundColor Yellow
    ipconfig /flushdns | Out-Null
    netsh winsock reset | Out-Null
    Write-Host "Rede resetada com sucesso." -ForegroundColor Green
    Write-Host ""

    Write-Host "[4/4] Limpando Arquivos Temporários..." -ForegroundColor Yellow
    Limpar-Temporarios -Embutido
    Write-Host ""

    Write-Host "=== REPARO CONCLUÍDO ===" -ForegroundColor Green
    Write-Host "Recomenda-se REINICIAR o computador agora para aplicar as alterações." -ForegroundColor Cyan
    Pausar
}

# =========================================================
# 3. LIMPAR ARQUIVOS TEMPORÁRIOS
# =========================================================

function Limpar-Temporarios {
    param([switch]$Embutido)

    if (-not $Embutido) {
        Clear-Host
        Escrever-Titulo "LIMPEZA DE ARQUIVOS TEMPORÁRIOS"
    }

    Write-Host "Limpando arquivos temporários...`n" -ForegroundColor Yellow

    Write-Host "Limpando TEMP do usuário..." -ForegroundColor Gray -NoNewline
    Progresso -Percentual 20 -Status "Limpando TEMP do usuário..."
    $restantesUsuario = Limpar-Pasta $env:TEMP
    Escrever-Resultado $restantesUsuario

    Write-Host "Limpando TEMP do Windows..." -ForegroundColor Gray -NoNewline
    Progresso -Percentual 60 -Status "Limpando TEMP do Windows..."
    $restantesWindows = Limpar-Pasta "$env:SystemRoot\Temp"
    Escrever-Resultado $restantesWindows

    Progresso -Percentual 100 -Status "Concluído!"
    Progresso -Concluir

    $total = $restantesUsuario + $restantesWindows
    Write-Host ""
    if ($total -eq 0) {
        Write-Host "=== Limpeza concluída sem problemas ===" -ForegroundColor Green
    } else {
        Write-Host "=== Limpeza concluída ($total arquivos não puderam ser removidos) ===" -ForegroundColor Yellow
    }

    if (-not $Embutido) { Pausar }
}

# =========================================================
# 4. LIMPAR CACHE DE NAVEGADORES
# =========================================================

function Limpar-CacheNavegador {
    param(
        [Parameter(Mandatory)][string]$Nome,
        [string[]]$Caminhos
    )

    Write-Host "Limpando cache do $Nome..." -ForegroundColor Gray -NoNewline

    $encontrados = $Caminhos |
        ForEach-Object { [Environment]::ExpandEnvironmentVariables($_) } |
        Where-Object { Test-Path $_ }

    if (-not $encontrados) {
        Write-Host " Não encontrado" -ForegroundColor DarkGray
        return
    }

    foreach ($caminho in $encontrados) {
        Remove-Item -Path "$caminho\*" -Recurse -Force -ErrorAction Ignore
    }
    Write-Host " OK" -ForegroundColor Green
}

function Limpar-CacheNavegadores {
    Clear-Host
    Escrever-Titulo "LIMPAR CACHE DE NAVEGADORES"
    Write-Host "Aviso: Feche os navegadores antes de continuar para melhor resultado.`n" -ForegroundColor Yellow

    $subpastasChromium = "Cache", "Code Cache", "GPUCache", "Service Worker\CacheStorage"

    foreach ($navegador in @(
        @{ Nome = "Google Chrome";   Base = "%LOCALAPPDATA%\Google\Chrome\User Data" },
        @{ Nome = "Microsoft Edge";  Base = "%LOCALAPPDATA%\Microsoft\Edge\User Data" }
    )) {
        $caminhos = @($subpastasChromium | ForEach-Object { "$($navegador.Base)\Default\$_" }) +
                    "$($navegador.Base)\ShaderCache"
        Limpar-CacheNavegador -Nome $navegador.Nome -Caminhos $caminhos
    }

    $perfisFirefox = Get-ChildItem "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction Ignore
    Limpar-CacheNavegador -Nome "Mozilla Firefox" -Caminhos @($perfisFirefox | ForEach-Object { "$($_.FullName)\cache2" })

    Write-Host "`n=== Limpeza de cache concluída ===" -ForegroundColor Green
    Write-Host "Dica: Reinicie os navegadores para aplicar as alterações." -ForegroundColor Yellow
    Pausar
}

# =========================================================
# 5. VERIFICAR INTEGRIDADE DO DISCO
# =========================================================

function Verificar-Disco {
    if (-not (Exigir-Admin)) { return }

    Clear-Host
    Escrever-Titulo "VERIFICAR INTEGRIDADE DO DISCO"

    $corPorSaude = @{ Healthy = 'Green'; Warning = 'Yellow'; Unhealthy = 'Red' }
    $obterCor = { param($saude) if ($corPorSaude.ContainsKey([string]$saude)) { $corPorSaude[[string]$saude] } else { 'Gray' } }
    $obterLabel = { param($volume) if ($volume.FileSystemLabel) { $volume.FileSystemLabel } else { "Sem nome" } }

    Write-Host "Volumes encontrados:`n" -ForegroundColor Cyan

    $volumes = @(Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' })
    for ($i = 0; $i -lt $volumes.Count; $i++) {
        $volume = $volumes[$i]
        Write-Host "  [$($i + 1)] $($volume.DriveLetter): - $(& $obterLabel $volume)" -ForegroundColor White -NoNewline
        Write-Host " [$($volume.HealthStatus)]" -ForegroundColor (& $obterCor $volume.HealthStatus)
    }

    Write-Host "`n  [0] Verificar todos os volumes"
    Write-Host "  [V] Voltar`n"

    $escolha = Read-Host "Escolha um volume"

    if ($escolha -match '^[vV]$') { return }

    if ($escolha -eq '0') {
        $selecionados = $volumes
    } elseif ($escolha -match '^\d+$' -and [int]$escolha -ge 1 -and [int]$escolha -le $volumes.Count) {
        $selecionados = @($volumes[[int]$escolha - 1])
    } else {
        Write-Host "Opção inválida!" -ForegroundColor Red
        Pausar
        return
    }

    Write-Host "`nIniciando verificação...`n" -ForegroundColor Yellow

    $inicio = 20
    $fim = 80
    $contador = 0

    foreach ($volume in $selecionados) {
        $letra = $volume.DriveLetter
        $contador++
        $percentual = $inicio + ($contador / $selecionados.Count) * ($fim - $inicio)

        Write-Host "Verificando ${letra}: ($(& $obterLabel $volume))..." -ForegroundColor Gray -NoNewline
        Progresso -Percentual $percentual -Status ("Verificando disco {0} de {1}: {2}" -f $contador, $selecionados.Count, $letra)

        # CHKDSK em modo scan (somente verificação, sem reparo)
        $resultado = (& cmd /c "chkdsk ${letra}: /scan" 2>&1) -join "`n"

        if ($resultado -match "found no problems") {
            Write-Host " OK (sem problemas)" -ForegroundColor Green
        } elseif ($resultado -match "problems") {
            Write-Host " ATENÇÃO (problemas encontrados)" -ForegroundColor Yellow
        } else {
            Write-Host " OK" -ForegroundColor Green
        }
    }

    Write-Host "`n=== STATUS SMART DOS DISCOS ===" -ForegroundColor Cyan
    try {
        foreach ($disco in Get-PhysicalDisk) {
            Write-Host "  $($disco.FriendlyName): " -ForegroundColor White -NoNewline
            Write-Host "$($disco.HealthStatus)" -ForegroundColor (& $obterCor $disco.HealthStatus)
        }
    } catch {
        Write-Host "  Não foi possível consultar status SMART" -ForegroundColor Yellow
    }

    Progresso -Percentual 100 -Status "Concluído!"
    Progresso -Concluir

    Write-Host "`n=== Verificação concluída ===" -ForegroundColor Green
    Pausar
}

# =========================================================
# 6. INFORMAÇÕES DO SISTEMA
# =========================================================

function Mostrar-InfoSistema {
    Clear-Host
    Escrever-Titulo "INFORMAÇÕES DO SISTEMA"

    function Linha { param([string]$Texto, $Cor = 'White') Write-Host "  $Texto" -ForegroundColor $Cor }
    function Secao { param([string]$Nome) Write-Host "=== $Nome ===" -ForegroundColor Cyan }

    Secao "SISTEMA OPERACIONAL"
    $os = Get-CimInstance Win32_OperatingSystem
    Linha "Nome:        $($os.Caption)"
    Linha "Versão:      $($os.Version)"
    Linha "Build:       $($os.BuildNumber)"
    Linha "Arquitetura: $($os.OSArchitecture)"
    Linha "Instalação:  $($os.InstallDate.ToString('dd/MM/yyyy'))"
    Linha "Último boot: $($os.LastBootUpTime.ToString('dd/MM/yyyy HH:mm:ss'))"
    Write-Host ""

    Secao "PROCESSADOR"
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    Linha "Nome:       $($cpu.Name.Trim())"
    Linha "Núcleos:    $($cpu.NumberOfCores)"
    Linha "Threads:    $($cpu.NumberOfLogicalProcessors)"
    Linha "Velocidade: $($cpu.MaxClockSpeed) MHz"
    Write-Host ""

    Secao "MEMÓRIA RAM"
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $ramLivre = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $ramUsada = [math]::Round($ramTotal - $ramLivre, 2)
    $ramPercentual = [math]::Round(($ramUsada / $ramTotal) * 100, 1)
    $corRam = if ($ramPercentual -gt 85) { 'Red' } elseif ($ramPercentual -gt 70) { 'Yellow' } else { 'Green' }
    Linha "Total:      $ramTotal GB"
    Linha "Usada:      $ramUsada GB ($ramPercentual%)" $corRam
    Linha "Disponível: $ramLivre GB"
    Write-Host ""

    Secao "DISCOS"
    Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne $_.Used } | ForEach-Object {
        $percentual = [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 2)
        $cor = if ($percentual -gt 80) { 'Red' } elseif ($percentual -gt 60) { 'Yellow' } else { 'Green' }
        $usadoGB = [math]::Round($_.Used / 1GB, 2)
        $livreGB = [math]::Round($_.Free / 1GB, 2)
        Linha "$($_.Name): Usado: ${usadoGB}GB / Livre: ${livreGB}GB ($percentual%)" $cor
    }
    Write-Host ""

    Secao "REDE"
    Linha "Hostname:  $env:COMPUTERNAME"
    Linha "Usuário:   $env:USERNAME"
    Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | ForEach-Object {
        Linha "Adaptador: $($_.Description)"
        if ($_.IPAddress)  { Write-Host "    IP:   $($_.IPAddress -join ', ')" -ForegroundColor Gray }
        if ($_.MACAddress) { Write-Host "    MAC:  $($_.MACAddress)" -ForegroundColor Gray }
    }
    Write-Host ""

    Secao "UPTIME"
    $uptime = (Get-Date) - $os.LastBootUpTime
    Linha "Tempo ligado: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"

    Pausar
}

# =========================================================
# 7. SINCRONIZAR DATA E HORÁRIO
# =========================================================

function Invocar-Etapa {
    param(
        [Parameter(Mandatory)][string]$Descricao,
        [Parameter(Mandatory)][scriptblock]$Acao
    )

    Write-Host "$Descricao..." -ForegroundColor Gray -NoNewline
    try {
        & $Acao | Out-Null
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " FALHA" -ForegroundColor Red
    }
}

function Sincronizar-Horario {
    if (-not (Exigir-Admin)) { return }

    Clear-Host
    Escrever-Titulo "SINCRONIZAR DATA E HORÁRIO"
    Write-Host "Horário atual do sistema: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`n" -ForegroundColor Gray

    Invocar-Etapa "Reiniciando serviço Windows Time" {
        Stop-Service -Name W32Time -Force -ErrorAction Ignore
        Start-Service -Name W32Time -ErrorAction Ignore
    }
    Invocar-Etapa "Configurando servidor NTP (time.windows.com)" {
        w32tm /config /manualpeerlist:"time.windows.com pool.ntp.org" /syncfromflags:manual /reliable:YES /update
    }
    Invocar-Etapa "Forçando sincronização com servidor NTP" {
        w32tm /resync /force
    }

    Write-Host "`nVerificando status do serviço..." -ForegroundColor Gray -NoNewline
    $status = w32tm /query /status 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green

        $extrair = { param($campo) ($status | Select-String "^$campo" | Select-Object -First 1) -replace "^${campo}[^:]*:\s*", "" }

        Write-Host "`nStatus da sincronização:" -ForegroundColor Cyan
        Write-Host "  • Fonte: $(& $extrair 'Source')"
        Write-Host "  • Stratum: $(& $extrair 'Stratum')"
        Write-Host "  • Última sync: $(& $extrair 'Last Successful Sync Time')"
    } else {
        Write-Host " FALHA" -ForegroundColor Red
    }

    Write-Host "`nHorário atualizado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Green
    Write-Host "`n=== Sincronização concluída ===" -ForegroundColor Green
    Pausar
}

# =========================================================
# PAINEL PRINCIPAL
# =========================================================

function Mostrar-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    PAINEL DE MANUTENÇÃO DO SISTEMA" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Data: $(Get-Date -Format 'dd/MM/yyyy')" -ForegroundColor Gray -NoNewline
    Write-Host "  |  " -ForegroundColor Gray -NoNewline
    Write-Host "Hora: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    if (-not (Test-Admin)) {
        Write-Host "Aviso: sem permissão de administrador (algumas opções ficarão indisponíveis)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host " 🔄 [1] Atualizar programas (winget)"
    Write-Host " 🔧 [2] Reparo geral do Windows"
    Write-Host " 🗃  [3] Limpar arquivos temporários"
    Write-Host " 🗑  [4] Limpar cache de navegadores"
    Write-Host " 💽 [5] Verificar integridade de disco"
    Write-Host " 💻 [6] Informações do sistema"
    Write-Host " ⌚ [7] Sincronizar data/horário"
    Write-Host " ❎ [0] Sair"
    Write-Host ""
}

while ($true) {
    Mostrar-Menu

    switch (Read-Host "Escolha uma opção") {
        '1' { Atualizar-Pacotes }
        '2' { Reparar-Windows }
        '3' { Limpar-Temporarios }
        '4' { Limpar-CacheNavegadores }
        '5' { Verificar-Disco }
        '6' { Mostrar-InfoSistema }
        '7' { Sincronizar-Horario }
        '0' {
            Clear-Host
            Write-Host "`n=== Até logo! ===`n" -ForegroundColor Green
            return
        }
        default {
            Write-Host "Opção inválida!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

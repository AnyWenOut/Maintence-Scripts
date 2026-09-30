# ========================================
# VERIFICAR INTEGRIDADE DO DISCO
# ========================================

param(
    [switch]$ModoReparo
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$contador = 0

$inicio = 20
$fim = 80

# Verifica permissões de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERRO] Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Read-Host "ENTER para sair"
    exit
}

if (-not $ModoReparo) {
    Clear-Host
    Escrever-Titulo -Texto "VERIFICAR INTEGRIDADE DO DISCO"
}

# ===== LISTAR VOLUMES =====
Write-Host "Volumes encontrados:" -ForegroundColor Cyan
Write-Host ""

$volumes = @(Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.DriveType -eq 'Fixed' })

$i = 1
$volumesLista = @{}
foreach ($volume in $volumes) {
    $letra = $volume.DriveLetter
    $label = if ($volume.FileSystemLabel) { $volume.FileSystemLabel } else { "Sem nome" }
    $saude = $volume.HealthStatus

    $corSaude = switch ($saude) {
        'Healthy' { 'Green' }
        'Warning' { 'Yellow' }
        'Unhealthy' { 'Red' }
        default { 'Gray' }
    }

    Write-Host "  [$i] $letra`: - $label" -ForegroundColor White -NoNewline
    Write-Host " [$saude]" -ForegroundColor $corSaude

    $volumesLista[$i.ToString()] = $volume
    $i++
}

Write-Host ""
Write-Host "  [0] Verificar todos os volumes" -ForegroundColor White
Write-Host "  [V] Voltar" -ForegroundColor White
Write-Host ""

$escolha = Read-Host "Escolha um volume"

if ($escolha -eq 'V' -or $escolha -eq 'v') {
    if (-not $ModoReparo) {
        Pausar
    }
    exit
}

# ===== DEFINIR QUAIS VOLUMES VERIFICAR =====
$volumesParaVerificar = @()

if ($escolha -eq '0') {
    $volumesParaVerificar = @($volumes)
} elseif ($volumesLista.ContainsKey($escolha)) {
    $volumesParaVerificar = @($volumesLista[$escolha])
} else {
    Write-Host "Opção inválida!" -ForegroundColor Red
    if (-not $ModoPainel) {
        Pausar
    }
    exit
}

# ===== VERIFICAR CADA VOLUME =====
Write-Host ""
Write-Host "Iniciando verificação..." -ForegroundColor Yellow
Write-Host ""

foreach ($volume in $volumesParaVerificar) {
    $letra = $volume.DriveLetter
    $label = if ($volume.FileSystemLabel) { $volume.FileSystemLabel } else { "Sem nome" }
    $contador++
    $fatiaDoLoop = ($contador / $volumesParaVerificar.Count) * ($fim - $inicio)
    $percentualMacro = $inicio + $fatiaDoLoop

    Write-Host "Verificando $letra`: ($label)..." -ForegroundColor Gray -NoNewline
    Progresso -Percentual $percentualMacro -Status ("Verificando disco {0} de {1}: {2}" -f $contador, $volumesParaVerificar.Count, $letra)


    try {
        # Executa CHKDSK em modo scan (sem reparo, apenas verificação)
        $resultado = & cmd /c "chkdsk $letra`: /scan" 2>&1

        # Verifica se houve erro
        $resultadoTexto = $resultado -join "`n"

        if ($resultadoTexto -match "Windows has scanned the file system and found no problems") {
            Write-Host " OK (sem problemas)" -ForegroundColor Green
        } elseif ($resultadoTexto -match "problems") {
            Write-Host " ATENÇÃO (problemas encontrados)" -ForegroundColor Yellow
        } else {
            Write-Host " OK" -ForegroundColor Green
        }

    } catch {
        Write-Host " FALHA" -ForegroundColor Red
    }
}

# ===== STATUS SMART (se disponível) =====
Write-Host ""
Write-Host "=== STATUS SMART DOS DISCOS ===" -ForegroundColor Cyan

try {
    $discos = Get-PhysicalDisk
    foreach ($disco in $discos) {
        $corSaude = switch ($disco.HealthStatus) {
            'Healthy' { 'Green' }
            'Warning' { 'Yellow' }
            'Unhealthy' { 'Red' }
            default { 'Gray' }
        }

        Write-Host "  $($disco.FriendlyName): " -ForegroundColor White -NoNewline
        Write-Host "$($disco.HealthStatus)" -ForegroundColor $corSaude
    }
} catch {
    Write-Host "  Não foi possível consultar status SMART" -ForegroundColor Yellow
}
Progresso -Percentual 100 -Status "Concluído!"

Write-Host ""
Write-Host "=== Verificação concluída ===" -ForegroundColor Green

Progresso -Percentual 100 -Concluir

if (-not $ModoReparo) {
    Pausar
}

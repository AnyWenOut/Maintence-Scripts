# =========================================================
# FUNÇÕES REUTILIZÁVEIS
# =========================================================


function Escrever-Titulo {
    param(
		[Parameter(Mandatory=$true)]
		[string]$Texto
	)
    Write-Host ""
    Write-Host "=== $Texto ===" -ForegroundColor Cyan
    Write-Host ""
}

function Encerrar {

	Clear-Host
	Write-Host ""
	Write-Host "=== Até logo! ===" -ForegroundColor Green
	Write-Host ""

	Start-Sleep -Seconds 1
    exit
}

function Titulo-Colorido {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Mensagem,

		[ValidateSet("INFO", "SUCESSO", "ERRO", "AVISO")]
		[String]$Tipo
	)

	Clear-Host

	switch ($Tipo) {
        "INFO" {
			Write-Host ""
			Write-Host "=== $Mensagem ===" -ForegroundColor Gray
			Write-Host ""
		}
        "SUCESSO" {
			Write-Host ""
			Write-Host "=== $Mensagem ===" -ForegroundColor Green
			Write-Host ""
		}
        "ERRO" {
			Write-Host ""
			Write-Host "=== $Mensagem ===" -ForegroundColor Red
			Write-Host ""
		}
        "AVISO" {
			Write-Host ""
			Write-Host "=== $Mensagem ===" -ForegroundColor Yellow
			Write-Host ""
		}
    }

	Start-Sleep -Seconds 1
    exit
}

function Pausar {
    Read-Host "`nPressione ENTER para continuar"
}

function Progresso {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Percentual,

        [Parameter(Mandatory = $false)]
        [string]$Status = "Processando...",

        [Parameter(Mandatory = $false)]
        [string]$Titulo = "Ferramenta de reparo do Sistema",

        [switch]$Concluir
    )

    # Se a flag -Concluir for passada, fecha a barra
    if ($Concluir) {
        Write-Progress -Activity $Titulo -Completed -Id 1
        return
    }

    # 1. Garante que fique entre 0 e 100
    $PercentualClamped = [math]::Max(0, [math]::Min(100, $Percentual))

    # 2. Arredonda o float para o número inteiro mais próximo que a barra exige
    $PercentualInteiro = [math]::Round($PercentualClamped)

    # 3. No texto do status você pode exibir o decimal bonitinho (ex: 12.5%)
    # O "{0:N1}" formata para exibir apenas 1 casa decimal
    $statusComPorcentagem = "{0} ({1:N1}%)" -f $Status, $PercentualClamped

    # Passa o inteiro para o -PercentComplete
    Write-Progress -Id 1 -Activity $Titulo -Status $statusComPorcentagem -PercentComplete $PercentualInteiro
}

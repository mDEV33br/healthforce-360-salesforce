# Healthforce 360 - PowerShell Deployment Script
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Healthforce 360 - Deploy para Org Salesforce   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Verificar se a CLI sf está disponível
if (-not (Get-Command sf -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Salesforce CLI (sf) não encontrada no PATH." -ForegroundColor Red
    Write-Host "Instale via winget: winget install --id Salesforce.CLI -e --source winget" -ForegroundColor Yellow
    Exit 1
}

# 2. Validar conexão com a org padrão
Write-Host "`n[1/4] Verificando org conectada..." -ForegroundColor Green
sf org display

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[AVISO] Nenhuma org padrão conectada. Execute para autorizar:" -ForegroundColor Yellow
    Write-Host "sf org login web -d -a HealthforceOrg" -ForegroundColor White
    Exit 1
}

# 3. Deploy dos metadados
Write-Host "`n[2/4] Realizando deploy dos metadados (Custom Objects, Apex, LWC, Permissions)..." -ForegroundColor Green
sf project deploy start --source-dir force-app

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERRO] Falha no deploy dos metadados." -ForegroundColor Red
    Exit 1
}

# 4. Atribuir Permission Set
Write-Host "`n[3/4] Atribuindo Permission Sets..." -ForegroundColor Green
sf org assign permset --name Healthforce_Gestor
sf org assign permset --name Healthforce_Agentforce

# 5. Carga de dados sintéticos
Write-Host "`n[4/4] Inserindo dados sintéticos de teste..." -ForegroundColor Green
sf apex run --file data/seed-data.apex

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "   Healthforce 360 Implantado com Sucesso!        " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

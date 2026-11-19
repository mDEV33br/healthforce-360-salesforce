# Healthforce 360 - Script de Publicação no GitHub
param(
    [string]$RepoName = "healthforce-360-salesforce",
    [string]$GitHubUser = ""
)

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Healthforce 360 - Publicação no GitHub         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Verificar Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Git não encontrado no PATH." -ForegroundColor Red
    Write-Host "Instale via: winget install --id Git.Git -e --source winget" -ForegroundColor Yellow
    Exit 1
}

# 2. Inicializar repositório local
if (-not (Test-Path ".git")) {
    Write-Host "`n[1/4] Inicializando repositório Git local..." -ForegroundColor Green
    git init -b main
} else {
    Write-Host "`n[1/4] Repositório Git já inicializado." -ForegroundColor Green
}

# 3. Adicionar arquivos e criar commit inicial
Write-Host "`n[2/4] Preparando arquivos e commit..." -ForegroundColor Green
git add .
git commit -m "feat: initial commit Healthforce 360 - Salesforce Agentforce MVP"

# 4. Publicação via GitHub CLI (gh) ou manual
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "`n[3/4] GitHub CLI detectado. Criando repositório remoto público..." -ForegroundColor Green
    gh repo create $RepoName --public --source=. --remote=origin --push
    Write-Host "`n[SUCESSO] Repositório publicado com sucesso no GitHub!" -ForegroundColor Green
} else {
    Write-Host "`n[3/4] GitHub CLI (gh) não configurado." -ForegroundColor Yellow
    Write-Host "Para associar ao seu repositório remoto no GitHub, execute:" -ForegroundColor White
    Write-Host "  git remote add origin https://github.com/<SEU-USUARIO>/$RepoName.git" -ForegroundColor Cyan
    Write-Host "  git branch -M main" -ForegroundColor Cyan
    Write-Host "  git push -u origin main" -ForegroundColor Cyan
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "   Concluído! Código versionado com sucesso.      " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

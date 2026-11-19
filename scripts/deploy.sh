#!/usr/bin/env bash
set -e

echo "=================================================="
echo "   Healthforce 360 - Deploy para Org Salesforce   "
echo "=================================================="

# 1. Checagem de ferramentas
command -v sf >/dev/null 2>&1 || { echo "[ERRO] Salesforce CLI (sf) não encontrada."; exit 1; }

# 2. Deploy
echo "[1/3] Realizando deploy da pasta force-app..."
sf project deploy start --source-dir force-app

# 3. Atribuição de permissões
echo "[2/3] Atribuindo Permission Sets..."
sf org assign permset --name Healthforce_Gestor
sf org assign permset --name Healthforce_Agentforce

# 4. Seed Data
echo "[3/3] Carregando dados sintéticos..."
sf apex run --file data/seed-data.apex

echo "=================================================="
echo "   Healthforce 360 Implantado com Sucesso!        "
echo "=================================================="

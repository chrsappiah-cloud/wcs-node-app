#!/usr/bin/env bash
set -euo pipefail

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) is required. Install it before running this script."
  exit 1
fi

RG_NAME="${1:-dreamflow-rg}"
LOCATION="${2:-eastus}"
NAME_PREFIX="${3:-dreamflow}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/main.bicep"
PARAMS_FILE="${SCRIPT_DIR}/main.parameters.json"

echo "Creating resource group ${RG_NAME} in ${LOCATION}..."
az group create --name "${RG_NAME}" --location "${LOCATION}" >/dev/null

echo "Deploying DreamFlow Azure infrastructure..."
az deployment group create \
  --resource-group "${RG_NAME}" \
  --template-file "${TEMPLATE_FILE}" \
  --parameters "${PARAMS_FILE}" namePrefix="${NAME_PREFIX}"

echo "Deployment complete."

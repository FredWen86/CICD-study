#!/usr/bin/env bash

# 说明：
# - 该脚本用于 GitHub Actions 执行“单机部署”（docker compose up）
# - 日志打印英文，便于在 CI/CD 日志里检索

set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: missing env: ${name}" >&2
    exit 1
  fi
}

require_env DEPLOY_HOST
require_env DEPLOY_USER
require_env DEPLOY_PATH
require_env IMAGE_NAME
require_env IMAGE_TAG
require_env GHCR_USERNAME
require_env GHCR_TOKEN

echo "INFO: deploying ${IMAGE_NAME}:${IMAGE_TAG} to ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}"

mkdir -p compose

if [[ ! -f "compose/compose.yml" || ! -f "compose/compose.prod.yml" || ! -f "compose/.env.prod" ]]; then
  echo "ERROR: expected compose files missing in workspace" >&2
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no"
SCP_OPTS="${SSH_OPTS}"

echo "INFO: ensuring remote directory exists"
ssh ${SSH_OPTS} "${DEPLOY_USER}@${DEPLOY_HOST}" "mkdir -p \"${DEPLOY_PATH}/compose\""

echo "INFO: syncing compose files"
scp ${SCP_OPTS} \
  "compose/compose.yml" \
  "compose/compose.prod.yml" \
  "compose/.env.prod" \
  "${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_PATH}/compose/"

echo "INFO: logging into GHCR on remote host"
echo "${GHCR_TOKEN}" | ssh ${SSH_OPTS} "${DEPLOY_USER}@${DEPLOY_HOST}" \
  "docker login ghcr.io -u \"${GHCR_USERNAME}\" --password-stdin >/dev/null"

echo "INFO: running remote deployment commands"
ssh ${SSH_OPTS} "${DEPLOY_USER}@${DEPLOY_HOST}" bash -lc "
set -euo pipefail
cd \"${DEPLOY_PATH}\"

if docker compose version >/dev/null 2>&1; then
  DC=\"docker compose\"
elif command -v docker-compose >/dev/null 2>&1; then
  DC=\"docker-compose\"
else
  echo \"ERROR: docker compose not found\" >&2
  exit 1
fi

echo \"INFO: pulling images\"
\$DC --env-file compose/.env.prod -f compose/compose.yml -f compose/compose.prod.yml pull

echo \"INFO: starting services\"
\$DC --env-file compose/.env.prod -f compose/compose.yml -f compose/compose.prod.yml up -d

echo \"INFO: status\"
\$DC --env-file compose/.env.prod -f compose/compose.yml -f compose/compose.prod.yml ps
"

echo "INFO: deploy finished"

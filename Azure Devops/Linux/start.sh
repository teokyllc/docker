#!/bin/bash
set -e

if [ -n "$AGENT_WORK_DIR" ]; then
  mkdir -p "$AGENT_WORK_DIR"
fi

AZP_URL=https://dev.azure.com/$ADO_ORG

export AGENT_ALLOW_RUNASROOT="0"

AZP_TOKEN=$(cat .token)
rm -f .token

# Ignore environment variables
export VSO_AGENT_IGNORE=AZP_TOKEN

./config.sh --unattended \
  --agent "$(hostname)" \
  --url "$AZP_URL" \
  --auth PAT \
  --token $AZP_TOKEN \
  --pool "$AGENT_POOL" \
  --work "$AGENT_WORK_DIR" \
  --replace \
  --acceptTeeEula & wait $!

unset AZP_TOKEN

cd bin
./Agent.Listener run --once & wait $!

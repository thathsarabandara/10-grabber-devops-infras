#!/usr/bin/env bash
# pull-all-repos.sh - Safely pull and fast-forward all cloned repositories
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/../config" && pwd)"
ENV_FILE="${CONFIG_DIR}/repositories.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Config file repositories.env not found. Initializing from repositories.env.example..."
    cp "${ENV_FILE}.example" "$ENV_FILE"
fi

# Source repository details
# shellcheck source=/dev/null
source "$ENV_FILE"

PLATFORM_ROOT="/opt/grabber-platform"
echo "=============================================="
echo " Pulling latest updates for all repositories..."
echo "=============================================="

# Array of services
REPOS=(
    "frontend|${FRONTEND_BRANCH}"
    "api-gateway|${API_GATEWAY_BRANCH}"
    "auth-service|${AUTH_SERVICE_BRANCH}"
    "robot-service|${ROBOT_SERVICE_BRANCH}"
    "telemetry-service|${TELEMETRY_BRANCH}"
    "ai-service|${AI_SERVICE_BRANCH}"
)

for entry in "${REPOS[@]}"; do
    IFS="|" read -r name branch <<< "$entry"
    TARGET_PATH="${PLATFORM_ROOT}/${name}"

    echo "Updating ${name} (branch: ${branch})..."
    
    if [[ ! -d "$TARGET_PATH" ]]; then
        echo "Warning: Repository ${name} does not exist at ${TARGET_PATH}. Run 'make clone' first." >&2
        continue
    fi

    if [[ ! -d "${TARGET_PATH}/.git" ]]; then
        echo "Error: Directory ${TARGET_PATH} is not a valid Git repository!" >&2
        exit 1
    fi

    # Fetch and fast-forward safely
    git -C "$TARGET_PATH" fetch origin
    git -C "$TARGET_PATH" checkout "$branch"
    
    # Run git pull --ff-only to ensure we don't force or create merge commits unexpectedly
    if git -C "$TARGET_PATH" pull --ff-only; then
        echo "Successfully updated ${name} to latest."
    else
        echo "Error: Failed to fast-forward ${name}. Manual merge resolution may be required." >&2
        exit 1
    fi
    echo "----------------------------------------------"
done

echo "=============================================="
echo " All repositories updated successfully!"
echo "=============================================="

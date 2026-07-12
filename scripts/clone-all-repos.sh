#!/usr/bin/env bash
# clone-all-repos.sh - Clone/update all platform repositories under /opt/grabber-platform/
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/../config" && pwd)"
ENV_FILE="${CONFIG_DIR}/repositories.env"

# Ensure the config file exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Config file repositories.env not found. Initializing from repositories.env.example..."
    cp "${ENV_FILE}.example" "$ENV_FILE"
fi

# Source repository details
# shellcheck source=/dev/null
source "$ENV_FILE"

PLATFORM_ROOT="/opt/grabber-platform"
echo "=============================================="
echo " Cloning platform repositories to ${PLATFORM_ROOT}..."
echo "=============================================="

# Create platform root if missing (using sudo if necessary)
if [[ ! -d "$PLATFORM_ROOT" ]]; then
    echo "Creating directory ${PLATFORM_ROOT}..."
    sudo mkdir -p "$PLATFORM_ROOT"
    sudo chown -R "$(id -u):$(id -g)" "$PLATFORM_ROOT"
fi

# Define array of services to clone
# Format: "local_dir_name|repo_url|branch"
REPOS=(
    "frontend|${FRONTEND_REPO}|${FRONTEND_BRANCH}"
    "api-gateway|${API_GATEWAY_REPO}|${API_GATEWAY_BRANCH}"
    "auth-service|${AUTH_SERVICE_REPO}|${AUTH_SERVICE_BRANCH}"
    "robot-service|${ROBOT_SERVICE_REPO}|${ROBOT_SERVICE_BRANCH}"
    "telemetry-service|${TELEMETRY_SERVICE_REPO}|${TELEMETRY_BRANCH}"
    "ai-service|${AI_SERVICE_REPO}|${AI_SERVICE_BRANCH}"
)

for entry in "${REPOS[@]}"; do
    IFS="|" read -r name repo branch <<< "$entry"
    TARGET_PATH="${PLATFORM_ROOT}/${name}"

    echo "Processing service: ${name}..."

    # Check if target exists but is not a Git repo
    if [[ -d "$TARGET_PATH" ]] && [[ ! -d "${TARGET_PATH}/.git" ]]; then
        echo "Error: Directory ${TARGET_PATH} exists but is not a valid Git repository!" >&2
        exit 1
    fi

    if [[ -d "$TARGET_PATH" ]]; then
        echo "Repository ${name} already exists. Updating in-place..."
        # If it exists, checkout the correct branch and fetch/pull
        git -C "$TARGET_PATH" fetch --all
        git -C "$TARGET_PATH" checkout "$branch"
        git -C "$TARGET_PATH" merge "origin/${branch}" || echo "Warning: Merge failed, might need manual resolve in ${name}"
    else
        echo "Cloning ${name} (branch: ${branch}) from ${repo}..."
        git clone --branch "$branch" "$repo" "$TARGET_PATH"
    fi
    echo "Finished processing ${name}."
    echo "----------------------------------------------"
done

echo "=============================================="
echo " Repositories cloning / updating complete!"
echo "=============================================="

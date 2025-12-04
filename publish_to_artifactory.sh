#!/bin/bash

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

FRAMEWORK_NAME="${EPOST_SDK_NAME}"

# === UPDATE BITBUCKET REPO ===
# Check for changes
echo "📝 Starting to commit framework changes to Bitbucket repo..."
if [ -n "$(git status --porcelain)" ]; then
  git add .
  git commit -m "New version: ${VERSION} has been committed using automated script for SDK Release."
  git push origin master
  echo "✅ Code pushed successfully"
else
  echo "ℹ️ No changes to commit"
fi

# Tagging (always runs)
echo "Creating new tag: ${VERSION}"
git tag -f "${VERSION}"      # -f ensures overwriting if tag exists locally
git push origin -f "${VERSION}"
echo "🏷️ Tag '${VERSION}' pushed to Bitbucket."

# === LOGIN TO ARTIFACTORY ===
echo "🔐 Login to Artifactory with access token..."
swift package-registry login "${ARTIFACTORY_URL}" --username "${ARTIFACTORY_USERNAME}" --password "${JFROG_ACCESS_TOKEN}"
echo "✅ Successfully Logged in to Artifactory"

# === PUBLISH ARTIFACTORY ===
echo "📤 Publishing Framework to Artifactory..."
swift package-registry publish axon.ePostSDK "${VERSION}" --url "${ARTIFACTORY_URL}"
echo "✅ Successfully Published to Artifactory"

# === Discard changes of copied framework ===
git checkout .
git clean -fd

# === Notify Slack ===
#Extract the latest changelog block for the version
LATEST_CHANGELOG=$(awk "/## \\[${VERSION//./\\.}\\]/ {print_flag=1; next} /^## \\[/ {print_flag=0} print_flag" CHANGELOG.md)

# Format changelog for Slack
SLACK_MESSAGE="*SDK ${VERSION} has been deployed!*\n\n*Changelog:*\n\`\`\`\n${LATEST_CHANGELOG}\n\`\`\`"
echo ${SLACK_MESSAGE}
curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${SLACK_MESSAGE}\"}" "$SLACK_WEBHOOK_URL"
echo "🔔 Slack notification sent"

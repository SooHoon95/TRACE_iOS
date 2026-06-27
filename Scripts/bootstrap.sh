#!/usr/bin/env bash
# Bootstrap a fresh clone: create local secrets file, install toolchain, generate the project.
set -euo pipefail
cd "$(dirname "$0")/.."

# 1. Local-only secrets file (git-ignored) from the committed template.
if [ ! -f XCConfigs/Sensitive.xcconfig ]; then
  cp XCConfigs/Sensitive.xcconfig.example XCConfigs/Sensitive.xcconfig
  echo "✓ created XCConfigs/Sensitive.xcconfig from example — fill in local secrets if needed"
fi

# 2. Toolchain (Tuist pinned in .mise.toml) + project generation.
if command -v mise >/dev/null 2>&1; then
  mise install
  mise exec -- tuist generate --no-open
else
  echo "⚠️  mise not found. Install mise (https://mise.jdx.dev) then re-run, or:"
  echo "    tuist generate --no-open"
fi

echo "✓ bootstrap done — open TRACE.xcworkspace"

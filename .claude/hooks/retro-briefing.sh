#!/bin/bash
# Retro session briefing hook — installed by `retro init`
# Reads the project briefing file and injects it as context at session start.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_SLUG=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
BRIEFING_FILE="$HOME/.retro/briefings/${PROJECT_SLUG}.md"
if [ -f "$BRIEFING_FILE" ]; then
    cat "$BRIEFING_FILE"
fi
exit 0

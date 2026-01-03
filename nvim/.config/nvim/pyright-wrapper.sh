#!/bin/bash
# Wrapper script for pyright with increased memory limit

# Set Node.js options to increase memory limit to 8GB
export NODE_OPTIONS="--max-old-space-size=8192"

# Execute the actual pyright-langserver with all arguments
exec "$HOME/.local/share/nvim/mason/bin/pyright-langserver" "$@"
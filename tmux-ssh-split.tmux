#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}/scripts"
HELPERS_DIR="${CURRENT_DIR}/scripts"

# shellcheck source=scripts/helpers.sh
source "${HELPERS_DIR}/helpers.sh"

tmux bind-key "$(split_bind_vertical_key)" run-shell "$SCRIPTS_DIR/tmux_ssh_split.sh -h"
tmux bind-key "$(split_bind_horizontal_key)" run-shell "$SCRIPTS_DIR/tmux_ssh_split.sh -v"

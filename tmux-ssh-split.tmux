#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmux bind-key '%' run-shell "${CURRENT_DIR}/scripts/tmux_ssh_split.sh -h"
tmux bind-key '"' run-shell "${CURRENT_DIR}/scripts/tmux_ssh_split.sh -v"

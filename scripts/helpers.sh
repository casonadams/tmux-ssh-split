#!/usr/bin/env bash

split_bind_vertical='%'
split_bind_vertical_option="@split_bind_vertical"

split_bind_horizontal='"'
split_bind_horizontal_option="@split_bind_horizontal"

# helper functions
function get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

function split_bind_vertical_key() {
  get_tmux_option "$split_bind_horizontal_option" "$split_bind_horizontal"
}

function split_bind_horizontal_key() {
  get_tmux_option "$split_bind_vertical_option" "$split_bind_vertical"
}

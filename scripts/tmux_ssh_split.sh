#!/usr/bin/env bash

set -e

unset GREP_OPTIONS
export LC_NUMERIC=C

function _tmux_ssh_split_tty_info() {
  tty="${1##/dev/}"
  case "$(uname -s)" in
    *CYGWIN*)
      ps -al | tail -n +2 | awk -v tty="$tty" '
        ((/ssh/ && !/-W/) || !/ssh/) && $5 == tty {
          user[$1] = $6; parent[$1] = $2; child[$2] = $1
        }
        END {
          for (i in parent)
          {
            j = i
            while (parent[j])
              j = parent[j]
            if (!(i in child) && j != 1)
            {
              file = "/proc/" i "/cmdline"; getline command < file; close(file)
              gsub(/\0/, " ", command)
              "id -un " user[i] | getline username
              print i":"username":"command
              exit
            }
          }
        }
      '
      ;;
    *)
      ps -t "$tty" -o user=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -o pid= -o ppid= -o command= | awk '
        NR > 1 && ((/ssh/ && !/-W/) || !/ssh/) {
          user[$2] = $1; parent[$2] = $3; child[$3] = $2; pid=$2; $1 = $2 = $3 = ""; command[pid] = substr($0,4)
        }
        END {
          for (i in parent)
          {
            j = i
            while (parent[j])
              j = parent[j]
            if (!(i in child) && j != 1)
            {
              print i":"user[i]":"command[i]
              exit
            }
          }
        }
      '
      ;;
  esac
}

function _tmux_ssh_split() {
  direction=${1:-'-h')}
  tty=${2:-$(tmux display -p '#{s,/dev/,,:pane_tty}')}

  tty_info=$(_tmux_ssh_split_tty_info "$tty")
  command=${tty_info#*:}
  command=${command#*:}

  case "$command" in
    *mosh-client*)
      # shellcheck disable=SC2046
      tmux split-window "$direction" mosh $(echo "$command" | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/')
      ;;
    *ssh*)
      # shellcheck disable=SC2001,SC2046
      tmux split-window "$direction" $(echo "$command" | sed -e 's/;/\\;/g')
      ;;
    *)
      tmux split-window "$direction" -c "#{pane_current_path}"
      ;;
  esac
}

_tmux_ssh_split "$@"

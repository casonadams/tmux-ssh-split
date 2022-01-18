#!/usr/bin/env bash

set -e

unset GREP_OPTIONS
export LC_NUMERIC=C

_uname_s=$(uname -s)

_is_true() {
  [ x"$1" = x"true" ] || [ x"$1" = x"yes" ] || [ x"$1" = x"1" ]
}

if command -v pkill > /dev/null 2>&1; then
  _pkillf() {
    pkill -f "$@" || true
  }
else
  case "$_uname_s" in
    *CYGWIN*)
      _pkillf() {
        while IFS= read -r pid; do
          kill "$pid" || true
        done << EOF
$(grep -Eao "$@" /proc/*/cmdline | xargs -0 | sed -E -n 's,/proc/([0-9]+)/.+$,\1,pg')
EOF
      }
      ;;
    *)
      _pkillf() {
        while IFS= read -r pid; do
          kill "$pid" || true
        done << EOF
$(ps -x -o pid= -o command= | grep -E "$@" | cut -d' ' -f1)
EOF
      }
      ;;
  esac
fi

_tty_info() {
  tty="${1##/dev/}"
  case "$_uname_s" in
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

_ssh_or_mosh_args() {
  case "$1" in
    *ssh*)
      args=$(printf '%s' "$1" | perl -n -e 'print if s/(.*?)\bssh\b\s+(.*)/\2/')
      ;;
    *mosh-client*)
      args=$(printf '%s' "$1" | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/' -e 's/-[^ ]*//g' -e 's/\d:\d//g')
      ;;
  esac

  printf '%s' "$args"
}

_username() {
  tty=${1:-$(tmux display -p '#{s,/dev/,,:pane_tty}')}
  ssh_only=$2

  tty_info=$(_tty_info "$tty")
  command=${tty_info#*:}
  command=${command#*:}

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    username=$(ssh -G $ssh_or_mosh_args 2> /dev/null | awk '/^user / { print $2; exit }')
    # shellcheck disable=SC2086
    [ -z "$username" ] && username=$(ssh -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%username%% %r >&2'" $ssh_or_mosh_args 2>&1 | awk '/^%username% / { print $2; exit }')
  else
    if ! _is_true "$ssh_only"; then
      username=${tty_info#*:}
      username=${username%%:*}
    fi
  fi

  printf '%s\n' "$username"
}

_hostname() {
  tty=${1:-$(tmux display -p '#{s,/dev/,,:pane_tty}')}
  ssh_only=$2
  full=$3
  h_or_H=$4

  tty_info=$(_tty_info "$tty")
  command=${tty_info#*:}
  command=${command#*:}

  ssh_or_mosh_args=$(_ssh_or_mosh_args "$command")
  if [ -n "$ssh_or_mosh_args" ]; then
    # shellcheck disable=SC2086
    hostname=$(ssh -G $ssh_or_mosh_args 2> /dev/null | awk '/^hostname / { print $2; exit }')
    # shellcheck disable=SC2086
    [ -z "$hostname" ] && hostname=$(ssh -T -o ControlPath=none -o ProxyCommand="sh -c 'echo %%hostname%% %h >&2'" $ssh_or_mosh_args 2>&1 | awk '/^%hostname% / { print $2; exit }')

    if ! _is_true "$full"; then
      case "$hostname" in
        *[a-z-].*)
          hostname=${hostname%%.*}
          ;;
        127.0.0.1)
          hostname="localhost"
          ;;
      esac
    fi
  else
    if ! _is_true "$ssh_only"; then
      hostname="$h_or_H"
    fi
  fi

  printf '%s\n' "$hostname"
}

_split_window_ssh() {
  direction=${1:-'-h')}
  tty=${2:-$(tmux display -p '#{s,/dev/,,:pane_tty}')}

  tty_info=$(_tty_info "$tty")
  command=${tty_info#*:}
  command=${command#*:}

  case "$command" in
    *mosh-client*)
      # shellcheck disable=SC2046
      tmux split-window "$direction" mosh $(echo "$command" | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/')
      ;;
    *ssh*)
      # shellcheck disable=SC2046
      tmux split-window "$direction" $(echo "$command" | sed -e 's/;/\\;/g')
      ;;
    *)
      tmux split-window "$direction"
      ;;
  esac
}

_split_window_ssh "$@"

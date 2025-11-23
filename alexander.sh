#!/usr/bin/env bash

##################################################################################################
# ALEXANDER - A Linux Equivalent of Source Auto-Named Demo Recorder
# Script that writes "record <timestamp>" to CFG file every X seconds when the game is running
# Config can then be executed during the game to start recording timestamped demo
#
# Inspired by Sander Dijkstra's "SANDER" (https://dyxtra.github.io/sander)
##################################################################################################

settings() {
  # string # Config for games found by ALEXANDER via '--populate' flag
  custom_paths="${HOME}/.config/alexander.conf"

  # string # Name of the file to write the command to (must be unique)
  cfg_file='sander.cfg'

  # string # Demo name with default prefix: autorec_2023-06-04-12-53-04.dem
  demo_prefix='autorec_'

  # integer # Check for the process every X seconds
  check_for_games='30'

  # integer # Refresh the timestamp every X seconds
  refresh_command='10'
}

game_settings() {
  # Left 4 Dead
  l4d_cfg="${HOME}/.local/share/Steam/steamapps/common/left 4 dead/left4dead/cfg"
  l4d_process=("left4dead.exe")

  # Left 4 Dead 2
  l4d2_cfg="${HOME}/.local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2/cfg"
  l4d2_process=("hl2_linux" "left4dead2.exe")
}

help_message() {
  echo "Usage: ${0##*/} <game> [options]"
  echo "Source engine demo recording helper."
  echo
  echo "Options:"
  echo "  -e, --edit        Edit the script and exit."
  echo "  -h, --help        Display help and exit."
  echo "  -p, --populate    Populate ALEXANDER's config with game paths and exit."
  echo "  -v, --version     Show version and exit."
  echo
  echo "Customizations can be applied inside the script in the 'settings' function."
}

bash_error() { echo -e "${cred}${1}${cstop} ${*:2}"; }
bash_warn() { echo -e "${cyellow}${1}${cstop} ${*:2}"; }
bash_success() { echo -e "${cgreen}${1}${cstop} ${*:2}"; }
bash_info() { echo -e "${cblue}${1}${cstop} ${2} ${cblue}${3}${cstop} ${*:4}"; }

desktop_notification() {
  if command -v notify-send > /dev/null 2>&1; then
    notify-send -a ALEXANDER "$@"
  fi
}

write_command() {
  timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
  cfg_command="record ${demo_prefix}${timestamp}"
  echo "$cfg_command" > "$cfg_path"
}

cleanup_dirty_exit() {
  desktop_notification "Warning!" "Script terminated."
  bash_warn "\nScript terminated."
  rm "$cfg_path"
  exit 130
}

populate_config() {
  bash_info "Generating game paths @ '$custom_paths'"

  if mkdir -p "${custom_paths%/*}" && [[ -w ${custom_paths%/*} ]]; then
    bash_success "Working directory set: '${custom_paths}'"
  else
    bash_error "Couldn't access '${custom_paths%/*}'. Exiting."
    exit 13
  fi

  if [[ -s $custom_paths ]]; then
    read -r -p "Wipe config first? (if yes, type full 'yes') " user_choice
    case "$user_choice" in
      '[yY][eE][sS]')
        :>"$custom_paths"
        ;;
      *)
        ;;
    esac
  fi

  while true; do
    read -r -p "Full path to search in (def. '~/.local/share/Steam/steamapps') " user_choice
    case "$user_choice" in
      '')
        local search_path="${HOME}/.local/share/Steam/steamapps"
        break
        ;;
      *)
        local search_path="$user_choice"
        if [[ ! -d $search_path ]]; then
          bash_error "Invalid directory."
        else
          break
        fi
        ;;
    esac
  done

  declare -A path_id
  path_id[l4d]="left4dead/cfg"
  path_id[l4d2]="left4dead2/cfg"

  for game in "${!path_id[@]}"; do
    while true; do
      # local game_path="$(find "$search_path" -type d "${exclusions[@]}" -path "*/${path_id[$game]}" -print -quit 2>/dev/null)"
      local game_path
      game_path="$(find "$search_path" -type d -path "*/${path_id[$game]}" -print -quit 2>/dev/null)"
      # if [[ ! $game_path ]]; then
        # bash_warn "Skipping '$game' (not found)..."
        # break
      # else
        echo "${game}_cfg=${game_path}"
        # read -r -t 30 -p "Write to config? (Y/n) " user_choice
        # case "$user_choice" in
        #   [nN]|[nN][oO])
        #     local exclusions=("${exclusions[@]}" "-not" "-path" "${game_path}")
        #     unset game_path
        #     ;;
        #   *)
            echo "${game}_cfg='${game_path}'" >> "$custom_paths"
            break
        #     ;;
        # esac
      # fi
    done
  # unset user_choice game_path
  unset game_path
  done

  sort "$custom_paths" -o "$custom_paths"
  bash_success "Config generated!"
  bash_info "If any of the paths above are wrong or missing, regenerate or edit '${custom_paths}' by hand."
}

main() {

  version=1.4.0

  cred="\033[31m"
  cgreen="\033[32m"
  cyellow="\033[33m"
  cblue="\033[34m"
  cstop="\033[0m"

  # Setup
  settings
  game_settings

  # shellcheck source=/dev/null
  if [[ -f $custom_paths ]]; then
    source "$custom_paths"
  fi

  # Parse all positional parameters
  while [[ "$1" != "" ]]; do
    case "$1" in

      '-p'|'--populate')
        populate_config
        exit 0
        ;;

      '-e'|'--edit')
        [[ ! $EDITOR ]] && echo 'EDITOR variable not found!' && exit 127
        echo "Editing \"$0\""
        "$EDITOR" "$0"
        exit 0
        ;;

      '-h'|'--help')
        help_message
        exit 0
        ;;

      '-v'|'--version')
        echo "       _                          _           "
        echo "  __ _| | _____  ____ _ _ __   __| | ___ _ __ "
        echo " / _' | |/ _ \ \/ / _' | '_ \ / _' |/ _ \ '__|"
        echo "| (_| | |  __/>  < (_| | | | | (_| |  __/ |   "
        echo " \__,_|_|\___/_/\_\__,_|_| |_|\__,_|\___|_|.sh"
        echo
        echo "A Linux Equivalent of Source Auto-Named Demo Recorder v${version}"
        echo "Copyright (c) 2023 L0q1 - MIT license"
        echo
        exit 0
        ;;

      'l4d')
        cfg_folder="$l4d_cfg"
        process_name=("${l4d_process[@]}")
        ;;

      'l4d2')
        cfg_folder="$l4d2_cfg"
        process_name=("${l4d2_process[@]}")
        ;;

      *)
        echo "Invalid option: \"$1\""
        help_message
        exit 1
        ;;

    esac
    shift
  done

  # Cleanup
  cfg_folder="${cfg_folder%/}"
  [[ $cfg_file != *.cfg ]] && cfg_file="${cfg_file}.cfg"
  cfg_path="${cfg_folder}/${cfg_file}"

  for int in $check_for_games $refresh_command; do
    if [[ ! $int =~ ^[0-9]+$ ]] || [[ $int -le 0 ]]; then
      desktop_notification "ERROR" "Invalid integer in settings."
      bash_error "ERROR: Invalid integer in settings" "'$int'"
      exit 22
    fi
  done

  if [[ ! -d $cfg_folder ]]; then
    desktop_notification "ERROR" "Directory not found."
    bash_error "ERROR: Directory not found" "'$cfg_folder'"
    exit 2
  elif [[ ! -w $cfg_folder ]]; then
    desktop_notification "ERROR" "Cannot access directory."
    bash_error "ERROR: Directory is read-only" "'$cfg_folder'"
    exit 13
  fi

  if [[ -f $cfg_path ]]; then
    desktop_notification "ERROR" "Not allowed to overwrite '$cfg_file'."
    bash_error "ERROR: File exists" "'$cfg_path'"
    exit 17
  else
    :>"$cfg_path"
    bash_success "Config set:" "'$cfg_path'"
  fi

  trap "cleanup_dirty_exit" SIGINT SIGTERM

  # Run the program
  bash_success "Looking for:" "'$process_name'"

  while [[ -w $cfg_path ]]; do
    if pgrep -x "$process_name" > /dev/null 2>&1; then
      if [[ ! -s $cfg_path ]]; then
        bash_success "Process '$process_name' found!"
      fi
      write_command
      read -r -t $refresh_command user_input
    else
      if [[ -s $cfg_path ]]; then
        bash_warn "Process lost."
        :>"$cfg_path"
      fi
      read -r -t $check_for_games user_input
    fi

    case $user_input in
      's'|'status')
        if [[ ! -s $cfg_path ]]; then
          bash_info "Looking for" "'$process_name'" "every" "${check_for_games}s"
        else
          bash_info "Updating timestamp in" "'$cfg_file'" "every" "${refresh_command}s"
        fi
        ;;
      'q'|'quit'|'stop'|'exit')
        bash_success "Script stopped."
        rm "$cfg_path"
        exit 0
        ;;
      '')
        ;;
      *)
        bash_info "s, status           " "Check script status."
        bash_info "q, quit, stop, exit " "Stop the script."
        ;;
    esac
  done

  if [[ ! -f $cfg_path ]]; then
    desktop_notification "Unexpected exit!" "Config deleted."
    bash_warn "Exiting. Config deleted."
    exit 2
  elif [[ ! -w $cfg_path ]]; then
    desktop_notification "Unexpected exit!" "Config permissions changed."
    bash_warn "Exiting. Config permissions changed."
    rm -f "$cfg_path"
    exit 13
  else
    desktop_notification "Unexpected exit!" "Reason unknown."
    bash_warn "Exiting. Reason unknown."
    rm "$cfg_path"
    exit 1
  fi

}

main "$@"

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
  paths_config="${HOME}/.config/alexander.conf"

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
  echo "  -h, --help        Display this help and exit."
  echo "  -p, --populate    Populate ALEXANDER's config with game paths."
  echo "  -v, --version     Show version and exit."
  echo
  echo "Customizations can be applied inside the script in the 'settings' function."
  echo "Custom game paths are stored in: $paths_config"
}

desktop_notification() {
  if command -v notify-send > /dev/null 2>&1; then
    notify-send -a ALEXANDER "$@" > /dev/null 2>&1
  fi
}

bash_error() { echo -e "${cred}${1}${cstop} ${*:2}"; desktop_notification "$@"; }
bash_warn() { echo -e "${cyellow}${1}${cstop} ${*:2}"; desktop_notification "$@"; }
bash_success() { echo -e "${cgreen}${1}${cstop} ${*:2}"; }
bash_info() { echo -e "${cblue}${1}${cstop} ${2} ${cblue}${3}${cstop} ${*:4}"; }

write_command() {
  timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
  cfg_command="record ${demo_prefix}${timestamp}"
  echo "$cfg_command" > "$cfg_path"
}

cleanup_dirty_exit() {
  bash_success "\nScript terminated."
  rm "$cfg_path"
  exit 130
}

merge_with() {
  local IFS="$1"
  shift
  echo "$*"
}

check_root() {
  if [[ $(id -u) -eq 0 ]]; then
    bash_error "ඞ"
    exit $?
  fi
}

populate_config() {
  bash_info "Generating game paths @ $paths_config"

  if ! mkdir -p "${paths_config%/*}" > /dev/null 2>&1 || [[ ! -w ${paths_config%/*} ]]; then
    bash_error "ERROR: Access denied!" "${paths_config%/*}"
    exit 13
  fi

  if [[ -f $paths_config ]] && [[ -s $paths_config ]]; then
    read -r -p "Wipe config first? (if yes, type full 'yes'): " user_choice
    case "$user_choice" in
      '[yY][eE][sS]')
        :>"$paths_config"
        ;;
      *)
        ;;
    esac
  fi

  while true; do
    read -r -p "Full path to search in (def. '~/.local/share/Steam/steamapps'): " user_choice
    case "$user_choice" in
      '')
        local search_path="${HOME}/.local/share/Steam/steamapps"
        break
        ;;
      *)
        local search_path="$user_choice"
        if [[ ! -d $search_path ]]; then
          bash_warn "Invalid directory" "'$search_path'"
        else
          break
        fi
        ;;
    esac
  done

  declare -A path_id
  path_id[l4d]="left4dead/cfg"
  path_id[l4d2]="left4dead2/cfg"

  local game_path
  for game in "${!path_id[@]}"; do
    game_path="$(find "$search_path" -type d -path "*/${path_id[$game]}" -print -quit 2>/dev/null)"
    if [[ $game_path ]]; then
      echo "${game}_cfg=${game_path}"
      echo "${game}_cfg='${game_path}'" >> "$paths_config"
    else
      bash_info "Skipping '$game'." "Not found."
    fi
    unset game_path
  done

  # sort "$paths_config" -o "$paths_config"
  bash_success "Config generated!"
}

main() {

  version=2.0.0

  cred="\033[31m"
  cgreen="\033[32m"
  cyellow="\033[33m"
  cblue="\033[34m"
  cstop="\033[0m"

  check_root
  settings
  game_settings

  if [[ $paths_config == */ ]] || [[ -d $paths_config ]]; then
    paths_config="${paths_config%/}/alexander.conf"
  fi

  # Parse all positional parameters
  while [[ "$1" != "" ]]; do
    case "$1" in

      '-p'|'--populate')
        populate_config
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
        proc_name=("${l4d_process[@]}")
        ;;

      'l4d2')
        cfg_folder="$l4d2_cfg"
        proc_name=("${l4d2_process[@]}")
        ;;

      *)
        echo "Invalid option: '$1'"
        help_message
        exit 1
        ;;

    esac
    shift
  done

  if [[ -f $paths_config ]]; then
    source "$paths_config"
  else
    bash_warn "Paths to games not found!" "Using script's defaults."
    bash_info "Run '${0##*/} --populate' to generate game paths."
  fi

  if [[ ! $cfg_folder ]] || [[ ! ${proc_name[*]} ]]; then
    while true; do
      read -r -p "Game to load (lowercase abbreviation): " user_choice
      case "$user_choice" in
        'l4d')
          cfg_folder="$l4d_cfg"
          proc_name=("${l4d_process[@]}")
          break
          ;;

        'l4d2')
          cfg_folder="$l4d2_cfg"
          proc_name=("${l4d2_process[@]}")
          break
          ;;

        *)
          ;;
      esac
    done
  fi

  cfg_folder="${cfg_folder%/}"
  [[ $cfg_file != *.cfg ]] && cfg_file="${cfg_file}.cfg"
  cfg_path="${cfg_folder}/${cfg_file}"

  for int in $check_for_games $refresh_command; do
    if [[ ! $int =~ ^[0-9]+$ ]] || [[ $int -le 0 ]]; then
      bash_error "ERROR: Invalid integer in settings!" "$int"
      exit 22
    fi
  done

  if [[ ! -d $cfg_folder ]]; then
    bash_error "ERROR: Config directory not found!" "$cfg_folder"
    exit 2
  elif [[ ! -w $cfg_folder ]]; then
    bash_error "ERROR: Config directory is read-only!" "$cfg_folder"
    exit 13
  fi

  if [[ -f $cfg_path ]]; then
    bash_error "ERROR: Config file exists (and may be important)!" "$cfg_path"
    exit 17
  else
    :>"$cfg_path"
    bash_success "Config set:" "$cfg_path"
  fi

  trap "cleanup_dirty_exit" SIGINT SIGTERM

  # Run the program
  bash_success "Looking for:" "${proc_name[*]}"

  while [[ -w $cfg_path ]]; do
    if pgrep -f ".*$(merge_with "|" "${proc_name[@]}").*" > /dev/null 2>&1; then
      if [[ ! -s $cfg_path ]]; then
        bash_success "Process found!"
      fi
      write_command
      read -r -t $refresh_command user_input
    else
      if [[ -s $cfg_path ]]; then
        bash_info "Process lost."
        :>"$cfg_path"
      fi
      read -r -t $check_for_games user_input
    fi

    case $user_input in
      's'|'status')
        if [[ ! -s $cfg_path ]]; then
          bash_info "Looking for" "${proc_name[*]}" "every" "${check_for_games}s"
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
    bash_warn "Exiting." "Config deleted."
    exit 2
  elif [[ ! -w $cfg_path ]]; then
    bash_warn "Exiting." "Config permissions changed."
    rm -f "$cfg_path"
    exit 13
  else
    bash_warn "Exiting." "Reason unknown."
    rm "$cfg_path"
    exit 1
  fi

}

main "$@"

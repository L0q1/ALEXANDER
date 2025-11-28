#!/usr/bin/env bash

##################################################################################################
# ALEXANDER - A Linux Equivalent of Source Auto-Named Demo Recorder
# Script that writes "record <timestamp>" to CFG file every X seconds when the game is running
# Config can then be executed during the game to start recording timestamped demo
#
# Inspired by Sander Dijkstra's "SANDER" (https://dyxtra.github.io/sander)
##################################################################################################

settings() {
  # string # ALEXANDER's config
  main_config="${HOME}/.config/alexander.conf"

  # string # Name of the file to write the command to (must be unique)
  cfg_file='sander.cfg'

  # string # Demo name with default prefix: autorec_2023-06-04-12-53-04.dem
  demo_prefix='autorec_'

  # integer # Check for the process every X seconds
  check_for_games='30'

  # integer # Refresh the timestamp every X seconds
  refresh_command='10'

  # array of strings # Paths to search for supported games (won't follow symlinks)
  search_paths=(
    "${HOME}/.local/share/Steam/steamapps" # default Steam library path
    "${HOME}/.steam/steam/steamapps" # legacy/compatibility path
    "${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps" # Flatpak
    "${HOME}/.var/app/com.valvesoftware.Steam/.steam/steam/steamapps" # Flatpak
  )
}

help_message() {
  echo "Usage: ${0##*/} <game|option>"
  echo "Source engine demo recording helper."
  echo
  echo "Supported games:"
  echo "  l4d               Left 4 Dead"
  echo "  l4d2              Left 4 Dead 2"
  echo
  echo "Options:"
  echo "  -c, --config      Edit game paths and exit."
  echo "  -e, --edit        Edit the script and exit."
  echo "  -g, --generate    Generate ALEXANDER's config and exit."
  echo "  -h, --help        Display this help and exit."
  echo "  -v, --version     Show version and exit."
  echo
  echo "Customizations can be applied inside the script in the 'settings' function."
  echo "Game paths are stored in: $main_config"
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
  rm "$cfg_path"
  bash_success "Script terminated."
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

generate_config() {
  bash_info "Generating game paths @" "$main_config"

  if ! mkdir -p "${main_config%/*}" > /dev/null 2>&1 || [[ ! -w ${main_config%/*} ]]; then
    bash_error "ERROR: Access denied!" "${main_config%/*}"
    exit 13
  fi

  declare -A path_id
  path_id[l4d]="left4dead/cfg"
  path_id[l4d2]="left4dead2/cfg"

  for game in "${!path_id[@]}"; do
    unset game_path game_cfg
    game_path="$(find "${search_paths[@]}" -type d -path "*/${path_id[$game]}" -print -quit 2>/dev/null)"
    game_cfg="${game}_cfg"
    if [[ $game_path ]] && [[ ! ${!game_cfg} ]]; then
      echo "${game_cfg}='${game_path}'" | tee -a "$main_config"
    fi
  done

  bash_success "Done!"
}

main() {

  version=2.1.0

  cred="\033[31m"
  cgreen="\033[32m"
  cyellow="\033[33m"
  cblue="\033[34m"
  cstop="\033[0m"

  check_root
  settings

  if [[ $main_config == */ ]] || [[ -d $main_config ]]; then
    main_config="${main_config%/}/alexander.conf"
  fi

  if [[ ! -f $main_config ]]; then
    bash_warn "Initializing first launch setup."
    generate_config
  fi

  source "$main_config" || exit $?

  case "$1" in
    '-c'|'--config')
      [[ ! $EDITOR ]] && echo 'EDITOR variable not found!' && exit 127
      "$EDITOR" "$main_config"
      exit 0
      ;;
    '-e'|'--edit')
      [[ ! $EDITOR ]] && echo 'EDITOR variable not found!' && exit 127
      "$EDITOR" "$0"
      exit 0
      ;;
    '-g'|'--generate')
      generate_config
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
      proc_name=("left4dead.exe")
      ;;
    'l4d2')
      cfg_folder="$l4d2_cfg"
      proc_name=("hl2_linux" "left4dead2.exe")
      ;;

    '')
      bash_error "ERROR: Missing argument!" "Specify a game or an option."
      help_message
      exit 1
      ;;
    *)
      bash_error "ERROR: Invalid option: $1"
      help_message
      exit 1
      ;;
  esac

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
    bash_error "ERROR: Config directory doesn't exist!" "$cfg_folder"
    exit 2
  elif [[ ! -w $cfg_folder ]]; then
    bash_error "ERROR: Config directory is read-only!" "$cfg_folder"
    exit 13
  fi

  if [[ -f $cfg_path ]]; then
    bash_error "ERROR: Config file exists!" "$cfg_path"
    exit 17
  else
    :>"$cfg_path"
    bash_success "Config set:" "$cfg_path"
  fi

  trap "cleanup_dirty_exit" SIGINT SIGTERM

  # Run the loop
  bash_success "Looking for:" "${proc_name[*]}"
  bash_info "Keys:" "[h]elp, [q]uit, [s]tatus"

  while [[ -w $cfg_path ]]; do
    if pgrep -f ".*$(merge_with "|" "${proc_name[@]}").*" > /dev/null 2>&1; then
      if [[ ! -s $cfg_path ]]; then
        bash_success "Process found!"
      fi
      write_command
      read -r -n1 -s -t $refresh_command user_input
    else
      if [[ -s $cfg_path ]]; then
        bash_info "Process lost."
        :>"$cfg_path"
      fi
      read -r -n1 -s -t $check_for_games user_input
    fi

    case $user_input in
      'h')
        bash_info "Keys:" "[h]elp, [q]uit, [s]tatus"
        ;;
      'q')
        rm "$cfg_path"
        bash_success "Script stopped."
        exit 0
        ;;
      's')
        if [[ ! -s $cfg_path ]]; then
          bash_info "Looking for" "${proc_name[*]}" "every" "${check_for_games}s"
        else
          bash_info "Updating timestamp in" "'$cfg_file'" "every" "${refresh_command}s"
        fi
        ;;
      *)
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
    rm -f "$cfg_path"
    exit 1
  fi

}

main "$@"

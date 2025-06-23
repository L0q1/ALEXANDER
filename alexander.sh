#!/usr/bin/env bash

##################################################################################################
# ALEXANDER - A Linux Equivalent of Source Auto-Named Demo Recorder
# Script that writes "record <timestamp>" to CFG file every X seconds when the game is running
# Config can then be executed during the game to start recording timestamped demo
#
# Inspired by Sander Dijkstra's "SANDER" (https://www.dyxtra.com/sander)
##################################################################################################

settings() {
  # string # Path to cfg folder
  cfg_folder="$HOME/.steam/steam/steamapps/common/Left 4 Dead 2/left4dead2/cfg"

  # string # Name of the file to write the command to (must be unique)
  cfg_file='sander.cfg'

  # string # Demo name with default prefix: autorec_2023-06-04-12-53-04.dem
  demo_prefix='autorec_'

  # string # Start refreshing the timestamp when this process is found
  process_name='hl2_linux'

  # integer # Check for the process every X seconds
  check_for_games='30'

  # integer # Refresh the timestamp every X seconds
  refresh_command='10'
}

help_message() {
  echo "Usage: ${0##*/} [options]"
  echo "Source engine demo recording helper."
  echo
  echo "Options:"
  echo "  -e, --edit       Edit the script and exit."
  echo "  -h, --help       Display help and exit."
  echo "  -v, --version    Show version and exit."
  echo
  echo "Customizations can be applied inside the script in the 'settings' function."
}

bash_error() { echo -e "${cred}$1${cstop} ${@:2}"; }
bash_warn() { echo -e "${cyellow}$1${cstop}" ${@:2}; }
bash_success() { echo -e "${cgreen}$1${cstop}" ${@:2}; }
bash_info() { echo -e "${cblue}$1${cstop} $2 ${cblue}$3${cstop} ${@:4}"; }

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

main() {

  version=2.0.0

  cred="\033[31m"
  cgreen="\033[32m"
  cyellow="\033[33m"
  cblue="\033[34m"
  cstop="\033[0m"

  settings

  cfg_folder="${cfg_folder%/}"
  [[ $cfg_file != *.cfg ]] && cfg_file="${cfg_file}.cfg"
  cfg_path="${cfg_folder}/${cfg_file}"

  # Parse all positional parameters
  while [[ "$1" != "" ]]; do
    case "$1" in

      '-e'|'--edit')
        [[ ! $EDITOR ]] && echo '$EDITOR variable not found!' && exit 127
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

      *)
        echo "Invalid option: \"$1\""
        help_message
        exit 1
        ;;

    esac
    shift
  done

  for int in $check_for_games $refresh_command; do
    if [[ ! $int =~ ^[0-9]+$ ]] || [[ $int -le 0 ]]; then
      desktop_notification "ERROR" "Invalid integer in settings."
      bash_error "ERROR: Invalid integer in settings" \"$int\"
      exit 22
    fi
  done

  if [[ ! -d $cfg_folder ]]; then
    desktop_notification "ERROR" "Directory not found."
    bash_error "ERROR: Directory not found" \"$cfg_folder\"
    exit 2
  elif [[ ! -w $cfg_folder ]]; then
    desktop_notification "ERROR" "Cannot access directory."
    bash_error "ERROR: Directory is read-only" \"$cfg_folder\"
    exit 13
  fi

  if [[ -f $cfg_path ]]; then
    desktop_notification "ERROR" "Not allowed to overwrite \"$cfg_file\"."
    bash_error "ERROR: File exists" \"$cfg_path\"
    exit 17
  else
    :>"$cfg_path"
    bash_success "Config set:" \"$cfg_path\"
  fi

  trap "cleanup_dirty_exit" SIGINT SIGTERM

  # Run the program
  bash_success "Looking for:" \"$process_name\"

  while [[ -w $cfg_path ]]; do
    if pgrep -x $process_name > /dev/null 2>&1; then
      if [[ ! -s $cfg_path ]]; then
        bash_success "Process \"$process_name\" found!"
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
          bash_info "Looking for" "\"$process_name\"" "every" "${check_for_games}s"
        else
          bash_info "Updating timestamp in" "\"$cfg_file\"" "every" "${refresh_command}s"
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

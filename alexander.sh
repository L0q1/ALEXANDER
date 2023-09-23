#!/bin/bash

##################################################################################################################
# ALEXANDER - A Linux Equivalent of Source Auto-Named Demo Recorder
# Bash script that writes "record <timestamp>" to set .cfg file every X seconds when the game is running
# Config can then be executed during the game to start recording a demo with unique timestamp
#
# Inspired by Source Auto-Named Demo Recorder (SANDER) by Sander Dijkstra (https://www.dyxtra.com/sander)
##################################################################################################################

# Settings
cfg_folder="$HOME/.steam/steam/steamapps/common/Left 4 Dead 2/left4dead2/cfg" # string # path to cfg folder
cfg_name='sander.cfg' # string # name of the file to write the command to (whole file will be overwritten!)
demo_prefix='autorec_' # string # example of a demo name with default prefix: autorec_2023-06-04-12-53-04.dem
process_name='hl2_linux' # string # start refreshing the timestamp when this process is found running
check_for_games='30' # integer # check for the process specified above every X seconds
refresh_command='10' # integer # refresh the timestamp every X seconds if process is running

# Shell colors
cred="\e[31m"
cgreen="\e[32m"
cyellow="\e[33m"
cblue="\e[34m"
cstop="\e[0m"

# FUNCTION: bash messages
bash_error() { echo -e "${cred}$1${cstop} $2"; }
bash_warn() { echo -e "${cyellow}$1${cstop} $2"; }
bash_success() { echo -e "${cgreen}$1${cstop} $2"; }
bash_info() { echo -e "${cblue}$1${cstop} $2"; }

# FUNCTION: send libnotify notification to desktop if possible
desktop_notification() {
  if command -v notify-send > /dev/null 2>&1; then
    notify-send -a ALEXANDER "$1" "$2"
  fi
}

# CHECK: is ALEXANDER already running
if pidof -x "$(basename -- "$0")" -o $$ > /dev/null; then
  desktop_notification "ALEXANDER is already running!" "Process ID: $(pidof -x "$(basename -- "$0")" -o $$)"
  bash_warn "The script is already running." "PID: $(pidof -x "$(basename -- "$0")" -o $$)"
  exit 114
fi

# FUNCTION: is integer and 0<
is_valid_int() {
  case $1 in
    ''|*[!0-9]*|0)
      desktop_notification "ERROR" "'$2' has invalid value."
      bash_error "ERROR: '$2' is assigned an invalid value:" "$1"
      exit 22 ;;
    *) ;;
  esac
}

# CHECK: are check_for_games and refresh_command present and valid
is_valid_int $check_for_games check_for_games
is_valid_int $refresh_command refresh_command

# FIX: remove last '/' in directory path if present
cfg_folder=${cfg_folder%/}

# FIX: append .cfg extension to cfg_name if absent
if [[ $cfg_name != *.cfg ]]; then
  cfg_name=$cfg_name.cfg
fi

# Set up full path to the config
cfg_path=$cfg_folder/$cfg_name

# CHECK: does config directory exist
if [[ ! -d $cfg_folder ]]; then
  desktop_notification "ERROR" "Directory not found."
  bash_error "ERROR: Directory not found:" "$cfg_folder"
  exit 2
fi

# CHECK: set config file / create if doesn't exist
if [[ -s $cfg_path ]]; then
  desktop_notification "ERROR" "'$cfg_name' exists but is not empty."
  bash_error "ERROR: Config exists but is not empty:" "$cfg_path"
  exit 27
elif [[ -w $cfg_path ]]; then
  bash_success "Config set:" "$cfg_path"
elif [[ ! -f $cfg_path ]]; then
  bash_warn "Config file '$cfg_name' not found. Creating..."
  if [[ -w $cfg_folder ]]; then
    :>"$cfg_path"
    bash_success "Done!"
    bash_success "Config set:" "$cfg_path"
  else
    desktop_notification "ERROR" "Cannot create '$cfg_name'."
    bash_error "ERROR: Directory is read-only:" "$cfg_folder"
    exit 13
  fi
else
  desktop_notification "ERROR" "Cannot write to '$cfg_name'."
  bash_error "ERROR: Config is read-only:" "$cfg_path"
  exit 13
fi

# FUNCTION: update timestamp and write command to config
write_command() {
  timestamp=$(date +"%Y-%m-%d-%H-%M-%S")
  cfg_command="record $demo_prefix$timestamp"
  echo $cfg_command > "$cfg_path"
}

# FUNCTION: cleanup on dirty exit
function dirty_exit() {
  desktop_notification "Warning!" "Script terminated."
  bash_warn "\nScript terminated."
  :>"$cfg_path"
  exit 130
}

# Perform cleanup on SIGINT (Ctrl+C) and SIGTERM ('End Process...')
trap "dirty_exit" 2 15

# Start scanning & user input
bash_success "ALEXANDER is looking for the process:" "$process_name"
while [[ -w $cfg_path ]]; do
  if pgrep -x $process_name > /dev/null; then
    write_command
    work_var=1
    read -t $refresh_command user_input
  else
    :>"$cfg_path"
    work_var=0
    read -t $check_for_games user_input
  fi

  case $user_input in
    'help')
      bash_info "help" "Print available commands."
      bash_info "status" "Check script status."
      bash_info "stop, quit, exit" "Stop the script." ;;
    'status')
      if [[ $work_var == 0 ]]; then
        bash_info "LOOKING FOR:" "$process_name"
      else
        bash_info "WRITING TO:" "$cfg_path"
      fi ;;
    'stop'|'quit'|'exit')
      bash_success "Script stopped."
      :>"$cfg_path"
      exit 0 ;;
    '') ;;
    *) echo "Type 'help' for available commands." ;;
  esac
done

# Other exit reasons
if [[ ! -f $cfg_path ]]; then
  desktop_notification "Warning!" "Config deleted."
  bash_warn "Config deleted."
  exit 2
elif [[ ! -w $cfg_path ]]; then
  desktop_notification "Warning!" "Config permissions changed."
  bash_warn "Config permissions changed."
  exit 13
else
  desktop_notification "Exiting!" "Reason unknown."
  bash_warn "Exiting. Reason unknown."
  :>"$cfg_path"
  exit 1
fi

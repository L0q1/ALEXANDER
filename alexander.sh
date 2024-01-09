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
cred="\033[31m"
cgreen="\033[32m"
cyellow="\033[33m"
cblue="\033[34m"
cstop="\033[0m"

# FUNCTION: bash messages
bash_error() { echo -e "${cred}$1${cstop} $2"; }
bash_warn() { echo -e "${cyellow}$1${cstop} $2"; }
bash_success() { echo -e "${cgreen}$1${cstop} $2"; }
bash_info() { echo -e "${cblue}$1${cstop} $2 ${cblue}$3${cstop} $4"; }

# FUNCTION: send libnotify notification to desktop if possible
desktop_notification() {
  if command -v notify-send > /dev/null 2>&1; then
    notify-send -a ALEXANDER "$1" "$2"
  fi
}

# CHECK: is ALEXANDER already running
if pidof -x "$(basename -- $0)" -o $$ > /dev/null 2>&1; then
  desktop_notification "ALEXANDER is already running!" "Process ID: $(pidof -x "$(basename -- $0)" -o $$)"
  bash_warn "This script is already running. PID:" "$(pidof -x "$(basename -- $0)" -o $$)"
  exit 114
fi

# FUNCTION: is integer and 0<
is_valid_int() {
  case $1 in
    ''|*[!0-9]*|0)
      desktop_notification "ERROR" "Invalid value '$1' in '$2' setting.\nInsert a number (in seconds) instead."
      bash_error "ERROR: '$2' is assigned an invalid value:" "$1"
      exit 22 ;;
    *) ;;
  esac
}

# CHECK: are variables present and valid
is_valid_int $check_for_games check_for_games
is_valid_int $refresh_command refresh_command

# Remove last '/' in directory path if present
cfg_folder=${cfg_folder%/}

# Append '.cfg' extension to config name if absent
if [[ $cfg_name != *.cfg ]]; then
  cfg_name=$cfg_name.cfg
fi

# Set up full path to the config
cfg_path=$cfg_folder/$cfg_name

# CHECK: does config directory exist
if [[ ! -d $cfg_folder ]]; then
  desktop_notification "ERROR" "Config directory not found."
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
dirty_exit() {
  desktop_notification "Warning!" "Script terminated."
  bash_warn "\nScript terminated."
  :>"$cfg_path"
  exit 130
}

# Perform cleanup on SIGINT (Ctrl+C) and SIGTERM ('End Process...')
trap "dirty_exit" 2 15

# Start scanning & user input
work_var=0
bash_success "Looking for the process:" "$process_name"
while [[ -w $cfg_path ]]; do
  if pgrep -x $process_name > /dev/null; then
    if [[ $work_var == 0 ]]; then
      bash_success "Process found!"
      work_var=1
    fi
    write_command
    read -r -t $refresh_command user_input
  else
    if [[ $work_var == 1 ]]; then
      bash_warn "Process lost."
      :>"$cfg_path"
      work_var=0
    fi
    read -r -t $check_for_games user_input
  fi

  case $user_input in
    help)
      bash_info "help             " "print all available commands"
      bash_info "status           " "check script status"
      bash_info "quit, stop, exit " "stop the script" ;;
    status)
      if [[ $work_var == 0 ]]; then
        bash_info "Looking for" "$process_name" "every" "$check_for_games"s
      else
        bash_info "Found" "$process_name"
        bash_info "Updating timestamp in" "$cfg_name" "every" "$refresh_command"s
      fi ;;
    quit|stop|exit)
      bash_success "Script stopped."
      :>"$cfg_path"
      exit 0 ;;
    '') ;;
    *) bash_info "Type" "help" "for a list of available commands." ;;
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

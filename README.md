# What is it?
A demo recording helper for Source games, inspired by [SANDER](https://dyxtra.github.io/sander). Written in bash.

# How does it work?
1. Perform a bunch of checks to make sure nothing unexpected happens
2. Create empty .cfg file inside game's .../cfg directory
3. Run a loop that looks for specified game's process(es)
4. When process is found, start writing a record command with unique timestamp to the .cfg file
5. When process is lost, wipe the .cfg file so user doesn't accidentally overwrite the last recorded demo

# Installation
1. Download the script & make it executable
   - `git clone https://github.com/L0q1/alexander`
   - `wget 'https://raw.githubusercontent.com/L0q1/alexander/master/alexander.sh' -O alexander.sh && chmod +x alexander.sh`
   - `curl 'https://raw.githubusercontent.com/L0q1/alexander/master/alexander.sh' > alexander.sh && chmod +x alexander.sh`
2. *(optional)* Open the script with text editor and edit **settings()** function

## Dependencies
- bash
- *(optional)* libnotify - desktop notifications

# Usage
1. Launch the script specifying the game you want to monitor (lowercase abbreviation)
```
./alexander.sh l4d2
```

2. Open the in-game console and execute the config created by ALEXANDER to start recording
```
exec sander.cfg
```

3. *(optional)* Assign config execution to your scoreboard key for convenience
```
alias "+showexec" "+showscores; exec sander.cfg"
alias "-showexec" "-showscores"
bind "TAB" "+showexec"
```

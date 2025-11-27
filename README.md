# What is it?
[SANDER](https://dyxtra.github.io/sander) for Linux. Written in bash.

# How does it work?
1. Performs a bunch of checks to make sure nothing unexpected happens
2. Creates empty .cfg file inside game's .../cfg directory
3. Runs a loop that looks for specified game's process(es)
4. When process is found, starts writing a record command with unique timestamp to its .cfg file
5. When process is lost, wipes the .cfg file so user doesn't accidentally overwrite the last demo

# Installation
[Download a stable release](../../tags), or:
```
git clone https://github.com/L0q1/alexander
```
```
wget 'https://raw.githubusercontent.com/L0q1/alexander/master/alexander.sh' -O alexander.sh && chmod +x alexander.sh
```
```
curl 'https://raw.githubusercontent.com/L0q1/alexander/master/alexander.sh' > alexander.sh && chmod +x alexander.sh
```

## Dependencies
- bash
- *(optional)* libnotify - desktop notifications

# Usage
0. *(optional)* Open the script and edit the **settings()** function
```
./alexander.sh -e
```

1. Launch the script specifying the game you want to monitor (lowercase abbreviation)
```
./alexander.sh l4d2
```

2. Open the in-game console and execute the config created by ALEXANDER to start recording
```
exec sander.cfg
```

or assign config execution to your scoreboard key for convenience
```
alias "+showexec" "+showscores; exec sander.cfg"
alias "-showexec" "-showscores"
bind "TAB" "+showexec"
```

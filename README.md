# What is it?
[SANDER](https://www.dyxtra.com/sander) for Linux. Written in bash.

# What does it do?
It tries to create its own, empty .cfg file (**sander.cfg** by default).

Then it checks every 30 seconds if specified in the script process is running.

If it finds the process, it starts writing a record command with unique timestamp to **sander.cfg** every 10 seconds.

When the script is stopped, **sander.cfg** is wiped to prevent any accidental demo overwrites.

# Installation
1. Download the script
   - `git clone https://github.com/L0q1/ALEXANDER`
   - `wget 'https://raw.githubusercontent.com/L0q1/ALEXANDER/master/alexander.sh' -O alexander.sh`
   - `curl 'https://raw.githubusercontent.com/L0q1/ALEXANDER/master/alexander.sh' > alexander.sh`
2. Make it executable *(if not using git clone)*
   - `chmod +x alexander.sh`

Script comes preconfigured for Left 4 Dead 2.

# Usage
Execute the script.

To start recording a demo, open the in-game console and execute the config created by ALEXANDER.
```
exec sander.cfg
```

If you want to record all your matches, assign the config execution to your scoreboard key.
```
alias "+showexec" "+showscores; exec sander.cfg"
alias "-showexec" "-showscores"
bind "TAB" "+showexec"
```

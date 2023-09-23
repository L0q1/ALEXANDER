# What is it?
[SANDER](https://www.dyxtra.com/sander) but for Linux.

# What does it do?
First it tries to create its own, empty .cfg file (**sander.cfg** by default).

Then, every 30 seconds it checks if specified in the script game process is currently running.

If it finds the process it is looking for, it starts writing a record command to **sander.cfg**.

Timestamp included in the command refreshes every 10 seconds to prevent new demos from overwriting old ones.

When the script is closed it wipes **sander.cfg** to prevent any potential demo overwrites.

# Installation
1. Download the script
   - `git clone https://github.com/L0q1/ALEXANDER ~/Downloads/ALEXANDER`
2. Make it executable
   - `chmod +x alexander.sh`

You can place the script wherever you want.

Set the script to launch on system boot if you want to always be ready to record.

# Usage
Execute the script.

To start recording a demo, open the in-game console and execute the config created by ALEXANDER.
```
exec sander.cfg
```

If you want to record all your matches, assign the config execution to your scoreboard key.

Code below does exactly that, feel free to put it in your autoexec.
```
alias "+showexec" "+showscores; exec sander.cfg"
alias "-showexec" "-showscores"
bind "TAB" "+showexec"
```

# Disclaimer
I have never seen SANDER's source code.

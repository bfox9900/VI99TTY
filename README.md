# VI99 TTY
### A VI style editor over RS232 for TI-99 computer

This editor was an experiment to see if we could get 80 column editing 
on the TI-99 simply by using an RS232 connection and a terminal emulator.
This version is based on the previous VI99 editor but is a significant rewrite.  Like VI99 is wakes up in the VI99 shell which gives the user 
a few shell commands:

- ls to see a filename only directory
- ls-l  to see a directory with file types and size in sectors 
- vi <filename> to edit a file
- view <filename> to see a file in read-only mode. (save is disabled)
- cd <device> to change the default disk for the shell
- rm <filename> to delete a file (permanently) with an "Are you sure?"


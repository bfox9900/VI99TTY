# VI99 TTY
### A VI style editor over RS232 for TI-99 computer

This editor was an experiment to see if we could get 80 column editing 
on the TI-99 simply by using an RS232 connection and a terminal emulator.
This version is based on the previous VI99 editor but is a significant rewrite.  Like VI99 is wakes up in the VI99 shell which gives the user 
a few shell commands:

- ls [dskx.] to see a filename only directory. (disk name is optional)
- ls-l [dskx.] to see a directory with file types and size in sectors 
- vi <filename> to edit a file
- view <filename> to see a file in read-only mode. (save is disabled)
- cd <device> to change the default disk for the shell
- rm <filename> to delete a file (permanently) with an "Are you sure?"

The editor behaves very much like VI but the entire feature set cannot
fit into the 24K of program space on the TI-99 so VI99 TTY provides the
most commonly used commands and features. 

See VI99MANPAGE.TXT for all the available features and commands. 


CLI-Gist-Runner
===============

Command Line Interface to execute scripts directly from Gist

_Warning: Executing code from Gists can be dangerous. Use at your own risk._

===============

Install CLI-Gist-Runner by executing this command:

`curl -s https://raw.githubusercontent.com/koter84/CLI-Gist-Runner/master/install.sh | bash`

===============

## Command-Line-Arguments
you can use gist to execute gists directly from github! commands are autocompleted with realtime information from github
it's possible to execute the commands on remote servers with rsync and ssh and you can pass arguments through to the called script

some command examples for use with the 'gist' command
- your own gist ` > gist my-script.php`
- a starred gist ` > gist -s starred-script.rb`
- someone else's gist ` > gist -o user public-script.pl`
- run on a remote machine over SSH ` > gist -r user@server my-script.sh`
- execute with sudo ` > gist -x public-script.pl`
- execute with watch ` > gist -w5 script.sh`
- a gist with extra arguments ` > gist my-script.php --my-script-option`
- upload a file or directory to gist ` > gist -u dir/` or ` > gist -u file.sh`
- upload output from another command to gist ` > cmd_with_output | gist` (-u not needed)
- edit a gist locally ` > gist -e script-to-edit.py`

you can update the gist-script with ` > gist --upgrade`

## Environment Variables
when you run a script through gist you can use the following environment variables in your script
- GIST_PWD - the working dir from where the gist command was called

## Hiding files from CLI-Gist-Runner
If you have a gist with multiple files, for instance because of a library you include in the main script, it's nice to hide the lib
from autocomplete. To do this, you name the library file with ~~ at the beginning of the filename, like `~~mylibrary.sh`

## ToDo
### First
- [ ] check for fail-messages and/or errors in gitcurl
- [ ] --upgrade should check installed location of completion file

### Later
- [ ] upload a update to an existing gist ` > gist -U file.sh` (or check for a file with the same name when uploading?)

## ToRead
- (1) http://stedolan.github.io/jq/tutorial/
- (2) http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
- (3) https://developer.github.com/v3/auth/#working-with-two-factor-authentication
- (4) http://anonscm.debian.org/cgit/bash-completion/bash-completion.git/plain/README


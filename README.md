CLI-Gist-Runner
===============

Command Line Interface to execute scripts directly from Gist

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
- a gist with extra arguments ` > gist my-script.php --my-script-option`
- upload a file or directory to gist ` > gist -u dir/` or ` > gist -u file.sh`
- upload output from another command to gist ` > cmd_with_output | gist` (-u not needed)

you can update the gist-script with ` > gist --upgrade`

## ToDo
### First
- [ ] upload should by default only use the last part of the filename (not the whole path)
- [ ] check for fail-messages and/or errors in gitcurl
- [ ] --upgrade should check installed location of completion file

### Later
- [ ] edit a gist ( clone the repo, change files, commit, push... ( git clone git@github.com:gist_id.git ) ) ` > gist -e edit-script.py`
- [ ] upload a update to an existing gist ` > gist -U file.sh` (or check for a file with the same name when uploading?)

## ToRead
- (1) http://stedolan.github.io/jq/tutorial/
- (2) http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
- (3) https://developer.github.com/v3/auth/#working-with-two-factor-authentication
- (4) http://anonscm.debian.org/cgit/bash-completion/bash-completion.git/plain/README


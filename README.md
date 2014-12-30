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

## ToRead
- http://stedolan.github.io/jq/tutorial/
- http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
- https://developer.github.com/v3/auth/#working-with-two-factor-authentication
- http://anonscm.debian.org/cgit/bash-completion/bash-completion.git/plain/README

## ToDo
### First
- check for fail-messages and/or errors in gitcurl

### Later
- caching --ac-* (how long to cache? and which ones?)
- uploading 1 or more files to gist ` > gist -u new-dir/` or ` > gist -u new-file.sh`

### Decide
- autocomplete for subscripts ?
- settings file ?
- edit a gist ( download, open file in editor, upload on close ) ` > gist -e edit-script.py`

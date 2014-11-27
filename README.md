CLI-Gist-Runner
===============

Command Line Interface to execute scripts directly from Gist

===============

Install CLI-Gist-Runner by executing this command: ( ToDo / Work-In-Progress )

`curl -s https://raw.githubusercontent.com/koter84/CLI-Gist-Runner/master/gist.sh | bash`

===============

## Command-Line-Arguments
how to handle different options on the command line...
define how to parse for other people's gists, starred gists etc.
what to do with each filetype, show a file before execution? or just run it...

by default 'gist.sh' should be 'gist'
- your own gist ` > gist my-script.php`
- a starred gist ` > gist -s starred-script.rb`
- someone else's gist ` > gist -o user public-script.pl`

## ToRead
- http://stedolan.github.io/jq/tutorial/
- http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
- https://developer.github.com/v3/auth/#working-with-two-factor-authentication

## ToDo
### First
- parse command line arguments
- cli-arguments for autocomplete should start with --ac-* so it's easy to recognise
- download/execute gist-scripts

### Later
- download/install gist.sh ( or save current script which is run from a pipe? )
- install/symlink gist-command in PATH
- possibility to load/run someone else's scripts
- autocomplete stop when a script is selected
- check for fail-messages and/or errors in gitcurl
- version number information in some way

### Decide
- option to pre-load all scripts or to download on demand
- when to update the autocomplete-file ( --update ?? )
- include install in default gist.sh or create separate install.sh
- autocomplete for subscripts
- settings file

### Investigate
- gist with multiple files, which could include/link to one-another, how to handle?
- edit a gist ( download, open file in editor, upload on close ) ` > gist -e edit-script.py`
- run a gist on a remote machine over SSH ` > gist -r user@server remote-script.sh`

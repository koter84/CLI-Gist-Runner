CLI-Gist-Runner
===============

Command Line Interface to execute scripts directly from Gist

===============

Install CLI-Gist-Runner by executing this command:

`curl -s https://raw.githubusercontent.com/koter84/CLI-Gist-Runner/master/install.sh | bash`

===============

## Command-Line-Arguments
how to handle different options on the command line...
define how to parse for other people's gists, starred gists etc.
what to do with each filetype, show a file before execution? or just run it...

by default 'gist.sh' should be 'gist'
- your own gist ` > gist my-script.php`
- a starred gist ` > gist -s starred-script.rb`
- someone else's gist ` > gist -o user public-script.pl`
- execute with sudo ` > gist -? public-script.pl` (don't know which argument to use for this, obvious -s is already taken) (for testing -x)

## ToRead
- http://stedolan.github.io/jq/tutorial/
- http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
- https://developer.github.com/v3/auth/#working-with-two-factor-authentication
- http://anonscm.debian.org/cgit/bash-completion/bash-completion.git/plain/README

## ToDo
### First
- run a gist on a remote machine over SSH ` > gist -r user@server remote-script.sh`
- caching --ac-* (how long to cache? and which ones?)

### Later
- autocomplete stop when a script is selected
- check for fail-messages and/or errors in gitcurl

### Decide
- autocomplete for subscripts
- settings file ?

### Investigate
- edit a gist ( download, open file in editor, upload on close ) ` > gist -e edit-script.py`


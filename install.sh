#!/bin/bash

## Command Check ##
for cmd in 'bash' 'git' 'curl' 'jq'
do
	which $cmd > /dev/null 2>&1
	if [ "$?" != "0" ]
	then
		echo "Command not found: $cmd"
		cmd_not_found="true"
	fi
done
if [ "$cmd_not_found" != "" ]
then
	echo "some commands not found"
	exit
fi

## $PATH Check
if [[ :$PATH: == *:"/bin":* ]]
then
	gist_path="/bin"
fi
if [[ :$PATH: == *:"/usr/bin":* ]]
then
	gist_path="/usr/bin"
fi
if [[ :$PATH: == *:"/usr/local/bin":* ]]
then
	gist_path="/usr/local/bin"
fi
if [[ $(which gist) == */gist ]]
then
	gist_path="$(dirname $(which gist))"
fi
if [ "$gist_path" == "" ]
then
	echo "no good directory found in $PATH"
	exit
fi

## Completions Check
gist_comp1=$(pkg-config --variable=completionsdir bash-completion)
gist_comp2=$(pkg-config --variable=compatdir bash-completion)
if [ "$gist_comp2" != "" ] && [ -d "$gist_comp2" ]
then
	gist_completionsdir="$gist_comp2"
fi
if [ "$gist_comp1" != "" ] && [ -d "$gist_comp1" ]
then
	gist_completionsdir="$gist_comp1"
fi
# ToDo - find existing completion file
if [ "$gist_completionsdir" == "" ]
then
	echo "no bash-completion dir found"
	exit
fi

## Get Latest Tag ##
version_remote_hash=$(curl -s "https://api.github.com/repos/koter84/CLI-Gist-Runner/tags" | jq '.[0].commit.sha' | sed 's/\"//g')

## Install ##
sudo wget -q -O $gist_path/gist https://raw.githubusercontent.com/koter84/CLI-Gist-Runner/$version_remote_hash/gist.sh
sudo chmod +x $gist_path/gist

sudo wget -q -O $gist_completionsdir/gist https://raw.githubusercontent.com/koter84/CLI-Gist-Runner/$version_remote_hash/completion.sh

## Setup ##
gist --setup


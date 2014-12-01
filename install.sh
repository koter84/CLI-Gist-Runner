#!/bin/bash

# Ask if user wants to install as root/sudo or just for the local user
echo -n "Do you want to install as root/sudo? [y/N]"
read sudo_install
if [ "$sudo_install" == "Y" ] || [ "$sudo_install" == "y" ]
then
	echo "run the installer with sudo..."
	exit
fi


## Command Check ##
for cmd in 'bash' 'curl' 'jq'
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
	echo "command not found, exit"
	exit
fi


## Install ##
# ?
# - download gist.sh to $PATH
# - download complete.sh to:
#  - pkg-config --variable=completionsdir bash-completion
#  - pkg-config --variable=compatdir bash-completion
#  - or just for current user in: ~/.bash_completion


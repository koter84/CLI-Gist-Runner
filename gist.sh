#!/bin/bash

## Options Parser ##
while [[ $# -ge 1 ]]
do
	case $1 in
		--update)
			gistopt_update=1
		;;
		--upgrade)
			gistopt_upgrade=1
		;;
		--version)
			echo "v0.9.1"
			exit
		;;
		-h|--help)
			echo ""
			echo "CLI-Gist-Runner"
			echo "https://github.com/koter84/CLI-Gist-Runner"
			echo ""
			echo "    --update               ? force-update autocomplete with latest gists"
			echo "    --upgrade              upgrade gist.sh (this script)"
			echo "    --version              version information"
			echo "    --help                 this help text"
			echo ""
			echo "these options are used by bash-autocompletion so you don't need root to update the autocomplete-files"
			echo "    -g --listgist [user]    output a list of gists for [user], default for authenticated user"
			echo "    -s --liststarred        output a list of starred gists for authenticated user"
#			echo "    -u --listuser %user%    output a list of users from github"
			echo ""
			exit
		;;
		-g|--listgist)
			gistopt_listgist=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gistopt_listgist_user="$2"
				shift
			fi
		;;
		-s|--liststarred)
			gistopt_listgist=1
			gistopt_listgist_starred=1
		;;
		-u|--listuser)
			echo "the option -u or --listuser is not working yet"
			exit
			gistopt_listuser=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gistopt_listuser_user="$2"
				shift
			fi
		;;
		*)
			echo "unknown option \"$1\" use --help to list possible options"
			exit
		;;
	esac
	shift
done


## Variables and Constants ##
url="https://api.github.com"
curl_opts="-s -H 'User-Agent: CLI-Gist-Runner'"


## Functions ##
function gitcurl {

	local gitcurl_tmp=`curl $curl_opts -u $token:x-oauth-basic $url$1`
#	echo "$gitcurl_tmp"

#todo
#	echo "$gitcurl_tmp" | jq '.error' ????

#	local gitcurl="$gitcurl_tmp"
	echo $gitcurl_tmp
}


## Command Check ##
# only on install/setup
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


## Initialisation ##
if [ -f ~/.gisttoken ]
then
	token=$(cat ~/.gisttoken)
else
	echo -n "Do you want to manually generate a Personal-Access-Token [y/N]? "
	read manual_token
	if [ "$manual_token" == "Y" ] || [ "$manual_token" == "y" ]
	then
		echo "Go to https://github.com/settings/tokens/new to generate a token, be sure to select the \"gist\" scope!"
		echo -n "GitHub.com Personal-Access-Token: "
		read token
	else
		echo -n "GitHub.com Username: "
		read username

		token_curl=`curl $curl_opts -u $username --data '{ "scopes": [ "gist" ], "note": "CLI Gist Runner", "note_url": "https://github.com/koter84/CLI-Gist-Runner" }' $url/authorizations`
		token=`echo "$token_curl" | jq '.token' | sed 's/\"//g'`
	fi

	token_check=`echo $(gitcurl /user) | jq '.login' | sed 's/\"//g'`
	if [ "$token_check" != "" ]
	then
		echo $token > ~/.gisttoken
	else
		echo "Failed to connect to GitHub.com with OAuth Token..."
		exit
	fi
fi


## Install ##
# only on install/setup
# ?


## AutoCompletion ##
# only on install/setup
if [ "$gistopt_update" == "1" ]
then
#	autocomplete=`echo $(gitcurl /gists) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'`
	cat <<EOT > /tmp/gist_autocomplete
_gist_runner()
{
    local cur prev opts gists
#    COMPREPLY=()
    cur="\${COMP_WORDS[COMP_CWORD]}"
    prev="\${COMP_WORDS[COMP_CWORD-1]}"

    opts="--help --version --update --upgrade --listgist --liststarred"
    gists=\$(/data/GitHub/CLI-Gist-Runner/gist.sh --listgist)

    if [[ \${cur} == -* ]] ; then
        COMPREPLY=( \$(compgen -W "\${opts}" -- \${cur}) )
    else
        COMPREPLY=( \$(compgen -W "\${gists}" -- \${cur}) )
    fi
    return 0
}
complete -F _gist_runner gist.sh
complete -F _gist_runner ./gist.sh
EOT
	#. /tmp/gist_autocomplete
fi


## The Core ##

if [ ! -f /tmp/cligistrunner_listgist ] || [ "$gistopt_update" == "1" ]
then
	echo $(gitcurl /gists) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g' > /tmp/cligistrunner_listgist
fi

if [ "$gistopt_listgist" == "1" ]
then
	if [ "$gistopt_listgist_user" != "" ]
	then
		echo $(gitcurl /users/$gistopt_listgist_user/gists) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	elif [ "$gistopt_listgist_starred" == "1" ]
	then
		echo $(gitcurl /gists/starred) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	else
		cat /tmp/cligistrunner_listgist
	fi
fi

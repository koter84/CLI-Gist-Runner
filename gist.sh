#!/bin/bash

## Variables and Constants ##
url="https://api.github.com"
curl_opts="-s -H 'User-Agent: CLI-Gist-Runner'"


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
			echo " these options are used by bash-autocompletion so you don't need to be root to update the autocomplete-file"
			echo "    --ac-gist [user]    output a list of gists for [user], default for authenticated user"
			echo "    --ac-starred        output a list of starred gists for authenticated user"
			echo "    --ac-user %user%    output a list of users from github"
			echo ""
			exit
		;;
		--ac-gist)
			gistac_gist=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gistac_gist_user="$2"
				shift
			fi
		;;
		--ac-starred)
			gistac_gist=1
			gistac_gist_starred=1
		;;
		--ac-user)
			echo "the option --ac-user is not working yet"
			exit
			gistac_user=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gistac_user_name="$2"
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


## Functions ##
function gitcurl {

	local gitcurl_tmp=`curl $curl_opts -u $token:x-oauth-basic $url$1`
#	echo "$gitcurl_tmp"

#todo
#	echo "$gitcurl_tmp" | jq '.error' ????

#	local gitcurl="$gitcurl_tmp"
	echo $gitcurl_tmp
}


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


## The Core ##

if [ ! -f /tmp/cligistrunner_listgist ] || [ "$gistopt_update" == "1" ]
then
	echo $(gitcurl /gists) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g' > /tmp/cligistrunner_listgist
fi

if [ "$gistac_gist" == "1" ]
then
	if [ "$gistac_gist_user" != "" ]
	then
		echo $(gitcurl /users/$gistac_gist_user/gists) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	elif [ "$gistac_gist_starred" == "1" ]
	then
		echo $(gitcurl /gists/starred) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	else
		cat /tmp/cligistrunner_listgist
	fi
fi


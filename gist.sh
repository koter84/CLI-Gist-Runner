#!/bin/bash

## Variables and Constants ##
url="https://api.github.com"
curl_opts="-s -H 'User-Agent: CLI-Gist-Runner'"


## Options Parser ##
while [[ $# -ge 1 ]]
do
	case $1 in
		--upgrade)
			echo "the --upgrade option is not yet implemented"
			gistopt_upgrade=1
			exit
		;;
		--version)
			echo "v0.9.2"
			exit
		;;
		-h|--help)
			echo ""
			echo "CLI-Gist-Runner"
			echo "https://github.com/koter84/CLI-Gist-Runner"
			echo ""
			echo "$0 [options] [script-name]"
			echo ""
			echo "    -o username         execute another user's gist"
			echo "    -r user@server      execute gist on remote server via ssh"
			echo "    -s                  execute a starred gist"
			echo "    -x                  execute gist with sudo"
			echo ""
			echo "    --upgrade           upgrade gist.sh (this script)"
			echo "    --version           version information"
			echo "    --help              this help text"
			echo ""
			echo " these options are used by bash-autocompletion so you don't need to be root to update the autocomplete-file"
			echo "    --ac-test           execute a couple of --ac-* actions to get a timing"
			echo "    --ac-opts           output a list of arguments that gist accepts"
			echo "    --ac-gist [user]    output a list of gists for [user], default for authenticated user"
			echo "    --ac-starred        output a list of starred gists for authenticated user"
			echo "    --ac-user %user%    output a list of users from github"
			echo ""
			exit
		;;
		-o)
			gist_otheruser=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gist_otheruser_name="$2"
				shift
			else
				echo "-o expects a github.com username"
				exit
			fi
		;;
		-r)
			gist_remote=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gist_remote_name="$2"
				shift
			else
				echo "-r expects a remote server to connect to"
				exit
			fi
		;;
		-s)
			gist_starred=1
		;;
		-x)
			gist_root=1
		;;
		--ac-test)
			if [ "$2" == "timed" ]
			then
				gistac_test=1
			else
				time $0 --ac-test timed
				exit
			fi
		;;
		--ac-opts)
			echo "-h -o -r -s -x --upgrade --version --help --ac-test --ac-opts --ac-gist --ac-starred --ac-user"
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
			gistac_user=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gistac_user_name="$2"
				shift
			else
				echo "--ac-user expects a github.com username"
				exit
			fi
		;;
		*)
			gist_command="$1"
			if [ "$2" != "" ]
			then
				shift
				# get remaining arguments and pass them through to gist_command
				gist_command_arguments="$@"
			fi
			break
		;;
	esac
	shift
done

if [ "$gist_command" == "" ] && [ "$gistac_gist" != "1" ] && [ "$gistac_user" != "1" ] && [ "$gistac_test" != "1" ]
then
	echo "you must give a command to execute"
	exit
fi

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


## AutoComplete ##

if [ "$gistac_test" == "1" ]
then
	# no github interaction with this command, no cache-ability
#	echo "> --ac-opts"
#	output=`$0 --ac-opts`

	echo "> --ac-gist"
	for i in "1 2 3 4 5" ; do
		output=`$0 --ac-gist`
	done
	echo "> --ac-starred"
	for i in "1 2 3 4 5" ; do
		output=`$0 --ac-starred`

	# not sure how usefull this is to test, mostly you'll be looking at your own scripts
#	echo "> --ac-user octo"
#	output=`$0 --ac-user octo`
#	echo -n ">> "
#	for user in $output
#	do
#		echo -n "$user "
#		output=`$0 --ac-gist $user`
#	done
	exit
fi

if [ "$gistac_gist" == "1" ]
then
	if [ "$gistac_gist_user" != "" ]
	then
		echo $(gitcurl /users/$gistac_gist_user/gists) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	elif [ "$gistac_gist_starred" == "1" ]
	then
		# ToDo - caching
		echo $(gitcurl /gists/starred) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	else
		# ToDo - caching
		echo $(gitcurl /gists) | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	fi
fi

if [ "$gistac_user" == "1" ]
then
	echo $(gitcurl /search/users?q=$gistac_user_name) | jq '.items[].login' | sed 's/\"//g' | sed 's/\n/ /g'
fi


## The Core ##

if [ "$gist_command" != "" ]
then

	if [ "$gist_starred" == "1" ]
	then
		check_cmd=`$0 --ac-starred|grep $gist_command`
		if [ "$check_cmd" != "$gist_command" ]
		then
			echo "command seems wrong"
			echo "$gist_command"
			echo "$check_cmd"
		fi

		# get the gist-id
		gist_id=`echo $(gitcurl /gists/starred) | jq '.[] | if .files[].filename == "'$gist_command'" then .id else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g'`

	elif [ "$gist_otheruser" == "1" ]
	then
		check_user=`$0 --ac-user $gist_otheruser_name|grep -e ^$gist_otheruser_name\$`
		if [ "$check_user" != "$gist_otheruser_name" ]
		then
			echo "otheruser seems wrong"
			echo "$gist_otheruser_name"
			echo "$check_user"
		fi

		check_cmd=`$0 --ac-gist $gist_otheruser_name|grep $gist_command`
		if [ "$check_cmd" != "$gist_command" ]
		then
			echo "command seems wrong"
			echo "$gist_command"
			echo "$check_cmd"
		fi

		# get the gist-id
		gist_id=`echo $(gitcurl /users/$gist_otheruser_name/gists) | jq '.[] | if .files[].filename == "'$gist_command'" then .id else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g'`

	else # your own gist

		check_cmd=`$0 --ac-gist|grep $gist_command`
		if [ "$check_cmd" != "$gist_command" ]
		then
			echo "command seems wrong"
			echo "$gist_command"
			echo "$check_cmd"
		fi

		# get the gist-id
		gist_id=`echo $(gitcurl /gists) | jq '.[] | if .files[].filename == "'$gist_command'" then .id else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g'`

	fi


	if [ "$gist_id" != "" ]
	then
		# make tmp-dir
		gist_tmp=`mktemp -dt cligist-XXXXXX`
		if [ ! -d $gist_tmp ]
		then
			echo "tmp-dir not created...."
			echo "$gist_tmp"
			exit
		fi

		# download all gist-files
		gist_files=`echo $(gitcurl /gists/$gist_id) | jq '.files[].raw_url' | sed 's/\"//g' | sed 's/\n/ /g'`
		for raw_url in $gist_files
		do
			file="$gist_tmp/$(basename $raw_url)"
			wget -q -O $file $raw_url
			chmod +x $file
		done

		# detect file-type
		gist_command_type=`echo $(gitcurl /gists/$gist_id) | jq '.files[] | if .filename == "'$gist_command'" then .type else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g'`

		# goto tmp-dir
		cd $gist_tmp

		# add extra arguments to command
		gist_command="$gist_command $gist_command_arguments"

		# build command to execute...
		case $gist_command_type in
		application/x-httpd-php)
			cmd="php $gist_command"
		;;
		application/x-sh)
			cmd="bash $gist_command"
		;;
		text/plain)
			cmd="cat $gist_command"
		;;
		*)
			echo "> command type not implemented: $gist_command_type"
			exit
		;;
		esac

		if [ "$gist_root" == "1" ]
		then
			cmd="sudo $cmd"
		fi

		# execute command
		if [ "$gist_remote" == "1" ]
		then
			#echo "> going remote: $gist_remote_name"
			rsync="rsync --recursive ./ $gist_remote_name:$gist_tmp"
			#echo "> cmd: $rsync"
			eval $rsync
			cmd="ssh $gist_remote_name 'cd $gist_tmp; $cmd; rm -r $gist_tmp'"
			#echo "> cmd: $cmd"
			eval $cmd
		else
			#echo "> cmd: $cmd"
			eval $cmd
		fi

		# remove tmp-dir
		rm -r $gist_tmp

	else
		echo "> problem! no gist-id..."
		exit
	fi
fi

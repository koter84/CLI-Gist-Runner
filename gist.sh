#!/bin/bash


## Catch input from a Pipe
if [[ $(tty) != /dev/* ]]
then
	# found pipe'd data, upload-mode
	gist_upload=1
	gist_upload_name=$(mktemp -t gist-XXXXXX)
	# move piped-data into file
	piped=$(cat < /dev/stdin > $gist_upload_name)
fi


## Variables and Constants ##
url="https://api.github.com"
curl_opts="-s -H 'User-Agent: CLI-Gist-Runner'"


## Options Parser ##
while [[ $# -ge 1 ]]
do
	case $1 in
		--upgrade)
			curl -s https://raw.githubusercontent.com/koter84/CLI-Gist-Runner/master/install.sh | bash
			exit
		;;
		--version)
			echo "v1.1.0"
			exit
		;;
		-h|--help)
			echo ""
			echo "CLI-Gist-Runner"
			echo "https://github.com/koter84/CLI-Gist-Runner"
			echo ""
			echo "$0 [options] [script-name] [options for your gist-script]"
			echo ""
			echo "    -o username         execute another user's gist"
			echo "    -r user@server      execute gist on remote server via ssh"
			echo "    -s                  execute a starred gist"
			echo "    -u file|directory   upload a file or directory to gist (default with piped input)"
			echo "    -x                  execute gist with sudo"
			echo "    -w[seconds]         execute a gist using watch"
			echo ""
			echo "    --upgrade           upgrade gist.sh (this script)"
			echo "    --version           version information"
			echo "    -h --help           this help text"
			echo "    --setup             setup and configure your GitHub-access-token"
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
		--setup)
			gist_setup=1
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
		-u)
			gist_upload=1
			if [[ "$2" != -* ]] && [ "$2" != "" ] && [ "$3" == "" ]
			then
				gist_upload_name="$2"
				shift
			else
				echo "-u expects 1 file or 1 directory to upload"
				exit
			fi
		;;
		-x)
			gist_root=1
		;;
		-w)
			gist_watch=5
		;;
		-w*)
			# strip -w from $1
			gist_watch=${1#-w}
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
			echo "-h -o -r -s -u -x -w --upgrade --version --help --ac-test --ac-opts --ac-gist --ac-starred --ac-user"
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
			if [[ "$1" == -* ]]
			then
				echo "unknown option $1"
				exit
			fi
			gist_command="$1"
			if [ "$2" != "" ]
			then
				shift
				# get remaining arguments and pass them through to gist_command
				gist_command_arguments="$*"
			fi
			break
		;;
	esac
	shift
done

if [ "$gist_command" == "" ] && [ "$gist_upload" != "1" ] && [ "$gistac_gist" != "1" ] && [ "$gistac_user" != "1" ] && [ "$gistac_test" != "1" ]
then
	echo "you must give a command to execute"
	$0 --help
	exit
fi


## Functions ##
function gist_dl
{
	local cmd="curl $curl_opts -u $token:x-oauth-basic $url$1"
	#echo "$cmd"
	local gist_tmp=$($cmd)

# ToDo - catching errors
#	echo "$gist_tmp" | jq '.error' ????

	echo $gist_tmp
}

function gist_ul
{
	echo "$1" > /tmp/gist_json_upload_file
	local cmd="curl $curl_opts -u $token:x-oauth-basic -X POST --data @/tmp/gist_json_upload_file $url/gists"
#	echo "$cmd"
	local gist_tmp=$($cmd)

# ToDo - catching errors
#	echo "$gist_tmp" | jq '.error' ????

	echo $gist_tmp
}

function gist_encode
{
	JSON_RAW=$(cat $1)
	JSON_RAW=${JSON_RAW//\\/\\\\} # \
	JSON_RAW=${JSON_RAW//\//\\\/} # /
	JSON_RAW=${JSON_RAW//\'/\\\'} # ' (not strictly needed ?)
	JSON_RAW=${JSON_RAW//\"/\\\"} # "
	JSON_RAW=${JSON_RAW//	/\\t} # \t (tab)
	JSON_RAW=${JSON_RAW//
/\\\n} # \n (newline)
	JSON_RAW=${JSON_RAW//^M/\\\r} # \r (carriage return)
	JSON_RAW=${JSON_RAW//^L/\\\f} # \f (form feed)
	JSON_RAW=${JSON_RAW//^H/\\\b} # \b (backspace)

	echo "$JSON_RAW"
}


## Initialisation ##
if [ -f ~/.gisttoken ]
then
	token=$(cat ~/.gisttoken)
else
	echo -n "Do you want to manually generate a Personal-Access-Token [y/N]? "
	read manual_token </dev/tty
	if [ "$manual_token" == "Y" ] || [ "$manual_token" == "y" ]
	then
		echo "Go to https://github.com/settings/tokens/new to generate a token, be sure to select the \"gist\" scope!"
		echo -n "GitHub.com Personal-Access-Token: "
		read token </dev/tty
	else
		echo -n "GitHub.com Username: "
		read username </dev/tty

		token_curl=$(curl $curl_opts -u $username --data '{ "scopes": [ "gist" ], "note": "CLI Gist Runner", "note_url": "https://github.com/koter84/CLI-Gist-Runner" }' $url/authorizations)
		token=$(echo "$token_curl" | jq '.token' | sed 's/\"//g')
	fi

	token_check=$(gist_dl /user | jq '.login' | sed 's/\"//g')
	if [ "$token_check" != "" ]
	then
		echo $token > ~/.gisttoken
	else
		echo "Failed to connect to GitHub.com with OAuth Token..."
		exit
	fi
fi
if [ "$gist_setup" == "1" ]
then
	echo "Setup Done."
	exit
fi


## AutoComplete ##
if [ "$gistac_test" == "1" ]
then
	echo "> --ac-opts"
	output=$($0 --ac-opts)

	echo -n "> --ac-gist     "
	for i in {1..10} ; do
		echo -n "$i "
		output=$($0 --ac-gist)
	done
	echo " done"

	echo -n "> --ac-starred  "
	for i in {1..10} ; do
		echo -n "$i "
		output=$($0 --ac-starred)
	done
	echo " done"

	# not sure how usefull this is to test, mostly you'll be looking at your own scripts
	echo "> --ac-user octo"
	output=$($0 --ac-user octo)
	echo -n ">> "
	for user in $output
	do
		echo -n "$user "
		output=$($0 --ac-gist $user)
	done

	exit
fi

if [ "$gistac_gist" == "1" ]
then
	cache_time="+1"
	if [ "$gistac_gist_user" != "" ]
	then
		gist_dl "/users/${gistac_gist_user}/gists" | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g'
	elif [ "$gistac_gist_starred" == "1" ]
	then
		cache_file="/tmp/gistCache_mygists"
		if [ ! -f ${cache_file} ] || [ "$(find ${cache_file} -mmin ${cache_time})" != "" ]
		then
			gist_dl /gists/starred | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g' > ${cache_file}
		fi
		cat ${cache_file}
	else
		cache_file="/tmp/gistCache_starred"
		if [ ! -f ${cache_file} ] || [ "$(find ${cache_file} -mmin ${cache_time})" != "" ]
		then
			gist_dl /gists | jq '.[].files[].filename' | sed 's/\"//g' | sed 's/\n/ /g' > ${cache_file}
		fi
		cat ${cache_file}
	fi
fi

if [ "$gistac_user" == "1" ]
then
	gist_dl "/search/users?q=${gistac_user_name}" | jq '.items[].login' | sed 's/\"//g' | sed 's/\n/ /g'
fi


## Uploader ##
if [ "$gist_upload" == "1" ]
then
	if [ -f "$gist_upload_name" ]
	then
		# ask to change filename
		read -p "change upload-filename? [$(basename "$gist_upload_name")] " gist_upload_filename </dev/tty
		if [ "$gist_upload_filename" == "" ]
		then
			gist_upload_filename="$(basename "$gist_upload_name")"
		fi

		content=$(gist_encode $gist_upload_name)
		files_tmp='"'"$gist_upload_filename"'": { "content": "'"$content"'" }'

	elif [ -d "$gist_upload_name" ]
	then
		for file in $(ls $gist_upload_name)
		do
			if [ -d "$gist_upload_name/$file" ]
			then
				# ToDo - use -f|--force to overrride?
				echo "recursion not supported! (found dir $file inside dir $gist_upload_name)"
				exit
			fi

			content=$(gist_encode "$gist_upload_name/$file")
			files_tmp+="$comma"'"'"$file"'": { "content": "'"$content"'" }'
			comma=", "
		done

	else
		echo "$gist_upload_name is not a file nor a directory"
	fi

	gist_upload_files='"files": { '"$files_tmp"' }'

	# ask for a description
	read -p "write a simple (one-line) description: " gist_upload_desc </dev/tty

	# ask for public of private
	read -p "do you want to make this upload public ? [y/N] " public </dev/tty
	if [ "$public" == "y" ] || [ "$public" == "Y" ]
	then
		gist_upload_public="true"
	else
		gist_upload_public="false"
	fi

	# upload
	gist_ul '{ "description": "'"$gist_upload_desc"'", "public": '"$gist_upload_public"', '"$gist_upload_files"' }'

	exit
fi


## The Core ##
if [ "$gist_command" != "" ]
then

	if [ "$gist_starred" == "1" ]
	then
		check_cmd=$($0 --ac-starred|grep "$gist_command")
		if [ "$check_cmd" != "$gist_command" ]
		then
			echo "command seems wrong"
			echo "$gist_command"
			echo "$check_cmd"
		fi

		# get the gist-id
		gist_id=$(gist_dl /gists/starred | jq '.[] | if .files[].filename == "'"$gist_command"'" then .id else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g')

	elif [ "$gist_otheruser" == "1" ]
	then
		check_user=$($0 --ac-user "$gist_otheruser_name"|grep -e "^$gist_otheruser_name\$")
		if [ "$check_user" != "$gist_otheruser_name" ]
		then
			echo "otheruser seems wrong"
			echo "$gist_otheruser_name"
			echo "$check_user"
		fi

		check_cmd=$($0 --ac-gist "$gist_otheruser_name"|grep "$gist_command")
		if [ "$check_cmd" != "$gist_command" ]
		then
			echo "command seems wrong"
			echo "$gist_command"
			echo "$check_cmd"
		fi

		# get the gist-id
		gist_id=$(gist_dl "/users/${gist_otheruser_name}/gists" | jq '.[] | if .files[].filename == "'"$gist_command"'" then .id else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g')

	else # your own gist

		check_cmd=$($0 --ac-gist|grep "$gist_command")
		if [ "$check_cmd" != "$gist_command" ]
		then
			echo "command seems wrong"
			echo "$gist_command"
			echo "$check_cmd"
		fi

		# get the gist-id
		gist_id=$(gist_dl /gists | jq '.[] | if .files[].filename == "'"$gist_command"'" then .id else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g')

	fi


	if [ "$gist_id" != "" ]
	then
		# make tmp-dir
		gist_tmp=$(mktemp -dt cligist-XXXXXX)
		if [ ! -d "$gist_tmp" ]
		then
			echo "tmp-dir not created...."
			echo "$gist_tmp"
			exit
		fi

		# download all gist-files
		gist_files=$(gist_dl "/gists/$gist_id" | jq '.files[].raw_url' | sed 's/\"//g' | sed 's/\n/ /g')
		for raw_url in $gist_files
		do
			file="$gist_tmp/$(basename "$raw_url")"
			wget -q -O "$file" "$raw_url"
			chmod +x "$file"
		done

		# detect file-type
		gist_command_type=$(gist_dl "/gists/$gist_id" | jq '.files[] | if .filename == "'"$gist_command"'" then .type else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g')

		# goto tmp-dir
		cd "$gist_tmp"

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

		if [ "$gist_watch" != "" ]
		then
			cmd="watch -n$gist_watch $cmd"
		fi

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
			eval "$rsync"
			cmd="ssh $gist_remote_name 'hostname; cd $gist_tmp; $cmd; rm -r $gist_tmp'"
			#echo "> cmd: $cmd"
			eval "$cmd"
		else
			#echo "> cmd: $cmd"
			eval "$cmd"
		fi

		# remove tmp-dir
		rm -r "$gist_tmp"

	else
		echo "> problem! no gist-id..."
		exit
	fi
fi

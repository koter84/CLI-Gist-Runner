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
if [ -f ~/.gisttoken ]
then
	token=$(cat ~/.gisttoken)
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


## Options Parser ##
while [[ $# -ge 1 ]]
do
	case $1 in
		--upgrade)
			version_local=$(gist --version|sed s/'v'//)
			version_remote=$(curl $curl_opts "$url/repos/koter84/CLI-Gist-Runner/tags" | jq '.[0].name' | sed 's/\"//g')
			if [ "$version_local" == "$version_remote" ]
			then
				echo "you have v$version_local which is the latest release"
			else
				echo "upgrade from v$version_local to v$version_remote"
				version_remote_hash=$(curl $curl_opts "$url/repos/koter84/CLI-Gist-Runner/tags" | jq '.[0].commit.sha' | sed 's/\"//g')
				curl -s https://raw.githubusercontent.com/koter84/CLI-Gist-Runner/$version_remote_hash/install.sh | bash
			fi
			exit
		;;
		--version)
			echo "v1.3.0"
			exit
		;;
		-h|--help)
			echo ""
			echo "CLI-Gist-Runner"
			echo "https://github.com/koter84/CLI-Gist-Runner"
			echo ""
			echo "$0 [options] [script-name] [options for your gist-script]"
			echo ""
			echo "    -e script-name      edit a gist-script on local machine"
			echo "    -o username         execute another user's gist"
			echo "    -r user@server      execute gist on remote server via ssh"
			echo "    -s                  execute a starred gist"
			echo "    -u file|directory   upload a file or directory to gist (default with piped input)"
			echo "    -w[seconds]         execute a gist using watch"
			echo "    -x                  execute gist with sudo"
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
		-e)
			gist_edit=1
			if [[ "$2" != -* ]] && [ "$2" != "" ]
			then
				gist_edit_name="$2"
				shift
			else
				echo "-e expects a gist script-name"
				exit
			fi
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
			echo "-e -h -o -r -s -u -x -w --help --setup --upgrade --version --ac-test --ac-opts --ac-gist --ac-starred --ac-user"
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

if [ "$gist_command" == "" ] && [ "$gist_upload" != "1" ] && [ "$gist_edit" != "1" ] && [ "$gist_setup" != "1" ] && [ "$gistac_gist" != "1" ] && [ "$gistac_user" != "1" ] && [ "$gistac_test" != "1" ]
then
	echo "you must give a command to execute"
	$0 --help
	exit
fi


## Initialisation ##
if [ "$token" == "" ] || [ "$token" == "null" ]
then
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
		gist_dl "/users/${gistac_gist_user}/gists" | jq '.[].files[].filename' | grep -v '^"~~' | sed 's/\"//g' | sed 's/\n/ /g'
	elif [ "$gistac_gist_starred" == "1" ]
	then
		cache_file="/tmp/gistCache_mygists"
		if [ ! -f ${cache_file} ] || [ "$(find ${cache_file} -mmin ${cache_time})" != "" ]
		then
			gist_dl /gists/starred | jq '.[].files[].filename' | grep -v '^"~~' | sed 's/\"//g' | sed 's/\n/ /g' > ${cache_file}
		fi
		cat ${cache_file}
	else
		cache_file="/tmp/gistCache_starred"
		if [ ! -f ${cache_file} ] || [ "$(find ${cache_file} -mmin ${cache_time})" != "" ]
		then
			gist_dl /gists | jq '.[].files[].filename' | grep -v '^"~~' | sed 's/\"//g' | sed 's/\n/ /g' > ${cache_file}
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
	# make temp-dir for files
	gist_move_tmp=$(mktemp -dt cligistmove-XXXXXX)

	if [ -f "$gist_upload_name" ]
	then
		# ask to change filename
		read -p "change upload-filename? [$(basename "$gist_upload_name")] " gist_upload_filename </dev/tty
		if [ "$gist_upload_filename" == "" ]
		then
			gist_upload_filename="$(basename "$gist_upload_name")"
		fi

		# move file to temp-dir
		cp "$gist_upload_name" "$gist_move_tmp/$gist_upload_filename"

	elif [ -d "$gist_upload_name" ]
	then
		for file in $(ls $gist_upload_name)
		do
			if [ -d "$gist_upload_name/$file" ]
			then
				echo "recursion not supported by GitHub Gist! (found dir '$file' inside dir '$gist_upload_name')"
				if [ "$gist_move_tmp/" != "/" ]; then
					rm -rf "$gist_move_tmp/"
				fi
				exit
			fi

			# move files to temp-dir
			cp "$gist_upload_name/$file" "$gist_move_tmp/"
		done

	else
		echo "$gist_upload_name is not a file nor a directory"
	fi

	# upload only 1 emtpy file called empty.file containing 'empty.file'
	gist_upload_files='"files": { "empty.file": { "content": "empty.file" } }'

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

	# upload empty.file
	new_upload=$(gist_ul '{ "description": "'"$gist_upload_desc"'", "public": '"$gist_upload_public"', '"$gist_upload_files"' }')

	# make temp-dir
	gist_tmp=$(mktemp -dt cligistupload-XXXXXX)

	# get gist-id for cloning
	gist_id=$(echo "$new_upload" | jq .id | sed 's/\"//g' )

	# git clone the new gist
	git clone -q git@gist.github.com:${gist_id}.git "$gist_tmp"

	# git rm empty.file
	result_rm=$(cd "$gist_tmp" && git rm empty.file)

	# move files from temp-dir into git-clone dir
	mv "$gist_move_tmp"/* "$gist_tmp/"

	# git add
	result_add=$(cd "$gist_tmp" && git add -A .)

	# git commit
	result_commit=$(cd "$gist_tmp" && git commit --amend -m "Initial commit")

	# git push
	result_push=$(cd "$gist_tmp" && git push -f --quiet)

	# clean-up temp-dir and git-clone dir
	if [ "$gist_move_tmp/" != "/" ]; then
		rm -rf "$gist_move_tmp/"
	fi
	if [ "$gist_tmp/" != "/" ]; then
		rm -rf "$gist_tmp/"
	fi

	exit
fi


## Editor ##
if [ "$gist_edit" == "1" ]
then
	# make temp-dir
	gist_tmp=$(mktemp -dt cligistedit-XXXXXX)

	# get gist-id for cloning
	gist_id=$(gist_dl /gists | jq '.[] | if .files[].filename == "'"$gist_edit_name"'" then .id else null end' | grep -ve '^null$' | sed 's/\"//g' | sed 's/\n/ /g')

	# git clone
	git clone -q git@gist.github.com:${gist_id}.git $gist_tmp

	# echo instructions for editing
	echo ""
	echo "You are now working in a bash subshell"
	echo "This is a Git repository of '${gist_edit_name}', edit the code, commit it and push it back upstream"
	echo "when you are done use 'exit' to remove this temporary directory and go back to where you came from"
	echo ""

	# cd to temp dir
	cd $gist_tmp

	# start a while-loop to edit git until everything is committed and pushed or discarded
	while true
	do
		# change the bash-prompt to show you are in GistEdit
		export PS1="[GistEdit ${gist_edit_name}]\$ "

		# start bash in the subshell
		${SHELL}

		# check if git is clean (everything committed and pushed)
		git_update=`git remote update` #be quiet
		git_commit=`git clean -n; git status --porcelain`
		git_push=`git log --branches --not --remotes`

		if [ "$git_commit" != "" ] || [ "$git_push" != "" ]
		then
			echo ""
			echo "+---------------------------------------------------+"
			if [ "$git_commit" != "" ]; then
				echo "|  There are uncommitted changes in the repository  |"
			fi
			if [ "$git_push" != "" ]; then
				echo "|    There are unpushed changes in the repository   |"
			fi
			echo "+---------------------------------------------------+"
			echo ""

			# make sure the user is OK with discarding the changes
			read -p "Are you sure you want to discard your changes ? [y/N] " discard_repo
			if [ "$discard_repo" == "y" ] || [ "$discard_repo" == "Y" ]
			then
				# stop the while-loop
				break
			fi
		else
			# everything is clean, stop the while-loop
			break
		fi
	done

	# remove the temp-dir
	if [ -d $gist_tmp ]
	then
		rm -rf ${gist_tmp}
	fi

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

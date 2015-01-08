# bash completion for CLI-Gist-Runner

_gist_runner()
{
	local cur prev opts
#	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev1=""
	if [ $COMP_CWORD -ge 2 ] ; then
		prev1="${COMP_WORDS[COMP_CWORD-1]}"
	fi
	prev2=""
	if [ $COMP_CWORD -ge 3 ] ; then
		prev2="${COMP_WORDS[COMP_CWORD-2]}"
	fi

	if [ "DeBuG" == "No-DeBuG" ]
	then
		opts="count_$COMP_CWORD cur_$cur prev1_$prev1 prev2_$prev2"
		COMPREPLY=( $(compgen -W "${opts}") )

	elif [[ ${prev1} == -o ]] ; then
		if [ "${cur}" == "" ]
		then
			opts=""
		else
			opts=$(gist --ac-user ${cur})
		fi
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	elif [[ ${prev2} == -o ]] ; then
		opts=$(gist --ac-gist ${prev1})
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	elif [[ ${prev1} == -r ]] ; then
		_known_hosts_real "${cur}"
	elif [[ ${prev1} == -s ]] ; then
		opts=$(gist --ac-starred)
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	elif [[ ${prev1} == -u ]] ; then
		COMPREPLY=( $(compgen -f -- ${cur} ) )
	elif [[ ${cur} == -* ]] ; then
		opts=$(gist --ac-opts)
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	else
		opts=$(gist --ac-gist)
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	fi
	return 0
}

complete -F _gist_runner gist
complete -F _gist_runner ./gist.sh

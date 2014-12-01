# bash completion for CLI-Gist-Runner

_gist_runner()
{
	local cur prev opts gists
#	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	opts="--update --upgrade --version --help --ac-gist --ac-starred --ac-user"
	gists=$(/data/GitHub/CLI-Gist-Runner/gist.sh --ac-gist)

	if [[ ${cur} == -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
	else
		COMPREPLY=( $(compgen -W "${gists}" -- ${cur}) )
	fi
	return 0
}

complete -F _gist_runner gist.sh
complete -F _gist_runner ./gist.sh


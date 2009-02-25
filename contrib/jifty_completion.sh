#-*- mode: shell-script;-*-
#
# bash complition script for jifty 
# put this file into /etc/bash_completion.d/

have jifty &&
_jifty()
{
    local cur
    cur=${COMP_WORDS[COMP_CWORD]}

    local jifty_commands="action adopt app console env fastcgi help modperl2 model plugin po schema server"
    if (($COMP_CWORD == 1)); then
        COMPREPLY=( $( compgen -W "$jifty_commands" -- $cur ) )
        return 0
    fi

    local opts_schema="--create-database --drop-database --help --ignore-reserved-words --man --print --setup"
    local opts_server="--port"
    local opts_action="--name --force"
    local opts_model="--name --force"
    local opts_op="--js --dir --language"
    local opts_adopt="--ls"

    case "${COMP_WORDS[1]}" in 
        schema)
            COMPREPLY=( $( compgen -W "$opts_schema" -- $cur ) )
            return 0
        ;;
        server)
            COMPREPLY=( $( compgen -W "$opts_server" -- $cur ) )
            return 0
        ;;
        action)
            COMPREPLY=( $( compgen -W "$opts_action" -- $cur ) )
            return 0
        ;;
        model)
            COMPREPLY=( $( compgen -W "$opts_model" -- $cur ) )
            return 0
        ;;
        op)
            COMPREPLY=( $( compgen -W "$opts_op" -- $cur ) )
            return 0
        ;;
        adopt)
            COMPREPLY=( $( compgen -W "$opts_adopt" -- $cur ) )
            return 0
        ;;
        *)
        ;;
    esac
}

[ "$have" ] && complete -F _jifty -o default jifty

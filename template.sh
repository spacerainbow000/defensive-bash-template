#!/bin/bash
# shellcheck disable=SC2012
# shellcheck disable=SC2046
# shellcheck disable=SC2086
# shellcheck disable=SC2164
#  Abby Embree  #

### IMMUTABLE GLOBAL VARIABLES
readonly PROGNAME=$(basename "${0}")
_SCRIPTLOC=${BASH_SOURCE[0]}
while [ -L ${_SCRIPTLOC} ] ;
do
    _SCRIPTLOC=$(readlink ${_SCRIPTLOC})
done
_SCRIPTLOC=$(dirname ${_SCRIPTLOC})
if [[ "${_SCRIPTLOC}" == "." ]] ;
then
    readonly SCRIPTLOC=$(pwd)
else
    readonly SCRIPTLOC=_SCRIPTLOC
fi
unset _SCRIPTLOC

### VERSION INFO
readonly VERSION="1.0"
version () {
    echo "${PROGNAME} version ${VERSION}"
}

### USAGE
usage () {
    version

    cat <<EOF
    USAGE:

    OPTIONS:
        -h, --help            print this help
        -i, --version         print program version
        -p, --pretend         test run (no changes made)
        -v, --verbose         verbose run (increased logging)
        -x, --debug           debug run (prints bash diagnostic info)
        -c, --config [file]   provide application configuration file
EOF
}

### OPTION PROCESSING
readonly DEFAULT_OPTS="pvxhic:"
# application-specific getopt string
readonly APP_OPTS=""
opts () {
    local ITER=
    local BLOCK=
    local BLOCKTAG=0
    declare -A BLOCKLIST # local
    for ITER ;
    do
        if [[ "${ITER:0:1}" == "-" ]] ;
        then
            # push current block so next argument block can start
            BLOCKLIST["${BLOCKTAG}"]="${BLOCK}"

            case "${ITER}"
            in
                # translate --gnu-long-options to -g (short options)
                --config)       BLOCK="-c"       ;;
                --pretend)      BLOCK="-p"       ;;
                --version)      BLOCK="-i"       ;;
                --help)         usage && exit 0 ;;
                --verbose)      BLOCK="-v"       ;;
                --debug)        BLOCK="-x"       ;;
                # program-specific long opts

                # pass through anything else
                *)              BLOCK="${ITER}"  ;;
            esac
        else
            BLOCK="${BLOCK} ${ITER} "
        fi
	BLOCKTAG=$((BLOCKTAG + 1))
    done

    # push last block
    BLOCKLIST["${BLOCKTAG}"]="${BLOCK}"

    STRINGBLOCK=
    declare -A FLAGBLOCK
    declare -A FLAGCOUNT
    for f in "${!BLOCKLIST[@]}" ; do parseblock ${BLOCKLIST[${f}]} ; done
    for f in "${!FLAGBLOCK[@]}" ; do for g in $(seq 1 ${FLAGCOUNT[${f}]}) ; do default_flags ${FLAGBLOCK[${f}]} ; done ; done

    # reset STRINGBLOCK if it's blank
    [ -z "${STRINGBLOCK// }" ] && STRINGBLOCK=
}
parseblock () {
    local TCHAR=
    local OPTIND=1
    getopts ":${APP_OPTS}${DEFAULT_OPTS}" TCHAR "${@}"
    case ${TCHAR}
    in
        \?)
            # block isn't flag/flag with argument, add to STRINGBLOCK
            STRINGBLOCK="${STRINGBLOCK} ${*} "
	    return
            ;;
        *)
	    if [[ ${FLAGBLOCK["-${TCHAR}"]} == "-${TCHAR}" ]] ;
            then
                # hit repeat flag (as in -vvv), increment count                                                                                                   
                FLAGCOUNT["-${TCHAR}"]=$(( FLAGCOUNT["-${TCHAR}"] + 1 ))
            else
                FLAGCOUNT["-${TCHAR}"]=1
            fi
            FLAGBLOCK["-${TCHAR}"]="-${TCHAR}"

	    # test whether compound short option given (-xv)
	    local OPTARG_P=${OPTARG} # next getopts will change OPTARG, save it
	    local TCHAR_P=${TCHAR} # next getopts will change TCHAR, save it
	    getopts ":${APP_OPTS}${DEFAULT_OPTS}" TCHAR "${@}"
	    case ${TCHAR}
	    in
		\?)
		    # no compound shortopt
		    if [ -z "${OPTARG_P}" ] ;
		    then
			# no argument to flag, add remaining to STRINGBLOCK and return
			shift 1
			[ ${#} -ge 1 ] && STRINGBLOCK="${STRINGBLOCK} ${*}"
			return
		    else
			# flag has argument - add to FLAGBLOCK
			FLAGBLOCK["-${TCHAR_P}"]="-${TCHAR_P} ${OPTARG_P}"
			shift 2
		    fi
		    ;;
		*)
		    # compound shortopt detected; parseblock again on next arg and return
		    local ATWRAP="${*}"
		    parseblock "-${ATWRAP:2}"
		    return
		    ;;
	    esac
            ;;
    esac
    # anything remaining isn't a flag/argument to a flag, add to STRINGBLOCK
    [ ${#} -ge 1 ] && STRINGBLOCK="${STRINGBLOCK} ${*}"
}
default_flags () {
    local FLAG="${1}"
    shift 1
    local OPTARG="${*}"
    case ${FLAG/-/} in
        v)
            readonly VERBOSE=1
	    VERBOSITY=$(( ${VERBOSITY} + 1 ))
            ;;
        h)
            usage
            exit 0
            ;;
        x)
            readonly DEBUG='-x'
            shopt -s extdebug
            set -x
            ;;
        i)
            version
            exit 0
            ;;
        c)
            if [ -z "${OPTARG}" ] ;
            then
                echo "missing configuration file for option -c. exiting"
                exit 1
            fi
            if [ ! -f "${OPTARG}" ] ;
            then
                echo "configuration file ${OPTARG} doesn't exist or is unreadable. exiting"
                exit 1
            fi
            readonly CONFIG_FILE=${OPTARG}
            ;;
        p)
            readonly PRETEND=1
            ;;
        *)
	    # shellcheck disable=SC2086
            program_flags ${FLAG} ${OPTARG}
            ;;
    esac
}
program_flags () {
    local FLAG="${1}"
    shift 1
    local OPTARG=${*}
    case ${FLAG/-/} in
        # define app-level flags and options here

        *)
            echo -ne "unrecognized option ${FLAG}; printing usage instead\n\n"
            usage
            exit 1
            ;;
    esac
}

# deletable once script is complete
todo () {
    echo "TODO ENCOUNTERED"
    echo "CALLING FUNCTION:${FUNCNAME[1]} ${BASH_SOURCE[0]}"
    echo "    AT: ${BASH_LINENO[0]}"
    [[ ${VERBOSE} == 1 ]] && echo -n "    IN CALL STACK:" && echo "${FUNCNAME[@]}"
}

cleanup () {
    # cleanup function that runs when C-c is pressed
    :
}

_main () {
    opts "${@}"
    trap cleanup INT
    # jump to main entry point
    main "${STRINGBLOCK}"
}
main () {
    unset STRINGBLOCK
    unset FLAGBLOCK
    unset FLAGCOUNT
    ### END PREDEFINED BLOCK
    # code goes here
    :
}

# jump to entry point wrapper
VERBOSITY=0
_main "${@}"
exit 0

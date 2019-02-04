#!/bin/bash
#  Abby Embree  #
# Jama Software #

### IMMUTABLE GLOBAL VARIABLES
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0) 2>/dev/null)
readonly ARGS="${@}"

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
#declare application-specific getopt string here
readonly APP_OPTS=""
opts () {
    local ITER=
    local GLOB=
    local GLOBTAG=0
    declare -A GLOBLIST #local
    for ITER ;
    do
        if [[ "${ITER:0:1}" == "-" ]] ;
        then
            #push current glob so next argument glob can start
            GLOBLIST["${GLOBTAG}"]="${GLOB}"

            case "${ITER}"
            in
                #translate --gnu-long-options to -g (short options)
                --config)       GLOB="-c"       ;;
                --pretend)      GLOB="-p"       ;;
                --version)      GLOB="-i"       ;;
                --help)         usage && exit 0 ;;
                --verbose)      GLOB="-v"       ;;
                --debug)        GLOB="-x"       ;;
                #program-specific long opts
                #pass through anything else
                *)              GLOB="${ITER}"  ;;
            esac
        else
            GLOB="${GLOB} ${ITER} "
        fi
	GLOBTAG=$((GLOBTAG + 1))
    done

    #push last glob
    GLOBLIST["${GLOBTAG}"]="${GLOB}"

    STRINGGLOB=
    declare -A FLAGGLOB
    for f in ${!GLOBLIST[@]} ; do parseglob ${GLOBLIST[${f}]} ; done
    for f in ${!FLAGGLOB[@]} ; do default-flags ${FLAGGLOB[${f}]} ; done

    #reset STRINGGLOB if it's blank
    [ -z "${STRINGGLOB// }" ] && STRINGGLOB=
}
parseglob () {
    local TCHAR=
    local OPTIND=1
    getopts ":${APP_OPTS}${DEFAULT_OPTS}" TCHAR "${@}"
    case ${TCHAR}
    in
        \?)
            #glob isn't flag/flag with argument, add to STRINGGLOB
            STRINGGLOB="${STRINGGLOB} ${@} "
	    return
            ;;
        *)
            FLAGGLOB["-${TCHAR}"]="-${TCHAR}"

            if [ -z ${OPTARG} ] ;
            then
		#no argument to flag, add remaining to STRINGGLOB and return
                shift 1
		[ ${#} -ge 1 ] && STRINGGLOB="${STRINGGLOB} ${@}"
		return
            else
                #flag has argument - add to FLAGGLOB
                FLAGGLOB["-${TCHAR}"]="-${TCHAR} ${OPTARG}"
		shift 2
            fi
            ;;
    esac
    #anything remaining isn't a flag/argument to a flag, add to STRINGGLOB
    [ ${#} -ge 1 ] && STRINGGLOB="${STRINGGLOB} ${@}"
}
default-flags () {
    local FLAG="${1}"
    shift 1
    local OPTARG=${@}
    case ${FLAG/-/} in
        v)
            readonly VERBOSE=1
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
            if [ -z ${OPTARG} ] ;
            then
                echo "missing configuration file for option -c. exiting"
                exit 1
            fi
            if [ ! -f ${OPTARG} ] ;
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
            program-flags ${FLAG} ${OPTARG}
            ;;
    esac
}
program-flags () {
    local FLAG="${1}"
    shift 1
    local OPTARG=${@}
    case ${FLAG/-/} in
        #define app-level flags and options here

        *)
            echo -ne "unrecognized option ${FLAG}; printing usage instead\n\n"
            usage
            exit 1
            ;;
    esac
}

#deletable once script is complete
todo () {
    echo "TODO ENCOUNTERED"
    echo "CALLING FUNCTION:"${FUNCNAME[1]}" "${BASH_SOURCE[0]}
    echo "    AT: "${BASH_LINENO}
    [[ ${VERBOSE} == 1 ]] && echo -n "    IN CALL STACK:" && echo "${FUNCNAME[@]}"
}

_main () {
    opts ${@}
    #jump to main entry point
    main ${STRINGGLOB}
}
main () {
    unset STRINGGLOB
    unset FLAGGLOB
    ### END PREDEFINED BLOCK
    #code goes here
    :
}

#jump to entry point wrapper
_main ${@}
exit 0


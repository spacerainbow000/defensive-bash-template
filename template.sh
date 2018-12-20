#!/bin/bash
#  Abby Embree  #
# Jama Software #

### IMMUTABLE GLOBAL VARIABLES
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0) 2>/dev/null)
readonly ARGS="$@"

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

### GENERIC OPTION PROCESSING
opts () {
    local arg=
    local n_args=
    for arg
    do
        local delim=""
        case "$arg" in
            #translate --gnu-long-options to -g (short options)
            --config)       args="${args}-c " ;;
            --pretend)      args="${args}-p " ;;
            --version)      args="${args}-i " ;;
            --help)         usage && exit 0   ;;
            --verbose)      args="${args}-v " ;;
            --debug)        args="${args}-x " ;;
            #pass through anything else
            *) [[ "${arg:0:1}" == "-" ]] || { delim="\"" && \
                       n_args="${n_args} ${arg} "; }
               args="${args}${delim}${arg}${delim} ";;
        esac
    done

    #generic argument string
    GEN_OPTS="pvhxic:"

    #reorder arguments for POSIX and move non-option arguments to the back of the list
    ordered=$(eval getopt --quiet -o ${GEN_OPTS}${APP_OPTS} -- "${args}" | sed 's/--//')
    n_difference=$(
        diff \
            --changed-group-format='%<' \
            --unchanged-group-format='' \
            --suppress-common-lines \
            <(
                echo ${n_args} | xargs printf '%s\n' | xargs printf '%s\n' | sort
            ) \
            <(
                echo ${ordered} | xargs printf '%s\n' | xargs printf '%s\n' | sort
            ) | \
            xargs
    )

   #reset the positional parameters to the short options
    eval set -- ${ordered}' -- '$(eval echo ${n_difference})

    #process generic args
    while getopts ":${APP_OPTS}${GEN_OPTS}" OPTION
    do
         case ${OPTION} in
         v)
             readonly VERBOSE=1
             ;;
         h)
             usage
             exit 0
             ;;
         x)
             readonly DEBUG='-x'
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
             readonly CONFIG_FILE=${OPTARG}
             ;;
         p)
             readonly PRETEND=1
             ;;
         *)
             def_opts ${OPTION} ${OPTARG}
             ;;
        esac
    done

    return 0
}

### APP-SPECIFIC OPT DEFINITIONS
readonly APP_OPTS="" #app-specific opt single-char flags
def_opts () {
    local OPTARG=${2}
    case ${1} in
        #define app-level flags and options here; must also be specified above or option will be treated as unrecognized!

        *)
            echo -ne "unrecognized option (${1}); printing usage instead\n\n"
            usage
            exit 1
            ;;
    esac
}

main () {
    opts ${ARGS}
    eval set -- ${ordered}' -- '${n_difference}
    shift $((${OPTIND} - 1))

    ### END PREDEFINED BLOCK
    #code goes here
    
}

#jump to main entry point
main ${@}
exit 0

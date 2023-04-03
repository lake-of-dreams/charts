#!/bin/bash
#WIP
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
source ${SCRIPT_DIR}/common.sh
chart=
targetVersion=
patchFile=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-t target-version] [-p patch-file]

-c Name of chart
-t Version of chart
-p Location of patch file

-h Print this help text
"""

    if [ ! -z "$msg" ]; then
        echo """
        error: $msg
        """
    fi
    exit $ec
}

while getopts 'c:t:p:' opt; do
    case $opt in
    c)
        chart=${OPTARG}
        ;;
    t)
        targetVersion=${OPTARG}
        ;;
    p)
        patchFile=${OPTARG}
        ;;
    h)
        usage
        ;;
    ?)
        usage 1 "Invalid option: ${OPTARG}"
        ;;
    esac
done

if [ -z "${chart}" ]; then
    usage 1 "Provide a chart name"
fi

if [ -z "${targetVersion}" ]; then
    usage 1 "Provide the version of ${chart}"
fi

if [ -z "${patchFile}" ]; then
    usage 1 "Provide the patch file location"
fi

if [ ! -f "${patchFile}" ]; then
    echo "patch file does not exist at ${patchFile}"
    exit 1
fi

rejects_file="/tmp/${chart}-${targetVersion}-patch-rejects"
rm -rf ${rejects_file}
patch --no-backup-if-mismatch -r ${rejects_file} --directory ${SCRIPT_DIR}/../charts/${chart}/${targetVersion} <${patchFile}
if [ -f "${rejects_file}" ]; then
    if [ -s "${rejects_file}" ]; then
        echo "Chart patched with rejects."
        cat ${rejects_file}
    else
        rm -rf ${rejects_file}
    fi
else
    echo "Chart patched."
fi

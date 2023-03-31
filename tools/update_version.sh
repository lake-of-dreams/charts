#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
source ${SCRIPT_DIR}/common.sh
chart=
version=
targetVersion=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-v version] [-t target-version]

-c Name of chart
-v Version of chart
-t target version of chart to be updated

-h Print this help text
"""

    if [ ! -z "$msg" ]; then
        echo """
        error: $msg
        """
    fi
    exit $ec
}

while getopts 'h:c:v:t:' opt; do
    case $opt in
    c)
        chart=${OPTARG}
        ;;
    t)
        targetVersion=${OPTARG}
        ;;
    v)
        version=${OPTARG}
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
    usage 1 "Provide the target version to be updated to ${chart} ${version}"
fi

if [ -z "${version}" ]; then
    version=${targetVersion}
fi

install_jq
install_yq

echo "Updating version of ${chart} to ${targetVersion} in ${SCRIPT_DIR}/../charts/${chart}/${targetVersion}/Chart.yaml"
yq -i ".version = \"$targetVersion\"" ${SCRIPT_DIR}/../charts/${chart}/${targetVersion}/Chart.yaml

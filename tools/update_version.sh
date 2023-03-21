#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
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
    v)
        version=${OPTARG}
        ;;
    t)
        targetVersion=${OPTARG}
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

if [ -z "${version}" ]; then
    usage 1 "Provide the version of ${chart}"
fi
if [ -z "${targetVersion}" ]; then
    usage 1 "Provide the target version to be updated to ${chart} ${version}"
fi

echo "Updating version of ${chart} ${version} to ${targetVersion}"
yq -i ".version = \"$targetVersion\"" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml

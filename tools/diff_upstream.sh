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
    patchFile="${SCRIPT_DIR}/../${chart}-${targetVersion}.patch"
fi

upstream_provenance_file="${SCRIPT_DIR}/../provenance/${chart}/${targetVersion}.yaml"
if [ ! -f "${upstream_provenance_file}"]; then
    echo "Upstream provenance file does not exist at ${upstream_provenance_file}"
    exit 1
fi

install_jq
install_yq

upstream_chart_local_dir=$(yq ".upstreamChartLocalPath" ${upstream_provenance_file})
if [ -z "${upstream_chart_local_dir}" ]; then
    echo "upstreamChartLocalPath not defined in ${upstream_provenance_file}"
    exit 1
fi

upstream_chart_local_dir="${SCRIPT_DIR}/../provenance/${upstream_chart_local_dir}"
if [ ! -d "${upstream_chart_local_dir}" ]; then
    echo "${upstream_chart_local_dir} does not exist."
    exit 1
fi

diff -Naurw ${upstream_chart_local_dir} ${SCRIPT_DIR}/../charts/${chart}/${targetVersion} >${patchFile}
if [ -f "${patchFile}"]; then
    echo "Patch file generated at ${patchFile}"
else
    echo "Failed generating patch file at ${patchFile}"
    exit 1
fi

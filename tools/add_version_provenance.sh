#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
source ${SCRIPT_DIR}/common.sh
chart=
version=
targetVersion=
helmIndex=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-v version] [-t target-version] [-i helm-index-location]

-c Name of chart
-v Version of chart
-t target version of chart
-i helm index location

-h Print this help text
"""

    if [ ! -z "$msg" ]; then
        echo """
        error: $msg
        """
    fi
    exit $ec
}

while getopts 'c:v:t:i:' opt; do
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
    i)
        helmIndex=${OPTARG}
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
    targetVersion=${version}
fi

if [ -z "${helmIndex}" ]; then
    usage 1 "Provide helm repo index url"
fi

install_jq
install_yq

echo "Adding version provenance information for ${chart} ${targetVersion} from ${version}"
echo "Download index from ${helmIndex}"
rm -rf ${chart}-index.yaml
wget ${helmIndex} -q -O ${chart}-index.yaml
echo "Index downloaded."
rm -rf ${chart}-entry.yaml
yq e ".entries.\"${chart}\".[] | select(.name == \"${chart}\" and .version == \"${version}\")" ./${chart}-index.yaml >${chart}-entry.yaml
${SCRIPT_DIR}/add_provenance.sh -c ${chart} -v ${targetVersion} -p "upstreamVersion" -k ${version}
${SCRIPT_DIR}/add_provenance.sh -c ${chart} -v ${targetVersion} -p "upstreamIndexEntry" -f ${chart}-entry.yaml
${SCRIPT_DIR}/add_provenance.sh -c ${chart} -v ${targetVersion} -p "upstreamChartLocalPath" -k "upstreams/${version}"
rm -rf ${chart}-index.yaml
rm -rf ${chart}-entry.yaml
echo "Version provenance added for ${chart} ${targetVersion}"

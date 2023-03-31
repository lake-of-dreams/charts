#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
source ${SCRIPT_DIR}/common.sh
chart=
version=
provenanceName=
provenanceValue=
provenanceValueYamlFile=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-v version] [-p provenance-name] [-k provenance-value] [-f provenance-value-yaml-file ]

-c Name of chart
-v Version of chart
-p Provenance Name
-k Provenance value
-f yaml file containing value of provenance to be added

-h Print this help text
"""

    if [ ! -z "$msg" ]; then
        echo """
        error: $msg
        """
    fi
    exit $ec
}

while getopts 'h:c:v:p:k:f:' opt; do
    case $opt in
    c)
        chart=${OPTARG}
        ;;
    v)
        version=${OPTARG}
        ;;
    p)
        provenanceName=${OPTARG}
        ;;
    k)
        provenanceValue=${OPTARG}
        ;;
    f)
        provenanceValueYamlFile=${OPTARG}
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

if [ -z "${provenanceName}" ]; then
    usage 1 "Provide the name of provenance."
fi

if [[ -z "${provenanceValue}" && -z "${provenanceValueYamlFile}" ]]; then
    usage 1 "Either provenance value or file containing provenance yaml should be provided."
fi

install_jq
install_yq

mkdir -p ${SCRIPT_DIR}/../provenance/${chart}
touch ${SCRIPT_DIR}/../provenance/${chart}/${version}.yaml

if [ ! -z "${provenanceValueYamlFile}" ]; then
    yq -i ".$provenanceName = load(\"$provenanceValueYamlFile\")" ${SCRIPT_DIR}/../provenance/${chart}/${version}.yaml
else
    yq -i ".$provenanceName = \"$provenanceValue\"" ${SCRIPT_DIR}/../provenance/${chart}/${version}.yaml
fi

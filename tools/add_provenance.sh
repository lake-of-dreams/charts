#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
chart=
version=
provenanceEntryYamlFile=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-v version] [-p file-with-provenance-entry]

-c Name of chart
-v Version of chart
-p yaml file containing provenance to be added

-h Print this help text
"""

    if [ ! -z "$msg" ]; then
        echo """
        error: $msg
        """
    fi
    exit $ec
}

while getopts 'h:c:v:p:' opt; do
    case $opt in
    c)
        chart=${OPTARG}
        ;;
    v)
        version=${OPTARG}
        ;;
    p)
        provenanceEntryYamlFile=${OPTARG}
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
if [ -z "${provenanceEntryYamlFile}" ]; then
    usage 1 "Provide the yaml file with provennace entry to be added to ${chart} ${version}"
fi

provenanceAnnotationExists=$(yq ".annotations | has(\"provenance\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml)
if [ "$provenanceAnnotationExists" == "true" ]; then
    yq -i ".annotations.provenance += load_str(\"$provenanceEntryYamlFile\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
else
    yq -i " . += {\"annotations\":{\"provenance\": null}}" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
    yq -i " .annotations.provenance |= load_str(\"$provenanceEntryYamlFile\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
fi

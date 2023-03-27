#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
chart=
version=
annotationName=
annotationValue=
annotationValueYamlFile=
multiLineValue=false

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-v version] [-a annotation-name] [-k annotation-value] [-f annotation-value-yaml-file ] [-m if-multi-line-value]

-c Name of chart
-v Version of chart
-a Annotation Name
-k Annotation value
-f yaml file containing value of annotation to be added

-h Print this help text
"""

    if [ ! -z "$msg" ]; then
        echo """
        error: $msg
        """
    fi
    exit $ec
}

while getopts 'h:c:v:a:k:f:m:' opt; do
    case $opt in
    c)
        chart=${OPTARG}
        ;;
    v)
        version=${OPTARG}
        ;;
    a)
        annotationName=${OPTARG}
        ;;
    k)
        annotationValue=${OPTARG}
        ;;
    f)
        annotationValueYamlFile=${OPTARG}
        ;;
    m)
        multiLineValue=true
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

if [ -z "${annotationName}" ]; then
    usage 1 "Provide the name of annotation."
fi

if [[ -z "${annotationValue}" && -z "${annotationValueYamlFile}" ]]; then
    usage 1 "Either annotation value or file containing annotation yaml should be provided."
fi

parentAnnotationExists=$(yq ". | has(\"$annotations\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml)
if [ "$annotationExists" == "false" ]; then
    yq -i " . += {\"annotations\": null}" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
fi

annotationExists=$(yq ".annotations | has(\"$annotationName\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml)
if [ "$annotationExists" == "false" ]; then
    if [ "$multiLineValue" == "true" ]; then
        yq -i " .annotations += {\"$annotationName\": null}" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
    else
        yq -i " .annotations += {\"$annotationName\": \"\"}" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
    fi
fi

if [ ! -z "${annotationValueYamlFile}" ]; then
    yq -i ".annotations.$annotationName |= load_str(\"$annotationValueYamlFile\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
else
    yq -i ".annotations.$annotationName += \"$annotationValue\"" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
fi

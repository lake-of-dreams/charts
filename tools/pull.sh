#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
chart=
version=
targetVersion=
helmRepo=
helmIndex=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-v version] [-t target-version] [-r helm-repo-url] [-i helm-index-location]

-c Name of chart
-v Version of chart
-t targetVersion of chart
-r helm repo url
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

while getopts 'h:c:v:t:r:i:' opt; do
    case $opt in
    c)
        chart=${OPTARG}
        ;;
    v)
        version=${OPTARG}
        ;;
    r)
        helmRepo=${OPTARG}
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
if [ -z "${version}" ]; then
    usage 1 "Provide the version of ${chart}"
fi
if [ -z "${helmRepo}" ]; then
    usage 1 "Provide helm repo url to pull ${chart} ${version}"
fi
if [ -z "${helmIndex}" ]; then
    usage 1 "Provide helm repo index for ${helmRepo}"
fi

echo $SCRIPT_DIR
rm -rf ${SCRIPT_DIR}/../charts/${chart}/${version}
rm -rf ${chart}-entry.yaml
rm -rf ${chart}-index.yaml
helm repo add ${chart}-provider ${helmRepo}
helm pull --untar --untardir="${SCRIPT_DIR}/../charts/${chart}/${version}" ${chart}-provider/${chart} --version ${version}
shopt -s dotglob
mv ${SCRIPT_DIR}/../charts/${chart}/${version}/${chart}/* ${SCRIPT_DIR}/../charts/${chart}/${version}
rmdir ${SCRIPT_DIR}/../charts/${chart}/${version}/${chart}
shopt -u dotglob
echo "Successfully pulled chart"
wget ${helmIndex} -O ${chart}-index.yaml
yq e ".entries.\"${chart}\".[] | select(.name == \"${chart}\" and .version == \"${version}\")" ./${chart}-index.yaml >${chart}-entry.yaml
yq -i "[{\"${version}\":{\"upstreamIndexEntry\":.}}]" ${chart}-entry.yaml
provenanceAnnotationExists=$(yq ".annotations | has(\"provenance\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml)
if [ "$provenanceAnnotationExists" == "true" ]; then
    yq -i ".annotations.provenance |+= load_str($chart-entry.yaml)" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
else
    yq -i " . += {\"annotations\":{\"provenance\": null}}" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
    yq -i " .annotations.provenance |= load_str(\"$chart-entry.yaml\")" ${SCRIPT_DIR}/../charts/${chart}/${version}/Chart.yaml
fi
rm -rf ${chart}-entry.yaml
rm -rf ${chart}-index.yaml

#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
source ${SCRIPT_DIR}/common.sh
chart=
version=
helmRepo=
targetVersion=
saveUpstream=true

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-v version] [-t target-version] [-r helm-repo-url] [-u save-upstream]

-c Name of chart
-v Version of chart
-r helm repo url
-t target version of chart
-u whether to save upstream

-h Print this help text
"""

    if [ ! -z "$msg" ]; then
        echo """
        error: $msg
        """
    fi
    exit $ec
}

while getopts 'h:c:v:r:t:u:' opt; do
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
    u)
        saveUpstream=${OPTARG}
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

if [ -z "${helmRepo}" ]; then
    usage 1 "Provide helm repo url to pull ${chart} ${version}"
fi

install_jq
install_yq
install_kubectl
install_helm

echo "Pulling ${chart} ${version} from ${helmRepo}."
rm -rf ${SCRIPT_DIR}/../charts/${chart}/${targetVersion}
helm repo add ${chart}-provider ${helmRepo}
helm pull --untar --untardir="${SCRIPT_DIR}/../charts/${chart}/${targetVersion}" ${chart}-provider/${chart} --version ${version}
shopt -s dotglob
mv ${SCRIPT_DIR}/../charts/${chart}/${targetVersion}/${chart}/* ${SCRIPT_DIR}/../charts/${chart}/${targetVersion}
rmdir ${SCRIPT_DIR}/../charts/${chart}/${targetVersion}/${chart}
if [ "${saveUpstream}" == "true" ]; then
    mkdir -p ${SCRIPT_DIR}/../provenance/${chart}/upstreams/${version}
    cp -R ${SCRIPT_DIR}/../charts/${chart}/${targetVersion}/* ${SCRIPT_DIR}/../provenance/${chart}/upstreams//${version}/.
fi
shopt -u dotglob
echo "Successfully pulled chart ${chart} ${version} into charts/${chart}/${targetVersion}"

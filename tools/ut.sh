#!/bin/bash
#WIP
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
source ${SCRIPT_DIR}/common.sh
chart=
testPackage=
targetVersion=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-t target-version]

-c Name of chart
-t Version of chart

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

echo "Verify prerequisites."

binary_exists "python3" python_location
if [ ! -z "${python_location}" ]; then
    echo "Using python3 from ${python_location}."
else
    echo "python3 must be installed"
    exit 1
fi

binary_exists "pip3" pip_location
if [ ! -z "${pip_location}" ]; then
    echo "Using pip3 from ${pip_location}."
else
    echo "pip3 must be installed"
    exit 1
fi

venv_dir="./venv"
python3 -m venv "${venv_dir}"
source "${venv_dir}/bin/activate"

binary_exists "yamllint" yamllint_location
if [ ! -z "${yamllint_location}" ]; then
    echo "Using yamllint from ${yamllint_location}."
else
    echo "Installing yamllint"
    pip3 install yamllint
fi

binary_exists "yamale" yamale_location
if [ ! -z "${yamale_location}" ]; then
    echo "Using yamale from ${yamale_location}."
else
    echo "Installing yamale"
    pip3 install yamale
fi

install_yq
install_kubectl
install_helm
install_ct

ct lint --charts ${SCRIPT_DIR}/../charts/${chart}/${targetVersion} --chart-yaml-schema ${SCRIPT_DIR}/chart_schema.yaml --lint-conf ${SCRIPT_DIR}/lintconf.yaml
deactivate
rm -rf ${venv_dir}

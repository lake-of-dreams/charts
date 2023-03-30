#!/bin/bash
#WIP
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)
chart=
testPackage=
targetVersion=

usage() {
    local ec=${1:-0}
    local msg=${2:-""}
    echo """
usage:

$(basename $0) [-h] [-c chart-name] [-t target-version] [-p test-package-path]

-c Name of chart
-t Version of chart
-p test package path

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
        testPackage=${OPTARG}
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

if [ -z "${testPackage}" ]; then
    usage 1 "Provide test package to be compiled for ${chart}"
fi

echo "Verify structure of ${chart} ${targetVersion}."
ct lint --chart-dirs ${SCRIPT_DIR}/../charts --charts keycloakx
echo "Compiling ${testPackage} for ${chart}."
go test -c ${SCRIPT_DIR}/../testing/${chart}/${testPackage} -o test_suite.test
echo "Install ${chart} ${targetVersion}"
ct install --chart-dirs ${SCRIPT_DIR}/../charts --charts keycloakx
pod=$(kubectl get the testing pod)
kubectl cp ./test_suite.test $pod:/test_suite.test
kubectl logs -f $pod

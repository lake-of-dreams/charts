#!/bin/bash
SCRIPT_DIR=$(
    cd $(dirname "$0")
    pwd -P
)

function get_os() {
    local os_name=$1
    OS="$(uname)"
    if [ "${OS}" = "Darwin" ]; then
        eval $os_name="osx"
    else
        eval $os_name="linux"
    fi
}

function get_os_arch() {
    local os_arch_name=$1
    LOCAL_ARCH=$(uname -m)
    case "${LOCAL_ARCH}" in
    x86_64 | amd64)
        eval $os_arch_name="amd64"
        ;;
    armv8* | aarch64* | arm64)
        eval $os_arch_name="arm64"
        ;;
    armv*)
        eval $os_arch_name="armv7"
        ;;
    *)
        echo "Not supported"
        exit 1
        ;;
    esac
}

function set_in_path() {
    local binary_to_set_location=$1
    chmod a+x $binary_to_set_location
    PATH=$PATH:$binary_to_set_location
}

function download_binary() {
    local binary_download_location=$1
    local binary_url=$2
    curl -sLo $binary_download_location $binary_url
}

function binary_exists() {
    local binary_name=$1
    local binary_location=$2
    exec_location=$(command -v ${binary_name})
    eval $binary_location=$exec_location

    if [ ! -z "${exec_location}" ]; then
        echo "$binary_name is installed at ${exec_location}."
    else
        echo "$binary_name is not installed."
    fi
}

function install_jq() {
    binary_exists "jq" jq_location

    if [ ! -z "${jq_location}" ]; then
        echo "Using jq from ${jq_location}."
        return 0
    else
        echo "installing latest version of jq"
    fi
    local install_location=$1
    get_os jq_os
    local binary_name="jq"
    if [ "${jq_os}" = "osx" ]; then
        binary_name="${binary_name}-osx-amd6"
    else
        binary_name="${binary_name}-linux64"
    fi
    download_binary $install_location/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/${binary_name}"
    set_in_path $install_location/jq
}

function get_latest_asset_download_url_or_fail() {
    local asset_name=$1
    local git_repo=$2
    local url=$3
    eval $url=$(curl -sL -H "Accept: application/vnd.github+json" https://api.github.com/repos/${git_repo}/releases/latest | jq '.assets[] | select(.name=="${asset_name}")' | jq .browser_download_url)
    if [ ! -z "${url}" ]; then
        echo "Latest asset from ${git_repo} present at ${url}"
        return 0
    else
        echo "Could not find download url of ${asset_name} from Github repo ${git_repo}"
        exit 1
    fi
}

function get_latest_version() {
    local git_repo=$1
    local version=$2
    eval $version=$(curl -sL -H "Accept: application/vnd.github+json" https://api.github.com/repos/${git_repo}/releases/latest | jq .tag_name)
    if [ ! -z "${version}" ]; then
        echo "Latest version from ${git_repo} is ${version}"
        return 0
    else
        echo "Could not find latest release version from Github repo ${git_repo}"
        exit 1
    fi
}

function install_yq() {
    binary_exists "yq" yq_location

    if [ ! -z "${yq_location}" ]; then
        echo "Using yq from ${yq_location}."
        return 0
    else
        echo "installing latest version of yq"
    fi

    local install_location=$1
    get_os yq_os
    get_os_arch yq_os_arch
    local binary_name="yq"
    if [ "${yq_os}" = "osx" ]; then
        binary_name="${binary_name}_darwin_${yq_os_arch}"
    else
        binary_name="${binary_name}_${yq_os}_${yq_os_arch}"
    fi
    get_latest_asset_download_url_or_fail "${binary_name}" "mikefarah/yq" download_url
    download_binary $install_location/yq "${download_url}"
    set_in_path $install_location/yq
}

function install_helm() {
    binary_exists "helm" helm_location

    if [ ! -z "${helm_location}" ]; then
        echo "Using helm from ${helm_location}."
        return 0
    else
        echo "installing latest version of helm"
    fi
    get_latest_version "helm/helm" helm_version

    local install_location=$1
    get_os helm_os
    get_os_arch helm_os_arch
    local binary_name="helm"
    if [ "${helm_os}" = "osx" ]; then
        helm_os="darwin"
        binary_name="${binary_name}-${helm_version}-darwin-${helm_os_arch}.tar.gz"
    else
        binary_name="${binary_name}-${helm_version}-${helm_os}-${helm_os_arch}.tar.gz"
    fi

    download_binary ./${binary_name} "https://get.helm.sh/${binary_name}"
    tar -xzf "${binary_name}"
    cp ./${helm_os}-${helm_os_arch}/helm $install_location/helm
    set_in_path $install_location/helm
}

function install_kubectl() {
    binary_exists "kubectl" kubectl_location

    if [ ! -z "${kubectl_location}" ]; then
        echo "Using kubectl from ${kubectl_location}."
        return 0
    else
        echo "installing latest version of kubectl"
    fi

    local install_location=$1
    get_os kubectl_os
    get_os_arch kubectl_os_arch
    local binary_name="kubectl"
    if [ "${helm_os}" = "osx" ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/${kubectl_os_arch}/kubectl"
    else
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    fi

    cp ./kubectl $install_location/kubectl
    set_in_path $install_location/kubectl
}

function install_ct() {
    binary_exists "ct" ct_location

    if [ ! -z "${ct_location}" ]; then
        echo "Using ct from ${ct_location}."
        return 0
    else
        echo "installing latest version of ct"
    fi
    get_latest_version "helm/chart-testing" ct_version

    local install_location=$1
    get_os ct_os
    get_os_arch ct_os_arch
    local binary_name="chart-testing"
    if [ "${ct_os}" = "osx" ]; then
        binary_name="${binary_name}_${ct_version}_darwin_${ct_os_arch}.tar.gz"
    else
        binary_name="${binary_name}_${ct_version}_${ct_os}_${ct_os_arch}.tar.gz"
    fi

    get_latest_asset_download_url_or_fail "${binary_name}" "helm/chart-testing" download_url
    download_binary ./${binary_name} "${download_url}"
    tar -xzf "${binary_name}"
    cp ./ct $install_location/ct
    set_in_path $install_location/ct
}

install_jq

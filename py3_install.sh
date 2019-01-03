#!/bin/bash
# Author: Jrohy
# Github: https://github.com/Jrohy/python3-install

INSTALL_VERSION=""

LASTEST_VERSION="3.7.2"

OPENSSL_VERSION="1.1.1a"

LATEST=0

ORIGIN_PATH=$(pwd)

#######color code########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message

colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

#######get params#########
while [[ $# > 0 ]];do
    key="$1"
    case $key in
        --latest)
        LATEST=1
        ;;
        -v|--version)
        INSTALL_VERSION="$2"
        echo -e "prepare install python $(colorEcho ${BLUE} $INSTALL_VERSION)..\n"
        shift
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done
#############################

checkSys() {
    # check root user
    [ $(id -u) != "0" ] && { colorEcho ${RED} "Error: You must be root to run this script"; exit 1; }

    # check os
    if [[ -e /etc/redhat-release ]];then
        if [[ $(cat /etc/redhat-release | grep Fedora) ]];then
            OS='Fedora'
            PACKAGE_MANAGER='dnf'
        else
            OS='CentOS'
            PACKAGE_MANAGER='yum'
        fi
    elif [[ $(cat /etc/issue | grep Debian) ]];then
        OS='Debian'
        PACKAGE_MANAGER='apt-get'
    elif [[ $(cat /etc/issue | grep Ubuntu) ]];then
        OS='Ubuntu'
        PACKAGE_MANAGER='apt-get'
    else
        colorEcho ${RED} "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

commonDependent(){
    ${PACKAGE_MANAGER} update -y
    ${PACKAGE_MANAGER} install wget -y
}

compileDependent(){
    if [[ ${OS} == 'CentOS' || ${OS} == 'Fedora' ]];then
        ${PACKAGE_MANAGER} groupinstall -y "Development tools"
        ${PACKAGE_MANAGER} install -y tk-devel xz-devel gdbm-devel sqlite-devel bzip2-devel readline-devel zlib-devel openssl-devel libffi-devel
    else
        ${PACKAGE_MANAGER} install -y build-essential
        ${PACKAGE_MANAGER} install -y uuid-dev tk-dev liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libffi-dev
    fi
}

downloadPackage(){
    cd $ORIGIN_PATH
    [[ $LATEST == 1 ]] && INSTALL_VERSION=$LASTEST_VERSION
    wget https://www.python.org/ftp/python/$INSTALL_VERSION/Python-$INSTALL_VERSION.tgz
    [[ $? != 0 ]] && colorEcho ${RED} "Fail download Python-$INSTALL_VERSION.tgz version python!" && exit 1
    tar xzvf Python-$INSTALL_VERSION.tgz
    cd Python-$INSTALL_VERSION
}

updateOpenSSL(){
    cd $ORIGIN_PATH
    local VERSION=$1
    wget https://www.openssl.org/source/openssl-$VERSION.tar.gz
    tar xzvf openssl-$VERSION.tar.gz
    cd openssl-$VERSION
    ./config --prefix=/usr/local/openssl shared zlib
    make && make install
    mv -f /usr/bin/openssl /usr/bin/openssl.old
    mv -f /usr/include/openssl /usr/include/openssl.old
    ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
    ln -s /usr/local/openssl/include/openssl /usr/include/openssl
    echo "/usr/local/openssl/lib">>/etc/ld.so.conf
    ldconfig
}

# compile install python3
compileInstall(){
    compileDependent

    LOCAL_SSL_VERSION=$(openssl version|awk '{print $2}'|tr -cd '[0-9]')

    if [ $LOCAL_SSL_VERSION -gt 101 ];then
        downloadPackage
        ./configure
        make && make install
    else
        updateOpenSSL $OPENSSL_VERSION
        echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/openssl/lib" >> $HOME/.bashrc
        source $HOME/.bashrc
        downloadPackage
        ./configure --with-openssl=/usr/local/openssl
        make && make install
    fi
}

#online install python3
webInstall(){
    if [[ ${OS} == 'CentOS' || ${OS} == 'Fedora' ]];then
        [[ ${OS} == 'CentOS' ]] && ${PACKAGE_MANAGER} install epel-release -y
        if ! type python3 >/dev/null 2>&1;then
            ${PACKAGE_MANAGER} install https://centos7.iuscommunity.org/ius-release.rpm -y
            ${PACKAGE_MANAGER} install python36u -y
            ln -s /bin/python3.6 /bin/python3
        fi
    else
        if ! type python3 >/dev/null 2>&1;then
            ${PACKAGE_MANAGER} install python3 -y
        fi
        ${PACKAGE_MANAGER} install python3-distutils -y >/dev/null 2>&1
    fi
}

main(){
    checkSys

    commonDependent
    
    if [[ $LATEST == 1 || $INSTALL_VERSION ]];then
        compileInstall
    else
        webInstall
    fi
    # install latest pip
    python3 <(curl -sL https://bootstrap.pypa.io/get-pip.py)
}

main
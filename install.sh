#!/bin/bash
# Author: Jrohy
# Github: https://github.com/Jrohy/python3-install

INSTALL_VERSION=""

OPENSSL_VERSION="1.1.1l"

LATEST=0

NO_PIP=0

CONFIG_PARAM=""

ORIGIN_PATH=$(pwd)

# cancel centos alias
[[ -f /etc/redhat-release ]] && unalias -a

#######color code########
RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="36m"
FUCHSIA="35m"

colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

#######get params#########
while [[ $# > 0 ]];do
    KEY="$1"
    case $KEY in
        --nopip)
        NO_PIP=1
        colorEcho $BLUE "only install python3..\n"
        ;;
        --latest)
        LATEST=1
        ;;
        -v|--version)
        INSTALL_VERSION="$2"
        echo -e "prepare install python $(colorEcho ${BLUE} $INSTALL_VERSION)..\n"
        shift
        ;;
        *)
        CONFIG_PARAM=$CONFIG_PARAM" $KEY"
        ;;
    esac
    shift # past argument or value
done
if [[ $LATEST == 1 || $INSTALL_VERSION ]];then
    [[ $CONFIG_PARAM ]] && echo "python3 compile command: `colorEcho $BLUE ./configure $CONFIG_PARAM`"
fi
#############################

checkSys() {
    # check root user
    [ $(id -u) != "0" ] && { colorEcho ${RED} "Error: You must be root to run this script"; exit 1; }

    if [[ `command -v apt-get` ]];then
        PACKAGE_MANAGER='apt-get'
    elif [[ `command -v dnf` ]];then
        PACKAGE_MANAGER='dnf'
    elif [[ `command -v yum` ]];then
        PACKAGE_MANAGER='yum'
    else
        colorEcho $RED "Not support OS!"
        exit 1
    fi

    # 缺失/usr/local/bin路径时自动添加
    [[ -z `echo $PATH|grep /usr/local/bin` ]] && { echo 'export PATH=$PATH:/usr/local/bin' >> /etc/bashrc; source /etc/bashrc; }
}

commonDependent(){
    [[ $PACKAGE_MANAGER == 'apt-get' ]] && ${PACKAGE_MANAGER} update -y
    ${PACKAGE_MANAGER} install wget -y
}

compileDependent(){
    if [[ ${PACKAGE_MANAGER} == 'yum' || ${PACKAGE_MANAGER} == 'dnf' ]];then
        ${PACKAGE_MANAGER} groupinstall -y "Development tools"
        ${PACKAGE_MANAGER} install -y tk-devel xz-devel gdbm-devel sqlite-devel bzip2-devel readline-devel zlib-devel openssl-devel libffi-devel
    else
        ${PACKAGE_MANAGER} install -y build-essential
        ${PACKAGE_MANAGER} install -y uuid-dev tk-dev liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libffi-dev
    fi
}

downloadPackage(){
    cd $ORIGIN_PATH
    [[ $LATEST == 1 ]] && INSTALL_VERSION=`curl -s https://www.python.org/|grep "downloads/release/"|egrep -o "Python [[:digit:]]+\.[[:digit:]]+\.[[:digit:]]"|sed s/"Python "//g`
    PYTHON_PACKAGE="Python-$INSTALL_VERSION.tgz"
    while :
    do
        if [[ ! -e $PYTHON_PACKAGE ]];then
            wget https://www.python.org/ftp/python/$INSTALL_VERSION/$PYTHON_PACKAGE
            if [[ $? != 0 ]];then
                colorEcho ${RED} "Fail download $PYTHON_PACKAGE version python!"
                exit 1
            fi
        fi
        tar xzvf $PYTHON_PACKAGE
        if [[ $? == 0 ]];then
            break
        else
            rm -rf $PYTHON_PACKAGE Python-$INSTALL_VERSION
        fi
    done
    cd Python-$INSTALL_VERSION
}

updateOpenSSL(){
    cd $ORIGIN_PATH
    local VERSION=$1
    wget --no-check-certificate https://www.openssl.org/source/openssl-$VERSION.tar.gz
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

    cd $ORIGIN_PATH && rm -rf openssl-$VERSION*
}

# compile install python3
compileInstall(){
    compileDependent

    LOCAL_SSL_VERSION=$(openssl version|awk '{print $2}'|tr -cd '[0-9]')

    if [[ $LOCAL_SSL_VERSION -le 101 ]] || ([[ $LATEST == 1 ]] && [[ $LOCAL_SSL_VERSION -lt 111 ]]);then
        updateOpenSSL $OPENSSL_VERSION
        echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/openssl/lib" >> $HOME/.bashrc
        source $HOME/.bashrc
        downloadPackage
        ./configure --with-openssl=/usr/local/openssl $CONFIG_PARAM
        make && make install
    else
        downloadPackage
        ./configure $CONFIG_PARAM
        make && make install
    fi

    cd $ORIGIN_PATH && rm -rf Python-$INSTALL_VERSION*
}

#online install python3
webInstall(){
    if [[ ${PACKAGE_MANAGER} == 'yum' || ${PACKAGE_MANAGER} == 'dnf' ]];then
        if ! type python3 >/dev/null 2>&1;then
            if [[ ${PACKAGE_MANAGER} == 'yum' ]];then
                ${PACKAGE_MANAGER} install epel-release -y
                ${PACKAGE_MANAGER} install https://repo.ius.io/ius-release-el7.rpm -y
                ${PACKAGE_MANAGER} install python36u -y
                [[ ! -e /bin/python3 ]] && ln -s /bin/python3.6 /bin/python3
            elif [[ ${PACKAGE_MANAGER} == 'dnf' ]];then
                ${PACKAGE_MANAGER} install python3 -y
            fi
        fi
    else
        if ! type python3 >/dev/null 2>&1;then
            ${PACKAGE_MANAGER} install python3 -y
        fi
        ${PACKAGE_MANAGER} install python3-distutils -y >/dev/null 2>&1
    fi
}

pipInstall(){
    [[ $NO_PIP == 1 ]] && return
    PY3_VERSION=`python3 -V|tr -cd '[0-9.]'|cut -d. -f2`
    if [ $PY3_VERSION -gt 5 ];then
        python3 <(curl -sL https://bootstrap.pypa.io/get-pip.py)
    else
        if [[ -z `command -v pip` ]];then
            if [[ ${PACKAGE_MANAGER} == 'apt-get' ]];then
                apt-get install -y python3-pip
            fi
            [[ -z `command -v pip` && `command -v pip3` ]] && ln -s $(which pip3) /usr/bin/pip
        fi
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

    pipInstall
}

main

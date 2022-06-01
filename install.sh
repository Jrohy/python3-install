#!/bin/bash
# Author: Jrohy
# Github: https://github.com/Jrohy/python3-install

latest=0

no_pip=0

config_param=""

install_version=""

origin_path=$(pwd)

openssl_version="1.1.1o"

# cancel centos alias
[[ -f /etc/redhat-release ]] && unalias -a

#######color code########
red="31m"
green="32m"
yellow="33m"
blue="36m"
fuchsia="35m"

color_echo(){
    echo -e "\033[$1${@:2}\033[0m"
}

#######get params#########
while [[ $# > 0 ]];do
    KEY="$1"
    case $KEY in
        --nopip)
        no_pip=1
        color_echo $blue "only install python3..\n"
        ;;
        --latest)
        latest=1
        ;;
        -v|--version)
        install_version="$2"
        echo -e "prepare install python $(color_echo ${blue} $install_version)..\n"
        shift
        ;;
        *)
        config_param=$config_param" $KEY"
        ;;
    esac
    shift # past argument or value
done
if [[ $latest == 1 || $install_version ]];then
    [[ $config_param ]] && echo "python3 compile command: `color_echo $blue ./configure $config_param`"
fi
#############################

check_sys() {
    # check root user
    [ $(id -u) != "0" ] && { color_echo ${red} "Error: You must be root to run this script"; exit 1; }

    if [[ `command -v apt-get` ]];then
        package_manager='apt-get'
    elif [[ `command -v dnf` ]];then
        package_manager='dnf'
    elif [[ `command -v yum` ]];then
        package_manager='yum'
    else
        color_echo $red "Not support OS!"
        exit 1
    fi

    # 缺失/usr/local/bin路径时自动添加
    [[ -z `echo $PATH|grep /usr/local/bin` ]] && { echo 'export PATH=$PATH:/usr/local/bin' >> /etc/bashrc; source /etc/bashrc; }
}

common_dependent(){
    [[ $package_manager == 'apt-get' ]] && ${package_manager} update -y
    ${package_manager} install wget -y
}

compile_dependent(){
    if [[ ${package_manager} == 'yum' || ${package_manager} == 'dnf' ]];then
        ${package_manager} groupinstall -y "Development tools"
        ${package_manager} install -y tk-devel xz-devel gdbm-devel sqlite-devel bzip2-devel readline-devel zlib-devel openssl-devel libffi-devel
    else
        ${package_manager} install -y build-essential
        ${package_manager} install -y uuid-dev tk-dev liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libffi-dev
    fi
}

download_package(){
    cd $origin_path
    [[ $latest == 1 ]] && install_version=`curl -s https://www.python.org/|grep "downloads/release/"|egrep -o "Python [[:digit:]]+\.[[:digit:]]+\.[[:digit:]]"|sed s/"Python "//g`
    python_package="Python-$install_version.tgz"
    while :
    do
        if [[ ! -e $python_package ]];then
            wget https://www.python.org/ftp/python/$install_version/$python_package
            if [[ $? != 0 ]];then
                color_echo ${red} "Fail download $python_package version python!"
                exit 1
            fi
        fi
        tar xzvf $python_package
        if [[ $? == 0 ]];then
            break
        else
            rm -rf $python_package Python-$install_version
        fi
    done
    cd Python-$install_version
}

update_openssl(){
    cd $origin_path
    local version=$1
    wget --no-check-certificate https://www.openssl.org/source/openssl-$version.tar.gz
    tar xzvf openssl-$version.tar.gz
    cd openssl-$version
    ./config --prefix=/usr/local/openssl shared zlib
    make && make install
    mv -f /usr/bin/openssl /usr/bin/openssl.old
    mv -f /usr/include/openssl /usr/include/openssl.old
    ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
    ln -s /usr/local/openssl/include/openssl /usr/include/openssl
    echo "/usr/local/openssl/lib">>/etc/ld.so.conf
    ldconfig

    cd $origin_path && rm -rf openssl-$version*
}

# compile install python3
compileInstall(){
    compile_dependent

    local local_ssl_version=$(openssl version|awk '{print $2}'|tr -cd '[0-9]')

    if [[ $local_ssl_version -le 101 ]] || ([[ $latest == 1 ]] && [[ $local_ssl_version -lt 111 ]]);then
        update_openssl $openssl_version
        echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/openssl/lib" >> $HOME/.bashrc
        source $HOME/.bashrc
        download_package
        ./configure --with-openssl=/usr/local/openssl $config_param
        make && make install
    else
        download_package
        ./configure $config_param
        make && make install
    fi

    cd $origin_path && rm -rf Python-$install_version*
}

#online install python3
web_install(){
    if [[ ${package_manager} == 'yum' || ${package_manager} == 'dnf' ]];then
        if ! type python3 >/dev/null 2>&1;then
            if [[ ${package_manager} == 'yum' ]];then
                ${package_manager} install epel-release -y
                ${package_manager} install https://repo.ius.io/ius-release-el7.rpm -y
                ${package_manager} install python36u -y
                [[ ! -e /bin/python3 ]] && ln -s /bin/python3.6 /bin/python3
            elif [[ ${package_manager} == 'dnf' ]];then
                ${package_manager} install python3 -y
            fi
        fi
    else
        if ! type python3 >/dev/null 2>&1;then
            ${package_manager} install python3 -y
        fi
        ${package_manager} install python3-distutils -y >/dev/null 2>&1
    fi
}

pip_install(){
    [[ $no_pip == 1 ]] && return
    py3_version=`python3 -V|tr -cd '[0-9.]'|cut -d. -f2`
    if [[ $py3_version > 6 ]];then
        python3 <(curl -sL https://bootstrap.pypa.io/get-pip.py)
    elif [[ $py3_version == 6 ]];then
        python3 <(curl -sL https://bootstrap.pypa.io/pip/3.6/get-pip.py)
    else
        if [[ -z `command -v pip` ]];then
            if [[ ${package_manager} == 'apt-get' ]];then
                apt-get install -y python3-pip
            fi
            [[ -z `command -v pip` && `command -v pip3` ]] && ln -s $(which pip3) /usr/bin/pip
        fi
    fi
}

main(){
    check_sys

    common_dependent
    
    if [[ $latest == 1 || $install_version ]];then
        compileInstall
    else
        web_install
    fi

    pip_install
}

main

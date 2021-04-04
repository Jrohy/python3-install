# python3-install
![](https://img.shields.io/github/stars/Jrohy/python3-install.svg)   ![](https://img.shields.io/github/forks/Jrohy/python3-install.svg) ![](https://img.shields.io/github/license/Jrohy/python3-install.svg)  
auto install Python3 and pip  
support **CentOS 6+/Debian 8+/Ubuntu 14+**

## Install without compile(recommend)
```
source <(curl -sL https://python3.netlify.app/install.sh)
```

## Install with compile(latest version)
```
source <(curl -sL https://python3.netlify.app/install.sh) --latest
```

## Install with compile(special version)
```
source <(curl -sL https://python3.netlify.app/install.sh) -v 3.6.5
```

## Only install python3
```
source <(curl -sL https://python3.netlify.app/install.sh) --nopip
```

## Compile with custom param
```
source <(curl -sL https://python3.netlify.app/install.sh) --latest --enable-optimizations
```

find the special version in [python_version_list](https://www.python.org/ftp/python/), script will auto download and compile it   

if os openssl version less than **1.0.2** , script will auto install latest openssl before compile python3, it may be have risk(except new install os), so recommend install without compile way
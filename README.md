# python3-install
auto install Python3 and pip3  
support **CentOS 6+/Debian 8+/Ubuntu 14+**

## Install without compile(recommend)
```
bash <(curl -sL https://git.io/fhqMz)
```

## Install with compile(latest version)
```
bash <(curl -sL https://git.io/fhqMz) --latest
```

## Install with compile(special version)
```
bash <(curl -sL https://git.io/fhqMz) -v 3.6.5
```
find the special version in [python_version_list](https://www.python.org/ftp/python/), script will auto download and compile it   

if os openssl version less than **1.0.2** , script will auto install latest openssl before compile python3, it may be have risk(except new install os), so recomend install without compile way

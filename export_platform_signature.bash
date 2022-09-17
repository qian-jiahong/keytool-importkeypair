#!/bin/bash
# English
# Export the signature of the Android platform from the AOSP source code
# Please put keytool-importkeypair into the AOSP code root directory
# Example:
# bash export_platform_signature.bash mypwd123456
# mypwd123456 is your password

# chinese
# 从 AOSP 源码导出 Android 平台的签名
# 请把 keytool-importkeypair 放入AOSP代码根目录
# 示例：
# bash export_platform_signature.bash mypwd123456
# mypwd123456 是你的密码
#
# qianjiahong 2022.03.26

function showErrorMsg(){
    echo -ne "${color_failed}"
    echo -e $1
    echo -ne "${color_reset}"
}

function showSuccessMsg(){
    echo -ne "${color_success}"
    echo -e $1
    echo -ne "${color_reset}"
}

function export_signature() {
    pk8file=$1
    pemfile=$2
    jksfile=$3
    logfile=/tmp/keytool.log
    tmp_keystore=/tmp/platform.keystore

    if [ ! -f ${IMPORTKEYPAIR} ];then
        showErrorMsg "ERROR: script file not found! ${IMPORTKEYPAIR}"
        exit 1
    fi

    if [ ! -f ${pk8file} ] || [ ! -f ${pemfile} ];then
        showErrorMsg "ERROR: Please execute in the AOSP root directory!"
        showErrorMsg "Can't find file: ${pk8file} or ${pemfile}"
        exit 1
    fi

    if [ -f ${jksfile} ];then 
        rm -f ${jksfile}
    fi

    bash ${IMPORTKEYPAIR} -k "${tmp_keystore}" -p ${passphrase} -pk8 ${pk8file} -cert ${pemfile} -alias ${alias} >${logfile} 2>&1
    ret=$?
    if [ "$ret" == "0" ];then
        keytool -importkeystore -srckeystore "${tmp_keystore}" -destkeystore "${jksfile}" -deststoretype pkcs12 -deststorepass "${passphrase}"  -srcstorepass "${passphrase}" >${logfile} 2>&1
        ret=$? 
        if [ "$ret" == "0" ];then
            # echo keystore: $(pwd)"/${jksfile}"
            showSuccessMsg "keystore: $(pwd)/${jksfile}"
            showSuccessMsg "alias: ${alias}"
            showSuccessMsg "passphrase: ${passphrase}"
            echo 
        else
            echo -ne "${color_failed}"
            cat ${logfile}
            echo -ne "${color_reset}\n"
        fi
    else
        echo -ne "${color_failed}"
        cat ${logfile}
        echo -ne "${color_reset}\n"
    fi

    if [ -f ${tmp_keystore} ];then 
        rm -f ${tmp_keystore}
    fi

    if [ -f ${logfile} ];then 
        rm -f ${logfile}
    fi
}

#***************#
# MAIN FUNCTION #
#***************#

color_failed=$'\E'"[0;31m"
color_success=$'\E'"[0;32m"
color_reset=$'\E'"[00m"

if [ -z "$1" ]; then
   showErrorMsg 'ERROR: Please pass in the parameter as the keystore password'

   echo "e.g."
   echo "bash export_platform_signature.bash mypwd123456"
   echo "mypwd123456 is your password"
   exit 1
fi

IMPORTKEYPAIR=./keytool-importkeypair
alias=android
passphrase=$1

pk8file_debug=build/target/product/security/platform.pk8
pemfile_debug=build/target/product/security/platform.x509.pem
pk8file_user=build/target/product/security/release/platform.pk8
pemfile_user=build/target/product/security/release/platform.x509.pem

export_signature ${pk8file_debug} ${pemfile_debug} platform_debug.jks
export_signature ${pk8file_user}  ${pemfile_user}  platform_user.jks

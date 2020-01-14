#!/bin/bash

if [[ $1 = *"@"* ]]; then
    USERNAME=${1%@*}
    SERVER=${1#*@}
else
    SERVER="$1"
    echo -n "Username (@${SERVER}): "
    read USERNAME
fi
[ -z "${USERNAME}" ] && { echo "Username not set"; exit 1; }
shift

if [ $# -ge 1 ]; then
    PORT=$1
else
    PORT=22
fi
shift

OPTIONS="$@"

SSH="/usr/bin/ssh"
CMD="$SSH ${OPTIONS} -p ${PORT} ${USERNAME}@${SERVER}"

echo "Configure new Server (${SERVER}) for personal use"

$CMD /bin/bash << EOF
    test -e "~/bashrc_add" && { echo "Server ${SERVER} configured"; exit 0; }
    rm -rf ~/bashrc_add
    #wget "https://git.schuerz.at/?p=public/server-config.git;a=blob_plain;f=bashrc_add;hb=HEAD" -O ~/bashrc_add
    git clone https://git.schuerz.at/public/server-config.git
    ln -s server-config/bashrc_add bashrc_add
    echo "modify ~/.bashrc"
    if grep -q bashrc_add .bashrc ;then
        sed -i -e '/bashrc_add/d' .bashrc
    fi
    echo
    printf "%s" "[ -f bashrc_add ] && . bashrc_add" | tee -a .bashrc
    echo
EOF
$CMD

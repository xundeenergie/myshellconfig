# Initialize variables, if not set
[ -z ${TMUX_SESSION_DIRS+x} ] && TMUX_SESSION_DIRS=( ~/.config/tmux/sessions ~/.local/share/tmux/sessions ~/.tmux/sessions)
[ -z ${SETPROXY_CREDS_DIRS+x} ] && SETPROXY_CREDS_DIRS=(~/.config/proxycreds)
[ -z ${KERBEROS_CONFIG_DIRS+x} ] && KERBEROS_CONFIG_DIRS=(~/.config/kinit)
[ -z ${ENCFS_CONFIG_DIRS+x} ] && ENCFS_CONFIG_DIRS=(~/.config/encfs)

export TMUX_SESSION_DIRS SETPROXY_CREDS_DIRS KERBEROS_CONFIG_DIRS

cpb() {
    scp "$1" ${SSH_CLIENT%% *}:~/Work
}

sudo() {
    local SUDO
    SUDO=$( if [ -e /bin/sudo ]; then echo /bin/sudo; else echo /usr/bin/sudo; fi )
    $SUDO TMUX=$TMUX SSHS=$SSHS SSH_TTY=$SSH_TTY "$@"

}
create_symlinks() {

    #echo MYSHELLCONFIG_BASE: $MYSHELLCONFIG_BASE
#    MYSHELLCONFIG_BASEDIR="$1"
#    DIR="$(basename ${MYSHELLCONFIG_BASEDIR})"
#    cd  "${MYSHELLCONFIG_BASEDIR}"
    cd ${MYSHELLCONFIG_BASE}
    #echo "DIR MYSHELLCONFIG_BASEDIR $DIR $MYSHELLCONFIG_BASEDIR"
    git config credential.helper 'cache --timeout=300'
    #Anlegen von Symlinks
    rm -rf ~/.vimrc ~/.vim ~/bashrc_add ~/.gitconfig ~/.tmux.conf ~/.tmux
    ln -sf "${MYSHELLCONFIG_BASE}/vimrc" ~/.vimrc
    ln -sf "${MYSHELLCONFIG_BASE}/vim" ~/.vim
    ln -sf "${MYSHELLCONFIG_BASE}/.gitconfig" ~/.gitconfig
    #ln -sf "${MYSHELLCONFIG_BASE}/bashrc_add" ~/bashrc_add
    ln -sf "${MYSHELLCONFIG_BASE}/tmux" ~/.tmux
    ln -sf "${MYSHELLCONFIG_BASE}/tmux/tmux.conf" ~/.tmux.conf

    # Configure to use githooks in .githooks, not in standardlocation .git/hooks
    $SGIT config core.hooksPath .githooks
    # remove all old symlinks in .githooks and relink files from .githooks to .git/hooks
    # don't know, why i do it here. TODO: Check it
    find .git/hooks -type l -exec rm {} \; && find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;
    cd ~-

}

setproxy () {

    local CONFIG
    case $# in
        0)
            echo too few arguments
            return
            ;;
        *)
            if [ -z ${SETPROXY_CREDS_DIRS+x} ] ; then
                echo "are you sure, SETPROXY_CREDS_DIRS is defined?"
                return 1
            else
                CONFIG=$(find ${SETPROXY_CREDS_DIRS[*]} -mindepth 1 -name "$1.conf" -print -quit 2>/dev/null )
            fi
         ;;
    esac

    if [ -e ${CONFIG} ]; then
        echo -n "${CONFIG} existing: "
        source "${CONFIG}"
        echo "sourced"
        export PROXY_CREDS="${PROXY_USER}:${PROXY_PASS}@"
    else
        echo "${CONFIG} not existing"
        export PROXY_CREDS=""
    fi
    export {http,https,ftp}_proxy="http://${PROXY_CREDS}${PROXY_SERVER}:${PROXY_PORT}"
    export {HTTP,HTTPS,FTP}_PROXY="http://${PROXY_CREDS}${PROXY_SERVER}:${PROXY_PORT}"
}

mencfs () {

    [ $# -eq 0 ] && { echo "too few arguments" >&2; return 1; }
    local PKEY
    local ENCDIR
    local DESTDIR
    local PASS=$(which pass 2>/dev/null || exit 127 )
    local ENCFS=$(which encfs 2>/dev/null || exit 127 )
    local CONFIG
    if [ -z ${ENCFS_CONFIG_DIRS+x} ] ; then
        echo "are you sure, ENCFS_CONFIG_DIRS is defined?"
        return 1
    else
        CONFIG=$(find ${ENCFS_CONFIG_DIRS[*]} -mindepth 1 -name "$1.conf" -print -quit 2>/dev/null )
    fi
    
    if [ -e ${CONFIG} ]; then
        echo -n "${CONFIG} existing: "
        source "${CONFIG}"
        echo "sourced"
    else
        echo "${CONFIG} not existing"
        return 2
    fi

    [ -z ${PKEY+x} ] && return 3
    [ -z ${ENCDIR+x} ] && return 4
    [ -z ${DESTDIR+x} ] && DESTDIR="$(dirname $ENCDIR)/$(basename $ENCDIR| tr '[:lower:]' '[:upper:]'| sed -e 's/^\.//')"
    $PASS "${PKEY}" 1>/dev/null 2>&1 || { echo entry $PKEY does not exist in passwordsotre; return 5; }
    local ENCFS_PASSWORD=$($PASS "${PKEY}" | head -n1)

    if [ -z ${ENCDIR+x} -a -d ${ENCDIR} ];then
        echo "no encrypted directory found -> exit"
        return 4
    else
        echo mount encrypted directory $ENCDIR on $DESTDIR
        $ENCFS -S $ENCDIR $DESTDIR <<!
$ENCFS_PASSWORD
!
        if [ $? ]; then
            echo open "$DESTDIR"
            xdg-open $DESTDIR
        fi
    fi
}

uencfs () {

    local FUSERMOUNT=$(which fusermount 2>/dev/null || exit 127 )
    local i
    [ -z ${FUSERMOUNT+x} ] && return 127
    if [ $# -eq 1 ]; then
        if [ ! -d ${1} ];then
            echo "encrypted directory ${1} not found -> exit" >&2
            return 128
        else
            echo umount encrypted directory $1 >&2
            sync
            $FUSERMOUNT -u "$1"
        fi
    else
        echo "no arguments given. Umount all mounted encfs-dirs" >&2
        for i in $(mount|grep encfs|sed -e 's/^encfs on \(.*\)\ type.*$/\1/');do
            echo $FUSERMOUNT -u "$i"
            sync
            $FUSERMOUNT -u "$i"
        done
        return 1
    fi
}

kinit-custom () {

    local PKEY
    local REALM
    local PASS=$(which pass 2>/dev/null || exit 127 )
    local KINIT=$(which kinit 2>/dev/null || exit 127 )
    local CONFIG
    if [ -z ${KERBEROS_CONFIG_DIRS+x} ] ; then
        echo "are you sure, KERBEROS_CONFIG_DIRS is defined?"
        return 1
    else
        CONFIG=$(find ${KERBEROS_CONFIG_DIRS[*]} -mindepth 1 -name "$1.conf" -print -quit 2>/dev/null )
    fi
    
    if [ -e ${CONFIG} ]; then
        echo -n "${CONFIG} existing: "
        source "${CONFIG}"
        echo "sourced"
    else
        echo "${CONFIG} not existing"
        return 2
    fi

    [ -z ${PKEY+x} ] && return 3
    $PASS "${PKEY}" 1>/dev/null 2>&1 || return 3
    local KERBEROS_PASSWORD=$($PASS "${PKEY}" | head -n1)
    local KERBEROS_USER=$($PASS "${PKEY}" | grep login | sed -e 's/^login: //' )
    #echo KERBEROS_PASSWORD: $KERBEROS_PASSWORD
    echo Get kerberos-ticket for: $KERBEROS_USER@$REALM

    if [ -z ${KERBEROS_USER+x} ];then
        echo "no kerberos user found -> exit"
        return 4
    else
        $KINIT -R "${KERBEROS_USER}@${REALM}" <<!
${KERBEROS_PASSWORD}
!
        if [ $? -gt 0 ] ; then
            echo renew kerberos-ticket failed. try to get a new one
            $KINIT "${KERBEROS_USER}@${REALM}" <<!
${KERBEROS_PASSWORD}
!
        fi

    fi
}

unsetproxy () {
    unset {HTTP,HTTPS,FTP}_PROXY
    unset PROXY_{CREDS,USER,PASS,SERVER,PORT}
    unset {http,https,ftp}_proxy
    unset proxy_{creds,user,pass,server,port}
}

git-mergedetachedheadtomaster () {
    git checkout -b tmp
    git branch -f master tmp
    git checkout master
    git branch -d tmp
    git commit -m "Merged detached head into master" .
    #git push origin master
}

pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}

mkcd () {
    mkdir -p "$1"
    cd "$1"
}

sshmyshellconfig() {

    [ -z "${MYSHELLCONFIG_SUBPATH+x}" ]     && MYSHELLCONFIG_SUBPATH=".local/myshellconfig"
    [ -z "${MYSHELLCONFIG_BASE+x}" ]        && MYSHELLCONFIG_BASE="${HOME}/${MYSHELLCONFIG_SUBPATH}"
    MYSHELLCONFIG_BASE_PARENT="$(dirname $MYSHELLCONFIG_BASE)"

    if [ $1 == "localhost" ]; then
        CMD=""
    else
        local SSH="/usr/bin/ssh"
        [ -e ${MYSHELLCONFIG_BASE}/bashrc_add ] && $SSH -T -o VisualHostKey=no $@ "mkdir -p ~/\$MYSHELLCONFIG_BASE_PARENT; cat > ~/bashrc_add" < "${MYSHELLCONFIG_BASE}/bashrc_add"
        local CMD="$SSH -T $@"
    fi
    $CMD /bin/bash << EOF
    [ -e /etc/bashrc ] && .  /etc/bashrc
    [ -e /etc/bash.bashrc ] && . /etc/bash.bashrc
    echo "modify ~/.bashrc"
    sed -i -e '/^\[ -f bashrc_add \] /d' ~/.bashrc
    sed -i -e '/#MYSHELLCONFIG-start/,/#MYSHELLCONFIG-end/d' ~/.bashrc
    echo
    printf "%s\n" "#MYSHELLCONFIG-start" "[ -f \"\${HOME}/${MYSHELLCONFIG_SUBPATH}/bashrc_add\" ] && . \"\${HOME}/${MYSHELLCONFIG_SUBPATH}/bashrc_add\""  "#MYSHELLCONFIG-end"| tee -a ~/.bashrc
    #printf "%s\n" "#MYSHELLCONFIG-start" "if [ -e \${HOME}/${MYSHELLCONFIG_SUBPATH}/bashrc_add ]; then" "  . \${HOME}/${MYSHELLCONFIG_SUBPATH}/bashrc_add;" "else" "  if [ -f ~/bashrc_add ] ;then" "    . ~/bashrc_add;" "  fi;" "fi" "#MYSHELLCONFIG-end" |tee -a ~/.bashrc
    echo
    echo cleanup from old config
    rm -rf  ~/server-config && echo rm -rf  ~/server-config

EOF

}

sshs() {

#    MKTMPCMD='mktemp $(echo ${XDG_RUNTIME_DIR}/bashrc.XXXXXXXX.conf)'
#    VIMMKTMPCMD="mktemp ${XDG_RUNTIME_DIR}/vimrc.XXXXXXXX.conf"

    local f
    local TMPBASHCONFIG=$(mktemp -p ${XDG_RUNTIME_DIR} -t bashrc.XXXXXXXX --suffix=.conf)
    local FILELIST=( ~/.aliases "${MYSHELLCONFIG_BASE}/functions.sh" "${MYSHELLCONFIG_BASE}/aliases" "${MYSHELLCONFIG_BASE}/PS1" "${MYSHELLCONFIG_BASE}/bash_completion.d/*" "${MYSHELLCONFIG_BASE}/myshell_load_fortmpconfig" )

    local SSH_OPTS="-o VisualHostKey=no -o ControlMaster=auto -o ControlPersist=15s -o ControlPath=~/.ssh/ssh-%r@%h:%p"
    # Read /etc/bashrc or /etc/bash.bashrc (depending on distribution) and /etc/profile.d/*.sh first
    cat << EOF >> "${TMPBASHCONFIG}"
[ -e /etc/bashrc ] && BASHRC=/etc/bashrc
[ -e /etc/bash.bashrc ] && BASHRC=/etc/bash.bashrc
. \$BASHRC

for i in /etc/profile.d/*.sh; do
    if [ -r "$i" ];then
        if [ "$PS1" ]; then
            . "$i"
        else
            . "$i" >/dev/null
        fi
    fi
done
unset i
EOF

    for f in ${FILELIST[*]}; do
        if [ -e $f ]; then
            #echo add $f to tmpconfig
            cat "$f" >> "${TMPBASHCONFIG}";
        fi
    done
    
    if [ $# -ge 1 ]; then
        if [ -e "${TMPBASHCONFIG}" ] ; then
           local RCMD="/bin/bash --noprofile --norc -c "
           local REMOTETMPBASHCONFIG=$(ssh -T ${SSH_OPTS} $@ "mktemp -p \${XDG_RUNTIME_DIR} -t bashrc.XXXXXXXX --suffix=.conf"| tr -d '[:space:]' )
           local REMOTETMPVIMCONFIG=$(ssh -T ${SSH_OPTS} $@ "mktemp -p \${XDG_RUNTIME_DIR} -t vimrc.XXXXXXXX --suffix=.conf"| tr -d '[:space:]')

           # Add additional aliases to bashrc for remote-machine
           cat << EOF >> "${TMPBASHCONFIG}"
alias vi='vim -u ${REMOTETMPVIMCONFIG}'
alias vim='vim -u ${REMOTETMPVIMCONFIG}'
alias vimdiff='vimdiff -u ${REMOTETMPVIMCONFIG}'
export LS_OPTIONS="${LS_OPTIONS}"
export VIMRC="${REMOTETMPVIMCONFIG}"
export BASHRC="${REMOTETMPBASHCONFIG}"
title "\$USER@\$HOSTNAME: \$PWD"
echo "This bash runs with temporary config from \$BASHRC"
EOF

           ssh -T ${SSH_OPTS} $@ "cat > ${REMOTETMPBASHCONFIG}" < "${TMPBASHCONFIG}"
           ssh -T ${SSH_OPTS} $@ "cat > ${REMOTETMPVIMCONFIG}" < "${MYSHELLCONFIG_BASE}/vimrc"
           RCMD="
           trap \"rm -f ${REMOTETMPBASHCONFIG} ${REMOTETMPVIMCONFIG}\" EXIT " ;
           ssh -t ${SSH_OPTS} $@ "$RCMD; SSHS=true bash -c \"function bash () { /bin/bash --rcfile ${REMOTETMPBASHCONFIG} -i ; } ; export -f bash; exec bash --rcfile ${REMOTETMPBASHCONFIG}\""
           rm "${TMPBASHCONFIG}"
        else
           echo "${TMPBASHCONFIG} does not exist. Use »ssh $@«" >&2
           ssh -t "$@" 
        fi
    else
        echo "too few arguments for sshs" >&2
        ssh
    fi
}


VIMRC="${MYSHELLCONFIG_BASE}/vimrc"

svi () { 
    if [ -f ${VIMRC} ]; then
        sudo vim -u "${VIMRC}" $@; 
    else
        sudo vim $@
    fi
}

vim-plugins-update () {
    vim -c "PluginUpdate" -c ":qa!"
    
}

vim-plugins-install () {
    vim -c "PluginInstall" -c ":qa!"
    
}

vim-repair-vundle () {
    if [ -z ${MYSHELLCONFIG_BASE+x} ]; then   
        echo "MYSHELLCONFIG_BASE nicht gesetzt. Eventuell noch einmal ausloggen und wieder einloggen"
    else
        cd $MYSHELLCONFIG_BASE
        cd vim/bundle
        rm -rf Vundle.vim
        git clone  "${MYSHELLCONFIG_GIT_REMOTE_PUBLIC}Vim/gmarik/Vundle.vim.git"
        cd ~-
    fi
}

getbashrcfile () {
    if [ -z ${BASHRC+x} ] ; then
        echo "bash uses default"
    else
        cat /proc/$$/cmdline | xargs -0 echo|awk '{print $3}'
    fi
}

catbashrcfile () {
    if [ -z ${BASHRC+x} ] ; then
        echo "bash uses default"
    else
        #cat $(cat /proc/$$/cmdline | xargs -0 echo|awk '{print $3}')
        cat $(getbashrcfile)
    fi
}

getvimrcfile () {
    if [ -z ${VIMRC+x} ] ; then
        echo "vim uses default"
    else
        echo $VIMRC
    fi
}

catvimrcfile () {
    if [ -z ${VIMRC+x} ] ; then
        echo "vim uses default"
    else
        #cat $VIMRC
        cat $(getvimrcfile)
    fi
}


# Functions to set the correct title of the terminal
function title()
{
   # change the title of the current window or tab
   echo -ne "\033]0;$*\007"
}

function sshx()
{
   /usr/bin/ssh "$@"
   # revert the window title after the ssh command
   title $USER@$HOST
}

function su()
{
   /bin/su "$@"
   # revert the window title after the su command
   title $USER@$HOST
}

function usage() 
{
cat << EOF
    Keyboard-shortcuts:

    # tmux:
        C+Cursor    tmux window change size
        M+[hjkl]    tmux change splitted windows

    # vim:
        C+[hjkl]    vim change splitted windows
EOF
}

function pdsh-update-hetzner()
{
    curl -s -H "Authorization: Bearer $(pass hetzner.com/api-token | head -n1)" \
        https://api.hetzner.cloud/v1/servers \
        | /usr/bin/jq '.servers[].public_net.ipv4.ip'|sed -e 's/\"//g' \
        |while read i; do 
            dig -x $i | awk '$0 !~ /^;/ && $4 == "PTR" {print $5}' 
        done |sed -s -e 's/\.$//' > ~/.dsh/group/hetzner-servers
}

function tmuxx() {
    case $# in
        1)
            SESS=($(find ${TMUX_SESSION_DIRS[*]} -mindepth 1 -name "$1.session" 2>/dev/null ))
            ;;
        *)
            echo no session specified return
            ;;
    esac
    TMUX='/usr/bin/tmux'
    $TMUX -f ~/.tmux.conf new-session -d
    [ -e ${SESS[0]} ] && $TMUX source-file ${SESS[0]}
    $TMUX attach-session -d
}


function checkbkp() {
    if ping -c 3 backup.vpn >/dev/null 2>&1 ; then
        local SSH="/usr/bin/ssh"
        local CMD="$SSH -T backup.vpn"
        $CMD /bin/bash << EOF
        sudo find /srv/nfs/backup -mindepth 1 -maxdepth 1|grep -v -e "git$\|git-backup-repos"|while read i;do printf "%-30s%s\\n" "\$i" \$(ls \$i|tail -n1);done|sort -k 2.1 -r
EOF
    else
        echo "backup.vpn is not reachable -> exit"
        return 1
        
    fi
}
function checkbkp-full() {
    if ping -c 3 backup.vpn >/dev/null 2>&1 ; then
        local SSH="/usr/bin/ssh"
        local CMD="$SSH -T backup.vpn"
        $CMD /bin/bash << EOF
        sudo find /srv/nfs/backup -mindepth 1 -maxdepth 1|grep -v -e "git$\|git-backup-repos"|while read i;do printf "%-30s%s\\n" "\$i" \$(ls \$i|tail -n1);done|sort -k 2.1 -r
EOF
        #which pdsh 1>/dev/null 2>&1 && pdsh -g hetzner-servers sudo systemctl status backup.service
        which pdsh 1>/dev/null 2>&1 && pdsh -g vpn sudo systemctl status backup.service

    else
        echo "backup.vpn is not reachable -> exit"
        return 1
        
    fi
}

turnoffbeep() {
    changebeep none
}

changebeep() {
    local style
    case $1 in
        none)
            style=none
            ;;
        visible)
            style=visible
            ;;
        audible)
            style=audible
            ;;
        *)
            echo "usage: changebeep [none|visible|audible]"
            return 1
            ;;
    esac
    local line='set bell-style'
    local file=~/.inputrc
    if [ -e "${file}" ] ; then
        sed -i -e "/$line/d" "${file}"
    fi
    echo "${line} ${style}" >> "${file}"
    return 0
}

turnoffconfigsync() {
    local line='MYSHELLCONFIG_GIT_SYNC='
    local file=~/.bashrc
    if [ -e "${file}" ] ; then
        sed -i -e "/${line}/d" "${file}"
    fi
    sed -i -e "/#MYSHELLCONFIG-start/i${line}false" "${file}"
}

turnonconfigsync() {
    local line='MYSHELLCONFIG_GIT_SYNC='
    local file=~/.bashrc
    if [ -e "${file}" ] ; then
        sed -i -e "/${line}/d" "${file}"
    fi
    sed -i "/#MYSHELLCONFIG-start/i${line}true" "${file}"
}

function gnome-shell-extensions-enable-defaults() { 
    local i
    if [ -f ~/.config/gnome-shell-extensions-default.list ]; then
        for i in $(cat ~/.config/gnome-shell-extensions-default.list); do 
            #gnome-shell-extension-tool -e $i;
            gnome-extensions enable $i;
        done; 
    fi
}

gnome-shell-extensions-make-actual-permanent-systemwide() {
    # https://people.gnome.org/~pmkovar/system-admin-guide/extensions-enable.html
    # https://askubuntu.com/questions/359958/extensions-are-turned-off-after-reboot
    local file="/etc/dconf/profile/user"
    sudo mkdir -p "/etc/dconf/profile/"
    local line='user-db:user'
    if [ -e "${file}" ] ; then
        echo "$command"
        sudo sh -c "$command"
    fi
    local line='system-db:local'
    if [ -e "${file}" ] ; then
        command="grep -xqF -- ${line} ${file} || echo $line >> $file"
        sudo sh -c "$command"
    fi
    local line='enabled-extensions='
    local file='/etc/dconf/db/local.d/00-extensions'
    sudo mkdir -p '/etc/dconf/db/local.d'
    if [ -e "${file}" ] ; then
        sudo sed -i -e "/${line}/d" "${file}"
        #sudo sed -i -e "/\[org\/gnome\/shell\]/d" "${file}"
    fi
    local EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions)
    line="[org/gnome/shell]"
    command="grep -xqF -- ${line} ${file} || echo $line >> $file"
    sudo sh -c "$command"

    local line='enabled-extensions='
    echo "Update or add extensions"
    #echo "${line}${EXTENSIONS}" | sudo tee -a "${file}"
    sudo sed -i "/\[org\/gnome\/shell\]/a${line}${EXTENSIONS}" "${file}"
    sudo dconf update
}

reachable () {
    local SERVER=$1
    local PORT=${2:-22}
    if nc -z $SERVER $PORT 2>/dev/null; then
        echo "${SERVER}:${PORT} is reachable"
    else
        echo "${SERVER}:${PORT} is not reachable"
    fi
}
#EOF

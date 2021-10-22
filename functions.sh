# Initialize variables, if not set
[ -z ${TMUX_SESSION_DIRS+x} ] && TMUX_SESSION_DIRS=( ~/.config/tmux/sessions ~/.local/share/tmux/sessions ~/.tmux/sessions)
[ -z ${SETPROXY_CREDS_DIRS+x} ] && SETPROXY_CREDS_DIRS=(~/.config/proxycreds)
[ -z ${KERBEROS_CONFIG_DIRS+x} ] && KERBEROS_CONFIG_DIRS=(~/.config/kinit)
[ -z ${ENCFS_CONFIG_DIRS+x} ] && ENCFS_CONFIG_DIRS=(~/.config/encfs)

export TMUX_SESSION_DIRS SETPROXY_CREDS_DIRS KERBEROS_CONFIG_DIRS

promptcommandmunge () {
    ENTRY
    case ";${PROMPT_COMMAND};" in
        "*;$1;*")
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PROMPT_COMMAND="${PROMPT_COMMAND};$1"
            else
                PROMPT_COMMAND="$1;${PROMPT_COMMAND}"
            fi
    esac
    EXIT
}
## this function updates in combination with PROMPT_COMMAND the shell-environment-variables in tmux-sessions,
#  every time prompt is called. It does it only, when called from tmux (Environment TMUX is set)
function _tmux_hook() {
#    [ -z "${TMUX+x}" ] || eval "$(tmux show-environment -s)"

    if [ -n "${TMUX}" ]; then
        eval "$(tmux show-environment -s)"
    fi

}

# To make the code more reliable on detecting the default umask
function _umask_hook {
  # Record the default umask value on the 1st run
  [[ -z $DEFAULT_UMASK ]] && export DEFAULT_UMASK="$(builtin umask)"

  if [[ -n $UMASK ]]; then
    umask "$UMASK"
  else
    umask "$DEFAULT_UMASK"
  fi
}

cpb() {
    scp "$1" ${SSH_CLIENT%% *}:~/Work
}

sudo() {
    local SUDO
    SUDO=$( if [ -e /bin/sudo ]; then echo /bin/sudo; else echo /usr/bin/sudo; fi )
    $SUDO \
        GIT_AUTHOR_EMAIL="$GIT_AUTHOR_EMAIL" \
        GIT_AUTHOR_NAME="$GIT_AUTHOR_NAME" \
        GIT_COMMITTER_EMAIL="$GIT_COMMITTER_EMAIL" \
        GIT_COMMITTER_NAME="$GIT_COMMITTER_NAME" \
        TMUX="$TMUX" \
        SSHS="$SSHS" \
        P11M="$P11M" \
        SSH_TTY="$SSH_TTY" \
        SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
        http_proxy="$http_proxy" \
        "$@"

}
create_symlinks() {

    #echo MSC_BASE: $MSC_BASE
#    MSC_BASEDIR="$1"
#    DIR="$(basename ${MSC_BASEDIR})"
#    cd  "${MSC_BASEDIR}"
    cd ${MSC_BASE}
    #echo "DIR MSC_BASEDIR $DIR $MSC_BASEDIR"
    git config credential.helper 'cache --timeout=300'
    #Anlegen von Symlinks
    rm -rf ~/.vimrc ~/.vim ~/bashrc_add ~/.gitconfig ~/.tmux.conf ~/.tmux
    ln -sf "${MSC_BASE}/vimrc" ~/.vimrc
    ln -sf "${MSC_BASE}/vim" ~/.vim
    ln -sf "${MSC_BASE}/.gitconfig" ~/.gitconfig
    ln -sf "${MSC_BASE}/.gitignore_global" ~/.gitignore_global
    #ln -sf "${MSC_BASE}/bashrc_add" ~/bashrc_add
    ln -sf "${MSC_BASE}/tmux" ~/.tmux
    ln -sf "${MSC_BASE}/tmux/tmux.conf" ~/.tmux.conf

    # Configure to use githooks in .githooks, not in standardlocation .git/hooks
    $SGIT config core.hooksPath .githooks
    # remove all old symlinks in .githooks and relink files from .githooks to .git/hooks
    # don't know, why i do it here. TODO: Check it
    find .git/hooks -type l -exec rm {} \; && find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;
    cd ~-

}

setproxy () {

    ENTRY
    local CONFIG
    case $# in
        0)
            logwarn "too few arguments"
            return
            ;;
        *)
            if [ -z ${SETPROXY_CREDS_DIRS+x} ] ; then
                logwarn "are you sure, SETPROXY_CREDS_DIRS is defined?"
                return 1
            else
                CONFIG=$(find ${SETPROXY_CREDS_DIRS[*]} -mindepth 1 -name "$1.conf" -print -quit 2>/dev/null )
            fi
         ;;
    esac
    
    logwarn "CONFIG: ${CONFIG}"

    if [ -e ${CONFIG} ]; then
        loginfo -n "${CONFIG} existing: "
        source "${CONFIG}"
        loginfo "sourced"
        export PROXY_CREDS="${PROXY_USER}:${PROXY_PASS}@"
    else
        loginfo "${CONFIG} not existing"
        export PROXY_CREDS=""
    fi
    export {http,https,ftp}_proxy="http://${PROXY_CREDS}${PROXY_SERVER}:${PROXY_PORT}"
    export {HTTP,HTTPS,FTP}_PROXY="http://${PROXY_CREDS}${PROXY_SERVER}:${PROXY_PORT}"
    EXIT
}

mencfs () {

    ENTRY
    [ $# -eq 0 ] && { logwarn "too few arguments" >&2; return 1; }
    local PKEY
    local ENCDIR
    local DESTDIR
    local PASS=$(which pass 2>/dev/null || exit 127 )
    local ENCFS=$(which encfs 2>/dev/null || exit 127 )
    local CONFIG
    if [ -z ${ENCFS_CONFIG_DIRS+x} ] ; then
        logwarn "are you sure, ENCFS_CONFIG_DIRS is defined?"
        EXIT
        return 1
    else
        CONFIG=$(find ${ENCFS_CONFIG_DIRS[*]} -mindepth 1 -name "$1.conf" -print -quit 2>/dev/null )
    fi
    
    if [ -e ${CONFIG} ]; then
        loginfo -n "${CONFIG} existing: "
        source "${CONFIG}"
        loginfo "sourced"
    else
        loginfo "${CONFIG} not existing"
        EXIT
        return 2
    fi

    logdebug "ENCDIR:   $ENCDIR"
    [ -z ${PKEY+x} ] && { EXIT; return 3; }
    [ -z ${ENCDIR+x} ] && { EXIT; return 4; }
    [ -z "${DESTDIR+x}" ] && [ -n "${XDG_RUNTIME_DIR}" ] && DESTDIR="${XDG_RUNTIME_DIR}/decrypted/$(basename $ENCDIR| tr '[:lower:]' '[:upper:]'| sed -e 's/^\.//')"
    [ -z ${DESTDIR+x} ] && DESTDIR="$(dirname $ENCDIR)/$(basename $ENCDIR| tr '[:lower:]' '[:upper:]'| sed -e 's/^\.//')"
    logdebug "DESTDIR:  $DESTDIR"
    [ -d "$DESTDIR" ] || mkdir -p "$DESTDIR"
    $PASS "${PKEY}" 1>/dev/null 2>&1 || { logerror "entry $PKEY does not exist in passwordsotre"; return 5; }
    local ENCFS_PASSWORD=$($PASS show "${PKEY}")

    if [ -z ${ENCDIR+x} -a -d ${ENCDIR} ];then
        logerror "no encrypted directory found -> exit"
        EXIT
        return 4
    else
        loginfo "mount encrypted directory $ENCDIR on $DESTDIR"
        $ENCFS -S $ENCDIR $DESTDIR <<!
$ENCFS_PASSWORD
!
        if [ $? ]; then
            loginfo "open $DESTDIR"
            xdg-open $DESTDIR
        fi
    fi
    EXIT
}

uencfs () {

    ENTRY
    local FUSERMOUNT=$(which fusermount 2>/dev/null || exit 127 )
    local i
    [ -z ${FUSERMOUNT+x} ] && return 127
    if [ $# -eq 1 ]; then
        if [ ! -d ${1} ];then
            logwarn "encrypted directory ${1} not found -> exit" >&2
            EXIT
            return 128
        else
            loginfo "umount encrypted directory" $1 >&2
            sync
            $FUSERMOUNT -z -u "$1"
        fi
    else
        loginfo "no arguments given. Umount all mounted encfs-dirs" >&2
        for i in $(mount|grep encfs|sed -e 's/^encfs on \(.*\)\ type.*$/\1/');do
            loginfo "$FUSERMOUNT -u $i"
            sync
            $FUSERMOUNT -z -u "$i"
        done
        EXIT
        return 1
    fi
    EXIT
}

kinit-custom () {

    ENTRY
    local PKEY
    local REALM
    local PASS=$(which pass 2>/dev/null || exit 127 )
    local KINIT=$(which kinit 2>/dev/null || exit 127 )
    local CONFIG
    if [ -z ${KERBEROS_CONFIG_DIRS+x} ] ; then
        logwarn "are you sure, KERBEROS_CONFIG_DIRS is defined?"
        EXIT
        return 1
    else
        CONFIG=$(find ${KERBEROS_CONFIG_DIRS[*]} -mindepth 1 -name "$1.conf" -print -quit 2>/dev/null )
    fi
    
    if [ -e ${CONFIG} ]; then
        logdebug -n "${CONFIG} existing: "
        source "${CONFIG}"
        logdebug "sourced"
    else
        logwarn "${CONFIG} not existing"
        EXIT
        return 2
    fi

    [ -z ${PKEY+x} ] && return 3
    $PASS "${PKEY}" 1>/dev/null 2>&1 || return 3
    local KERBEROS_PASSWORD=$($PASS show "${PKEY}")
    local KERBEROS_USER=$($PASS "${PKEY}" | grep login | sed -e 's/^login: //' )
    #echo KERBEROS_PASSWORD: $KERBEROS_PASSWORD
    loginfo "Get kerberos-ticket for: $KERBEROS_USER@$REALM"

    if [ -z ${KERBEROS_USER+x} ];then
        logwarn "no kerberos user found -> exit"
        EXIT
        return 4
    else
        $KINIT -R "${KERBEROS_USER}@${REALM}" <<!
${KERBEROS_PASSWORD}
!
        if [ $? -gt 0 ] ; then
            loginfo renew kerberos-ticket failed. try to get a new one
            $KINIT "${KERBEROS_USER}@${REALM}" <<!
${KERBEROS_PASSWORD}
!
        fi

    fi
    EXIT
}

unsetproxy () {
    ENTRY
    unset {HTTP,HTTPS,FTP}_PROXY
    unset PROXY_{CREDS,USER,PASS,SERVER,PORT}
    unset {http,https,ftp}_proxy
    unset proxy_{creds,user,pass,server,port}
    EXIT
}

# transfered to bin
#git-mergedetachedheadtomaster () {
#    ENTRY
#    git checkout -b tmp
#    git branch -f master tmp
#    git checkout master
#    git branch -d tmp
#    git commit -m "Merged detached head into master" .
#    #git push origin master
#    EXIT
#}

pathmunge () {
    ENTRY
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
    EXIT
}

mkcd () {
    mkdir -p "$1"
    cd "$1"
}

sshmyshellconfig() {

    ENTRY
    [ -z "${MSC_SUBPATH+x}" ]     && MSC_SUBPATH=".local/myshellconfig"
    [ -z "${MSC_BASE+x}" ]        && MSC_BASE="${HOME}/${MSC_SUBPATH}"
    MSC_BASE_PARENT="$(dirname $MSC_BASE)"

    if [ $1 == "localhost" ]; then
        CMD=""
    else
        local SSH="/usr/bin/ssh"
        [ -e ${MSC_BASE}/bashrc_add ] && $SSH -T -o VisualHostKey=no $@ "mkdir -p ~/\$MSC_BASE_PARENT; cat > ~/bashrc_add" < "${MSC_BASE}/bashrc_add"
        local CMD="$SSH -T $@"
    fi
    $CMD /bin/bash << EOF
    [ -e /etc/bashrc ] && .  /etc/bashrc
    [ -e /etc/bash.bashrc ] && . /etc/bash.bashrc
    echo "modify ~/.bashrc"
    sed -i -e '/^\[ -f bashrc_add \] /d' ~/.bashrc
    sed -i -e '/#MYSHELLCONFIG-start/,/#MYSHELLCONFIG-end/d' ~/.bashrc
    echo
    printf "%s\n" "#MYSHELLCONFIG-start" "[ -f \"\${HOME}/${MSC_SUBPATH}/bashrc_add\" ] && . \"\${HOME}/${MSC_SUBPATH}/bashrc_add\""  "#MYSHELLCONFIG-end"| tee -a ~/.bashrc
    #printf "%s\n" "#MYSHELLCONFIG-start" "if [ -e \${HOME}/${MSC_SUBPATH}/bashrc_add ]; then" "  . \${HOME}/${MSC_SUBPATH}/bashrc_add;" "else" "  if [ -f ~/bashrc_add ] ;then" "    . ~/bashrc_add;" "  fi;" "fi" "#MYSHELLCONFIG-end" |tee -a ~/.bashrc
    echo
    echo cleanup from old config
    rm -rf  ~/server-config && echo rm -rf  ~/server-config
    echo mkdir -p ~/.local
    mkdir -p ~/.local
    #echo git clone
    echo git clone --recurse-submodules $MSC_GIT_REMOTE \${HOME}/${MSC_SUBPATH}
    git clone --recurse-submodules $MSC_GIT_REMOTE \${HOME}/${MSC_SUBPATH}
    date "+%s" > \${HOME}/${MSC_SUBPATH}/.last_update_submodules
#    date "+%s" > \${HOME}/${MSC_SUBPATH}/.last_update_repo

EOF
    EXIT

}

sshs() {
    ENTRY

    local LOGLEVEL="WARN"
#    MKTMPCMD='mktemp $(echo ${XDG_RUNTIME_DIR}/bashrc.XXXXXXXX.conf)'
#    VIMMKTMPCMD="mktemp ${XDG_RUNTIME_DIR}/vimrc.XXXXXXXX.conf"

    local f
    local TMPBASHCONFIG=$(mktemp -p ${XDG_RUNTIME_DIR} -t bashrc.XXXXXXXX --suffix=.conf)
    local FILELIST=( "${MSC_BASE}/functions.sh" "${MSC_BASE}/logging" "${MSC_BASE}/myshell_load_fortmpconfig" $(getbashrcfile) ~/.aliases "${MSC_BASE}/aliases" "${MSC_BASE}/PS1" "${MSC_BASE}/bash_completion.d/*" )

    logdebug "FILELIST: $FILELIST"
    if [ -e "${HOME}/.config/myshellconfig/sshs_addfiles.conf" ] ; then
        for f in $(cat "${HOME}/.config/myshellconfig/sshs_addfiles.conf");do
            [ -e "$f" ] && {\
                logdebug "add $f to FILELIST"; \
                FILELIST+=("$f"); } 
        done
    fi
    logdebug "FILELIST: $FILELIST"
    local SSH_OPTS="-o VisualHostKey=no -o ControlMaster=auto -o ControlPersist=15s -o ControlPath=~/.ssh/ssh-%C"
    #local SSH_OPTS="-o VisualHostKey=no -o ControlMaster=yes -o ControlPersist=10s -o ControlPath=~/.ssh/ssh-%C"
    # Read /etc/bashrc or /etc/bash.bashrc (depending on distribution) and /etc/profile.d/*.sh first
    cat << EOF >> "${TMPBASHCONFIG}"
[ -e /etc/bashrc ] && BASHRC=/etc/bashrc
[ -e /etc/bash.bashrc ] && BASHRC=/etc/bash.bashrc
. \$BASHRC

export USERNAME="${USERNAME}"
export FULLNAME="${FULLNAME}"
export USEREMAIL="${USEREMAIL}"
export SCRIPT_LOG="\$(cat /proc/\$$/cmdline | xargs -0 echo|awk '{print \$3}' |sed 's/.conf$/.log/')"
export LOGLEVEL_DEFAULT="${LOGLEVEL_DEFAULT}"
export FILELOGLEVEL_DEFAULT="${FILELOGLEVEL_DEFAULT}"

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
            logdebug "add $f to tmpconfig"
            cat "$f" >> "${TMPBASHCONFIG}";
        fi
    done
    
    if [ $# -ge 1 ]; then
        if [ -e "${TMPBASHCONFIG}" ] ; then
           logdebug "create remote bashrc"
           logdebug "SSH_OPTS: $SSH_OPTS"
           local REMOTETMPBASHCONFIG=$(ssh -T ${SSH_OPTS} $@ "mktemp -p \${XDG_RUNTIME_DIR-~} -t bashrc.XXXXXXXX --suffix=.conf" | tr -d '[:space:]' )
           logdebug "REMOTETMPBASHCONFIG: $REMOTETMPBASHCONFIG"
           logdebug $(ssh -T ${SSH_OPTS} $@ "stat ${REMOTETMPBASHCONFIG}")
           logdebug $(ssh -T ${SSH_OPTS} $@ "hostnamectl")
           logdebug "create remote vimrc"
           local REMOTETMPVIMCONFIG=$(ssh -T ${SSH_OPTS} $@ "mktemp -p \${XDG_RUNTIME_DIR-~} -t vimrc.XXXXXXXX --suffix=.conf" | tr -d '[:space:]' )
           logdebug "REMOTETMPVIMCONFIG: $REMOTETMPVIMCONFIG"

           # Add additional aliases to bashrc for remote-machine
           cat << EOF >> "${TMPBASHCONFIG}"
alias vi='vim -u ${REMOTETMPVIMCONFIG}'
alias vim='vim -u ${REMOTETMPVIMCONFIG}'
alias vimdiff='vimdiff -u ${REMOTETMPVIMCONFIG}'
export LS_OPTIONS="${LS_OPTIONS}"
export VIMRC="${REMOTETMPVIMCONFIG}"
export BASHRC="${REMOTETMPBASHCONFIG}"
title "\$USER@\$HOSTNAME: \$PWD"
loginfo "This bash runs with temporary config from \$BASHRC"
EOF

           logdebug "create fill remote bashrc"
           ssh -T ${SSH_OPTS} $@ "cat > ${REMOTETMPBASHCONFIG}" < "${TMPBASHCONFIG}"
           logdebug  $(ssh -T ${SSH_OPTS} $@ "stat ${REMOTETMPBASHCONFIG}")
           logdebug "create fill remote vimrc"
           ssh -T ${SSH_OPTS} $@ "cat > ${REMOTETMPVIMCONFIG}" < "${MSC_BASE}/vimrc"
           local RCMD="/bin/bash --noprofile --norc -c "
           RCMD="
           trap \"rm -f ${REMOTETMPBASHCONFIG} ${REMOTETMPVIMCONFIG}\" EXIT " ;
           logdebug "run remote shell with temporary config"
           ssh -t ${SSH_OPTS} $@ "$RCMD; SSHS=true bash -c \"function bash () { /bin/bash --rcfile ${REMOTETMPBASHCONFIG} -i ; } ; export -f bash; exec bash --rcfile ${REMOTETMPBASHCONFIG}\""
           rm "${TMPBASHCONFIG}"
        else
           logwarn "${TMPBASHCONFIG} does not exist. Using »ssh -t $@«"
           ssh -t "$@" 
        fi
    else
        logwarn "too few arguments for sshs" >&2
        ssh
    fi
    
    EXIT
}


VIMRC="${MSC_BASE}/vimrc"

svi () { 
    ENTRY
    if [ -f ${VIMRC} ]; then
        sudo vim -u "${VIMRC}" $@; 
    else
        sudo vim $@
    fi
    EXIT
}

#vim-plugins-update () {
#    ENTRY
#    vim -c "PluginUpdate" -c ":qa!"
#    EXIT
#    
#}
#
#vim-plugins-install () {
#    ENTRY
#    vim -c "PluginInstall" -c ":qa!"
#    EXIT
#    
#}

vim-repair-vundle () {
    ENTRY

    if [ -z ${MSC_BASE+x} ]; then   
        echo "MSC_BASE nicht gesetzt. Eventuell noch einmal ausloggen und wieder einloggen"
    else
        cd $MSC_BASE
        cd vim/bundle
        rm -rf Vundle.vim
        echo git clone  "${MSC_GIT_SUBMODULES_SERVER-$MSC_GIT_SUBMODULES_SERVER_DEFAULT}gmarik/Vundle.vim.git"
        git clone  "${MSC_GIT_SUBMODULES_SERVER-$MSC_GIT_SUBMODULES_SERVER_DEFAULT}gmarik/Vundle.vim.git"
        cd ~-
    fi
    EXIT
}

getbashrcfile () {
    ENTRY
    if [ -z ${BASHRC+x} ] ; then
        echo "bash uses default" >&2
    else
        cat /proc/$$/cmdline | xargs -0 echo|awk '{print $3}'
    fi
    EXIT
}

catbashrcfile () {
    ENTRY
    if [ -z ${BASHRC+x} ] ; then
        echo "bash uses default" >&2
    else
        #cat $(cat /proc/$$/cmdline | xargs -0 echo|awk '{print $3}')
        cat $(getbashrcfile)
    fi
    EXIT
}

getvimrcfile () {
    ENTRY
    if [ -z ${VIMRC+x} ] ; then
        echo "vim uses default" >&2
    else
        echo $VIMRC
    fi
    EXIT
}

catvimrcfile () {
    ENTRY
    if [ -z ${VIMRC+x} ] ; then
        echo "vim uses default" >&2
    else
        #cat $VIMRC
        cat $(getvimrcfile)
    fi
    EXIT
}


# Functions to set the correct title of the terminal
function title()
{
    
    ENTRY
   # change the title of the current window or tab
   echo -ne "\033]0;$*\007"
   
    EXIT
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

function update-hetzner-serverlist()
{
    for i in basic-services sc xe tu; do
        curl -s -H "Authorization: Bearer $(pass show hetzner.com/projects/${i}/api-token)" \
            https://api.hetzner.cloud/v1/servers \
            | /usr/bin/jq '.servers[].public_net.ipv4.ip'|sed -e 's/\"//g' \
            |while read i; do 
                dig -x $i | awk '$0 !~ /^;/ && $4 == "PTR" {print $5}' 
            done |sed -s -e 's/\.$//' > ~/.dsh/group/hetzner-servers-${i}
    done
    cat ~/.dsh/group/hetzner-servers-* > ~/.dsh/group/hetzner-servers
}

function tmuxx() {
    ENTRY
    
    case $# in
        1)
            SESS=($(find ${TMUX_SESSION_DIRS[*]} -mindepth 1 -name "$1.session" 2>/dev/null ))
            ;;
        *)
            logwarn no session specified return
            ;;
    esac
    TMUX_BIN='/usr/bin/tmux'
    $TMUX_BIN -f ~/.tmux.conf new-session -d
    [ -e ${SESS[0]} ] && $TMUX_BIN source-file ${SESS[0]}
    $TMUX_BIN attach-session -d
    EXIT
}


function checkbkp() {
    ENTRY
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
    EXIT
}
function checkbkp-full() {
    ENTRY
    if ping -c 3 backup.vpn >/dev/null 2>&1 ; then
        local SSH="/usr/bin/ssh"
        local CMD="$SSH -T backup.vpn"
        $CMD /bin/bash << EOF
        sudo find /srv/nfs/backup -mindepth 1 -maxdepth 1|grep -v -e "git$\|git-backup-repos"|while read i;do printf "%-30s%s\\n" "\$i" \$(ls \$i|tail -n1);done|sort -k 2.1 -r
EOF
        which pdsh 1>/dev/null 2>&1 && pdsh -g vpn sudo systemctl status backup.service

    else
        logwarn "backup.vpn is not reachable -> exit"
        return 1
        
    fi
    EXIT
}

turnoffbeep() {
    ENTRY
    changebeep none
    EXIT
}

changebeep() {
    ENTRY
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
            logwarn "usage: changebeep [none|visible|audible]"
            EXIT
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
    EXIT
}

turnoffconfigsync() {
    ENTRY
    local line='MSC_GIT_SYNC='
    local file=~/.bashrc
    if [ -e "${file}" ] ; then
        sed -i -e "/${line}/d" "${file}"
    fi
    sed -i -e "/#MYSHELLCONFIG-start/i${line}false" "${file}"
    EXIT
}

turnonconfigsync() {
    ENTRY
    local line='MSC_GIT_SYNC='
    local file=~/.bashrc
    if [ -e "${file}" ] ; then
        sed -i -e "/${line}/d" "${file}"
    fi
    sed -i "/#MYSHELLCONFIG-start/i${line}true" "${file}"
    EXIT
}

function gnome-shell-extensions-enable-defaults() { 
    ENTRY
    local i
    if [ -f ~/.config/gnome-shell-extensions-default.list ]; then
        for i in $(cat ~/.config/gnome-shell-extensions-default.list); do 
            #gnome-shell-extension-tool -e $i;
            gnome-extensions enable $i;
        done; 
    fi
    EXIT
}

gnome-shell-extensions-make-actual-permanent() {
    ENTRY
    file="${HOME}/.config/gnome-shell-extensions-default.list"
    local EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions)
    line="[org/gnome/shell]"
    for line in ${EXTENSIONS[@]}; do
        loginfo "add $line to $file"
        grep -xqF -- ${line} ${file} || echo $line >> $file
    done

    EXIT
}
gnome-shell-extensions-make-actual-permanent-systemwide() {
    ENTRY
    # https://people.gnome.org/~pmkovar/system-admin-guide/extensions-enable.html
    # https://askubuntu.com/questions/359958/extensions-are-turned-off-after-reboot
    local file="/etc/dconf/profile/user"
    sudo mkdir -p "/etc/dconf/profile/"
    local line='user-db:user'
    if [ -e "${file}" ] ; then
        command="grep -xqF -- ${line} ${file} || echo $line >> $file"
        logtrace "$command"
        sudo sh -c "$command"
    fi
    local line='system-db:local'
    if [ -e "${file}" ] ; then
        command="grep -xqF -- ${line} ${file} || echo $line >> $file"
        logtrace "$command"
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
    loginfo "Update or add extensions"
    #echo "${line}${EXTENSIONS}" | sudo tee -a "${file}"
    sudo sed -i "/\[org\/gnome\/shell\]/a${line}${EXTENSIONS}" "${file}"
    sudo dconf update
    EXIT
}

reachable-default () {
    local SERVER=$1
    local PORT=${2:-22}
    local res=3
    if which nc >/dev/null; then
        if nc -w 2 -z $SERVER $PORT 2>/dev/null; then
            res=0
        fi
    else
        res=2
    fi
    return $res
}

reachable () {
    ENTRY
    # returncodes:
    #   1: servername not resolveable
    #   2: command nc not found
    #   3: server:port not reachable
    #   999999: something went wrong
    #   0: server was resolve- and reachable
    GETENTHOSTS=ahosts
    local SERVER=$1
    # dig does not consult /etc/hosts, so use getent hosts instead
    #local IP=$(dig +nocmd $SERVER a +noall +answer|tail -n 1 |awk '{print $5}')
    # getent ahostsv4 returns only ipv4 addresses
    loginfo -n "Try to resolve $SERVER: "
    local IP=$(getent $GETENTHOSTS $SERVER|awk '$0 ~ /STREAM/ {print $1}'|uniq|head -n1)
    if [ -z ${IP-x} ]; then 
        logwarn "not resolvable -> exit"
        return 1
    else
        loginfo $IP
    fi
    local PORT=${2:-22}
    local SEC=${3:-1}
    local res=999
    local i
    loginfo -n "Try to connect to ${SERVER} (${IP}):${PORT} " >&2
    for i in $(seq 1 $SEC); do
        loginfo -n "." >&2
        if reachable-default ${IP} ${PORT} 2>/dev/null; then
            res=0
            break
        else
            res=$?
        fi
        [ ${SEC} -gt 1 -a $i -lt ${SEC} ] && sleep 1
    done

    [ ${res} -gt 0 ] && loginfo " not reachable" >&2 || loginfo " success" >&2; 

    EXIT
    return $res

}

utoken () {

    ENTRY
    ssh_identity=$1

    [ -z "${P11M+x}" ] && { P11M=$PKCS11_MODULE; export P11M; }
    
    if [ -n "${ssh_identity+x}" ]; then
        agentfile="${HOME}/.ssh/agents/agent-${ssh_identity}-$(hostname)"
        if [ -e "$agentfile" ]; then 
            local SSH_AUTH_SOCK
            local SSH_AGENT_PID
            /bin/sh -c ". $agentfile >/dev/null 2>/dev/null; ssh-add -l; ssh-add -e $P11M; ssh-add -l"
        fi
    fi
    EXIT
}

token(){

    [ -z "${P11M:+x}" ] && { P11M=$PKCS11_MODULE; export P11M; }

    tmppubkey="${XDG_RUNTIME_DIR}/token.pub"
    # Write public keys of all in agent stored keys to a temporary file
    loginfo "$(ssh-add -L > $tmppubkey)"

    # Usage:
    #   token <identity>                        will load token in agent. does nothing, if token is already loaded
    #   token -r|-f|--reload-token <identity>   will remove token from agent and add it again (if plugged off and plugged in again
#    startagent -t $@
#    loadagent $@
    # Check if public-keys in tmppubkey are working. They are not working, if you removed and add back hardware-token. 
    loginfo "$(ssh-add -T ${tmppubkey} || { ssh-add -e $P11M; ssh-add -s $P11M; } )"
    loginfo "$(ssh-add -l)"

}


token-extract-pubkey() {
    if pkcs11-tool --module $P11M --list-token-slots >&2 ;then
        ssh-keygen -i -m pkcs8 -f <(pkcs11-tool --module $P11M -r --type pubkey ${1:+--label} ${1} |openssl rsa -pubin -inform DER )
        if [ $? -gt 0 ] ; then
            token-list-objects >&2
        fi
    else
        echo "Please insert token. Exit" >&2
        return 1
    fi
}

token-list-objects() {
    case $1 in
        --login|-l)
            pkcs11-tool --module $P11M --login --list-objects
            ;;
        *)
            pkcs11-tool --module $P11M --list-objects
            ;;
    esac

}

loadagent() {
    ENTRY
    local af
    af=$(startagent --create-only $1 )
    loginfo "Load agent from $af"
    unset SSH_AUTH_SOCKET SSH_AGENT_PID
    eval $(<$af)
    logdebug "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK-not set}"
    logdebug "SSH_AGENT_PID: ${SSH_AGENT_PID-not set}"
    loginfo "currently loaded keys in agent:
$(ssh-add -l)"

    EXIT
}

setloglevel () {
    ENTRY
    local loglevels
    local oldloglevel=${LOGLEVEL-$LOGLEVEL_DEFAULT}
    declare -a loglevels
    loglevels=("ERROR" "WARN" "INFO" "DEBUG" "TRACE")
    if [[ ${loglevels[*]} =~ "${1^^}" ]]; then
        export LOGLEVEL=${1^^}
    else
        logerror "LOGLEVEL must be one of ERROR, WARN, INFO, DEBUG or TRACE"
    fi
    logerror "change LOGLEVEL from $oldloglevel -> $LOGLEVEL"
    EXIT
}

setfileloglevel () {
    ENTRY
    local loglevels
    local oldloglevel=${FILELOGLEVEL-${FILELOGLEVEL_DEFAULT}}
    declare -a loglevels
    loglevels=("ERROR" "WARN" "INFO" "DEBUG" "TRACE")
    if [[ ${loglevels[*]} =~ "$1" ]]; then
        export FILELOGLEVEL=$1
    else
        logerror "FILELOGLEVEL must be one of ERROR, WARN, INFO, DEBUG or TRACE"
    fi
    logerror "change FILELOGLEVEL from $oldloglevel -> $FILELOGLEVEL"
    EXIT
}

getloglevels () {
    ENTRY
    cat << EOF |tee -a $SCRIPT_LOG
    LOGLEVEL: ${LOGLEVEL-${LOGLEVEL_DEFAULT}}
    FILELOGLEVEL: ${FILELOGLEVEL-${FILELOGLEVEL_DEFAULT}}

    change LOGLEVEL: \$ setloglevel [ERROR|WARN|INFO|DEBUG|TRACE]
    change FILELOGLEVEL: \$ setfileloglevel [ERROR|WARN|INFO|DEBUG|TRACE]
EOF

}

rescan_scsi () {
    echo "- - -" > /sys/class/scsi_host/host0/scan
}

get_crtime() {
  for target in "${@}"; do
    inode=$(stat -c %i "${target}")
    fs=$(df  --output=source "${target}"  | tail -1)
    crtime=$(sudo debugfs -R 'stat <'"${inode}"'>' "${fs}" 2>/dev/null | 
    grep -oP 'crtime.*--\s*\K.*')
    printf "%s\t%s\n" "${target}" "${crtime}"
  done
    }

# jira-confluence-specific is temporary in here
#function getdbcreds_jira () {
#    [ $# -eq 0 ] return 1
#
#    DB_FILE=$1
#
#    DB_URL="$(grep -oPm1 "(?<=<url>)[^<]+" ${DB_FILE})"
#    DB_USER="$(grep -oPm1 "(?<=<username>)[^<]+" ${DB_FILE})"
#    DB_PWD="$(grep -oPm1 "(?<=<password>)[^<]+" ${DB_FILE})"
#    DB_HOST="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*):\(.*\)/\(.*\)$@\1@')"
#    DB_PORT="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*):\(.*\)/\(.*\)$@\2@')"
#    DB_NAME="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*):\(.*\)/\(.*\)$@\3@')"
#
#    cat << \
#        EOF
#        DB_HOST: ${DB_HOST}
#        DB_PORT: ${DB_PORT}
#        DB_NAME: ${DB_NAME}
#        DB_USER: ${DB_USER}
#        DB_PWD:  ${DB_PWD}
#EOF
#    return 0
#}


is_btrfs_subvolume() {
    sudo btrfs subvolume show "$1" >/dev/null
}

convert_to_subvolume () {
    local XSUDO
    local DIR
    case $1 in
        --sudo|-s)
            XSUDO=sudo
            shift
            ;;
    esac
    DIR="${1}"
    [ -d "${DIR}" ] || return 1
    is_btrfs_subvolume "${DIR}" && return 0
    set -x
    #btrfs subvolume create "${DIR}".new && \ 
    ${XSUDO:+sudo} btrfs subvolume create "${DIR}.new" && \
    /bin/cp -aTr --reflink=always "${DIR}" "${DIR}".new && \ 
    mv "${DIR}" "${DIR}".orig && \
    mv "${DIR}".new "${DIR}" || return 2

    set +x
    return 0


}

getfreeip () {
    local N=$1
    sudo nmap -v -sn -n $1 -oG - | awk '/Status: Down/{print $2}'
}

cporig () {

    cp -b -i "${1}" "${1}.orig"

}

vgrename_full () {

    altevolumegroup="$1"
    neuevolumegroup="$2"

    vgrename ${altevolumegroup} ${neuevolumegroup}
    sed -i "s/${altevolumegroup}/${neuevolumegroup}/g" /etc/fstab
    sed -i "s/${altevolumegroup}/${neuevolumegroup}/g" /boot/grub/grub.cfg
    sed -i "s/${altevolumegroup}/${neuevolumegroup}/g" /boot/grub/menu.lst
    sed -i "s/${altevolumegroup}/${neuevolumegroup}/g" /etc/initramfs-tools/conf.d/resume
    update-initramfs -c -k all
}

getfreeip () {
    
    local N=$1

    sudo nmap -v -sn -n $1 -oG - | awk '/Status: Down/{print $2}'

}

getusedip () {

    local N=$1
    local DNS=$2

    sudo nmap -v -sn -n $1 -oG - | awk '!/Status: Down/{print $2}'|while read i;do 
        echo "$i: $(dig "${DNS:+@}${DNS}" -x $i +short +search)"
        
    done

}

function getdbcreds_jra () {
    case $# in
        0)
            gojirahome
            DB_FILE=dbconfig.xml
            cd -
            ;;
        1)
            DB_FILE=$1
            ;;
        *)
            echo "wrong number of arguments"
            return 1
            ;;
    esac

    DB_URL="$(grep -oPm1 "(?<=<url>)[^<]+" ${DB_FILE})"
    DB_USER="$(grep -oPm1 "(?<=<username>)[^<]+" ${DB_FILE})"
    DB_PWD="$(grep -oPm1 "(?<=<password>)[^<]+" ${DB_FILE})"
    DB_HOST="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*\):\(.*\)/\(.*\)$@\1@')"
    DB_PORT="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*\):\(.*\)/\(.*\)$@\2@')"
    DB_NAME="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*\):\(.*\)/\(.*\)$@\3@')"

    return 0
}

function getdbcreds_cnf () {
    case $# in
        0)
            gocnfhome
            DB_FILE=confluence.cfg.xml
            ;;
        1)
            DB_FILE=$1
            ;;
        *)
            echo "wrong number of arguments"
            cd -
            return 1
            ;;
    esac

    DB_URL="$(grep -oPm1 "(?<=<property name=\"hibernate.connection.url\">)[^<]+" ${DB_FILE})"
    DB_USER="$(grep -oPm1 "(?<=<property name=\"hibernate.connection.username\">)[^<]+" ${DB_FILE})"
    DB_PWD="$(grep -oPm1 "(?<=<property name=\"hibernate.connection.password\">)[^<]+" ${DB_FILE})"
    DB_HOST="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*\):\(.*\)/\(.*\)$@\1@')"
    DB_PORT="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*\):\(.*\)/\(.*\)$@\2@')"
    DB_NAME="$(echo $DB_URL|sed 's@^.*//@@;s@\(^.*\):\(.*\)/\(.*\)$@\3@')"

    cd -
    return 0
}
function connectdb () {

    case $1 in 
        jra|jira)
            getdbcreds_jra
            ;;
        cnf|conf|confluence)
            getdbcreds_cnf
            ;;
        *)
            echo "wrong argument"
            return 1
            ;;
    esac

    PGPASSWORD=$DB_PWD psql -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME
}
#EOF

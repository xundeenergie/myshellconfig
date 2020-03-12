# myshellconfig

Am Einfachsten ist es, das github-Repo zu forken und in .gitconfig den Namen und die Emailadresse an die eigenen Werte anzupassen. Das Repo ist öffentlich, also keine Passwörter speichern!!!

## ACHTUNG
Diese automatische Konfiguration überschreibt bei jedem Login in ${HOME} einige Dateien mit Symlinks in das lokale Repo. Die zuvor vorhandenen Dateien werden nicht gesichert und gehen daher verloren.
Folgende Dateien werden durch Symlinks ersetzt. Diese bitte VOR dem ersten Aufruf sichern.

```
~/.gitconfig -> ${HOME}/.local/myshellconfig/.gitconfig
~/.tmux -> ${HOME}/.local/myshellconfig/tmux
~/.tmux.conf -> ${HOME}/.local/myshellconfig/tmux/tmux.conf
~/.vim -> ${HOME}/.local/myshellconfig/vim
~/.vimrc -> ${HOME}/.local/myshellconfig/vimrc
```

**Bitte beachten, dass damit eine schon vorhandene eigene Datei überschrieben wird!**

## Proxy
Wenn in einem Setup ein Proxy verwendet werden muss, so ist dieser VORHER zu konfigurieren. Da Proxyeinstellungen Hostabhängig sind und nicht generell in die allgemeine Konfiguration aufgenommen werden können, sind die Proxy-Einstellungen für git im File

~/.gitconfig_local
```
[http]
        proxy = http://username:password@proxy.domain.tld:1233/
```

abzulegen. Die verteilte .gitconfig enthält bereits eine Zeile, welche dieses lokale File für git sourced.


## Installation
Damit auf einem neuen Server meine persönlichen Alias und Bash-Promt, wie auch verschiedene andere Befehle (vim in sudo mit der vimrc des Benutzers) zur Verfügung stehen, muss als erstes nach dem ersten Login folgendes ausgeführt werden:

Clone von github
```
git clone https://github.com/xundeenergie/myshellconfig.git ${HOME}/.local/myshellconfig
```

~/.bashrc ist am Ende um folgende Zeilen zu ergänzen
```
#MYSHELLCONFIG-start
if [ -e ~/.local/myshellconfig/bashrc_add ]; then . ~/.local/myshellconfig/bashrc_add; fi
#MYSHELLCONFIG-end
```
Ausloggen und neu Einloggen.

## Lokale Configuration
in ~/.bashrc werden vor der Zeile zum Einbinden der myshellconfig die Variablen eingefügt um damit ein hostspezifisches Verhalten zu steuern
```
MYSHELLCONFIG_GIT_CHECKOUTSCRIPT_OPTIONS=
```
Mögliche Optionen:

    * -h
    * ''

Verwendung: Damit kann man angeben, ob ein headless Repo erzeugt wird. Ohne -h folgt das Repo origin/master
Default ist die Option "-h". Soll ein normales Repo (nicht headless) verwendet werden, so MUSS die Variable so gesetzt werden

```
MYSHELLCONFIG_GIT_CHECKOUTSCRIPT_OPTIONS=""
```

### Git Protokolle für push und pull
```
MYSHELLCONFIG_GIT_REMOTE_PROTOCOL=git # git ist default
MYSHELLCONFIG_GIT_REMOTE_PUSH_PROTOCOL=$MYSHELLCONFIG_GIT_REMOTE_PROTOCOL # MYSHELLCONFIG_GIT_REMOTE_PROTOCOL ist default
```

Mögliche Optionen:

    * git - (default) Gitprotokoll ist git (Auf manchen Umgebungen kann der dazu notwenidge Port gesperrt sein)
    * http - wenn git nicht möglich ist, kann das http/https Protokoll verwendet werden. (ist langsamer als git, jedoch ist fast überall Port 80 oder 440 freigeschaltet)
    * ssh - Wenn auch schreibend auf das Repo zugegriffen werden soll, so muss Privatekey, Pubkey (und wenn konfiguriert Certifikate mit den notwendigen Principals) vorhanden sein, dann kann das ssh-Prodokoll verwendet werden.
    * file - Das entfernte Repository ist auf einem USB-Stick, welcher unter /media/$USER/gitstick beim Einstecken gemountet wird. Der Pfad ist anpassbar (siehe MYSHELLCONFIG_GIT_REPO_PATH)

Vim Plugins werden prinzipiell von github.com bezogen. Für spezielle Anwendungsfälle (github.com ist per firewall gesperrt), kann man diese auch in eigenen Repos hosten. Um diese eigenen Repos zu verwenden, muss in ~/.bashrc die Variable entsprechend gesetzt werden. Es ist ein Verzeichnis anzugeben, unter dem alle Pluginrepos als bare-Repos gecloned werden. Wichtig ist, dass die Usernamenverzeichnisse von github.com hier auch vorhanden sind, damit ohne dieser gesetzten Variable die Plugins direkt von github.com geladen werden können.

```
MYSHELLCONFIG_VIM_PLUGINS=https://my.git.server/public/Vim
```

Z.B. das Plugin Vundle.vim hat ist auf github unter dieser URL zu finden
```
//github.com/gmarik/Vundle.vim.git
```
Damit ist das eigene Repo am eigenen git-server unter dieser Adresse erreichbar zu machen wenn die Variable MYSHELLCONFIG\_VIM\_PLUGINS wie oben Angegeben gesetzt wird.:
```
https://my.git.server/public/Vim/gmarik/Vundle
```

### Über ~/.bashrc manuell festlegbare Variablen und ihre Default-Werte, wenn nicht manuell gesetzt:
```
MYSHELLCONFIG_SUBPATH=.local/myshellconfig
MYSHELLCONFIG_BASE="${HOME}/${MYSHELLCONFIG_SUBPATH}"
MYSHELLCONFIG_LOGDIR="${MYSHELLCONFIG_BASE}/logs"
MYSHELLCONFIG_LOGFILE="${MYSHELLCONFIG_LOGDIR}/git.log"
MYSHELLCONFIG_GIT_TIMEOUT=5s

MYSHELLCONFIG_GIT_SERVER="git.schuerz.at"
MYSHELLCONFIG_GIT_REPO_NAME="server-config.git"
MYSHELLCONFIG_GIT_REPO_PATH_HTTP="/public/"
MYSHELLCONFIG_GIT_REPO_PATH_SSH=":public/"
MYSHELLCONFIG_GIT_REPO_PATH_GIT="/public/"
```


# Verteilen auf neuen Host/User
Einen neuen User auf einem anderen Host mit der selben Konfiguration versehen funktioniert folgendermaßen:

```
sshmyshellconfig USER@HOST
```
und dann auf dem Host einloggen
```
ssh USER@HOST
```
es können die üblichen ssh-Optionen und Parameter verwendet werden.



## Signieren der Commits mit gpg
Wenn man seine Commits signieren möchte, kann dazu in der Datei
```
~/.gitconfig_local
```
folgendes eingetragen werden:

```
[user]
	signingKey = 0xABC123DEF456GHI7
[gpg]
	program = gpg2

```

signingKey muss natürlich dem eigenen gpg-Key entsprechen, der lokal vorhanden ist und verwendet werden soll.

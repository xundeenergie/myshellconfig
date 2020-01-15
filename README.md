# server-config

Am Einfachsten ist es, das github-Repo zu forken und in .gitconfig den Namen und die Emailadresse an die eigenen Werte anzupassen. Das Repo ist öffentlich, also keine Passwörter speicher!!!

.gitconfig wird von diesem Repo beim Einrichten nach ~/.gitconfig gelinkt. Bitte beachten, dass damit eine schon vorhandene eigene Datei überschrieben wird!

Soll ein Proxy zum Einsatz kommen, so ist dieser mittels
```
git config http.proxy "http://proxy.to.use:prot/"
```
local für jedes Repo zu konfigurieren. Die globale gitconfig für den User wird auf allen eingesetzten Instanzen verteilt und versioniert!

## Installation
Damit auf einem neuen Server meine persönlichen Alias und Bash-Promt, wie auch verschiedene andere Befehle (vim in sudo mit der vimrc des Benutzers) zur Verfügung stehen, muss als erstes nach dem ersten Login folgendes ausgeführt werden:

Clone von github
```
git clone https://github.com/xundeenergie/myshellconfig.git ~/.local/myshellconfig
```

~/.bashrc ist am Ende um folgende Zeilen zu ergänzen
```
#MYSHELLCONFIG-start
if [ -e ~/.local/myshellconfig/bashrc_add ]; then
  . ~/.local/myshellconfig/bashrc_add;
else
  if [ -f ~/bashrc_add ] ;then
    . ~/bashrc_add;
  fi;
fi
#MYSHELLCONFIG-end
```
Ausloggen und neu Einloggen.

## Lokale Configuration
in ~/.bashrc werden vor der Zeile zum Einbinden der myshellconfig die Variablen eingefügt um damit ein hostspezifisches Verhalten zu steuern
MYSHELLCONFIG\_GIT\_CHECKOUTSCRIPT\_OPTIONS=
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
MYSHELLCONFIG\_GIT\_REMOTE\_PROTOCOL=git # git ist default
MYSHELLCONFIG\_GIT\_REMOTE\_PUSH\_PROTOCOL=$MYSHELLCONFIG\_GIT\_REMOTE\_PROTOCOL # MYSHELLCONFIG\_GIT\_REMOTE\_PROTOCOL ist default
```

Mögliche Optionen:

    * git - (default) Gitprotokoll ist git (Auf manchen Umgebungen kann der dazu notwenidge Port gesperrt sein)
    * http - wenn git nicht möglich ist, kann das http/https Protokoll verwendet werden. (ist langsamer als git, jedoch ist fast überall Port 80 oder 440 freigeschaltet)
    * ssh - Wenn auch schreibend auf das Repo zugegriffen werden soll, so muss Privatekey, Pubkey (und wenn konfiguriert Certifikate mit den notwendigen Principals) vorhanden sein, dann kann das ssh-Prodokoll verwendet werden.

Vim Plugins werden prinzipiell von github.com bezogen. Für spezielle Anwendungsfälle (github.com ist per firewall gesperrt), kann man diese auch in eigenen Repos hosten. Um diese eigenen Repos zu verwenden, muss in ~/.bashrc die Variable entsprechend gesetzt werden. Es ist ein Verzeichnis anzugeben, unter dem alle Pluginrepos als bare-Repos gecloned werden. Wichtig ist, dass die Usernamenverzeichnisse von github.com hier auch vorhanden sind, damit ohne dieser gesetzten Variable die Plugins direkt von github.com geladen werden können.

MYSHELLCONFIG\_VIM\_PLUGINS=https://my.git.server/public/Vim

### Über ~/.bashrc manuell festlegbare Variablen und ihre Default-Werte, wenn nicht manuell gesetzt:
MYSHELLCONFIG\_SUBPATH=.local/myshellconfig
MYSHELLCONFIG\_BASE="${HOME}/${MYSHELLCONFIG\_SUBPATH}"
MYSHELLCONFIG\_LOGDIR="${MYSHELLCONFIG\_BASE}/logs"
MYSHELLCONFIG\_LOGFILE="${MYSHELLCONFIG\_LOGDIR}/git.log"
MYSHELLCONFIG\_GIT\_TIMEOUT=5s

MYSHELLCONFIG\_GIT\_SERVER="git.schuerz.at"
MYSHELLCONFIG\_GIT\_REPO\_NAME="server-config.git"
MYSHELLCONFIG\_GIT\_REPO\_PATH\_HTTP="/public/"
MYSHELLCONFIG\_GIT\_REPO\_PATH\_SSH=":public/"
MYSHELLCONFIG\_GIT\_REPO\_PATH\_GIT="/public/"


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



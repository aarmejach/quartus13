# Instruccions per installar Quartus i Modelsim

## Dependències
Instal·lar docker. Instruccions aqui:
```
https://docs.docker.com/engine/install/
```

## Setup

Clonar el següent repository:
```bash
git clone https://github.com/aarmejach/quartus13.git
cd quartus13
export QUARTUS_PATH=$PWD
```

Descarregar Quartus II 13.0sp1 Web Edition
```
https://www.intel.com/content/www/us/en/software-kit/711790/intel-quartus-ii-web-edition-design-software-version-13-0sp1-for-linux.html
```

Descomprimir el tar i moure els seguents fitxers a `QUARTUS_PATH`:
```
arria_web-13.0.1.232.qdz
cyclonev-13.0.1.232.qdz
cyclone_web-13.0.1.232.qdz
max_web-13.0.1.232.qdz
ModelSimSetup-13.0.1.232.run
QuartusHelpSetup-13.0.1.232.run
QuartusSetupWeb-13.0.1.232.run
```

Genera la imatge base incloent ModelSim:
```bash
docker build -t quartus_base:13.0.1.2 -f Dockerfile_with_modelsim .
```

Genera la imatge final amb tag `quartus:13.0.1.2` usant com a base la imatge anterior:
```
docker build -t quartus:13.0.1.2 -f Dockerfile_devices --build-arg QUARTUS_BASE=quartus_base:13.0.1.2 .
```

Despres de generar la imatge final es pot borrar la cache:
```
docker builder prune
```

Executar Quartus:
```bash
$QUARTUS_PATH/shell/quartus
```

Executar Quartus a macOS:
```bash
$QUARTUS_PATH/shell-macos/quartus
```

## ModelSim
Si al executar modelsim teniu un error de llicencies, heu de seleccionar una altra versió de ModelSim.

Aneu a `Tools->Options->EDA Tool Options` i a la ruta de ModelSim poseu la versio `_ase`
```
/opt/altera/13.0sp1/modelsim_ase/linuxaloem
```

# Usar Podman en lloc de Docker

Si no teniu Docker (per exemple, a màquines on només hi ha Podman), podeu fer servir Podman en mode *rootless*.

Instal·lar Podman:
```bash
sudo apt install podman
```

Comproveu que el vostre usuari té un rang de subuids/subgids assignat (necessari per construir la imatge):
```bash
grep $USER /etc/subuid /etc/subgid
```

## Construir la imatge

*Atenció:* la construcció necessita uns 30 GB lliures al disc on Podman guarda les imatges (per defecte `~/.local/share/containers`). En el pic, la imatge base té dues còpies de la instal·lació de Quartus + ModelSim (~13 GB cadascuna). La imatge final ocupa uns 15 GB.

Seguiu les mateixes passes de [Setup](#setup), però canviant `docker` per `podman`:
```bash
podman build -t quartus_base:13.0.1.2 -f Dockerfile_with_modelsim .
podman build -t quartus:13.0.1.2 -f Dockerfile_devices --build-arg QUARTUS_BASE=quartus_base:13.0.1.2 .
```

Despres de generar la imatge final es poden borrar les imatges intermèdies:
```bash
podman image prune -f
```

## Copiar la imatge a una altra màquina

Podeu construir la imatge en una màquina i fer-la servir en una altra on només hi ha Podman:
```bash
# A la màquina on s'ha construit
podman save -o quartus-13.0.1.2.tar quartus:13.0.1.2
# A la màquina destí
podman load -i quartus-13.0.1.2.tar
```

## Executar Quartus

Els mateixos scripts detecten automàticament si cal fer servir Docker o Podman:
```bash
$QUARTUS_PATH/shell/quartus
```

Si teniu els dos instal·lats i voleu forçar Podman:
```bash
CONTAINER_ENGINE=podman $QUARTUS_PATH/shell/quartus
```

Amb Podman rootless, dins del contenidor sou `root`, però aquest `root` correspon al vostre usuari a la màquina host: els fitxers que es creen al vostre `$HOME` són vostres.

Per programar la placa (USB-Blaster) amb Podman, el vostre usuari ha de tenir permís d'escriptura al dispositiu USB a la màquina host (per exemple, amb una regla udev).

# Instal·lar entorn per a macOS ARM M1+

És possible executar Quartus i Modelsim a un màquina Mac amb el processador M1 o superior.
Per fer-ho, primerament és necessari tenir instalat el gestor de paquets Homebrew. Per fer-ho,
consulteu https://brew.sh .

Un cop instal·lat Homebrew, cal instalar els següents paquets.

## Docker
```
brew install docker
brew install docker-compose
```

## Colima
```
brew install colima
brew install lima-additional-guestagents
```

## QEMU
```
brew install qemu
```

## XQuartz
```
brew install --cask xquartz
```

## IMPORTANT
Seguint les mateixes instruccions que es descriuen més amunt per instal·lar Quartus i Modelsim, abans d'executar Docker és necessari inicialitzar Colima perquè s'iniciï l'entorn de la màquina virtual. També cal configurar les variables d'entorn necessàries perquè XQuartz pugui funcionar correctament. A continuació s'explica com fer-ho.

### Inicialitzar Colima
```bash
colima start --arch x86_64 --vz-rosetta
```

Si es vol assignar més recursos (memòria i cores) a la màquina virtual, executa:
```bash
colima start --arch x86_64 --vz-rosetta --memory X --cpu Y
```
*Precaució:* Els paràmetres de memòria dependran dels recursos disponibles a la vostra màquina.
Si s'assignen massa recursos, és possible patir problemes a la màquina host i congelar el sistema. L'ideal és assignar un 40-60% de la RAM total i de 2 a 4 cores.

Aquesta comanda s'haura d'executar abans d'instalar Quartus i cada cop que es vulgui executar-lo.

### Inicialitzar correctament la variable d'entorn DISPLAY

```bash
export DISPLAY=:0
```

### Donar permís a connexions locals per emprar XQuartz

Executar:
```bash
open -a XQuartz
```

Anar a XQuartz -> Settings -> Security -> Allow connections from network clients.

Executar:
```bash
xhost +local:
```

Continuar les instruccions que s'expliquen més amunt per a instalar Quartus i Modelsim.

### Parar l'execució de Colima

```bash
colima stop
```

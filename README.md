# Anleitung zur Installation eines Matrix-Servers

## Referenzen
Anleitung in Anlehnung an:
* [Matrix Synapse Hosting Guide](https://matrix.org/docs/older/understanding-synapse-hosting/)
* [NethServer Community Guide](https://community.nethserver.org/t/install-matrix-synapse-including-whatsapp-bridge-using-docker-compose/21214)

## Beispiel-Configurations-Dateien
* install_docker.sh
* docker-compose.yml
* homeserver.yaml
* default.conf

## VPS Host
Voraussetzung für die Installation ist ein Host mit einer öffentlichen Internetadresse.
* Beispiel-Hosting-Anbieter: [Netcup](https://www.netcup.com)
* VPS mit Public IP/ Domain (Beispiel): `185.xxx.xxx.xxx` / `v2200000000000000000.nicesrv.de`

![VPS Host](/figures/architektur_setup.png)

## Debian 12 installieren
Die Installation des Betriebssystems erfolgt über ein bereitgestelltes Image:
1. Debian 12-Image auswählen und mit Root-User installieren.
2. SSH-Login (z.B. mit Putty) mit Root und bereitgestelltem Passwort.
3. System-Update durchführen:
```bash
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo reboot
```

## Docker, Docker Compose, Portainer installieren
Da der Matrix-Server über Docker bereitgestellt wird:
1. SSH-Login (z.B. mit WinSCP) mit Root und bereitgestelltem Passwort.
2. Installationsverzeichnis `docker` anlegen und ins Verzeichnis wechseln.
3. `install_docker.sh` ins Installationsverzeichnis kopieren.
4. Skript ausführbar machen:
```bash
chmod +x install_docker.sh
```
5. Skript mit Root-Rechten ausführen:
```bash
sudo ./install_docker.sh
```

## Portainer starten
Die Container-Administrations-Software sollte nun laufen und kann über den Browser aufgerufen werden:
* `https://185.xxx.xxx.xxx:9443/#!/home`
* Beim ersten Login einen Administrator-Account anlegen.

## Synapse, Postgres, NGINX, Traefik, pgAdmin, Element installieren
1. SSH-Login mit Root.
2. Installationsverzeichnis `matrix` anlegen und ins Verzeichnis wechseln.
3. Konfigurationsdatei `homeserver.yaml` erstellen:
```bash
docker run --rm --mount type=volume,src=matrix_synapse_data,dst=/data \
-e SYNAPSE_SERVER_NAME=v2200000000000000000.nicesrv.de \
-e SYNAPSE_REPORT_STATS=yes \
matrixdotorg/synapse:latest generate
```
4. Datei unter `/matrix/data` editieren. In unserm Beispiel wird die Postgres-DB konfiguriert und eingestellt, dass sich Benutzer selbst registieren können. Ein Captcha sichert dies ab. Details zu den möglichen Konfigurationen inkl. Google Captcha finden sich im Internet. 

![Konfigurationsdatei](/figures/homeserver_yaml.png)

5. `docker-compose.yaml` ins Installationsverzeichnis kopieren.
6. `.env`-Datei mit geheimen Infos erstellen (`ACME_EMAIL=,PGADMIN_EMAIL=,PGADMIN_PASSWORD=,POSTGRES_PASSWORD=,POSTGRES_USER=`).
7. Container starten:
```bash
docker compose up -d
```
8. Verzeichnisstruktur prüfen:

![Docker Volumes](/figures/docker_volumes.png)

## Administrator-Account erstellen
1. In Portainer einloggen und die Container-Konsole des Synapse-Containers öffnen.
2. Admin-User erstellen:
```bash
docker exec -it matrix-synapse-1 register_new_matrix_user \
http://localhost:8008 -c /data/homeserver.yaml \
-u SuperAdmin -p MeinSicheresAdminPW1234 --admin
```
3. Weitere Benutzer ohne `--admin` erstellen.
4. Synapse-Administrator-Console unter `https://admin.v2200000000000000000.nicesrv.de/` nutzen.

## Login über Element
1. Web-Client nutzen: [Element](https://app.element.io/).

![Element Login](/figures/client_element.png)

## Federation
1. NGINX konfigurieren. default.conf ins Verzeichnis kopieren.
2. Federation in homeserver.yaml konfigurieren
3. Überprüfen, ob die Konfiguration für die Federation korrekt ist:

[Federation Tester](https://federationtester.matrix.org/)

## WhatsApp-Bridge installieren
1. Installationsverzeichnis `mautrix-whatsapp` anlegen und wechseln.
2. Docker-Image herunterladen:
```bash
docker pull dock.mau.dev/mautrix/whatsapp:latest
```
3. Initiale Konfigurationsdatei erstellen:
```bash
docker run --rm -v `pwd`:/data:z dock.mau.dev/mautrix/whatsapp:latest
```
4. Konfigurationsdatei ins Syanpse-Volume-Verzeichnis kopieren
5. homeserver.yaml anpassen
6. Container starten:
```bash
docker run --restart unless-stopped --network=matrix_matrix_network \
-v `pwd`:/data:z dock.mau.dev/mautrix/whatsapp:latest
```
7. Datenbank erstellen:
```bash
docker exec -it matrix-synapse_db-1 psql -U synapse
CREATE DATABASE mautrix ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' 
template=template0 OWNER synapse;
\q
```
8. Matrix-Client verwenden und Bot hinzufügen (`@whatsappbot:v2200000000000000000.nicesrv.de`).
9. Authentifizierung mit `login qr` und WhatsApp-App-Scan durchführen.


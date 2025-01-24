#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # #
#                Konfiguration                #
# # # # # # # # # # # # # # # # # # # # # # # #
#Quelle: https://schroederdennis.de/docker/docker-volume-backup-script-sichern-mit-secure-copy-scp-nas/#
# Dieses Skript erstellt ein Backup von Docker-Volumes und kopiert es auf einen entfernten Server.

# Verzeichnis, das gesichert werden soll
source_dir="/var/lib/docker/volumes"
# Verzeichnis, in dem die Backups gespeichert werden sollen
backup_dir="/opt/docker_backups"
# Anzahl der zu behaltenden Backups
keep_backups=10
# Aktuelles Datum und Uhrzeit
current_datetime=$(date +"%Y-%m-%d_%H-%M-%S")
# Name für das Backup-Archiv
backup_filename="${current_datetime}-backup.tar"
# Zielserver-Informationen
remote_user="user"
remote_server="IP-Adresse"
remote_dir="/home/user/docker-backups"
# # # # # # # # # # # # # # # # # # # # # # # #
#           Ende der Konfiguration            #
# # # # # # # # # # # # # # # # # # # # # # # #

remote_target="${remote_user}@${remote_server}"
backup_fullpath="${backup_dir}/${backup_filename}"

# Docker-Container herunterfahren
docker stop $(docker ps -q)
# Erstelle das Backup-Archiv
tar -cpf "${backup_fullpath}" "${source_dir}"
# Docker-Container wieder starten
docker start $(docker ps -a -q)
# Komprimiere das Backup-Archiv
gzip "${backup_fullpath}"
backup_fullpath="${backup_fullpath}.gz"
# Kopiere das Backup auf den Zielserver mit SCP ohne Passwort
scp "${backup_fullpath}" "${remote_target}:$remote_dir/"
# Lösche ältere lokale Backups mit `find`
find "$backup_dir" -type f -name "*-backup.tar.gz" -mtime +$keep_backups -e># Lösche ältere remote Backups mit `find`
ssh "${remote_target}" "find ${remote_dir} -type f -name '*-backup.tar.gz' >
echo "Backup wurde erstellt: ${backup_fullpath} und auf ${remote_target} ko>

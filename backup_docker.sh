#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# # # # # # # # # # # # # # # # # # # # # # # #
#                Konfiguration                #
# # # # # # # # # # # # # # # # # # # # # # # #
source_dir="/var/lib/docker/volumes"      # Verzeichnis, das gesichert werden soll
backup_dir="/opt/docker_backups"          # Verzeichnis, in dem die Backups gespeichert werden sollen
keep_backups=10                           # Anzahl der Tage, ab denen Backups gelöscht werden
current_datetime=$(date +"%Y-%m-%d_%H-%M-%S")
backup_filename="${current_datetime}-backup.tar.gz"  # Direkt komprimiertes Archiv
remote_user="user"
remote_server="192.168.178.101"
remote_dir="/home/user/docker-backups"    # Zielverzeichnis auf dem Remote-Server
# # # # # # # # # # # # # # # # # # # # # # # #
#           Ende der Konfiguration            #
# # # # # # # # # # # # # # # # # # # # # # # #

remote_target="${remote_user}@${remote_server}"
backup_fullpath="${backup_dir}/${backup_filename}"

# Logging-Funktion
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $*"
}

# Backup-Verzeichnis anlegen, falls nicht vorhanden
mkdir -p "${backup_dir}"

# Funktion zum Neustarten von Docker-Containern
restart_containers() {
    local container_ids
    container_ids=$(docker ps -a -q)
    if [ -n "${container_ids}" ]; then
        log "Starte alle Docker-Container neu..."
        docker start ${container_ids} > /dev/null 2>&1 || log "Warnung: Einige Container konnten nicht gestartet werden."
    fi
}

# Bei Fehlern werden die Container neu gestartet
trap 'log "Fehler aufgetreten. Starte Docker-Container neu."; restart_containers; exit 1' ERR

# Nur laufende Container stoppen
running_containers=$(docker ps -q)
if [ -n "${running_containers}" ]; then
    log "Stoppe alle laufenden Docker-Container..."
    docker stop ${running_containers} > /dev/null
else
    log "Keine laufenden Container gefunden."
fi

log "Erstelle Backup-Archiv: ${backup_fullpath}"
# Erstelle ein tar.gz-Archiv; -C sorgt dafür, dass der Archivinhalt relativ abgelegt wird
tar -czpf "${backup_fullpath}" -C "$(dirname "${source_dir}")" "$(basename "${source_dir}")"

log "Backup-Archiv erstellt: ${backup_fullpath}"

# Docker-Container neu starten
restart_containers

log "Kopiere Backup auf den Remote-Server (${remote_target})..."
scp "${backup_fullpath}" "${remote_target}:${remote_dir}/"

log "Lösche lokale Backups, die älter als ${keep_backups} Tage sind..."
find "${backup_dir}" -type f -name "*-backup.tar.gz" -mtime +${keep_backups} -exec rm -v {} \;

log "Lösche auf dem Remote-Server Backups, die älter als ${keep_backups} Tage sind..."
ssh "${remote_target}" "find ${remote_dir} -type f -name '*-backup.tar.gz' -mtime +${keep_backups} -exec rm -v {} \;"

log "Backup wurde erstellt: ${backup_fullpath} und auf ${remote_target} kopiert."

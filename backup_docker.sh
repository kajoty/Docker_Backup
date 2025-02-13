#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

CONFIG_FILE="config.json"
LOG_FILE="docker_backup.log"

# Prüfe, ob die Konfigurationsdatei existiert
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Fehler: Konfigurationsdatei '$CONFIG_FILE' nicht gefunden!"
    exit 1
fi

#########################################
# Abhängigkeiten prüfen
#########################################
check_dependencies() {
    local dependencies=(jq docker tar scp ssh curl)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Fehler: '$cmd' ist nicht installiert. Bitte installiere '$cmd' und starte das Script neu." | tee -a "$LOG_FILE"
            exit 1
        fi
    done
}
check_dependencies

#########################################
# Logging-Funktion (Ausgabe in Konsole und Log-Datei)
#########################################
log() {
    local message="[$(date +"%Y-%m-%d %H:%M:%S")] $*"
    echo "$message" | tee -a "$LOG_FILE"
}

#########################################
# Konfiguration laden
#########################################
load_config() {
    SOURCE_DIR=$(jq -r '.source_dir' "$CONFIG_FILE")
    BACKUP_DIR=$(jq -r '.backup_dir' "$CONFIG_FILE")
    KEEP_BACKUPS=$(jq -r '.keep_backups' "$CONFIG_FILE")
    REMOTE_USER=$(jq -r '.remote.user' "$CONFIG_FILE")
    REMOTE_SERVER=$(jq -r '.remote.server' "$CONFIG_FILE")
    REMOTE_DIR=$(jq -r '.remote.dir' "$CONFIG_FILE")
    
    # Optionale Pushover-Konfiguration
    PUSHOVER_ENABLED=$(jq -r '.pushover.enabled // "false"' "$CONFIG_FILE")
    PUSHOVER_TOKEN=$(jq -r '.pushover.token // empty' "$CONFIG_FILE")
    PUSHOVER_USER=$(jq -r '.pushover.user // empty' "$CONFIG_FILE")
    
    CURRENT_DATETIME=$(date +"%Y-%m-%d_%H-%M-%S")
    BACKUP_FILENAME="${CURRENT_DATETIME}-backup.tar.gz"
    BACKUP_FULLPATH="${BACKUP_DIR}/${BACKUP_FILENAME}"
    REMOTE_TARGET="${REMOTE_USER}@${REMOTE_SERVER}"
    
    # Überprüfe, ob alle erforderlichen Parameter gesetzt sind
    if [ -z "$SOURCE_DIR" ] || [ -z "$BACKUP_DIR" ] || [ -z "$REMOTE_USER" ] || [ -z "$REMOTE_SERVER" ] || [ -z "$REMOTE_DIR" ]; then
        log "Fehler: Ein oder mehrere erforderliche Konfigurationsparameter fehlen!"
        exit 1
    fi
}

#########################################
# Optionale Pushover-Benachrichtigung
#########################################
send_pushover() {
    local message="$1"
    if [ "$PUSHOVER_ENABLED" = "true" ]; then
        if [ -z "$PUSHOVER_TOKEN" ] || [ -z "$PUSHOVER_USER" ]; then
            log "Pushover ist aktiviert, aber Token oder User fehlen in der Konfiguration."
            return 1
        fi
        curl -s \
             --form-string "token=${PUSHOVER_TOKEN}" \
             --form-string "user=${PUSHOVER_USER}" \
             --form-string "message=${message}" \
             https://api.pushover.net/1/messages.json > /dev/null
    fi
}

#########################################
# Docker-Container stoppen
#########################################
stop_containers() {
    local running_containers
    running_containers=$(docker ps -q)
    if [ -n "$running_containers" ]; then
        log "Stoppe alle laufenden Docker-Container..."
        docker stop $running_containers > /dev/null
    else
        log "Keine laufenden Docker-Container gefunden."
    fi
}

#########################################
# Docker-Container neu starten
#########################################
restart_containers() {
    local container_ids
    container_ids=$(docker ps -a -q)
    if [ -n "$container_ids" ]; then
        log "Starte alle Docker-Container neu..."
        docker start $container_ids > /dev/null 2>&1 || log "Warnung: Einige Container konnten nicht gestartet werden."
    fi
}

#########################################
# Backup erstellen
#########################################
create_backup() {
    log "Erstelle Backup-Archiv: ${BACKUP_FULLPATH}"
    mkdir -p "${BACKUP_DIR}"
    tar -czpf "${BACKUP_FULLPATH}" -C "$(dirname "${SOURCE_DIR}")" "$(basename "${SOURCE_DIR}")"
    log "Backup-Archiv erstellt: ${BACKUP_FULLPATH}"
}

#########################################
# Backup zum Remote-Server übertragen
#########################################
transfer_backup() {
    log "Kopiere Backup auf den Remote-Server (${REMOTE_TARGET})..."
    scp "${BACKUP_FULLPATH}" "${REMOTE_TARGET}:${REMOTE_DIR}/"
}

#########################################
# Lokale Backups aufräumen
#########################################
cleanup_local_backups() {
    log "Lösche lokale Backups, die älter als ${KEEP_BACKUPS} Tage sind..."
    find "${BACKUP_DIR}" -type f -name "*-backup.tar.gz" -mtime +${KEEP_BACKUPS} -exec rm -v {} \;
}

#########################################
# Remote-Backups aufräumen
#########################################
cleanup_remote_backups() {
    log "Lösche auf dem Remote-Server Backups, die älter als ${KEEP_BACKUPS} Tage sind..."
    ssh "${REMOTE_TARGET}" "find ${REMOTE_DIR} -type f -name '*-backup.tar.gz' -mtime +${KEEP_BACKUPS} -exec rm -v {} \;"
}

#########################################
# Fehlerbehandlung (wird bei Fehlern durch trap aufgerufen)
#########################################
error_handler() {
    log "Fehler aufgetreten. Starte Docker-Container neu."
    send_pushover "Backup-Fehler: Es trat ein Fehler auf. Docker-Container werden neu gestartet."
    restart_containers
    exit 1
}
trap error_handler ERR

#########################################
# Hauptprogramm
#########################################
main() {
    load_config
    stop_containers
    create_backup
    restart_containers
    transfer_backup
    cleanup_local_backups
    cleanup_remote_backups
    log "Backup erstellt: ${BACKUP_FULLPATH} und auf ${REMOTE_TARGET} kopiert."
    send_pushover "Backup erfolgreich: ${BACKUP_FULLPATH} erstellt und auf ${REMOTE_TARGET} kopiert."
}

main

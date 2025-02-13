# Docker Backup Script

Dieses Bash-Script ermöglicht die automatische Sicherung aller Docker-Volumes. Das Backup wird lokal gespeichert und optional auf einen Remote-Server übertragen. Zusätzlich kann eine Pushover-Benachrichtigung über den Backup-Status versendet werden.

## Funktionen
- Automatisches Stoppen und Neustarten aller Docker-Container während des Backups
- Erstellung eines komprimierten Backup-Archivs (`tar.gz`)
- Sicherung auf einem Remote-Server mittels `scp`
- Automatische Löschung alter Backups (lokal und remote)
- Fehlerbehandlung und Logging
- **Automatische Ausführung mit systemd**
- **Optionale Benachrichtigung per Pushover**

---

## Installation & Einrichtung

### 1. Abhängigkeiten installieren
Folgende Programme müssen auf dem System installiert sein:
```bash
sudo apt update && sudo apt install -y jq docker.io openssh-client curl
```

### 2. Konfigurationsdatei erstellen
Erstelle eine `config.json` im gleichen Verzeichnis wie das Script und passe sie nach deinen Bedürfnissen an:
```json
{
  "source_dir": "/var/lib/docker/volumes",
  "backup_dir": "/opt/docker_backups",
  "keep_backups": 10,
  "remote": {
    "user": "user",
    "server": "192.168.178.101",
    "dir": "/home/user/docker-backups"
  },
  "pushover": {
    "enabled": true,
    "token": "DEIN_PUSHOVER_APP_TOKEN",
    "user": "DEIN_PUSHOVER_USER_KEY"
  }
}
```

### 3. Script-Berechtigungen setzen
Das Backup-Script sollte nur von `root` ausführbar sein:
```bash
sudo chown root:root /path/to/docker_backup.sh
sudo chmod 700 /path/to/docker_backup.sh
```

---

## Manuelle Nutzung
Das Script kann jederzeit manuell ausgeführt werden:
```bash
sudo /path/to/docker_backup.sh
```

---

## Automatisierung mit systemd
Damit das Backup regelmäßig automatisch läuft, kann systemd genutzt werden.

### 1. Systemd-Service erstellen
Erstelle die Datei für den Service:
```bash
sudo nano /etc/systemd/system/docker_backup.service
```

Füge folgenden Inhalt ein:
```ini
[Unit]
Description=Docker Backup Service
Wants=docker_backup.timer
After=network.target

[Service]
Type=simple
ExecStart=/path/to/docker_backup.sh
User=root
WorkingDirectory=/path/to/
StandardOutput=append:/var/log/docker_backup.log
StandardError=append:/var/log/docker_backup.log

[Install]
WantedBy=multi-user.target
```

### 2. Systemd-Timer erstellen
Erstelle die Datei für den Timer:
```bash
sudo nano /etc/systemd/system/docker_backup.timer
```

Füge folgenden Inhalt ein:
```ini
[Unit]
Description=Timer for Docker Backup Service

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### 3. Systemd-Timer aktivieren
```bash
sudo systemctl daemon-reload
sudo systemctl enable docker_backup.timer
sudo systemctl start docker_backup.timer
```

### 4. Timer-Status prüfen
```bash
systemctl list-timers --all
```

Falls du das Backup sofort testen möchtest:
```bash
sudo systemctl start docker_backup.service
```

---

## Fehlerbehandlung
Falls das Backup fehlschlägt, kannst du folgende Maßnahmen ergreifen:
- Prüfe das Log-File `docker_backup.log`
- Stelle sicher, dass die Konfigurationsdatei (`config.json`) korrekt ist
- Überprüfe die Erreichbarkeit des Remote-Servers
- Prüfe den Systemd-Status mit:
  ```bash
  sudo systemctl status docker_backup.service
  ```

---

## Lizenz
Dieses Script ist Open Source und unter der MIT-Lizenz verfügbar.


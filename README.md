Docker Volume Backup Script
Dieses Skript erstellt ein Backup von Docker-Volumes und speichert es lokal oder auf einem entfernten Server. Es kann automatisiert mit einem systemd Timer ausgeführt werden.

🔧 Voraussetzungen
Ein Linux-System mit Docker installiert
Ein Benutzer mit ausreichenden Berechtigungen
SSH-Zugriff auf das Zielsystem für den Remote-Backup

🔑 SSH-Login ohne Passwort einrichten
Damit das Skript ohne Benutzereingaben funktioniert, muss der SSH-Schlüssel vom Hauptsystem auf das Zielsystem kopiert werden.

1️⃣ SSH-Schlüsselpaar erstellen (falls noch nicht vorhanden)

´´´
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
´´´

2️⃣ Öffentlichen Schlüssel auf das Zielsystem übertragen

´´´
ssh-copy-id user@Ziel-IP
´´´

Nach der Passworteingabe wird der Schlüssel hinterlegt.

3️⃣ SSH-Login testen

´´´
ssh user@Ziel-IP
´´´
Falls die Anmeldung ohne Passwort funktioniert, ist alles korrekt eingerichtet.

📂 Datei- und Verzeichnisstruktur

´´´
/root/backup_docker.sh                  # Backup-Skript
/etc/systemd/system/docker-backup.service  # Systemd Service
/etc/systemd/system/docker-backup.timer    # Systemd Timer
/opt/docker_backups/                      # Lokaler Backup-Speicherort
´´´

🛠️ Installation und Nutzung

1️⃣ Skript ausführbar machen

´´´
chmod +x /root/backup_docker.sh
´´´

2️⃣ Systemd Service und Timer einrichten

Die docker-backup.service und docker-backup.timer müssen unter /etc/systemd/system/ liegen und "root" gehören.

Nach dem Kopieren:

´´´
systemctl daemon-reload
systemctl enable docker-backup.timer
systemctl start docker-backup.timer
´´´

3️⃣ Status überprüfen

´´´
systemctl status docker-backup.timer
systemctl status docker-backup.service
´´´

4️⃣ Manuelles Backup starten

Falls du das Backup sofort ausführen möchtest:

´´´
systemctl start docker-backup.service
´´´

🗑️ Alte Backups automatisch löschen
Das Skript löscht alte Backups lokal und auf dem Zielserver. Die Anzahl der gespeicherten Backups kann in der Konfiguration angepasst werden.

✅ Fazit
Dieses Skript sorgt für eine einfache, automatisierte Sicherung deiner Docker-Volumes. Es kann per systemd gesteuert werden und unterstützt Remote-Backups über SCP.

🚀 Viel Erfolg mit deinem Docker-Backup!
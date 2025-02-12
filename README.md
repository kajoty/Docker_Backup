# 🐳 Docker Volume Backup Script

Dieses Skript erstellt ein Backup von Docker-Volumes und kopiert das Archiv automatisch auf einen entfernten Server. Es ermöglicht eine automatisierte Sicherung mithilfe von `systemd` und funktioniert ohne Benutzereingaben durch die Einrichtung eines passwortlosen SSH-Logins.  

---

## 📌 Inhalt
- [🔧 Voraussetzungen](#-voraussetzungen)
- [⚙️ Installation & Konfiguration](#️-installation--konfiguration)
- [🔑 Passwortlosen SSH-Login einrichten](#-passwortlosen-ssh-login-einrichten)
- [📜 Backup-Skript (`backup_docker.sh`)](#-backup-skript-backup_dockersh)
- [⏳ Automatisierung mit Systemd (`.service` & `.timer`)](#-automatisierung-mit-systemd-service--timer)
- [🛠 Befehle zur Verwaltung](#-befehle-zur-verwaltung)
- [🗑️ Aufräumen alter Backups](#-aufräumen-alter-backups)
- [📢 Zusammenfassung](#-zusammenfassung)

---

## 🔧 Voraussetzungen
Bevor du das Skript verwendest, stelle sicher, dass folgende Voraussetzungen erfüllt sind:

✅ **Docker** ist installiert und läuft  
✅ **SSH & SCP** sind auf dem Haupt- und Zielsystem verfügbar  
✅ **Systemd** wird auf dem Hauptsystem genutzt  
✅ **SSH-Key-Pair** wurde eingerichtet (siehe nächster Abschnitt)  

---

## ⚙️ Installation & Konfiguration

### 📁 Dateien & Verzeichnisse
| Datei/Verzeichnis        | Zweck |
|--------------------------|------------------------------------------------|
| `/root/backup_docker.sh` | Das eigentliche Backup-Skript |
| `/etc/systemd/system/docker-backup.service` | Systemd Service-Datei für das Backup |
| `/etc/systemd/system/docker-backup.timer` | Systemd Timer-Datei zur Automatisierung |

### 🔑 Berechtigungen setzen
```
bash
chmod +x /root/backup_docker.sh
chown root:root /root/backup_docker.sh
```

## Systemd-Konfiguration neu laden

´´´
systemctl daemon-reload
´´´

Passwortlosen SSH-Login einrichten

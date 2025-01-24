Quelle:
https://schroederdennis.de/docker/docker-volume-backup-script-sichern-mit-secure-copy-scp-nas/

Damit das Script auch ohne Benutzereingaben läuft, muss der Public Key vom Hauptsystem auf das Zielsystem kopiert werden. Damit ist dann auch eine Passwortlose-Anmeldung möglich. Also zunächst ein Keypärchen erstellen und dann den Public Key kopieren.

## Auf dem Hauptsystem ausführen, nicht dem Backup Ziel ##
ssh-keygen -t rsa
ssh-copy-id root@Ziel-IP


## Wenn du den Passwortlosen-Login testen möchtest gebe folgendes in die CLI ein

ssh root@Ziel-IP

## .service und .timer 

Müssen "root" gehören

docker-backup.service & docker-backup.timer liegen unter:

 /etc/systemd/system/

 systemctl daemon-reload
 
 systemctl status/start/stop/restart docker-backup.timer

 systemctl status/start/stop/restart docker-backup.service

## backup_docker.sh

liegt unter /root
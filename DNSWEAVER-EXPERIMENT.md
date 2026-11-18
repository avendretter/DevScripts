# DNSWeaver LXC – experimenteller Community-Scripts-Entwurf

Dieser Branch enthält einen **experimentellen Entwurf**, kein offizielles Community-Script. Er installiert DNSWeaver ohne Docker in einem Debian-13-LXC. Das Projekt veröffentlicht Docker-Images; das Installationsskript baut das Programm aus dem GitHub-Release-Quellcode.

## Stand des Tests

Am 18. November 2026 wurde der Branch auf Proxmox VE 9.2 mit einem unprivilegierten amd64-LXC getestet. Der Build von DNSWeaver 3.4.0 und der Start als systemd-Dienst funktionierten. Die Proxmox-Quelle erkannte statisch adressierte LXCs; der UniFi-Provider funktionierte mit einer Dream Machine SE und Network 11.0.97.

In einem anschließenden Funktionstest wurden zwei A-Records mit unterschiedlichen Gast-IP-Adressen erstellt. Nach dem Wechsel von `additive` auf `managed` wurden ein nicht mehr zum Tag-Filter passender, DNSWeaver-eigener A-Record und sein Ownership-TXT-Eintrag entfernt. Dies ist ein einzelner Funktionstest, keine vollständige Installations-, Update-, Wiederherstellungs- oder Sicherheitsprüfung. Eine separate Validierung von DHCP-Containern, VMs und ARM64 steht noch aus.

**Bekannte Grenzen:** Die API-Konfiguration muss manuell erfolgen. Der Dienst startet nach Installation absichtlich nicht automatisch. Die Release-Helfer speichern die Version beim Download vor dem Build; ein fehlgeschlagener Update-Build kann weitere Update-Versuche verhindern. Das Update und seine Fehlerbehandlung wurden nicht getestet. Die GitHub-Release-Assets enthielten zum Testzeitpunkt keine separat herunterladbaren Linux-Binaries. Das Skript ist nicht zur Einreichung fertig und wurde nicht von Community Scripts veröffentlicht oder geprüft.

## Installation aus dem Fork

Auf einem Proxmox-Host in einer geeigneten Testumgebung:

```bash
COMMUNITY_SCRIPTS_URL="https://raw.githubusercontent.com/avendretter/DevScripts/experiment/dnsweaver-lxc" \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/avendretter/DevScripts/experiment/dnsweaver-lxc/ct/dnsweaver.sh)"
```

Die Variable sorgt dafür, dass das zugehörige Installationsskript aus demselben Fork und Branch geladen wird. Das Skript läuft mit Root-Rechten auf dem Proxmox-Host. Der Build benötigt Internetzugang. Die bereitgestellte Datei `/etc/dnsweaver/dnsweaver.env` ist eine unvollständige Ausgangskonfiguration mit Dry-Run; der systemd-Dienst bleibt bis zur Konfiguration deaktiviert.

## Proxmox-Integration

DNSWeaver liest Gäste und IP-Adressen über die Proxmox-API. Für Proxmox VE 9 wurde beim Test eine eigene Rolle mit `VM.Audit`, `VM.GuestAgent.Audit` und `Pool.Audit` verwendet. Die Upstream-Dokumentation nennt teilweise noch `VM.Monitor`; diese Berechtigung ist auf dem getesteten PVE 9 nicht verfügbar. `VM.GuestAgent.Audit` ist für informative QEMU-Guest-Agent-Abfragen relevant. Für reine LXCs kann der Berechtigungsumfang geringer sein. Die benötigten Rechte und Gültigkeit der ACLs für die eigene Umgebung prüfen.

```bash
# Auf dem Proxmox-Host; nur ausführen, wenn Rolle und Benutzer noch nicht existieren.
pveum role add DNSWeaver -privs "VM.Audit,VM.GuestAgent.Audit,Pool.Audit"
pveum user add dnsweaver@pve --comment "DNSWeaver"
pveum aclmod / -user dnsweaver@pve -role DNSWeaver
pveum user token add dnsweaver@pve dnsweaver --privsep=0
```

Den einmalig angezeigten Token-Secret geschützt in `/etc/dnsweaver/proxmox-token` innerhalb des DNSWeaver-LXC speichern (`chmod 600`). `--privsep=0` lässt den Token die Rechte des Benutzers übernehmen. Keine Secrets in Logs, Git oder öffentliche Diskussionen schreiben.

Der Tag-Filter `DNSWEAVER_PROXMOX_TAG_FILTER=dnsweaver` berücksichtigt nur Gäste mit einem passenden Tag; Upstream beschreibt einen **Präfixvergleich**. Mit `DNSWEAVER_PROXMOX_DOMAIN_SUFFIX=home` und Gastname `grafana` wird etwa `grafana.home` erzeugt. `guest-ip` nutzt die aus Proxmox ermittelte Gast-IP. VMs benötigen einen laufenden QEMU Guest Agent; ohne auflösbare Gast-IP werden sie übersprungen. Standardmäßig werden laufende Gäste berücksichtigt.

## UniFi-Integration

### Voraussetzungen und Rechte

DNSWeaver benötigt laut Upstream die **lokale Network Integration API**, UniFi Network 10.6 oder neuer und ein UniFi-Gateway, das die DNS-Antworten für Clients bereitstellt. In der getesteten Installation konnte ein vom Site-Admin-Konto erstellter API-Key DNS-Policies lesen, erstellen und löschen. Das belegt keine DNS-only-Berechtigung: In der getesteten Oberfläche war keine separate DNS-only-Einschränkung für API-Keys sichtbar. Site-Admin kann weitere Rechte besitzen. Ein Dry-Run begrenzt das Verhalten von DNSWeaver, nicht die Rechte des Keys. Rechte, Widerrufsmöglichkeiten und Sichtbarkeit des Keys im eigenen UniFi-System prüfen.

Den lokalen Network-API-Key in `/etc/dnsweaver/unifi-api-key` im LXC speichern und mit `chmod 600` schützen. Einen separaten Account und angemessen eingeschränkte Rechte verwenden; Schlüssel niemals in die Konfigurationsdatei, Git oder öffentliche Logs kopieren.

### TLS-Zertifikate

Zertifikatsprüfung aktiviert lassen. Für Proxmox kann das öffentliche CA-Zertifikat vom Host in den Container kopiert werden:

```bash
# Auf dem Proxmox-Host: <CTID> durch die DNSWeaver-Container-ID ersetzen.
pct push <CTID> /etc/pve/pve-root-ca.pem /etc/dnsweaver/proxmox-ca.pem
```

Die Hostadresse muss zu einem Namen oder einer IP im Zertifikat passen. Das UniFi-Zertifikat bzw. die vertrauenswürdige CA muss ebenfalls bereitgestellt und unabhängig auf Echtheit überprüft werden. Im Test enthielt das selbstsignierte Zertifikat `unifi.local`, nicht die Gateway-IP. Nach Vergleich des vollständigen SHA-256-Fingerabdrucks wurde die geprüfte Zertifikatsdatei als CA-Datei verwendet und `DNSWEAVER_UNIFI_TLS_SERVER_NAME=unifi.local` gesetzt. Andere Installationen können andere Zertifikate und Namen haben. Die Einstellungen `TLS_CA_FILE` und `TLS_SERVER_NAME` entsprechend anpassen; nicht ungeprüft fremde Zertifikate vertrauen.

### Beispielkonfiguration

Folgende Werte sind Beispiele und müssen an die eigene Umgebung angepasst werden. `192.0.2.0/24` ist ein Dokumentationsnetz. Der UniFi-Provider verlangte im Test ein `TARGET`, obwohl `guest-ip` die tatsächliche Adresse für jeden Gast lieferte. Der Wert `192.0.2.1` unten ist nur ein Dummy für den **Dry-Run**; ihn nicht als produktives Fallback verwenden. Bei Grafana und Prometheus wurde die ermittelte Gast-IP im echten Eintrag bestätigt; das belegt nicht jedes Fehlerverhalten.

```ini
DNSWEAVER_PLATFORM=none
DNSWEAVER_DRY_RUN=true
DNSWEAVER_LOG_LEVEL=debug

DNSWEAVER_SOURCES=proxmox
DNSWEAVER_PROXMOX_URL=https://pve.example.test:8006
DNSWEAVER_PROXMOX_TOKEN_ID=dnsweaver@pve!dnsweaver
DNSWEAVER_PROXMOX_TOKEN_SECRET_FILE=/etc/dnsweaver/proxmox-token
DNSWEAVER_PROXMOX_TLS_CA_FILE=/etc/dnsweaver/proxmox-ca.pem
DNSWEAVER_PROXMOX_DOMAIN_SUFFIX=home
DNSWEAVER_PROXMOX_TAG_FILTER=dnsweaver
DNSWEAVER_PROXMOX_TARGET_MODE=guest-ip

DNSWEAVER_INSTANCES=unifi
DNSWEAVER_UNIFI_TYPE=unifi
DNSWEAVER_UNIFI_URL=https://gateway.example.test
DNSWEAVER_UNIFI_API_KEY_FILE=/etc/dnsweaver/unifi-api-key
DNSWEAVER_UNIFI_TLS_CA_FILE=/etc/dnsweaver/unifi-cert.pem
DNSWEAVER_UNIFI_TLS_SERVER_NAME=unifi.local
DNSWEAVER_UNIFI_SITE=default
DNSWEAVER_UNIFI_RECORD_TYPE=A
DNSWEAVER_UNIFI_TARGET=192.0.2.1
DNSWEAVER_UNIFI_DOMAINS=*.home
DNSWEAVER_UNIFI_MODE=managed
```

Im systemd-EnvironmentFile stehen die Platzhalterwerte selbst; hier gibt es keine Shell-Expansion. Den Hostnamen `unifi.local` nur verwenden, wenn das geprüfte Zertifikat genau diesen Namen enthält. `.home` war die Nutzerwahl im Test, ist aber keine speziell reservierte private DNS-Zone; `home.arpa` ist eine Alternative. DNS löst Namen zu IP-Adressen auf und ersetzt keine Portnummer oder Reverse-Proxy-Konfiguration.

### Testen und Betrieb

Vor dem ersten Start die eigene Konfiguration und Zertifikate prüfen und einen eng begrenzten Tag-/Domain-Filter wählen. Der Dienst wird manuell gestartet:

```bash
systemctl start dnsweaver
systemctl status dnsweaver --no-pager -l
journalctl -u dnsweaver -n 100 --no-pager -l
```

`dry_run:true` in den Start- und Abgleichmeldungen prüfen. Die Version im Log kann `dev` anzeigen, weil der lokale Build keine Release-Metadaten einbettet. Ein erfolgreicher Dry-Run beweist nur Lesezugriff und zeigt möglicherweise nicht alle geplanten Zieladressen. Vor echtem Betrieb mit einem gezielten einzelnen Host prüfen; den Dummy-Target durch ein bewusst gewähltes gültiges Fallback ersetzen und beachten, dass das Fallback nicht als Schutz gegen falsche Adressen dient.

In UniFi unter Network → Policy Table → DNS die erzeugten Records kontrollieren und mit `nslookup <name> <gateway-ip>` testen. Im Modus `managed` entfernt DNSWeaver seine anhand der TXT-Marker erkannten eigenen verwaisten Records; durch den Statusfilter können auch Records gestoppter Gäste verschwinden. `additive` legt Records an, löscht aber keine verwaisten Einträge. `authoritative` kann fremde Records im Geltungsbereich löschen und wurde nicht verwendet.

Nach erfolgreichem Test kann `systemctl enable dnsweaver` den automatischen Start aktivieren. Änderungen an Konfiguration erfordern einen Neustart. Vor Updates ein Backup der Konfiguration und Secret-Dateien erstellen; das Update dieses experimentellen Skripts wurde nicht geprüft.

## Quellen

- [DNSWeaver: Proxmox-Quelle](https://maxfield-allison.github.io/dnsweaver/sources/proxmox/)
- [DNSWeaver: UniFi-Provider](https://maxfield-allison.github.io/dnsweaver/providers/unifi/)
- [DNSWeaver: Betriebsmodi](https://maxfield-allison.github.io/dnsweaver/configuration/modes/)
- [Proxmox: Änderungen an Guest-Agent-Berechtigungen](https://lore.proxmox.com/pve-devel/20250717133711.84715-1-f.ebner@proxmox.com/)

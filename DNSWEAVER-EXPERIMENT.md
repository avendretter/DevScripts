# DNSWeaver: Community-Scripts-Entwurf

Dieser Entwurf baut DNSWeaver aus dem offiziellen GitHub-Release in einem Debian-LXC. Er ist noch kein veröffentlichtes Community-Script und wurde nicht auf Proxmox getestet. Die beiden Dateien gehören in einen Checkout oder Fork von community-scripts/DevScripts; der öffentliche DevScripts-Zweig enthält sie noch nicht. Daher den üblichen Einzeiler nicht unverändert verwenden.

Der Dienst bleibt nach der Installation absichtlich deaktiviert. `/etc/dnsweaver/dnsweaver.env` enthält zunächst nur Standalone-Modus und Dry-Run. Für eine funktionierende Installation müssen Proxmox-Quelle, UniFi-Provider, API-Zugänge und Zertifikate nach der Upstream-Dokumentation konfiguriert werden. Vor dem Aktivieren sicherstellen, dass Dry-Run tatsächlich aktiv ist und die Logs prüfen. UniFi Network 10.6 oder neuer ist laut Upstream erforderlich. Keine API-Schlüssel in Skript oder Chat eintragen.

Die Community-Release-Helfer speichern die Release-Version beim Download, vor dem Build. Ein fehlgeschlagener Build kann deshalb eine erneute Update-Erkennung verhindern; dieser Fall muss vor einem produktiven Einsatz und einer Einreichung noch geklärt und getestet werden. Ein erfolgreich gebautes Update ersetzt das Programm atomar und startet nur einen bereits laufenden Dienst neu. Konfiguration unter `/etc/dnsweaver` bleibt erhalten.

Quellen: https://github.com/maxfield-allison/dnsweaver , https://maxfield-allison.github.io/dnsweaver/sources/proxmox/ , https://maxfield-allison.github.io/dnsweaver/providers/unifi/ .

## Experimental branch

This branch is an untested draft, not a Community Scripts release. Do not use on a production host. The installer requires both the CT script and the matching install script from this branch. `_CS_DEFAULT_URL` still points at the upstream project, so any future isolated test must explicitly set `COMMUNITY_SCRIPTS_URL` to `https://raw.githubusercontent.com/avendretter/DevScripts/experiment/dnsweaver-lxc` before invoking the branch's CT script. No end-to-end test has verified this workflow yet.

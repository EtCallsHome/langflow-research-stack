# Langflow Research Stack – Portainer / GitHub

Versionierter Docker-Stack fuer universelle Langflow-Research-Agenten mit einem separaten Chromium-Browser. **Keine Passwoerter oder Tokens im Repository.**

## Inhalt

- docker-compose.yml – bisherige Dienste Ollama, Open WebUI, PostgreSQL und Langflow plus research-browser.
- Dockerfile – Langflow 1.12.1 mit Playwright-Python und libatomic; Chromium laeuft separat.
- .github/workflows/build-langflow.yml – baut das Image fuer ghcr.io.
- .env.example – **nur Variablennamen/Platzhalter**, keine Zugangsdaten.

## Sicherheit – vor dem Umstieg lesen

Das Repository ist **public**. Niemals echte Passwoerter, API-Keys, Browser-Tokens, Datenbank-URLs mit Zugangsdaten oder exportierte Flows mit Secrets committen. Alle Geheimwerte sind Variablen aus **Portainer > Stacks > Environment variables**; sie werden in der YAML nur referenziert. Die in einer frueheren Compose-Datei im Chat offengelegten Zugangsdaten sollten kontrolliert rotiert werden.

WICHTIG: Kein zweiter, paralleler Stack mit denselben container_name-Werten starten. Alle laufenden Forschungsjobs vor einer Migration beenden. Bei Wechsel eines bestehenden Web-Editor-Stacks auf Git zuerst Backup und Volume-Zuordnung pruefen, dann die bisherige Stack-Bereitstellung ersetzen; nicht blind Daten oder Volumes entfernen.

### Bestehende Datenvolumes identifizieren

~~~bash
docker inspect langflow-db --format '{{range .Mounts}}{{println .Name .Destination}}{{end}}'
docker inspect langflow --format '{{range .Mounts}}{{println .Name .Destination}}{{end}}'
~~~

Die Namen der bestehenden Volumes fuer /var/lib/postgresql/data und /app/langflow als Portainer-Variablen LANGFLOW_PG_VOLUME und LANGFLOW_CONFIG_VOLUME eintragen. Die Compose-Datei nutzt **external volumes**: Wenn der Name falsch ist, bricht das Deployment ab, statt eine leere Datenbank anzulegen.

### Achtung: Research-Journal unter /app/data

Im bisherigen Stack war nur /app/langflow gemountet; der Research-Job-Status liegt jedoch unter /app/data/.langflow (z.B. research_v6_5.sqlite3). Eine Neuerstellung des bisherigen Containers ohne Backup wuerde dieses Journal verlieren.

Vor der Umstellung: aktive Jobs abschliessen, aktuellen Langflow-Container anhalten und den **gesamten Inhalt von /app/data** sichern:

~~~bash
mkdir -p /root/langflow-runtime-backup
docker stop langflow
docker cp langflow:/app/data/. /root/langflow-runtime-backup/
docker volume create langflow_research_runtime
docker run --rm -v langflow_research_runtime:/target -v /root/langflow-runtime-backup:/source:ro alpine:3.22 sh -c 'cp -a /source/. /target/ && chown -R 1000:0 /target'
~~~

Danach LANGFLOW_RUNTIME_VOLUME=langflow_research_runtime in Portainer anlegen. Den alten Container/Stack erst nach Sicherung und Vorbereitung des neuen Deployments ersetzen. Falls du nicht direkt umstellst, kann docker start langflow den alten Container wieder starten; danach entstandene Jobs muessen vor der spaeteren Umstellung erneut gesichert werden. Der Postgres-Datenbestand sollte zusaetzlich per pg_dump gesichert werden.

### Variablen in Portainer (ohne echte Werte in GitHub)

- POSTGRES_PASSWORD – **aktuelles** Datenbank-Passwort; ein Aendern dieses Werts allein aendert NICHT das Passwort des bereits initialisierten PostgreSQL-Users.
- LANGFLOW_DATABASE_URL – vollstaendige PostgreSQL-URL inkl. Passwort, nur in Portainer.
- LANGFLOW_SUPERUSER_PASSWORD – Langflow-Login-Passwort.
- LANGFLOW_SECRET_KEY – bestehender Langflow-Schluessel; vorsicht beim Rotieren, sonst koennen gespeicherte Zugangsdaten unlesbar werden.
- BROWSER_TOKEN – neuer, zufaelliger Token (z.B. openssl rand -hex 32).
- LANGFLOW_PG_VOLUME – existierender Docker-Volume-Name fuer PostgreSQL.
- LANGFLOW_CONFIG_VOLUME – existierender Docker-Volume-Name fuer /app/langflow.
- LANGFLOW_RUNTIME_VOLUME – Name des neu mit Backup befuellten Volumes fuer /app/data.

Die .env.example enthaelt nur die Namen, **keine verwendbaren Anmeldedaten**. In einem Git-Stack Portainer-Variablen im Stack-Formular hinterlegen. Keine .env mit echten Werten nach Git pushen.

### Langflow-Image / GitHub Container Registry

GitHub Actions erstellt aus dem Dockerfile das Image:

~~~text
ghcr.io/etcallshome/langflow-research:1.12.1
~~~

Actions im Repository erlauben und den ersten erfolgreichen Build abwarten. **Wichtig:** Neue GHCR-Packages sind eventuell zunaechst privat, obwohl das Repository public ist. Die Image-Package-Sichtbarkeit unter GitHub Packages auf Public stellen, damit Portainer ohne Registry-Zugangsdaten pullen kann. Der Stack laesst sich erst deployen, wenn das Image verfuegbar ist.

### Browser-Verbindung in Langflow

Im importierten Research-V6.7.8-Flow das erweiterte **Browser CDP-WebSocket (optional)**-Feld als Secret konfigurieren:

~~~text
ws://research-browser:3000?token=DEIN_BROWSER_TOKEN
~~~

Der Token steht ausschliesslich in Portainer und im Secret-Feld des Flows, **niemals** in einem exportierten JSON oder GitHub-Commit. Ggf. in Langflow Global Variables als Secret hinterlegen. Danach im Playground: browsertest. Keine lokale Chromium-Installation im Langflow-Container noetig.

### Portainer / Git-Deployment

- Git-Repository: https://github.com/EtCallsHome/langflow-research-stack
- Branch: main
- Compose path: docker-compose.yml
- Portainer-Umgebungsvariablen aus obiger Liste eintragen.
- Bestehende Stack-Identitaet/Volumes erhalten; **nicht einfach einen zweiten Stack parallel bereitstellen**.

Die Browserless-Webschnittstelle hat **keinen veroeffentlichten Host-Port**. Sie ist nur fuer Langflow im Docker-Netz research_network erreichbar, mit TOKEN-Schutz. Aufgerufene Websites koennen dennoch riskant sein: unbekannte Seiten nicht automatisiert in interne Netzwerke navigieren lassen, keine Captchas umgehen, keine Anmeldungen/Bestellungen/Vertragsabschluesse erlauben.

## Updates

Langflow: Basisversion im Dockerfile und Image-Tag in docker-compose.yml kontrolliert anheben, GitHub Actions baut neues Image. Browserless: gepinnten Tag im Compose anheben. Vor Updates Backup; Research-Journal und PostgreSQL-Volumes nicht loeschen.

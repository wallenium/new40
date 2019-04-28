# NEW 4.0 (Norddeutsche Energiewende 4.0) Project
Homee Extensions for NEW 4.0 project

## Status Logger ##
Generate a new webhook for NEW 4.0. The script will log the start and endpoint of an action.

### Strom günstig ###
**Auslöser**
Wenn *Homeegramm Strom günstig* ausgelöst wird

**Aktion**
Webhook
URL: http://IP-ADRESS/new40/new_logger.php?status=eingeschaltet
Ohne Verzögerung

### Strom teuer ###
**Auslöser**
Wenn *Homeegramm Strom teuer* ausgelöst wird

**Aktion**
Webhook
URL: http://IP-ADRESS/new40/new_logger.php?status=ausgeschaltet
Ohne Verzögerung

## Auswertung ##

### Benötigte Software ###
R sowie am einfachsten RStudio

### Anpassungen ###
Die Summierten Verbrauchsdaten müssen im Ordner ./data/ liegen. Pfad muss im Skript angepasst werden. Zudem muss die URL zur Textdatei des Loggers oben angegeben werden.

### Auswertung ###
Skript starten, er generiert zwei Plots.

### Wichtige Data Frames ###
consumptionPerDay       Hier sind die Summierten Verbrauchswerte Billig/Teuer erfasst. Zudem die Prozentzahl des verbrauchten billgen Stroms.
percentagePerMonthCheap Hier ist das selbe, nur auf den Monat gerechnet.

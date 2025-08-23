== OpenBSD Home Server t400 Tutorial alpha 0.1 fast version===
Autor: retrobofh bofh@retro-technology.pl / 23.08.2025

Opis:
Ten przewodnik pokazuje krok po kroku, jak skonfigurować serwer OpenBSD 7.7 z:
- statycznym IP w LAN,
- PF z ochroną przed atakami i mini-DDoS,
- HTTP/HTTPS z ACME (Let's Encrypt),
- DDNS do dynamicznego IP (GnuDIP / Dynu),
- SSH do zarządzania.

--------------------------------------------------------
1. Statyczne IP na serwerze

Edytuj /etc/hostname.em0 (przykład dla interfejsu em0):
inet 192.168.1.100 255.255.255.0 192.168.1.1

- 192.168.1.100 → IP serwera
- 192.168.1.1   → brama (Funbox)
- restart interfejsu: doas sh /etc/netstart em0
- sprawdź połączenie: ping 192.168.1.1, ping 8.8.8.8

Dodaj DNS w /etc/resolv.conf:
nameserver 8.8.8.8
nameserver 8.8.4.4

Dalej w funboxie - 192.168.1.1 lgoujemy i  klikamy na sieć
dalej/nat/pat, dodajemy Secure Web Server (HTTPS) na 443
oraz 
Web Server (HTTP) na port 80 - powinno wykryć w urządzeniu
nasz ip czyli po nazwie hostname np. u mnie serv się
pojawia. Po dodaniu idzemy do sekcji DMZ: i tam dodajemy nasz
statyczny ip czyli 192.168.1.100 i nazwa serv w moim przypadku
tutaj wypuszczamy w świat. Dodaj to opcje dmz dopiero po skonfigurowaniu
httpd i zrobieniu pf.

--------------------------------------------------------
2. Instalacja i konfiguracja HTTPD
1. Sprawdź, czy httpd jest zainstalowany:
pkg_info | grep httpd

2. Włącz usługę:
doas rcctl enable httpd
doas rcctl start httpd

3. Umieść pliki HTML w katalogu:
- /var/www/htdocs/nazwa_strony
Przykład: /var/www/htdocs/nazwa_strony/index.html

4. Test w przeglądarce:
http://192.168.1.100
--------------------------------------------------------
3. HTTPS z ACME - wbudowany jest w OpenBSD bodajże nie
trzeba instalować.

1. Zainstaluj acme-client:
doas pkg_add acme-client

2. Wygeneruj certyfikat:
doas acme-client -v twojadomena.ddnsgeek.com

3. Przeładuj httpd:
doas rcctl reload httpd

4. Automatyczne odnawianie certyfikatu:
Edytuj crontab roota:
doas crontab -e

Dodaj:
0 3 * * * acme-client twojadomena.ddnsgeek.com && rcctl reload httpd

--------------------------------------------------------
4. PF – firewall i ochrona przed DDoS
Przykładowy fragment /etc/pf.conf:

ext_if = "em0"
table <abuse> persist

set block-policy return
set skip on lo

block in all
block out all

# SSH tylko z zaufanego IP
trusted_host = "123.123.123.123"
pass in on $ext_if proto tcp from $trusted_host to ($ext_if) port 22 flags S/SA keep state

# HTTP / HTTPS
pass in on $ext_if proto tcp to ($ext_if) port {80,443} flags S/SA     synproxy state (max-src-conn 40, max-src-conn-rate 20/5, overload <abuse> flush global)

pass out on $ext_if keep state

# test składni:
doas pfctl -nf /etc/pf.conf
# przeładuj reguły:
doas pfctl -f /etc/pf.conf

# sprawdzenie tabeli abuse:
doas pfctl -t abuse -T show

# zapis tabeli abuse do logu:
-------------------------------------------------------
!/bin/sh
LOGFILE="/var/log/pf_abuse.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")
echo "==== $DATE ====" >> $LOGFILE
doas pfctl -t abuse -T show >> $LOGFILE 2>&1
echo "" >> $LOGFILE

--------------------------------------------------------
5. DDNS – dynamiczne IP - tą sekcje robimy na stronie https://www.dynu.com
w OpenBSD nie ma gnudip
serwer korzysta tylko z pkg nie ze źródeł.

4. Zarządzanie serwerem po SSH
- Upewnij się, że PF pozwala na port 22



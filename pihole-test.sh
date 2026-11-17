#!/bin/bash
# Pi-hole Tester fürs Terminal
# Prüft alle Domains aus einer Blockliste gegen einen DNS-Server.
# Nutzung:  bash pihole-test.sh [DNS-Server] [Listen-URL]
# Beispiel: bash pihole-test.sh 192.168.178.201

SERVER="${1:-127.0.0.1}"
URL="${2:-https://raw.githubusercontent.com/Raccoonscityttv/pihole-blacklist/main/rote-domains.txt}"

command -v dig >/dev/null || { echo "dig fehlt: sudo apt install -y dnsutils"; exit 1; }

mapfile -t DOMAINS < <(curl -fsSL "$URL" | sed 's/#.*//' | tr -d '\r' | awk 'NF{print $NF}' | sort -u)
TOTAL=${#DOMAINS[@]}
[ "$TOTAL" -eq 0 ] && { echo "Keine Domains geladen von: $URL"; exit 1; }

echo "Teste $TOTAL Domains gegen DNS-Server $SERVER ..."
BLOCKED=0; NX=0; OPEN=(); i=0
for d in "${DOMAINS[@]}"; do
  i=$((i+1)); printf '\r  %d/%d' "$i" "$TOTAL"
  ans=$(dig +short +time=2 +tries=1 @"$SERVER" "$d" A 2>/dev/null | grep -E '^[0-9.]+$' | tail -n1)
  if [ "$ans" = "0.0.0.0" ]; then
    BLOCKED=$((BLOCKED+1))
  elif [ -z "$ans" ]; then
    NX=$((NX+1))
  else
    OPEN+=("$d -> $ans")
  fi
done
echo
echo "------------------------------------------"
echo "Geblockt:            $BLOCKED"
echo "Existiert nicht:     $NX   (zählt als geblockt)"
echo "NICHT geblockt:      ${#OPEN[@]}"
echo "Ergebnis:            $(( (BLOCKED+NX)*100/TOTAL ))%"
echo "------------------------------------------"
if [ ${#OPEN[@]} -gt 0 ]; then
  echo "Diese Domains kommen durch:"
  printf '  %s\n' "${OPEN[@]}"
fi

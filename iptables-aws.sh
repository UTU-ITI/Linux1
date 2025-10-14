#!/bin/bash

# Descargar IPs de Uruguay
curl -s https://www.ipdeny.com/ipblocks/data/countries/uy.zone -o /tmp/uy.zone

# Crear chain personalizado
iptables -N URUGUAY 2>/dev/null || iptables -F URUGUAY

# Agregar IPs de Uruguay
while read ip; do
    iptables -A URUGUAY -s $ip -j ACCEPT
done < /tmp/uy.zone

# Política: Rechazar todo lo que no sea Uruguay
iptables -A URUGUAY -j DROP

# Aplicar a puertos web
iptables -I INPUT -p tcp --dport 80 -j URUGUAY
iptables -I INPUT -p tcp --dport 443 -j URUGUAY

# SSH solo desde Uruguay (CUIDADO: puedes perder acceso)
# iptables -I INPUT -p tcp --dport 22 -j URUGUAY

echo "Firewall configurado: Solo Uruguay permitido"
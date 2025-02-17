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
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "SMB1" -Type DWord -Value 0
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" -ValueName "LDAPServerIntegrity" -Type DWord -Value 2
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "LsaCfgFlags" -Type DWord -Value 1
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos" -ValueName "TicketExpiry" -Type DWord -Value 600
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "RestrictAnonymous" -Type DWord -Value 1
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -ValueName "RequireSecuritySignature" -Type DWord -Value 1
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ValueName "EnableMulticast" -Type DWord -Value 0
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" -ValueName "NodeType" -Type DWord -Value 2
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "DisableNTLMInDomain" -Type DWord -Value 1
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "RestrictRemoteSAM" -Type DWord -Value 1
Set-GPRegistryValue -Name "HackConRD2025_Hardening_AD" -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "EnableLUA" -Type DWord -Value 1

# Finalizar barra de progreso
$progress = 100
Write-Progress -PercentComplete $progress -Status "Configuración completa" -Activity "Aplicando configuraciones... por favor espere."

Write-Host "Configuraciones aplicadas correctamente en la GPO HackConRD2025_Hardening_AD." -ForegroundColor Green

# Deshabilitar cuentas inactivas (30 días de inactividad)
$inactiveDays = 30
$time = (Get-Date).Adddays(-$inactiveDays)
Get-ADUser -Filter {LastLogonTimeStamp -lt $time} | Disable-ADAccount

Write-Host "Cuentas inactivas deshabilitadas correctamente." -ForegroundColor Yellow

# Ventana emergente para ingresar las direcciones IP de RDP
Add-Type -AssemblyName "System.Windows.Forms"

# Crear el formulario para ingresar las IPs
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ingresar Direcciones IP para RDP"
$form.Size = New-Object System.Drawing.Size(300,150)

# Crear un campo de texto para ingresar las IPs
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(200,20)
$textBox.Location = New-Object System.Drawing.Point(50, 30)
$form.Controls.Add($textBox)

# Crear un botón de "Aceptar"
$button = New-Object System.Windows.Forms.Button
$button.Text = "Aceptar"
$button.Size = New-Object System.Drawing.Size(75,23)
$button.Location = New-Object System.Drawing.Point(100, 70)
$button.Add_Click({
    $global:ips = $textBox.Text
    $form.Close()
})

$form.Controls.Add($button)

# Mostrar el formulario
$form.ShowDialog()

# Verificar que se ingresaron direcciones IP
if ($global:ips) {
    $ipList = $global:ips -split ","
    Write-Host "Aplicando reglas de firewall para RDP desde las IPs: $($ipList -join ', ')" -ForegroundColor Green

    # Aplicar reglas de firewall restrictivas para RDP
    New-NetFirewallRule -DisplayName "Allow RDP from Admin IPs" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress $ipList -Action Allow
    New-NetFirewallRule -DisplayName "Block RDP from Others" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Block

    Write-Host "Reglas de firewall aplicadas correctamente." -ForegroundColor Yellow
} else {
    Write-Host "No se ingresaron direcciones IP. Las reglas de firewall no fueron aplicadas." -ForegroundColor Red
}

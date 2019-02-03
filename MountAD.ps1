<#
Date de création :          2019-02-03 à 03:20
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - https://www.it-connect.fr/active-directory-deployer-adds-avec-powershell/
Version          :          1.0.8
Dernière modif.  :          2019-02-03 à 03:21
#>



do {
    $is_set = Read-Host "Is the network configuration set ? Yes (Y), No (N)"
} until ($is_set -match '^[YN]+$')
if ($is_set -eq "N") {
    Write-Host "Please complete the informations asked below to configure the Active Directory Domain Services."
    $IPAddrv4 = Read-Host "IPv4 address "
    $PrefixLength = Read-Host "Subnet mask in CIDR notation "
    $DefaultGW = Read-Host "Default gateway "
    $FutureHostname = Read-Host "Future hostname of the domain controller (less than 15 characters) "
    New-NetIPAddress -IPAddress $IPAddrv4 -PrefixLength "$PrefixLength" -InterfaceIndex (Get-NetAdapter).ifIndex -DefaultGateway 192.168.1.254
    Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).ifIndex -ServerAddresses ("127.0.0.1")
    Rename-Computer -NewName $FutureHostname -Force
    Write-Host "Re-launch this script after the restart..."
    Wait-Event -Timeout 3
    Restart-Computer
}
else {
    $FeatureList = @("RSAT-AD-Tools","AD-Domain-Services","DNS")
    Foreach ($Feature in $FeatureList) {
        if (((Get-WindowsFeature -Name $Feature).InstallState) -eq "Available") {
            $DomainNameDNS = Read-Host "Enter you future DNS domain name "
            $DomainNameNetbios = Read-Host "Enter your future Netbios name "
            Write-Output "Feature $Feature will be installed now !"
            Try {
                Add-WindowsFeature -Name $Feature -IncludeManagementTools -IncludeAllSubFeature
                Write-Output "$Feature : Installation is a success !"

                $ForestConfiguration = @{
                '-DatabasePath'= 'C:\Windows\NTDS';
                '-DomainMode' = 'Default';
                '-DomainName' = $DomainNameDNS;
                '-DomainNetbiosName' = $DomainNameNetbios;
                '-ForestMode' = 'Default';
                '-InstallDns' = $true;
                '-LogPath' = 'C:\Windows\NTDS';
                '-NoRebootOnCompletion' = $false;
                '-SysvolPath' = 'C:\Windows\SYSVOL';
                '-Force' = $true;
                '-CreateDnsDelegation' = $false }
                
                Update-Help
                Update-Module
                Install-ADDSForest @ForestConfiguration
            } Catch {
                Write-Output "$Feature : Error during installation !"
            }
        }
    }
}
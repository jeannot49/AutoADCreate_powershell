<#
Date de création :          2019-01-28 à 17:05
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow
                            - Chaine Youtube Editions ENI
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
Version          :          1.0.4
Dernière modif.  :          2019-01-28 à 17:06
#>

# Inclusion de la librairie de fonctions
. .\Library_CreateAD.ps1

function CreateSimpleUser{
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Name,                                 # Attribut GivenName de l'utilisateur dans l'AD
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Surname,                              # Attribut Surname de l'utilisateur dans l'AD
        [Parameter(Mandatory=$true, Position=0)]
        [string] $SamAccName,                           # Attribut SamAccountName de l'utilisateur dans l'AD
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Description                           # Attribut Description de l'utilisateur dans l'AD
    )
    $arobase = "@"
    $password = Read-Host -Prompt "Entrez votre mot de passe " -AsSecureString
    $OUusers = "OU=Utilisateurs,OU=Agence,DC=guitton,DC=fr"         # Attribut Path de l'utilisateur dans l'AD
    $dnsroot = (Get-ADDomain).dnsroot
    $upn = "$samaccname$arobase$dnsroot"                # Attribut UserPrincipalName de l'utilisateur dans l'AD
    $fullname = "$name $surname"                        # Attribut Name de l'utilisateur dans l'AD

    New-ADUser `
        -DisplayName $fullname `
        -GivenName $name `
        -Name $fullname `
        -Surname $surname `
        -SamAccountName $samaccname `
        -UserPrincipalName $upn `
        -AccountPassword $password `        # /!\ TODO : Vérifier que le mot de passe n'est plus stocké dans une variable après la fin du script
        -Description $description `
        -Company (Get-ADDomain).NetBIOSName `
        -Path $OUusers `
        -Enabled 1 `
        -Verbose `
}
CreateSimpleUser -Name Jean -Surname Guittoin -SamAccName "jguittoin" -Description "Compte de test"

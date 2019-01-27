# Inclusion de la librairie de fonctions
. .\Library_CreateAD.ps1

$arobase = "@"
$name = Read-Host "Entrez votre prenom "
$surname = Read-Host "Entrez votre nom de famille "
$samaccname = Read-Host "Entrez un nom de login (premiere lettre du prenom suivie du nom. Ex : hdupont "
$password = Read-Host "Entrer un mot de passe "
$description = Read-Host "Description du compte "
$OUusers = "OU=Utilisateurs,OU=Agence,DC=guitton,DC=fr"
$dnsroot = (Get-ADDomain).dnsroot
$upn = "$samaccname$arobase$dnsroot"
$fullname = "$name $surname"

New-ADUser `
-DisplayName $fullname `
-GivenName $name `
-Name $fullname `
-Surname $surname `
-SamAccountName $samaccname `
-UserPrincipalName $upn `
-AccountPassword (ConvertTo-SecureString -AsPlainText $password -Force) `
-Description $description `
-Company (Get-ADDomain).NetBIOSName `
-Path $OUusers `
-Enabled 1 `
-Verbose `

<#
function CreateUserTemplate {
    $tabtemplates = Import-csv -Path .\new_users.csv -delimiter ";" # Importation du tableau contenant les utilisateurs à ajouter, dans les bonnes OU
    foreach ($item in $tabtemplates) {

    }
}
#>
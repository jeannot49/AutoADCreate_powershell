<#
Date de création :          2019-01-28 à 17:05
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow
                            - Chaine Youtube Editions ENI
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
Version          :          1.0.7
Dernière modif.  :          2019-01-31 à 00:34
#>

# Inclusion de la librairie de fonctions
. .\Library_CreateAD.ps1
function AddObjectToGroup {
	Param (
        [Parameter(Mandatory=$true, Position=0)]
		[string] $User,
		[Parameter(Mandatory=$true, Position=0)]
		[string] $Group
    )
	$dnsroot = (Get-ADDomain).dnsroot
	$userchoice = Read-Host "Entrez le nom de login de l'utilisateur "
	Write-Host ""
	(Get-ADGroup -Filter {Name -like "G_*"}).name ; (Get-ADGroup -Filter {name -like "U_*"}).name
	Write-Host ""
	$groupname = Read-Host "Entrez le nom du groupe COMPLET sans le préfixe G_, U_ ou bien DL_ "
	Add-ADGroupMember -Identity $groupname -Member $userchoice -Server $dnsroot -Verbose
}
# Lister les groupes dans 'Global' et 'Universel' : (Get-ADGroup -Filter {Name -like "G_*"}).name ; (Get-ADGroup -Filter {name -like "U_*"}).name
AddObjectToGroup

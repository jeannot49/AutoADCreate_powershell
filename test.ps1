<#
Date de création :          2019-01-28 à 17:05
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow
                            - Chaine Youtube Editions ENI
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
Version          :          1.0.8
Dernière modif.  :          2019-02-01 à 02:09
#>

###################################################
# Tests pour inclusion de la librairie de fonctions
. .\Library_CreateAD.ps1

function CheckandAddUser {
    Param (
        [string] $SamAccName,
        [switch] $Global:isthesame
	)
	$base = (Get-ADUser -Filter {SamAccountName -like $SamAccName}).SamAccountName
	$basename = (Get-ADUser -Filter {SamAccountName -like $SamAccName}).Name
    if ($SamAccName -like $base) {
		Write-Host "$SamAccName est le même que $base"
		Write-Host "/!\ ATTENTION /!\ : L'utilisateur $SamAccName existe déjà et est attribué à $basename, il n'a pas besoin d'etre ajouté"
		$Global:isthesame=$true
    }
    else {
		"$SamAccName est différent de $base"
		Write-Host "L'utilisateur $SamAccName va être créé dans l'AD"
		$Global:isthesame=$false
	}
}

function test {													# Equivalent d'une fonction de création d'utilisateurs
	Write-Host "Valeur avant check : $isthesame"
	$Sam = Read-Host "login "
	$SamDef = "`"$Sam`""
	CheckandAddUser -SamAccName $Sam
	Write-Host "Valeur après check : $isthesame"
	if ($Global:isthesame -eq $false) {
		Write-Host "Créer"
	}
	else {
		Write-Output "Ne pas créer"
	}
}
###############################################
# Appel de la fonction obligatoire pour le test
test
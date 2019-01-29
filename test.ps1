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

function CreateMultipleUser {
    $tabusers = Import-csv -Path .\new_users.csv -delimiter ";" # Importation du tableau contenant les utilisateurs à ajouter, dans les bonnes OU
    $oudomain = (Get-ADDomain).distinguishedname
    $usersdn = (Get-ADOrganizationalUnit -Filter "name -like 'Utilisateurs'").distinguishedname
    Write-Host ""
    foreach ($item in $tabusers) {
        $username = $item.givenname
        $usersurname = $item.surname
        $usercontainer = $item.container
        $userdescription = $item.description
        $usersamaccname = $item.samaccname

        # Vérification de l'existence de l'utilisateur puis ajout s'il n'est pas déjà présent
        $is_existing = (Get-ADUser -Filter "samaccountname -like '$usersamaccname'" -SearchBase "$oudomain").name
        if ($is_existing -eq $null) {
            CreateSimpleUser -Name $username -Surname $usersurname -SamAccName $usersamaccname -Description $userdescription -Container $usercontainer
        }
        else {
            Write-Host "L'utilisateur $is_existing existe deja dans l'annuaire"
            Write-Host ""
        }
        #Write-Host ""
        # /!\ TODO : Réaliser un tableau Excel facilitant la construction des tous les attributs sans erreur
        # Concatener afin d'avoir un SamAccountName dans Excel : =MINUSCULE(CONCATENER(GAUCHE(B2;1);C2))
    }
}

CreateMultipleUser

<#                                                  Remarque 
                                Création automatique avec changement de mdp à la première ouverture de session :
New-ADUser `
    -DisplayName "Jean Guittoin" `
    -Name "Jean Guittoin" `
    -GivenName "Jean" `
    -Surname "Guittoin" `
    -SamAccountName "jguittoin" `
    -UserPrincipalName "jguittoin@guitton.fr" `
    -Description "Compte automatique de test" `
    -Company "GUITTON" `
    -Path "OU=Utilisateurs,OU=Agence,DC=GUITTON,DC=FR" `
    -Enabled 1 `
    -ChangePasswordAtLogon 1 `
    -PasswordNotRequired 1 `
    -Verbose
#>

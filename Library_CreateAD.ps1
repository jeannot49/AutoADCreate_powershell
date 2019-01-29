<#
Date de création :          2019-01-24 à 16:44
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow
                            - Chaine Youtube Editions ENI
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
Version          :          1.0.4
Dernière modif.  :          2019-01-28 à 17:05
#>

#==================================================================
#========================== Library file ==========================
#==================================================================

###################################
# Déclaration de variables globales
$global:coma = ","
$global:rootOU = "OU=$NewOUname"
$global:DefinitiveDC = "DC=$dc1,DC=$dc2"
$global:rootarray = @('Utilisateurs','Ordinateurs','Groupes','Ressources','Partages')

############################################################
# Teste la présence d'un module ou non dans le système local
function Test-Module 
{
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $PSModule
    ) 
    try {
        Import-Module $PSModule
    }
    catch {
        Write-host "Module '$PSModule' absent, veuillez l'installer avant de continuer"
        DisplayErrorMessage  
    }
}

###################################
# Exécute des vérifications de base
function ExecuteVerifications {
    SetUTF8
    #/!\ TODO : Vérifier que l'utilisateur a bien rempli tous les fichiers .csv
}

######################################################################
# Vérification du codage clavier, il doit impérativement être en UTF-8
function SetUTF8 {
    $detected = $PSDefaultParameterValues['Out-File:Encoding']
    if ($detected -like 'utf8') {
        Write-Host ""
        Write-Host "La codage par defaut est $detected, le script peut continuer... "
    }
    else {
        do {
            Write-Host ""
            $choice = Read-Host "Le codage clavier '$detected' n'est pas compatible avec ce script. Voulez-vous le modifier ? Oui (O), Non (N) "
        } until ($choice -match '^[ON]+$')
        switch ($choice) {
            "O" {
                $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
            }
            "N" {
                DisplayErrorMessage
            }
        }
    }
}

############################################
# Affichage d'un Menu réduit en cas d'erreur
function PrincipalMenuReduced {
    Write-Host "_________________________________________________________"
    Write-Host "|                                                       |"
    Write-Host "|          1. Executer les verifications                |"
    Write-Host "|          2. Sortir                                    |"
    Write-Host "|_______________________________________________________|"
do {
        Write-Host ""
        $task = Read-Host "Entrez le numero de la tache a executer "
    } until ($task -match '^[12]+$')
    switch ($task) {
        "1" {
            # /!\ À remettre
            #Start-Transcript
            ExecuteVerifications
        }
        "2" {
            ExitScript
        }
    }
}

#############################
# Affichage du Menu principal
function PrincipalMenu {
    Write-Host "_________________________________________________________"
    Write-Host "|                                                       |"
    Write-Host "|          1. Executer tout le script                   |"
    Write-Host "|          2. Creer une structure d'OU via .csv         |"
    Write-Host "|          3. Creer des groupes a la main               |"
    Write-Host "|          4. Creer des groupes via .csv                |"
    Write-Host "|          5. Creer DL et partages                      |"
    Write-Host "|          6. Creer des utilisateurs                    |"
    Write-Host "|          7. Sortir                                    |"
    Write-Host "|_______________________________________________________|"

    do {
        Write-Host ""
        $task = Read-Host "Entrez le numero de la tache a executer "
    } until ($task -match '^[1234567]+$')
    switch ($task) {
        "1" {
            # /!\ À remettre
            #Start-Transcript
            Write-Host "Le script va continuer..."
        }
        "2" {
            # /!\ À remettre
            #Start-Transcript
            CreateOUStructure
            PrincipalMenu
        }
        "3" {
            # /!\ À remettre
            #Start-Transcript
            CreateSecurityGroup
            PrincipalMenu
        }
        "4" {
            # /!\ À remettre
            #Start-Transcript
            CreateMultipleSecurityGroup
            PrincipalMenu
        }
        "5" {
            # /!\ À remettre
            #Start-Transcript
            CreateAGDLPShare
            PrincipalMenu
        }
        "6" {
            # /!\ À remettre
            #Start-Transcript
            CreateUser
            PrincipalMenu
        }
        "7" {
            ExitScript
        }
    }
}

################################
# Création d'une structure d'OU
function CreateOUStructure {                                
    $tabOU = Import-csv -Path .\new_OU.csv -delimiter ";"   # Importation du tableau contenant les services à placer dans l'annuaire, au sein de l'OU Racine
    foreach ($item in $tabOU) {                             # Création d'OU de base, en fonction du fichier .csv "new_OU.csv"
        $oucreate = $item.name
        $oupath = $item.path
    
        # Création des OU demandées dans le fichier "new_OU.csv"
        New-ADOrganizationalUnit -Name $oucreate -Path $oupath -ProtectedFromAccidentalDeletion $false -verbose
    }
    Write-Host ""
}

############################################
# Création d'un groupe de sécurité à la main
function CreateSecurityGroup {
$groupname = Read-Host "Saisissez le nom du groupe "
$groupcategory = 'Security'
    do {
        Write-Host ""
        $choice = Read-Host "Etendue du groupe : Domaine local (1), Global (2), Universel (3) "
    } until ($choice -match '^[123]+$')
    switch ($choice) {                           # Switch qui attribue les variables $groupscope et $grouppath en fonction du choix réalisé plus haut
        "1" {
            $secgroupprefix = 'DL_'
            $groupscope = 'DomainLocal'
            $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Domaines locaux'").distinguishedname
        }
        "2" {
            $secgroupprefix = 'G_'
            $groupscope = 'Global'
            $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes globaux'").distinguishedname
        }
        "3" {
            $secgroupprefix = 'U_'
            $groupscope = 'Universal'
            $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes universels'").distinguishedname
        }
    }

# Ajout des groupes dans l'OU correspondante
    New-ADGroup -DisplayName $secgroupprefix$groupname -Name $secgroupprefix$groupname -GroupCategory $groupcategory -GroupScope $groupscope -Path $grouppath -Verbose
    Write-Host ""
}

######################################################################
# Création de plusieurs groupes de sécurité à partir d'un fichier .csv
function CreateMultipleSecurityGroup {
    $tabgroup = Import-Csv -Path .\new_groups.csv -delimiter ";"    # Création des groupes nommés dans "new_groups.csv"
    $groupcategory = 'Security'
    Write-Host ""
    foreach ($item in $tabgroup) {
    $groupname = $item.name
    $groupscope = $item.groupscope
        switch ($groupscope) {                           # Switch qui attribue les variables $groupscope et $grouppath en fonction du choix réalisé plus haut
            "DomainLocal" {
                $secgroupprefix = 'DL_'
                $groupscope = 'DomainLocal'
                $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Domaines locaux'").distinguishedname
            }
            "Global" {
                $secgroupprefix = 'G_'
                $groupscope = 'Global'
                $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes globaux'").distinguishedname
            }
            "Universal" {
                $secgroupprefix = 'U_'
                $groupscope = 'Universal'
               $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes universels'").distinguishedname
            }
        }
    # Ajout des groupes dans l'OU correspondante
    New-ADGroup -DisplayName $secgroupprefix$groupname -Name $secgroupprefix$groupname -GroupCategory $groupcategory -GroupScope $groupscope -Path $grouppath -Verbose
    }
}

########################################
# Création de partage (1 OU et ses 4 DL)
function CreateAGDLPShare {
    $dl = "DL"
    $ct = "CT"
    $m = "M"
    $l = "L"
    $r = "R"
    $ou = "OU"
    $uds = "_"
    $coma = ","
    $egal = "="
    $sharename = Read-Host "Nom du partage "
    Write-Host ""
    $addomain = (Get-ADDomain).NetBIOSName
    $dlpath = (Get-ADOrganizationalUnit -Filter "name -like 'Domaines locaux'").distinguishedname
    $completesharename = "$addomain$uds$sharename"
    $oudlsharename = "$dl$uds$completesharename$uds"
    $oudlsharepath = "$ou$egal$dl$uds$completesharename$coma$dlpath"
    New-ADOrganizationalUnit -Name $dl$uds$completesharename -Path $dlpath -ProtectedFromAccidentalDeletion $false -verbose

    #CreateSimpleGroup -GroupName $completesharename$uds$ct -GroupScope DomainLocal
    New-ADGroup -Name "$oudlsharename$ct" -DisplayName "$oudlsharename$ct" -GroupCategory Security -GroupScope DomainLocal -Path "$oudlsharepath" -Verbose
    New-ADGroup -Name "$oudlsharename$m" -DisplayName "$oudlsharename$m" -GroupCategory Security -GroupScope DomainLocal -Path "$oudlsharepath" -Verbose
    New-ADGroup -Name "$oudlsharename$l" -DisplayName "$oudlsharename$l" -GroupCategory Security -GroupScope DomainLocal -Path "$oudlsharepath" -Verbose
    New-ADGroup -Name "$oudlsharename$r" -DisplayName "$oudlsharename$r" -GroupCategory Security -GroupScope DomainLocal -Path "$oudlsharepath" -Verbose
    Write-Host ""
    Write-Host "Vous devrez modifier les ACL au sein du serveur de fichier afin de correspondre aux DL."
}

##########################################
# Création simple d'un utilisateur de l'AD
function CreateSimpleUser {
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Name,                                 # Attribut GivenName de l'utilisateur dans l'AD
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Surname,                              # Attribut Surname de l'utilisateur dans l'AD
        [Parameter(Mandatory=$true, Position=0)]
        [string] $SamAccName,                           # Attribut SamAccountName de l'utilisateur dans l'AD
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Description,                          # Attribut Description de l'utilisateur dans l'AD
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Container
    )
    $coma = ","
    $rootOU = "OU=$NewOUname"
    $usersdn = (Get-ADOrganizationalUnit -Filter "name -like 'Utilisateurs'").distinguishedname
    $arobase = "@"
    $password = Read-Host -Prompt "Entrez votre mot de passe " -AsSecureString
    #$OUusers = "OU=Utilisateurs$coma$rootOU$coma$DefinitiveDC"         # Attribut Path de l'utilisateur dans l'AD
    #$dnsroot = (Get-ADDomain).dnsroot
    $upn = "$samaccname$arobase$dnsroot"                # Attribut UserPrincipalName de l'utilisateur dans l'AD
    $fullname = "$name $surname"                        # Attribut Name de l'utilisateur dans l'AD

    New-ADUser -DisplayName $fullname -GivenName $name -Name $fullname -Surname $surname -SamAccountName $samaccname -UserPrincipalName $upn -AccountPassword $password -Description $description -Company (Get-ADDomain).NetBIOSName -Path "OU=$Container$coma$usersdn" -Enabled 1 -Verbose

# /!\ TODO : Vérifier que le mot de passe n'est plus stocké dans une variable après la fin du script
<# Remarque importante 
On peut créer un utilisateur grâce à la commande :
    - CreateSimpleUser -Name <name> -Surname <surname> -SamAccName <samaccname> -Description <description> -Container <OU>
#>
}

##################################
# Création d'un utilisateur modèle
function CreateUserTemplate {
    
}

######################################################
# Création de plusieurs comptes d'utilisateurs modèles
function CreateMultipleUserTemplate {
    $tabusers = Import-csv -Path .\new_users.csv -delimiter ";" # Importation du tableau contenant les utilisateurs à ajouter, dans les bonnes OU
    foreach ($item in $tabusers) {

    }
}

#####################################
# Création d'un utilisateur dans l'AD
function CreateUser {
    $username = Read-Host "Entrez un prénom "
    $usersurname = Read-Host "Entrez un nom de famille "
    $samaccname = Read-Host "Entrez un nom de login, ex : Prenom Nom --> pnom "
    $userdescription = Read-Host "Entrez une description "
    $usercontainer = Read-Host "Entrez le nom de l'OU parente "
    # Placement dans l'OU
    CreateSimpleUser -Name $username -Surname $usersurname -SamAccName $samaccname -Description "$userdescription" -Container $usercontainer
}

####################################
# Création de plusieurs utilisateurs
function CreateMultipleUser {

}

#####################################################
# Affichage d'un message d'erreur et sortie du script
function DisplayErrorMessage {
    Write-Host ""
    Write-Host "Erreur. Veuillez lire le message plus haut."
    Wait-Event -Timeout 5
    PrincipalMenuReduced
}

##################
# Sortir du script
function ExitScript {
    Write-Host "Fin du script..." 
# /!\ À remettre    Stop-Transcript
    Wait-Event -Timeout 3
    Exit
}

#=========================================================================
#========================== End of library file ==========================
#=========================================================================
<#
Date de création :          2019-01-24 à 16:44
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow Topics
                                . Load variables from another powershell script
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
                            - https://www.itprotoday.com/powershell/powershell-one-liner-creating-and-modifying-environment-variable
Version          :          1.0.7
Dernière modif.  :          2019-01-31 à 00:34
#>

#==================================================================
#========================== Library file ==========================
#==================================================================

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
    #/!\ TODO : Vérifier la version de Powershell : tests à réaliser sur WS2008, WS2008R2, WS2012, WS2012R2, WS2016
}

######################################################################
# Vérification du codage clavier, il doit impérativement être en UTF-8
function SetUTF8 {
    $detected = $PSDefaultParameterValues['Out-File:Encoding']
    if ($detected -like 'utf8') {
        Write-Host ""
        Write-Host "La codage par défaut est $detected, le script peut continuer... "
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
    Write-Host "|       1. Exécuter les vérifications                   |"
    Write-Host "|       2. Sortir                                       |"
    Write-Host "|_______________________________________________________|"
do {
        Write-Host ""
        $task = Read-Host "Entrez le numéro de la tâche à exécuter "
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
    Write-Host "|       1. Exécuter tout le script                      |"
    Write-Host "|       2. Créer une structure d'OU via .csv            |"
    Write-Host "|       3. Créer des groupes                            |"
    Write-Host "|       4. Créer Groupes DL et OU                       |"
    Write-Host "|       5. Créer des utilisateurs/modeles               |"
    Write-Host "|       6. Sortir                                       |"
    Write-Host "|                                                       |"
    Write-Host "|____M E N U      P R I N C I P A L_____________________|"

    do {
        Write-Host ""
        $task = Read-Host "Entrez le numéro de la tâche à exécuter "
    } until ($task -match '^[1234567]+$')
    #Start-Transcript
    switch ($task) {
        "1" {
            Write-Host "Le script va continuer..."
        }
        "2" {
            CreateOUStructure
            PrincipalMenu
        }
        "3" {
            PrincipalMenuGroups
            PrincipalMenu
        }
        "4" {
            CreateAGDLPShare
            PrincipalMenu
        }
        "5" {
            PrincipalMenuUsers
            PrincipalMenu
        }
        "6" {
            ExitScript
            PrincipalMenu
        }
        "7" {
            
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
        Write-Host ""
    }
}
function PrincipalMenuGroups {
    Write-Host "_________________________________________________________"
    Write-Host "|                                                       |"
    Write-Host "|       1. Créer des groupes a la main                  |"
    Write-Host "|       2. Créer des groupes via .csv                   |"
    Write-Host "|       3. Ne rien faire                                |"
    Write-Host "|                                                       |"
    Write-Host "|____M E N U      G R O U P E S_________________________|"
    
    do {
        Write-Host ""
        $taskusers = Read-Host "Entrez le numéro de la tâche à exécuter "
    } until ($taskusers -match '^[12345]+$')
    switch ($taskusers) {
        "1" {
            CreateSecurityGroupByHand
            PrincipalMenuUsers 
        }
        "2" {
            CreateMultipleSecurityGroup
            PrincipalMenuUsers
        }
        "3" {
            Write-Host "Le script va continuer..."
        }
    }
}

################################
# Création d'un groupe de simple
function CreateSimpleGroup {
        Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $GroupName,
        [Parameter(Mandatory=$true, Position=0)]
        [string] $GroupScope
    )
    $groupcategory = 'Security'
    switch ($GroupScope) {                           # Attribution des variables $secgroupprefix et $grouppath en fonction des paramètres passés plus haut
        "DomainLocal" {
            $secgroupprefix = 'DL_'
            $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Domaines locaux'").distinguishedname
        }
        "Global" {
            $secgroupprefix = 'G_'
            $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes globaux'").distinguishedname
        }
        "Universal" {
            $secgroupprefix = 'U_'
            $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes universels'").distinguishedname
        }
    }
# Ajout des groupes dans l'OU correspondante
    New-ADGroup -DisplayName $secgroupprefix$groupname -Name $secgroupprefix$groupname -GroupCategory $groupcategory -GroupScope $groupscope -Path $grouppath -Verbose
    Write-Host ""
}

##################################################################
# Vérifie si un groupe existe déjà ou non, auquel cas il le crééra
function CheckandAddGroup {
	Param (
        [Parameter(Mandatory=$true, Position=0)]
		[string] $Name,
		[Parameter(Mandatory=$true, Position=0)]
		[string] $Scope
    )
    $uds = "_"
        switch ($Scope) {
        "1" {
            $base = "DL$uds$Name"
        }
        "2" {
            $base = "G$uds$Name"
        }
        "3" {
            $base = "U$uds$Name"
        }
    }
    $result = (Get-ADGroup -Filter {Name -like $base}).name
    if ($base -eq $result) {
        Write-Host ""
		Write-Host "Le groupe $base existe, il n'a pas besoin d'etre ajouté"
	}
	else {
        switch ($Scope) {                           # Switch qui attribue la variable $groupscope en fonction de la valeur passée en paramètre
			"1" {
				$groupscope = "DomainLocal"
			}
			"2" {
				$groupscope = "Global"
			}
			"3" {
				$groupscope = "Universal"
            }   
        }
        CreateSimpleGroup -GroupName $Name -GroupScope $groupscope
	}
}

############################################
# Création d'un groupe de sécurité à la main
function CreateSecurityGroupByHand {
    $groupname = Read-Host "Saisissez le nom du groupe "
    do {
        $groupscope = Read-Host "Étendue du groupe : Domaine local (1), Global (2), Universel (3) "
    } until ($groupscope -match '^[123]+$')

    CheckandAddGroup -Name $groupname -Scope $groupscope
}

######################################################################
# Création de plusieurs groupes de sécurité à partir d'un fichier .csv
function CreateMultipleSecurityGroup {
    $tabgroup = Import-Csv -Path .\new_groups.csv -delimiter ";"    # Création des groupes nommés dans "new_groups.csv"
    $groupcategory = 'Security'
    foreach ($item in $tabgroup) {
        $groupname = $item.name
        $groupscope = $item.groupscope
        switch ($groupscope) {                           # Switch qui attribue les variables $groupscope et $grouppath en fonction du choix réalisé plus haut
            "DomainLocal" {
                $scope = "1"
                $secgroupprefix = 'DL_'
                $groupscope = 'DomainLocal'
                $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Domaines locaux'").distinguishedname
            }
            "Global" {
                $scope = "2"
                $secgroupprefix = 'G_'
                $groupscope = 'Global'
                $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes globaux'").distinguishedname
            }
            "Universal" {
                $scope = "3"
                $secgroupprefix = 'U_'
                $groupscope = 'Universal'
                $grouppath = (Get-ADOrganizationalUnit -Filter "name -like 'Groupes universels'").distinguishedname
            }
        }
    # Ajout des groupes dans l'OU correspondante
    #New-ADGroup -DisplayName $secgroupprefix$groupname -Name $secgroupprefix$groupname -GroupCategory $groupcategory -GroupScope $groupscope -Path $grouppath -Verbose
    CheckandAddGroup -Name $groupname -Scope $scope
    }
Write-Host ""
}

########################################
# Création de partage (1 OU et ses 4 DL)
function CreateAGDLPShare {
    $uds = "_"
    $coma = ","
    $egal = "="
    $sharename = Read-Host "Nom du partage "
    Write-Host ""
    $addomain = (Get-ADDomain).NetBIOSName
    $dlpath = (Get-ADOrganizationalUnit -Filter "name -like 'Domaines locaux'").distinguishedname
    $completesharename = "$addomain$uds$sharename"
    $oudlsharename = "DL$uds$completesharename$uds"
    $oudlsharepath = "OU=DL$uds$completesharename$coma$dlpath"
    New-ADOrganizationalUnit -Name "DL$uds$completesharename" -Path $dlpath -ProtectedFromAccidentalDeletion $false -verbose

    # Création des groupes de domaine locaux
    New-ADGroup -Name $oudlsharename"CT" -DisplayName $oudlsharename"CT" -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    New-ADGroup -Name $oudlsharename"M" -DisplayName $oudlsharename"M" -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    New-ADGroup -Name $oudlsharename"L" -DisplayName $oudlsharename"L" -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    New-ADGroup -Name $oudlsharename"R" -DisplayName $oudlsharename"R" -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    Write-Host ""
    Write-Host "Vous devrez modifier les ACL au sein du serveur de fichier afin de correspondre aux DL."
    Write-Host ""
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
    $usersdn = (Get-ADOrganizationalUnit -Filter "name -like 'Utilisateurs'").distinguishedname
    $companyname = (Get-ADDomain).NetBIOSName
    $arobase = "@"
    #$password = Read-Host -Prompt "Entrez votre mot de passe " -AsSecureString
    $dnsroot = (Get-ADDomain).dnsroot
    $upn = "$samaccname$arobase$dnsroot"                # Attribut UserPrincipalName de l'utilisateur dans l'AD
    $fullname = "$name $surname"                        # Attribut Name de l'utilisateur dans l'AD
    
    New-ADUser `
        -DisplayName "$fullname" `
        -GivenName "$name" `
        -Name "$fullname" `
        -Surname "$surname" `
        -SamAccountName "$samaccname" `
        -UserPrincipalName "$upn" `
        -Description "$description" `
        -Company "$companyname" `
        -Path "OU=$Container$coma$usersdn" `
        -Department "$container" `
        -ChangePasswordAtLogon 1 `
        -PasswordNotRequired 1 `
        -Enabled 1 `
        -Verbose
    Write-Host ""
    #-AccountPassword $password `
        # /!\ ATTENTION : Dans ce cas, vérifier que le mot de passe n'est plus stocké dans une variable après la fin du script
}

function PrincipalMenuUsers {
    Write-Host "_________________________________________________________"
    Write-Host "|                                                       |"
    Write-Host "|       1. Créer un utilisateur à la main               |"
    Write-Host "|       2. Créer des utilisateur via .csv               |"
    Write-Host "|       3. Créer un modele à la main                    |"
    Write-Host "|       4. Créer des modeles via .csv                   |"
    Write-Host "|       5. Ne rien faire                                |"
    Write-Host "|                                                       |"
    Write-Host "|____M E N U      U T I L I S A T E U R S_______________|"

    do {
        Write-Host ""
        $taskusers = Read-Host "Entrez le numéro de la tâche à exécuter "
    } until ($taskusers -match '^[12345]+$')
    switch ($taskusers) {
        "1" {
            CreateUser
            PrincipalMenuUsers 
        }
        "2" {
            CreateMultipleUser
            PrincipalMenuUsers
        }
        "3" {
            CreateUserTemplate
            PrincipalMenuUsers
        }
        "4" {
            CreateMultipleUserTemplate
            PrincipalMenuUsers
        }
        "5" {
            Write-Host "Le script va continuer..."
        }
    }
}

##################################
# Création d'un utilisateur modèle
function CreateUserTemplate {
    
}

######################################################
# Création de plusieurs comptes d'utilisateurs modèles
function CreateMultipleUserTemplate {
    $tabusertemplate = Import-csv -Path .\new_usertemplates.csv -delimiter ";" # Importation du tableau contenant les modèles d'utilisateurs à ajouter, dans les bonnes OU
    foreach ($item in $tabusertemplate) {

    # /!\ TODO : Réaliser un tableau Excel facilitant la construction des tous les attributs sans erreur
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
    CreateSimpleUser -Name $username -Surname $usersurname -SamAccName $samaccname -Description $userdescription -Container $usercontainer
}

####################################
# Création de plusieurs utilisateurs
function CreateMultipleUser {
    $tabusers = Import-csv -Path .\new_users.csv -delimiter ";" # Importation du tableau contenant les utilisateurs à ajouter, dans les bonnes OU
    $oudomain = (Get-ADDomain).distinguishedname
    Write-Host ""
    foreach ($item in $tabusers) {
        $username = $item.givenname
        $usersurname = $item.surname
        $usercontainer = $item.container
        $userdescription = $item.description
        $usersamaccname = $item.samaccname

        # Vérification de l'existence de l'utilisateur puis ajout s'il n'est pas déjà présent
        $is_existing = (Get-ADUser -Filter "samaccountname -like '$usersamaccname'" -SearchBase "$oudomain").name
        if ($null -eq $is_existing) {
            CreateSimpleUser -Name $username -Surname $usersurname -SamAccName $usersamaccname -Description $userdescription -Container $usercontainer
        }
        else {
            Write-Host "L'utilisateur $is_existing existe déjà dans l'annuaire"
            Write-Host ""
        }
        #Write-Host ""
        # /!\ TODO : Réaliser un tableau Excel facilitant la construction des tous les attributs sans erreur
        # Concatener afin d'avoir un SamAccountName dans Excel : =MINUSCULE(CONCATENER(GAUCHE(B2;1);C2))
    }
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
    Write-Host "Le script va se terminer dans 3 secondes..." 
# /!\ À remettre 
    #Stop-Transcript
# /!\ TODO : Prévenir des Timeout afin que l'utilisateur n'aie pas l'impression d'un plantage
    Wait-Event -Timeout 3
    Exit
}

#=========================================================================
#========================== End of library file ==========================
#=========================================================================
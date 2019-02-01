<#
Date de création :          2019-01-24 à 16:44
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow Topics
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
                            - https://www.itprotoday.com/powershell/powershell-one-liner-creating-and-modifying-environment-variable
                            - http://gmergit.blogspot.com/2011/11/recemment-jai-eu-besoin-de-creer-des.html
Version          :          1.0.8
Dernière modif.  :          2019-02-01 à 02:09
#>

#==================================================================
#========================== Library file ==========================
#==================================================================

###################################
# Exécute des vérifications de base
function ExecuteVerifications {
    SetUTF8
    TestModulePresence -PSModule ActiveDirectory
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

############################################################
# Teste la présence d'un module ou non dans le système local
function TestModulePresence {
    Param (
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

############################################
# Affichage d'un Menu réduit en cas d'erreur
function PrincipalMenuReduced {
    Write-Host "          _________________________________________________________"
    Write-Host "          |                                                       |"
    Write-Host "          |       1. Exécuter les vérifications                   |"
    Write-Host "          |       2. Sortir                                       |"
    Write-Host "          |_______________________________________________________|"
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
    Write-Host "          _________________________________________________________"
    Write-Host "          |                                                       |"
    Write-Host "          |       1. Exécuter tout le script                      |"
    Write-Host "          |       2. Créer une structure d'OU via .csv            |"
    Write-Host "          |       3. Créer des groupes                            |"
    Write-Host "          |       4. Créer Groupes DL et OU                       |"
    Write-Host "          |       5. Créer des utilisateurs/modeles               |"
    Write-Host "          |       6. Sortir                                       |"
    Write-Host "          |                                                       |"
    Write-Host "          |____M E N U      P R I N C I P A L_____________________|"

    do {
        Write-Host ""
        $task = Read-Host "Entrez le numéro de la tâche à exécuter "
    } until ($task -match '^[123456]+$')
    # /!\ À remettre
    #Start-Transcript
    switch ($task) {
        "1" {
            Write-Host "Le script va continuer..."
        }
        "2" {
            CreateBaseStructure
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

function CreateBaseStructure {
    Param (
        [string] $RootOrganizationUnit
	)
    $DomainDN = (Get-ADDomain).distinguishedname
	$RootArray = @('Utilisateurs','Ordinateurs','Groupes','Ressources','Partages')
	
    # Création de l'OU racine
    Write-Host ""
    Write-Host "/!\ Étape n°1.0 : Création de l'OU racine"
	New-ADOrganizationalUnit -DisplayName $RootOrganizationUnit -Name $RootOrganizationUnit -Path $DomainDN -ProtectedFromAccidentalDeletion $false -Verbose

    # Création des OU de base sous la racine
	Write-Host ""
    Write-Host "/!\ Étape n°1.1 : Création d'OU de base, sous la racine --> voir ligne suivante"
    Write-Host "                  Ordinateurs, Utilisateurs, Groupes, Partages, Ressources"
	$path = (Get-ADOrganizationalUnit -Filter {name -eq $RootOrganizationUnit}).distinguishedname
	foreach ($item in $RootArray) {
		New-ADOrganizationalUnit -DisplayName $item -Name $item -Path $path -ProtectedFromAccidentalDeletion $false -verbose
	}

    # Création d'OU sous les OU de base mentionnées plus haut
    Write-Host ""
    Write-Host "/!\ Etape n°1.2 : Création des OU de services"
	$tabOU = Import-csv -Path .\new_ou.csv -delimiter ";"   # Importation du tableau contenant les services à placer dans l'annuaire, au sein de l'OU Racine
    foreach ($item in $tabOU) {                             # Création d'OU de base, en fonction du fichier .csv "new_OU.csv"
        $oucreate = $item.name
        $oupath = $item.path
		
		New-ADOrganizationalUnit -Name $oucreate -Path $oupath -ProtectedFromAccidentalDeletion $false -verbose
	}
	
	# Création de groupes de sécurité, basé sur les sous-OU de l'OU Utilisateurs
    Write-Host ""
    Write-Host "/!\ Etape n°2 : Création de groupes de sécurité, portant le même nom que les OU de service sous Utilisateurs"
	$tabGroupOU = ($tab | Where-Object {$_.ou1name -match "Utilisateurs"}).name
	foreach ($item in $tabGroupOU) {
		CheckandAddGroup -Name $item -Scope '2'                   # Création de groupes de sécurité globaux
	}
}

function PrincipalMenuGroups {
    Write-Host "          _________________________________________________________"
    Write-Host "          |                                                       |"
    Write-Host "          |       1. Créer des groupes a la main                  |"
    Write-Host "          |       2. Créer des groupes via .csv                   |"
    Write-Host "          |       3. Ne rien faire                                |"
    Write-Host "          |                                                       |"
    Write-Host "          |____M E N U      G R O U P E S_________________________|"
    
    do {
        Write-Host ""
        $taskgroup = Read-Host "Entrez le numéro de la tâche à exécuter "
    } until ($taskgroup -match '^[123]+$')
    switch ($taskgroup) {
        "1" {
            CreateSecurityGroupByHand
            PrincipalMenuGroups 
        }
        "2" {
            CreateMultipleSecurityGroup
            PrincipalMenuGroups
        }
        "3" {
            Write-Host "Le script va continuer..."
        }
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
    CheckandAddGroup -Name $groupname -Scope $scope
    }
}

############################################################
# Vérifie si un groupe existe déjà ou non avant de l'ajouter
function CheckandAddGroup {
	Param (
		[string] $Name,
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
        Write-Host "/!\ ATTENTION /!\ : Le groupe $base existe déjà, il n'a pas besoin d'etre ajouté"
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

#######################################
# Création simple d'un groupe dans l'AD
function CreateSimpleGroup {
        Param (
        [string] $GroupName,
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
}

function PrincipalMenuUsers {
    Write-Host "          _________________________________________________________"
    Write-Host "          |                                                       |"
    Write-Host "          |       1. Créer un utilisateur à la main               |"
    Write-Host "          |       2. Créer des utilisateur via .csv               |"
    Write-Host "          |       3. Créer un modele à la main                    |"
    Write-Host "          |       4. Créer des modeles via .csv                   |"
    Write-Host "          |       5. Ne rien faire                                |"
    Write-Host "          |                                                       |"
    Write-Host "          |____M E N U      U T I L I S A T E U R S_______________|"

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

    }
}

#####################################
# Création d'un utilisateur dans l'AD
function CreateUser {
    $username = Read-Host "Entrez un prénom "
    $usersurname = Read-Host "Entrez un nom de famille "
    $samaccname = Read-Host "Entrez un nom de login, ex : Prenom Nom --> pnom "
    $userdescription = Read-Host "Entrez une description "
    Write-Host ""
    (Get-ADOrganizationalUnit -Filter * | Where-Object {$_.DistinguishedName -like "OU=*,OU=Utilisateurs,OU=Agence,DC=guitton,DC=fr"}).Name
    Write-Host ""

    # Choix de l'OU parente
    $usercontainer = Read-Host "Entrez le nom de l'OU parente parmi l'une ci-dessus"
    
    # Proposition d'inclusion dans le groupe de sécurité global portant le même nom que l'OU (O), sinon on se contente de créer l'utilisateur (N)
    do {
        $taskgroup = Read-Host "Faut-il l'ajouter au groupe G_$usercontainer ? Oui (O), Non (N) "
        Write-Host ""
    } until ($taskgroup -match '^[ON]+$')
    switch ($taskgroup) {
        "O" {
            CheckandAddUser -SamAccName $samaccname
            if ($Global:is_thesame -eq $false) {
                $servername = (Get-ADDomain).dnsroot
                $uds = "_"
                CreateSimpleUser -Name "$username" -Surname "$usersurname" -SamAccName "$samaccname" -Description "$userdescription" -Container "$usercontainer"
                Add-ADGroupMember -Identity "G$uds$usercontainer" -Members "$samaccname" -Server "$servername"
            }
        }
        "N" {
            CheckandAddUser -SamAccName $samaccname
            if ($Global:is_thesame -eq $false) {
                $servername = (Get-ADDomain).dnsroot
                $uds = "_"
                CreateSimpleUser -Name "$username" -Surname "$usersurname" -SamAccName "$samaccname" -Description "$userdescription" -Container "$usercontainer"
            }
        }
    }
}

####################################
# Création de plusieurs utilisateurs
function CreateMultipleUser {
    $tabusers = Import-csv -Path .\new_users.csv -delimiter ";" # Importation du tableau contenant les utilisateurs à ajouter, dans les bonnes OU
    $oudomain = (Get-ADDomain).distinguishedname
    foreach ($item in $tabusers) {
        $username = $item.givenname
        $usersurname = $item.surname
        $usercontainer = $item.container
        $userdescription = $item.description
        $usersamaccname = $item.samaccname

        # Vérification de l'existence et ajout de l'utilisateur dans l'AD
        CheckandAddUser -SamAccName $usersamaccname
        if ($Global:is_thesame -eq $false) {
            $servername = (Get-ADDomain).dnsroot
            $uds = "_"
            CreateSimpleUser -Name "$username" -Surname "$usersurname" -SamAccName "$usersamaccname" -Description "$userdescription" -Container "$usercontainer"
            Add-ADGroupMember -Identity "G$uds$usercontainer" -Members "$usersamaccname" -Server "$servername"
        }
    }
}

#################################################################
# Vérifie si un utilisateur existe déjà ou non avant de l'ajouter
function CheckandAddUser {
    Param (
        [string] $SamAccName,
        [switch] $Global:is_thesame
	)
	$base = (Get-ADUser -Filter {SamAccountName -like $SamAccName}).SamAccountName
	$basename = (Get-ADUser -Filter {SamAccountName -like $SamAccName}).Name
    if ($SamAccName -like $base) {
		Write-Host "/!\ ATTENTION /!\ : Ce nom existe déjà, il est attribué à $basename (login $base) et n'a pas besoin d'etre ajouté."
        $Global:is_thesame=$true
    }
    else {
		$Global:is_thesame=$false
	}
}

##########################################
# Création simple d'un utilisateur de l'AD
function CreateSimpleUser {
    Param (
        [string] $Name,              # Attribut GivenName de l'utilisateur dans l'AD
        [string] $Surname,           # Attribut Surname de l'utilisateur dans l'AD
        [string] $SamAccName,        # Attribut SamAccountName de l'utilisateur dans l'AD
        [string] $Description,       # Attribut Description de l'utilisateur dans l'AD
        [string] $Container
    )
    $coma = ","
    $usersdn = (Get-ADOrganizationalUnit -Filter "name -like 'Utilisateurs'").distinguishedname
    $companyname = (Get-ADDomain).NetBIOSName
    $arobase = "@"
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
    Wait-Event -Timeout 3
    Exit
}

#=========================================================================
#========================== End of library file ==========================
#=========================================================================
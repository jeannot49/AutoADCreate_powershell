<#
Date de création :          2019-01-24 à 16:44
Auteur           :          Jean Guitton
Sources          :          Microsoft Technet, Stack Overflow
Version          :          1.0.1
Dernière modif.  :          2019-01-27 à 02:46
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
    $tabOU = Import-csv -Path .\nom_OU.csv -delimiter ";" # Importation du tableau contenant les services à placer dans l'annuaire, au sein de l'OU Racine
    foreach ($item in $tabOU) {
        $oucreate = $item.name
        $oupath = $item.path
    
        # Création des OU demandées dans le fichier "nom_OU.csv"
        New-ADOrganizationalUnit -Name $oucreate -Path $oupath -ProtectedFromAccidentalDeletion $false -verbose
    }
    Write-Host ""
}

############################################
# Création d'un groupe de sécurité à la main
function CreateSecurityGroup {
$groupname = Read-Host "Saisissez le nom du groupe"
$groupcategory = 'Security'
    do {
        Write-Host ""
        $choice = Read-Host "Etendue du groupe : Domaine local (1), Global (2), Universel (3)"
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

##########################################################
# Création de plusieurs groupes à partir d'un fichier .csv
function CreateMultipleSecurityGroup {
$tabgroup = Import-Csv -Path .\new_groups.csv -delimiter ";"
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
    $sharename = Read-Host "Nom du partage"
    Write-Host ""
    $addomain = (Get-ADDomain).NetBIOSName
    $completesharename = "$addomain$uds$sharename"
    $oudlsharename = "$dl$uds$completesharename$uds"
    $oudlsharepath = "$ou$egal$dl$uds$completesharename$coma$dlpath"
    $dlpath = (Get-ADOrganizationalUnit -Filter "name -like 'Domaines locaux'").distinguishedname
    New-ADOrganizationalUnit -Name $dl$uds$completesharename -Path $dlpath -ProtectedFromAccidentalDeletion $false -verbose

    #CreateSimpleGroup -GroupName $completesharename$uds$ct -GroupScope DomainLocal
    New-ADGroup -Name $oudlsharename$ct -DisplayName $oudlsharename$ct -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    New-ADGroup -Name $oudlsharename$m -DisplayName $oudlsharename$m -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    New-ADGroup -Name $oudlsharename$l -DisplayName $oudlsharename$l -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    New-ADGroup -Name $oudlsharename$r -DisplayName $oudlsharename$r -GroupCategory Security -GroupScope DomainLocal -Path $oudlsharepath -Verbose
    Write-Host ""
    Write-Host "Vous devrez modifier les ACL au sein du serveur de fichier afin de correspondre aux DL"
}

#####################################################
# Affichage d'un message d'erreur et sortie du script
function DisplayErrorMessage {
    Write-host "An error occured, please read the message above and restart the script"
    Wait-Event -Timeout 3
    
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
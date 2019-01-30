<#
Date de création :          2019-01-24 à 16:44
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow
                            - Chaine Youtube Editions ENI
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
Version          :          1.0.6
Dernière modif.  :          2019-01-30 à 00:07
#>

###############################
# Appel au fichier de fonctions
. .\Library_CreateAD.ps1

#============================================================
#========================== Worker ==========================
#============================================================

###############################################################
# Exécution de différentes vérifications essentielles au script
ExecuteVerifications

#############################
# Affichage du Menu principal
Write-Host " "
Write-Host "!!!!!  IMPORTANT  !!!!! "
Write-Host "S'il s'agit de la premiere execution de ce script dans l'annuaire, veuillez selectionner l'option (1)"
PrincipalMenu

####################################
# Demandes d'informations du domaine
Write-Host " "
Write-Host "Description du script :"
Write-Host " "
Write-Host "/!\ Étape n°0 : Entrer le nom de domaine en notation LDAP comme ceci : domaine.fr --> dc1 = DOMAINE & dc2 = FR"
$dc1 = Read-Host "Entrez la valeur de dc1 "
$dc2 = Read-Host "Entrez la valeur de dc2 "
Write-Host " "
Write-Host "/!\ Étape n°1 : Créer l'OU racine, elle accueillera toutes les OU du domaine"
$NewOUname = Read-Host "Entrez le nom de l'OU racine du domaine "
Write-Host " "
Write-Host "Avant de continuer, veuillez consulter le fichier nommé README.txt"
# /!\ TODO : Automatiser cette partie autant que possible

##########################
# Déclaration de variables
$coma = ","
$rootOU = "OU=$NewOUname"
$DefinitiveDC = "DC=$dc1,DC=$dc2"
$rootarray = @('Utilisateurs','Ordinateurs','Groupes','Ressources','Partages')

################################################
# Création des unités d'organisation principales
Write-Host " "
Write-Host "/!\ Étape n°2 : Création de l'arborescence en dessous de cette racine --> voir ligne suivante :"
Write-Host "            Plusieurs OU de base : Ordinateurs, Utilisateurs, Groupes, Partages, Ressources"
Test-Module -PSModule ActiveDirectory
New-ADOrganizationalUnit -DisplayName $NewOUname -Name $NewOUname -Path $DefinitiveDC -ProtectedFromAccidentalDeletion $false

foreach ($i in $rootarray) {
    New-ADOrganizationalUnit -DisplayName $i -Name $i -Path $rootOU$coma$DefinitiveDC -ProtectedFromAccidentalDeletion $false -verbose
}

Write-Host ""
Write-Host "/!\ Etape n°3 : Creer les OU principales, elle accueillera toutes les OU du domaine"
# /!\ TODO : Créer un Excel plus "convivial" pour la création des OU qui génère un .csv compatible avec le script
CreateOUStructure

# /!\ TODO : Création de groupe automatique en fonction du nom des OU dans l'OU Utilisateurs

##################################
# Création des groupes de sécurité
# Plusieurs choix possibles : 
#   - taper 1 permet la saisie manuelle d'un groupe grâce à la fonction CreateSecurityGroup présente dans le fichier Library_CreateAD.ps1
#   - taper 2 crée un ou plusieurs groupes de sécurité en s'appuyant sur le fichier .csv et la fonction CreateMultipleSecurityGroup
Write-Host ""
Write-Host "/!\ Etape n°4 : Génération des groupes via une saisie manuelle ou par le fichier 'new_groups.csv'"
do {
    do {
        Write-Host "0 - Sortie"
        Write-Host "1 - Ajouter un groupe à la main"
        Write-Host "2 - Ajouter plusieurs groupes grâce à un fichier .csv"
        Write-Host ""
        $choice = Read-Host "Votre choix"
        $ok = $choice -match '^[012]+$'

        if (-not $ok) {
            Write-Host "Entrée invalide, veuillez recommencer"
            Write-Host ""
        }
    } until ($ok)
switch ($choice) {
    "1" {
        CreateSecurityGroup
    }
    "2" {
        CreateMultipleSecurityGroup
    }
}
} until ($choice -match '^[0]+$')

<# 
/!\ TODO : Proposer à l'utilisateur de créer des groupes, ou non, mais le prévenir que l'absence de groupe pourra provoquer des erreurs si l'on souhaite
ajouter des utilisateurs dans ces groupes
#>

######################################################################################
# Création des partages et de 4 DL (AGDLP), 1 OU par partage dans l'OU "Domaine local"
Write-Host ""
Write-Host "/!\ Etape n°5 : Création d'une OU et de 4 DL correspondant à un partage réseau au sein du domaine"
do {
    $choice = Read-Host "Faut-il ajouter des partages ? Oui (O), Non (N)"
} until ($choice -match '^[ON]+$')
if ($choice -eq "O") {
    CreateAGDLPShare
}

###################################################
# Création de modèle(s) d'utilisateur(s) du domaine 
do {
    do {
        Write-Host "0 - Sortie"
        Write-Host "1 - Ajouter un modèle d'utilisateur à la main"
        Write-Host "2 - Ajouter plusieurs modèles d'utilisateurs grâce à un fichier .csv"
        Write-Host ""
        $choice = Read-Host "Votre choix"
        $ok = $choice -match '^[012]+$'

        if (-not $ok) {
            Write-Host "Entrée invalide, veuillez recommencer"
        }
    } until ($ok)
switch ($choice) {
    "1" {
        CreateUserTemplate
    }
    "2" {
        CreateMultipleUserTemplate
    }
}
} until ($choice -match '^[0]+$')

#############################################
# Création d'un/des utilisateur(s) du domaine
Write-Host "/!\ Etape n°6.2 : Création d'un ou de plusieurs utilisateur(s) au sein du domaine"
PrincipalMenuUsers

##################
# Sortie du script
ExitScript

#===================================================================
#========================== End of worker ==========================
#===================================================================
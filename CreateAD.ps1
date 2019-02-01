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

###############################
# Appel au fichier de fonctions
. .\Library_CreateAD.ps1

#============================================================
#========================== Frontend ========================
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

#########################################
# Demandes d'informations pour le domaine
$RootOrganizationUnit = Read-Host "Entrez le nom de l'OU racine du domaine "
CreateBaseStructure -RootOrganizationUnit $RootOrganizationUnit

# /!\ TODO : Créer un Excel plus "convivial" pour la création des OU qui génère un .csv compatible avec le script

##################################
# Création des groupes de sécurité
Write-Host ""
Write-Host "/!\ Etape n°3 : Génération des groupes via une saisie manuelle ou par le fichier 'new_groups.csv'"
PrincipalMenuGroups

######################################################################################
# Création des partages et de 4 DL (AGDLP), 1 OU par partage dans l'OU "Domaine local"
Write-Host ""
Write-Host "/!\ Etape n°4 : Création d'une OU et de 4 DL correspondant à un partage réseau au sein du domaine"
do {
    $choice = Read-Host "Faut-il ajouter des partages ? Oui (O), Non (N)"
} until ($choice -match '^[ON]+$')
if ($choice -eq "O") {
    CreateAGDLPShare
}

#############################################
# Création d'un/des utilisateur(s) du domaine
Write-Host ""
Write-Host "/!\ Etape n°5 : Création d'un ou de plusieurs utilisateur(s) au sein du domaine"
PrincipalMenuUsers

##################
# Sortie du script
Write-Host ""
Write-Host "/!\ Etape n°6"
ExitScript

#===================================================================
#========================== End of Frontend ========================
#===================================================================
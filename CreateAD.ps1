<#
Date de création :          2019-01-24 à 16:44
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow Topics
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
                            - https://www.itprotoday.com/powershell/powershell-one-liner-creating-and-modifying-environment-variable
                            - http://gmergit.blogspot.com/2011/11/recemment-jai-eu-besoin-de-creer-des.html
                            - https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
                            - https://lazywinadmin.com/2015/05/powershell-remove-diacritics-accents.html (François-Xavier Cat)
                            - https://en.wikiversity.org/wiki/PowerShell/Arrays_and_Hash_Tables
                            - https://www.developpez.net/forums/d1077534/general-developpement/programmation-systeme/windows/scripts-batch/executer-commande-contenue-variable/
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

##########################################
# Création de la structure de base de l'AD
CreateBaseStructure

##################################
# Création des groupes de sécurité
Write-Host ""
Write-Host "/!\ Etape n°3 : Génération des groupes via une saisie manuelle ou par le fichier 'new_groups.csv'"
PrincipalMenuGroups

######################################################################################
# Création des partages et de 4 DL (AGDLP), 1 OU par partage dans l'OU "Domaine local"
Write-Host ""
Write-Host "/!\ Etape n°4 : Création d'OU et de ses 4 DL correspondants (règle AGDLP)"
PrincipalMenuAGDLP

#############################################
# Création d'un/des utilisateur(s) du domaine
Write-Host ""
Write-Host "/!\ Etape n°5 : Création d'un ou de plusieurs utilisateur(s) au sein du domaine"
PrincipalMenuUsers

##################
# Sortie du script
Write-Host ""
Write-Host "/!\ Etape n°6 : Fin du script"
ExitScript

#===================================================================
#========================== End of Frontend ========================
#===================================================================
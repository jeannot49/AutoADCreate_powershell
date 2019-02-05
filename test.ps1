<#
Date de création :          2019-01-28 à 17:05
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
Version          :          1.0.9
Dernière modif.  :          2019-02-04 à 22:05
#>

###################################################
# Tests pour inclusion de la librairie de fonctions
. .\Library_CreateAD.ps1


###############################################
# Appel de la fonction obligatoire pour le test
CheckCSV
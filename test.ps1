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

######################################################
# Création de plusieurs comptes d'utilisateurs modèles
function CreateMultipleUserTemplate {
    $tabusertemplate = Import-csv -Path csv\new_templates.csv -delimiter ";" # Importation du tableau contenant les modèles d'utilisateurs à ajouter, dans les bonnes OU
    foreach ($item in $tabusertemplate) {
        $point = "."
        $mod = "0m"
        $templatename = $item.name
        $templatenameLow = "$templatename".ToLower()
        $templatecontainer = $item.container
        $templategroup = $item.group

        # Tronquage du nom à partir de 5 caractères
        if ($templatenameLow.Length -lt 4 ) {
            $templatenameLowTrunk = $templatenameLow.Substring(0,$templatenameLow.Length)
        }
        else {
            $templatenameLowTrunk = $templatenameLow.Substring(0,4)
        }
    
        # Tronquage du nom d'OU à partir de 12 caractères
        if ($templatecontainer.Length -lt 12 ) {
            $templatecontainerTrunk = $templatecontainer.Substring(0,$templatecontainer.Length)
        }
        else {
            $templatecontainerTrunk = $templatecontainer.Substring(0,12)
        }

        $templatenameDef = Remove-StringDiacriticAndUpper -String $mod$point$templatenameLowTrunk$point$templatecontainerTrunk
        $templatedescrDef = "Modèle de compte $templatenameLow pour le service $templatecontainer"
        
        # Vérification et ajout des modèles
        # Puis ajout dans les bons groupes en fonction du fichier "csv\new_templates.csv"
        CheckUser -SamAccName "$templatenameDef"
        if ($Global:is_thesame -eq $false) {
            Write-Host ""
            Write-Host "--- Création du modèle `"$templatenameDef`" ---"
            CreateSimpleTemplate -Name "$templatenameDef" -Container "$templatecontainer" -Description "$templatedescrDef"
            $FinalCommand = "$templategroup | Add-ADGroupMember -Members $templatenameDef"
            Invoke-Expression $FinalCommand
        }
    }
}

function Detest {
    $tabusertemplate = Import-csv -Path csv\new_templates.csv -delimiter ";" # Importation du tableau contenant les modèles d'utilisateurs à ajouter, dans les bonnes OU
    $init = 0
    foreach ($item in $tabusertemplate) {
        $templatename = $item.name
        $templatecontainer = $item.container
        $GroupUniversal = $item.universal
        $point = "."
        $mod = "0m"
        $templatenameLow = $templatename.ToLower()

        # Tronquage du nom à partir de 5 caractères
        if ($templatenameLow.Length -lt 4 ) {
            $templatenameLowTrunk = $templatenameLow.Substring(0,$templatenameLow.Length)
        }
        else {
            $templatenameLowTrunk = $templatenameLow.Substring(0,4)
        }
    
        # Tronquage du nom d'OU à partir de 12 caractères
        if ($templatecontainer.Length -lt 12 ) {
            $templatecontainerTrunk = $templatecontainer.Substring(0,$templatecontainer.Length)
        }
        else {
            $templatecontainerTrunk = $templatecontainer.Substring(0,12)
        }

        $templatenameDef = Remove-StringDiacriticAndUpper -String $mod$point$templatenameLowTrunk$point$templatecontainerTrunk
        $templatedescrDef = "Modèle de compte $templatenameLow pour le service $templatecontainer"

        CheckUser -SamAccName "$templatenameDef"
        if ($Global:is_thesame -eq $false) {
            Write-Host ""
            Write-Host "--- Création du modèle `"$templatenameDef`" ---"
            CreateSimpleTemplate -Name "$templatenameDef" -Container "$templatecontainer" -Description "$templatedescrDef"
            $GroupSplit = $tabusertemplate[$init].groups.Split(',')
            for ($i = 0; $i -lt $GroupSplit.Length; $i++) {
                $QuotedGroupSplit = $GroupSplit[$i]
                $DefQuotedGroupSplit = "`"$QuotedGroupSplit`""
                $FinalCommand = "$DefQuotedGroupSplit | Add-ADGroupMember -Members $templatenameDef"
                Invoke-Expression $FinalCommand
            }
        }
        $init = $init + 1
    }
}

###############################################
# Appel de la fonction obligatoire pour le test
Detest
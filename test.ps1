<#
Date de création :          2019-01-28 à 17:05
Auteur           :          Jean Guitton
Sources          :          - Microsoft Technet
                            - Stack Overflow
                            - Chaine Youtube Editions ENI
                            - https://www.sqlshack.com/how-to-secure-your-passwords-with-powershell/
Version          :          1.0.8
Dernière modif.  :          2019-02-01 à 02:09
#>

###################################################
# Tests pour inclusion de la librairie de fonctions
. .\Library_CreateAD.ps1

##################################
# Création d'un utilisateur modèle
function CreateUserTemplate {
    # Demande d'informations à l'utilisateur
    Write-Host ""
    $Template = Read-Host "Entrez un nom de modèle (ex: resp), maximum 5 caractères "
    Write-Host ""
    $userou = (Get-ADOrganizationalUnit -Filter * | Where-Object {$_.Name -like "Utilisateurs"}).DistinguishedName
    $OUarray = (Get-ADOrganizationalUnit -Filter * | Where-Object {$_.DistinguishedName -like "OU=*,$userou"}).Name
    $OUarray
    Write-Host ""
    do {
        $ChoiceOU = Read-Host "Entrez l'OU d'appartenance pour ce modèle (liste ci-dessus) "
    } until ($OUarray -contains $ChoiceOU)
    $ChoiceOULow = $ChoiceOU.ToLower()
    Write-Host ""
    $GroupArray = (Get-ADGroup -Filter {(Name -like "G_*") -or (name -like "U_*")}).name
    $GroupArray
    Write-Host ""
    do {
        $CountGroup = Read-Host "Entrez le nombre de groupes (listés ci-dessus) dont le modèle doit faire partie "
    } until ($CountGroup -match '^[123456789]+$')
    
    # Création d'un tableau contenant tous les groupes auxquels appartiendra le modèle, il sera créé par la fonction CreateSimpleTemplate
    $point = "."
    $mod = "m"
    $dnsroot = (Get-ADDomain).dnsroot
    $FullTemplName = "$mod$point$Template$point$ChoiceOU".ToLower()

    # Ajout du nouvel l'utilisateur modèle au groupe demandé après vérification de sa non-existence dans l'annuaire
    CheckUser -SamAccName "$FullTemplName"
    if ($Global:is_thesame -eq $false) {
        CreateSimpleTemplate -Name "$Template" -Container $ChoiceOU -Description "Compte modèle - $Template - $ChoiceOULow" -GroupMemberof $UserChoice
        Write-Host ""
    }
    for ($i = 0; $i -lt $CountGroup; $i++) {
        $j = $i+1

        # Vérification de la saisie : pour chacune des entrées ci-dessus le groupe doit exister au préalable
        do {
            do {
                $UserChoice = Read-Host "Groupe n°$j contenant l'utilisateur $FullTemplName "
            } until ($GroupArray -contains $UserChoice)
            CheckGroupMembership -Username "$FullTemplName" -Groupname "$UserChoice"                # Appel à la fonction dé vérification d'appartenance à un groupe
            if ($Global:is_member -eq $false) {
                Add-ADGroupMember -Identity "$UserChoice" -Members "$FullTemplName" -Server "$dnsroot"      # S'il l'utilisateur n'appartient pas au groupe, alors on l'y ajoute
            }
        } until ($Global:is_member -eq $false)        
        Write-Host ""
    }
}

######################################################
# Création de plusieurs comptes d'utilisateurs modèles
function CreateMultipleUserTemplate {
    $tabusertemplate = Import-csv -Path .\new_templates.csv -delimiter ";" # Importation du tableau contenant les modèles d'utilisateurs à ajouter, dans les bonnes OU
    foreach ($item in $tabusertemplate) {
        $point = "."
        $mod = "m"
        $templatename = $item.name
        $templatedescr = $item.description
        $templatecontainer = $item.container
        $templategroup = $item.group
        $templatenameDef = "$mod$point$templatename$point$templatecontainer".ToLower()
        #$templatenameDefLow = $templatenameDef.ToLower()

        # Vérification et ajout des modèles
        # Puis ajout dans les bons groupes en fonction du fichier "new_templates.csv"
        CheckUser -SamAccName "$templatenameDef"
        if ($Global:is_thesame -eq $false) {
            Write-Host ""
            Write-Host "--- Création du modèle `"$templatenameDef`" ---"
            CreateSimpleTemplate -Name "$templatename" -Container "$templatecontainer" -Description "$templatedescr"
            $FinalCommand = "$templategroup | Add-ADGroupMember -Members $templatenameDef"
            Invoke-Expression $FinalCommand
        }
    }
    Write-Host ""
}

#############################################################
# Vérification de l'appartenance d'un utilisateur à un groupe
function CheckGroupMembership {
    param (
        [string] $Username,
        [string] $Groupname
    )
    $dnsroot = (Get-ADDomain).dnsroot
    $groupmember = (Get-ADGroupMember -Identity "$Groupname" -Server "$dnsroot").name
    if ($groupmember -contains $Username) {
        Write-Host "ATTENTION /!\ : L'utilisateur"`"$Username`"" fait déjà partie du groupe "`"$Groupname`"" et n'a pas besoin d'y être ajouté."
        $Global:is_member = $true
    }
    else {
        $Global:is_member = $false
    }
}

##################################
# Création d'un modèle utilisateur
function CreateSimpleTemplate {
    Param (
        [string] $Name,                 # Inférieur ou égal à 4 caractères
        [string] $Container,            # Inférieur ou égal à 12 caractères
        [string] $Description           # Description du modèle
    )
    $point = "."
    $coma = ","
    $mod = "m"
    $usersdn = (Get-ADOrganizationalUnit -Filter "name -like 'Utilisateurs'").distinguishedname
    $companyname = (Get-ADDomain).NetBIOSName
    $dnsroot = (Get-ADDomain).dnsroot
    $DefinitiveName = Remove-StringDiacriticAndUpper -String "$mod$point$Name$point$Container"

    New-ADUser `
        -Name "$DefinitiveName" `
        -DisplayName "$DefinitiveName" `
        -GivenName "$DefinitiveName" `
        -Company "$companyname" `
        -Path "OU=$Container$coma$usersdn" `
        -Department "$Container" `
        -PasswordNotRequired 1 `
        -Description "$Description" `
        -Enabled 0 `
        -Verbose
}

###############################################
# Appel de la fonction obligatoire pour le test
CreateMultipleUserTemplate
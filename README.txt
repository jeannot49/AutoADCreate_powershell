**************************************************************************************************
*** 							    À lire avant de commencer :								   ***
**************************************************************************************************
Il est conseillé d'exécuter ce programme sur un annuaire Active Directory venant tout juste d'être installé. Il peut en effet y avoir des conflits sur la création des groupes par exemple, notamment s'ils existent déjà. 
Plusieurs étapes sont détaillées dans le script mais il faut au préalable remplir les fichiers .csv qui serviront de base de données afin de peupler l'AD.
Il est possible dans ce script de sélectionner l'étape à réaliser. Un menu sera en effet disponible dès début mais le programme pourra être lancé dans son intégralité. Néanmoins, lors de la toute première exécution, il est conseillé de lancer le script en entier afin de mettre en place un maximum d'objets.

Les 5 fichiers .csv à remplir sont donc
	- new_OU.csv
	- new_groups.csv
	- new_templates.csv
	- new_users.csv
	- new_shares.csv

Il vous sera demandé dans le script de bien vérifier que les champs sont remplis correctement.
En effet, cette partie est essentielle pour le bon déroulement de la procédure. Si une erreur survient, pensez en premier lieu à vérifier ces fichiers.

Penser à entrer la commande suivante pour autoriser les scripts :
Set-ExecutionPolicy Unrestricted

Remarque importante : Ce script a été testé sur une machine Windows Server 2012R2, à jour du 2 Février 2019 avec Powershell 4.0. Il est parfaitement compatible avec celle-ci mais peut présenter des beugs sur des versions précédentes ou suivantes.
Un système en 32 ou 64 bits est requis.

Lisez attentivement les instructions d'installation qui suivent. Elles vous aideront à remplir correctement votre Active Directory.



**************************************************************************************************
***  					    ADCreate.ps1 --> Instructions d'utilisation :				 	   ***
**************************************************************************************************
1 - Pensez à bien remplir tous les fichiers CSV. Le script vérifiera leur présence de toute façon.
----------
2 - Ayez un Active Directory vierge, des utilisateurs ou des groupes dans un AD déjà peuplé pourraient entrer en conflit avec ceux inclus dans les fichiers CSV lors de l'ajout.
----------
3 - Le script vérifie également au départ si la console est en utf-8, si la version de Powershell est 4 au minimum et charge le module ActiveDirectory s'il ne l'est pas.
----------
4 - Après cette étape apparaîtra un tableau (MENU PRINCIPAL) listant les actions possibles.

	. -> L'option 1 agit comme un assistant afin de peupler l'AD, soit à la main, soit grâce aux CSV préalablement remplis. C'est l'option recommandée pour un premier lancement sur un serveur.

	. -> L'option 2 permet de créer la structure de base de l'annuaire. Le reste du script repose sur cette partie, il est donc important qu'elle aie été exécutée au moins une fois.
	Elle requiert un fichier CSV "csv\new_OU.csv' pour fonctionner.

	. -> L'option 3 ajoute un ou plusieurs groupe(s) selon les besoins. Elle se présente sous la forme d'un autre tableau. En fonction du choix de l'étendue, le nom sera préfixé de "DL_", "G_" ou bien "U_".
		
		Entrées du (MENU GROUPES)
		  1. Des questions seront posées, il faudra y répondre pour créer le groupe.
		  2. Ajout via le fichier "csv\new_groups.csv".

	. -> L'option 4 permet la même action pour créer des "partages" AGDLP. 
	C'est une pratique consistant à imbriquer des groupes afin de ne pas avoir à modifier les permissions NTFS par la suite sur le serveur de fichiers.
	Premièrement, une OU sera créée, symbolisant le "partage". À l'intérieur, 4 groupes de domaine local se terminant tous par "CT", "M", "L" et "R" correspondent respectivement aux ACL : "Contrôle Total", "Modification", "Lecture" et "Refus".
	Ces quatre groupes de DL (Domaine local) seront à placer dans les options dudit partage sur un serveur de fichiers membre du domaine. On attribuera alors le contrôle total au groupe <groupe>_CT, la modification au groupe <groupe>_M etc.
	La fin de l'opération consistera à ajouter des groupes de sécurité "Globaux" ou "Universels" dans ces groupes de DL afin d'appliquer les permissions des utilisateurs sur chacun de ces partages.
	L'intérêt de l'automatisation prend alors ici tout son sens puisque l'on s'évite la création de tous ces objets. On respecte également une nomenclature bien définie.
		
		Entrées du (MENU PARTAGES AGDLP)
		  1. Ajout à la main, avec demande du nombre de partages à créer, ainsi que leur nom.
		  2. Ajout via le fichier CSV "csv\new_shares.csv".

	. -> L'option 5 recense les ajouts d'utilisateurs et de modèles, différenciées car ne possédant pas les mêmes caractéristiques.
	L'utilisateur aura par exemple une adresse mail générée automatiquement par le remplissage des champs <SamAccountName> et <Domain>.
	Le compte modèle sera quant à lui désactivé par défaut, et fera partie de groupes définis à l'avance.

		Entrée du (MENU UTILISATEURS)
		  1. Ajout à la main d'un utilisateur avec demande du nombre à créer.
		  2. Ajout via le fichier CSV "csv\new_users.csv"
		  3. Ajout de modèles à la main : leur nom est généré automatiquement par : le préfixe "0m" puis la fonction du modèle (par exemple une fonction de Responsable) et tronqué à 4 caractères. Le nom de son OU parente, qui composera la fin du nom, le sera à 12.
		  4. Ajout via le fichier CSV "csv\new_templates.csv", il faut entrer les noms avec les préfixes "G_" ou "U_" dans le fichier Excel, il y aura un risque d'erreur d'attribution aux groupes dans le cas contraire.

----------
	. -> L'option 6 installe automatiquement tous les objets cités dans les fichiers Excel. Le script demande en premier lieu la confirmation que tous les fichiers sont remplis correctement, puis procède à la construction de l'arborescence.
	Cette option est déconseillée si vous n'êtes pas certain du contenu de vos fichiers CSV. Une certaine rigueur dans le nommage des utilisateurs, des groupes, des partages et des modèles est requise pour cette partie.
----------
	. -> L'option 7 permet de quitter le script quand on le souhaite. Un timeout d'une seconde se déclenche avant de quitter le processus.



**************************************************************************************************
***										  Mises à jour :									   ***
**************************************************************************************************
V1.0.0 : Création de la structure de bases d'UO (Types de ressources, services, matériel 
		 etc.) grâce au fichier new_OU.csv
V1.0.1 : Fonction d'ajout de groupes (Domaine local, global et universel)
		 Ajout de groupes grâce au fichier new_groups.csv
		 Ajout de DL spécifiques à AGDLP
V1.0.2 : Fonctionnalité de vérification d'erreur : codage UTF-8 requis
		 Menu principal réduit si l'utilisateur ne respecte pas les spécifications
		 Correction de soucis d'affichage
V1.0.4 : Fonctionnalité d'ajout simple d'un utilisateur
		 Refonte de l'en-tête pour correspondre aux sources multiples
V1.0.5 : Fonction CreateUser fonctionnelle
		 Modifications esthétiques du script pendant son déroulement
		 Correction de bug sur la fonction d'ajout de Groupes/DL (AGDLP)
V1.0.6 : Ajout de la fonction de création d'utilisateurs via un fichier csv
		 Modification de l'encodage des fichiers Excel afin de supporter l'UTF-8
V1.0.7 : Amélioration des fonctions de groupes : vérification de l'existence avant d'ajouter
		 Création d'un Menu Utilisateur et Groupes dans des boites
		 Test de la fonction d'ajout d'un utilisateur à un groupe
		 Nettoyage général du code, suppression des commentaires inutiles et ajout de nouveaux
		 	. Commentaire des fonctions à compléter
		 Création de groupes globaux portant le même nom que les OU sous "Utilisateurs"
V1.0.8 : Amélioration des fonctions d'utilisateurs : vérification de l'existence avant d'ajouter
		 Nettoyage du code : mise en ordre des fonctions de la librairie
		 Rapatriement des commandes de CreateAD.ps1 dans la librairie, au sein d'une fonction
		    . Nom : CreateBaseStructure
		 Automatisation de la recherche de DNSroot (ex : domain.fr)
		 Renommage de certaines fonctions
		 Correction de bugs mineurs : numéros en trop dans les menus
V1.0.9 : Vérification de la version de Powershell
		 Vérification de l'existence d'une OU avant de la créer
		 Demander à l'utilisateur combien d'utilisateurs/groupes/modèles il veut créer
		 Fonctionnalité Mode automatique : aucune action utilisateur
		 Création de modèles d'utilisateurs
		 Vérification de la longueur des oms de modèles : inférieurs à 20 caractères au total
		   . Fonction d'ajout automatique d'ajout de modèles au leurs groupes, grâce au fichier .csv new_templates.csv
		 Fonction enlevant tout caractère accentué et/ou en majuscule : Remove-StringDiacriticAndUpper (par François-Xavier Cat, voir sources)
		 Vérification : tous les fichiers .csv requis doivent être présents

V1.0.0 : Création  d'un script d'installation de l'AD et promotion en contrôleur de domaine
**************************************************************************************************
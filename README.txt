**************************************************************************************************
À lire avant de commencer :

  . Il est conseillé d'exécuter ce programme sur un annuaire Active Directory venant tout juste d'être installé. Il peut en effet y avoir des conflits sur la création des groupes par exemple, notamment s'ils existent déjà. 
    Plusieurs étapes sont détaillées dans le script mais il faut au préalable remplir les fichiers .csv qui serviront de base de données afin de peupler l'AD.
    Il est possible dans ce script de sélectionner l'étape à réaliser. Un menu sera en effet disponible dès début mais le programme pourra être lancé dans son intégralité. Néanmoins, lors de la toute première exécution, il est conseillé de lancer le script en entier afin de mettre en place un maximum d'objets.

Les 4 fichiers .csv à remplir sont donc
	- new_OU.csv
	- new_groups.csv
	- new_templates.csv
	- new_users.csv

Il vous sera demandé dans le script de bien vérifier que les champs sont remplis correctement.
En effet, cette partie est essentielle pour le bon déroulement de la procédure. Si une erreur survient, pensez en premier lieu à vérifier ces fichiers.

Remarque importante : 

**************************************************************************************************
Mises à jour :

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
V1.0.8 : Amélioration des fonctions d'utilisateurs : vérification de l'existence avant d'ajouter
		 Nettoyage du code : mise en ordre des fonctions de la librairie
		 Rapatriement des commandes de CreateAD.ps1 dans la librairie, au sein d'une fonction
		    . Nom : CreateBaseStructure
		 Automatisation de la recherche de DNSroot (ex : domain.fr)
		 Renommage de certaines fonctions
		 Correction de bugs mineurs : numéros en trop dans les menus
**************************************************************************************************
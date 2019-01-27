**************************************************************************************************
# À lire avant de commencer :

  . Il est conseillé d'exécuter ce programme sur un annuaire Active Directory venant tout juste d'être installé. Il peut en effet y avoir des conflits sur la création des groupes par exemple, notamment s'ils existent déjà. 
    Plusieurs étapes sont détaillées dans le script mais il faut au préalable remplir les fichiers .csv qui serviront de base de données afin de peupler l'AD.
    Il est possible dans ce script de sélectionner l'étape à réaliser. Un menu sera en effet disponible dès début mais le programme pourra être lancé dans son intégralité. Néanmoins, lors de la toute première exécution, il est conseillé de lancer le script en entier afin de mettre en place un maximum d'objets.




**************************************************************************************************
# Mises à jour :

V1.0.0 : 	Création de la structure de bases d'UO (Types de ressources, services, matériel 
		etc.) grâce au fichier new_OU.csv
V1.0.1 : 	Fonction d'ajout de groupes (Domaine local, global et universel)
		Ajout de groupes gr�ce au fichier new_groups.csv
		Ajout de DL sp�cifiques � AGDLP
V1.0.2 :	Fonctionnalit� de v�rification d'erreur : codage UTF-8 requis
		Menu principal r�duit si l'utilisateur ne respecte pas les sp�cifications
		Correction de soucis d'affichage
**************************************************************************************************
## � faire :
  . Ajout des comptes utilisateurs mod�les
  . Gestion des logs
  . V�rifier que l'OU racine mentionn�e dans le fichier Excel est le m�me que celui not� en d�but      de script

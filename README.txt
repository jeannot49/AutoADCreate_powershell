**************************************************************************************************
� lire avant de commencer :

  . Il est conseill� d'ex�cuter ce programme sur un annuaire Active Directory venant tout juste d'�tre install�. Il peut en effet y avoir des conflits sur la cr�ation des groupes par exemple, notamment s'ils existent d�j�. 
    Plusieurs �tapes sont d�taill�es dans le script mais il faut au pr�alable remplir les fichiers .csv qui serviront de base de donn�es afin de peupler l'AD.
    Il est possible dans ce script de s�lectionner l'�tape � r�aliser. Un menu sera en effet disponible d�s d�but mais le programme pourra �tre lanc� dans son int�gralit�. N�anmoins, lors de la toute premi�re ex�cution, il est conseill� de lancer le script en entier afin de mettre en place un maximum d'objets.




**************************************************************************************************
Mises � jour :

V1.0.0 : 	Cr�ation de la structure de bases d'UO (Types de ressources, services, mat�riel 			etc.) gr�ce au fichier new_OU.csv
V1.0.1 : 	Fonction d'ajout de groupes (Domaine local, global et universel)
		Ajout de groupes gr�ce au fichier new_groups.csv
		Ajout de DL sp�cifiques � AGDLP
**************************************************************************************************
� faire :
  . Ajout des comptes utilisateurs mod�les
  . Gestion des logs
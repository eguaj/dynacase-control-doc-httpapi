# Sandbox : Test de l'API {#ref:90cd9315-fd76-4367-b9c0-07841c51db6a}

L'API est mise à disposition avec un module facultatif permettant de tester des requêtes REST.

Ce paquet se nomme `Dynacase HTTP Api v1 : sandbox`, il ajoute l'application `HTTPAPI_V1_DEV` et son interface est
accessible via l'url : `<contexte>/?app=HTTPAPI_V1_DEV`.

## Interface {#ref:e853c070-a6b2-415e-b112-0f9f4784a1f8}

L'interface se présente comme ci-dessous :

![ Interface sandbox ](sandbox.png "Interface sandbox")

Elle est séparée en deux parties :

* la partie de gauche est dédiée à la construction de la requête : vous avez accès à :
 * une liste de requête standard d'exemple (examples),
 * la page de présentation de l'api (Show the documentation),
 * l'URL de la ressource,
 * la méthode que vous souhaitez appliquer à l'URL (`GET`, `POST`, `PUT`, `DELETE`),
 * un champ pour saisir le contenu de la requête (uniquement pour les requêtes `POST`, `PUT`),
 * le bouton pour envoyer la requête.
* la partie droite est dédiée au résultat, elle est automatiquement mise à jour après un clique sur le bouton envoyer la requête. Le résultat est présenté sous la forme d'une chaîne JSON indentée.

## Précautions d'usage {#ref:149c4fdb-f9cd-4488-a4e5-fb44fcb75016}

Ce programme est mis à disposition à des fins pédagogique pour mieux comprendre l'API, son usage en production est à
**proscrire**.
La base de documents manipulée via l'application est la base réelle, si vous supprimez, modifiez, créez un document
celui-ci est modifié en conséquence.



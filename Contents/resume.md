# Résumé de l'API {#rest:3ac9a1f3-1099-4c12-8c86-8215c4045567}

## Structure message

    {
        success: <bool(true|false)>,
        error: <string(errMsg)>,
        warnings: [
            <string(warnStr_1)>,
            ...
            <string(warnStr_n)>,
        ],
        data: <json(responseData)>
    }

## Algorithme interprétation des réponses HTTP par le client REST

    SI HTTP status == 2xx ALORS
        SI la réponse n'est pas un objet JSON valide ALORS
            ARRET: erreur générale de communication
        FINSI
        SI la réponse n'a pas les 4 propriétés {success, error, warnings, data} ALORS
            ARRET: erreur générale de communication
        FINSI
        SI .success !== true ALORS
            ARRET: erreur de l'API : voir .error avec le message d'erreur
        FINSI
        SI .warning existe ET est un array non vide ALORS
            présenter les messages éventuels de warning
        FINSI
        traiter la réponse .data
    SINON
        SI la réponse n'est pas un objet JSON valide ALORS
            ARRET: erreur générale de communication
        FINSI
        SI la réponse n'a pas les 4 propétés {success, error, warnings, data} ALORS
            ARRET: erreur générale de communication
        FINSI
        SI .success !== false ALORS
            ARRET: erreur conflit sémantique...
        FINSI
        traiter la réponse d'erreur
    FINSI

## Authentification

On garde le fonctionnement actuel qui est que toute requête doit être
authentifiée par HTTP Basic et que c'est Apache qui gère l'authentification.

Après avoir installé dynacase-control, la seule requête possible est celle pour
positionner le mot de passe :

    SI le passwd admin n'est pas défini ALORS
        SI la requête n'est pas /api/v1/auth ALORS
            Envoyer une erreur indiquant qu'il faut
                d'abord positionner le password.
            ,--
            | HTTP/1.1 403 Undefined password
            | {
            |     success: false,
            |     error: "Password must be defined first."
            | }
            '--
            RETOURNE
        FINSI
    FINSI
    SI la requête n'est pas authentifié ALORS
        Envoyer HTTP/1.1 401 Authentication required
        ,--
        | HTTP/1.1 401 Authentication required
        | {
        |     success: false,
        |     error: "You must be authenticated to perform this action."
        | }
        '--
        RETOURNE
    FINSI
    traiter la requête

Par la suite toutes les requêtes doivent être authentifiées.

## Codes erreur HTTP

Liste des codes erreurs émis par l'API :

`HTTP/1.1 400 Insecure connection detected`
:   La connexion n'est pas sécurisée : refaire la requête par HTTPS.

`HTTP/1.1 401 Authentication required`
:   La requête n'est pas authentifiée : envoyer la requête avec auth HTTP
    Basic.

`HTTP/1.1 403 Undefined password`
:   Le mot de passe n'a pas été défini : positionner le mot de passe
    (`PUT /api/v1/auth`).

`HTTP/1.1 409 Conflict`
:   L'état de la ressource est incompatible avec l'action demandée.

`HTTP/1.1 500 Requested action returned with error`
:   L'action demandée à rencontré une erreur.

## Carte de l'api {#rest:7bdf9aab-e021-4819-a73b-7335a5766a69}

### setup

La ressource `setup` permet de voir la version actuelle de dynacasee-control,
s'il y a une mise à jour de disponible et de déclencher la mise à jour si une
mise à jour est disponible.

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/setup**                                                    | 100%           | Version de dynacase-control et version de mise à jour disponible     |
| PUT    |                                                                      |                | -                                                                    |
| POST   | **/api/v1/setup**                                                    | 0%             | Mettre à jour dynacase-control si mise à jour disponible             |
| DELETE |                                                                      |                | -                                                                    |

#### GET

* Obtenir la version :

    GET /api/v1/setup

Réponse si pas de mise à jour disponible :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            version: "1.4.0-20140114123456"
        }
    }

Réponse si une mise à jour est disponible :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            version: "1.4.0-20140114123456",
            update: "2.0.0-1"
        }
    }

#### POST

* Mettre à jour dynacase-control :

    POST /api/v1/setup

Réponse si pas de mise à jour disponible :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Your installation is already up-to-date.",
        data: {
            version: "1.4.0-20140114123456"
        }
    }

Réponse si mise à jour appliquée avec succés :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            version: "2.0.0-1"
        }
    }

Réponse si erreur dans le téléchargement et/ou l'application de la mise à jour
:

    HTTP/1.1 500 Error
    {
        success: false,
        error: "Error [...]"
    }

### auth

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/auth**                                                     | 100%           | Gérer le mot de passe de connexion à dynacase-control                |
| PUT    | **/api/v1/auth**                                                     | 100%           | Modifier le mot de passe de connexion                                |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

#### GET

* Status authentification :

Peut servir à savoir si le mot de passe est correct ou si on est conneecté à
dynacase-control.

    GET /api/v1/auth

Réponse si pas authentifié :

    HTTP/1.1 401 Authentication required

Réponse si authentifié :

    HTTP/1.1 200 OK
    {
        "success": true
    }

#### PUT

* Modifier le mot de passe de connexion :

    PUT /api/v1/auth
    {
        "password": "50Me s3cr3t p4s5W0rD"
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true
    }

### system-parameters/

Présentation des `system-parameters` :

L'idée de ces paramètres est de remplacer certains paramètres "CORE" de
Dynacase. Dynacase n'aurait donc plus de références en dur à la base de données
par exemple, mais demanderait à Control de lui fournir les coordonnées de sa
base de données. Idem pour le vault.

Le fonctionnement global précis reste encore à définir,

Les paramètres sont regroupés dans des sections et sont typés. Une contrainte
peut être appliquée lors de la sauvegarde des valeurs des paramètres pour
vérifier que la valeur est correcte par exemple.

* Section "Base de données" :
  * Nom du service postgresql : type "text"
* Section "SMTP" :
  * Nom d'hôte : type "text"
  * Port : type "integer"
  * autres ?
* Section "Vault" :
  * Chemin du vault : type "text"
* autres ?



|  Type  |              URL               |  Implanté  |  Signification                               |
| ------ | ------------------------------ | ---------- | -------------------------------------------- |
| GET    | **/api/v1/system-parameters/** | 100%       | Liste des sections et des paramètres système |
| PUT    |                                |            |                                              |
| POST   |                                |            |                                              |
| DELETE |                                |            |                                              |

#### GET

* Lister les sections et les paramètres système :

    GET /api/v1/system-parameters/

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": [
            {
                "uri": "/api/v1/system-paremeters/database",
                "section": "database",
                "label": "Database server",
                "description": "Database used by Dynacase context",
                "parameters": [
                    {
                        "uri": "/api/v1/system-parameters/database/core_db",
                        "name": "core_db",
                        "label": "Postgres service name",
                        "description": "",
                        "type": "text",
                        "default": "dynacase",
                        "required": true,
                        "value": ""
                    },
                    ...
                ]
            },
            ...
        ]
    }

### system-parameters/{sectionName}

|  Type  |  URL                                                    |  Implanté  |  Signification                                |
| ------ | ------------------------------------------------------- | ---------- | --------------------------------------------- |
| GET    | **/api/v1/system-parameters/{sectionName}**             | 0%         | Récupérer les paramètres d'une section        |
| PUT    |                                                         |            |                                               |
| POST   |                                                         |            |                                               |
| DELETE |                                                         |            |                                               |

#### GET

* Récupérer les paramètres d'une sectoin :

    GET /api/v1/system-parameters/database

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/system-paremeters/database",
            "section": "database",
            "label": "Database server",
            "description": "Database used by Dynacase context",
            "parameters": [
                {
                    "uri": "/api/v1/system-parameters/database/core_db",
                    "name": "core_db",
                    "label": "Postgres service name",
                    "description": "",
                    "type": "text",
                    "default": "dynacase",
                    "required": true
                    "value": "",
                },
                ...
            ]
        }
    }

### system-parameters/{sectionName}/{paramName}

|  Type  |  URL                                                    |  Implanté  |  Signification                                |
| ------ | ------------------------------------------------------- | ---------- | --------------------------------------------- |
| GET    | **/api/v1/system-parameters/{sectionName}/{paramName}** | 100%       | Récupérer un paramètre système avec sa valeur |
| PUT    | **/api/v1/system-parameters/{sectionName}/{paramName}** | 100%       | Ecrire la valeur d'un paramètre système       |
| POST   |                                                         |            |                                               |
| DELETE |                                                         |            |                                               |

#### GET

* Récupérer la définition d'un paramètre système avec sa valeur :

    GET /api/v1/system-parameters/database/core_db

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/system-parameters/database/core_db",
            "name": "core_db",
            "label": "Postgres service name",
            "description": "",
            "type": "text",
            "default": "dynacase",
            "required": true,
            "value": ""
        }
    }

Propriétés :

* `type`: le type de l'attribut.
  * `text`: texte brut.
  * `url`: un texte suivant la forme d'une URL (e.g.
    `<scheme>://<hostname>/<pathname>?<query>`).
  * `enum(<choice1>|...|<choiceN>)`: une liste de choix possibles séparés par
    un pipe (`|`).
  * `integer`: un entier.
  * `password`: un mot de passe.
  * autres types à définir au fur et à mesure des besoins...
* `required`: une valeur est requise. Le client doit obliger l'utilisateur à
  entrer et sauvegarder une valeur non-vide.
* `default`: valeur par défaut que le client peut proposer à l'utilisateur.
* `visibility`: si la propriété est présent et que sa valeur est vaut `expert`,
  alors cela indique que ce paramètre est du niveau Expert et peut être masqué
  par défaut et affiché si l'utilisateur indique qu'il souhaite voir aussi les
  paramètres de niveau Expert.

Notes :
* Si un paramètre est `required`, alors une valeur non-vide doit être fournie.
* La valeur `default` proposée par le serveur peut être utilisée par le client
  comme valeur à sauvegarder si l'utilisateur ne rentre pas de valeur.

#### PUT

* Ecrire la valeur d'un paramètre système :

    PUT /api/v1/system-parameters/database/core_db
    {
        "value": "foo"
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/system-parameters/database/core_db",
            "name": "core_db",
            "label": "Postgres service name",
            "description": "",
            "type": "text",
            "default": "dynacase",
            "required": true,
            "value": "foo"
        }
    }

### repositories/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/repositories/**                                            | 100%           | Liste des dépôts de paquets configurés sur dynacase-control          |
| PUT    |                                                                      |                | -                                                                    |
| POST   | **/api/v1/repositories/**                                            | 100%           | Ajouter un nouveau dépôt de paquets                                  |
| DELETE |                                                                      |                | -                                                                    |

#### GET

* Lister les dépôts :

    GET /api/v1/repositories/

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": [
            {
                "uri": "/api/v1/repositories/foo",
                "id": "foo",
                "description": "ACME Corp. repository",
                "url": "http://repo.example.net/foo/webinst",
                "authenticated": "yes",
                "login": "john.doe",
                "default": true,
                "enabled": true
            },
            ...
        ]
    }

#### POST

* Ajouter un nouveau dépôt :

    POST /api/v1/repositories/
    {
        "id": "local",
        "description": "Local repo",
        "enabled": false,
        ...
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/repositories/local,
            "id": "local",
            "description": "Local repo",
            "enabled": false,
            ...
        }
    }

### repositories/{repoId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/repositories/{repoId}**                                    | 100%           | Paramètres du dépôt de paquets                                       |
| PUT    | **/api/v1/repositories/{repoId}**                                    | 100%           | Modifier les paramètres du dépôt                                     |
| POST   |                                                                      |                | -                                                                    |
| DELETE | **/api/v1/repositories/{repoId}**                                    | 100%           | Supprimer le dépôt de paquets                                        |

#### GET

* Requête consultation dépôt :

    GET /api/v1/repositories/foo

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data: {
            "uri": "/api/v1/repositories/foo",
            "id": "foo",
            "enabled": true,
            ...
        }
    }

#### PUT

* Requête modification dépôt :

    PUT /api/v1/repositories/foo
    {
        "description": "ACME Corp. repository",
        "enabled": false
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/repositories/foo",
            "id": "foo",
            "description": "ACME Corp. repository",
            "enabled": false,
            ...
        }
    }

#### DELETE

* Requête suppression dépôt :

    DELETE /api/v1/repositories/foo

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true
    }

### modules/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/modules/**                                                 | 100%           | Liste des modules installés/disponibles/upgradables sur le contexte  |
| PUT    |                                                                      | 100%           | Installer ou mettre à jour un module                                 |
| POST   |                                                                      | 100%           | Uploader un module et l'installer/upgrader dans le contexte          |
| DELETE |                                                                      |                | -                                                                    |

#### GET

* Lister tous les modules installés dans le contexte :

    GET /api/v1/modules/?status=installed

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": [
            {
                "id": "dynacase-core",
                "version": "3.2.18",
                "release": "0.20141127.174457",
                "status": "installed",
                ...
            },
            ...
        ]
    }

* Lister tous les modules disponibles :

    GET /api/v1/modules/?status=available

Liste tous tous les modules des dépôt marqués {`enabled`: true} en ne prenant
que la dernière version des modules s'il y des doublons.

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": [
            {
                "id": "foo",
                "version: "1.0.0",
                "release": "1",
                ...
            }
        ]
    }

* Lister les modules installés ayant une mise à jour de disponible :

    GET /api/v1/modules/?status=upgradable

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": [
            {
                "id": "dynacase-core",
                "version": "3.2.23",
                "release": "0",
                ...
            }
        ]
    }

* Liste « synthétique » des modules :

    GET /api/v1/modules/

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": [
            {
                "id": "dynacase-core",
                "version": "3.2.23",
                "release": "0",
                "status": "installed",
                "update": {
                    "name": "dynacase-core",
                    "version": "3.2.24",
                    "release": "1"
                }
            },
            ...
            {
                "id": "foo",
                "version": "1.0.0",
                "release": "0",
                "status": "installed",
                "update": null
            },
            ...
            {
                "id": "bar",
                "version": "1.0.0",
                "release": "1",
                "status": "available",
                "update": null
            }
        ]
    }

La liste contient dans l'ordre suivant :

- les modules installés ayant une mise à jour ordonnés par le nom ;
- les modules installés n'ayant pas de mise à jour ordonnés par le nom ;
- les modules disponibles non-installés ordonnés par le nom.

#### PUT

* Installer ou mettre à jour des modules :

    PUT /api/v1/modules/
    {
        "install": [
            "dynacase-core",
            "foo",
            "bar"
        ]
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "transaction": "/api/v1/transactions/123"
        }
    }

L'URL de la transaction est retournée.

Réponse en cas d'erreur (dépendances incorrectes, etc.) :

    HTTP/1.1 400 Error
    {
        "success": false,
        "error": "Module 'baz' required by module 'bar' not found"
    }

#### POST

* Uploader et installer un module :

    POST /api/v1/modules/
    Content-Length: xxx
    
    <raw-webinst-file-content>

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "transaction": "/api/v1/transactions/123"
        }
    }

### transactions/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/transactions/*                                              |                | Liste des transactions globale en cours                              |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Liste les transactions :

    GET /api/v1/transactions/

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: [
            {
                uri: "/api/v1/transactions/123",
                id: "123",
                status: "ready",
                currentOperation: ""
            }
        ]
    }

Note :
* Pour le moment, une seule transaction est gérée (transaction avec identifiant
  `0`). Normalement il ne devrait y avoir qu'une seule transaction.

### transactions/{xactId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/transactions/{xactId}**                                    |                | Obtenir les détails de la transaction globale {xactId}               |
| PUT    |                                                                      |                | -                                                                    |
| POST   | **/api/v1/transactions/{xactId}**                                    |                | Démarre la transaction                                               |
| DELETE | **/api/v1/transactions/{xactId}**                                    |                | Nettoyer ou avorter la transaction                                   |

Modèle :

* Une `Transaction` contient des `Operations`.
* La `Transaction` est traitée par un `TransactionProcessor` (processeur).

Commandes du processeur :

* `run` : exécute toutes les opérations jusq'à la fin ou jusqu'à l'occurence
  d'une erreur.

* `next` : exécute une opération et se met en erreur ou en pause (commande par défaut).

* `skip` : ignore l'opération courante et exécute l'opération suivante.

* `retry` : rejoue l'opération courante.

États du processeur :

* `initializing` : lorsque la transaction est en train d'être créé et avant
  qu'elle ne soit disponible dans l'état `ready`.

* `ready` : état initial du processeur.

* `licenses` : toutes les licences doivent être acceptées. Tant que toutes les
  licenses ne sont pas {accept: true}, on ne peut pas passer à une autre
  opération.

* `parameters` : les valeurs des paramètres des modules doivent être définies.

* `end` : fin des opérations.

* `error` : erreur rencontrée lors de l'exécution d'une opération.

* `running` : une opération est en cours d'exécution.

* `pause` : le processeur est en attente d'une commande pour continuer son
  exécution.

![Transactions states](transactions-states.png)

* Obtenir le détail d'une transaction

    GET /api/v1/transactions/123

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/transactions/123",
            "id": 123,
            "status": "ready",
            "currentOperation": 0,
            "module-licenses": [
                {
                    "module": "acme-foo",
                    "license": "ACME Public License",
                    ...
                    "accept": false
                },
                ...
            ],
            "module-parameters": [
                {
                    "module": "dynacase-core",
                    "parameters": [
                        {
                            "uri": "/api/v1/transactions/123/module-parameters/dynacase-core/core_admin_passwd",
                            "id": "core_admin_passwd",
                            "label": "Admin password,
                            "default": "anakeen",
                            "type": "text",
                            "volatile": "yes",
                            "oninstall": "W",
                            "onpugrade": "H",
                            "onedit": "H"
                        },
                        ...
                    ]
                },
                ...
            ],
            operations: [
                {
                    uri: "/api/v1/transactions/123/operations/1",
                    id: 1,
                    operationContext: {
                        type: "upgrade",
                        phase: "pre-upgrade",
                        module: "my-module"
                    status: "OK",
                    type: "task",
                    label: "Installation of 'my-module'",
                    typedData: {
                    }
                },
                ...
            ]
        }
    }

* Lance l'exécution automatique de la transaction :

    POST /api/v1/transactions/123?run

Réponse lorsque toute la transaction est terminée :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/transactions/123",
            "id": 123,
            "status": "end",
            "currentOperation": 10,
            ...
        }
    }

La transaction s'est terminée sans erreur sur la dernière opération #10.

Réponse lorsqu'une erreur est rencontrée :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/transactions/123",
            "id": 123,
            "status": "error",
            "currentOperation": 5,
            ...
        }
    }

Une erreur a été rencontrée lors de l'exécution de l'opération #5.

Réponse lorsque des paramètres sont requis :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/transactions/123",
            "id": "123",
            "status": "parameters",
            ...
        }
    }

* Lance l'exécution pas-à-pas de la transaction :

    POST /api/v1/transactions/123?next

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/transactions/123",
            "id": "123",
            "status": "parameters",
            ...
        }
    }

* Rejouer l'opération courante :

    POST /api/v1/transactions/123?retry=yes

Demande que l'opération courante soit rejouée.

Possible seulement lorsque le processeur n'est pas dans l'état "running".

* Ignorer l'opération courante :

    POST /api/v1/transactions/123?skip=yes

Demande que l'opération courante soit ignorée.

Possible seulement lorsque le processeur n'est pas dans l'état "running".

* Interrompte une opération :

    POST /api/v1/transactions/123?abort=yes

Demande l'arrêt de l'opération courante.

Possible seulement lorsque le processeur est dans l'état "running".

* Nettoyer une transaction terminée :

    DELETE /api/v1/transactions/123

Réponse si la transaction s'est naturellement terminée {"status": end} :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            ....
        }
    }

Réponse si la transaction n'est pas terminée :

    HTTP/1.1 409 Conflict
    {
        "success": false,
        "error": "The transaction is still running."
    }

### (DRAFT) transactions/{xactId}/module-parameters/{moduleId}/{paramName}

|  Type  |                                 URL                                        |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    |                                                                            |                | -                                                                    |
| PUT    | **/api/v1/transactions/{xactId}/module-parameters/{moduleId}/{paramName}** | 100%           | Définir la valeur du paramètre                                       |
| POST   |                                                                            |                | -                                                                    |
| DELETE |                                                                            |                | -                                                                    |

#### PUT

    PUT /api/v1/transactions/123/module-parameters/dynacase-core/core_admin_passwd
    {
        "value": "secret"
    }

### (DRAFT) transactions/{xactId}/module-licenses/{moduleId}

|  Type  |                                 URL                                        |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    |                                                                            |                | -                                                                    |
| PUT    | **/api/v1/transactions/{xactId}/module-licenses/{moduleId}**               | 100%           | Définir la valeur du paramètre                                       |
| POST   |                                                                            |                | -                                                                    |
| DELETE |                                                                            |                | -                                                                    |

#### PUT

    PUT /api/v1/transactions/123/module-licenses/dynacase-core
    {
        "accept": true
    }

### transactions/{xactId}/operations/{opId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/transactions/{xactId}/operations/{opId}**                  | 100%           | Récupérer le détail d'une opération                                  |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Récupérer les infos de l'opération :

    GET /api/v1/transactions/123/operations/8

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../8",
            id: 8,
            type: "task",
            status: ""
            label: "Registering application MY_APP"
            typedData: {
            }
        }
    }

Réponse si l'opération est en cours d'exécution :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../8",
            id: 8,
            type: "task",
            status: "running",
            label: "Registering application MY_APP"
            output: "...",
            progress: "1272/19473"
            typedData: {
            }
        }
    }

### archives/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/archives/**                                                | 100%           | Récupérer la liste des archives                                      |
| PUT    | **/api/v1/archives/**                                                | 100%           | Lancer la création d'une archive du contexte                         |
| POST   | **/api/v1/archives/**                                                | 100%           | Téléverser le fichier d'une archive                                  |
| DELETE |                                                                      |                |                                                                      |

* Récupérer la liste des archives :

    GET /api/v1/archives/

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: [
            {
                uri: ".../<archiveId>",
                id: <archiveId>,
                ...
            },
            ...
        ]
    }

* Lancer la création d'une archive :

    PUT /api/v1/archives/
    {
        "name": "<archiveName>",
        "description": "<archiveDescription>",
        "excludeVault": true|false
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../api/v1/transactions/<txId>",
            id: <txId>,
            ...
        }
    }

La demande de création d'une archive retourne une transaction.

* Téléverser une archive :

    POST /api/v1/archives/
    &lt;archiveRawData&gt;

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../<archiveId>",
            id: <archiveId>,
            ...
        }
    }

### archives/{archiveId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/archives/{archiveId}**                                     | 100%           | Récupérer le détail d'une archive                                    |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE | **/api/v1/archives/{archiveId}**                                     | 100%           | Supprimer une archive                                                |

* Récupérer le détail d'une archive :

    GET /api/v1/archives/<archiveId>

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../<archiveId>",
            id: <archiveId>,
            ...
        }
    }

* Télécharger une archive :

    GET /api/v1/archives/<archiveId>?download=yes

Résponse :

    HTTP/1.1 200 OK
    <archiveRawData>

* Supprimer une archive :

    DELETE /api/v1/archives/<archiveId>

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../<archiveId>",
            id: <archiveId>,
            ...
        }
    }

<!--links-->


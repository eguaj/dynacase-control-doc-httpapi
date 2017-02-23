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
                        "value": "dynacase"
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
                    "value": "dynacase"
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
            "value": "dynacase"
        }
    }

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

### context

|  Type  |                                 URL                                |    Implanté    |                            Signification                             |
| ------ | ------------------------------------------------------------------ | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/context**                                                | 100%           | Informations du contexte s'il existe                                 |
| PUT    | **/api/v1/context**                                                | 0%             | Modifier les propriétés du contexte                                  |
| POST   | **/api/v1/context**                                                | 0%             | Créer un contexte                                                    |
| DELETE | **/api/v1/context**                                                | 0%             | Supprimer le contexte                                                |

#### GET

* Propriétés du contexte :

    GET /api/v1/context

Réponse lorsqu'un contexte n'a pas encore été créé :

    HTTP/1.1 404 Not found
    {
        "success": false
    }

Réponse lorsqu'un contexte existe ;

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/context",
            "id": "production",
            "root": "/var/www/production",
            "url": "https://prod.example.net/"
        }
    }

#### PUT

* Modifier les propriétés du contexte :

    PUT /api/v1/context
    {
        "description": "ACME Corp. production site",
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/context",
            "id": "production",
            "root": "/var/www/production",
            "description": "ACME Corp. production site"
            "url": "http://prod.example.net"
        }
    }

#### POST

* Créer un contexte :

    POST /api/v1/context
    {
        "id": "production",
        "root": "/var/www/production"
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "uri": "/api/v1/context",
            "id": "production",
            "root": "/var/www/production"
        }
    }

Réponse si un context existe déjà :

    HTTP/1.1 409 Conflict

#### DELETE

* Supprimer le contexte :

    DELETE /api/v1/context

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
    }

### (DRAFT) modules/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/modules/**                                                 | 100%           | Liste des modules installés/disponibles/upgradables sur le contexte  |
| PUT    |                                                                      | 20%            | Installer ou mettre à jour un module                                 |
| POST   |                                                                      | 0%             | Uploader un module et l'installer/upgrader dans le contexte          |
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
            "transaction": "/api/v1/transactions/123",
            "summary": [
                {
                    "name": "dynacase-core",
                    ...
                    "operation": "install"
                },
                {
                    "name": "foo",
                    ...
                    "operation": "upgrade"
                },
                {
                    "name": "bar",
                    ...
                    "operation": "replaced",
                    "replacedBy": "bar-new"
                },
                {
                    "name": "bar-new",
                    ...,
                    "operation": "install"
                }
            ],
        }
    }

Le résumé de ce qui sera fait est retourné dans "summary".

- Si le client décide de poursuivre, alors il exécute la transaction planifiée.
- Sinon, il supprime la transaction planifiée.

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

### (DRAFT) transactions/

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

Normalent il ne devrait y avoir qu'une seule transaction.

### (DRAFT) transactions/{xactId}

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

* `next` : exécute une opération et se met en erreur ou en pause.

* `skip` : ignore l'opération courante et exécute l'opération suivante.

* `retry` : rejoue l'opération courante.

* `abort` : interrompt l'opération courante.

États du processeur :

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



    "ready" --> "licenses" -> "parameters" --> "end"
                                           --> "error"
                                           --> "running"
                                           --> "pause"
            --> "running" --> "end"
                          --> "error"
                          --> "pause"
            --> "error" --> "running"
            --> "pause" --> "running"
            --> "end"



Type d'opérations :

`h1`..`h6`
:   Élément de présentation représentant une section, un commentaire,
    une information pour délimiter les opérations, etc.

    "h1": {
        "label": "Label de la section"
    }

`task`
:   Élément représentant une tâche a exécuter.

    "task": {
        "label": "Label de description de l'opération"
    }    



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
                    status: "OK",
                    type: "h1",
                    h1: {
                        label: "Installation of 'my-module'",
                    }
                },
                {
                    uri: ".../2",
                    id: 2,
                    status: "OK",
                    type: "h2",
                    h2: {
                        label: "Runnig pre-install...",
                    }
                },
                {
                    uri: ".../3",
                    id: 3,
                    status: "running",
                    type: "task",
                    task: {
                        label: "Checking for Foo",
                    }
                },
                {
                    uri: ".../4",
                    id: 4,
                    status: "",
                    type: "task",
                    task: {
                        label: "Checking for Bar",
                        optional: true,
                    }
                },
                {
                    uri: ".../5",
                    id: 5,
                    status: "",
                    type: "h2",
                    h2: {
                        label: "Extracting files...",
                    }
                },
                {
                    uri: ".../6",
                    id: 6,
                    status: "",
                    type: "task",
                    task: {
                        label: "Extracting files",
                    }
                },
                {
                    uri: ".../7",
                    id: 7,
                    status: "",
                    type: "h2",
                    h2: {
                        label: "Running post-install...",
                    }
                },
                {
                    uri: ".../8",
                    id: 8,
                    status: "",
                    type: "task",
                    task: {
                        label: "Registering application MY_APP",
                    }
                }
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
            "currentOperation": 0,
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
            "currentOperation": 0,
            ...
        }
    }

* Rejouer l'opération courante :

    POST /api/v1/transactions/123
    {
        "retry": 5
    }

Demande que l'opération courante #5 soit rejouée.

Possible seulement lorsque le processeur n'est pas dans l'état "running".

* Ignorer l'opération courante :

    POST /api/v1/transactions/123
    {
        "skip": 5
    }

Demande que l'opération courante #5 soit ignorée.

Possible seulement lorsque le processeur n'est pas dans l'état "running".

* Interrompte une opération :

    POST /api/v1/transactions/123
    {
        "abort": 5
    }

Demande l'arrêt de l'opération courante #5.

Possible seulement lorsque le processeur est dans l'état "running".

* Nettoyer une transaction terminée :

    DELETE /api/v1/transactions/123

Réponse si la transaction s'est naturellement terminée {"status": end} :

    HTTP/1.1 200 OK
    {
        "success": true
    }

Réponse si la transaction n'est pas terminée :

    HTTP/1.1 409 Conflict
    {
        "success": false,
        "error": "The transaction is still running."
    }

* Avorter une transaction non-terminée :

    DELETE /api/v1/transaction/123
    {
        "abort": true
    }

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            ...
        }
    }

Tuer les opérations qui tournent et supprimer la transaction.

### (DRAFT) transactions/{xactId}/module-parameters/{moduleId}/{paramName}

|  Type  |                                 URL                                        |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    |                                                                            |                | -                                                                    |
| PUT    | **/api/v1/transactions/{xactId}/module-parameters/{moduleId}/{paramName}** |                | Définir la valeur du paramètre                                       |
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
| PUT    | **/api/v1/transactions/{xactId}/module-licenses/{moduleId}**               |                | Définir la valeur du paramètre                                       |
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
| GET    | **/api/v1/transactions/{xactId}/operations/{opId}**                  |                | Récupérer le détail d'une opération                                  |
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
            task: {
                label: "Registering application MY_APP"
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
            task: {
                label: "Registering application MY_APP"
                output: "...",
                progress: "1272/19473"
            }
        }
    }

* Exécuter l'opération en synchrone :

    POST /api/v1/transactions/123/operations/8

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../8",
            id: 8,
            type: "task",
            status: "OK",
            next: ".../9"
            task: {
                label: "Registering application MY_APP",
                output: "...",
                progress: "100%"
            }
        }
    }

Réponse si fin de transaction :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../8",
            id: 8,
            type: "task",
            label: "Registering application MY_APP"
            status: "OK",
            next: "end"
        }
    }

Quand `next` vaut `end`, alors le `status` de la transasction passe à `end` et
`currentOperation` de la transaction passent à vide.

Le client doit alors supprimer la transaction avec `DELETE`.

Réponse si erreur :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../8",
            id: 8,
            type: "task",
            label: "Registering application MY_APP"
            status: "KO",
            output: "Erreur: ..."
        }
    }

Réponse si opération déjà en cours d'exécution :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Operation 9 is already running."
    }

* Exécuter l'opération en asynchrone :

    POST /api/v1/transactions/123/operations/8?async

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../8",
            id: 8,
            type: "task",
            label: "Registering application MY_APP"
            status: "running",
            output: "",
            progress: ""
        }
    }

* Arrêter une opération qui tourne

    DELETE /api/v1/transactions/123/operations/8

Réponse :

    HTTP/1.1 200 OK
    {
        success: true
    }

Réponse si l'opération ne tourne pas :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Operation 8 is not runnning."
    }

* Skipper une opération qui est en échec :

    POST /api/v1/transactions/123/operations/8?skip

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: ".../8",
            id: 8,
            type: "task",
            label: "Registering application MY_APP"
            status: "KO",
            output: "Error: ...",
            next: ".../9"
        }
    }

Réponse si l'opération n'est pas en échec ou tourne encore :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Operation 8 is runnning."
    }

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Operation 8 is not in failed state."
    }





















































Légende :

* Les URL en *italique* font références à des collections,
* Les URL en **gras** font références à des ressources,

<span class="flag inline nota-bene"></span> Les entrées documents de famillies et de trash possède aussi les sous-collections :

* history,
* revisions.

<span class="flag inline nota-bene"></span> Les entrées en Future version sont prévues pour une implémentation future 
mais non présentes dans la version courante de l'API.

## Brouillon

### Collections

    dynacase-control/
        parameters/
        repositories/
        contexts/
            properties/
            repositories/
            modules/
                parameters/
        archives/
        logs/

### Index dépôts de paquets



### Modélisation système de "Transaction" pour l'install/upgrade de modules

Graphe orienté

Lors de la demande d'installation - ou de mise à jour - d'un module dans un
contexte, le serveur calcule et stocke le "graphe" des opérations dans ce que
l'on nommera la Transaction.

Exemple de Transaction pour l'installation de dynacase-core :

    01 wstop (task)
    02 install dyncase-core (h1)
    03     license (h2)
    04         ask license (prompt)
    05     parameters (h2)
    06         ask core_db (prompt)
    07         ask ... (prompt)
    08     pre-install (h2)
    09         check aaa (task)
    10         check ...
    11     unpack (task)
    12     post-install (h2)
    13         process aaa (task)
    14         process ...
    15         process zzz
    16 install dynacase-foo
    17     license ask license
    18     parameters
    19         ask foo
    20         ask ...
    21     unpack
    22 wstart

Chaque nœud du graphe est typé :

* "h1"..."h6" : Titre à présenter à l'utilisateur (presentational elements).
* "task" : Tâche qui sera exécutée sur le serveur (executable element).
* "prompt" : Présentation d'un message à l'utilisateur et demande de réponse
  (inquisitive elements).

Le graphe doit être "déroulé" par le client depuis le début et ne peut aller
que de l'avant. Lorsqu'un nœud du "graphe" est en erreur, il peut rejouer le
nœud mais il ne peut pas revenir en arrière (jouer/rejouer un nœud précédent)

Le graphe stocke le nœud courant : le nœud sur lequel le client doit agir.

Le client interprête donc le graphe pour le présenter à l'utilisateur et
demander au serveur l'exécution de chaques nœud.

Le client peut intérroger à tout moment le "status" de chaque nœuds. Cela
permet au client de pouvoir ré-afficher à l'utilisateur les nœuds qui ont déjà
été exécutés.

Le client peut récupérer le graphe complet afin de pouvoir présenter à
l'utilisateur l'ensemble des opérations, ou ce qui a déjà été utilisé, ou ce
qui est à venir.



Qu'elle est l'API la plus simple pour contrôler/dérouler ce "graphe" ?



A partir de ce moment là, dynacase-control est "bloqué" sur cette Transaction :
on ne peut plus faire aucune opération sur dynacase-control autre que de jouer
ou annuler la Transaction.

Le client peut se déconnecter et laisser le contexte en l'état.

Lors de la reconnexion du client, si celui-ci veut manipuler le contexte, le
serveur lui indiquera qu'une Transaction est en cours. Si la Transaction n'a
pas été demarrée, alors le client peut l'annuler ou la démarrer. Si la
Transaction a été demarrée, alors le client peut l'annuler ou la continuer.

Lorsque la Transaction est annulée, le serveur "débloque" le contexte et le
laisse en l'état.

Une fois la transaction démarrée, le client va demander l'exécution de
l'opération suivante jusqu'à ce que toutes les opérations aient été exécutés.

Le serveur exécute les opérationn pas-à-pas sous la direction du client ? Ou
bien il exécute toutes les opérations qui sont en OK et s'arrête sur un KO ou
un prompt ?

Le serveur exécute l'opération courante, et les opérations suivantes tant que
le status de l'opération est OK ou que l'opération ne nécessite pas de données
de la part de l'utilisateur.

Ce mécanisme de Transaction est aussi utilisé lors de la suppression d'un
contexte (pour dérouler les opérations de pre-delete).

* Interroge si des transactions sont en cours :

    > GET /transactions
    < [123]

Deux modes d'exécution : 

* pas-à-pas : chaque opération est exécuté explicitement.
* automatique : les opérations sont exécutés dans l'ordre jusqu'à ce qu'une
  opération soit en erreur ou qu'elle demande une interaction avec le client.

Status des opérations :

* `OK` : l'opération a correctement été réalisée. Passer à l'opération
  suivante.
* `KO` (avec optional="yes|no") : l'opération a rencontré une erreur. Demander s'il faut ré-essayer
  l'opération ou passer à la suivante.

Exécution opération :

   Receive request
   If process already running Then
      Check for stalled process
      Send response with status="running"
   EndIf
   If async Then
      Send response with status="running"
      Detach from client connection
   EndIf
   Run process synchronously
   Store process execution status
   If sync Then
      Send response with status="OK|KO"
   EndIf
   Exit

Intérogation opération :

   Receive request
   If process already running Then
   Else
      
   EndIf


#### Transaction


Exemple de transaction :

    GET /api/v1/transactions/123

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/transactions/123",
            id: 123,
            status: "ready",
            currentOperation: "",
            operations: [
                {
                    uri: "/api/v1/transactions/123/operations/1",
                    id: 1,
                    status: "",
                    h1: {
                        label: "Installation of 'my-module'"
                    }
                },
                {
                    uri: ".../2",
                    id: 2,
                    status: "",
                    license: {
                        legalese: "xxx"
                    }
                },
                {
                    uri: ".../3",
                    id: 3,
                    status: "",
                    prompt: {
                        label: "Database postgresql service name",
                        type: "text",
                        values: "",
                        default: "pre-production"
                    }
                },

                {
                    uri: ".../4",
                    id: 4,
                    status: "",
                    h2: {
                        label: "Runnig pre-install..."
                    }
                },
                {
                    uri: ".../5",
                    id: 5,
                    status: "",
                    task: {
                        label: "Checking for Foo",
                    }
                },
                {
                    uri: ".../6",
                    id: 6,
                    status: "",
                    task: {
                        label: "Checking for Bar",
                        optional: true
                    }
                },
                {
                    uri: ".../7",
                    id: 7,
                    status: "",
                    h2: {
                        label: "Extracting files..."
                    }
                },
                {
                    uri: ".../8",
                    id: 8,
                    status: "",
                    task: {
                        label: "Extracting files",
                    }
                },
                {
                    uri: ".../9",
                    id: 9,
                    status: "",
                    h2: {
                        label: "Running post-install..."
                    }
                },
                {
                    uri: ".../10",
                    id: 10,
                    status: "",
                    task: {
                        label: "Registering application MY_APP"
                    }
                }
            }
        }
    }

#### Mode pas-à-pas (synchrone)

* On démarre la transaction (`currentOperation` passe à 1) et on retourne
  l'opération courante (#1)
* On exécute l'opération courante (#1)
* Si l'opération est "OK" alors `currentOperation` passe à 2 et on retourne
  l'opération exécutée (#1) avec une propriété `next` qui contient l'URI de
  l'opération suivante
* Si l'opération est "KO" alors on retourne l'opération courante (#1)

#### Mode automatique (asynchrone)

* On démarre la transaction (`currentOperation` passe à 1) et on retourne
  l'opération courante (#1) en `status: running`

### Exécution operations

Exécution des nœuds de type `task`.

Les nœuds de type `task` sont un process qui est exécuté par dynacase-control.

STDERR est redirigé dans STDOUT, et STDOUT est stocké dans un fichier.

La transaction stocke le pid et le fichier de sortie du process.

Le contenu du fichier de sortie n'est pas remonté par défaut lors de
l'interrogation de l'opération : il faut explicitement le demander.

On peut définir un protocole pour voir l'avancement de la tâche : le process
émet sur STDOUT un message dans un format particulier qui permet de suivre
l'avancement.

L'avancement est envoyé sur STDOUT ? ou un fichier spécifique ?

    [php]
    
    if (getenv('PROGRESS_FILE') !== false) {
        progressFile = getenv('PROGRESS_FILE');
    } else {
        progressFile = 'php://stdout';
    }
    file_put_contents($progressFile, sprintf('PROGRESS-API:VERSION=1'.PHP_EOL, $percent), FILE_APPEND|LOCK_EX);
    ...
    file_put_contents($progressFile, sprintf('PROGRESS:%d%%'.PHP_EOL, $percent), FILE_APPEND|LOCK_EX);

On peut aussi imaginer un mécanique similaire a cette Progress API pour que la
tâche puisse communiquer des messages d'avertissement :

    [php]
    if (getenv('PROGRESS_FILE') !== false) {
        warningFile = getenv('PROGRESS_FILE');
    } else {
        warningFile = 'php://stdout';
    }
    file_put_contents($warningFile, sprintf('WARNING:%s'.PHP_EOL, $warn), FILE_APPEND|LOCK_EX);

#### Progress API

Les process exécutés peuvent fournir leur avancement en envoyant un message
dans leur flux de sortie STDOUT (ou dans un fichier spécifique).

Progression (unsigned int)n/(unsigned int)total :

    ^PROGRESS:\d+/\d+$

Progression pourcentage (unsigned int)n% :

    ^PROGRESS:\d+%$

Progression "throbber" (compteur (unsigned int)n qui s'incrémente et wrappe) :

    ^PROGRESS:\d+$

Le client peut demander toute la sortie de la tâche :

    > GET /transactions/123/operation/26?output
    < {"id": 26, "status": "running", "label": "Record core application in database", "output": "..."}

Ou bien seulement l'avancement (on retourne le dernier message d'avancement) :

    > GET /transactions/123/operation/26?progress
    < {"id": 26, "status": "running", "label": "Record core application in database", "progress:" "12/357"}
    
    ou
    
    > GET /transactions/123/operation/26?progress
    < {"id": 26, "status": "running", "label": "Record core application in database", "progress:" "54%"}

Ou bien on retourne systématiquement le dernier progress, lors de
l'interrogation de l'operation, si le fichier de log contient des lignes de
progress ?

On peut aussi imaginer une API "Progress" fournit par dynacase-core 

    $progress = new Progress();
    $progress->setPercent(10);

Avec la classe `Progress` qui peut détecter si elle s'exécute dans Dynacase Control ou en autonome ?

* quand exec hors dynacase-control alors le message de progress est inhibé (ou
  formatté autrement)
* quand exec dans dynacase-control alors le message es émis au format PROGRESS
  ou dans une fichier distinct.




<!--links-->


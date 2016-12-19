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

Dans les réponse ci-dessous, la réponse ne présente que le contenu de la
propriété `data` : les autres propriétés du message ne sont pas présentés.

## Algorithme interprétation des réponses HTTP par le client REST

    SI HTTP status == 2xx ALORS
        SI .warning existe ET est non vide ALORS
            .warning contient les messages éventuels de warning
        FINSI
    SINON
        SI .success est false ALORS
            .error contient le message d'erreur
            Interpréter la réponse comme une erreur de l'application
        SINON
            Interpréter la réponse comme une erreur HTTP
                et gérer comme le ferait un client Web.
        FINSI
    FINSI

## Authentification

Cas (1) : on garde le fonctionnement actuel qui est que toute requête doit être
authentifiée par HTTP Basic.

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
| GET    | **/api/v1/setup**                                                    |                | Version de dynacase-control et version de mise à jour disponible     |
| PUT    |                                                                      |                | -                                                                    |
| POST   | **/api/v1/setup**                                                    |                | Mettre à jour dynacase-control si mise à jour disponible             |
| DELETE |                                                                      |                | -                                                                    |

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
| GET    | **/api/v1/auth**                                                     |                | Gérer le mot de passe de connexion à dynacase-control                |
| PUT    | **/api/v1/auth**                                                     |                | Modifier le mot de passe de connexion                                |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Status authentification :

Peut servir à savoir si le mot de passe est correct ou si on est conneecté à
dynacase-control.

    GET /api/v1/auth

Réponse si pas authentifié :

    HTTP/1.1 401 Authentication required

Réponse si authentifié :

    HTTP/1.1 200 OK
    {
        success: true
    }

* Modifier le mot de passe de connexion :

    PUT /api/v1/auth
    {
        password: "50Me s3cr3t p4s5W0rD"
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true
    }

### system-parameters/

|  Type  |              URL               |  Implanté  |  Signification                               |
| ------ | ------------------------------ | ---------- | -------------------------------------------- |
| GET    | **/api/v1/system-parameters/** |            | Liste des sections et des paramètres système |
| PUT    |                                |            |                                              |
| POST   |                                |            |                                              |
| DELETE |                                |            |                                              |

* Lister les sections et les paramètres système :

    GET /api/v1/system-parameters/

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": [
            {
                "section": "database",
                "label": "Database server",
                "description": "Database used by Dynacase context",
                "parameters": [
                    {
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

### system-parameters/{sectionName}/{paramName}

|  Type  |  URL                                                    |  Implanté  |  Signification                                |
| ------ | ------------------------------------------------------- | ---------- | --------------------------------------------- |
| GET    | **/api/v1/system-parameters/{sectionName}/{paramName}** |            | Récupérer un paramètre système avec sa valeur |
| PUT    | **/api/v1/system-parameters/{sectionName}/{paramName}** |            | Ecrire la valeur d'un paramètre système       |
| POST   |                                                         |            |                                               |
| DELETE |                                                         |            |                                               |

* Récupérer la définition d'un paramètre système avec sa valeur :

    GET /api/v1/system-parameters/database/core_db

Réponse :

    HTTP/1.1 200 OK
    {
        "success": true,
        "data": {
            "name": "core_db",
            "label": "Postgres service name",
            "description": "",
            "type": "text",
            "value": "dynacase"
        }
    }

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
            "name": "core_db",
            "label": "Postgres service name",
            "description": "",
            "type": "text",
            "value": "foo"
        }
    }

### parameters/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/parameters/**                                              |                | Liste des paramètres globaux de dynacase-control                     |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Lister les paramètres de dynacase-control :

    GET /api/v1/parameters/

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: [
            {
                uri: "/api/v1/parameters/proxy-host",
                id: "proxy-host",
                value: "http://localhost:3128"
            },
            ...
        ]
    }

### parameters/{paramId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/parameters/{paramId}**                                     |                | Récupérer la valeur d'un paramètre de dynacase-control               |
| PUT    |                                                                      |                | Modifier la valeur d'un paramètre de dynacase-control                |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Lire la valeur d'un paramètre :

    GET /api/v1/parameters/proxy-host

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/parameters/proxy-host",
            id: "proxy-host",
            value: "http://localhost:3128"
        }
    }

* Modifier la valeur d'un paramète :

    PUT /api/v1/parameters/proxy-host
    {
        value: "http://proxy.example.net:3128"
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/parameters/proxy-host",
            id: "proxy-host",
            value: ""http://proxy.example.net:3128"
        }
    }

### (OLD) eec

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/eec**                                                      |                | Voir le status de registration EEC                                   |
| PUT    |                                                                      |                | Modifier la valeur de la registration EEC                            |
| POST   |                                                                      |                | Soumettre les infos des tous les contextes "registered: true"        |
| DELETE |                                                                      |                | -                                                                    |

* Voir si compte EEC configuré :

    GET /api/v1/eec

Réponse si non enregistré :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            login: "",
            registered: false
        }
    }

Réponse si enregistré :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            login: "acmecorp",
            registered: true
        }
    }

* S'enregistrer :

    PUT /api/v1/eec
    {
        login: "acmecorp",
        password: "s3cr3t"
    }

Réponse si l'enregistrement auprès de EEC à réussi :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            login: "acmecorp",
            registered: true
        }
    }

Réponse si l'enregistrement auprès de EEC à échoué :

    HTTP/1.1 500 Error
    {
        success: false,
        error: "Registration with login 'acmecorp' failed: xxx"
    }

* Envoyer les informations de tous les contextes déclarés pour enregistrement :

    POST /api/v1/eec

Réponse:

    HTTP/1.1 200 OK
    {
        success: true
    }

Réponse si control pas enregistré :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Dynacase control is not registered with a EEC account. Please register first with a EEC account."
    }

Réponse si la soumission d'un contexte est en erreur :

    HTTP/1.1 200 OK
    {
        succcess: true,
        warnings: [
            "Error sending registration information for context 'foo': xxx",
            "Error sending registration information for context 'bar': xxx"
        ]
    }

### (OLD) eec/{contextId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/eec/{contextId}**                                          |                | Voir les infos qui sont soumise par EEC pour le contexte             |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Soumettre les infos EEC pour ce contexte                             |
| DELETE |                                                                      |                | -                                                                    |

* Voir les informations qui seraient soumise pour un contexte :

    GET /api/v1/eec/production

Réponse :

    HTTP/1.1 200 OK
    {
        succcess: true,
        data: {
            xml: "..."
        }
    }

Réponse :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Context 'production' is not registered for submission."
    }

* Soumettre les informations du contexte :

    POST /api/v1/eec/production

Réponse

    HTTP/1.1 200 OK
    {
        succcess: true,
        data: {
            xml: "..."
        }
    }

### (OLD) repositories/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/repositories/*                                              |                | Liste des dépôts de paquets configurés sur dynacase-control          |
| PUT    |                                                                      |                | -                                                                    |
| POST   | */api/v1/repositories/*                                              |                | Ajouter un nouveau dépôt de paquets                                  |
| DELETE |                                                                      |                | -                                                                    |

* Lister les dépôts :

    GET /api/v1/repositories/

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: [
            {
                uri: "/api/v1/repositories/foo",
                id: "foo",
                description: "ACME Corp. repository",
                url: "http://repo.example.net/foo/webinst",
                authenticated: "yes",
                login: "john.doe",
                default: true
            },
            ...
        ]
    }

* Ajouter un nouveau dépôt :

    POST /api/v1/repositories/
    {
        id: "local",
        description: "Local repo",
        protocol: "file",
        ...
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/repositories/local,
            id: "local",
            description: "Local repo",
            protocol: "file",
            ...
        }
    }

### (OLD) repositories/{repoId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/repositories/{repoId}**                                    |                | Paramètres du dépôt de paquets                                       |
| PUT    |                                                                      |                | Modifier les paramètres du dépôt                                     |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | Supprimer le dépôt de paquets                                        |

* Requête consultation dépôt :

    GET /api/v1/repositories/foo

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/repositories/foo",
            id: "foo",
            ...
        }
    }

* Requête modification dépôt :

    PUT /api/v1/repositories/foo
    {
        description: "Secure ACME Corp. repository"
        protocol: "https"
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/repositories/foo",
            id: "foo",
            description: "Secure ACME Corp. repository",
            protocol: "https",
            ...
        }
    }

* Requête suppression dépôt :

    DELETE /api/v1/repositories/foo

Réponse :

    HTTP/1.1 200 OK
    {
        success: true
    }

### (OLD) repositories/{repoId}/modules

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/repositories/{repoId}/modules**                            |                | Liste des modules du dépôt                                           |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

L'identifiant `id` du module est la valeur de la propriété `src` de l'index du
dépôt : la propriété `src` est la clef unique qui permet de référencer de
manière non ambigüe un module dans le dépôt (puisque c'est ce `src` qui est
utilisé pour télécharger le module).

* Liste des modules du dépôt :

    GET /api/v1/repositories/foo/modules

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: [
            {
                uri: "/api/v1/repositories/foo/modules/dynacase-core-3.2.0-1.webinst",
                id: "dynacase-core-3.2.0-1.webinst",
                name: "dynacase-core",
                version: "3.2.0",
                release: "1",
                ...
            },
            {
                uri: "/api/v1/repositories/foo/modules/my-module.webinst",
                id: "my-module.webinst",
                name: "my-module",
                version: "1.0.0",
                release: "42",
                ...
            },
            ...
        ]
    }

### (OLD) repositories/{repoId}/modules/{moduleSrc}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/repositories/{repoId}/modules/{moduleSrc}**                |                | Détails du paquet sur ce dépôt                                       |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Détail du module :

    GET /api/v1/repositories/foo/modules/my-module.webinst

Réponse :

    HTTP/1.1 200 OK
    {
        succcess: true,
        data: {
            uri: "/api/v1/repositories/foo/modules/my-module.webinst",
            id: "my-module.webinst",
            name: "my-module",
            version: "1.0.0",
            release: "42",
            ...
        }
    }

### context

|  Type  |                                 URL                                |    Implanté    |                            Signification                             |
| ------ | ------------------------------------------------------------------ | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/context*                                                  |                | Informations du contexte                                             |
| PUT    |                                                                    |                | -                                                                    |
| POST   | */api/v1/context*                                                  |                | Modifier des propriétés du contexte                                  |
| DELETE | */api/v1/context*                                                  |                | Supprimer le contexte                                                |

* Lister les contextes :

    GET /api/v1/context

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/context",
            id: "production",
            root: "/var/www/production",
            url: "https://prod.example.net/",
            register: "unregistered"
        }
    }

* Créer un nouveau contexte vierge :

    POST /api/v1/contexts/
    {
        context: {
            id: "pre-production",
            root: "/var/www/pre-production"
        }
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            context: {
                uri: "/api/v1/contexts/pre-production",
                id: "pre-production",
                root: "/var/www/pre-production"
            }
        }
    }

* Modifier les propriétés du contexte :

    PUT /api/v1/contexts/production
    {
        context: {
            description: "ACME Corp. production site",
            register: true
        }
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            context: {
                uri: "/api/v1/contexts/production",
                id: "production",
                root: "/var/www/production",
                description: "ACME Corp. production site"
                url: "http://prod.example.net",
                register: true
            }
        }
    }

* Supprimer un contexte :

    DELETE /api/v1/contexts/production

Réponse

    HTTP/1.1 200 OK
    {
        success: true
    }

### (OLD) context/repositoryLinks/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/contexts/{contextId}/repositoryLinks/*                      |                | Liste des dépôts actifs sur le contexte                              |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Lier un dépôt au contexte                                            |
| DELETE |                                                                      |                | -                                                                    |

* Lister les dépôts actifs sur le contexte :

    GET /api/v1/contexts/pre-production/repositoryLinks/

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            repositoryLinks: [
                {
                    uri: "/api/v1/repositories/local",
                    id: "local",
                    description: "Local repo",
                    protocol: "file",
                    ...
                },
                {
                    uri: "/api/v1/repositories/foo",
                    id: "foo",
                    description: "ACME Corp. repository",
                    protocol: "http",
                    ...
                }
            ]
        }
    }

* Lier un dépôt au contexte :

    POST /api/v1/contexts/{contextId}/repositoryLinks/
    {
        repositoryLink: {
            id: "foo"
        }
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            repository: [
                {
                    uri: "/api/v1/repositories/foo",
                    id: "foo",
                    description: "ACME Corp. repository",
                    protocol: "http",
                    ...
                },
                ...
            ]
        }
    }

### (OLD) repositoryLinks/{repoId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/repositoryLinks/{repoId}**                                 |                | Récupérer les propriétés du dépôt de paquets lié sur le contexte     |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | Dé-lier un dépôt du contexte                                         |

* Voir si le dépôt est actif pour ce contexte :

    GET /api/v1/contexts/pre-production/repositoryLinks/foo

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            repositoryLink: {
                uri: "/api/v1/repositories/foo",
                id: "foo",
                description: "ACME Corp. repository",
                protocol: "http",
                ...
            }
        }
    }

Réponse si le dépôt n'est pas lié sur le contexte :

    HTTP/1.1 404 Not found
    {
        success: false,
        error: "The repository 'foo' is not linked in context 'pre-production'."
    }

* Dé-lier un dépôt du contexte :

    DELETE /api/v1/contexts/pre-production/repositoryLinks/foo

Réponse : 

    HTTP/1.1 200 OK
    {
        success: true
    }

Réponse si le dépôt n'est pas lié sur le contexte :

    HTTP/1.1 404 Not found
    {
        success: false,
        error: "The repository 'foo' is not linked in context 'pre-production'."
    }

### (DRAFT) modules/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1//modules/*                                                  |                | Liste des modules installés/disponibles/upgradables sur le contexte  |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Uploader un module et l'installer/upgrader dans le contexte          |
| DELETE |                                                                      |                | -                                                                    |

Les modules installés ont un identifiant généré de la forme :

    [php]
    urlencode( ${moduleName} )

(`{moduleName}` est unique dans les modules installés du contexte.)

Les modules disponibles ont un identifiant généré de la forme :

    [php]
    urlencode( ${repositoryId} . "/" . ${moduleSrc} )

(`{moduleSrc}` est unique dans le dépôt `{repositoryId}`.)

Les modules installés comportent la propriété `status` avec la valeur
`installed`.

Les modules disponibles sur les dépôts portent une propriété `repository`
contenant l'identifiant du dépôt d'où ils proviennent.

* Lister tous les modules :

    GET /api/v1/modules/

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: [
            {
                uri: "/api/v1/modules/dynacase-core",
                id: "dynacase-core",
                version: "3.2.18",
                release: "0.20141127.174457",
                status: "installed",
                repository: {
                    uri: "/api/v1/repositories/dynacase"
                    id: "dynacase",
                    description: "Dynacase"
                }
                ...
                updatedBy: [
                    {
                        uri: "/api/v1/repositories/local/dynacase-core",
                        id: "dynacase-core",
                        version: "3.2.18",
                        release: "0.20150112.123456"
                    }
                ],
                replacedBy: [
                    {
                        uri: "/api/v1/repositories/foo/dynacase-foo",
                        id: "dynacase-foo",
                        version: "1.0.0",
                        release: "0",
                    }
                ]
            }
            ...
            {
                uri: "/api/v1/repositories/local/modules/my-module-1.0.0-0.webinst",
                id: "my-module"
                version: "1.0.0",
                release: "0",
                ...
                repository: {
                    uri: "/api/v1/repositories/local"
                    id: "local",
                    description: "Local development repository"
                }
            }
        ]
    }

* Rechercher la dernière version d'un module :

    GET /api/v1/contexts/pre-production/modules/
    {
       name: "dynacase-core",
       latest: true
    }

Réponse :

    HTTTP/1.1 200 OK
    {
        success: true,
        data: [
            {
                uri: "/api/v1/repositories/anakeen/modules/dynacase-core-3.2.19-1.webinst",
                id: "anakeen/dynacase-core-3.2.19-1.webinst",
                name: "dynacase-core",
                version: "3.2.19",
                release: "1",
                ...
            }
        ]
    }

Le résultat peut être un module avec un autre nom mais qui remplace le module
recherché.

* Installer le module "my-module" :

Installe un module nommé "my-module" (celui qui a la version la plus haute) :

    POST /api/v1/contexts/pre-production/modules/
    {
        install: [
            {
                name: "my-module"
            }
        ]
    }

Installer un module spécifique `{repo, nom, version, release}` :

    POST /api/v1/contexts/pre-production/modules/
    {
        install: [
            {
                id: "local/my-module-1.0.0-0.webinst"
            }
        ]
    }

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            transaction: {
                uri: "/api/v1/transactions/548bd75c-7e5d-4f8c-9f3d-cb0286a42224",
                id: "548bd75c-7e5d-4f8c-9f3d-cb0286a42224"
            }
        }
    }

* Mettre à jour "dynacase-core" :

    POST /api/v1/contexts/pre-production/modules/
    {
        install: [
            {
                name: "dynacase-core"
            }
        ]
    }

On utilise le verbe "install" pour gérer les install et les mises à jour. Comme
pour dpkg, l'upgrade ou l'install sera faite suivant que le module est installé
ou non.

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            transaction: {
                uri: "/api/v1/transactions/1608e06a-4c32-4bd1-ad90-080f05dc73fa",
                id: "1608e06a-4c32-4bd1-ad90-080f05dc73fa"
            }
        }
    }

* Uploader un paquet au format webinst (`my-module.webinst`) et l'installer :

    POST /api/v1/contexts/pre-production/modules/
    Content-Type: multipart/form-data; boundary=AaB03x
    
    --AaB03x
    Content-Disposition: form-data; name="package"; filename="my-module.webinst"
    
    ... binary content ...
    --AaB03x

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            transaction: {
                uri: "/api/v1/transactions/58cef40d-a677-40d9-9491-7713f9f78184",
                id: "58cef40d-a677-40d9-9491-7713f9f78184"
            }
        }
    }

Le système détecte automatiquement si le module contenu dans le paquet uploadé
est déjà installé et fera alors une mise à jour, sinon il fera une
installation.

* Options pour moduler l'install :

    nopre:   false|true
    nopost:  false|true
    nothing: false|true
    force:   false|true

### contexts/{contextId}/modules/{moduleName}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/contexts/{contextId}/modules/{moduleName}*                  |                | Récupérer les infos du module installé                               |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Infos :

    GET /api/v1/contexts/pre-production/modules/my-module

Résponse :

    HTTP/1.1 200 OK
    {
        success: true,

        data: {
            uri: "/api/v1/contexts/pre-production/modules/my-module",
            id: "my-module"
            name: "my-module",
            version: "1.0.0",
            release: "0",
            name: "my-module",
            version: "1.0.0",
            release: "0",
            ...,
            repository: {
                id: "local",
                uri: "/api/v1/repositories/local"
            }
        }
    }

### contexts/{contextId}/modules/{moduleName}/parameters/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/contexts/{contextId}/modules/{moduleName}/parameters/*      |                | Liste des paramètres du module installé                              |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Lister les paramètre d'un module installé :

    GET /api/v1/contexts/production/modules/dynacase-core/parameters/

Réponse :

    HTTP/1.1 200 OK
    {
        parameters: [
            {
                uri: "/api/v1/contexts/production/modules/dynacase-core/core_db",
                id: "core_db",
                value: "pg-production"
            },
            ...
        ]
    }

### contexts/{contextId}/modules/{moduleName}/parameters/{paramId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/contexts/{contextId}/modules/{moduleName}/parameters/{paramId}** |          | Valeur du paramètre du module installé                               |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Modifier la valeur du paramètre du module installé                   |
| DELETE |                                                                      |                | -                                                                    |

* Get :

    GET /api/v1/contexts/production/modules/dynacase-core/core_db


Réponse :

    HTTP/1.1 200 OK
    {
        parameter: {
            uri: "/api/v1/contexts/production/modules/dynacse-core/core_db",
            id: "core_db",
            value: "pg-production"
        }
    }

* Modify :

    PUT /api/v1/contexts/production/modules/dynacase-core/core_db
    {
        value: "pg-production-bis"
    }

Réponse :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "Parameter 'core_db' can't be changed."
    }

Actuellement, les paramètres ne sont pas modifiables.

### archives/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/archives*                                                   |                | Liste des archives                                                   |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Uploader un fichier d'archive OU archiver un contexte existant       |
| DELETE |                                                                      |                | -                                                                    |

* Liste des archives :

    GET /api/v1/archives/

Réponse :

    HTTP/1.1 200 OK
    {
        archives: [
            {
                uri: "/api/v1/archives/test-833cc0ab-75f2-42c8-a39f-86a78875d2e9",
                id: "test-833cc0ab-75f2-42c8-a39f-86a78875d2e9",
                name: "test"
            },
            ...
        ]
    }

* Uploader une archive :

    POST /api/v1/archives/
    Content-Type: multipart/form-data; boundary=AaB03x
    
    --AaB03x
    Content-Disposition: form-data; name="archive"; filename="xxx.fcz"
    
    ... binary content ...
    --AaB03x

Réponse :

    HTTP/1.1 200 OK
    {
        success: true
    }

* Archivage d'un contexte existant :

    POST /api/v1/archives/
    {
        context: "pre-production",
        excludeVault: true|false,
        description: "Archive avant mise à jour de la pre-prod."
    }

### archives/{archiveId}
|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/archives/{archiveId}**                                     |                | Voir les informations de l'archive OU télécharger l'archive          |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | Supprimer l'archive                                                  |

* Informations de l'archive :

    GET /api/v1/archives/833cc0ab-75f2-42c8-a39f-86a78875d2e9

Réponse

    HTTP/1.1 200 OK
    {
        archive: {
            uri: "/api/v1/archives/test-833cc0ab-75f2-42c8-a39f-86a78875d2e9",
            id: "test-833cc0ab-75f2-42c8-a39f-86a78875d2e9",,
            date: "2014-12-15 09:03:04",
            name: "test",
            size: 42131432,
            vault: true,
            description: "Archive de test",
            modules: [
                {
                    name: "dynacase-core",
                    version: "3.2.17",
                    release: "1"
                },
                ...
            ]
        }
    }

* Supprimer une archive :

    DELETE /api/v1/archives/test-833cc0ab-75f2-42c8-a39f-86a78875d2e9

Réponse :

    HTTP/1.1 200 OK
    {
        success: true
    }

### logs/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | */api/v1/logs*                                                       |                | Liste des fichiers de log disponibles                                |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

### logs/{logId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/logs/{logId}**                                             |                | Récupérer ou streamer le fichier de log                              |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Ajouter une entrée dans le fichier de log                            |
| DELETE |                                                                      |                | Vider le fichier de log                                              |

* Ajouter une (ou plusieurs) entrée(s) dans le fichier de log :

    POST /api/v1/logs/wiff.log
    {
        log: [
            "Hello from REST client!",
            "Goodbye from REST client."
        ]
    }

### transactions/

Une transaction est globale ? Ou par contexte ?

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

### transactions/{xactId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/transactions/{xactId}**                                    |                | Obtenir les détails de la transaction globale {xactId}               |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Démarre la transaction                                               |
| DELETE |                                                                      |                | Nettoyer ou avorter la transaction                                   |

États de la transaction :

    {status: "ready", currentOperation: ""}  /* État initial */
        |
        |
        v
    {status: "running", currentOperation: 1} /* État démarré : exécute les opérations */
        |
        |
        v
    {status: "running", currentOperation: 2}
        .
        .
        .
    {status: "running", currentOperation: N}
        |
        |
        v
    {status: "end", currentOperation: ""}    /* État terminé */

* Obtenir le détail d'une transaction

    GET /api/v1/transactions/123

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/transactions/123",
            id: 123,
            status: "ready",
            currentOperation: 3,
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
            }
        }
    }

* Attendre que la transasction se termine ou qu'une opération soit en échec :

    GET /api/v1/transactions/123?wait

Réponse :

    ... wait for end-of-transaction or failed operation ...
    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            ... transaction object ...
        }
    }

* Démarre la transaction :

    POST /api/v1/transactions/123

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: {
            uri: "/api/v1/transactions/123/operations/1",
            id: 1,
            type: "h1",
            status: "OK",
            next: "/api/v1/transactions/123/operations/2"
            h1: {
                label: "Installation of 'my-module'"
            }
        }
    }

* Nettoyer une transaction terminée :

    DELETE /api/v1/transactions/123

Réponse si la transaction s'est naturellement terminée (`status=end` et
`currentOperation=end`) :

    HTTP/1.1 200 OK
    {
        success: true
    }

Réponse si la transaction n'est pas terminée :

    HTTP/1.1 409 Conflict
    {
        success: false,
        error: "The transaction is still running."
    }

* Avorter une transaction non-terminée :

    DELETE /api/v1/transaction/123?abort

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
    }

Tuer les opérations qui tournent et supprimer la transaction.

### transactions/{xactId}/operations/

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/transactions/{xactId}/operations/**                        |                | Liste des opération de la transasction                               |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | -                                                                    |
| DELETE |                                                                      |                | -                                                                    |

* Liste des opérations de la transaction :

    GET /api/v1/transactions/123/operations/

Réponse :

    HTTP/1.1 200 OK
    {
        success: true,
        data: [
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
                    label: "Runnig pre-install..."
                    }
            },
            {
                uri: ".../3",
                id: 3,
                status: "OK",
                type: "task",
                task: {
                    label: "Checking for Foo",
                    }
            },
            {
                uri: ".../4",
                id: 4,
                status: "KO",
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
                    label: "Registering application MY_APP"
                    }
            }
        ]
    }

### transactions/{xactId}/operations/{opId}

|  Type  |                                 URL                                  |    Implanté    |                            Signification                             |
| ------ | -------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------- |
| GET    | **/api/v1/transactions/{xactId}/operations/{opId}**                  |                | Récupérer les inforrmations de l'opération                           |
| PUT    |                                                                      |                | -                                                                    |
| POST   |                                                                      |                | Exécuter l'opération                                                 |
| DELETE |                                                                      |                | Arrêter l'opération qui tourne                                       |

Type d'opérations :

`h1`..`h6`
:   Élément représentant une section, un commenntaire, une information pour
    délimiter les opérations, etc.
    
        h1: {
            label: "Label de la section"
            }
     
    États :
    
        {status: ""} --(exec)--> {status: "OK"}
    
    Données à soumettre pour l'exécution : aucune donnée à soumettre.

`task`
:   Élément représentant une tâche a exécuter.
    
        task: {
            label: "Label de description de l'opération"
            }
    
    États :
    
        {status: ""} --(exec)--> {status: "OK"}
        {status: ""} --(exec)--> {status: "KO"}
        {status: ""} --(exec)--> {status: "running"}
        
        {status: "running"} --> {status: "OK"}
        {status: "running"} --> {status: "KO"}
        
        {status: "KO"} --(exec)--> {status: "OK"}
        {status: "KO"} --(exec)--> {status: "KO"}
    
    Données pour l'exécution :
    
        {}

`license`
:   Élément représentant une licence pour laquelle l'utilisateur doit donner
    son accord.
    
        license: {
            licenseName: "ACME Corp. Public License 1.0"
            licenseText: "... content in text/plain ..."
            }
    
    États :
    
        {status: ""} --(exec)--> {status: "OK"}
        {status: ""} --(exec)--> {status: "end"}
    
    Données à soumettre pour l'exécution :
   
        {agree: true|false}
    
    Si l'utilisateur refuse la license, alors la transaction passe en status
    `end`.

`prompt`
:   Élément pour poser des questions et demander une réponse à l'utilisateur.
    
        prompt: [
            {
                id: "core_db",
                label: "Postgresql service name",
                type: "text",
                default: "pre-production"
            },
            {
                id: "colour"
                label: "What is you favorite colour?",
                type: "enum",
                values: "Red|Green|Blue"
            }
        ]
    
    États :
    
        {status: ""} --(exec)--> {status: "OK"}
    
    Données à soumettre pour l'exécution :
    
        [
            {
                id: "core_db",
                value: "pre-production"
            },
            {
                id: "colour",
                value: "Red"
            }
        ]

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

Réponse si la l'opération est en cours d'exécution :

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


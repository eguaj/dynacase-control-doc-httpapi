# Setup {#rest:e6cc573d-c269-4348-8394-bfa68a6993c5}

Cette ressource permet de voir la version actuellement installée de
dynacase-control, si une version de mise à jour est disponible, et de pouvoir
mettre à jour ce dernier si une mise à jour est disponible.

## Méthodes

* Ressource :

| Action   | URL                        | Action effectuée                                                               |
| :-     : | :                        : | :                                                                            : |
| `GET`    | `/api/v1/setup`            | [Retourne la version et si une mise à jour est disponible][get_version]        |
| `POST`   | `/api/v1/setup`            | [Met à jour dynacase-control si une mise à jour est dispnible][update_version] |
| `PUT`    | `/api/v1/setup`            | N/A                                                                            |
| `DELETE` | `/api/v1/setup`            | N/A                                                                            |

<!-- links -->
[get_version]: #rest:c9152c63-a18f-4351-b3e2-f1a240cfc3e4
[update_version]: #rest:50e38f5b-07ba-4442-b320-cd092c6e77a4

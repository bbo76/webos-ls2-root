# Analyse technique — webOS LS2 Root

## 1. Environnement testé

| Élément             | Valeur                 |
| ------------------- | ---------------------- |
| Téléviseur          | LG OLED55C35LA (C3)    |
| Version du firmware | 43.21.96               |
| Date du test        | 1er novembre 2026      |
| Accès initial       | SSH via Developer Mode |
| Compte SSH          | `prisoner` (UID 5693)  |
| Homebrew Channel    | 0.7.3                  |

Ces observations concernent un seul téléviseur. La compatibilité avec d'autres versions de webOS reste à vérifier.

## 2. Découverte : exécution privilégiée via LS2

Luna Service 2 (LS2) est le mécanisme de communication entre services utilisé par webOS.

Notre expérimentation a montré qu'un manifeste chargé dynamiquement depuis l'environnement Developer Mode pouvait enregistrer un service dont l'exécution aboutissait à des privilèges root.

### Mécanisme observé

1. Préparation d'un manifeste LS2 et d'une définition de service dynamique.
2. Chargement du manifeste depuis une page web exécutée sur le téléviseur, via `PalmServiceBridge` et `com.webos.service.bus/addManifestsDir`.
3. Invocation du service nouvellement enregistré.
4. Exécution d'un script de diagnostic.
5. Observation de `uid=0(root)` dans les résultats.

### Contexte d'exécution observé

- Processus parent : `ls-hubd`
- UID effectif : `0`
- GID effectif : `0`
- `NoNewPrivs` : `0`
- `Seccomp` : `0`

**À déterminer :** pourquoi cette configuration autorise une exécution privilégiée et quelles vérifications de sécurité sont appliquées lors de l'enregistrement du manifeste.

## 3. Persistance

Un manifeste distinct a été enregistré dans `/var/luna-service2-dev`, un emplacement consulté par LS2.

Après un redémarrage du téléviseur, le service pouvait de nouveau être appelé sans recharger manuellement le manifeste temporaire.

Cette observation démontre la persistance de son enregistrement à travers le redémarrage testé.

Elle ne démontre pas une exécution automatique au démarrage : le service dynamique est lancé à la demande.

## 4. Installation Homebrew Channel

L'installation officielle de Homebrew Channel 0.7.3 a été effectuée à partir du contexte root obtenu.

Le processus d'installation a modifié la définition du service Homebrew et ses autorisations LS2.

Résultats constatés :

- Installation réussie.
- `Root status: OK` dans Homebrew Channel.
- `Root status: OK` après redémarrage du téléviseur.
- Désactivation de Telnet par le marqueur de configuration Homebrew.

## 5. Limites et inconnues

Les éléments suivants restent à étudier :

- Reproductibilité depuis un environnement Developer Mode propre.
- Comportement après un cycle complet d'alimentation.
- Comportement après une mise à jour du firmware.
- Effet de la désactivation ou de l'expiration du Developer Mode.
- Contrôles d'autorisation sur les appels LS2.
- Nettoyage complet des services expérimentaux.

## 6. Considérations de sécurité

Le service expérimental utilisait un script modifiable depuis l'environnement Developer Mode, mais exécuté avec les privilèges root.

Il s'agit d'une configuration à risque, adaptée à un laboratoire de recherche temporaire mais pas à une installation permanente.

Le projet doit donc prévoir un nettoyage contrôlé des composants expérimentaux, sans modifier les scripts LG signés ni les fichiers nécessaires au fonctionnement de Homebrew Channel.

## Ce que ce package installe

- Le binaire `tsbridge` dans `__INSTALL_DIR__/tsbridge`, correspondant à
  l'architecture CPU de ce serveur (amd64 ou arm64).
- `__INSTALL_DIR__/config.yaml`, le fichier de configuration YAML de
  `tsbridge`.
- `__INSTALL_DIR__/tsbridge.env`, contenant `TS_AUTHKEY` (si vous en avez
  renseigné une), lu par le `EnvironmentFile=` de l'unité systemd.
- Une unité systemd `__APP__.service`, exécutée sous l'utilisateur
  système dédié `__APP__`, avec `Restart=on-failure`.
- Le dossier de données persistantes de l'app, contenant l'identité du
  nœud tsnet -- **non** supprimé lors d'une simple désinstallation,
  uniquement avec `--purge`.

Il n'y a ni domaine, ni configuration nginx, ni intégration SSO/LDAP :
`tsbridge` n'a pas d'interface web propre, cette app ne demande donc pas
de domaine/chemin.

## Ajouter, retirer et modifier des ponts (bridges)

La liste `bridges:` de `config.yaml` n'a pas de rechargement à chaud :
ajoutez, retirez ou modifiez un pont en éditant
`__INSTALL_DIR__/config.yaml`, puis

```sh
yunohost service restart __APP__
```

Chaque entrée nécessite `name`, `listen` (un chemin de socket Unix
absolu -- voir l'exemple déjà en commentaire dans `config.yaml`) et
`target` (`hôte:port` accessible sur le tailnet). Voir le README du
projet amont (lien dans la documentation d'administration de cette app)
pour la référence complète des champs, notamment `mode: http` pour
terminer le HTTP et faire du reverse-proxy plutôt qu'une simple copie
d'octets.

**Une liste `bridges:` modifiée à la main ne survit pas à une mise à
jour de l'app** -- voir le message affiché après la mise à jour.

## Joindre un socket de pont depuis un reverse-proxy

Les sockets de pont sont créées avec le groupe `www-data` par défaut
(`socket_group: www-data` dans `config.yaml`, avec
`SupplementaryGroups=www-data` sur l'unité systemd pour que `__APP__`
puisse appliquer ce groupe), afin que nginx -- ou tout autre service
local tournant en tant que `www-data` -- puisse s'y connecter
directement, par exemple comme cible `proxy_pass
http://unix:/run/__APP__/mon-service.sock:;` dans un extrait nginx écrit
à la main. Il n'y a pas de configuration nginx gérée par YunoHost pour
cette app ; relier un socket de pont à un domaine reste entièrement à
votre charge.

## Enregistrer le nœud auprès du tailnet

Si vous avez laissé la clé d'authentification vide à l'installation (ou
souhaitez vérifier le processus d'approbation), consultez le journal
juste après le démarrage du service pour une URL d'enregistrement à
usage unique :

```sh
yunohost service log __APP__
# ou
journalctl -u __APP__ -f
```

Ouvrez cette URL une fois pour approuver le nœud dans la console
d'administration Tailscale (ou votre serveur Headscale). Cela ne
s'effectue qu'une seule fois -- l'identité du nœud persiste dans le
dossier de données de l'app d'un redémarrage à l'autre.

## Panneau de configuration

Le panneau de configuration de l'app dans le webadmin (Applications >
__APP__ > Panneau de configuration) expose :

- **Nom du nœud sur le tailnet** (`hostname:` dans `config.yaml`)
- **URL du serveur de contrôle** (`control_url:` dans `config.yaml`) --
  vide pour utiliser celui de Tailscale ; à renseigner pour basculer vers
  une instance Headscale auto-hébergée
- **Clé d'authentification** (`TS_AUTHKEY` dans `tsbridge.env`) --
  n'affecte que l'enregistrement ; la modifier ne ré-enregistre **pas**
  un nœud déjà connu

Toute modification redémarre automatiquement le service `__APP__`. La
liste `bridges:` elle-même n'est volontairement pas exposée ici -- voir
les sections précédentes.

## Journaux

```sh
journalctl -u __APP__ -f          # suivre en direct
journalctl -u __APP__ -e          # aller à la fin
journalctl -u __APP__ --since -10m
```

Les journaux de démarrage listent chaque pont résolu par tsbridge (nom,
chemin d'écoute, cible) -- à vérifier en premier si un pont attendu ne
tourne pas.

## Exemple de règle ACL pour le tailnet

Restreignez ce nœud (taguez-le, par ex. `tag:tsbridge`, lors de la
génération de sa clé d'authentification) aux seuls hôtes/ports qu'il
relaie réellement :

```jsonc
{
  "tagOwners": {
    "tag:tsbridge": ["autogroup:admin"],
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:tsbridge"],
      "dst": [
        "machine-distante:1234",
      ],
    },
  ],
}
```

Ajustez `dst` pour correspondre à chaque `target:` relayée par cette
instance, et rien de plus.

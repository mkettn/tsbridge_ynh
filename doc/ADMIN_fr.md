## Ce que ce package installe

- Le binaire `tsbridge` dans `__INSTALL_DIR__/tsbridge`, correspondant à
  l'architecture CPU de ce serveur (amd64 ou arm64).
- `__INSTALL_DIR__/config.yaml`, le fichier de configuration YAML de
  `tsbridge`.
- `__INSTALL_DIR__/tsbridge.env`, contenant `TS_AUTHKEY` (si vous en avez
  renseigné une), lu par le `EnvironmentFile=` de l'unité systemd.
- Une unité systemd `__APP__.service`, exécutée sous l'utilisateur
  système dédié `__APP__`, avec `Restart=on-failure`.
- Le dossier de données persistantes de l'app (identité du nœud tsnet, et
  `managed-bridges.yaml` en cas d'utilisation de l'API de gestion
  ci-dessous) -- **non** supprimé lors d'une simple désinstallation,
  uniquement avec `--purge`.

Il n'y a ni domaine, ni configuration nginx, ni intégration SSO/LDAP :
`tsbridge` n'a pas d'interface web propre, cette app ne demande donc pas
de domaine/chemin.

## Ajouter, retirer et modifier des ponts (bridges)

La liste `bridges:` de `config.yaml` n'a pas de rechargement à chaud --
la modifier à la main nécessite `yunohost service restart __APP__` pour
prendre effet. Pour modifier les ponts sans redémarrage, l'API de gestion
en temps réel est activée par défaut sur `/run/__APP__/control.sock`
(accessible uniquement localement, par ex. via SSH, puisqu'il n'y a pas
de domaine pour l'exposer) :

```sh
# Ajouter un pont.
sudo curl --unix-socket /run/__APP__/control.sock \
  -X POST http://unix/bridges \
  -H 'content-type: application/json' \
  -d '{"name":"svc","listen":"/run/__APP__/svc.sock","target":"machine-distante:1234"}'

# Lister tous les ponts connus de tsbridge.
sudo curl --unix-socket /run/__APP__/control.sock http://unix/bridges

# Le désactiver sans l'oublier, puis le réactiver.
sudo curl --unix-socket /run/__APP__/control.sock -X POST http://unix/bridges/svc/disable
sudo curl --unix-socket /run/__APP__/control.sock -X POST http://unix/bridges/svc/enable

# Le supprimer entièrement.
sudo curl --unix-socket /run/__APP__/control.sock -X DELETE http://unix/bridges/svc

# Vérifier la connexion au tailnet elle-même (pas un pont en particulier).
sudo curl --unix-socket /run/__APP__/control.sock http://unix/status
```

Un pont ajouté ainsi est persisté dans `managed-bridges.yaml`, dans le
dossier de données de l'app, et survit aux redémarrages ; `DELETE`/
`disable` mettent aussi à jour ce fichier. Un pont défini directement
dans `config.yaml` revient en revanche à chaque redémarrage sauf à
modifier aussi `config.yaml` -- `disable`/`DELETE` via l'API ne
l'affectent alors que jusqu'au prochain redémarrage. `GET /bridges`
indique la `source` de chaque pont (`"config"` ou `"managed"`) pour les
distinguer. Voir le README du projet amont (lien dans la documentation
d'administration de cette app) pour la référence complète de l'API.

**Une liste `bridges:` modifiée à la main dans `config.yaml` ne survit
pas à une mise à jour de l'app** -- voir le message affiché après la mise
à jour. Les ponts ajoutés via l'API de gestion ne sont pas concernés.

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
la section précédente.

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

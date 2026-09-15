tsbridge expose des services TCP présents sur un tailnet
[Tailscale](https://tailscale.com) (ou un réseau [Headscale](https://headscale.net)
auto-hébergé) sous forme de sockets Unix locales, sans que ce serveur
YunoHost ait besoin de rejoindre le tailnet au niveau du système
d'exploitation. Il utilise la bibliothèque `tsnet` de Tailscale pour se
connecter entièrement en espace utilisateur (WireGuard userspace, pas
d'interface réseau système, pas de démon `tailscaled`), puis relaie les
octets TCP -- ou, pour les services HTTP, les requêtes via un
reverse-proxy -- entre chaque socket Unix et sa cible sur le tailnet.

Usage typique : un reverse-proxy ou un serveur d'application sur cette
machine se connecte à `/run/tsbridge/mon-service.sock` plutôt que
directement à `machine-distante:1234` sur le tailnet, de sorte que seul ce
nœud dédié, restreint par ACL, a besoin d'un accès au tailnet.

Cette app n'a pas d'interface web propre : il s'agit d'un service
système, configuré via un fichier YAML et, en option, une petite API JSON
locale permettant d'ajouter ou de retirer des ponts sans redémarrage.

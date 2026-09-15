Avant l'installation, vous devriez disposer (ou être prêt à créer) d'un
compte Tailscale, ou d'une instance Headscale auto-hébergée si vous
comptez en utiliser une à la place (via la question « URL du serveur de
contrôle » ci-dessous).

Générer à l'avance une clé d'authentification taguée et restreinte par
ACL est recommandé pour un enregistrement automatisé, mais pas
obligatoire -- laisser la clé vide fonctionne également, et vous
approuverez alors ce nœud une seule fois via une URL à usage unique
inscrite dans le journal au premier démarrage. Consultez la documentation
d'administration de l'app pour le détail des deux méthodes, ainsi qu'un
exemple de règle ACL pour restreindre ce nœud aux seuls hôtes/ports dont
il a réellement besoin.

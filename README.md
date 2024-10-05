
# Démonstration du Cluster CouchDB Multi-nœuds

Ce dépôt démontre comment configurer un cluster CouchDB multi-nœuds avec sharding et réplication.
Nous allons parcourir la configuration du cluster, l'ajout de nœuds et tester des scénarios tels que la tolérance aux pannes et la cohérence éventuelle.

## Backend et Frontend pour la Démonstration de CouchDB

Ce projet inclut également une démonstration avec un **backend** et un **frontend** pour interagir avec CouchDB via une API REST et une interface utilisateur simple. Voici les principaux points mis en évidence :

- **Interaction avec la base de données** : Le backend permet d'ajouter, de récupérer et de gérer les données de l'inventaire via des appels API CouchDB.
- **Répartition des données et réplication** : Grâce à CouchDB, le backend peut gérer la réplication des données sur plusieurs nœuds du cluster.
- **Tests de tolérance aux pannes** : Vous pouvez éteindre ou redémarrer un nœud CouchDB et voir comment les autres nœuds continuent à fonctionner grâce à la réplication continue.
- **Interface utilisateur** : Le frontend permet de visualiser les données de l'inventaire en interagissant avec le backend via des appels API. Il utilise CouchDB comme base de données NoSQL sous-jacente.

### Liens vers les dossiers

- [Backend](./backend) : Le dossier backend contient le code du serveur Node.js qui interagit avec CouchDB.
- [Frontend](./frontend) : Le dossier frontend contient le code de l'interface utilisateur qui interagit avec le backend.

---

### Points démontrés avec le Backend et Frontend

- **Gestion des items** : Vous pouvez ajouter des items à la base de données d'inventaire à travers le backend et les visualiser dans le frontend.
- **Connexion à CouchDB** : Le backend se connecte automatiquement aux nœuds CouchDB définis dans les variables d'environnement et distribue les requêtes entre les différents nœuds.
- **Vérification de la réplication** : Les données ajoutées à CouchDB via le backend sont automatiquement répliquées sur les autres nœuds du cluster, et vous pouvez visualiser cette réplication en temps réel dans le frontend.
- **Résilience** : En cas de panne d'un des nœuds CouchDB, les autres continuent de fonctionner sans interruption, illustrant ainsi la tolérance aux pannes de CouchDB.

Ces démonstrations permettent d'illustrer les avantages de CouchDB dans un environnement distribué avec des scénarios d'utilisation pratiques.

## Prérequis

Assurez-vous d'avoir les éléments suivants installés :
- **Docker** : https://www.docker.com/
- **Docker Compose** : https://docs.docker.com/compose/install/
- **Curl** : Pour effectuer des requêtes HTTP
- **.env** : un fichier `.env` pour la configuration des variables d'environnnement:
```env
  `COMPOSE_PROJECT_NAME`
  `PORT_BASE`
  `COUCHDB_USER`
  `COUCHDB_PASSWORD`
  `COUCHDB_SECRET`
  `COUCHDB_COOKIE`
```

## Configuration du Cluster

### Étape 1 : Démarrer les Nœuds CouchDB

Exécutez la commande suivante pour démarrer les trois nœuds CouchDB :

```bash
docker-compose up -d
```

### Étape 2 : Initialiser le Cluster

Exécutez la commande suivante [initialiser le cluster](./init-cluster-doc.md):

```bash
./init-cluster.sh
```

### Étape 3 : Vérifier l'Appartenance au Cluster

Exécutez la commande suivante pour vérifier les nœuds du cluster :

```bash
curl http://admin:password@localhost:55001/_membership
```

Vous devriez voir les trois nœuds listés sous `cluster_nodes`.

---

## Vérification du Sharding

Lors de la création d'une base de données, CouchDB répartit automatiquement les données (sharding) sur le cluster. Vous pouvez vérifier les shards avec la commande suivante :

```bash
curl http://admin:password@localhost:55001/inventaire/_shards
```

Cela renverra la distribution des shards entre les nœuds.

## Monitoring avec Fauxton

CouchDB fournit une interface web appelée **Fauxton**, qui permet d'inspecter visuellement les bases de données, documents, shards, et nœuds.

- **Accéder à Fauxton pour node1** : [http://localhost:55001/_utils](http://localhost:55001/_utils)
- **Accéder à Fauxton pour node2** : [http://localhost:55002/_utils](http://localhost:55002/_utils)
- **Accéder à Fauxton pour node3** : [http://localhost:55003/_utils](http://localhost:55003/_utils)

Utilisez Fauxton pour vérifier visuellement la distribution des shards et la réplication.

---

## Conclusion

Dans cette démonstration, nous avons configuré un cluster CouchDB multi-nœuds avec sharding et réplication. Nous avons vérifié son bon fonctionnement à travers des tests de tolérance aux pannes, de cohérence éventuelle, et de mode hors-ligne. CouchDB est une solution NoSQL robuste pour des environnements distribués nécessitant une haute disponibilité et une résilience aux pannes réseau.

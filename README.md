
# Démonstration du Cluster CouchDB Multi-nœuds

Ce dépôt démontre comment configurer un cluster CouchDB multi-nœuds avec sharding et réplication.
Nous allons parcourir la configuration du cluster, l'ajout de nœuds et tester des scénarios tels que la tolérance aux pannes et la cohérence éventuelle.

## Prérequis

Assurez-vous d'avoir les éléments suivants installés :
- **Docker** : https://www.docker.com/
- **Docker Compose** : https://docs.docker.com/compose/install/
- **Curl** : Pour effectuer des requêtes HTTP

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

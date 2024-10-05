
# CouchDB Cluster Initialization Script (`init-cluster.sh`)

This document explains the purpose of each step in the `init-cluster.sh` script used to initialize a CouchDB cluster from the **host**.

### Pre-requisite
Ensure that all CouchDB nodes are running and accessible before proceeding with the steps below.

---

## 1. Create Admin User
Run the following command to set up the admin user `admin` with the password `password` on `couchdb_node1`. Use `localhost:55001` since you're running this command from the host:

```bash
curl -X PUT http://admin:password@localhost:55001/_node/couchdb@couchdb_node1/_config/admins/admin -d '"password"'
```

---

## 2. Enable the Cluster on `couchdb_node1`
To begin the clustering process, enable the cluster on `couchdb_node1`:

```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_cluster_setup     -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password": "password", "node_count": "3"}'
```

You may safely ignore any warnings about skipping the cluster initialization if it is already active.

---

## 3. Join `couchdb_node2` and `couchdb_node3` to the Cluster

For each additional node (`couchdb_node2` and `couchdb_node3`), there are **two steps**:

### Step 1: Enable Cluster for the Additional Node (`couchdb_node2` and `couchdb_node3`)
Run the following command for each additional node to enable cluster mode for that node. Replace `<node-host>` and `<port>` with the appropriate values for each node.

#### For `couchdb_node2`:
```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_cluster_setup     -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password": "password", "port": 5984, "node_count": "3", "remote_node": "couchdb_node2", "remote_current_user": "admin", "remote_current_password": "password"}'
```

#### For `couchdb_node3`:
```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_cluster_setup     -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password": "password", "port": 5984, "node_count": "3", "remote_node": "couchdb_node3", "remote_current_user": "admin", "remote_current_password": "password"}'
```

### Step 2: Add Each Node to the Cluster
After enabling cluster mode on each node, you must add the node to the cluster with the following command:

#### For `couchdb_node2`:
```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_cluster_setup     -d '{"action": "add_node", "host": "couchdb_node2", "port": 5984, "username": "admin", "password": "password"}'
```

#### For `couchdb_node3`:
```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_cluster_setup     -d '{"action": "add_node", "host": "couchdb_node3", "port": 5984, "username": "admin", "password": "password"}'
```

---

## 4. Finalize the Cluster Setup
Complete the cluster setup by running the following command:

```bash
curl http://admin:password@localhost:55001/
```

```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_cluster_setup     -d '{"action": "finish_cluster"}'
```

---

## 5. Check Cluster Membership
Verify that all nodes (`couchdb_node1`, `couchdb_node2`, and `couchdb_node3`) have successfully joined the cluster:

```bash
curl http://admin:password@localhost:55001/_membership
```

The result should show both the `all_nodes` and `cluster_nodes` sections, and both should contain the names of all CouchDB nodes in the cluster.

---

## 6. Create the `Inventory` Database
Create the `inventory` database on `couchdb_node1`:

```bash
curl -X PUT http://admin:password@localhost:55001/inventory
```

---

## 7. Set Up Continuous Replication
Set up continuous replication of the `inventory` database between the nodes to ensure consistency across the cluster.

### Replicate from `couchdb_node1` to `couchdb_node2`:
```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_replicate     -d '{"source": "inventory", "target": "http://admin:password@localhost:5985/inventory", "create_target": true, "continuous": true}'
```

### Replicate from `couchdb_node1` to `couchdb_node3`:
```bash
curl -X POST -H "Content-Type: application/json"     http://admin:password@localhost:55001/_replicate     -d '{"source": "inventory", "target": "http://admin:password@localhost:5986/inventory", "create_target": true, "continuous": true}'
```

---

## 8. Create a Separate Backend User
Instead of using the `admin` user for your backend service, it's more secure to create a separate user with specific permissions.

### Create `backend_user`
Create a user called `backend_user` with the following command:

```bash
curl -X PUT http://admin:password@localhost:55001/_users/org.couchdb.user:backend_user     -H "Content-Type: application/json"     -d '{"name": "backend_user", "password": "backend_password", "roles": [], "type": "user"}'
```

### Assign Database Permissions
Grant the `backend_user` read and write permissions on the `inventory` database:

```bash
curl -X PUT http://admin:password@localhost:55001/inventory/_security     -H "Content-Type: application/json"     -d '{"admins": {"names": [], "roles": []}, "members": {"names": ["backend_user"], "roles": []}}'
```

---

## 9. Sharding and Load Testing
CouchDB uses sharding to distribute data across nodes. Verify that sharding is working properly by adding data and checking shard distribution.

### Add a Document to the Inventory Database
To add a document, run:

```bash
curl -X POST http://admin:password@localhost:55001/inventory     -H "Content-Type: application/json"     -d '{"item": "laptop", "quantity": 5}'
```

### Check Shard Allocation
To check shard distribution, view the shards of the `inventory` database:

```bash
curl http://admin:password@localhost:55001/inventory/_shards
```

---

## Conclusion
This script sets up a CouchDB cluster with three nodes (`couchdb_node1`, `couchdb_node2`, and `couchdb_node3`), creates the `inventory` database, ensures continuous replication between nodes, creates a separate `backend_user`, and tests sharding functionality.

All commands should be run from the **host** machine using `localhost` and the correct port for each node with admin credentials.

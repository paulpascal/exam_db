#!/bin/bash

# Load environment variables from .env file
source .env

# Configuration for CouchDB cluster nodes
DEPLOYMENT_NAME=${COMPOSE_PROJECT_NAME}
IFS=","
COORDINATOR_NODE="1"
ADDITIONAL_NODES="2,3"
ALL_NODES="${COORDINATOR_NODE},${ADDITIONAL_NODES}"

# Define color codes for output styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Function to display messages with color
function print_info() {
  echo -e "${YELLOW}$1${NC}"
}

function print_success() {
  echo -e "${GREEN}$1${NC}"
}

function print_error() {
  echo -e "${RED}$1${NC}"
}

# -------------------------------
# STEP 1: Enable the cluster on the coordinator node
# -------------------------------
echo ""
print_info "Step 1: Enabling cluster on the coordinator node (couchdb_node1)..."

for NODE_ID in $COORDINATOR_NODE
do
  curl -X POST -H "Content-Type: application/json" "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}${NODE_ID}/_cluster_setup" \
  -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "'"${COUCHDB_USER}"'", "password":"'"${COUCHDB_PASSWORD}"'", "node_count":"3"}'

  print_success "Coordinator node (couchdb_node1) cluster enabled."
  print_info "You may safely ignore any warnings above."
done

# -------------------------------
# STEP 2: Add additional nodes to the cluster
# -------------------------------
echo ""
print_info "Step 2: Adding additional nodes to the cluster..."

for NODE_ID in $ADDITIONAL_NODES
do
  # Enable the remote node
  curl -X POST -H "Content-Type: application/json" "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_cluster_setup" \
  -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "'"${COUCHDB_USER}"'", "password":"'"${COUCHDB_PASSWORD}"'", "port": 5984, "node_count": "3", "remote_node": "'"couchdb_node${NODE_ID}.${DEPLOYMENT_NAME}"'", "remote_current_user": "'"${COUCHDB_USER}"'", "remote_current_password": "'"${COUCHDB_PASSWORD}"'"}'

  # Add the node to the cluster
  curl -X POST -H "Content-Type: application/json" "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_cluster_setup" \
  -d '{"action": "add_node", "host":"'"couchdb_node${NODE_ID}.${DEPLOYMENT_NAME}"'", "port": 5984, "username": "'"${COUCHDB_USER}"'", "password":"'"${COUCHDB_PASSWORD}"'"}'

  print_success "Node couchdb_node${NODE_ID} added to the cluster."
done

# -------------------------------
# STEP 3: Finish cluster setup
# -------------------------------
echo ""
print_info "Step 3: Finalizing the cluster setup..."

# See https://github.com/apache/couchdb/issues/2858
curl "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/"

curl -X POST -H "Content-Type: application/json" "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_cluster_setup" \
-d '{"action": "finish_cluster"}'

print_success "Cluster setup finished."

# -------------------------------
# STEP 4: Verify cluster membership
# -------------------------------
echo ""
print_info "Step 4: Verifying cluster membership..."

curl "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_membership"

print_success "Cluster membership verified."

# -------------------------------
# STEP 5: Create backend user and assign permissions
# -------------------------------
echo ""
print_info "Step 5: Creating backend user and assigning permissions..."

# Ensure the _users and inventory databases exist before assigning permissions
curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_users"
curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/inventory"

# Create backend user
curl -X PUT http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_users/org.couchdb.user:${BACKEND_USER} \
-H "Content-Type: application/json" \
-d '{"name": "'"${BACKEND_USER}"'", "password": "'"${BACKEND_PASSWORD}"'", "roles": [], "type": "user"}'

print_success "Backend user created."

# Assign permissions to backend user
curl -X PUT http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/inventory/_security \
-H "Content-Type: application/json" \
-d '{"admins": {"names": [], "roles": []}, "members": {"names": ["'"${BACKEND_USER}"'"], "roles": []}}'

print_success "Backend user assigned permissions on inventory database."

# -------------------------------
# STEP 6: Display shards information
# -------------------------------
echo ""
print_info "Step 6: Displaying shard allocation information for the inventory database..."

curl "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/inventory/_shards"

# -------------------------------
# STEP 7: Set Up Continuous Replication
# -------------------------------
echo ""
print_info "Step 7: Setting up continuous replication between all nodes..."

# Replicate from node1 to node2
curl -X POST -H "Content-Type: application/json" \
  http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_replicate \
  -d '{"source": "inventory", "target": "http://admin:password@localhost:5985/inventory", "create_target": true, "continuous": true}'

# Replicate from node1 to node3
curl -X POST -H "Content-Type: application/json" \
  http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}1/_replicate \
  -d '{"source": "inventory", "target": "http://admin:password@localhost:5986/inventory", "create_target": true, "continuous": true}'

# Replicate from node2 to node1
curl -X POST -H "Content-Type: application/json" \
  http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}2/_replicate \
  -d '{"source": "inventory", "target": "http://admin:password@localhost:5984/inventory", "create_target": true, "continuous": true}'

# Replicate from node2 to node3
curl -X POST -H "Content-Type: application/json" \
  http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}2/_replicate \
  -d '{"source": "inventory", "target": "http://admin:password@localhost:5986/inventory", "create_target": true, "continuous": true}'

# Replicate from node3 to node1
curl -X POST -H "Content-Type: application/json" \
  http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}3/_replicate \
  -d '{"source": "inventory", "target": "http://admin:password@localhost:5984/inventory", "create_target": true, "continuous": true}'

# Replicate from node3 to node2
curl -X POST -H "Content-Type: application/json" \
  http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}3/_replicate \
  -d '{"source": "inventory", "target": "http://admin:password@localhost:5985/inventory", "create_target": true, "continuous": true}'

print_success "Continuous replication set up between all nodes."

# -------------------------------
# Display cluster nodes
# -------------------------------
echo ""
print_info "Your CouchDB cluster nodes are available at:"

for NODE_ID in ${ALL_NODES}
do
  echo -e "${GREEN}http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:${PORT_BASE}${NODE_ID}${NC}"
done

print_success "CouchDB cluster initialization complete."
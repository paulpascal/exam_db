const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Set up CORS
app.use(cors({
    origin: 'http://localhost:8080',
    methods: ['GET', 'POST'],
}));
app.use(express.json());

// Load port, credentials, and CouchDB URLs from environment variables
const COUCHDB_USER = process.env.COUCHDB_USER;
const COUCHDB_PASSWORD = process.env.COUCHDB_PASSWORD;
const PORT = process.env.PORT || 3000;

const node1Url = `http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@couchdb_node1:5984`;
const node2Url = `http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@couchdb_node2:5984`;
const node3Url = `http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@couchdb_node3:5984`;

const dbName = 'inventory';

// Function to add an item to a specific CouchDB node
async function addItem(nodeUrl, item, quantity) {
    try {
        const response = await axios.post(`${nodeUrl}/${dbName}`, {
            item: item,
            quantity: quantity
        });
        return response.data;
    } catch (error) {
        console.error(`Error adding item to node ${nodeUrl}:`, error.message);
        throw error;
    }
}

// Function to get the inventory from a specific node
async function getInventory(nodeUrl) {
    try {
        const response = await axios.get(`${nodeUrl}/${dbName}/_all_docs?include_docs=true`);
        return response.data.rows.map(row => row.doc);
    } catch (error) {
        console.error(`Error getting inventory from node ${nodeUrl}:`, error.message);
        throw error;
    }
}

// API to add an item to a specific node
app.post('/add-item', async (req, res) => {
    const { item, quantity, node } = req.body;
    const nodeUrl = node === 'node1' ? node1Url : node === 'node2' ? node2Url : node3Url;
    try {
        const result = await addItem(nodeUrl, item, quantity);
        res.json({ message: 'Item added successfully', result });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// API to get the inventory from a specific node
app.get('/inventory/:node', async (req, res) => {
    const node = req.params.node;
    const nodeUrl = node === 'node1' ? node1Url : node === 'node2' ? node2Url : node3Url;
    try {
        const inventory = await getInventory(nodeUrl);
        res.json(inventory);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Start the server and initialize the databases
app.listen(PORT, () => {
    console.log(`🚀 Backend service is running on port ${PORT}`);
});
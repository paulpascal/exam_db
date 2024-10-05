// Constants for dynamic values (can be moved to an .env file or config)
const BASE_URL = 'http://localhost:3000';  // Move this to a config or .env in real projects
const headers = { 'Content-Type': 'application/json' };

// Function to add an item to the inventory
async function addItem() {
    const item = document.getElementById('item').value;
    const quantity = document.getElementById('quantity').value;
    const node = document.getElementById('node').value;
    const errorDiv = document.getElementById('error');
    const resultDiv = document.getElementById('result');
    errorDiv.innerHTML = '';
    resultDiv.innerHTML = '';

    try {
        const response = await fetch(`${BASE_URL}/add-item`, {
            method: 'POST',
            headers: headers,
            body: JSON.stringify({ item, quantity, node })
        });

        if (!response.ok) {
            throw new Error(`Failed to add item: ${response.statusText}`);
        }

        const result = await response.json();
        resultDiv.innerHTML = `<p>Item added successfully to ${node}!</p>`;
    } catch (error) {
        errorDiv.innerHTML = `<p>Error: ${error.message}</p>`;
    }
}

// Function to get the inventory from a node
async function getInventory() {
    const node = document.getElementById('nodeRead').value;
    const errorDiv = document.getElementById('inventoryError');
    const resultDiv = document.getElementById('inventoryResult');
    errorDiv.innerHTML = '';
    resultDiv.innerHTML = '';

    try {
        const response = await fetch(`${BASE_URL}/inventory/${node}`);
        if (!response.ok) {
            throw new Error(`Failed to fetch inventory: ${response.statusText}`);
        }

        const data = await response.json();
        if (data.length === 0) {
            resultDiv.innerHTML = '<p>No inventory available</p>';
        } else {
            let output = '<h3>Inventory</h3><ul>';
            data.forEach(item => {
                output += `<li>${item.item}: ${item.quantity}</li>`;
            });
            output += '</ul>';
            resultDiv.innerHTML = output;
        }
    } catch (error) {
        errorDiv.innerHTML = `<p>Error: ${error.message}</p>`;
    }
}
const express = require('express');
const fetch = require('node-fetch');

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001';

app.get('/', async (req, res) => {
  let backendData;
  let error;
  
  try {
    const response = await fetch(`${BACKEND_URL}/api/data`);
    backendData = await response.json();
  } catch (err) {
    console.error('Error fetching from backend:', err);
    error = err.message;
  }

  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Kubernetes Demo</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
          .data-container {
            margin-top: 20px;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 4px;
            background-color: #f9f9f9;
          }
          .error {
            color: #dc3545;
            padding: 10px;
            border: 1px solid #dc3545;
            border-radius: 4px;
            background-color: #fff;
          }
          .refresh-btn {
            margin-top: 20px;
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
          }
          .refresh-btn:hover {
            background-color: #0056b3;
          }
        </style>
      </head>
      <body>
        <h1>Kubernetes Demo</h1>
        <form method="GET" action="/">
          <button type="submit" class="refresh-btn">Refresh Data</button>
        </form>
        ${error ? 
          `<div class="error">Error fetching data: ${error}</div>` :
          `<div class="data-container">
            <h3>Backend Response:</h3>
            <pre>${JSON.stringify(backendData, null, 2)}</pre>
           </div>`
        }
        <p>Last rendered at: ${new Date().toISOString()}</p>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Frontend service running on port ${PORT}`);
}); 
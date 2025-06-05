const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'backend-service',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/data', (req, res) => {
  const data = {
    message: 'Hello from the backend!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  };
  res.json(data);
});

app.listen(PORT, () => {
  console.log(`Backend service running on port ${PORT}`);
}); 
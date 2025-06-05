# Kubernetes Demo Services

This directory contains two Node.js services that demonstrate a simple frontend-backend interaction:

## Backend Service

Located in `backend-service/`, this is a simple API service that returns some fixed data.

To run:
```bash
cd backend-service
npm install
npm start
```

The service will run on port 3001 by default.

## Frontend Service

Located in `frontend-service/`, this is a simple web application that makes requests to the backend service.

To run:
```bash
cd frontend-service
npm install
npm start
```

The service will run on port 3000 by default.

## Environment Variables

Both services support the following environment variables:

### Frontend Service
- `PORT`: The port to run on (default: 3000)
- `BACKEND_URL`: The URL of the backend service (default: http://localhost:3001)

### Backend Service
- `PORT`: The port to run on (default: 3001)
- `NODE_ENV`: The environment (development/production)

## Testing the Setup

1. Start the backend service first
2. Start the frontend service
3. Visit http://localhost:3000 in your browser
4. Click the "Fetch Data from Backend" button to see the interaction 
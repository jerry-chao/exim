# API Authentication Guide

This document explains how to use token-based authentication with the Exim API.

## Overview

The Exim application provides a robust token-based authentication system that supports both web sessions and API access. The system uses session tokens that are stored in the database and can be validated for subsequent requests.

## Authentication Flow

### 1. Login and Token Generation

**Endpoint:** `POST /api/auth/login`

**Request:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "your_password"
  }
}
```

**Response (Success):**
```json
{
  "token": "base64_encoded_session_token",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "testuser"
  }
}
```

**Response (Error):**
```json
{
  "error": "Invalid email or password"
}
```

### 2. Token Verification

**Endpoint:** `GET /api/auth/verify`

**Headers:**
```
Authorization: Bearer <your_token_here>
```

**Response (Success):**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "testuser"
  }
}
```

**Response (Error):**
```json
{
  "error": "Invalid or expired token"
}
```

### 3. Token Invalidation (Logout)

**Endpoint:** `DELETE /api/auth/logout`

**Headers:**
```
Authorization: Bearer <your_token_here>
```

**Response (Success):**
```json
{
  "message": "Token invalidated successfully"
}
```

## Usage Examples

### cURL Examples

#### Login
```bash
curl -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123"
    }
  }'
```

#### Verify Token
```bash
curl -X GET http://localhost:4001/api/auth/verify \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Logout
```bash
curl -X DELETE http://localhost:4001/api/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### JavaScript Examples

#### Using Fetch API

```javascript
// Login
async function login(email, password) {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      user: {
        email: email,
        password: password
      }
    })
  });
  
  if (response.ok) {
    const data = await response.json();
    localStorage.setItem('authToken', data.token);
    return data;
  } else {
    throw new Error('Login failed');
  }
}

// Make authenticated requests
async function makeAuthenticatedRequest(url, options = {}) {
  const token = localStorage.getItem('authToken');
  
  const response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (response.status === 401) {
    // Token expired or invalid, redirect to login
    localStorage.removeItem('authToken');
    window.location.href = '/login';
    return;
  }
  
  return response;
}

// Verify token
async function verifyToken() {
  try {
    const response = await makeAuthenticatedRequest('/api/auth/verify');
    return response.ok ? await response.json() : null;
  } catch (error) {
    return null;
  }
}

// Logout
async function logout() {
  const token = localStorage.getItem('authToken');
  if (token) {
    await fetch('/api/auth/logout', {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    localStorage.removeItem('authToken');
  }
  window.location.href = '/login';
}
```

## Token Management

### Token Storage
- Tokens are stored in the database using the `UserToken` schema
- Each token is associated with a specific user and has a "session" context
- Tokens are automatically cleaned up when they expire or are explicitly invalidated

### Token Security
- Tokens are generated using cryptographically secure random bytes
- The raw token is base64 encoded for transmission
- Tokens should be transmitted over HTTPS in production
- Store tokens securely on the client side (consider using httpOnly cookies for web apps)

### Token Lifecycle
1. **Generation**: Token is created when user successfully authenticates
2. **Usage**: Token is sent with each API request in the Authorization header
3. **Validation**: Server validates token on each request
4. **Expiration**: Tokens expire based on configured timeout (60 days by default)
5. **Invalidation**: Tokens can be explicitly invalidated via logout

## Error Handling

### Common Error Responses

| Status Code | Error Message | Description |
|-------------|---------------|-------------|
| 401 | "Invalid email or password" | Login credentials are incorrect |
| 401 | "Invalid or expired token" | Token is not valid or has expired |
| 401 | "Invalid token format" | Token is not properly base64 encoded |
| 401 | "Authorization header missing or invalid" | Authorization header is missing or malformed |

### Best Practices

1. **Always check response status codes** before processing response data
2. **Handle token expiration gracefully** by redirecting to login
3. **Store tokens securely** and never expose them in logs or URLs
4. **Implement automatic token refresh** if your application requires it
5. **Clear tokens on logout** to prevent unauthorized access

## Integration with Phoenix LiveView

The same token system is used for both API access and web sessions. When a user logs in through the LoginLive component, a session token is generated and stored in the Phoenix session, allowing seamless integration between LiveView pages and API endpoints.

## Testing

You can test the authentication system using the provided cURL examples or by implementing the JavaScript examples in your frontend application. The server runs on `localhost:4001` by default in development.

## Working Example

Here's a complete working example:

1. **Create a test user** (if not exists):
```bash
# This user was created for testing: test@example.com / password123
```

2. **Login and get token**:
```bash
curl -X POST http://localhost:4001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test@example.com", "password": "password123"}}'
```

Response:
```json
{"user":{"id":3,"username":"testuser","email":"test@example.com"},"token":"YOUR_TOKEN_HERE"}
```

3. **Verify token**:
```bash
curl -X GET http://localhost:4001/api/auth/verify \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

4. **Logout (invalidate token)**:
```bash
curl -X DELETE http://localhost:4001/api/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```
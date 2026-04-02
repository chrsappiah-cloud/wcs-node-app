# GeoWCS API Documentation

## Base URL

```
Development:  http://localhost:3000/v1
Staging:      https://api-staging.geowcs.dev/v1
Production:   https://api.geowcs.dev/v1
```

---

## Authentication

All endpoints (except `/health` and auth endpoints) require:

```
Authorization: Bearer <JWT_TOKEN>
```

JWT Token Format:
- Algorithm: HS256
- Expiry: 7 days
- Claims: `{ sub: userId, iat, exp }`

---

## Endpoints

### Auth

#### POST `/auth/phone`
Initiate phone OTP flow.

**Request**:
```json
{
  "phone": "+14155552671"
}
```

**Response** (200):
```json
{
  "success": true,
  "message": "OTP sent to phone"
}
```

**Errors**:
- 400: Invalid phone format (must be E.164)
- 429: Rate limit exceeded

---

#### POST `/auth/phone/verify`
Verify OTP and get JWT.

**Request**:
```json
{
  "phone": "+14155552671",
  "otp": "123456"
}
```

**Response** (200):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 604800,
  "user": {
    "id": "user-123",
    "phone": "+14155552671",
    "subscriptionTier": "Free"
  }
}
```

**Errors**:
- 401: Invalid or expired OTP
- 404: User not found

---

#### POST `/auth/apple`
Authenticate via Apple Sign In.

**Request**:
```json
{
  "identityToken": "eyJraWQiOiI4NmQ1ODdhMyIs..."
}
```

**Response** (200):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 604800,
  "user": {
    "id": "user-456",
    "appleId": "001234.abcd...",
    "subscriptionTier": "Premium"
  }
}
```

**Errors**:
- 401: Invalid identity token
- 403: JWK verification failed

---

#### POST `/auth/google`
Authenticate via Google OAuth.

**Request**:
```json
{
  "accessToken": "ya29.a0AfH..."
}
```

**Response** (200):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 604800,
  "user": {
    "id": "user-789",
    "googleId": "104...@gmail.com",
    "subscriptionTier": "Free"
  }
}
```

**Errors**:
- 401: Invalid access token
- 403: Token validation failed

---

### Circles (Friend Groups)

#### POST `/circles`
Create a new circle.

**Request**:
```json
{
  "name": "Close Friends",
  "description": "My inner circle of trust",
  "maxMembers": 10
}
```

**Response** (201):
```json
{
  "id": "circle-abc123",
  "name": "Close Friends",
  "description": "My inner circle of trust",
  "maxMembers": 10,
  "creatorId": "user-123",
  "memberCount": 1,
  "createdAt": "2026-04-02T17:00:00Z"
}
```

**Errors**:
- 400: Missing required fields
- 401: Unauthorized

---

#### GET `/circles`
List user's circles.

**Response** (200):
```json
{
  "circles": [
    {
      "id": "circle-abc123",
      "name": "Close Friends",
      "memberCount": 5,
      "role": "Creator"
    },
    {
      "id": "circle-def456",
      "name": "Work Team",
      "memberCount": 12,
      "role": "Member"
    }
  ]
}
```

---

#### GET `/circles/:id`
Get circle details.

**Response** (200):
```json
{
  "id": "circle-abc123",
  "name": "Close Friends",
  "description": "My inner circle",
  "creatorId": "user-123",
  "members": [
    {
      "userId": "user-123",
      "name": "John Doe",
      "phone": "+14155552671",
      "role": "Creator",
      "joinedAt": "2026-04-02T17:00:00Z"
    }
  ],
  "createdAt": "2026-04-02T17:00:00Z"
}
```

**Errors**:
- 404: Circle not found
- 403: Access denied

---

#### POST `/circles/:id/members`
Add member to circle.

**Request**:
```json
{
  "userId": "user-456"
}
```

**Response** (201):
```json
{
  "success": true,
  "member": {
    "userId": "user-456",
    "name": "Jane Smith",
    "role": "Member",
    "joinedAt": "2026-04-02T18:00:00Z"
  }
}
```

**Errors**:
- 400: User not found
- 403: Insufficient permissions
- 409: User already in circle

---

### Alerts

#### POST `/alerts`
Submit a geofence alert (arrival/departure).

**Request**:
```json
{
  "circleId": "circle-abc123",
  "geofenceId": "geofence-123",
  "alertType": "arrival",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "metadata": {
    "accuracy": 25.5,
    "speed": 0.0,
    "altitude": 10.2
  }
}
```

**Response** (201):
```json
{
  "id": "alert-xyz789",
  "circleId": "circle-abc123",
  "userId": "user-123",
  "alertType": "arrival",
  "timestamp": "2026-04-02T17:05:30Z",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "status": "delivered"
}
```

**Errors**:
- 400: Invalid alertType (must be 'arrival' or 'departure')
- 401: Unauthorized (invalid JWT)
- 404: Circle not found

---

#### GET `/alerts`
List recent alerts for user's circles.

**Query Parameters**:
- `circleId` (optional): Filter by circle
- `limit` (optional, default: 50): Max results
- `offset` (optional, default: 0): Pagination offset

**Response** (200):
```json
{
  "alerts": [
    {
      "id": "alert-xyz789",
      "circleId": "circle-abc123",
      "userId": "user-123",
      "userName": "John Doe",
      "alertType": "arrival",
      "timestamp": "2026-04-02T17:05:30Z",
      "latitude": 37.7749,
      "longitude": -122.4194
    }
  ],
  "total": 245,
  "offset": 0,
  "limit": 50
}
```

---

#### GET `/alerts/:id`
Get alert details.

**Response** (200):
```json
{
  "id": "alert-xyz789",
  "circleId": "circle-abc123",
  "userId": "user-123",
  "userName": "John Doe",
  "geofenceId": "geofence-123",
  "alertType": "arrival",
  "timestamp": "2026-04-02T17:05:30Z",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "accuracy": 25.5,
  "metadata": {
    "speed": 0.0,
    "altitude": 10.2,
    "heading": 180.5
  }
}
```

**Errors**:
- 404: Alert not found
- 403: Access denied

---

### Health

#### GET `/health`
Service health check.

**Response** (200):
```json
{
  "status": "ok",
  "timestamp": "2026-04-02T17:00:00Z",
  "version": "1.0.0"
}
```

---

## Error Response Format

All errors follow this format:

```json
{
  "statusCode": 400,
  "message": "Invalid request",
  "error": "BadRequest",
  "details": [
    {
      "field": "phone",
      "message": "Invalid E.164 format"
    }
  ]
}
```

### Common Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict |
| 429 | Rate Limited |
| 500 | Internal Error |

---

## Rate Limiting

- Auth endpoints: 5 requests per minute per phone/email
- General endpoints: 100 requests per minute per user
- Alert submission: 10 per minute per user

Response headers include:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1680710400
```

---

## Webhooks (Future)

TBD: Push subscription for real-time alerts

---

## SDK Usage

### Swift (iOS)

```swift
import Foundation

class GeoWCSClient {
    let baseURL = URL(string: "https://api.geowcs.dev/v1")!
    var token: String?
    
    func submitAlert(circleId: String, alertType: String, lat: Double, lon: Double) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("alerts"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "circleId": circleId,
            "alertType": alertType,
            "latitude": lat,
            "longitude": lon
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        let alert = try JSONDecoder().decode(Alert.self, from: data)
        print("✅ Alert submitted: \(alert.id)")
    }
}
```

### TypeScript (Node.js / React)

```typescript
import axios from 'axios';

const geowcsClient = axios.create({
  baseURL: 'https://api.geowcs.dev/v1'
});

geowcsClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('geowcsToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

async function submitAlert(circleId: string, alertType: 'arrival' | 'departure', lat: number, lon: number) {
  const response = await geowcsClient.post('/alerts', {
    circleId,
    alertType,
    latitude: lat,
    longitude: lon
  });
  return response.data;
}
```

---

## Testing

### cURL Examples

**Phone Auth**:
```bash
curl -X POST https://api.geowcs.dev/v1/auth/phone \
  -H "Content-Type: application/json" \
  -d '{"phone": "+14155552671"}'
```

**Submit Alert**:
```bash
curl -X POST https://api.geowcs.dev/v1/alerts \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  -H "Content-Type: application/json" \
  -d '{
    "circleId": "circle-abc123",
    "alertType": "arrival",
    "latitude": 37.7749,
    "longitude": -122.4194
  }'
```

---

## Support

- Slack: #api-support
- Email: api@geowcs.dev
- Docs: https://docs.geowcs.dev

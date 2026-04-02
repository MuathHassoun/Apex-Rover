## Apex Rover Control - API Integration Guide

### MQTT Protocol

#### Topics

**Incoming (App listens to):**
- `robot/status` - Robot state updates
- `robot/battery` - Battery status
- `robot/sensors/#` - All sensor data
- `robot/command_response` - Command acknowledgments

**Outgoing (App publishes to):**
- `robot/control` - Control commands

#### Message Format

**Battery Status:**
```json
{
  "voltage": 12.5,
  "current": 2.3,
  "power": 28.75,
  "percentage": 75,
  "isCharging": false,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Robot Status:**
```json
{
  "isPoweredOn": true,
  "isCharging": false,
  "robotMode": "idle",
  "robotType": "wheeled",
  "lastUpdate": "2024-01-15T10:30:00Z"
}
```

**Sensor Data:**
```json
{
  "sensorId": "temp_01",
  "sensorName": "Temperature Sensor",
  "sensorType": "temperature",
  "value": 35.5,
  "unit": "°C",
  "isActive": true,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Control Command:**
```json
{
  "commandId": "cmd_001",
  "commandType": "move_forward",
  "parameters": {
    "speed": 50,
    "duration": 5000
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### WebSocket Protocol

#### Message Types

**Connection:**
```json
{
  "type": "connect",
  "clientId": "mobile_client_001",
  "version": "1.0"
}
```

**Status Update:**
```json
{
  "type": "status",
  "data": { ... }
}
```

**Command:**
```json
{
  "type": "command",
  "data": { ... }
}
```

**Response:**
```json
{
  "type": "response",
  "commandId": "cmd_001",
  "status": "success",
  "data": { ... }
}
```

### HTTP Endpoints (Future Enhancement)

```
POST /api/robot/connect
GET  /api/robot/status
POST /api/robot/command
GET  /api/sensors
GET  /api/battery
POST /api/logs
```

### Error Handling

The app handles common errors:
- `CONNECTION_FAILED` - Cannot connect to broker/server
- `TIMEOUT` - No response within timeout period
- `INVALID_DATA` - Malformed JSON or invalid data
- `COMMAND_REJECTED` - Robot rejected command
- `DATABASE_ERROR` - Local storage error

### Testing with Mosquitto

Install Mosquitto:
```bash
# macOS
brew install mosquitto

# Linux
sudo apt-get install mosquitto mosquitto-clients

# Windows
# Download from https://mosquitto.org/download/
```

Start broker:
```bash
mosquitto
```

Subscribe to topics (in another terminal):
```bash
mosquitto_sub -h localhost -t 'robot/+' -v
```

Publish test message:
```bash
mosquitto_pub -h localhost -t 'robot/battery' -m '{
  "voltage": 12.5,
  "current": 2.3,
  "power": 28.75,
  "percentage": 75,
  "isCharging": false,
  "timestamp": "2024-01-15T10:30:00Z"
}'
```

### Security Considerations

- Use TLS/SSL for MQTT (port 8883)
- Use WSS for WebSocket (secure WebSocket)
- Implement authentication tokens
- Validate all incoming data
- Rate limit commands
- Use connection timeouts
- Implement automatic disconnect on auth failure

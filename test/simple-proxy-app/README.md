# Nginx Proxy Example

This example demonstrates how to use the nginx buildpack in **proxy mode** to serve requests through nginx to an application server.

## How it works

1. **App Server**: The `app.sh` script acts as a mock application server that:
   - Listens on a Unix socket at `/tmp/nginx.socket`
   - Creates `/tmp/app-initialized` file when ready to signal nginx
   - Responds with a JSON message for demonstration

2. **Nginx Proxy**: The nginx buildpack:
   - Detects the app (via `nginx` in `Procfile`)
   - Starts the app server first
   - Waits for the `/tmp/app-initialized` signal
   - Starts nginx to proxy requests to the app server

3. **Request Flow**:
   ```
   Client Request → Nginx (port 5000) → App Server (Unix socket) → Response
   ```

## Files

- `Procfile`: `web: start-nginx ./app.sh` - Uses `start-nginx` command with app server
- `app.sh`: Mock application server that listens on Unix socket
- `package.json`: Example package.json (for demonstration, not used in this mock)
- `server.js`: Example Node.js server (alternative to app.sh)

## Testing

Build and run the container:

```bash
pack build nginx-proxy-test --buildpack . --builder heroku/builder:24 --path test/simple-proxy-app
docker run -p 8080:5000 nginx-proxy-test
```

Test the proxy:

```bash
curl http://localhost:8080/
# Response: {"message":"Hello from mock app behind nginx!","timestamp":"..."}
```

## Real-world Usage

In a real application, replace `app.sh` with your actual application server command:

### Node.js with Express
```
web: start-nginx npm start
```

### Ruby with Unicorn
```
web: start-nginx bundle exec unicorn -c config/unicorn.rb
```

### Python with Gunicorn
```
web: start-nginx gunicorn app:application
```

### Go Application
```
web: start-nginx ./my-go-app
```

## Requirements for App Server

Your application server must:

1. **Listen on Unix socket** at `/tmp/nginx.socket`
2. **Create signal file** `/tmp/app-initialized` when ready
3. **Handle graceful shutdown** when receiving SIGTERM/SIGINT

## Benefits of Nginx Proxy

- **Performance**: Nginx efficiently handles static assets and connection pooling
- **SSL Termination**: Nginx can handle HTTPS and forward HTTP to app
- **Load Balancing**: Can proxy to multiple app server instances
- **Request Buffering**: Nginx buffers slow client uploads
- **Security**: Additional layer for request filtering and rate limiting

## Environment Variables

- `NGINX_WORKERS`: Number of nginx worker processes (default: 1)
- `NGINX_WORKER_CONNECTIONS`: Connections per worker (default: 1024)
- `PORT`: Port for nginx to listen on (default: 5000)
- `NGINX_ACCESS_LOG_PATH`: Access log destination (default: /dev/stdout)
- `NGINX_ERROR_LOG_PATH`: Error log destination (default: /dev/stderr)
- `NGINX_IPV6_ONLY`: Set to "true" for IPv6-only platforms (default: false)

## IPv6-Only Deployment

For IPv6-only platforms, set the environment variable:

```bash
# Build with IPv6-only configuration
docker run -p 8080:5000 -e NGINX_IPV6_ONLY=true nginx-proxy-test

# Or set in your platform configuration
NGINX_IPV6_ONLY=true
```

This configures nginx to:
- Listen only on IPv6 addresses
- Use IPv6 DNS resolvers
- Optimize for IPv6-only environments
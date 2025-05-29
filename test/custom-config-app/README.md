# Custom Nginx Configuration Example

This example demonstrates how to use a custom `config/nginx.conf.erb` file with the nginx buildpack to implement advanced nginx features and configurations.

## 🚀 Features Demonstrated

### 1. **Rate Limiting**
- API endpoints: 10 requests/second with burst of 20
- Login endpoint: 1 request/second with burst of 5
- Returns 429 status when limits exceeded

### 2. **CORS Support**
- Configurable CORS headers for API endpoints
- Proper handling of preflight OPTIONS requests
- Support for custom origins via environment variables

### 3. **Security Headers**
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Custom application headers

### 4. **IP-based Access Control**
- Admin section restricted to private networks
- Configurable allowed IP ranges
- Automatic 403 responses for unauthorized IPs

### 5. **Multiple Server Blocks**
- Main application server
- Dedicated API subdomain configuration
- Different configurations per virtual host

### 6. **Advanced Caching**
- 1-year cache for static assets (CSS, JS, images)
- No-cache headers for HTML files
- Font-specific CORS headers

### 7. **Custom Logging**
- Enhanced log format with timing information
- Upstream connection and response times
- Request processing metrics

### 8. **SPA Routing Support**
- Fallback to index.html for client-side routing
- Proper handling of 404s for single-page applications

## 📁 File Structure

```
test/custom-config-app/
├── config/
│   └── nginx.conf.erb          # Custom nginx configuration template
├── public/
│   ├── index.html              # Main demo page with feature tests
│   └── admin/
│       └── index.html          # IP-restricted admin area
├── Procfile                    # Process definition
└── README.md                   # This file
```

## 🔧 Environment Variables

The custom nginx.conf.erb supports these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_NAME` | `nginx-buildpack-demo` | Custom app name in headers |
| `CORS_ORIGIN` | `*` | CORS allowed origin |
| `MAX_UPLOAD_SIZE` | `50m` | Maximum upload size |
| `SERVER_NAME` | `_` | Server name for virtual hosts |

Plus all standard nginx buildpack variables:
- `NGINX_WORKERS`
- `NGINX_WORKER_CONNECTIONS`
- `NGINX_ACCESS_LOG_PATH`
- `NGINX_ERROR_LOG_PATH`
- `PORT`

## 🏗️ Building and Running

### Build the image:
```bash
pack build custom-config-test \
  --buildpack . \
  --builder heroku/builder:24 \
  --path test/custom-config-app
```

### Run with default settings:
```bash
docker run -p 8080:5000 custom-config-test
```

### Run with custom environment variables:
```bash
docker run -p 8080:5000 \
  -e APP_NAME="My Custom App" \
  -e CORS_ORIGIN="https://mydomain.com" \
  -e MAX_UPLOAD_SIZE="100m" \
  custom-config-test
```

## 🧪 Testing the Features

Once running, visit http://localhost:8080 to access the interactive demo page.

### Manual testing:

```bash
# Test health endpoint
curl http://localhost:8080/health

# Test API with rate limiting
for i in {1..15}; do curl http://localhost:8080/api/test; done

# Test CORS preflight
curl -X OPTIONS \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type" \
  http://localhost:8080/api/cors-test

# Check security headers
curl -I http://localhost:8080/

# Test admin area (should work from localhost)
curl http://localhost:8080/admin/

# Test login rate limiting
for i in {1..10}; do curl http://localhost:8080/login; done
```

## 📊 Nginx Configuration Highlights

### Rate Limiting Zones
```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
```

### Security and CORS Headers
```nginx
add_header X-Custom-App "<%= ENV['APP_NAME'] || 'nginx-buildpack-demo' %>" always;
add_header 'Access-Control-Allow-Origin' '<%= ENV["CORS_ORIGIN"] || "*" %>';
```

### IP Restrictions
```nginx
location /admin/ {
    allow 127.0.0.1;
    allow 10.0.0.0/8;
    allow 172.16.0.0/12;
    allow 192.168.0.0/16;
    deny all;
}
```

### Custom Logging
```nginx
log_format custom '$remote_addr - $remote_user [$time_local] '
                 '"$request" $status $body_bytes_sent '
                 'rt=$request_time uct="$upstream_connect_time"';
```

## 🎯 Use Cases

This configuration pattern is ideal for:

- **API Gateways**: Rate limiting and CORS for API services
- **Single Page Applications**: SPA routing with fallback support
- **Admin Dashboards**: IP-restricted management interfaces
- **Static Sites with APIs**: Mixed static/dynamic content serving
- **Security-focused Applications**: Enhanced headers and access controls
- **Multi-tenant Applications**: Virtual host configurations

## 🔗 Related Examples

- [Simple Static App](../simple-static-app/) - Basic static file serving
- [Simple Proxy App](../simple-proxy-app/) - Reverse proxy configuration

## 📚 ERB Template Processing

The buildpack includes simple ERB processing that supports:
- Environment variable substitution
- Default value fallbacks
- Standard nginx buildpack variables

Template syntax:
```erb
<%= ENV["VARIABLE_NAME"] || "default_value" %>
```

This gets processed at container startup to generate the final nginx configuration.
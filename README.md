# Nginx Cloud Native Buildpack

A [Cloud Native Buildpack](https://buildpacks.io) for nginx web server that provides both static file serving and reverse proxy capabilities.

## Features

- **Static file serving** - Perfect for SPAs, JAMstack sites, and static websites
- **Reverse proxy mode** - Run nginx in front of your application server
- **ARM64 support** - Optimized for Heroku's heroku/buildpacks:24 stack
- **Customizable configuration** - Support for custom nginx.conf.erb templates
- **Modern defaults** - Gzip compression, security headers, and performance optimizations
- **Health checks** - Built-in `/health` endpoint
- **Environment-based configuration** - Configure workers, connections, and log paths via env vars

## Supported Stacks

- `heroku/buildpacks:24` (Ubuntu 24.04)
- Architecture: `arm64` (primary), `amd64` (for local development)

## Quick Start

### Static File Serving

For serving static files (SPAs, JAMstack sites):

```bash
# In your app directory
echo 'web: start-nginx-static' > Procfile

# Deploy your app
# The buildpack will automatically detect static files and serve them
```

### Reverse Proxy Mode

For running nginx in front of an application server:

```bash
# In your app directory
echo 'web: start-nginx your-app-server-command' > Procfile

# Example with a Ruby app:
echo 'web: start-nginx bundle exec puma -C config/puma.rb' > Procfile
```

## Detection

The buildpack will detect your app if any of the following conditions are met:

- `config/nginx.conf.erb` file exists
- `static.json` file exists
- `Procfile` contains "nginx"
- Common static file directories exist (`public`, `dist`, `build`, `www`)
- `package.json` contains a "build" script (indicating a frontend app)

## Usage Modes

### 1. Static File Mode

Best for: SPAs, static websites, JAMstack applications

```bash
# Procfile
web: start-nginx-static
```

The buildpack will automatically detect your static files directory:
- `public/` (first choice)
- `dist/` (common for build tools)
- `build/` (common for React apps)
- `www/` (alternative)
- Root directory (fallback)

### 2. Proxy Mode

Best for: Running nginx in front of application servers

```bash
# Procfile
web: start-nginx <your-app-command>

# Examples:
web: start-nginx bundle exec puma -C config/puma.rb
web: start-nginx node server.js
web: start-nginx python app.py
```

**Important**: Your application server must:
1. Listen on Unix socket `/tmp/nginx.socket`
2. Create file `/tmp/app-initialized` when ready to receive traffic

#### Example: Ruby with Puma

```ruby
# config/puma.rb
bind 'unix:///tmp/nginx.socket'

on_worker_boot do
  FileUtils.touch('/tmp/app-initialized')
end
```

#### Example: Node.js

```javascript
// server.js
const express = require('express');
const fs = require('fs');
const app = express();

const server = app.listen('/tmp/nginx.socket', () => {
  // Signal that app is ready
  fs.writeFileSync('/tmp/app-initialized', '');
  console.log('Server ready');
});
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NGINX_VERSION` | `1.26.2` | Nginx version to install |
| `NGINX_WORKERS` | `1` | Number of worker processes |
| `NGINX_WORKER_CONNECTIONS` | `1024` | Max connections per worker |
| `NGINX_ACCESS_LOG_PATH` | `/dev/stdout` | Access log destination |
| `NGINX_ERROR_LOG_PATH` | `/dev/stderr` | Error log destination |
| `NGINX_ROOT` | `/workspace` | Document root for static mode |

### Custom Configuration

You can provide your own nginx configuration by creating `config/nginx.conf.erb`:

```bash
# Copy a template to get started
copy-config static   # For static file serving
copy-config proxy    # For reverse proxy mode

# Edit the generated config/nginx.conf.erb file
```

The configuration file supports ERB templating with environment variables:

```nginx
# config/nginx.conf.erb
worker_processes <%= ENV['NGINX_WORKERS'] || 1 %>;

server {
    listen <%= ENV['PORT'] || 5000 %>;
    root <%= ENV['DOCUMENT_ROOT'] || '/workspace/public' %>;

    # Your custom configuration here
}
```

### Static Configuration (static.json)

For static sites, you can use `static.json` for additional configuration:

```json
{
  "root": "dist/",
  "clean_urls": true,
  "https_only": true,
  "headers": {
    "/**": {
      "X-Frame-Options": "DENY"
    }
  }
}
```

## Examples

### React Application

```bash
# package.json build script creates files in build/
echo 'web: start-nginx-static' > Procfile
```

### Vue.js Application

```bash
# Vue CLI creates files in dist/
echo 'web: start-nginx-static' > Procfile
```

### Ruby on Rails API + React Frontend

```bash
# Serve React build files, proxy API requests to Rails
echo 'web: start-nginx bundle exec rails server' > Procfile

# config/nginx.conf.erb
server {
    listen <%= ENV['PORT'] || 5000 %>;
    root /workspace/public;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to Rails
    location /api {
        proxy_pass http://unix:/tmp/nginx.socket;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Node.js Express App

```bash
echo 'web: start-nginx node server.js' > Procfile
```

```javascript
// server.js
const express = require('express');
const fs = require('fs');
const app = express();

// Your Express routes here
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from Express!' });
});

// Listen on Unix socket for nginx
const server = app.listen('/tmp/nginx.socket', () => {
  fs.writeFileSync('/tmp/app-initialized', '');
  console.log('Express server ready for nginx');
});
```

## Building and Testing

### Local Testing

```bash
# Test the buildpack locally
pack build my-nginx-app --buildpack . --builder heroku/builder:24

# Run the resulting image
docker run -p 8080:5000 my-nginx-app
```

### Custom Builds

You can customize the nginx installation by modifying the build script or providing build-time environment variables.

## Troubleshooting

### Common Issues

1. **App server not starting**: Ensure your app creates `/tmp/app-initialized` when ready
2. **Connection refused**: Check that your app listens on `/tmp/nginx.socket`
3. **Static files not found**: Verify your static files are in `public/`, `dist/`, `build/`, or `www/`
4. **Configuration errors**: Check nginx error logs via `NGINX_ERROR_LOG_PATH`

### Debug Mode

Enable verbose logging:

```bash
# Set environment variables
NGINX_ERROR_LOG_PATH=/dev/stderr
NGINX_ACCESS_LOG_PATH=/dev/stdout
```

### Health Checks

The buildpack provides a health check endpoint at `/health` that returns `200 OK`.

## Security

The buildpack includes several security features:

- Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- Denial of access to sensitive files (dotfiles, backup files)
- Optional HTTPS enforcement
- Request size limits

## Performance

Default optimizations include:

- Gzip compression for text files
- Static asset caching with appropriate headers
- Efficient file serving with sendfile
- Connection pooling and keep-alive

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `pack build`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Related

- [Cloud Native Buildpacks](https://buildpacks.io)
- [Heroku Buildpacks](https://devcenter.heroku.com/articles/buildpacks)
- [Nginx Documentation](https://nginx.org/en/docs/)
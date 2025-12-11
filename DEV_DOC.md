# Developer Documentation

This document provides technical information for developers who want to set up, build, modify, or understand the Inception project infrastructure.

## Table of Contents

1. [Environment Setup from Scratch](#environment-setup-from-scratch)
2. [Configuration Files and Secrets](#configuration-files-and-secrets)
3. [Building and Launching with Makefile](#building-and-launching-with-makefile)
4. [Docker Compose Management](#docker-compose-management)
5. [Container Management Commands](#container-management-commands)
6. [Volume Management and Data Persistence](#volume-management-and-data-persistence)
7. [Architecture Deep Dive](#architecture-deep-dive)
8. [Development Workflow](#development-workflow)
9. [Debugging and Testing](#debugging-and-testing)
10. [Extending the Project](#extending-the-project)

---

## Environment Setup from Scratch

### Prerequisites Installation

**System Requirements:**
- Linux-based OS (Ubuntu 20.04+, Debian 11+, or similar)
- Minimum 2GB RAM
- 10GB free disk space
- Sudo/root access

**Install Docker:**
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Verify installation
docker --version
```

**Install Docker Compose:**
```bash
# Docker Compose is included with Docker Desktop
# For Linux, install the plugin:
sudo apt-get install -y docker-compose-plugin

# Verify installation
docker compose version
```

**Post-Installation Setup:**
```bash
# Add your user to the docker group (avoid sudo for docker commands)
sudo usermod -aG docker $USER

# Activate the changes
newgrp docker

# Test Docker without sudo
docker run hello-world
```

**Install Make:**
```bash
sudo apt-get install -y make

# Verify installation
make --version
```

### Initial Project Setup

**1. Clone the Repository:**
```bash
git clone <repository-url> inception
cd inception
```

**2. Verify Project Structure:**
```bash
tree -L 3
```

Expected structure:
```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

**3. Set Up Environment Variables:**

Each service requires a `.env` file. Create them from examples:

```bash
# NGINX
cd srcs/requirements/nginx
cp .env.example .env
nano .env  # Edit DOMAIN_NAME if needed

# WordPress
cd ../wordpress
cp .env.example .env
nano .env  # Edit passwords and credentials

# MariaDB
cd ../mariadb
cp .env.example .env
nano .env  # Edit passwords (must match WordPress DB password)

# Return to project root
cd ../../..
```

**4. Update Configuration for Your Environment:**

Edit `srcs/docker-compose.yml`:
```yaml
volumes:
  wordpress:
    driver_opts:
      device: /home/<your_login>/data/wordpress  # Change this
  mariadb:
    driver_opts:
      device: /home/<your_login>/data/mariadb    # Change this
```

Edit `Makefile`:
```makefile
DATA_DIR = /home/<your_login>/data  # Change this

hosts:
    # Update domain name if needed
    echo "127.0.0.1 <your_login>.42.fr" | sudo tee -a /etc/hosts
```

**5. Set File Permissions:**
```bash
# Make scripts executable
chmod +x srcs/requirements/nginx/start-nginx.sh
chmod +x srcs/requirements/wordpress/setup-wordpress.sh
chmod +x srcs/requirements/mariadb/init-mariadb.sh

# Secure environment files
chmod 600 srcs/requirements/*/.env
```

**6. Add Domain to Hosts File:**
```bash
make hosts
```

This adds your domain (e.g., `fdorea.42.fr`) to `/etc/hosts` pointing to `127.0.0.1`.

---

## Configuration Files and Secrets

### Environment Variable Files

**Purpose:** Store service-specific configuration and credentials.

**Location Pattern:**
```
srcs/requirements/<service>/.env
```

### NGINX Configuration

**File:** `srcs/requirements/nginx/.env`

```bash
# Domain name for SSL certificate and server configuration
DOMAIN_NAME=fdorea.42.fr
```

**Used by:**
- SSL certificate generation (`start-nginx.sh`)
- NGINX server block configuration (`wordpress-https.conf`)

### WordPress Configuration

**File:** `srcs/requirements/wordpress/.env`

```bash
# Database connection settings
WORDPRESS_DB_HOST=mariadb:3306      # Docker service name:port
WORDPRESS_DB_NAME=wordpress          # Database name
WORDPRESS_DB_USER=wpuser            # Database username
WORDPRESS_DB_PASSWORD=secure_pass   # Must match MYSQL_PASSWORD in mariadb/.env

# WordPress admin user
WORDPRESS_ADMIN_USER=fdorea_admin
WORDPRESS_ADMIN_PASSWORD=admin_secure_pass
WORDPRESS_ADMIN_EMAIL=admin@fdorea.42.fr

# WordPress additional user (editor role)
WORDPRESS_USER=wpeditor
WORDPRESS_USER_PASSWORD=editor_secure_pass
WORDPRESS_USER_EMAIL=editor@fdorea.42.fr

# Site configuration
WORDPRESS_TITLE=Inception WordPress
WORDPRESS_URL=https://fdorea.42.fr
```

**Critical Rules:**
- `WORDPRESS_DB_PASSWORD` MUST match `MYSQL_PASSWORD` in `mariadb/.env`
- `WORDPRESS_DB_USER` MUST match `MYSQL_USER` in `mariadb/.env`
- `WORDPRESS_DB_NAME` MUST match `MYSQL_DATABASE` in `mariadb/.env`
- `WORDPRESS_DB_HOST` uses Docker service name (not IP address)

### MariaDB Configuration

**File:** `srcs/requirements/mariadb/.env`

```bash
# Root user password (administrative access)
MYSQL_ROOT_PASSWORD=root_secure_pass

# WordPress database configuration
MYSQL_DATABASE=wordpress          # Must match WORDPRESS_DB_NAME
MYSQL_USER=wpuser                # Must match WORDPRESS_DB_USER
MYSQL_PASSWORD=secure_pass       # Must match WORDPRESS_DB_PASSWORD
```

### Configuration File Reference

| File | Purpose | Key Variables |
|------|---------|---------------|
| `nginx/.env` | Domain configuration | `DOMAIN_NAME` |
| `wordpress/.env` | WP and DB connection | `WORDPRESS_DB_*`, `WORDPRESS_ADMIN_*` |
| `mariadb/.env` | Database setup | `MYSQL_ROOT_PASSWORD`, `MYSQL_*` |
| `nginx/wordpress-https.conf` | NGINX server block | Server name, FastCGI proxy |
| `wordpress/php-fpm-pool.conf` | PHP-FPM pool config | Listen address, process manager |
| `mariadb/mariadb-network.cnf` | MariaDB network | Bind address, port |

### Secret Management Best Practices

**Development Environment:**
- Use `.env` files (already in `.gitignore`)
- Store sensitive `.env` files outside version control
- Use different passwords for each environment

**Production Environment:**
- Use Docker Secrets instead of environment variables
- Implement secret rotation policies
- Use external secret management (HashiCorp Vault, AWS Secrets Manager)

**Example Docker Secrets Implementation (for future):**
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
  wp_admin_password:
    file: ./secrets/wp_admin_password.txt

services:
  wordpress:
    secrets:
      - db_password
      - wp_admin_password
```

---

## Building and Launching with Makefile

### Makefile Structure

The Makefile provides automation for common Docker operations.

**Variables:**
```makefile
DATA_DIR = /home/fdorea/data     # Base directory for persistent data
WP_DIR = $(DATA_DIR)/wordpress   # WordPress files location
DB_DIR = $(DATA_DIR)/mariadb     # MariaDB data location
```

### Make Targets Reference

#### Primary Targets

**`make all` (default):**
```bash
make all
```
- Creates data directories (`dirs` target)
- Checks for domain in `/etc/hosts`
- Builds Docker images
- Starts containers in detached mode
- Displays access URL

**Equivalent to:**
```bash
make dirs
docker compose -f ./srcs/docker-compose.yml up --build -d
```

#### Data Directory Management

**`make dirs`:**
```bash
make dirs
```
Creates required data directories:
- `/home/fdorea/data/wordpress`
- `/home/fdorea/data/mariadb`

**Implementation:**
```makefile
dirs:
    @mkdir -p $(WP_DIR)
    @mkdir -p $(DB_DIR)
```

#### Container Lifecycle

**`make up`:**
```bash
make up
```
- Builds images (only if Dockerfile changed)
- Creates and starts containers
- Creates networks and volumes
- Runs in detached mode

**`make down`:**
```bash
make down
```
- Stops containers
- Removes containers
- Removes network
- Preserves volumes and images

**`make start`:**
```bash
make start
```
- Starts existing containers (no rebuild)
- Fast restart after `make stop`

**`make stop`:**
```bash
make stop
```
- Stops containers gracefully
- Does not remove containers
- Data remains intact

#### Cleanup Targets

**`make clean`:**
```bash
make clean
```
- Executes `make down`
- Removes volumes (`-v` flag)
- Prunes unused Docker objects
- Preserves images

**Equivalent to:**
```bash
docker compose -f ./srcs/docker-compose.yml down -v
docker system prune -f
```

**`make fclean` (Full Clean):**
```bash
make fclean
```
- Executes `make down`
- Removes volumes
- Removes all built images (`--rmi all`)
- Removes data directories
- Complete system cleanup

**Equivalent to:**
```bash
docker compose -f ./srcs/docker-compose.yml down -v --rmi all
docker system prune -af --volumes
sudo rm -rf /home/fdorea/data
```

**`make re` (Rebuild):**
```bash
make re
```
- Executes `make fclean`
- Executes `make all`
- Complete fresh installation

#### Utility Targets

**`make hosts`:**
```bash
make hosts
```
- Checks if domain exists in `/etc/hosts`
- Adds domain if not present (requires sudo)
- Prevents duplicate entries

**`make logs`:**
```bash
make logs
```
- Shows logs from all containers
- Follow mode (real-time updates)
- Press `Ctrl+C` to exit

**Equivalent to:**
```bash
docker compose -f ./srcs/docker-compose.yml logs -f
```

**`make status`:**
```bash
make status
```
- Lists all containers with status
- Lists WordPress and MariaDB volumes
- Useful for health checks

**`make help`:**
```bash
make help
```
Displays all available targets with descriptions.

### Build Process Flow

```
make all
    │
    ├─> make dirs
    │   └─> mkdir -p /home/fdorea/data/{wordpress,mariadb}
    │
    ├─> Check /etc/hosts
    │   └─> Warn if domain not found
    │
    └─> docker compose up --build -d
        │
        ├─> Build nginx:42
        │   ├─> FROM debian:bookworm
        │   ├─> Install nginx, openssl
        │   ├─> Copy configuration files
        │   └─> Set entrypoint
        │
        ├─> Build wordpress:42
        │   ├─> FROM debian:bookworm
        │   ├─> Install PHP 8.2 + extensions
        │   ├─> Install WP-CLI
        │   └─> Set entrypoint
        │
        ├─> Build mariadb:42
        │   ├─> FROM debian:bookworm
        │   ├─> Install MariaDB
        │   └─> Set entrypoint
        │
        ├─> Create network: inception (bridge)
        │
        ├─> Create volumes: wordpress, mariadb
        │
        └─> Start containers:
            1. mariadb (no dependencies)
            2. wordpress (depends_on: mariadb)
            3. nginx (depends_on: wordpress)
```

---

## Docker Compose Management

### Docker Compose File Structure

**Location:** `srcs/docker-compose.yml`

**Version:** Compose file format v3.8+ (no explicit version needed)

### Service Definitions

#### NGINX Service

```yaml
services:
  nginx:
    build: ./requirements/nginx/.         # Build context
    container_name: nginx                 # Fixed container name
    depends_on:                           # Start order
      - wordpress
    env_file: ./requirements/nginx/.env   # Environment variables
    image: nginx:42                       # Image tag
    networks:                             # Network attachment
      - inception
    ports:                                # Port mapping
      - "443:443"                         # Host:Container
    restart: unless-stopped               # Restart policy
    volumes:                              # Volume mounts
      - wordpress:/var/www/html
```

**Key Points:**
- Only service exposing ports to host
- Depends on WordPress (waits for it to start)
- Shares WordPress volume (read-only access to files)
- TLS/SSL termination happens here

#### WordPress Service

```yaml
services:
  wordpress:
    build: ./requirements/wordpress/.
    container_name: wordpress
    depends_on:
      - mariadb
    env_file: ./requirements/wordpress/.env
    image: wordpress:42
    networks:
      - inception
    restart: unless-stopped
    volumes:
      - wordpress:/var/www/html
```

**Key Points:**
- No exposed ports (internal communication only)
- Depends on MariaDB (waits for it to start)
- PHP-FPM listens on port 9000 internally
- Mounts WordPress volume (read-write)

#### MariaDB Service

```yaml
services:
  mariadb:
    build: ./requirements/mariadb/.
    container_name: mariadb
    env_file: ./requirements/mariadb/.env
    image: mariadb:42
    networks:
      - inception
    restart: unless-stopped
    volumes:
      - mariadb:/var/lib/mysql
```

**Key Points:**
- No dependencies (starts first)
- No exposed ports (internal only)
- MySQL protocol on port 3306 internally
- Mounts MariaDB volume for data persistence

### Network Configuration

```yaml
networks:
  inception:
    driver: bridge
```

**Driver: bridge**
- Default Docker network driver
- Enables container-to-container communication
- Provides DNS resolution by service name
- Isolates containers from external networks

**DNS Resolution:**
```bash
# Inside WordPress container
ping mariadb          # Resolves to MariaDB container IP
mysql -h mariadb -u wpuser -p  # Connects via service name
```

### Volume Configuration

```yaml
volumes:
  wordpress:
    name: wordpress
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/fdorea/data/wordpress
  
  mariadb:
    name: mariadb
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/fdorea/data/mariadb
```

**Hybrid Approach Explanation:**
- Uses Docker volume interface (`docker volume ls`)
- Stores data at predictable host paths
- Combines benefits of both volumes and bind mounts
- Data persists across container recreations

### Docker Compose Commands

**Build images without starting:**
```bash
docker compose -f srcs/docker-compose.yml build
```

**Build specific service:**
```bash
docker compose -f srcs/docker-compose.yml build nginx
```

**Start in foreground (see logs):**
```bash
docker compose -f srcs/docker-compose.yml up
```

**Start in detached mode:**
```bash
docker compose -f srcs/docker-compose.yml up -d
```

**Force rebuild:**
```bash
docker compose -f srcs/docker-compose.yml up --build --force-recreate
```

**Scale service (if no container_name set):**
```bash
docker compose -f srcs/docker-compose.yml up -d --scale wordpress=3
```

**View service logs:**
```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
```

**Execute command in service:**
```bash
docker compose -f srcs/docker-compose.yml exec wordpress bash
```

**List services:**
```bash
docker compose -f srcs/docker-compose.yml ps
```

**Stop and remove:**
```bash
docker compose -f srcs/docker-compose.yml down
```

**Remove with volumes:**
```bash
docker compose -f srcs/docker-compose.yml down -v
```

---

## Container Management Commands

### Direct Docker Commands

**List all containers:**
```bash
docker ps -a
```

**Start/stop specific container:**
```bash
docker start nginx
docker stop nginx
```

**Restart container:**
```bash
docker restart nginx
```

**Remove container:**
```bash
docker rm nginx           # Must be stopped first
docker rm -f nginx        # Force remove (even if running)
```

### Accessing Containers

**Interactive shell:**
```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

**Single command execution:**
```bash
docker exec nginx ls -la /etc/nginx
docker exec wordpress wp --info --allow-root
docker exec mariadb mysql --version
```

**Run as specific user:**
```bash
docker exec -u www-data wordpress whoami
```

### Container Inspection

**View container details:**
```bash
docker inspect nginx
```

**View specific property:**
```bash
docker inspect nginx | jq '.[0].NetworkSettings.IPAddress'
docker inspect nginx | grep IPAddress
```

**View resource usage:**
```bash
docker stats
docker stats nginx wordpress mariadb
```

**View processes in container:**
```bash
docker top nginx
```

### Log Management

**View all logs:**
```bash
docker logs nginx
```

**Follow logs (live):**
```bash
docker logs -f nginx
```

**Last N lines:**
```bash
docker logs --tail 100 nginx
```

**Since timestamp:**
```bash
docker logs --since 2023-01-01T00:00:00 nginx
```

**With timestamps:**
```bash
docker logs -t nginx
```

### Image Management

**List images:**
```bash
docker images
docker images | grep 42
```

**Remove image:**
```bash
docker rmi nginx:42
docker rmi -f nginx:42  # Force remove
```

**View image history:**
```bash
docker history nginx:42
```

**Inspect image:**
```bash
docker inspect nginx:42
```

**Prune unused images:**
```bash
docker image prune       # Dangling images
docker image prune -a    # All unused images
```

---

## Volume Management and Data Persistence

### Understanding Data Storage

**Container Filesystem:**
- Ephemeral (lost when container is removed)
- Stored in Docker's internal storage
- Fast but not persistent

**Volumes:**
- Persistent storage outside container filesystem
- Managed by Docker
- Survive container removal
- Can be shared between containers

### Volume Locations

**Bind Mount Paths (as configured):**
```
/home/fdorea/data/
├── wordpress/           # WordPress files
│   ├── wp-admin/
│   ├── wp-content/
│   │   ├── plugins/
│   │   ├── themes/
│   │   └── uploads/
│   ├── wp-includes/
│   ├── wp-config.php
│   └── index.php
│
└── mariadb/             # MariaDB data
    ├── mysql/           # System database
    ├── wordpress/       # WordPress database
    ├── ibdata1          # InnoDB data file
    └── ib_logfile*      # Transaction logs
```

### Volume Commands

**List volumes:**
```bash
docker volume ls
docker volume ls | grep -E "wordpress|mariadb"
```

**Inspect volume:**
```bash
docker volume inspect wordpress
docker volume inspect mariadb
```

**Output example:**
```json
[
    {
        "CreatedAt": "2023-12-01T10:00:00Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/wordpress/_data",
        "Name": "wordpress",
        "Options": {
            "device": "/home/fdorea/data/wordpress",
            "o": "bind",
            "type": "none"
        },
        "Scope": "local"
    }
]
```

**Remove volume:**
```bash
docker volume rm wordpress      # Must stop containers first
docker volume rm -f wordpress   # Force remove
```

**Prune unused volumes:**
```bash
docker volume prune
```

### Data Persistence Verification

**Check WordPress data:**
```bash
ls -la /home/fdorea/data/wordpress/
```

**Check MariaDB data:**
```bash
sudo ls -la /home/fdorea/data/mariadb/
```

**Verify data persists across restarts:**
```bash
# 1. Create test post in WordPress
# 2. Stop containers
make down

# 3. Data still exists
ls /home/fdorea/data/wordpress/wp-content/uploads/

# 4. Restart
make up

# 5. Test post still visible
```

### Backup and Restore

**Backup WordPress:**
```bash
# Files backup
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz /home/fdorea/data/wordpress/

# Database backup
docker exec mariadb mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" wordpress > wordpress-db-$(date +%Y%m%d).sql
```

**Restore WordPress:**
```bash
# Stop containers
make down

# Restore files
tar -xzf wordpress-backup-20231201.tar.gz -C /

# Start containers
make up

# Restore database
cat wordpress-db-20231201.sql | docker exec -i mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" wordpress
```

**Automated backup script:**
```bash
#!/bin/bash
BACKUP_DIR="/home/fdorea/backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup WordPress files
tar -czf "$BACKUP_DIR/wordpress-$DATE.tar.gz" /home/fdorea/data/wordpress/

# Backup MariaDB
docker exec mariadb mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --all-databases > "$BACKUP_DIR/mariadb-$DATE.sql"

# Keep only last 7 days
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
```

### Volume Troubleshooting

**Permission issues:**
```bash
# Check ownership
ls -la /home/fdorea/data/wordpress/

# Fix WordPress permissions
sudo chown -R www-data:www-data /home/fdorea/data/wordpress/
sudo find /home/fdorea/data/wordpress/ -type d -exec chmod 755 {} \;
sudo find /home/fdorea/data/wordpress/ -type f -exec chmod 644 {} \;

# Fix MariaDB permissions
sudo chown -R 999:999 /home/fdorea/data/mariadb/
sudo chmod 750 /home/fdorea/data/mariadb/
```

**Disk space issues:**
```bash
# Check disk usage
df -h /home/fdorea/data/
du -sh /home/fdorea/data/*

# Check Docker usage
docker system df
```

---

## Architecture Deep Dive

### Container Communication Flow

```
User Browser
    ↓ HTTPS (Port 443)
┌───────────────────────┐
│   NGINX Container     │
│   - TLS Termination   │
│   - Static files      │
│   - Reverse proxy     │
└───────────────────────┘
    ↓ FastCGI (Port 9000)
┌───────────────────────┐
│ WordPress Container   │
│   - PHP-FPM           │
│   - WP-CLI            │
│   - Business logic    │
└───────────────────────┘
    ↓ MySQL Protocol (Port 3306)
┌───────────────────────┐
│  MariaDB Container    │
│   - Database engine   │
│   - Data persistence  │
└───────────────────────┘
```

### Request Lifecycle

**1. User visits `https://fdorea.42.fr`**

**2. NGINX receives request:**
```nginx
server {
    listen 443 ssl;
    server_name fdorea.42.fr;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    root /var/www/html;
    index index.php;
    
    # Static files served directly
    location ~ \.(css|js|jpg|png|gif)$ {
        # NGINX serves from volume
    }
    
    # PHP requests proxied to WordPress
    location ~ \.php$ {
        fastcgi_pass wordpress:9000;  # Service name:port
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

**3. WordPress/PHP-FPM processes request:**
```bash
# PHP-FPM listens on port 9000
listen = 9000

# Executes PHP script (e.g., index.php, wp-login.php)
# WordPress loads wp-config.php for DB connection
```

**4. WordPress queries MariaDB:**
```php
// wp-config.php
define('DB_HOST', 'mariadb:3306');  // Docker service name
define('DB_NAME', 'wordpress');
define('DB_USER', 'wpuser');
define('DB_PASSWORD', 'secure_pass');
```

**5. MariaDB returns data:**
```sql
SELECT * FROM wp_posts WHERE post_status = 'publish';
```

**6. WordPress generates HTML:**
```php
// WordPress renders template with data
get_header();
the_content();
get_footer();
```

**7. NGINX returns response to user:**
```
HTTP/1.1 200 OK
Content-Type: text/html
[HTML content]
```

### Network Details

**Inception Network (Bridge):**
```bash
# View network
docker network inspect inception
```

**Container IPs (example):**
- NGINX: `172.18.0.2`
- WordPress: `172.18.0.3`
- MariaDB: `172.18.0.4`

**DNS Resolution:**
```bash
# Inside any container on inception network
nslookup mariadb       # Resolves to 172.18.0.4
nslookup wordpress     # Resolves to 172.18.0.3
nslookup nginx         # Resolves to 172.18.0.2
```

### Startup Sequence

**1. MariaDB starts (no dependencies):**
```bash
/usr/local/bin/init-mariadb.sh
    ↓
mysql_install_db (if first time)
    ↓
Start temporary mysqld
    ↓
CREATE DATABASE wordpress
CREATE USER wpuser
GRANT PRIVILEGES
    ↓
Shutdown temporary instance
    ↓
exec mysqld (PID 1)
```

**2. WordPress starts (after MariaDB):**
```bash
/usr/local/bin/setup-wordpress.sh
    ↓
Wait for MariaDB (max 30 attempts)
    ↓
wp core download (if first time)
    ↓
wp config create (wp-config.php)
    ↓
wp core install (creates tables, admin user)
    ↓
wp user create (editor user)
    ↓
Set permissions
    ↓
exec php-fpm8.2 -F (PID 1)
```

**3. NGINX starts (after WordPress):**
```bash
/usr/local/bin/start-nginx.sh
    ↓
Generate SSL cert (if first time)
    ↓
Set SSL permissions
    ↓
nginx -t (test config)
    ↓
exec nginx -g 'daemon off;' (PID 1)
```

---

## Development Workflow

### Local Development Setup

**1. Initial setup:**
```bash
git clone <repo> inception
cd inception
cp srcs/requirements/*/.env.example srcs/requirements/*/.env
# Edit .env files
make hosts
make
```

**2. Make changes to code:**
```bash
# Edit Dockerfile, scripts, or config files
nano srcs/requirements/nginx/wordpress-https.conf
```

**3. Rebuild affected service:**
```bash
docker compose -f srcs/docker-compose.yml build nginx
docker compose -f srcs/docker-compose.yml up -d nginx
```

**4. Test changes:**
```bash
curl -k https://fdorea.42.fr
docker logs nginx
```

**5. Debug if needed:**
```bash
docker exec -it nginx bash
cat /var/log/nginx/error.log
```

### Iterative Development

**Quick rebuild cycle:**
```bash
# Make changes
nano srcs/requirements/wordpress/setup-wordpress.sh

# Rebuild and restart
make down
make up

# View logs
make logs
```

**Service-specific rebuild:**
```bash
# Only rebuild WordPress
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress

# Check logs
docker logs -f wordpress
```

### Configuration Changes

**NGINX config change:**
```bash
# 1. Edit config
nano srcs/requirements/nginx/wordpress-https.conf

# 2. Rebuild image
docker compose -f srcs/docker-compose.yml build nginx

# 3. Recreate container
docker compose -f srcs/docker-compose.yml up -d nginx

# 4. Verify
docker exec nginx nginx -t
curl -k https://fdorea.42.fr
```

**PHP-FPM config change:**
```bash
# 1. Edit config
nano srcs/requirements/wordpress/php-fpm-pool.conf

# 2. Rebuild and restart
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress

# 3. Verify
docker exec wordpress php-fpm8.2 -t
```

**MariaDB config change:**
```bash
# 1. Edit config
nano srcs/requirements/mariadb/mariadb-network.cnf

# 2. Rebuild
docker compose -f srcs/docker-compose.yml build mariadb

# 3. Restart with clean database (if needed)
make fclean
make up
```

---

## Debugging and Testing

### Container Health Checks

**Check if containers are running:**
```bash
docker ps
# All should show STATUS: Up X minutes
```

**Check container resource usage:**
```bash
docker stats --no-stream
```

**Check container exit codes:**
```bash
docker ps -a
# Look for STATUS: Exited (code)
```

### Log Analysis

**NGINX errors:**
```bash
docker logs nginx 2>&1 | grep -i error
docker exec nginx cat /var/log/nginx/error.log
```

**WordPress errors:**
```bash
docker logs wordpress | grep -i error
docker exec wordpress cat /var/www/html/wp-content/debug.log
```

**MariaDB errors:**
```bash
docker logs mariadb | grep -i error
docker exec mariadb cat /var/log/mysql/error.log
```

### Network Debugging

**Test connectivity between containers:**
```bash
# From WordPress to MariaDB
docker exec wordpress ping -c 3 mariadb

# From NGINX to WordPress
docker exec nginx ping -c 3 wordpress
```

**Test MySQL connection:**
```bash
docker exec wordpress mysql -h mariadb -u wpuser -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1"
```

**Test FastCGI connection:**
```bash
docker exec nginx nc -zv wordpress 9000
```

**Test NGINX from host:**
```bash
curl -k https://fdorea.42.fr -I
# Should return: HTTP/1.1 200 OK
```

### Database Debugging

**Check database exists:**
```bash
docker exec mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"
```

**Check WordPress tables:**
```bash
docker exec mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" wordpress -e "SHOW TABLES;"
```

**Check users and permissions:**
```bash
docker exec mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT User, Host FROM mysql.user;"
```

### WordPress Debugging

**Enable WordPress debug mode:**
```bash
docker exec wordpress wp config set WP_DEBUG true --raw --allow-root
docker exec wordpress wp config set WP_DEBUG_LOG true --raw --allow-root
docker exec wordpress wp config set WP_DEBUG_DISPLAY false --raw --allow-root
```

**Check WordPress status:**
```bash
docker exec wordpress wp --info --allow-root
docker exec wordpress wp core verify-checksums --allow-root
```

**List plugins and themes:**
```bash
docker exec wordpress wp plugin list --allow-root
docker exec wordpress wp theme list --allow-root
```

### Common Issues and Solutions

**Issue: Port 443 already in use**
```bash
# Find process using port 443
sudo lsof -i :443

# Kill process or change port mapping in docker-compose.yml
```

**Issue: Permission denied on volumes**
```bash
# Fix WordPress permissions
sudo chown -R 33:33 /home/fdorea/data/wordpress/

# Fix MariaDB permissions
sudo chown -R 999:999 /home/fdorea/data/mariadb/
```

**Issue: Database connection error**
```bash
# Verify credentials match
grep MYSQL_PASSWORD srcs/requirements/mariadb/.env
grep WORDPRESS_DB_PASSWORD srcs/requirements/wordpress/.env

# Test connection manually
docker exec wordpress mysql -h mariadb -u wpuser -p
```

---

## Extending the Project

### Adding a New Service

**Example: Adding Redis cache**

**1. Create service directory:**
```bash
mkdir srcs/requirements/redis
```

**2. Create Dockerfile:**
```dockerfile
FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y redis-server && \
    apt-get clean

EXPOSE 6379

CMD ["redis-server", "--protected-mode no"]
```

**3. Add to docker-compose.yml:**
```yaml
services:
  redis:
    build: ./requirements/redis/.
    container_name: redis
    image: redis:42
    networks:
      - inception
    restart: unless-stopped
    volumes:
      - redis:/data

volumes:
  redis:
    name: redis
    driver: local
```

**4. Connect WordPress to Redis:**
```bash
# Install Redis Object Cache plugin
docker exec wordpress wp plugin install redis-cache --activate --allow-root

# Configure Redis host
docker exec wordpress wp config set WP_REDIS_HOST redis --allow-root
```

### Customizing Service Images

**Add PHP extensions to WordPress:**
```dockerfile
# In wordpress/Dockerfile
RUN apt-get install -y \
    php8.2-redis \
    php8.2-imagick \
    php8.2-memcached
```

**Add NGINX modules:**
```dockerfile
# In nginx/Dockerfile
RUN apt-get install -y \
    nginx-extras \
    libnginx-mod-http-cache-purge
```

### Environment-Specific Configurations

**Create production docker-compose:**
```yaml
# srcs/docker-compose.prod.yml
services:
  nginx:
    # Production-specific settings
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

**Use with:**
```bash
docker compose -f srcs/docker-compose.yml -f srcs/docker-compose.prod.yml up -d
```

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Maintained by:** fdorea

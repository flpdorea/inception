# User Documentation

This document provides instructions for end users and system administrators on how to use and manage the Inception project.

## Table of Contents

1. [Services Overview](#services-overview)
2. [Starting and Stopping the Project](#starting-and-stopping-the-project)
3. [Accessing the Website](#accessing-the-website)
4. [Managing Credentials](#managing-credentials)
5. [Checking Service Status](#checking-service-status)
6. [Common Operations](#common-operations)
7. [Troubleshooting](#troubleshooting)

---

## Services Overview

The Inception project provides a complete WordPress website infrastructure with the following services:

### 1. NGINX Web Server (Port 443)

**Purpose:** Serves as the front-facing web server and reverse proxy.

**Features:**

- Handles HTTPS connections with TLS/SSL encryption (TLSv1.2 and TLSv1.3)
- Routes requests to the WordPress application
- Serves static files (images, CSS, JavaScript)
- Provides secure communication with self-signed certificates

**Access:** External users connect to this service at `https://fdorea.42.fr`

### 2. WordPress + PHP-FPM

**Purpose:** Content Management System (CMS) for website management.

**Features:**

- Complete WordPress installation with administrative interface
- PHP 8.2 with FastCGI Process Manager for optimal performance
- Pre-configured with two user accounts (admin and editor)
- Automatic installation and configuration on first launch

**Access:** Admin panel at `https://fdorea.42.fr/wp-admin`

### 3. MariaDB Database

**Purpose:** Relational database for storing website data.

**Features:**

- Stores WordPress content (posts, pages, comments, settings)
- User authentication and authorization data
- Plugin and theme configurations
- Persistent storage with automatic backups via Docker volumes

**Access:** Internal only (not exposed to external network)

### Service Communication Flow

```
Internet → NGINX (443) → WordPress/PHP-FPM (9000) → MariaDB (3306)
           [TLS/SSL]      [FastCGI]                  [MySQL Protocol]
```

---

## Starting and Stopping the Project

### Prerequisites Check

Before starting, ensure:

- Docker and Docker Compose are installed and running
- The domain (`fdorea.42.fr`) is added to your `/etc/hosts` file
- Required data directories exist

### Starting the Stack

**Option 1: Quick Start (Recommended)**

```bash
make
```

This single command will:

- Create necessary directories
- Build Docker images
- Start all containers
- Display access information

**Option 2: Step-by-Step Start**

```bash
# 1. Add domain to hosts file (first time only)
make hosts

# 2. Create data directories (first time only)
make dirs

# 3. Build and start containers
make up
```

**What Happens During Startup:**

1. Docker builds custom images for each service (first time only)
2. MariaDB initializes the database and creates users
3. WordPress downloads and installs automatically
4. NGINX generates SSL certificates and starts serving
5. All services connect via the internal Docker network

**Expected Output:**

```
Creating data directories...
Building and starting containers...
[+] Building 45.2s (24/24) FINISHED
[+] Running 4/4
 ✔ Network inception      Created
 ✔ Container mariadb      Started
 ✔ Container wordpress    Started
 ✔ Container nginx        Started
Containers are up!
Access your site at: https://fdorea.42.fr
```

### Stopping the Stack

**Graceful Shutdown (Preserves Data):**

```bash
make stop
```

- Stops all running containers
- Data remains intact in volumes
- Quick to restart with `make start`

**Complete Shutdown (Removes Containers):**

```bash
make down
```

- Stops and removes all containers
- Removes the Docker network
- Volumes and data remain intact
- Requires rebuild on next `make up`

### Restarting Services

**Restart All Services:**

```bash
make stop
make start
```

**Restart Individual Service:**

```bash
docker restart nginx
docker restart wordpress
docker restart mariadb
```

**Rebuild from Scratch:**

```bash
make re
```

- Performs complete cleanup
- Removes all data
- Rebuilds images
- Fresh installation

---

## Accessing the Website

### Website Access

**URL:** `https://fdorea.42.fr`

**First Visit:**

1. Open your web browser
2. Navigate to `https://fdorea.42.fr`
3. You will see a security warning (self-signed certificate)
4. Click "Advanced" → "Accept the Risk and Continue"
5. WordPress homepage loads

### WordPress Admin Panel

**Admin URL:** `https://fdorea.42.fr/wp-admin`

**Default Admin Credentials:**

- **Username:** `fdorea_admin`
- **Password:** Check `.env` file (see [Managing Credentials](#managing-credentials))

**Admin Panel Features:**

- **Dashboard:** Overview of site activity and statistics
- **Posts:** Create and manage blog posts
- **Media:** Upload and manage images, videos, files
- **Pages:** Create static pages (About, Contact, etc.)
- **Comments:** Moderate user comments
- **Appearance:** Customize themes and widgets
- **Plugins:** Install and manage WordPress plugins
- **Users:** Manage user accounts and permissions
- **Settings:** Configure site settings, permalinks, etc.

### Additional User Account

A secondary editor account is pre-configured:

**Editor URL:** `https://fdorea.42.fr/wp-admin`

**Default Editor Credentials:**

- **Username:** `wpeditor`
- **Password:** Check `.env` file
- **Role:** Editor (can publish and manage posts, but not plugins/themes)

---

## Managing Credentials

### Credential Storage Locations

All credentials are stored in environment variable files:

```
srcs/requirements/
├── nginx/.env          # Domain configuration
├── wordpress/.env      # WordPress and database credentials
└── mariadb/.env        # Database root and user credentials
```

### Viewing Current Credentials

**WordPress Admin Credentials:**

```bash
grep "WORDPRESS_ADMIN" srcs/requirements/wordpress/.env
```

**WordPress Editor Credentials:**

```bash
grep "WORDPRESS_USER" srcs/requirements/wordpress/.env
```

**Database Credentials:**

```bash
cat srcs/requirements/mariadb/.env
```

### Changing Credentials

**⚠️ IMPORTANT:** Credentials can only be changed before first startup or after complete cleanup.

**Step-by-Step Process:**

1. **Stop and clean the stack:**

   ```bash
   make fclean
   ```

2. **Edit environment files:**

   ```bash
   # WordPress admin password
   nano srcs/requirements/wordpress/.env
   # Change: WORDPRESS_ADMIN_PASSWORD=your_new_password
   
   # Database passwords
   nano srcs/requirements/mariadb/.env
   # Change: MYSQL_ROOT_PASSWORD=your_new_root_password
   # Change: MYSQL_PASSWORD=your_new_db_password
   ```

3. **Ensure passwords match:**
   - `WORDPRESS_DB_PASSWORD` in `wordpress/.env`
   - Must match `MYSQL_PASSWORD` in `mariadb/.env`

4. **Restart the stack:**

   ```bash
   make up
   ```

### Credential Reference Table

| Service | File Location | Variable Name | Default Value | Purpose |
|---------|--------------|---------------|---------------|---------|
| MariaDB | `mariadb/.env` | `MYSQL_ROOT_PASSWORD` | `change_this_root_password` | Database admin access |
| MariaDB | `mariadb/.env` | `MYSQL_PASSWORD` | `change_this_db_password` | WordPress database user |
| WordPress | `wordpress/.env` | `WORDPRESS_ADMIN_PASSWORD` | `change_this_admin_password` | WordPress admin login |
| WordPress | `wordpress/.env` | `WORDPRESS_USER_PASSWORD` | `change_this_editor_password` | WordPress editor login |
| WordPress | `wordpress/.env` | `WORDPRESS_DB_PASSWORD` | `change_this_db_password` | Database connection |

### Password Requirements

**Recommended Guidelines:**

- Minimum 12 characters
- Mix of uppercase, lowercase, numbers, and symbols
- Avoid dictionary words
- Different passwords for each service

**Example Strong Password:**

```
MyStr0ng!P@ssw0rd#2025
```

### Security Best Practices

1. **Change default passwords immediately** after first deployment
2. **Never commit `.env` files** to version control (already in `.gitignore`)
3. **Backup credentials securely** in a password manager
4. **Use different passwords** for each service and environment
5. **Restrict file permissions:**

   ```bash
   chmod 600 srcs/requirements/*/.env
   ```

---

## Checking Service Status

### Quick Status Check

**View all services:**

```bash
make status
```

**Expected Output:**

```
Container status:
CONTAINER ID   IMAGE            STATUS         PORTS                  NAMES
abc123def456   nginx:42         Up 10 minutes  0.0.0.0:443->443/tcp   nginx
def456ghi789   wordpress:42     Up 10 minutes  9000/tcp               wordpress
ghi789jkl012   mariadb:42       Up 10 minutes  3306/tcp               mariadb

Volume status:
wordpress    /home/fdorea/data/wordpress
mariadb      /home/fdorea/data/mariadb
```

### Individual Service Checks

**Check NGINX:**

```bash
docker ps | grep nginx
# Should show: Up X minutes, healthy
```

**Test NGINX is serving:**

```bash
curl -k https://fdorea.42.fr
# Should return HTML content
```

**Check WordPress:**

```bash
docker ps | grep wordpress
# Should show: Up X minutes

docker exec wordpress wp --info --allow-root
# Should show PHP and WordPress version info
```

**Check MariaDB:**

```bash
docker ps | grep mariadb
# Should show: Up X minutes

docker exec mariadb mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" ping
# Should return: mysqld is alive
```

### Viewing Service Logs

**All services (live follow):**

```bash
make logs
```

**Specific service:**

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Follow logs in real-time:**

```bash
docker logs -f nginx
# Press Ctrl+C to stop following
```

**Last 50 lines only:**

```bash
docker logs --tail 50 wordpress
```

### Health Indicators

**Healthy Stack Indicators:**

- ✅ All three containers show "Up" status
- ✅ NGINX responds on port 443
- ✅ Website loads without errors
- ✅ Admin panel is accessible
- ✅ No error messages in logs

**Problem Indicators:**

- ❌ Container status shows "Restarting" or "Exited"
- ❌ Website shows "Connection refused" or "502 Bad Gateway"
- ❌ Error messages in logs
- ❌ Cannot access admin panel

---

## Common Operations

### Accessing Container Shells

**NGINX container:**

```bash
docker exec -it nginx /bin/bash
```

**WordPress container:**

```bash
docker exec -it wordpress /bin/bash
```

**MariaDB container:**

```bash
docker exec -it mariadb /bin/bash
```

**Exit container shell:**

```bash
exit
```

### Database Operations

**Access MariaDB CLI:**

```bash
docker exec -it mariadb mysql -u root -p
# Enter root password from mariadb/.env
```

**Common SQL Commands:**

```sql
-- Show databases
SHOW DATABASES;

-- Use WordPress database
USE wordpress;

-- Show tables
SHOW TABLES;

-- Exit
EXIT;
```

**Backup Database:**

```bash
docker exec mariadb mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" wordpress > backup.sql
```

**Restore Database:**

```bash
cat backup.sql | docker exec -i mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" wordpress
```

### WordPress CLI Operations

**Check WordPress status:**

```bash
docker exec wordpress wp --info --allow-root
```

**List installed plugins:**

```bash
docker exec wordpress wp plugin list --allow-root
```

**List users:**

```bash
docker exec wordpress wp user list --allow-root
```

**Update WordPress core:**

```bash
docker exec wordpress wp core update --allow-root
```

### Volume Management

**List volumes:**

```bash
docker volume ls | grep -E "wordpress|mariadb"
```

**Inspect volume:**

```bash
docker volume inspect wordpress
docker volume inspect mariadb
```

**View volume contents:**

```bash
# WordPress files
ls -la /home/fdorea/data/wordpress/

# MariaDB data
sudo ls -la /home/fdorea/data/mariadb/
```

### Network Inspection

**View Docker networks:**

```bash
docker network ls | grep inception
```

**Inspect network:**

```bash
docker network inspect inception
```

**Test container connectivity:**

```bash
# From WordPress container to MariaDB
docker exec wordpress ping -c 3 mariadb

# From NGINX container to WordPress
docker exec nginx ping -c 3 wordpress
```

---

## Troubleshooting

### Website Not Loading

**Symptom:** Browser shows "This site can't be reached"

**Solutions:**

1. **Check if containers are running:**

   ```bash
   make status
   ```

2. **Verify domain in hosts file:**

   ```bash
   grep "fdorea.42.fr" /etc/hosts
   # Should return: 127.0.0.1 fdorea.42.fr
   ```

3. **Check NGINX logs:**

   ```bash
   docker logs nginx
   ```

4. **Restart services:**

   ```bash
   make re
   ```

### 502 Bad Gateway Error

**Symptom:** NGINX shows "502 Bad Gateway"

**Cause:** WordPress/PHP-FPM not responding

**Solutions:**

1. **Check WordPress container:**

   ```bash
   docker ps | grep wordpress
   docker logs wordpress
   ```

2. **Restart WordPress:**

   ```bash
   docker restart wordpress
   sleep 10
   docker restart nginx
   ```

### Database Connection Error

**Symptom:** WordPress shows "Error establishing a database connection"

**Cause:** MariaDB not running or wrong credentials

**Solutions:**

1. **Check MariaDB status:**

   ```bash
   docker ps | grep mariadb
   docker logs mariadb
   ```

2. **Verify credentials match:**

   ```bash
   grep "MYSQL_PASSWORD" srcs/requirements/mariadb/.env
   grep "WORDPRESS_DB_PASSWORD" srcs/requirements/wordpress/.env
   # These must be identical
   ```

3. **Restart database and WordPress:**

   ```bash
   docker restart mariadb
   sleep 15
   docker restart wordpress
   ```

### Permission Denied Errors

**Symptom:** Logs show "Permission denied" errors

**Solutions:**

1. **Check data directory permissions:**

   ```bash
   ls -la /home/fdorea/data/
   ```

2. **Fix permissions:**

   ```bash
   sudo chown -R $USER:$USER /home/fdorea/data/
   sudo chmod -R 755 /home/fdorea/data/
   ```

3. **Restart containers:**

   ```bash
   make restart
   ```

### Container Keeps Restarting

**Symptom:** Container status shows "Restarting" repeatedly

**Solutions:**

1. **View logs to identify error:**

   ```bash
   docker logs <container_name>
   ```

2. **Check for port conflicts:**

   ```bash
   sudo lsof -i :443  # For NGINX
   sudo lsof -i :3306 # For MariaDB
   ```

3. **Remove and recreate:**

   ```bash
   make fclean
   make up
   ```

### SSL Certificate Warnings

**Symptom:** Browser shows "Your connection is not private"

**Explanation:** This is expected behavior with self-signed certificates.

**Solutions:**

**For Testing (Accept the warning):**

- Click "Advanced" → "Proceed to site"

**For Production (Use real certificate):**

- Obtain certificate from Let's Encrypt
- Replace self-signed certificate in NGINX configuration

### Out of Disk Space

**Symptom:** Containers fail to start, "no space left on device" errors

**Solutions:**

1. **Check disk usage:**

   ```bash
   df -h
   docker system df
   ```

2. **Clean unused Docker resources:**

   ```bash
   docker system prune -a --volumes
   ```

3. **Remove old backups:**

   ```bash
   rm -rf /home/fdorea/data/backups/*
   ```

### Forgot Admin Password

**Solution:** Reset via database:

1. **Access MariaDB:**

   ```bash
   docker exec -it mariadb mysql -u root -p
   ```

2. **Reset password:**

   ```sql
   USE wordpress;
   UPDATE wp_users SET user_pass=MD5('new_password') WHERE user_login='fdorea_admin';
   EXIT;
   ```

3. **Clear WordPress cache:**

   ```bash
   docker exec wordpress rm -rf /var/www/html/wp-content/cache/*
   ```

### Getting Help

If issues persist:

1. **Collect diagnostic information:**

   ```bash
   make status > diagnostic.txt
   docker logs nginx >> diagnostic.txt
   docker logs wordpress >> diagnostic.txt
   docker logs mariadb >> diagnostic.txt
   ```

2. **Check project documentation:**
   - README.md for general information
   - DEV_DOC.md for technical details

3. **Review container configurations:**
   - Check Dockerfiles in `srcs/requirements/*/`
   - Review `srcs/docker-compose.yml`

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│              INCEPTION QUICK REFERENCE              │
├─────────────────────────────────────────────────────┤
│ Start Everything:        make                       │
│ Stop Containers:         make stop                  │
│ Remove Containers:       make down                  │
│ View Status:             make status                │
│ View Logs:               make logs                  │
│ Complete Reset:          make fclean && make        │
├─────────────────────────────────────────────────────┤
│ Website:                 https://fdorea.42.fr       │
│ Admin Panel:             /wp-admin                  │
│ Admin User:              fdorea_admin               │
│ Editor User:             wpeditor                   │
├─────────────────────────────────────────────────────┤
│ Container Access:        docker exec -it <name> sh  │
│ Database CLI:            docker exec -it mariadb    │
│                          mysql -u root -p           │
│ WordPress CLI:           docker exec wordpress wp   │
│                          --allow-root <command>     │
└─────────────────────────────────────────────────────┘
```

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Maintained by:** fdorea

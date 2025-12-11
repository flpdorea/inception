# Inception

## Description

Inception is a system administration project that involves setting up a small infrastructure using Docker. The project consists of creating a complete WordPress website running on NGINX with TLS/SSL encryption and MariaDB as the database. All services run in isolated Docker containers orchestrated with Docker Compose.

The main goal is to understand containerization, service orchestration, and infrastructure setup while following best practices for security and configuration management. Each service runs in its own dedicated container built from custom Dockerfiles based on the penultimate stable version of Debian (Bookworm).

**Key Features:**

- NGINX web server with TLSv1.2 and TLSv1.3 encryption
- WordPress with PHP-FPM
- MariaDB database
- Custom Docker images built from scratch
- Persistent data storage using Docker volumes
- Private Docker network for inter-container communication
- Environment-based configuration management

## Architecture Overview

The infrastructure consists of three main services:

```
┌─────────────────────────────────────────────────┐
│                   NGINX (Port 443)              │
│          - TLS/SSL Termination                  │
│          - Reverse Proxy                        │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│              WordPress + PHP-FPM                │
│          - Content Management System            │
│          - PHP 8.2 with FastCGI                 │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│                  MariaDB                        │
│          - Database Server                      │
│          - Persistent Storage                   │
└─────────────────────────────────────────────────┘
```

### Docker and Project Structure

This project leverages **Docker** to create isolated, reproducible environments for each service. Docker provides:

- **Containerization**: Each service (NGINX, WordPress, MariaDB) runs in its own isolated container with only the necessary dependencies
- **Portability**: The entire infrastructure can be deployed on any system with Docker installed
- **Consistency**: Development, testing, and production environments are identical
- **Resource Efficiency**: Containers share the host OS kernel, using fewer resources than traditional virtualization
- **Easy Orchestration**: Docker Compose allows managing multi-container applications with a single configuration file

**Project Structure:**

```
inception/
├── srcs/
│   ├── docker-compose.yml          # Service orchestration
│   └── requirements/
│       ├── nginx/                   # NGINX container
│       │   ├── Dockerfile
│       │   ├── .env.example
│       │   ├── wordpress-https.conf
│       │   └── start-nginx.sh
│       ├── wordpress/               # WordPress container
│       │   ├── Dockerfile
│       │   ├── .env.example
│       │   ├── php-fpm-pool.conf
│       │   └── setup-wordpress.sh
│       └── mariadb/                 # MariaDB container
│           ├── Dockerfile
│           ├── .env.example
│           ├── mariadb-network.cnf
│           └── init-mariadb.sh
├── Makefile                         # Build automation
└── README.md
```

## Instructions

### Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- Make (build automation)
- Sudo privileges (for initial setup)

### Installation

1. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Configure environment variables:**

   Each service requires environment variables. Create `.env` files from the examples:

   ```bash
   # NGINX configuration
   cp srcs/requirements/nginx/.env.example srcs/requirements/nginx/.env
   # Edit and set: DOMAIN_NAME, CERTS_*
   
   # WordPress configuration
   cp srcs/requirements/wordpress/.env.example srcs/requirements/wordpress/.env
   # Edit and set: DB_*, WP_*
   
   # MariaDB configuration
   cp srcs/requirements/mariadb/.env.example srcs/requirements/mariadb/.env
   # Edit and set: MYSQL_*
   ```

3. **Update domain configuration:**

   Update the domain name in `srcs/docker-compose.yml` (volumes section) and `Makefile` to match your login:

   ```bash
   # Replace 'fdorea' with your login in:
   # - srcs/docker-compose.yml (volume device paths)
   # - Makefile (DATA_DIR, hosts target)
   ```

4. **Add domain to hosts file:**

   ```bash
   make hosts
   ```

   This adds your domain (e.g., `fdorea.42.fr`) to `/etc/hosts` pointing to `127.0.0.1`.

### Compilation and Execution

**Quick start:**

```bash
make
# or
make all
```

This command will:

1. Create necessary data directories (`/home/<login>/data/wordpress` and `/home/<login>/data/mariadb`)
2. Build custom Docker images for all services
3. Start containers in detached mode
4. Display the access URL

**Available Make targets:**

| Command | Description |
|---------|-------------|
| `make all` | Build and start all containers (default) |
| `make up` | Build and start all containers |
| `make down` | Stop and remove containers |
| `make start` | Start existing containers without rebuilding |
| `make stop` | Stop running containers without removing |
| `make clean` | Remove containers and volumes (keeps images) |
| `make fclean` | Complete cleanup (removes everything including data) |
| `make re` | Rebuild from scratch (fclean + all) |
| `make logs` | Show container logs (follow mode) |
| `make status` | Display container and volume status |
| `make dirs` | Create data directories manually |
| `make hosts` | Add domain to /etc/hosts |
| `make help` | Show all available commands |

### Accessing the Website

After running `make`, access your WordPress site at:

- **URL**: `https://<login>.42.fr` (e.g., `https://fdorea.42.fr`)
- **Note**: Your browser will show a security warning because the SSL certificate is self-signed. Click "Advanced" and proceed to the site.

### Troubleshooting

**Check container status:**

```bash
make status
# or
docker ps -a
```

**View container logs:**

```bash
make logs
# or
docker logs <container_name>
```

**Restart services:**

```bash
make re
```

**Complete cleanup and fresh start:**

```bash
make fclean
make all
```

## Design Choices and Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker |
|--------|-----------------|--------|
| **Architecture** | Full OS with hypervisor | Shares host OS kernel |
| **Resource Usage** | Heavy (GBs of RAM per VM) | Lightweight (MBs per container) |
| **Boot Time** | Minutes | Seconds |
| **Isolation** | Complete hardware-level isolation | Process-level isolation |
| **Portability** | Large image files | Small, layered images |
| **Use Case** | Running different OS, complete isolation | Microservices, development environments |

**Why Docker for this project?**

- Faster deployment and iteration during development
- Efficient resource utilization on limited hardware
- Easy service orchestration with Docker Compose
- Better alignment with modern DevOps practices
- Sufficient isolation for web services

### Secrets vs Environment Variables

| Method | Secrets | Environment Variables |
|--------|---------|----------------------|
| **Security** | Encrypted at rest, encrypted in transit | Plaintext in container environment |
| **Visibility** | Mounted as files, not visible in `docker inspect` | Visible in `docker inspect`, process lists |
| **Rotation** | Can be rotated without rebuilding | Requires container restart |
| **Best For** | Production passwords, API keys, certificates | Non-sensitive configuration (ports, hostnames) |

**Project choice: Environment Variables**

- Simpler setup for educational purposes
- Adequate for local development environment
- Files are gitignored for basic protection
- In production, Docker Secrets or external secret management (Vault, AWS Secrets Manager) should be used

### Docker Network vs Host Network

| Aspect | Docker Network (Bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Each container has its own network namespace | Container uses host's network stack |
| **Port Mapping** | Requires explicit port mapping | Direct access to all ports |
| **Communication** | Containers communicate via network name | Localhost communication |
| **Security** | Better isolation between containers | Less isolation, potential conflicts |
| **Performance** | Slight overhead from network translation | Slightly better performance |

**Project choice: Docker Network (Bridge)**

```yaml
networks:
  inception:
    driver: bridge
```

- Provides service isolation (containers only expose necessary ports)
- Enables container-to-container communication by service name
- Better security through network segmentation
- Port 443 explicitly mapped for NGINX
- MariaDB and PHP-FPM remain isolated from external access

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Managed by Docker | Direct host filesystem access |
| **Portability** | Portable across systems | Tied to specific host paths |
| **Permissions** | Docker handles permissions | Host OS permissions apply |
| **Backup** | Docker volume backup tools | Standard filesystem backup |
| **Performance** | Optimized by Docker | Native filesystem performance |

**Project choice: Hybrid Approach (Docker Volumes with Bind Mount Driver)**

```yaml
volumes:
  wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/fdorea/data/wordpress
```

This configuration:

- Uses Docker volume management interface
- Stores data in predictable host locations (`/home/<login>/data/`)
- Ensures data persistence across container restarts
- Makes backups straightforward (direct host access)
- Meets project requirements for data location
- Provides better control over data lifecycle

**Why this approach?**

- Data persists even after `docker-compose down`
- Easy to backup and inspect data directly on host
- Meets 42 project requirement for data storage location
- Simplifies debugging and data recovery

## Resources

### Documentation and References

**Docker:**

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Networking Overview](https://docs.docker.com/network/)
- [Docker Volume Management](https://docs.docker.com/storage/volumes/)

**NGINX:**

- [NGINX Documentation](https://nginx.org/en/docs/)
- [NGINX TLS/SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [FastCGI with NGINX](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)

**WordPress:**

- [WordPress Documentation](https://wordpress.org/support/)
- [WP-CLI Official Site](https://wp-cli.org/)
- [WordPress Database Configuration](https://wordpress.org/support/article/editing-wp-config-php/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

**MariaDB:**

- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [MariaDB Server System Variables](https://mariadb.com/kb/en/server-system-variables/)
- [MySQL Security Best Practices](https://dev.mysql.com/doc/refman/8.0/en/security.html)

**System Administration:**

- [OpenSSL Certificate Generation](https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html)
- [Debian Package Management](https://www.debian.org/doc/manuals/debian-reference/ch02.en.html)
- [Linux File Permissions](https://linux.die.net/man/1/chmod)

### AI Usage Disclosure

AI assistance was used in the following aspects of this project:

**1. Research:**

- Understanding WordPress security best practices
- Learning about SSL/TLS certificate generation with OpenSSL

**2. Configuration Files:**

- Assistance with NGINX configuration syntax for FastCGI proxy
- PHP-FPM pool configuration optimization
- MariaDB configuration parameters for Docker environment

**3. Shell Scripts:**

- Debugging bash scripts for container initialization
- Error handling patterns in entrypoint scripts
- Wait-for-database logic in WordPress setup
- SSL certificate generation automation

**4. Documentation Writing:**

- Structuring README.md, USER_DOC.md and DEV_DOC.md files
- Creating clear explanations of technical concepts
- Generating comparison tables (VMs vs Docker, etc.)
- Proofreading and improving technical clarity

**5. Troubleshooting:**

- Resolving container startup timing issues
- Analyzing log output for error diagnosis

**Code NOT generated by AI:**

- Core Dockerfile and docker-compose.yml structure and service architecture
- Project-specific design decisions and implementation approach
- Custom Makefile targets and automation strategy

**Learning Approach:**
All AI-suggested code was thoroughly reviewed, tested, and understood before integration. The AI served as a learning assistant and documentation reference, not as a replacement for understanding the underlying technologies. Every configuration decision was validated through official documentation and testing.

---

## Additional Notes

**Security Considerations:**

- SSL certificates are self-signed (not suitable for production)
- Environment variables contain sensitive data (use secrets in production)
- All services run with default security settings
- No firewall rules implemented (host security recommended)

**Future Improvements:**

- Add health checks to Docker Compose
- Implement automated backup solution
- Add monitoring and logging aggregation
- Harden service configurations for production use
- Implement CI/CD pipeline

**Project Compliance:**
This project follows the 42 Inception subject requirements:

- ✅ Custom Dockerfiles from Debian Bookworm
- ✅ No pre-built Docker images (except base Debian)
- ✅ TLSv1.3 on NGINX
- ✅ WordPress with PHP-FPM
- ✅ MariaDB only (no MySQL)
- ✅ Docker Compose for orchestration
- ✅ Persistent volumes in `/home/<login>/data/`
- ✅ Private Docker network
- ✅ Container restart policies
- ✅ No hacky patches (sleep infinity, tail -f, etc.)

---

**License:** This project is part of the 42 curriculum and follows the school's academic policies.

**Author:** fdorea  
**Last Updated:** December 2025

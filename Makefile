DATA_DIR = $(HOME)/data
WP_DIR = $(DATA_DIR)/wordpress
DB_DIR = $(DATA_DIR)/mariadb

all: up

dirs:
	@echo "Creating data directories..."
	@mkdir -p $(WP_DIR)
	@mkdir -p $(DB_DIR)
	@echo "Data directories created:"
	@echo "  - $(WP_DIR)"
	@echo "  - $(DB_DIR)"

hosts:
	@echo "Checking /etc/hosts for fdorea.42.fr..."
	@if ! grep -q "fdorea.42.fr" /etc/hosts; then \
		echo "Adding fdorea.42.fr to /etc/hosts (requires sudo)..."; \
		echo "127.0.0.1 fdorea.42.fr" | sudo tee -a /etc/hosts > /dev/null; \
		echo "Domain added to /etc/hosts"; \
	else \
		echo "fdorea.42.fr already in /etc/hosts"; \
	fi

up: dirs
	@echo "Checking if fdorea.42.fr is in /etc/hosts..."
	@if ! grep -q "fdorea.42.fr" /etc/hosts; then \
		echo "Warning: fdorea.42.fr not found in /etc/hosts"; \
		echo "Run 'make hosts' to add it (requires sudo)"; \
	fi
	@echo "Building and starting containers..."
	@docker compose -f ./srcs/docker-compose.yml up --build -d
	@echo "Containers are up!"
	@echo "Access your site at: https://fdorea.42.fr"
	@echo "(You may need to accept the self-signed certificate warning)"

down:
	@echo "Stopping and removing containers..."
	@docker compose -f ./srcs/docker-compose.yml down
	@echo "Containers stopped and removed"

start:
	@echo "Starting containers..."
	@docker compose -f ./srcs/docker-compose.yml start
	@echo "Containers started"

stop:
	@echo "Stopping containers..."
	@docker compose -f ./srcs/docker-compose.yml stop
	@echo "Containers stopped"

clean: down
	@echo "Removing volumes..."
	@docker compose -f ./srcs/docker-compose.yml down -v
	@echo "Pruning Docker system..."
	@docker system prune -f
	@echo "Cleanup complete (images preserved)"

fclean: down
	@echo "Performing complete cleanup..."
	@docker compose -f ./srcs/docker-compose.yml down -v --rmi all
	@docker system prune -af --volumes
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_DIR)
	@echo "Complete cleanup done"

re: fclean all

logs:
	@docker compose -f ./srcs/docker-compose.yml logs -f

status:
	@echo "Container status:"
	@docker ps -a
	@echo ""
	@echo "Volume status:"
	@docker volume ls | grep -E "wordpress|mariadb" || echo "No volumes found"

help:
	@echo "Available targets:"
	@echo "  make all     - Build and start all containers (default)"
	@echo "  make up      - Build and start all containers"
	@echo "  make down    - Stop and remove containers"
	@echo "  make start   - Start existing containers"
	@echo "  make stop    - Stop running containers"
	@echo "  make clean   - Remove containers and volumes"
	@echo "  make fclean  - Remove everything (including data)"
	@echo "  make re      - Rebuild from scratch (fclean + all)"
	@echo "  make logs    - Show container logs"
	@echo "  make status  - Show container and volume status"
	@echo "  make dirs    - Create data directories"
	@echo "  make hosts   - Add fdorea.42.fr to /etc/hosts"
	@echo "  make help    - Show this help message"

.PHONY: all dirs hosts up down start stop clean fclean re logs status help

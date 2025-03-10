# vscode-web
Docker image for VS Code Web - a containerized version of Visual Studio Code running in a web browser using the code-insiders CLI.

## Features

- **Web Interface**: Access VS Code directly through your browser
- **Security**: Optional connection token authentication
- **Multi-arch Support**: Works across different CPU architectures
- **Persistence**: Mount volumes for persistent data storage
- **Development Tools**:
  - VS Code Web (latest insiders build)
  - Python 3 with pip and venv
  - OpenJDK 21 (headless)
  - Git (latest version)
  - Kubernetes tools:
    - kubectl CLI
    - Helm v3.17.1
  - Rust with cargo
  - Build essentials

## Usage

### Quick Start
Run the container with:
```bash
docker run -d -p 8000:8000 bjornjorgensen/vscode-web
```

### With Connection Token
To set a connection token, use:
```bash
docker run -d -p 8000:8000 -e CONNECTION_TOKEN="your_token" bjornjorgensen/vscode-web
```

### With Custom Port
To run the container on a custom port, use:
```bash
docker run -d -p <custom_port>:8000 bjornjorgensen/vscode-web
```

### With Custom Port and Connection Token
To run the container on a custom port with a connection token, use:
```bash
docker run -d -p <custom_port>:8000 -e CONNECTION_TOKEN="your_token" bjornjorgensen/vscode-web
```

### With Volume Mounting
To run the container with volume mounting for persistence, use:
```bash
docker run -d -p 8000:8000 -v /path/to/local/dir:/home/coder/project bjornjorgensen/vscode-web
```

### Using Docker Compose
Create a docker-compose.yml file:
```yaml
version: "3.8"
services:
  vscode-web:
    image: bjornjorgensen/vscode-web
    ports:
      - "8000:8000"
    environment:
      - CONNECTION_TOKEN=your_token  # optional
    volumes:
      - /path/to/local/dir:/home/coder/project  # optional
```
Then start the container with:
```bash
docker-compose up -d
```

## Configuration
The following environment variables can be used to configure the container:

- `CONNECTION_TOKEN`: Set a token for secure access

## Note
The container runs VS Code Web via the code-insiders CLI using the serve-web command. Set the CONNECTION_TOKEN if needed.

## Access
Once the container is running, access VS Code Web by navigating to `http://localhost:8000` in your web browser. Replace `localhost` with your server's IP address if running on a remote server.

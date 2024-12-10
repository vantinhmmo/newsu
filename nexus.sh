#!/bin/bash 

curl -s https://raw.githubusercontent.com/zunxbt/logo/main/logo.sh | bash
sleep 5

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'


show() {
    case $2 in
        "error")
            echo -e "${PINK}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${PINK}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${PINK}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

SERVICE_NAME="nexus"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# Install Rust
show "Installing Rust..." "progress"
if ! source <(wget -O - https://raw.githubusercontent.com/zunxbt/installation/main/rust.sh); then
    show "Failed to install Rust." "error"
    exit 1
fi

# Update package list
show "Updating package list..." "progress"
if ! sudo apt update; then
    show "Failed to update package list." "error"
    exit 1
fi

# Install Git if not installed
if ! command -v git &> /dev/null; then
    show "Git is not installed. Installing git..." "progress"
    if ! sudo apt install git -y; then
        show "Failed to install git." "error"
        exit 1
    fi
else
    show "Git is already installed."
fi

# Clone Nexus-XYZ repository
if [ -d "$HOME/network-api" ]; then
    show "Deleting existing repository..." "progress"
    rm -rf "$HOME/network-api"
fi

sleep 3

show "Cloning Nexus-XYZ network API repository..." "progress"
if ! git clone https://github.com/nexus-xyz/network-api.git "$HOME/network-api"; then
    show "Failed to clone the repository." "error"
    exit 1
fi

cd $HOME/network-api/clients/cli

# Install required dependencies including protoc
show "Installing required dependencies..." "progress"
sudo apt update && sudo apt upgrade && sudo apt install build-essential pkg-config libssl-dev protobuf-compiler -y

# Install specific version of protoc (3.19.0)
show "Installing protoc version 3.19.0..." "progress"
PROTOC_VERSION="3.19.0"
PROTOC_URL="https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOC_VERSION/protoc-$PROTOC_VERSION-linux-x86_64.zip"
PROTOC_DIR="$HOME/protoc-$PROTOC_VERSION"

# Download and extract protoc
if ! wget "$PROTOC_URL" -O "$PROTOC_DIR.zip"; then
    show "Failed to download protoc." "error"
    exit 1
fi

if ! unzip "$PROTOC_DIR.zip" -d "$PROTOC_DIR"; then
    show "Failed to unzip protoc." "error"
    exit 1
fi

# Move protoc binaries to /usr/local/bin
sudo mv "$PROTOC_DIR/bin/protoc" /usr/local/bin/
sudo mv "$PROTOC_DIR/include" /usr/local/include/

# Clean up
rm -rf "$PROTOC_DIR.zip" "$PROTOC_DIR"

# Verify protoc installation
if ! command -v protoc &> /dev/null; then
    show "protoc installation failed." "error"
    exit 1
else
    show "protoc version 3.19.0 installed successfully." "progress"
fi

# Handle nexus.service
if systemctl is-active --quiet nexus.service; then
    show "nexus.service is currently running. Stopping and disabling it..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
else
    show "nexus.service is not running."
fi

# Create systemd service
show "Creating systemd service..." "progress"
if ! sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Nexus XYZ Prover Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
ExecStart=$HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"; then
    show "Failed to create the systemd service file." "error"
    exit 1
fi

# Reload systemd and start service
show "Reloading systemd and starting the service..." "progress"
if ! sudo systemctl daemon-reload; then
    show "Failed to reload systemd." "error"
    exit 1
fi

if ! sudo systemctl start $SERVICE_NAME.service; then
    show "Failed to start the service." "error"
    exit 1
fi

if ! sudo systemctl enable $SERVICE_NAME.service; then
    show "Failed to enable the service." "error"
    exit 1
fi

# Final message
show "Nexus Prover installation and service setup complete!"
show "You can check Nexus Prover logs using this command : journalctl -u nexus.service -fn 50"

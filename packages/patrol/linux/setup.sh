#!/bin/bash

# Linux Native Automation Service Setup Script for Patrol

set -e

echo "Setting up Linux Native Automation Service for Patrol..."

# Check if we're on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "Error: This script is designed for Linux systems"
    exit 1
fi

# Check if running under Wayland — xdotool is X11-only
if [[ "${XDG_SESSION_TYPE,,}" == "wayland" ]]; then
    echo ""
    echo "WARNING: XDG_SESSION_TYPE is 'wayland'. The Linux native automation service"
    echo "uses xdotool, which only works on X11. Click, type, key, and swipe"
    echo "operations will likely fail. To resolve this, either:"
    echo "  1. Log in to an X11 session (select 'X11' at the login screen)"
    echo "  2. Set XDG_SESSION_TYPE=x11 before starting the service"
    echo ""
fi

# Install system dependencies
echo "Installing system dependencies..."

# Check for apt (Ubuntu/Debian)
if command -v apt &> /dev/null; then
    echo "Detected apt package manager"
    sudo apt update
    sudo apt install -y \
        python3 \
        python3-pip \
        python3-pyatspi \
        xdotool \
        at-spi2-core \
        libatspi2.0-dev \
        gir1.2-atspi-2.0 \
        python3-gi \
        gir1.2-gtk-3.0

# Check for dnf (Fedora)
elif command -v dnf &> /dev/null; then
    echo "Detected dnf package manager"
    sudo dnf install -y \
        python3 \
        python3-pip \
        python3-pyatspi \
        xdotool \
        at-spi2-core \
        at-spi2-atk-devel \
        python3-gobject \
        gtk3 \
        --skip-unavailable

# Check for pacman (Arch)
elif command -v pacman &> /dev/null; then
    echo "Detected pacman package manager"
    sudo pacman -S --needed \
        python \
        python-pip \
        at-spi2-core \
        at-spi2-atk \
        python-pyatspi \
        xdotool \
        python-gobject \
        gtk3

else
    echo "Warning: Unsupported package manager. Please install dependencies manually:"
    echo "- python3, python3-pip"
    echo "- pyatspi (python3-pyatspi)"
    echo "- xdotool"
    echo "- at-spi2-core"
    echo "- libatspi2.0-dev or equivalent"
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install --user -r requirements.txt

# Create startup script
echo "Creating startup script..."
cat > linux_automator.sh << 'EOF'
#!/bin/bash

# Linux Native Automation Service Startup Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if accessibility is enabled
if ! gsettings get org.gnome.desktop.interface toolkit-accessibility 2>/dev/null | grep -q true; then
    echo "Enabling accessibility..."
    gsettings set org.gnome.desktop.interface toolkit-accessibility true 2>/dev/null || true
fi

# Start the service
echo "Starting Linux Native Automation Service..."
python3 src/linux_automator_service.py
EOF

chmod +x linux_automator.sh

# Create systemd service file (optional)
echo "Creating systemd service file..."
cat > patrol-linux-automator.service << EOF
[Unit]
Description=Patrol Linux Native Automation Service
After=graphical-session.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(which python3) $(pwd)/src/linux_automator_service.py
Restart=on-failure
RestartSec=5
Environment=DISPLAY=$DISPLAY

[Install]
WantedBy=default.target
EOF

echo ""
echo "Setup completed successfully!"
echo ""
echo "To start the service:"
echo "  ./linux_automator.sh"
echo ""
echo "To install as a systemd service (optional):"
echo "  cp patrol-linux-automator.service ~/.config/systemd/user/"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now patrol-linux-automator.service"
echo ""
echo "Note: Make sure accessibility is enabled in your desktop environment:"
echo "  GNOME: Settings -> Universal Access -> Seeing -> Large Text"
echo "  Or run: gsettings set org.gnome.desktop.interface toolkit-accessibility true"
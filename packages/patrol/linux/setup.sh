#!/bin/bash

# Linux Native Automation Service Setup Script for Patrol

set -e

echo "Setting up Linux Native Automation Service for Patrol..."

# Check if we're on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "Error: This script is designed for Linux systems"
    exit 1
fi

# Detect session type
SESSION_TYPE="${XDG_SESSION_TYPE,,}"

# Check for Wayland
if [[ "$SESSION_TYPE" == "wayland" ]]; then
    echo ""
    echo "NOTICE: XDG_SESSION_TYPE is 'wayland'. xdotool is X11-only, so Patrol will"
    echo "use ydotool (via the Linux uinput kernel interface) for input simulation"
    echo "on Wayland. This script will install ydotool and configure it for you."
    echo ""
fi

USE_YDOTOOL=false
if [[ "$SESSION_TYPE" == "wayland" ]] || ! command -v xdotool &> /dev/null; then
    USE_YDOTOOL=true
fi

# Install system dependencies
echo "Installing system dependencies..."

# Check for apt (Ubuntu/Debian)
if command -v apt &> /dev/null; then
    echo "Detected apt package manager"
    sudo apt update
    PKGS=\
        python3 \
        python3-pip \
        python3-pyatspi \
        xdotool \
        at-spi2-core \
        libatspi2.0-dev \
        gir1.2-atspi-2.0 \
        python3-gi \
        gir1.2-gtk-3.0
    if [[ "$USE_YDOTOOL" == true ]]; then
        PKGS="$PKGS ydotool"
    fi
    sudo apt install -y $PKGS

# Check for dnf (Fedora)
elif command -v dnf &> /dev/null; then
    echo "Detected dnf package manager"
    PKGS=\
        python3 \
        python3-pip \
        python3-pyatspi \
        xdotool \
        at-spi2-core \
        at-spi2-atk-devel \
        python3-gobject \
        gtk3
    if [[ "$USE_YDOTOOL" == true ]]; then
        PKGS="$PKGS ydotool"
    fi
    sudo dnf install -y $PKGS --skip-unavailable

# Check for pacman (Arch)
elif command -v pacman &> /dev/null; then
    echo "Detected pacman package manager"
    PKGS=\
        python \
        python-pip \
        at-spi2-core \
        at-spi2-atk \
        python-pyatspi \
        xdotool \
        python-gobject \
        gtk3
    if [[ "$USE_YDOTOOL" == true ]]; then
        PKGS="$PKGS ydotool"
    fi
    sudo pacman -S --needed $PKGS

else
    echo "Warning: Unsupported package manager. Please install dependencies manually:"
    echo "- python3, python3-pip"
    echo "- pyatspi (python3-pyatspi)"
    echo "- xdotool"
    echo "- ydotool (for Wayland support)"
    echo "- at-spi2-core"
    echo "- libatspi2.0-dev or equivalent"
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install --user -r requirements.txt

# Configure ydotool (if installed)
if command -v ydotoold &> /dev/null || command -v ydotool &> /dev/null; then
    echo ""
    echo "Configuring ydotool for Wayland input simulation..."

    # Set up udev rules for non-root uinput access
    if [ ! -f /etc/udev/rules.d/99-uinput.rules ]; then
        echo "Creating udev rules for uinput access..."
        echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/99-uinput.rules > /dev/null
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        echo "Udev rules installed. You may need to log out and back in for changes to take effect."
    else
        echo "Udev rules for uinput already exist."
    fi

    # Add user to 'input' group for ydotool access
    if ! groups "$USER" | grep -q '\binput\b'; then
        echo "Adding $USER to 'input' group..."
        sudo usermod -aG input "$USER"
        echo "User added to 'input' group. You may need to log out and back in for this to take effect."
    fi

    echo "ydotool is configured."
    echo ""
fi

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

# Start ydotoold daemon for Wayland support (if installed)
if command -v ydotoold &> /dev/null; then
    # Check if daemon is already running
    if ! pgrep -x ydotoold > /dev/null; then
        echo "Starting ydotoold daemon..."
        ydotoold &
        sleep 0.5
    fi
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
echo ""
if [[ "$USE_YDOTOOL" == true ]]; then
    echo "ydotool was installed for Wayland input simulation. The linux_automator.sh"
    echo "script will automatically start the ydotoold daemon."
    echo ""
    echo "If you encounter 'permission denied' errors, log out and back in for"
    echo "the group/udev changes to take effect, or run: newgrp input"
    echo ""
fi
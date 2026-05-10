#!/bin/bash

# Enhanced ADB Wireless Setup Script
# This script automatically sets up wireless ADB when a device is connected

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if ADB is installed and accessible
check_adb() {
    if ! command -v adb &> /dev/null; then
        error "ADB is not installed or not in PATH"
        exit 1
    fi
}

# Wait for device to be connected and authorized
wait_for_device() {
    log "Waiting for device to be connected and authorized..."
    
    local timeout=30
    local count=0
    
    while [ $count -lt $timeout ]; do
        if adb get-state &>/dev/null; then
            local state=$(adb get-state 2>/dev/null)
            if [ "$state" = "device" ]; then
                success "Device connected and authorized"
                return 0
            elif [ "$state" = "unauthorized" ]; then
                warning "Device connected but unauthorized. Please check your device and accept USB debugging."
            fi
        fi
        sleep 1
        ((count++))
    done
    
    error "Timeout waiting for authorized device"
    return 1
}

# Get device IP address using multiple methods
get_device_ip() {
    log "Getting device IP address..."
    
    # Method 1: Try ip route (most reliable for newer Android versions)
    local ip=$(adb shell "ip route | grep wlan0" 2>/dev/null | awk '{print $9}' | head -n1)
    
    # Method 2: Try ifconfig if ip route fails
    if [ -z "$ip" ]; then
        ip=$(adb shell "ifconfig wlan0" 2>/dev/null | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
    fi
    
    # Method 3: Try ip addr show
    if [ -z "$ip" ]; then
        ip=$(adb shell "ip addr show wlan0" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | head -n1)
    fi
    
    # Method 4: Try netcfg (older Android versions)
    if [ -z "$ip" ]; then
        ip=$(adb shell "netcfg | grep wlan0" 2>/dev/null | awk '{print $3}' | cut -d'/' -f1)
    fi
    
    if [ -z "$ip" ] || [ "$ip" = "0.0.0.0" ]; then
        error "Could not get device IP address. Make sure device is connected to WiFi"
        return 1
    fi
    
    # Validate IP format
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        error "Invalid IP address format: $ip"
        return 1
    fi
    
    success "Device IP: $ip"
    echo "$ip"
}

# Setup TCP/IP mode
setup_tcpip() {
    local port=${1:-5555}
    log "Setting up TCP/IP mode on port $port..."
    
    if adb tcpip "$port"; then
        success "TCP/IP mode enabled on port $port"
        sleep 2  # Give device time to restart ADB in TCP mode
        return 0
    else
        error "Failed to enable TCP/IP mode"
        return 1
    fi
}

# Connect to device wirelessly
connect_wireless() {
    local ip="$1"
    local port="${2:-5555}"
    local target="${ip}:${port}"
    
    log "Connecting to $target..."
    
    # First disconnect any existing connections to avoid conflicts
    adb disconnect "$target" &>/dev/null || true
    
    if adb connect "$target"; then
        success "Connected to $target"
        
        # Verify connection
        sleep 2
        if adb -s "$target" get-state &>/dev/null; then
            success "Wireless connection verified"
            return 0
        else
            error "Wireless connection failed verification"
            return 1
        fi
    else
        error "Failed to connect to $target"
        return 1
    fi
}

# Check if Flutter is available and run it
run_flutter() {
    if command -v flutter &> /dev/null; then
        log "Starting Flutter application..."
        flutter run
    else
        warning "Flutter not found in PATH. Skipping Flutter run."
        log "You can manually run 'flutter run' now that wireless ADB is set up"
    fi
}

# Main function
main() {
    log "Starting ADB Wireless Setup..."
    
    check_adb
    
    if ! wait_for_device; then
        exit 1
    fi
    
    local device_ip
    if ! device_ip=$(get_device_ip); then
        exit 1
    fi
    
    if ! setup_tcpip 5555; then
        exit 1
    fi
    
    if ! connect_wireless "$device_ip" 5555; then
        exit 1
    fi
    
    success "ADB Wireless setup complete!"
    log "You can now unplug your device and use: adb connect ${device_ip}:5555"
    
    # Ask user if they want to run Flutter
    read -p "Do you want to run Flutter now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_flutter
    fi
}

# Handle script interruption
trap 'error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
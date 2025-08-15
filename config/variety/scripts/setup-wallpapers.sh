#!/bin/bash

# ═══════════════════════════════════════════════════
# Variety Wallpaper Setup Script
# Initialize wallpaper directories and download samples
# ═══════════════════════════════════════════════════

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create necessary directories
print_info "Creating wallpaper directories..."

mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/Pictures/Favorites
mkdir -p ~/.config/variety/Downloaded
mkdir -p ~/.config/variety/Fetched
mkdir -p ~/.config/variety/scripts

print_success "Directories created successfully"

# Download some default wallpapers if they don't exist
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

if [ ! -f "$WALLPAPER_DIR/default.jpg" ]; then
    print_info "Downloading default wallpapers..."
    
    # Create a simple gradient as fallback
    if command -v convert >/dev/null 2>&1; then
        convert -size 1920x1080 gradient:#2c3e50-#3498db "$WALLPAPER_DIR/default.jpg"
        print_success "Created default gradient wallpaper"
    else
        print_warning "ImageMagick not found, skipping default wallpaper creation"
        print_info "You can manually add wallpapers to $WALLPAPER_DIR/"
    fi
    
    # Create a simple solid color as fallback
    if command -v convert >/dev/null 2>&1; then
        convert -size 1920x1080 xc:#34495e "$WALLPAPER_DIR/fallback.png"
        print_success "Created fallback solid color wallpaper"
    fi
else
    print_info "Default wallpapers already exist"
fi

# Set up variety configuration
print_info "Setting up Variety configuration..."

# Ensure variety config directory exists
mkdir -p ~/.config/variety

# Create initial variety database if it doesn't exist
if [ ! -f ~/.config/variety/variety.db ]; then
    print_info "Creating initial Variety database..."
    variety --help > /dev/null 2>&1 || print_warning "Variety not installed, install with: sudo dnf install variety"
fi

print_success "Wallpaper setup completed!"

print_info "To use:"
print_info "1. Add wallpapers to $WALLPAPER_DIR/"
print_info "2. Run 'variety' to start the wallpaper manager"
print_info "3. Use Super+Alt+N/P to cycle through wallpapers (via swhkd)"
print_info "4. Use Super+Alt+F to favorite current wallpaper"
print_info "5. Use Super+Alt+T to trash current wallpaper"

# Check if variety is running
if pgrep -x "variety" > /dev/null; then
    print_success "Variety is already running"
else
    print_info "To start variety: variety &"
fi
#!/bin/bash

# Define color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}🚫 Please run as root or with sudo${NC}"
    exit 1
fi

# Enhanced Dependencies Check and Installation
check_and_install_dependencies() {
    local missing_deps=()
    
    # Array of required commands
    local required_commands=(
        "curl"
        "wget"
        "dig"
        "nc"
        "traceroute"
        "speedtest-cli"
        "jq"
    )
    
    echo "🔍 Checking required dependencies..."
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${YELLOW}📦 Missing dependencies: ${missing_deps[*]}${NC}"
        echo "🔄 Installing missing dependencies..."
        
        if command -v pacman &> /dev/null; then
            # For Arch Linux systems
            sudo pacman -S --needed --noconfirm dnsutils netcat traceroute jq || {
                echo -e "${RED}❌ Failed to install some packages with pacman.${NC}"
                exit 1
            }
            # Install speedtest-cli from AUR if missing
            if [[ " ${missing_deps[@]} " =~ " speedtest-cli " ]]; then
                if ! command -v yay &> /dev/null; then
                    echo "📦 Installing yay (AUR helper)..."
                    sudo pacman -S --needed --noconfirm base-devel git
                    git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd ..
                    rm -rf yay
                fi
                yay -S --noconfirm speedtest-cli || {
                    echo -e "${RED}❌ Failed to install speedtest-cli from AUR.${NC}"
                    exit 1
                }
            fi
        elif command -v apt-get &> /dev/null; then
            # For Debian-based systems
            sudo apt-get update
            sudo apt-get install -y dnsutils net-tools curl wget netcat traceroute jq speedtest-cli
        elif command -v yum &> /dev/null; then
            # For RHEL-based systems
            sudo yum install -y bind-utils net-tools curl wget nc traceroute jq
            curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
            sudo yum install speedtest-cli
        elif command -v brew &> /dev/null; then
            # For macOS with Homebrew
            brew install bind dnsutils net-tools curl wget netcat traceroute speedtest-cli jq
        else
            echo -e "${RED}❌ Unsupported package manager. Please install the following manually: ${missing_deps[*]}${NC}"
            exit 1
        fi
        
        # Verify installation
        for cmd in "${missing_deps[@]}"; do
            if ! command -v $cmd &> /dev/null; then
                echo -e "${RED}❌ Failed to install $cmd${NC}"
                exit 1
            fi
        done
        
        echo -e "${GREEN}✅ All dependencies installed successfully${NC}"
    else
        echo -e "${GREEN}✅ All dependencies are already installed${NC}"
    fi
}

# 🌐 Enhanced Network Connectivity Tester
test_connectivity() {
    local target="${1:-8.8.8.8}"
    echo "🔄 Testing network connectivity to $target..."
    
    # Resolve IP if domain name provided
    local ip
    ip=$(dig +short "$target" | tail -n1)
    if [ -z "$ip" ]; then
        echo -e "${RED}❌ Could not resolve hostname${NC}"
        return 1
    fi
    
    # Test basic connectivity
    if ping -c 4 "$target" &> /dev/null; then
        echo -e "${GREEN}✅ Network is reachable${NC}"
        ping -c 10 "$target" | tail -1 | awk '{print "📊 Average RTT: " $4 "ms"}'
        
        # Test route with timeout
        echo -e "\n🛣️  Route to destination:"
        timeout 30 traceroute "$target" || echo -e "${RED}❌ Traceroute timed out${NC}"
    else
        echo -e "${RED}❌ Network is unreachable${NC}"
    fi
}

# 🔍 Enhanced Port Availability Checker
check_port() {
    local host="${1:-localhost}"
    local port="${2:-80}"
    echo "🔍 Checking port $port on $host..."
    
    # Validate port number
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}❌ Invalid port number${NC}"
        return 1
    fi
    
    # Try NC connection with timeout
    if timeout 10 nc -zv "$host" "$port" 2>&1; then
        echo -e "${GREEN}✅ Port $port is open on $host${NC}"
        # Get service name if possible
        local service
        service=$(grep -w "$port/tcp" /etc/services | awk '{print $1}' | head -1)
        [[ -n "$service" ]] && echo "🏷️  Service: $service"
    else
        echo -e "${RED}❌ Port $port is closed or filtered on $host${NC}"
    fi
}

# 📝 Enhanced DNS Record Validator
validate_dns() {
    local domain="${1:-example.com}"
    echo "🔍 Checking DNS records for $domain..."
    
    # Validate domain format
    if ! echo "$domain" | grep -P '(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)' > /dev/null; then
        echo -e "${RED}❌ Invalid domain format${NC}"
        return 1
    fi
    
    local records=("A" "AAAA" "MX" "NS" "TXT" "CNAME")
    
    for record in "${records[@]}"; do
        echo -e "\n📍 $record Record:"
        local result
        result=$(dig +short "$record" "$domain")
        if [ -z "$result" ]; then
            echo -e "${YELLOW}No $record records found${NC}"
        else
            echo "$result"
        fi
    done
}

# 🏥 Enhanced API Health Monitor
monitor_api() {
    local endpoint="$1"
    local interval="${2:-60}"
    
    # Validate endpoint
    if [[ ! $endpoint =~ ^https?:// ]]; then
        endpoint="http://$endpoint"
    fi
    
    echo "🔄 Monitoring API endpoint: $endpoint (every $interval seconds)"
    
    while true; do
        local start=$(date +%s%N)
        local response=$(curl -sL -w "\n%{http_code},%{time_total}" --max-time 30 "$endpoint")
        local status=$(echo "$response" | tail -n1 | cut -d',' -f1)
        local time=$(echo "$response" | tail -n1 | cut -d',' -f2)
        local body=$(echo "$response" | head -n-1)
        
        echo "⏱️  $(date '+%Y-%m-%d %H:%M:%S')"
        
        if [ "$status" = "000" ]; then
            echo -e "${RED}❌ Connection failed or timed out${NC}"
        else
            echo -e "📊 Status: $status"
            echo "⌛ Response time: ${time}s"
            
            if [[ $status -lt 200 || $status -gt 299 ]]; then
                echo -e "${RED}❌ Error response:${NC}"
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
        fi
        
        echo -e "\n---"
        sleep $interval
    done
}

# 🚀 Network Speed Tester
test_speed() {
    echo "🔄 Running speed test..."
    speedtest-cli --simple

    # Test to specific servers
    echo -e "\n📊 Testing connection to major cloud providers..."

    # AWS
    echo "☁️  AWS:"
    curl -o /dev/null -s -w "Connection time: %{time_connect}s\nTotal time: %{time_total}s\n" http://ec2.amazonaws.com || echo -e "${RED}❌ Failed to connect to AWS${NC}"

    # Google Cloud
    echo -e "\n☁️  Google Cloud:"
    curl -o /dev/null -s -L -w "Connection time: %{time_connect}s\nTotal time: %{time_total}s\n" https://cloud.google.com || echo -e "${RED}❌ Failed to connect to Google Cloud${NC}"

    # Azure
    echo -e "\n☁️  Azure:"
    curl -o /dev/null -s -w "Connection time: %{time_connect}s\nTotal time: %{time_total}s\n" https://azure.microsoft.com || echo -e "${RED}❌ Failed to connect to Azure${NC}"
}


# 📊 Additional ML-related Network Monitoring
monitor_ml_endpoints() {
    local model_endpoint="${1:-http://localhost:8501}"
    echo "🤖 Monitoring ML model endpoint: $model_endpoint"
    
    # Test latency with dummy request
    curl -X POST "$model_endpoint/v1/models/model:predict" \
         -d '{"instances": [[1.0, 2.0, 3.0]]}' \
         -H "Content-Type: application/json" \
         -w "\n⌛ Response time: %{time_total}s\n"
}

# 📋 Main menu
main_menu() {
    # First check dependencies
    check_and_install_dependencies
    
    while true; do
        echo -e "\n🛠️  Network Testing Toolkit"
        echo "1) 🌐 Test Network Connectivity"
        echo "2) 🔍 Check Port Availability"
        echo "3) 📝 Validate DNS Records"
        echo "4) 🏥 Monitor API Health"
        echo "5) 🚀 Test Network Speed"
        echo "6) ❌ Exit"
        
        read -p "Select an option: " choice
        
        case $choice in
            1) read -p "Enter target host [default: 8.8.8.8]: " target
               test_connectivity ${target:-8.8.8.8}
               ;;
            2) read -p "Enter host [default: localhost]: " host
               read -p "Enter port [default: 80]: " port
               check_port ${host:-localhost} ${port:-80}
               ;;
            3) read -p "Enter domain: " domain
               validate_dns "$domain"
               ;;
            4) read -p "Enter API endpoint (e.g., api.example.com/health): " endpoint
               read -p "Enter check interval (seconds) [default: 60]: " interval
               monitor_api "$endpoint" ${interval:-60}
               ;;
            5) test_speed
               ;;
            6) echo "👋 Goodbye!"; exit 0
               ;;
            *) echo -e "${RED}❌ Invalid option${NC}"
               ;;
        esac
    done
}

# Start the script
main_menu
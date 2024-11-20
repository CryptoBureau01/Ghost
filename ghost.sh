# !/bin/bash

curl -s https://raw.githubusercontent.com/CryptoBureau01/logo/main/logo.sh | bash
sleep 5

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}



#Function to check system type and root privileges
master_fun() {
    echo "Checking system requirements..."

    # Check if the system is Ubuntu
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            echo "This script is designed for Ubuntu. Exiting."
            exit 1
        fi
    else
        echo "Cannot detect operating system. Exiting."
        exit 1
    fi

    # Check if the user is root
    if [ "$EUID" -ne 0 ]; then
        echo "You are not running as root. Please enter root password to proceed."
        sudo -k  # Force the user to enter password
        if sudo true; then
            echo "Switched to root user."
        else
            echo "Failed to gain root privileges. Exiting."
            exit 1
        fi
    else
        echo "You are running as root."
    fi

    echo "System check passed. Proceeding to package installation..."
}


# Function to install dependencies
install_dependency() {
    print_info "<=========== Install Dependency ==============>"
    print_info "Updating and upgrading system packages, and installing curl..."
    sudo apt update && sudo apt upgrade -y && sudo apt install screen build-essential clang make git wget curl -y 
    sudo apt install --assume-yes git clang curl libssl-dev protobuf-compiler
    sudo apt install --assume-yes git clang curl libssl-dev llvm libudev-dev make protobuf-compiler

    # Check if Rust is install
    print_info "Installing Rust..."
    # Download and run the custom Rust installation script
     wget https://raw.githubusercontent.com/CryptoBureau01/packages/main/packages/rust-setup.sh && chmod +x rust-setup.sh && sudo ./rust-setup.sh
     # Check for installation errors
     if [ $? -ne 0 ]; then
        print_error "Failed to install Rust. Please check your system for issues."
        exit 1
     fi

     # Clean up installation script
     sudo rm -rf rust-setup.sh

    # Rust Update 
    rustup update

    # Update Nightly
    rustup update nightly
    rustup target add wasm32-unknown-unknown --toolchain nightly
    rustup target add wasm32-unknown-unknown --toolchain stable-x86_64-unknown-linux-gnu
    rustup target add wasm32-unknown-unknown --toolchain default
    
    # Print Rust versions to confirm installation
    print_info "Checking Rust version..."
    rustc --version

    print_info "Checking Rust version Show..."
    rustup show
    rustup +nightly show

    print_info "Allow Port 30333..."
    sudo ufw numbered
    sudo ufw enable
    sudo ufw allow 30333

    # Call the uni_menu function to display the menu
    master
}



# Function to set up the Ghost node directory and clone the repository
setup_node() {
    echo "Setting up the Ghost node directory..."
    mkdir -p ghost && cd ghost
    echo "Cloning the Ghost node repository..."
    git clone https://git.ghostchain.io/ghostchain/ghost-node.git
    cd ghost-node

    # Call the uni_menu function to display the menu
    master
}


# Function to check directory and run build command
connect_node() {
    GHOST_NODE_DIR="/root/ghost/ghost-node"

    if [ -d "$GHOST_NODE_DIR" ]; then
        echo "Directory $GHOST_NODE_DIR exists."
        cd "$GHOST_NODE_DIR"
        
        echo "Starting the build process in a screen session. This may take approximately 30 minutes..."
        
        # Start a detached screen session and run the build command
        screen -dmS ghost_build bash -c "cargo build --release; exec bash"
        
        echo "The build process is running in a screen session named 'ghost_build'."
        echo "You can reattach to the screen session using: screen -r ghost_build"
    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the uni_menu function to display the menu
    master
}




# Function to display menu and prompt user for input
master() {
    print_info "==============================="
    print_info "    GHOST Node Tool Menu      "
    print_info "==============================="
    print_info ""
    print_info "1. Install-Dependency"
    print_info "2. Setup-Ghost"
    print_info "3. Connect-Ghost"
    print_info "4. Exit"
    print_info "" 
    print_info "==============================="
    print_info " Created By : CB-Master "
    print_info "==============================="
    print_info ""
    
    read -p "Enter your choice (1 or 4): " user_choice

    case $user_choice in
        1)
            install_dependency
            ;;
        2)
            setup_node
            ;;
        3) 
            connect_node
            ;;
        4)
            exit 0  # Exit the script after breaking the loop
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 3 : "
            ;;
    esac
}

# Call the uni_menu function to display the menu
master_fun
master

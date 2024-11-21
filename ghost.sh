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
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    sudo apt install --assume-yes git clang curl libssl-dev protobuf-compiler
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
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

    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    # Rust Update 
    rustup update

    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    # Update Nightly
    rustup update nightly
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    rustup target add wasm32-unknown-unknown --toolchain nightly
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    rustup target add wasm32-unknown-unknown --toolchain stable-x86_64-unknown-linux-gnu
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    rustup target add wasm32-unknown-unknown --toolchain default
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    rustup component add rust-src --toolchain stable
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    rustup component add rust-src --toolchain default
    
    # Print Rust versions to confirm installation
    print_info "Checking Rust version..."
    rustc --version

    print_info "Checking Rust version Show..."
    rustup show
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    rustup +nightly show

    print_info "Allow Port 30333..."
    sudo ufw numbered
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    sudo ufw enable
    print_info "Please wait ..."
    sleep 1 // wait 1 secound
    sudo ufw allow 30333

    # Call the uni_menu function to display the menu
    master
}



# Function to set up the Ghost node directory and clone the repository
install_node() {
    echo "Setting up the Ghost node directory..."
    mkdir -p ghost && cd ghost
    echo "Cloning the Ghost node repository..."
    git clone https://git.ghostchain.io/ghostchain/ghost-node.git
    cd ghost-node

    # Call the uni_menu function to display the menu
    master
}


# Function to check directory and run build command
setup_node() {
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


# Function to connect to the node and update it
connect_node() {
    GHOST_NODE_DIR="/root/ghost/ghost-node"

    if [ -d "$GHOST_NODE_DIR" ]; then
        echo "Directory $GHOST_NODE_DIR exists."
        cd "$GHOST_NODE_DIR"

        # Download spec.json
        echo "Downloading spec.json file..."
        wget -c https://ghostchain.io/wp-content/uploads/2024/09/spec.json -O ~/spec.json

        print_info "Please wait ..."
        sleep 1 // wait 1 secound
        # Git commands to update the repository
        echo "Switching to main branch and updating the repository..."
        print_info "Please wait ..."
        sleep 1 // wait 1 secound
        git switch main
        print_info "Please wait ..."
        sleep 1 // wait 1 secound
        git pull origin main
        print_info "Please wait ..."
        sleep 1 // wait 1 secound
        git fetch --tags
        print_info "Please wait ..."
        sleep 1 // wait 1 secound
        git checkout v0.0.2

    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the uni_menu function to display the menu
    master
}


# Function to set up services
services_setup() {
    # Create /etc/ghost directory
    echo "Creating /etc/ghost directory..."
    sudo mkdir -p /etc/ghost

    # Navigate to the Ghost node directory
    GHOST_NODE_DIR="/root/ghost/ghost-node"

    if [ -d "$GHOST_NODE_DIR" ]; then
        echo "Directory $GHOST_NODE_DIR exists."
        cd "$GHOST_NODE_DIR"

        # Run the starter script
        echo "Running the starter script to make the service global..."
        ./scripts/starter.sh --make-global
        echo "Starter script executed successfully."

        # Step 4: Run the starter script to set arguments
        echo "Running the starter script to set arguments..."
        ./scripts/starter.sh --set-arguments
        echo "Starter script '--set-arguments' executed successfully."
    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the uni_menu function to display the menu
    master
}


create_wallet() {
    echo "==================================="
    echo "         Creating Wallet           "
    echo "==================================="

    # Step 1: Check if the folder exists and change ownership
    if [ -d "/etc/ghost" ]; then
        echo "Directory /etc/ghost exists. Changing ownership..."
        sudo chown root /etc/ghost
    else
        echo "Directory /etc/ghost does not exist. Please create it first using 'sudo mkdir -p /etc/ghost'."
        return 1
    fi

    # Step 2: Generate Node Key
    echo "Generating Node Key..."
    /root/ghost/ghost-node/target/release/ghost key generate-node-key --bin --file=/etc/ghost/node-key
    echo "Node key generated successfully!"
    read -p "Press Enter to continue..."

    # Step 3: Generate Wallet Key
    echo "Generating Wallet Key..."
    ~/ghost/ghost-node/target/release/ghost key generate | grep "Secret seed" | awk '{$1=$2=""; sub(/^[ \t]+/, ""); print}' > /etc/ghost/wallet-key
    echo "Wallet key generated successfully!"
    read -p "Press Enter to display the wallet key..."

    # Display Wallet Key
    echo "Displaying Wallet Key:"
    ~/ghost/ghost-node/target/release/ghost key inspect $(cat /etc/ghost/wallet-key)
    read -p "Press Enter to continue..."

    # Step 4: Generate Stash Key
    echo "Generating Stash Key..."
    ~/ghost/ghost-node/target/release/ghost key generate | grep "Secret seed" | awk '{$1=$2=""; sub(/^[ \t]+/, ""); print}' > /etc/ghost/stash-key
    echo "Stash key generated successfully!"
    read -p "Press Enter to display the stash key..."

    # Display Stash Key
    echo "Displaying Stash Key:"
    ~/ghost/ghost-node/target/release/ghost key inspect $(cat /etc/ghost/stash-key)
    read -p "Press Enter to continue..."

    # Step 5: Generate Session Key
    echo "Generating Session Key..."
    ~/ghost/ghost-node/target/release/ghost key generate | grep "Secret seed" | awk '{$1=$2=""; sub(/^[ \t]+/, ""); print}' > /etc/ghost/session-key
    echo "Session key generated successfully!"
    read -p "Press Enter to display session keys..."

    # Display Session Keys
    echo "Displaying Session Key - AUDI:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//audi"
    read -p "Press Enter to continue..."

    echo "Displaying Session Key - BABE:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//babe"
    read -p "Press Enter to continue..."

    echo "Displaying Session Key - SLOW:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//slow"
    read -p "Press Enter to continue..."

    echo "Displaying Session Key - GRAN:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//gran" --scheme=ed25519
    read -p "Press Enter to finish..."

    echo "==================================="
    echo "        Wallet Setup Complete      "
    echo "==================================="

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
    print_info "2. Install-Ghost"
    print_info "3. Setup-Ghost"
    print_info "4. Connect-Ghost"
    print_info "5. Service-Setup" 
    print_info "6. Create-Wallet"
    print_info "7. Exit"
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
            install_node
            ;;
        3) 
            setup_node
            ;;
        4)
            connect_node
            ;;
        5)
            services_setup
            ;;
        6)
            create_wallet
            ;;
        7)
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

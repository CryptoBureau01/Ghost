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


# install rustc and cargo 
rust_setup() {
    # Step 1: Inform the user about the installation process
    echo "Starting the Rust setup process..."
    
    # Step 2: Update the package index (optional but recommended)
    echo "Updating package index..."
    sudo apt update -y
    
    print_info "Please wait ..."
    sleep 1
    # Step 3: Install the Rust toolchain using rustup
    echo "Installing Rust (rustc and cargo)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    print_info "Please wait ..."
    sleep 1
    # Step 4: Source the environment file to make Rust commands available
    echo "Configuring Rust environment..."
    source "$HOME/.cargo/env"

    print_info "Please wait ..."
    sleep 1
    # Step 5: Verify the installation of rustc
    echo "Verifying rustc installation..."
    if command -v rustc > /dev/null 2>&1; then
        echo "Rustc installed successfully. Version: $(rustc --version)"
    else
        echo "Error: Rustc installation failed!"
        exit 1
    fi

    print_info "Please wait ..."
    sleep 1
    # Step 6: Verify the installation of cargo
    echo "Verifying cargo installation..."
    if command -v cargo > /dev/null 2>&1; then
        echo "Cargo installed successfully. Version: $(cargo --version)"
    else
        echo "Error: Cargo installation failed!"
        exit 1
    fi

    # Final Step: Inform the user that setup is complete
    echo "Rust setup completed successfully!"
}


# Function to install dependencies
install_dependency() {
    print_info "<=========== Install Dependency ==============>"

    # System Update and Installing Required Packages
    print_info "Updating system and installing essential packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y screen nano net-tools build-essential clang make git wget jq curl libssl-dev protobuf-compiler llvm traceroute

    print_info "Please wait ..."
    sleep 1 

    # Rust Installation with rust_setup function
    print_info "Installing Rust..."
    rust_setup || { echo "Rust setup failed! Exiting."; exit 1; }

    print_info "Please wait ..."
    sleep 1 
    print_info "Updating Rust to the latest version..."
    rustup update || { echo "Rust update failed! Exiting."; exit 1; }
    rustup update nightly
    rustup target add wasm32-unknown-unknown --toolchain nightly
    print_info "Please wait ..."
    sleep 1 
    rustup target add wasm32-unknown-unknown --toolchain stable-x86_64-unknown-linux-gnu
    print_info "Please wait ..."
    sleep 1 
    rustup target add wasm32-unknown-unknown --toolchain stable
    rustup component add rust-src --toolchain stable

    print_info "Please wait ..."
    sleep 1
    print_info "Rust installation completed."
    rustc --version || { echo "Rust compiler is not working! Exiting."; exit 1; }
    rustup show
    rustup +nightly show

    print_info "Please wait ..."
    sleep 1
    # Configure SSH and Firewall
    print_info "Configuring SSH and firewall settings..."
    sudo systemctl enable ssh
    sudo apt install -y ufw
    sudo ufw allow ssh
    sudo ufw enable || { echo "Firewall setup failed! Exiting."; exit 1; }
    sudo ufw allow 30333
    sudo ufw deny 9945

    # Allow numbered rules for firewall
    print_info "Configuring firewall rules..."
    sudo ufw numbered

    # Final Confirmation
    print_info "Dependency installation and configuration completed."

    # Call the Master function to display the menu
    master
}


# Function to set up the Ghost node directory and clone the repository
install_node() {
    echo "Setting up the Ghost node directory..."
    mkdir -p ghost && cd ghost
    echo "Cloning the Ghost node repository..."
    git clone https://git.ghostchain.io/ghostchain/ghost-node.git
    cd ghost-node

    # Call the Master function to display the menu
    master
}

# Function to install traceroute and manage firewall rules
bind_NAT() {
    echo "Installing traceroute..."
    sudo apt update && sudo apt install -y traceroute
    if [ $? -eq 0 ]; then
        echo "Traceroute installed successfully."
    else
        echo "Failed to install traceroute. Exiting."
        exit 1
    fi

    echo "Allowing port 30333..."
    sudo ufw allow 30333
    if [ $? -eq 0 ]; then
        echo "Port 30333 allowed successfully."
    else
        echo "Failed to allow port 30333."
    fi

    echo "Denying port 9945..."
    sudo ufw deny 9945
    if [ $? -eq 0 ]; then
        echo "Port 9945 denied successfully."
    else
        echo "Failed to deny port 9945."
    fi

    echo "Bind-NAT function completed."

    # Call the Master function to display the menu
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

    # Call the Master function to display the menu
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
        sleep 1 
        # Git commands to update the repository
        echo "Switching to main branch and updating the repository..."
        print_info "Please wait ..."
        sleep 1 
        git switch main
        print_info "Please wait ..."
        sleep 1 
        git pull origin main
        print_info "Please wait ..."
        sleep 1 
        git fetch --tags
        print_info "Please wait ..."
        sleep 1 
        git checkout v0.0.2

    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the Master function to display the menu
    master
}


# Function to set up services add enter all details 
services_build() {
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
    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the Master function to display the menu
    master
}


# Function to set up services add enter all details 
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
        sha256sum /etc/ghost/casper.json
        echo "Starter script executed successfully."

        print_info "Please wait ..."
        sleep 1 
        # Step 4: Run the starter script to set arguments
        echo "Running the starter script to set arguments..."
        ./scripts/starter.sh --set-arguments
        echo "Starter script '--set-arguments' executed successfully."
        
    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the Master function to display the menu
    master
}


create_wallet() {
    echo "====================================================================================="
    echo "                         Creating Wallet                                             "
    echo "====================================================================================="

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
    ~/ghost/ghost-node/target/release/ghost key inspect $(cat /etc/ghost/wallet-key) --scheme=ed25519
    read -p "Press Enter to continue..."

    # Step 4: Generate Stash Key
    echo "Generating Stash Key..."
    ~/ghost/ghost-node/target/release/ghost key generate | grep "Secret seed" | awk '{$1=$2=""; sub(/^[ \t]+/, ""); print}' > /etc/ghost/stash-key
    echo "Stash key generated successfully!"
    read -p "Press Enter to display the stash key..."

    # Display Stash Key
    echo "Displaying Stash Key:"
    ~/ghost/ghost-node/target/release/ghost key inspect $(cat /etc/ghost/stash-key) --scheme=ed25519
    read -p "Press Enter to continue..."

    # Step 5: Generate Session Key
    echo "Generating Session Key..."
    ~/ghost/ghost-node/target/release/ghost key generate | grep "Secret seed" | awk '{$1=$2=""; sub(/^[ \t]+/, ""); print}' > /etc/ghost/session-key
    echo "Session key generated successfully!"
    read -p "Press Enter to display session keys..."

    # Display Session Keys
    echo "Displaying Session Key - AUDI:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//audi" --scheme=ed25519
    read -p "Press Enter to continue..."

    echo "Displaying Session Key - BABE:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//babe" --scheme=ed25519
    read -p "Press Enter to continue..."

    echo "Displaying Session Key - SLOW:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//slow" --scheme=ed25519
    read -p "Press Enter to continue..."

    echo "Displaying Session Key - GRAN:"
    ~/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//gran" --scheme=ed25519
    read -p "Press Enter to finish..."

    echo "====================================================================================="
    echo "                     Wallet Setup Complete                                           "
    echo "====================================================================================="

    # Call the Master function to display the menu
    master
}



save_keys() {
    # Check if wallet.txt already exists
    if [ -f "/root/wallet.txt" ]; then
        echo "File wallet.txt already exists. Skipping creation..."
    else
        echo "Creating wallet.txt file..."
        touch /root/wallet.txt
        echo "File wallet.txt created successfully."
    fi

    # Append outputs of all commands to wallet.txt
    echo "=====================================================================================" >> /root/wallet.txt
    echo "                       Ghost Saving Keys Details                                     " >> /root/wallet.txt
    echo "=====================================================================================" >> /root/wallet.txt

    echo -e "\n\n" >> /root/ghost/ghost-node/wallet.txt
    # Save Node Key Inspection Output
    echo "Inspecting Node Key:" >> /root/wallet.txt
    /root/ghost/ghost-node/target/release/ghost key inspect-node-key --bin --file=/etc/ghost/node-key >> /root/wallet.txt 2>&1
    echo -e "\n\n" >> /root/wallet.txt
    
    # Save Wallet Key Inspection Output
    echo "Inspecting Wallet Key:" >> /root/wallet.txt
    /root/ghost/ghost-node/target/release/ghost key inspect $(cat /etc/ghost/wallet-key) >> /root/wallet.txt 2>&1
    echo -e "\n\n" >> /root/wallet.txt
    
    # Save Stash Key Inspection Output
    echo "Inspecting Stash Key:" >> /root/wallet.txt
    /root/ghost/ghost-node/target/release/ghost key inspect $(cat /etc/ghost/stash-key) >> /root/wallet.txt 2>&1
    echo -e "\n\n" >> /root/wallet.txt
    
    # Save Session Keys Inspection Outputs
    echo "Inspecting Session Key - AUDI:" >> /root/wallet.txt
    /root/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//audi" >> /root/wallet.txt 2>&1
    echo -e "\n\n" >> /root/wallet.txt
    
    echo "Inspecting Session Key - BABE:" >> /root/wallet.txt
    /root/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//babe" >> /root/wallet.txt 2>&1
    echo -e "\n\n" >> /root/wallet.txt
    
    echo "Inspecting Session Key - SLOW:" >> /root/wallet.txt
    /root/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//slow" >> /root/wallet.txt 2>&1
    echo -e "\n\n" >> /root/wallet.txt
    
    echo "Inspecting Session Key - GRAN:" >> /root/wallet.txt
    /root/ghost/ghost-node/target/release/ghost key inspect "$(cat /etc/ghost/session-key)//gran" >> /root/wallet.txt 2>&1
    echo -e "\n\n" >> /root/wallet.txt
    echo "=====================================================================================" >> /root/wallet.txt
    echo "                      Ghost Keys Saved Successfully                                  " >> /root/wallet.txt
    echo "=====================================================================================" >> /root/wallet.txt

    echo "All keys' details have been saved to /root/wallet.txt"

    # Call the Master function to display the menu
    master
}


keys_update_server() {
    echo "Reading wallet details from /root/wallet.txt..."
    
    # Define wallet file path
    WALLET_FILE="/root/wallet.txt"

    # Check if wallet file exists
    if [ ! -f "$WALLET_FILE" ]; then
        echo "Error: Wallet file not found at $WALLET_FILE."
        return 1
    fi

    # Extract keys using grep, awk, and sed
    LOCAL_IDENTITY=$(grep -A 1 "Inspecting Node Key" "$WALLET_FILE" | tail -n 1 | awk '{print $1}')
    WALLET_KEY=$(grep -A 4 "Inspecting Wallet Key" "$WALLET_FILE" | grep "Public key (hex)" | awk '{print $4}')
    STASH_KEY=$(grep -A 4 "Inspecting Stash Key" "$WALLET_FILE" | grep "Public key (hex)" | awk '{print $4}')
    AUDI_KEY=$(grep -A 4 "Inspecting Session Key - AUDI" "$WALLET_FILE" | grep "Public key (hex)" | awk '{print $4}')
    BABE_KEY=$(grep -A 4 "Inspecting Session Key - BABE" "$WALLET_FILE" | grep "Public key (hex)" | awk '{print $4}')
    SLOW_KEY=$(grep -A 4 "Inspecting Session Key - SLOW" "$WALLET_FILE" | grep "Public key (hex)" | awk '{print $4}')
    GRAN_KEY=$(grep -A 4 "Inspecting Session Key - GRAN" "$WALLET_FILE" | grep "Public key (hex)" | awk '{print $4}')

    # Display the keys
    echo "Local Identity: $LOCAL_IDENTITY"
    echo "Wallet Key: $WALLET_KEY"
    echo "Stash Key: $STASH_KEY"
    echo "Audi Key: $AUDI_KEY"
    echo "Babe Key: $BABE_KEY"
    echo "Slow Key: $SLOW_KEY"
    echo "Gran Key: $GRAN_KEY"

    # Wait for user confirmation
    read -p "Press Enter to continue..."

    print_info "Please wait ..."
    sleep 1 

    # Navigate to the Ghost node directory
    GHOST_NODE_DIR="/root/ghost/ghost-node"
    if [ -d "$GHOST_NODE_DIR" ]; then
        echo "Navigating to $GHOST_NODE_DIR..."
        cd "$GHOST_NODE_DIR" || { echo "Failed to navigate to $GHOST_NODE_DIR."; return 1; }
    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        return 1
    fi

    print_info "Please wait ..."
    sleep 1 
    
    # Pull latest changes from Git and create a new branch
    echo "Fetching the latest changes from Git..."
    git pull origin main
    print_info "Please wait ..."
    sleep 1 
    read -p "Enter the branch name to create: " branch_name
    git checkout -b "$branch_name"

    print_info "Please wait ..."
    sleep 1 
    # Check if the git.txt file exists, and either create or update it
    GIT_FILE="/root/git.txt"
    if [ -f "$GIT_FILE" ]; then
        echo "File exists. Updating branch name..."
    else
        echo "File does not exist. Creating file..."
    fi

    # Update or create the file with the branch name
    echo "$branch_name" > "$GIT_FILE"

    
    # Update service/ghosties file
    SERVICE_FILE="$GHOST_NODE_DIR/service/ghosties"
    echo "Updating $SERVICE_FILE with wallet details..."
    {
        echo "### My Submission for Genesis Code - Satoshi ###"
        echo "Local identity             : $LOCAL_IDENTITY"
        echo "Public key (hex) wallet    : $WALLET_KEY"
        echo "=================================================================================================================="
        echo "Public key (hex) stash     : $STASH_KEY"
        echo "Public key (hex) audi      : $AUDI_KEY"
        echo "Public key (hex) babe      : $BABE_KEY"
        echo "Public key (hex) slow      : $SLOW_KEY"
        echo "Public key (hex) gran      : $GRAN_KEY"
    } > "$SERVICE_FILE"

    # Confirmation message
    echo "Keys updated in Ghost server successfully."

    # Call the Master function to display the menu
    master
}


git_ssh_key() {
    # Define paths for the keys and files
    ghost_node_dir="/root/ghost/ghost-node"
    ssh_dir="/root/.ssh"
    git_txt="/root/git.txt"
    git_password_file="$ghost_node_dir/Git_Password"

    # Ensure the /root/ghost/ghost-node folder exists
    mkdir -p "$ghost_node_dir"
    
    # Ensure the /root/.ssh folder exists
    mkdir -p "$ssh_dir"

    # Define default key file location
    default_key="$ghost_node_dir/id_rsa"

    # Prompt the user for the SSH key name (optional)
    read -p "Enter the SSH key name (default is $default_key): " key_name
    if [ -z "$key_name" ]; then
        key_name="$default_key"  # Use the default if no input is provided
    fi

    # Generate SSH key pair without interactive prompts, specifying the key file
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$key_name" -N ""  # -N "" to skip passphrase

    # Check if the key files exist
    private_key="${key_name}"
    public_key="${key_name}.pub"

    if [ -f "$private_key" ] && [ -f "$public_key" ]; then
        echo "SSH key pair generated successfully."

        print_info "Please wait ..."
        sleep 1 
        
        # Save the public key to git.txt with label "SSH key"
        echo "Saving the SSH key to $git_txt..."

        # Append the public key to git.txt
        echo "SSH key: $public_key" >> "$git_txt"
        cat "$public_key" >> "$git_txt"
        echo "" >> "$git_txt"  # Add a new line for separation

        # Create 'Git Password' file
        echo "Git SSH key has been generated and is ready for use." > "$git_password_file"

        print_info "Please wait ..."
        sleep 1 
        
        # Save the Git Password message to git.txt
        echo "Git Password:" >> "$git_txt"
        cat "$git_password_file" >> "$git_txt"

        echo "Git Password and SSH key saved to $git_txt."
    else
        echo "Error: SSH key generation failed. Please try again."
        return 1
    fi

    print_info "Please wait ..."
    sleep 1 
    
    # Copy the keys to the /root/.ssh/ directory with user-provided naming
    echo "Copying the SSH keys to /root/.ssh/..."
    cp "$private_key" "$ssh_dir/$(basename "$private_key")"
    cp "$public_key" "$ssh_dir/$(basename "$public_key")"

    echo "SSH keys copied to /root/.ssh/ with the same names provided by the user."

    print_info "Please wait ..."
    sleep 1 
    
    # Copy the keys to the /root/ghost/ghost-node/ directory with user-provided naming
    echo "Copying the SSH keys to /root/ghost/ghost-node/..."
    cp "$private_key" "$ghost_node_dir/$(basename "$private_key")"
    cp "$public_key" "$ghost_node_dir/$(basename "$public_key")"

    echo "SSH keys copied to /root/ghost/ghost-node/ with the same names provided by the user."

    print_info "Please wait ..."
    sleep 1 
    
    # Configure git to use the SSH key
    git config --global gpg.format ssh
    git config --global user.signingkey "$ssh_dir/$(basename "$private_key")"

    echo "SSH key setup complete."

    # Call the Master function to display the menu
    master
}


key_checker() {
    # Define the target working directory
    WORKING_DIR="/root/ghost/ghost-node"

    echo "Navigating to $WORKING_DIR..."
    cd "$WORKING_DIR" || { echo "Error: Unable to access $WORKING_DIR. Please check if it exists."; exit 1; }

    # Run the command
    echo "Running ./scripts/starter.sh with --check-keys and --insert-keys options..."
    ./scripts/starter.sh --check-keys --insert-keys

    # Check if the command was successful
    if [ $? -eq 0 ]; then
        echo "Command executed successfully."
    else
        echo "Error: Command failed. Please check the script or logs for more details."
    fi

    # Call the Master function to display the menu
    master
}

# Function to set up services add enter all details 
unit_start() {
    # Create /etc/ghost directory
    echo "Creating /etc/ghost directory..."
    sudo mkdir -p /etc/ghost

    # Navigate to the Ghost node directory
    GHOST_NODE_DIR="/root/ghost/ghost-node"

    if [ -d "$GHOST_NODE_DIR" ]; then
        echo "Directory $GHOST_NODE_DIR exists."
        cd "$GHOST_NODE_DIR"
        
        print_info "Please wait ..."
        sleep 1 
        # Step 4: Run the starter script to set arguments
        echo "Running the starter script to set arguments..."
        ./scripts/starter.sh --unit-file
        echo "Starter script '--un8t-file' executed successfully."
        
    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the Master function to display the menu
    master
}

# Function to check VPS IP, traceroute, and port binding
Nat_bind_checker() {
    # Get the VPS IP address
    echo "Fetching VPS IP address..."
    VPS_IP=$(curl -s ifconfig.me)
    
    if [ -z "$VPS_IP" ]; then
        echo "Failed to fetch VPS IP address. Exiting."
        exit 1
    fi

    echo "Your VPS IP is: $VPS_IP"

    # Perform traceroute to the VPS IP
    echo "Running traceroute for VPS IP: $VPS_IP"
    traceroute "$VPS_IP"
    if [ $? -ne 0 ]; then
        echo "Traceroute failed. Exiting."
        exit 1
    fi

    # Check if port 30333 is bound to Ghost node
    echo "Checking if port 30333 is bound to Ghost node..."
    BIND_CHECK=$(sudo netstat -tuln | grep ":30333")

    if [[ -n "$BIND_CHECK" ]]; then
        echo "Port 30333 is successfully bound to Ghost node."
    else
        echo "Port 30333 is not bound. Please check your node configuration."
    fi

    # Call the Master function to display the menu
    master
}

start_service() {
    echo "Starting the ghost-node service..."

    # Run the command to start the service
    sudo systemctl start ghost-node

    # Check if the service started successfully
    if [ $? -eq 0 ]; then
        echo "ghost-node service started successfully."
    else
        echo "Error: Failed to start the ghost-node service. Please check the service status for details."
    fi

    # Call the Master function to display the menu
    master
}


stop_service() {
    echo "Stop the ghost-node service..."

    # Run the command to stop the service
    sudo systemctl stop ghost-node

    # Check if the service started successfully
    if [ $? -eq 0 ]; then
        echo "ghost-node service stoped successfully."
    else
        echo "Error: Failed to start the ghost-node service. Please check the service status for details."
    fi

    # Call the Master function to display the menu
    master
}


reconnect_peers() {

    GHOST_NODE_DIR="/root/ghost/ghost-node"

    # Step 1: Stop the running Ghost node service
    echo "Stopping the Ghost node..."
    sudo systemctl stop ghost-node

    # Inform the user and add a delay for better clarity
    print_info "Please wait ..."
    sleep 1 

    # Step 2: Navigate to the Ghost node folder or exit if not found
    if [ -d "$GHOST_NODE_DIR" ]; then
        echo "Directory $GHOST_NODE_DIR exists."
        cd "$GHOST_NODE_DIR"

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

        # Step 3: Clean up old Ghost node data by removing the folder
        echo "Cleaning up existing Ghost node data..."
        sudo rm -rf /var/lib/ghost

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

        # Step 4: Switch to the 'main' branch in the Git repository
        echo "Switching to the 'main' branch..."
        git switch main

        # Step 5: Pull the latest updates from the Git repository
        echo "Pulling the latest updates from the repository..."
        git pull origin main

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

	# Rust Installation with rust_setup function
        print_info "ReChecking  Rust..."
        rust_setup || { echo "Rust setup failed! Exiting."; exit 1; }

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

        # Step 6: Start the setup process with release and global options
        echo "Starting the setup process..."
        ./scripts/starter.sh --release --make-global

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

        # Step 7: Verify the SHA256 checksum of the Casper JSON file
        echo "Checking SHA256 checksum of the Casper JSON..."
        sha256sum /etc/ghost/casper.json

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

        # Step 8: Set the unit file arguments for the service
        echo "Setting unit file arguments..."
        ./scripts/starter.sh --unit-file --set-arguments

        # Step 9: Perform a keys check
        echo "Checking keys..."
        ./scripts/starter.sh --check-keys

        # Step 10: Start the Ghost node service
        echo "Starting the Ghost node..."
        sudo systemctl start ghost-node

        # Add a delay to allow the service to stabilize
        print_info "Please wait 1 minute ..."
        sleep 60 

        # Step 11: Insert keys into the node
        echo "Inserting keys..."
        ./scripts/starter.sh --check-keys --insert-keys

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

        # Step 12: Restart the Ghost node service
        echo "Restarting the Ghost node..."
        sudo systemctl restart ghost-node

        # Inform the user and add a delay for better clarity
        print_info "Please wait ..."
        sleep 1 

        # Step 13: Enable the Ghost node service for auto-start on boot
        echo "Enabling the Ghost node service..."
        sudo systemctl enable ghost-node

        # Final step: Notify the user of successful completion
        echo "Reconnect process completed successfully!"

    else
        echo "Error: Directory $GHOST_NODE_DIR does not exist."
        echo "Please run the setup_node function first."
        exit 1
    fi

    # Call the Master function to display the menu
    master
}


enable_service() {
    echo "Enabling the ghost-node service to start at boot..."

    # Run the command to enable the service
    sudo systemctl enable ghost-node

    # Check if the service was enabled successfully
    if [ $? -eq 0 ]; then
        echo "ghost-node service enabled successfully."
    else
        echo "Error: Failed to enable the ghost-node service. Please check the service configuration."
    fi

    # Call the Master function to display the menu
    master
}


status_service() {
    echo "Enabling the ghost-node service to status..."

    # Run the command to status the service
    sudo systemctl status ghost-node

    # Check if the service was status successfully
    if [ $? -eq 0 ]; then
        echo "ghost-node service status successfully."
    else
        echo "Error: Failed to enable the ghost-node status. Please check the service configuration."
    fi

    # Call the Master function to display the menu
    master
}


restart_service() {
    echo "Restarting the ghost-node service..."

    # Run the command to restart the service
    sudo systemctl restart ghost-node

    # Check if the service was restarted successfully
    if [ $? -eq 0 ]; then
        echo "ghost-node service restarted successfully."
    else
        echo "Error: Failed to restart the ghost-node service. Please check the service logs for details."
    fi

    # Call the Master function to display the menu
    master
}


# Function to fetch and display the Peer ID (Account ID)
account_id() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "'jq' is not installed. Installing jq now..."
        # Install jq if not present
        sudo apt update && sudo apt install -y jq
        echo "jq has been installed."
    else
        echo "jq is already installed. Proceeding with fetching the Peer ID..."
    fi
    
    # Fetch the Peer ID using curl and jq
    peer_id=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_localPeerId", "params":[]}' http://localhost:9945 | jq -r '.result')

    # Return the Peer ID (Account ID)
    echo "Account ID: $peer_id"

   # Call the Master function to display the menu
   master
}


logs_checker() {
    echo "Checking logs for the ghost-node service..."

    # Run the command to monitor the logs
    sudo journalctl -f -u ghost-node

    # Note: The above command will continue to show logs in real-time until stopped.

    # Call the Master function to display the menu
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
    print_info "3. Bind-NAT"
    print_info "4. Setup-Ghost"
    print_info "5. Connect-Ghost"
    print_info "6. Service-Build" 
    print_info "7. Service-Setup"
    print_info "8. Create-Wallet"
    print_info "9. Save-Keys"
    print_info "10. Keys-Update-Server"
    print_info "11. Git-SSH-Keys"
    print_info "12. Keys-Checker"
    print_info "13. Unit-Start"
    print_info "14. NAT-Bind-Checker"
    print_info "15. Enable-Service"
    print_info "16. Start-Service"
    print_info "17. Stop-Service"
    print_info "18. Reconnect-Peers"
    print_info "19. Restart-Service"
    print_info "20. Status-Checker"
    print_info "21. Account-ID"
    print_info "22. Logs-Checker"
    print_info "23. Exit"
    print_info ""
    print_info "==============================="
    print_info " Created By : CB-Master "
    print_info "==============================="
    print_info ""
    
    read -p "Enter your choice (1 or 23): " user_choice

    case $user_choice in
        1)
            install_dependency
            ;;
        2)
            install_node
            ;;
        3) 
            bind_NAT
            ;;
        4)
            setup_node
            ;;
        5)
            connect_node
            ;;
        6)
            services_build
            ;;
        7)
            services_setup
            ;;
        8)
            create_wallet
            ;;
        9)
            save_keys
            ;;
        10)
            keys_update_server
            ;;
        11)
            git_ssh_key
            ;;
        12)
            key_checker
            ;;
        13)
            unit_start
            ;;
        14)
            Nat_bind_checker
            ;;
        15)
            enable_service
            ;;
        16)
            start_service
            ;;
        17)
            stop_service
            ;;
        18)
            reconnect_peers
            ;;
        19)
            restart_service
            ;;
        20)
            status_service
            ;;
        21)
            account_id
            ;;
        22)
            logs_checker
            ;;
        23)
            exit 0  # Exit the script after breaking the loop
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 23 : "
            ;;
    esac
}

# Call the uni_menu function to display the menu
master_fun
master

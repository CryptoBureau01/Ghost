# Ghost
**Ghost Node Setup With CryptoBureau**

______________________________________________________________________________________________________________________________

## System Requirements

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 4 Cores                 |
| **RAM**      | 6 GB                    |
| **Disk**     | 256 GB                  |
| **Bandwidth**| 60 MBit/s               |



**Follow our TG : https://t.me/CryptoBureau01**

**Follow Ghost TG : https://t.me/realGhostChain**

______________________________________________________________________________________________________________________________

## Tool Installation Command

To install the necessary tools for managing your Ghost Full node, run the following command in your terminal:


```bash

cd $HOME && wget https://raw.githubusercontent.com/CryptoBureau01/Ghost/main/ghost.sh && chmod +x ghost.sh && ./ghost.sh
```


______________________________________________________________________________________________________________________________

# Node Management Script

This script helps you manage Ghost node, providing a simple way to set up, check sync status, view logs, and manage your nodes.

## Features
- **Install Dependencies**: Installs all the required dependencies to set up the Ghost node seamlessly.
- **Node Configuration**: Enables easy setup and configuration of the Ghost node for new users.
- **NAT Binding**: Configures Network Address Translation (NAT) and verifies port binding for node connectivity.
- **Wallet Management**: Simplifies wallet creation, key saving, and updates for seamless integration with the node.
- **Service Management**: Automates creating, starting, stopping, and restarting Ghost node services.
- **Monitoring Tools**: Provides tools to check the status, logs, and synchronization of the node for troubleshooting and maintenance.

---

## Menu Options
The script provides an interactive menu with the following options:

1. **Install-Dependency**  
   Installs all required dependencies such as software packages and tools necessary for running the Ghost node.

2. **Install-Ghost**  
   Downloads and installs the Ghost node software.

3. **Bind-NAT**  
   Configures NAT settings and sets up port 30333 , 9945 bindings for the node.

4. **Setup-Ghost**  
  
   The **Setup-Ghost** option builds the Ghost node:

   - **Directory Check**: Ensures `/root/ghost/ghost-node` exists; otherwise, prompts an error.  
   - **Build Process**: Starts `cargo build --release` in a detached screen session named `ghost_build`, allowing the process to run in the background (takes ~60 minutes).  
   - **Monitor Build**: Use `screen -r ghost_build` to view progress; detach with `Ctrl + A + D`.  
   - **Error Handling**: If the directory is missing, the script exits with instructions to set up the node first.

5. **Connect-Ghost**  
   Connects the Ghost node to the blockchain network.

6. **Service-Build**  
   User Input: During execution, the user is prompted with "Rebuild GHOST Node type: Y" and must type Y to proceed.

7. **Service-Setup**  
 
   The **Service-Setup** option sets up the Ghost node service with specific arguments:

   - **Directory Creation**: Creates the `/etc/ghost` directory if it doesn't exist.  
   - **Directory Check**: Verifies that the Ghost node directory (`/root/ghost/ghost-node`) exists. If not, it exits with instructions to run the `setup_node` function first.  
   - **SHA256 Checksum**: Runs a checksum on `/etc/ghost/casper.json` for verification.  
   - **Starter Script Execution**: 
     - First, runs the script with `--set-arguments` to configure the necessary arguments.
     - Prompts the user during execution:  
       - **Disable bootnode mode [y/N]**: User must type **y** to disable the bootnode mode.  
       - **Boot node address**: User will be prompted to paste the following address:
         ```bash
          /dns/bootnode69.chain.ghostchain.io/tcp/30334/p2p/12D3KooWF9SWxz9dmy6vfndQhoxqCa7PESaoFWEiF8Jkqh4xKDRf
         ```
     
   - **Completion**: Displays a success message after the script runs.
   
8. **Create-Wallet**  
   Helps the user create a new wallet for the Ghost node.

9. **Save-Keys** 

   The **Save-Keys** option allows the user to view and manage their Ghost node keys:

    - **Key Location**: The user's keys are saved in the file located at `/root/ghost/ghost-node/wallet.txt`.
    - **Check Keys**: The user can check their saved keys by navigating to this file.
    - **Edit Keys**: To view or edit the keys, the user can use the following command:
      ```bash
       nano /root/ghost/ghost-node/wallet.txt
      ```
   This will open the `wallet.txt` file in the `nano` editor, allowing the user to view or make changes to the keys.

10. **Keys-Update-Server** 

    The **Keys-Update-Server** function allows the user to update their keys on the server:

      - **Branch Name**: First, the user is prompted with the following message:
        ```
         Enter the branch name to create:
        ```
      The user should enter their desired branch name. This could be any name they choose for their branch.

    Once the user inputs the branch name, the script will proceed to update the keys on the server with the specified branch name.

11. **Git-SSH-Keys**

    The **Git-SSH-Keys** function prompts the user to enter the SSH key name:

      - **SSH Key Name**: The user will be asked to input their SSH key name with the following message:
        ```
         Enter the SSH key name (default is $default_key):
        ```
      The user can either press **Enter** to use the default key name or provide their custom SSH key name. 

     After the user provides the key name, the script proceeds to configure the SSH key for the Git repository.

12. **Keys-Checker**  
    Verifies the saved keys for correctness and usability.

13. **NAT-Bind-Checker**  
    Checks if the NAT configuration is correctly set up and port 30333 , 9945 are bound.

14. **Enable-Service**  
    Enables the Ghost node service for automatic startup on reboot.

15. **Start-Service**  
    Starts the Ghost node service.

16. **Stop-Service**  
    Stops the running Ghost node service.

17. **Restart-Service**  
    Restarts the Ghost node service for applying changes.

18. **Status-Checker**  
    Checks the status of the Ghost node service.

19. **Logs-Checker**  
    Displays the latest logs to monitor the Ghost node's performance or troubleshoot issues.

20. **Exit**  
    Exits the script and ends the session.



______________________________________________________________________________________________________________________________

# Conclusion
This Auto Script for Node Management on the Ghost has been created by CryptoBuroMaster. It is a comprehensive solution designed to simplify and enhance the node management experience. By providing a clear and organized interface, it allows users to efficiently manage their nodes with ease. Whether you are a newcomer or an experienced user, this script empowers you to handle node operations seamlessly, ensuring that you can focus on what truly matters in your blockchain journey.

# Author
**Created by: CryptoBureau-Master**

**Join our TG : https://t.me/CryptoBuroOfficial**

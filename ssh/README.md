# Connecting-remote-via-SSH

This guide demonstrates how to connect remote via SSH.

---

## Setup Instructions

### On the **Client**

1. SSH Key Generation
    Generate an SSH key pair:
    ```shell
    ssh-keygen -t ed25519 -C "<your_email>@<example.com>"
    ```

2. Configure Client SSH Access
    Edit the `~/.ssh/config` file:
    ```
    Host <Host_Name>
        HostName 127.0.0.1
        User <VM_Username>
        Port <Your_Port_Forwarding_Host_Port>
        IdentityFile <Path_to_Private_Key>
    ```

#### **(Optional)** On the **Client** with **VS Code**

1. (Option) Install `ms-vscode-remote.remote-ssh`
    ```shell
    code --install-extension ms-vscode-remote.remote-ssh
    ```

### On the **Host** as the **root user**

1. Set up the sshd service:
    ```shell
    setup_sshd.sh
    ```

### On the **Host** as the **rootless user**

1. Configure the public key:
    ```shell
    sshd_add_pub_key.sh -p <PUB_KEY>
    restart_sshd.sh
    ```

## How to Use

### Connect **Host** Via **SSH**

```shell
ssh <Host_Name>
```

### Connect **Host** Via **VS Code**

1. Open VS Code.
2. Run the command `Remote-SSH: Connect to Host...` from the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).
3. Select the Host you configured.
4. **Done!** You are now connected to your VM.
> [!TIP]
> Developing directly within a VirtualBox shared folder may lead to unexpected write permission issues. It is highly recommended to keep your source code in the VM's local filesystem for better performance and reliability.

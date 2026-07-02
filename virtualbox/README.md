# Configure-VirtualBox-development-environment

This guide demonstrates how to configure a VirtualBox virtual machine development environment.

---

## Prerequisites

- **Install VirtualBox**: Download it from the [official Oracle website](https://www.virtualbox.org/wiki/Downloads).

- **Prepare a Linux ISO**: 

    - 
        For best compatibility with **VS Code**.

        Please choose a **glibc-based** Linux distribution (e.g., Debian, Ubuntu, CentOS).

        For more details, refer to the:

        - [VS Code System Requirements](https://code.visualstudio.com/docs/supporting/requirements)
        - [Remote Development Overview](https://code.visualstudio.com/docs/remote/remote-overview)
        - [Remote Development FAQ](https://code.visualstudio.com/docs/remote/faq)

---

## Setup Instructions

### 1. Configure VirtualBox

#### Networking
To enable remote access, set up Port Forwarding:
- Go to **Settings > Network**.
- Attached to: **NAT**.
- Click **Advanced > Port Forwarding** and add a new rule:
    - **Protocol**: `TCP`
    - **Host Port**: `[Choose an arbitrary port, e.g., 2222]`
    - **Guest Port**: `22` (Default SSH port)

#### Shared Folders
To enable mount shared folders
- Go to **Settings > Shared Folders**.
- Click **Add Share**

### 2. VM Installation
- Start the VM and complete the Linux installation.

### 3. On the **VM** as the **root user**

1. Mount Shared Folders
    To mount a VirtualBox shared folder, run the following:
    ```shell
    mount -t vboxsf <Folder_Name_from_VirtualBox_Settings> <Mount_Path_in_VM>
    ```

2. Run Configuration Scripts
    Execute the provided scripts to automate the environment setup:
    ```shell
    vbox_permanent_shares.sh -m <MOUNT_POINT> -s <SHARD_NAME>
    ```

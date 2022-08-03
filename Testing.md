# Testing the bash scripts

This document describe how you can test in an easy way the diffrent customization scripts of this project before you decide to install them natively in your machine.

There are two options regarding if you want to customize your:
- Linux System: Install packages, extender terminal functions, environment variables, etc...
- Ubuntu Customization: UI, extra menu options, etc..


To test these two options I have designed two different testing setups:
- Docker container: This is mainly for the Linux System scripts
- Virtual machine: Mainly for the Ubuntu customization 


## Docker Container

Assuming you have docker installed, configured and working in your machine.

TODO: Finish the part of the docker container...

1. Create a Docker container of the Linux System you want to test. In my case [Ubuntu 18.04](https://hub.docker.com/_/ubuntu):
```bash
docker run ubuntu:18.04
```

2. Attach a terminal to the running container
```bash
docker 
```


## Virtual Machine

1. Install VirtualBox in your OS

2. Download an image of your Ubuntu Linux (or any other Linux distribution you want to test) from [OSBOXES](https://www.osboxes.org/). Take into account the tab __Info__ in the image you download since you will find there the user/password among any other valuable information.

3. Verify the SHA256 checksum on the downloaded file
```bash
sha256sum DOWNLOADED_FILE.7z
```

4. Extract the file:
```bash
sudo apt-get install p7zip-full
7z e DOWNLOADED_FILE.7z
```

5. Copy the file to your VirtualBox's virtual hard disks repository, in my case `/home/francisco/VirtualBox\ VMs/`
```bash
mv EXTRACTED_FILE.vdi cd /home/francisco/VirtualBox\ VMs/
```

6. Start VirtualBox and create a new virtual machine (according to the OS image you downloaded)
```bash
Machine -- New
```
The emerging dialog will guide you through the creation process. When you reach the __Hard disk__ section, then selct the option __Use an existing virtual hard disk file__ and select the *.vdi file you downloaded in the previous steps.

7. Mount this project as a volume so you can test the installation of the bash scripts.

8. Start the image and configure some settints such as the language, the keyboard or install the VirtualBox Guest Additions.

9. When you reach a point where you feel the system is usable, then Switch Off the image and create an Snapshot.

10. Restart the image again and test the installation of the scripts.
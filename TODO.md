TODOs
===============================================================

## Scripts to Implement

 - [ ] Create SSH keys script (in_review/linux/create_ssh_keys.sh) - Generate SSH keys for code repositories automatically
 - [ ] Install bash scripts (in_review/linux/install_bash_scripts.sh) - Deploy custom bash scripts to ~/bin
 - [ ] Install packages script (in_review/ubuntu/install_packages.sh) - Read from resources/apt/list_of_packages.txt and install

## Installation Process

 - [ ] Create a script that triggers the entire installation process
 - [ ] The installation script must ask the user if he works in a company, if the user say yes, then the script must ask 
       for the name of the company and store the answer in the OS variable `COMPANY`. If the user do not work in a company
       then the variable must be empty.
 - [ ] Create the system variable `COMPANY` that holds the name of the company and append the variable to the `/etc/environment` 
       file in order to be present among sessions.
 - [ ] In the script `create_directory_structure` check the `COMPANY` variable and if it is empty then do not create the
       directory for the company.
 - [ ] Create script for installing [nala](https://gitlab.com/volian/nala#installation).
 - [ ] When you create a script for creating keyboard shortcuts, you must have into account the content of the `COMPANY`
       variable, if the variable is not empty, then create a shortcut with `<Super>+<FIRST_LETTER>` to the directory
      `~/Documents/$COMPANY`. Note that `FIRST_LETTER` is the first letter of the name of the company.

# Criterias to have into account
 - All operations must be idempotent: That means executing a script multiple times has the same effect as executing the
   same script 1 time. The script only perform the operation the first time, the subsequent times the script checks if
   the operation was already performed and do nothing.


# Project Basis
- Define an order for things. Install first [nala](https://gitlab.com/volian/nala#installation) before installing any package using `apt`.
  After installing nala, use `nala` to install all packages
- Install zsh ( https://ohmyz.sh/#install )
- Create installation script in the parent directory (A script that - installs the other scripts in the system)
- Review all the scripts in the directory `in_review` and make them production ready (from a functional perspective) and move them to the `customize` directory
- Review this file and ensure the TODOs are actual
- Test with a docker Ubuntu image
  - Create a docker Ubuntu container for testing
  - Document how to start the container and how to test the project
- copy/paste inside the _new_structure_directory each script on its respective folder
- get the content of the _new_structure_ directory and put it in the root directory
- create a .gitignore
- Create a proper README.md file
- Branching strategy
- Bash Script templates:
    - Parse arguments
    - Interpolate some fields during installation:
      - Author name
      - Email
      - Company name
- Python Script templates:
    - Documentation
    - Parse arguments
    - Interpolate some fields during installation:
      - Author name
      - Email
- Complete the TODOs for each script
- Create man pages for the scripts
  - https://unix.stackexchange.com/questions/34516/can-i-create-a-man-page-for-a-script
  - https://www.cyberciti.biz/faq/linux-unix-creating-a-manpage/


# Scripts TODOs

## Java
  ### install_sdkman.sh
  ### install_JDK.sh (using sdkman)
  ### install_gradle.sh (using sdkman)
  ### install_maven.sh (using sdkman)
  ### install_eclipse.sh
  ### install_intellij.sh 

## Python
  ### install_pycharm.sh

## JS
  ### install_NVM.sh
  ### install_NodeJS
  ### install_Postman.sh ???
  ### install_Newman.sh
  ### install_Postman_Collection_Transformer.sh
  ### install_visual_studio_code.sh

## DEVOPS
  ### install_docker.sh (See mdwiki & existing script)
  ### docker_no_sudo.sh (See mdwiki)
  ### install_docker-compose.sh (See mdwiki)
  ### install_kubectl.sh (See mdwiki)
  ### install_minikube.sh (See mdwiki)
  ### install_helm.sh (See mdwiki)
  ### install_azure.sh
  

## install_java.sh

- separate repository ???
- man documentation
- Header
- parse arguments & show error
- include external references ???
- create functions 
- clean obsolete code
- redo the article InstallOpenJDKInUbuntu.md

## mute_ms_teams.sh

- man documentation
- Header
- 

## create_directory_structure.sh

## linux_setup.sh

## ubuntu_setup.sh

# TODOs for the future

 - https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
 - https://stackoverflow.com/questions/1371261/get-current-directory-name-without-full-path-in-a-bash-script
 - https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script


 # Enrich the documentation with Mermaid diagrams






MyLiCuLa ( My Linux Customization Layer )
==========================================================================

This project is a customization layer for (Ubuntu) Linux that I install on top of the OS.
By doing this I ensure homogeneity on all my Linux devices, all of my Linux devices will have the same 
applications, packages, menus, custom utilities, configuration and much more. I will never have to 
manually install packages or tools when I switch from one device to another.

The entire idea of creating this project is to automatize the ideas exposed in the article [General Conventions](/home/francisco/git/francisco/franciscoguemes.com/mdwiki/entries/setup/General%20Conventions.md)


# Usage
This project takes as starting that the user has followed [these manual steps](https://mdwiki.franciscoguemes.com/#!NEW.md) in the new computer.


# Structure of the project

The project is structured in the following directories:

```bash
tree -L 2 .
.
├── customize
│   ├── linux
│   └── ubuntu
├── in_review
│   ├── git
│   ├── linux
│   ├── linux_setup.sh
│   ├── ubuntu
│   └── ubuntu_setup.sh
├── install.sh
├── LICENSE
├── README.md
├── Testing.md
└── TODO.md
```

In the root directory there is a `install.sh` script that will install the entire customization layer in your 
machine. It is an interactive scritp that will ask you a few questions.

The scripts under the _customize_ directory are the ones designated to transform your OS in order to get a similar setup than the one I have in all my machines. In other words you can get the same Ubuntu customization (UI, extra menu options, etc..) and the same Linux customization (Installed packages, extended terminal functions, environment variables, etc...). Inside the _customize_ directory there are the scripts _linux_setup.sh_ and _ubuntu_setup.sh_ to install the respective customizations.

The scripts under the *in_review* directory are scripts that are not yet production ready and therefore they need more refinement and testing.


## Requirements

The scripts are coded in:
 - [Bash](https://www.gnu.org/software/bash/) 4.X or above
 - [Python](https://www.python.org/) 3.X or above


You can check which version of bash you have installed in your system by using any of the two commands below:
```bash
# General way of checking your bash version
bash --version
# Get only bash version number
echo "${BASH_VERSION}"
```

In the case of Python you can check your installed versions by typing:
```bash
# For python 2.X versions
python --version
# For python 3.X versions
python3 --version
```

## Colaborating with the project

Fell free to colaborate with the project creating a fork of this project and customizing it for your favourite Linux distribution or sugesting new ideas, scripts and customizations for the generic Linux part or the Ubuntu customization.

As any other project there are some rules and standards that I followed when created the project.

### New scripts
In order to create new scripts, please use the templates located in the folder `templates` of this project and follow the conventions shown in the template such as the documentation header, the documentation in the functions, the naming conventions for global variables, etc...

### TODOs
The pending tasks will be marked with the _TODO:_ tag and then what is missing. 
```bash
TODO: Here a clear description of what is missing
```

----

TODO: Review from here down...

----


### Interpolation
All values that will be interpolated during the installation process must be in the format 
```bash
<<<KEY_TO_INTERPOLATE>>>
```

### Interpolation directory
The interpolation directory will be `.target` inside the current directory.

During the installation process the files are copied to the directory `./.target` and then interpolated. So if you run the installation with the DryRun; inside this directory you can see the source scripts that would be installed in your computer.
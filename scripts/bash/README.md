============================================================

The scripts inside this directory are installed in the OS by creating a symbolic link to
`/usr/local/bin`. This directory is by default included in the `PATH` variable. You can create the links 
automatically for all scripts by executing the script `./customize/linux/install_bash_scripts.sh`

Alternatively you can create the symbolic links manually. The following examples create a link to the scripts:
```shell
PATH_TO_PROJECT=~/mylicULA
sudo ln -s $PATH_TO_PROJECT/scripts/connect_to_Zulutrade_VPN.sh /usr/local/bin/connect_to_Zulutrade_VPN
sudo ln -s $PATH_TO_PROJECT/scripts/disconnect_from_Zulutrade_VPN.sh /usr/local/bin/disconnect_from_Zulutrade_VPN
sudo ln -s $PATH_TO_PROJECT/scripts/zulutrade_maven_config.sh /usr/local/bin/zulutrade_maven_config.sh
```

On top of the link, you may want to create a keyboard shortcut in the OS, so you can execute the script
directly from the keyboard without having to open a terminal window.


#TODO: Download pycharm-community

#TODO: Verify sha256 checksum


#Unpack the pycharm-community*.tar.gz file to /opt (recommended installation location according to the filesystem hierarchy standard (FHS))
sudo tar xzf pycharm-community*.tar.gz -C /opt/

#Switch to the bin subdirectory
cd /opt/pycharm-community*/bin

#Start pycharm-community
sh pycharm.sh


#TODO: Create icon in the system dash. See ubuntu/AddApplicationToDash.md


# https://flatpak.org/setup/Ubuntu


#Install Flatpak
sudo add-apt-repository ppa:flatpak/stable
sudo nala update
sudo nala install flatpak

#Install the Software Flatpak plugin
sudo nala install gnome-software-plugin-flatpak

#Add the Flathub repository 
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo


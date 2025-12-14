#TODO 12122025 - Divest all the docker and base vscode crap and configure this to JUST install Yara and Yara capabilities
# Also make this better, this can be included on top of the other ubuntu builds now!
# Maybe there are other yara capabilities and extensions now? A newer Yara?


# DEV Note - All under this line is WIP

#############################################
### Docker file for GTMR YARA Environment
### Author: James Konderla
### Version: 3
### Created: 12/1/2023
### Updated: 7/16/2025
#############################################
FROM kasmweb/ubuntu-jammy-desktop:1.17.0-rolling-weekly
USER root
ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=$STARTUPDIR/install
WORKDIR $HOME
######### Customize Container Here ###########
RUN apt-get update && apt-get update -y
RUN apt-get install libssl-dev automake libtool yara -y
RUN pip3 install yara-python
RUN pip3 install -U yls-yara
# Begin Step: Add VSCode to repository
RUN curl -sSL -O https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
# End Step
# Begin Step: Install apps and prepare Python venv
RUN apt update
RUN apt install python3-venv -y
RUN mkdir -p ~/yls && cd ~/yls
RUN python3 -m venv env yls/env/bin/activate
# End Step
# Begin Step: Create Icons and Install VSCode extensions
RUN cd /usr/share/applications && sed -i 's%--new-window% c --no-sandbox --disable-workspace-trust --new-window%' code.desktop
RUN cd /usr/share/applications && sed -i 's%--unity-launch% c --no-sandbox --disable-workspace-trust --new-window%' code.desktop
RUN mkdir -p /home/kasm-user/.local/share/applications && cp /usr/share/applications/code.desktop /home/kasm-user/.local/share/applications/code.desktop
RUN code --no-sandbox --user-data-dir ~/.config/Code --install-extension infosec-intern.yara
RUN code --no-sandbox --user-data-dir ~/.config/Code --install-extension avast-threatlabs-yara.vscode-yls
# End Step
######### End Customizations ###########
RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME
ENV HOME=/home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME
USER 1000
##################### EOF ###################
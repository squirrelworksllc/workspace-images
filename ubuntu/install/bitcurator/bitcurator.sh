#TODO on 12/1/2025 - Offload the install stuff from the Bitcurator dockerfile to THIS.
# Then move the bitcurator dockerfile into the workspace-images repo!
# Then redevelop and redeploy
# Then once it works, make Bitcurator public!

#### Everything below here is BAD, hasn't been fixed yet!!!!!

# Modified version of Bitcurator's Dockerfile designed to work with Kasm.
# Bitcurator dockerfile: "https://github.com/BitCurator/bitcurator-docker/blob/main/Dockerfile.noble"
# For a working Docker image see "https://hub.docker.com/repository/docker/squirrelworksllc/bitcurator5"

##################### SOF ###################
FROM kasmweb/ubuntu-noble-desktop:1.18.0-rolling-weekly
USER root
ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=$STARTUPDIR/install
WORKDIR $HOME

######### START Bitcurator Container Customizations ###########
# Step 1 - Download and prep Bitcurator CLI
RUN apt update && apt upgrade -y
RUN apt install nano build-essential gcc make perl wget curl gnupg ca-certificates -y
RUN apt install --reinstall ca-certificates -y
RUN wget -O /tmp/bitcurator https://github.com/BitCurator/bitcurator-cli/releases/download/v2.0.0/bitcurator-cli-linux
RUN chmod +x /tmp/bitcurator
# Step 2 - Add kasm-user to the proper groups
RUN groupadd bcadmin && usermod -aG sudo,bcadmin kasm-user
# Step 3 - Install Bitcurator (will take some time)
RUN sudo /tmp/bitcurator install --mode=addon --user=kasm-user
######### END Bitcurator Container Customizations ###########

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME
ENV HOME=/home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME
USER 1000
##################### EOF ###################
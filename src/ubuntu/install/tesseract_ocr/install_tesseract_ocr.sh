#TODO 12122025 - Divest all the docker crap and configure this to JUST install tesseract and OCR capabilities
# Also make this better, this can be included on top of the other ubuntu builds now!


# DEV Note - All under this line is WIP

#############################################
### Docker file for Tesseract-OCR Environment
### Author: James Konderla
### Version: 2
### Created: 3/19/2024
### Updated: 5/13/2024
#############################################
FROM kasmweb/core-ubuntu-jammy:1.15.0-rolling
USER root
ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=$STARTUPDIR/install
WORKDIR $HOME
######### Customize Container Here ###########
RUN apt-get update && apt-get update -y
RUN apt-get install tesseract-ocr libtesseract-dev python3-opencv build-essential tesseract-ocr-eng libleptonica-dev wl-clipboard gimagereader python3-pip firefox -y
RUN pip install normcap
COPY tesseract.desktop $HOME/Desktop/
COPY documentation.desktop $HOME/Desktop/
COPY tesseract.png /usr/share/backgrounds/bg_default.png
RUN echo "/usr/bin/desktop_ready" > $STARTUPDIR/custom_startup.sh
RUN chmod +x $STARTUPDIR/custom_startup.sh
######### End Customizations ###########
RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME
ENV HOME=/home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME
USER 1000
##################### EOF ###################
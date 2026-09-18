# docker container run -v "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY:ro" -t --rm -i -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY" -e XDG_RUNTIME_DIR=/tmp -e GDK_BACKEND=wayland alal45643/fedora-emacsgui:latest
FROM fedora:44

RUN dnf install -y emacs emacs-pgtk git makeinfo sudo
RUN useradd -U -m user 
RUN echo 'user:user' | chpasswd
RUN usermod -aG wheel user
RUN dnf -y install glibc-locale-source glibc-langpack-en
ENV LANG=en_US.utf8
RUN echo "$LANG UTF-8" >> /etc/locale.gen
RUN localedef --verbose --force -i en_US -f UTF-8 en_US.UTF-8
RUN update-locale --reset LANG=$LANG
USER user
WORKDIR /home/user/

CMD rm .emacs && git clone https://github.com/AlAl45643/.emacs.d.git && bash .emacs.d/setup.sh && emacs

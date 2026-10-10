FROM ubuntu:20.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# FIX CONNECTION: Change official mirrors to local Indonesian mirror (Kartolo) for faster download speeds
RUN echo "deb http://archive.ubuntu.com/ubuntu/ focal main universe\n\
deb http://archive.ubuntu.com/ubuntu/ focal-updates main universe\n\
deb http://security.ubuntu.com/ubuntu focal-security main universe" > /etc/apt/sources.list

# 1. Install lightweight desktop environment (XFCE), TigerVNC server, and basic utilities
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    xterm \
    bzip2 \
    tigervnc-standalone-server \
    wget \
    curl \
    zenity \
    git \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# 2. Install core 64-bit graphical and GUI dependency libraries required by Eagle CAD
RUN apt-get update && apt-get install -y \
    libxrender1 \
    libxrandr2 \
    libxi6 \
    libfontconfig1 \
    libfreetype6 \
    libxcursor1 \
    libxft2 \
    && rm -rf /var/lib/apt/lists/*

# 3. Manually download and install libssl1.1 (required for modern Ubuntu internal tools)
RUN wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb \
    && dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb \
    && rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb

# 4. Manually download legacy libssl1.0.0 from Ubuntu Xenial security archive (CRITICAL for Eagle v7.7.0)
RUN wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
    && dpkg -i libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb || apt-get install -f -y \
    && rm libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb

# 5. Configure VNC password and environment
ENV USER=root
ENV HOME=/root
RUN mkdir /root/.vnc \
    && echo "password" | vncpasswd -f > /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

# Create xstartup file to properly launch the XFCE Desktop environment inside TigerVNC
# Anti-sleep: X blanking off (default timeout 600s blanks VNC after 10 min idle)
RUN echo "#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xset s off\n\
xset s noblank\n\
xset -dpms || true\n\
exec startxfce4" > /root/.vnc/xstartup \
    && chmod +x /root/.vnc/xstartup

# Disable XFCE auto-sleep/lock: light-locker locks root out (no password to unlock),
# power-manager + xscreensaver blank the VNC framebuffer on idle
RUN mkdir -p /root/.config/autostart \
    && printf '[Desktop Entry]\nHidden=true\n' > /root/.config/autostart/light-locker.desktop \
    && printf '[Desktop Entry]\nHidden=true\n' > /root/.config/autostart/xfce4-power-manager.desktop \
    && printf '[Desktop Entry]\nHidden=true\n' > /root/.config/autostart/xscreensaver.desktop

# 6. Copy and extract Eagle CAD v7 Linux installer
# NOTE: installer takes the BASE dir as a positional arg ($0 /opt -> /opt/eagle-7.7.0).
# Any dash-flag (e.g. --nox11 --target ...) only prints USAGE and exits 0, leaving /opt empty.
COPY eagle-lin64-7.7.0.run /tmp/eagle-installer.run

# Run the self-extracting installer in headless mode (no display needed when TARGET is given)
RUN chmod +x /tmp/eagle-installer.run \
    && /tmp/eagle-installer.run /opt \
    && rm /tmp/eagle-installer.run \
    && test -x /opt/eagle-7.7.0/bin/eagle

# Create a symlink to easily run Eagle from any terminal inside the container
RUN ln -s /opt/eagle-7.7.0/bin/eagle /usr/local/bin/eagle

# 7. Set XFCE default terminal (helpers.rc missing => "failed to execute default terminal emulator";
#    alternatives auto-point to gnome-terminal which needs D-Bus that xstartup unsets)
RUN mkdir -p /root/.config/xfce4 \
    && printf '[Helper]\nTerminalEmulator=xfce4-terminal\n' > /root/.config/xfce4/helpers.rc \
    && update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

# 8. Desktop launcher so EAGLE can start without a terminal
RUN mkdir -p /root/Desktop && printf '[Desktop Entry]\nVersion=1.0\nType=Application\nName=EAGLE 7.7.0\nExec=/opt/eagle-7.7.0/bin/eagle\nIcon=application-x-executable\nTerminal=false\nCategories=Graphics;Engineering;\n' > /root/Desktop/EAGLE.desktop \
    && chmod +x /root/Desktop/EAGLE.desktop

# Expose only standard VNC port (5901)
EXPOSE 5901

# Clean up any leftover locks, start TigerVNC server (daemonizes), then keep container alive in foreground
CMD ["sh", "-c", "rm -f /tmp/.X1-lock /tmp/.X11-unix/X1* && vncserver :1 -geometry 1280x800 -depth 24 -localhost no -rfbauth /root/.vnc/passwd && tail -F /root/.vnc/*.log"]
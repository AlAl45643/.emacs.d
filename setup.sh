#! /bin/bash
mkdir bin
cd bin


wget https://github.com/Samsung/netcoredbg/releases/download/3.1.2-1054/netcoredbg-linux-amd64.tar.gz
tar -xf netcoredbg-linux-amd64.tar.gz
mv ./netcoredbg netcored
sudo mv ./netcored/* ./

wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x ./dotnet-install.sh
./dotnet-install.sh --version latest --channel STS
./dotnet-install.sh --version latest --channel LTS
cat >>~/.bashrc <<EOL
export DOTNET_ROOT=\$HOME/.dotnet
export PATH=\$PATH:\$DOTNET_ROOT:\$DOTNET_ROOT/tools
EOL

# setup java
wget https://github.com/microsoft/java-debug/archive/refs/tags/0.53.1.zip
unzip 0.53.1.zip
cd java-debug-0.53.1
./mvnw clean install
cd ../
rm 0.53.1.zip
mv java-debug-0.53.1 jdtls

# setup sql
sudo dnf install go

# setup python
sudo dnf install pip
pip install "debugpy"
pip install "uv"

# setup rass
uv tool install "rassumfrassum"

# setup vterm
sudo dnf install cmake libtool libvterm

cat >>~/.bashrc <<EOL
vterm_printf() {
    if [ -n "\$TMUX" ] \\
        && { [ "\${TERM%%-*}" = "tmux" ] \\
            || [ "\${TERM%%-*}" = "screen" ]; }; then
        # Tell tmux to pass the escape sequences through
        printf "\ePtmux;\e\e]%s\007\e\\\\" "\$1"
    elif [ "\${TERM%%-*}" = "screen" ]; then
        # GNU screen (screen, screen-256color, screen-256color-bce)
        printf "\eP\e]%s\007\e\\\\" "\$1"
    else
        printf "\e]%s\e\\\\" "\$1"
    fi
}
vterm_prompt_end(){
    vterm_printf "51;A\$(whoami)@\$(hostname):\$(pwd)"
}
PS1=\$PS1'\[\$(vterm_prompt_end)\]'
EOL

# install jetbrains mono font
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"

echo "Restart your computer."


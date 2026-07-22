#! /bin/bash
mkdir bin
cd bin


# wget https://github.com/Samsung/netcoredbg/releases/download/3.1.2-1054/netcoredbg-linux-amd64.tar.gz
# tar -xf netcoredbg-linux-amd64.tar.gz
# mv ./netcoredbg netcored
# sudo mv ./netcored/* ./
# 
# wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
# chmod +x ./dotnet-install.sh
# ./dotnet-install.sh --version latest --channel STS
# ./dotnet-install.sh --version latest --channel LTS
# cat >>~/.bashrc <<EOL
# export DOTNET_ROOT=\$HOME/.dotnet
# export PATH=\$PATH:\$DOTNET_ROOT:\$DOTNET_ROOT/tools
# EOL


# setup python
sudo dnf install pip
pip install "uv"

# setup rass
uv tool install "rassumfrassum"


# install jetbrains mono font
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"

echo "Restart your computer."


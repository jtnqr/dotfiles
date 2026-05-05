#!/bin/bash
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# Function to clone plugin if missing
install_plugin() {
    if [ ! -d "$ZSH_CUSTOM/plugins/$1" ]; then
        echo "Installing $1..."
        git clone https://github.com/$2 "$ZSH_CUSTOM/plugins/$1"
    fi
}

install_plugin "zsh-syntax-highlighting" "zsh-users/zsh-syntax-highlighting.git"
install_plugin "zsh-autosuggestions" "zsh-users/zsh-autosuggestions.git"
install_plugin "you-should-use" "MichaelAquilina/zsh-you-should-use.git"
install_plugin "evalcache" "mroth/evalcache.git"

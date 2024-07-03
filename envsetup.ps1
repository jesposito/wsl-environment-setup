# Ensure script is running with administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    Exit
}

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Install Windows Terminal
if (-not (Test-Command winget)) {
    Write-Host "Winget is not installed. Please install it from the Microsoft Store."
    Exit
}

winget install --id=Microsoft.WindowsTerminal -e

# Download and install MesloLGS NF font
$fontUrl = "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf", 
           "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf",
           "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf",
           "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"

$fontFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)

foreach ($font in $fontUrl) {
    $fileName = $font.Split("/")[-1]
    Invoke-WebRequest -Uri $font -OutFile "$env:TEMP\$fileName"
    $fontFolder.CopyHere("$env:TEMP\$fileName", 0x10)
    Remove-Item "$env:TEMP\$fileName" -Force
}

# Configure Windows Terminal
$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$wtSettings = @{
    "$schema" = "https://aka.ms/terminal-profiles-schema"
    "defaultProfile" = "{YOUR-LINUX-MINT-GUID}"  # Replace with actual GUID
    "profiles" = @{
        "defaults" = @{
            "fontFace" = "MesloLGS NF"
            "fontSize" = 12
            "colorScheme" = "One Half Dark"
            "cursorShape" = "bar"
            "useAcrylic" = $true
            "acrylicOpacity" = 0.8
        }
        "list" = @(
            @{
                "guid" = "{YOUR-LINUX-MINT-GUID}"  # Replace with actual GUID
                "hidden" = $false
                "name" = "Linux Mint"
                "source" = "Windows.Terminal.Wsl"
                "startingDirectory" = "//wsl$/Mint/home/yourusername"  # Replace with your username
            }
        )
    }
    "schemes" = @(
        @{
            "name" = "One Half Dark"
            "background" = "#282C34"
            "foreground" = "#DCDFE4"
            "black" = "#282C34"
            "blue" = "#61AFEF"
            "cyan" = "#56B6C2"
            "green" = "#98C379"
            "purple" = "#C678DD"
            "red" = "#E06C75"
            "white" = "#DCDFE4"
            "yellow" = "#E5C07B"
            "brightBlack" = "#5A6374"
            "brightBlue" = "#61AFEF"
            "brightCyan" = "#56B6C2"
            "brightGreen" = "#98C379"
            "brightPurple" = "#C678DD"
            "brightRed" = "#E06C75"
            "brightWhite" = "#DCDFE4"
            "brightYellow" = "#E5C07B"
        }
    )
}

$wtSettings | ConvertTo-Json -Depth 32 | Set-Content $wtSettingsPath

# Configure zshrc in WSL
$zshrcContent = @'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load dircolors for Solarized color scheme
eval $(dircolors ~/.dircolors)

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git vscode docker docker-compose kubectl npm zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

sudocode() {
    sudo "/mnt/c/Users/YourUsername/AppData/Local/Programs/Microsoft VS Code/Code.exe" --user-data-dir="~/.vscode-root" "$@"
}

# VSCode function
code() {
    echo "Attempting to run VS Code..."
    if [ $# -eq 0 ]; then
        # No arguments, open current directory
        WIN_PWD=$(wslpath -w "$(pwd)")
        echo "Opening current directory: $WIN_PWD"
        (/mnt/c/Users/YourUsername/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe "$WIN_PWD" &>/dev/null &)
    else
        # Handle arguments
        for arg in "$@"; do
            if [[ "$arg" =~ ^[a-zA-Z]: ]]; then
                # Handle Windows-style paths
                WIN_PATH=$(wslpath -u "$arg")
            else
                # Handle regular paths
                WIN_PATH="$arg"
            fi

            if [ -e "$WIN_PATH" ]; then
                # File or directory exists
                WIN_PATH=$(wslpath -w "$(realpath "$WIN_PATH")")
                echo "Opening: $WIN_PATH"
                (/mnt/c/Users/YourUsername/AppData/Local/Programs/Microsoft\ VS\ Code/Code.exe "$WIN_PATH" &>/dev/null &)
            else
                echo "Error: $arg does not exist"
            fi
        done
    fi
    echo "VS Code launched in background"
}

# explorer
open() {
    explorer.exe .
}

# PATH configuration
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Environment variables
export PATH=$HOME/bin:/usr/local/bin:$PATH
export BROWSER="wslview"

# Unalias code if it exists
unalias code 2>/dev/null

# Add autocompletion for kubectl
source <(kubectl completion zsh)

# To customize prompt, run p10k configure or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases for kubectl
alias k=kubectl
complete -F __start_kubectl k
source <(kubectl completion zsh)
source <(helm completion zsh)
alias kns=kubens
alias kctx=kubectx

# Added Aliases and Functions
# Navigation Aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias home="cd ~"

# Common Commands
alias ll="/bin/ls -alF --color=auto"
alias la="/bin/ls -A --color=auto"
alias l="/bin/ls -CF --color=auto"
alias ls="/bin/ls --color=auto"
alias grep="grep --color=auto"
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

# System and Process
alias df="df -h"
alias du="du -h -c"
alias top="htop"

# Git Aliases
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gst="git status"
alias gco="git checkout"
alias gbr="git branch"
alias gd="git diff"
alias gcl="git clone"

# Docker Aliases
alias dps="docker ps"
alias dpa="docker ps -a"
alias di="docker images"
alias dr="docker run"
alias db="docker build"
alias dstop="docker stop"
alias drm="docker rm"
alias drmi="docker rmi"

# Kubernetes Aliases
alias k="kubectl"
alias kx="kubectx"
alias kns="kubens"

# VSCode Alias
alias code.="code ."
alias c='clear'

# Ensure color output
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Ensure proper command output
unsetopt PROMPT_SP
unsetopt PROMPT_CR

# Disable autocorrect
unsetopt correct_all
unsetopt correct

# Force reload of completion system
autoload -Uz compinit
compinit

# Reset zsh options
setopt LOCAL_OPTIONS
setopt LOCAL_TRAPS

# Better handling of special characters in filenames
setopt NO_CLOBBER
'@

# Write zshrc content to WSL
wsl -d Mint -u yourusername zsh -c "echo '$zshrcContent' > ~/.zshrc"

# Install Oh My Zsh and Powerlevel10k in WSL
wsl -d Mint -u yourusername zsh -c '
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Install Powerlevel10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    # Install zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    # Install zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # Source zshrc
    source ~/.zshrc
'

Write-Host "Setup complete. Please restart Windows Terminal and configure Powerlevel10k by running 'p10k configure' in your WSL terminal."
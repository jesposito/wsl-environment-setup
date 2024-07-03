# Windows WSL Environment Setup

This script sets up a complete development environment on Windows with WSL, including:

- Windows Terminal installation and configuration
- MesloLGS NF font installation
- ZSH configuration in WSL with Oh My Zsh and Powerlevel10k

## Prerequisites

- Windows 10 or later
- WSL installed with Linux Mint distribution
- Winget package manager installed

## Usage

1. Clone this repository or download the files.
2. Right-click on `setup_environment.bat` and select "Run as administrator".
3. Follow any on-screen prompts.
4. After the script completes, restart Windows Terminal.
5. In your WSL terminal, run `p10k configure` to finish setting up Powerlevel10k.

## Customization

Before running the script, you may want to edit `setup_environment.ps1` to:

- Replace `{YOUR-LINUX-MINT-GUID}` with your actual Linux Mint WSL GUID.
- Replace `yourusername` with your WSL username.
- Replace `YourUsername` with your Windows username.

## Note

This script will overwrite existing Windows Terminal settings and ZSH configurations. Make sure to backup any important configurations before running the script.
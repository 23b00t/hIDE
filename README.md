# hIDE - hyper IDE 

## WIP - Idea

- A zellij based IDE like environment for use with Helix
- Much more config to do 
- Should maybe packaged at the end, with all required binaries included

## Requirements

- zellij, helix, lazysql, scooter, ec, lazygit, ft (gets installed by init.sh), yazi, fzf, rg, maybe later lazydocker and some basic LSP servers, copilot cli or an alternative

## Usage

- Clone the repo
- Run `./init.sh` to install dependencies and set up the environment
- source $HOME/.hIDE_aliases if .(z)profile doesn't already source it
- Use init-hIDE to start zellij with the shipped config
- Use hIDE to open a IDE like zellij tab in the current directory

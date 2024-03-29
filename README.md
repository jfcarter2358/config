# About

This repo contains helper scripts and files to be sourced to help setup a terminal environment

# Getting Started

First, create your secrets files with:

```bash
vim ./shell/.personal.private
# Add any credentials you want stored as env variables for personal use to this file
```

Then add the shell files files to your `~/.{zsh,bash}rc` file, run the following command:

```bash
# Use ~/.bashrc instead of ~/.zshrc if using Bash
cat << EOF >> ~/.zshrc
# Source aliases and functions
source ~/helpers/shell/.rc

# Source credentials
source ~/helpers/shell/.personal.private
EOF
```

Create a credential json file with the following structure in `data/cred.json`

```json
{
    // Service that this credential is for
    "github": {
        // Org that this credential is for
        "personal": {
            "username": "my github username",
            "password": "my github password"
        },
    },
    "aws": {
        ...
    },
    ...
}
```

Create a repo file with the following structure in `data/clone.json`

```json
[
    {
        "base_dir": "directory to clone into",
        "org": "organization that owns this location",
        "aliases": [
            "other names to use for org",
            ...
        ],
        "user": "git",
        "url": "github.com"
    },
    ...
]
```

Create an environment via pyenv:

```bash
pyenv virtualenv 3.10.0 helpers
pyenv activate helpers
pip install -r requirements.txt
pyenv deactivate
```

Source your `~/.{zsh.bash}rc` file

```bash
# Use ~/.bashrc if using Bash
source ~/.zshrc
```

Create vim directories

```bash
mkdir -p ~/.vim ~/.vim/autoload ~/.vim/backup ~/.vim/colors ~/.vim/plugged
```

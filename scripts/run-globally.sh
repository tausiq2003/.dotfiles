#!/usr/bin/env bash

#sudo mv $1 /usr/local/bin/$2

#sudo chmod +x /usr/local/bin/$2

#my own creation above, chatgpt below

if [ $# -ne 2 ]; then
    echo "Usage: $0 <path_to_appimage> <global_command_name>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File '$1' does not exist."
    exit 1
fi

sudo mv "$1" /usr/local/bin/"$2"

if [ $? -ne 0 ]; then
    echo "Error: Failed to move the file."
    exit 1
fi

sudo chmod +x /usr/local/bin/"$2"

if [ $? -ne 0 ]; then
    echo "Error: Failed to make the file executable."
    exit 1
fi

echo "AppImage successfully installed as '$2'. You can now run it globally by typing '$2'."



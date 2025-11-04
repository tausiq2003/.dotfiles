This is the dotfile of mine, its integrated with nixos.
How to pack
1. Backup using restic.
2. Zip it with encryption if possible or just chat gpt idk.
3. Send to google drive.
4. git push the dotfiles and nixos (cp if possible, i don't like sudo git), configuration.nix, home.nix, flake.nix and Makefile that is available here [nix-setup](https://github.com/tausiq2003/nix-setup).
How to unpack
1. connect to wifi, ping then cfdisk then create partitions, label them, mount them, if possible crypt the /nvme0n1p3, chat gpt.
2. then just generate config nixos-generate-config --root /mnt
3. then add git, stow, neovim, xclip if required in configuration.nix
4. nixos-install
5. reboot
6. now you will be in tty
7. just git clone this .dotfile in your home and stow everything
8. then install [nix-setup](https://github.com/tausiq2003/nix-setup) and move everything to /etc/nixos
9. then follow start.sh
10. then in make file do sudo make switch
11. reboot.
12. download the backup
13. unzip and decrypt the backup
14. ig, you are gtg.


Note to preserve history of git just install nixos in your home directory and cp all the content to /etc/nixos with new git init there. And while packing just move them all in nix-setup.

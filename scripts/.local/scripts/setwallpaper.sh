#!/usr/bin/env zsh

#fetch current date and month

current_date=$(date +"%d")
current_month=$(date +"%m")


# set spring = feb and march
# set summer = april to june
# set rainy = july to september
# set autumn = october to november 15th
# set winter = nov 15th to jan


if ((current_month == 2 || current_month == 3)); then
	season="$HOME/.dotfiles/wallpapers/spring.jpg"
elif ((current_month >= 4 && current_month <= 6)); then
	season="$HOME/.dotfiles/wallpapers/summer.jpg"
elif ((current_month >= 7 && current_month <= 9)); then
	season="$HOME/.dotfiles/wallpapers/rainy.jpg"
elif ((current_month == 10 || (current_month == 11 && current_date <= 15) )); then
	season="$HOME/.dotfiles/wallpapers/autumn.jpg"
else
	season="$HOME/.dotfiles/wallpapers/winter.jpg"
fi

echo "$season"


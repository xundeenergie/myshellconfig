#!/bin/bash
youtube-dl --write-description --write-info-json --write-annotations --write-all-thumbnails -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' -o '%(playlist)s/%(title)s.%(ext)s' -c -w -a ./url

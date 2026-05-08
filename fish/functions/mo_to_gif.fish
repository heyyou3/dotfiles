function mo_to_gif
    ffmpeg -i "$argv[1]" -r 10 "$argv[2]"
end

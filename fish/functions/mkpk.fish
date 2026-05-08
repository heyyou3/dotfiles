function mkpk
    mkdir $argv[1]
    echo "package $argv[1]" >> "$argv[1]/$argv[1].go"
end

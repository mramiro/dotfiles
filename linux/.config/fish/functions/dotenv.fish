function dotenv
    set -l envfile "$PWD/.env"
    if [ (count $argv) -gt 0 ]
        set envfile $argv[1]
    end

    if [ -e "$envfile" ]
        for line in (cat "$envfile")
            set -l key (echo $line | cut -d = -f 1)
            set -l val (echo $line | cut -d = -f 2-)
            eval "set -xg $key $val"
        end
    end
end


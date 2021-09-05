function jwt-decode
    argparse 'f/full' -- $argv; or return 1
    set -l jwt $argv[1]
    if test (count $argv) -lt 1; or test "$jwt" = "-"
        read jwt
    end
    if test -n "$_flag_full"
        echo $jwt | cut -d. -f1,2 | sed 's/\./\n/g' | base64 --decode | jq
        echo $jwt | cut -d. -f3
    else
        echo $jwt | cut -d. -f2 | base64 --decode | jq
    end
end


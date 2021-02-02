function az_keyvault_import
    argparse 'f/file=' -- $argv
    if not set -q argv[1]
        echo "Missing argument: targetKeyvault" 1>&2
        return 1
    end
    set -l target_vault $argv[1]
    if not az keyvault show --name $target_vault 1>/dev/null
        return 2
    end
    for line in (cat $_flag_f)
        set -l name (echo $line | cut -d = -s -f -1)
        set -l value (string unescape (echo $line | cut -d = -s -f 2-))
        echo "Setting secret $name in $target_vault..."
        az keyvault secret set --vault-name $target_vault --name $name --value $value
    end
end

function az_keyvault_export
    set -l vault $argv[1]
    for id in (az keyvault secret list --vault-name $vault | jq -r '.[].id')
        set -l name (basename $id)
        set -l value (string escape (az keyvault secret show --id $id | jq -r '.value'))
        echo "$name=$value"
    end
end

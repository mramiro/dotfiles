function az_keyvault_secret_mv
    set -l source_vault $argv[1]
    set -l target_vault $argv[2]
    set -l secret_name $argv[3]
    set -l value (az keyvault secret show --vault-name $source_vault --name $secret_name | jq -r '.value')
    if [ $status -ne 0 ]
        echo "Secret $secret_name not found." 1>&2
        exit 1
    end
    az keyvault secret set --vault-name $target_vault --name $secret_name --value $value
end

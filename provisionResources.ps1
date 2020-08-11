# TODO: set variables
$studentName = "Kevin"
$rgName = "$studentName-lc0820-ps-rg"
$vmName = "$studentName-lc0820-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = "$(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn" -o tsv)"
$vmAdminUsername = "student"
$vmAdminPassword = "LaunchCode-@zure1"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG

	# set az location default
	az configure --default location=eastus

	# RG: provision
	az group create -n "$rgName"

	# set az rg default
	az configure --default group=$rgName

# TODO: provision VM

	# capture vm output for splitting
	$vmData= az vm create -n $vmName --size $vmSize --image $vmImage --admin-username $vmAdminUsername --admin-password $vmAdminPassword --authentication-type password --assign-identity --query "[ identity.systemAssignedIdentity, publicIpAddress ]" -o tsv

	

# TODO: capture the VM systemAssignedIdentity

	# vm value is (2 lines):
	# <identity line>
	# <public IP line>

	# get the 1st line (identity)
	$vmID= $vmData.Split([Environment]::NewLine) | Select -First 1
	# get the 2nd line (ip)
	$vmIP=$vmData.Split([Environment]::NewLine) | Select -Last 2

# TODO: open vm port 443

	# VM: add NSG rule for port 443 (https)
	az vm open-port --port 443

	# set az vm default
	az configure --default vm=$vmName


# provision KV

az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)

	az keyvault secret set --vault-name $kvName --description 'connection string' --name $kvSecretName --value $kvSecretValue

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)

	az keyvault set-policy --name $kvName --object-id $vmID --secret-permissions list get

	az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

	az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

	az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file

	echo "VM available at $vmIP"
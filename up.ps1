# Script to start a sandbox container under Windows

if ($args.count -lt 2) {
    $command = $MyInvocation.MyCommand.Name
    Write-Host "Usage: $command docker_tag index"
    Write-Host "       Creates a instance of the docker image called tyk-sandbox with the docker tag given"
    exit 1
}

$tag = $args[0]
$index = $args[1]

Write-Host "$tag $index"

$SandboxPluginDir="\Users\pstubbs\tyk\plugins"
$SandboxCertDir="\Users\pstubbs\tyk\certs"

$SandboxPluginDir="/C//Users/pstubbs/tyk/plugins"
$SandboxCertDir="/C//Users/pstubbs/tyk/certs"

$offset=$index-1
$hostFQDN="pstubbs-PC"
$dashboardPort=3000+$offset
$gatewayPort=8080+$offset
$tibPort=3010+$offset
$tykVersion=$tag

$containerName="sandbox-$index"
$label=$containerName
$dashboardURL="http://${hostFQDN}:$dashboardPort/"
$gatewayURL="https://${hostFQDN}:$gatewayPort/"

# Create a version specific plugin directory. Tyk plugins must be compiled specifically for each version
if (! (Test-Path "$SandboxPluginDir/$tykVersion") -and $tykVersion -ne "latest") {
    New-Item -Path $SandboxPluginDir -ItemType "directory" -Name "$tykVersion" > $null
    Write-Host "Created plugin dir $SandboxPluginDir/$tykVersion. It will be empty."
}

Write-Host "[DEBUG]
docker container create --name $containerName --publish published=$dashboardPort,target=3000 `
--publish published=$gatewayPort,target=8080 --env TYK_GW_PORT=$gatewayPort `
--env TYK_GW_HOST=$hostFQDN --env TYK_DSHB_HOST=$hostFQDN --label sandbox.label=$label `
--label sandbox.version=$tykVersion --label sandbox.dashurl=$dashboardURL `
--label sandbox.gateurl=$gatewayURL --label sandbox.index=$index `
--volume "$SandboxPluginDir/${tykVersion}:/opt/tyk-plugins" `
--volume "${SandboxCertDir}:/opt/tyk-certificates" tyk-sandbox:$tykVersion
"

Write-Host "[INFO]Creating container $containerName"
docker container create --name $containerName --publish published=$dashboardPort,target=3000 `
--publish published=$gatewayPort,target=8080 --env TYK_GW_PORT=$gatewayPort `
--env TYK_GW_HOST=$hostFQDN --env TYK_DSHB_HOST=$hostFQDN --label sandbox.label=$label `
--label sandbox.version=$tykVersion --label sandbox.dashurl=$dashboardURL `
--label sandbox.gateurl=$gatewayURL --label sandbox.index=$index `
--volume "$SandboxPluginDir/${tykVersion}:/opt/tyk-plugins" `
--volume "${SandboxCertDir}:/opt/tyk-certificates" tyk-sandbox:$tykVersion

# Start the container and print its details if it was created successfully
if ($?) {
    Write-Host "[INFO]Starting container $containerName"
    docker container start $containerName
    docker container inspect -f '{{ range $k, $v := .Config.Labels }}{{ $k }}={{ println $v }}{{ end }}' $containerName
}

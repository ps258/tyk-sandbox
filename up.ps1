if ($args.count -lt 2) {
    $command = $MyInvocation.MyCommand.Name
    Write-Host "Usage: $command docker tag index"
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

if (! (Test-Path "$SandboxPluginDir/$tykVersion")) {
    New-Item -Path $SandboxPluginDir -ItemType "directory" -Name "$tykVersion" > $null
    Write-Host "Created plugin dir $SandboxPluginDir/$tykVersion. It will be empty."
}

#if [[ $tykVersion != "latest" && ! -d $SandboxPluginDir/$tykVersion ]]
#then
# echo "[WARN]Creating $SandboxPluginDir/$tykVersion: It will be empty"
# mkdir -p $SandboxPluginDir/$tykVersion
#fi

Write-Host "[INFO]Creating container $containerName"
Write-Host "docker container create --name $containerName --publish target=$dashboardPort,published=3000 `
--publish target=$gatewayPort,published=8080 --env TYK_GW_PORT=$gatewayPort `
--env TYK_GW_HOST=$hostFQDN --env TYK_DSHB_HOST=$hostFQDN --label sandbox.label=$label `
--label sandbox.version=$tykVersion --label sandbox.dashurl=$dashboardURL `
--label sandbox.gateurl=$gatewayURL --label sandbox.index=$index `
--volume "$SandboxPluginDir/${tykVersion}:/opt/tyk-plugins" `
--volume "${SandboxCertDir}:/opt/tyk-certificates" tyk-sandbox:$tykVersion"
docker container create --name $containerName --publish target=$dashboardPort,published=3000 `
    --publish target=$gatewayPort,published=8080 --env TYK_GW_PORT=$gatewayPort `
    --env TYK_GW_HOST=$hostFQDN --env TYK_DSHB_HOST=$hostFQDN --label sandbox.label=$label `
    --label sandbox.version=$tykVersion --label sandbox.dashurl=$dashboardURL `
    --label sandbox.gateurl=$gatewayURL --label sandbox.index=$index `
    --volume "$SandboxPluginDir/${tykVersion}:/opt/tyk-plugins" `
    --volume "${SandboxCertDir}:/opt/tyk-certificates" tyk-sandbox:$tykVersion

Write-Host "[INFO]Starting container $containerName"
docker container start $containerName
docker container inspect -f '{{ range $k, $v := .Config.Labels }}{{ $k }}={{ println $v }}{{ end }}' $containerName
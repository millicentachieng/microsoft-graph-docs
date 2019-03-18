Param(
    [switch]$cleanUp,
    [string]$file
)

$repoPath = (Get-Location).Path
$downloadedApiDoctor = $false
$downloadedNuGet = $false

Write-Host "Repository location: ", $repoPath
Write-Host "GitHub Token: ", $env:GITHUB_TOKEN
Write-Host "Git Path: ",(Get-Command "git.exe").Source
Write-Host "Build Number: ", $env:BUILD_BUILDNUMBER
Write-Host "Build ID: ", $env:BUILD_BUILDID
Write-Host "Pull Request Number: ", $env:BUILD_PULLREQUEST_PULLREQUESTNUMBER
Write-Host "Source Branch: $($env:BUILD_SOURCEBRANCHNAME)"
Write-Host "Target Branch: $($env:BUILD_PULLREQUEST_TARGETBRANCHNAME)" 


# Check for ApiDoctor in path
$apidoc = $null
if (Get-Command "apidoc.exe" -ErrorAction SilentlyContinue) {
    $apidoc = (Get-Command "apidoc.exe").Source
}
else {
	# Download apidoctor from GitHub	
	$apidocPath = Join-Path $repoPath -ChildPath "apidoctor"
	New-Item -ItemType Directory -Force -Path $apidocPath
	
	Write-Host "Cloning apidoctor repo from GitHub"
	& git clone -b master https://github.com/millicentachieng/apidoctor.git --recurse-submodules 
	$downloadedApiDoctor = $true
}

# Get Nuget
$nugetPath = $null
if (Get-Command "nuget.exe" -ErrorAction SilentlyContinue) {
	# Use the existing nuget.exe from the path
	$nugetPath = (Get-Command "nuget.exe").Source
}
else
{
	# Download nuget.exe from the nuget server if required
	$nugetPath = Join-Path $repoPath -ChildPath "nuget.exe"
	$nugetExists = Test-Path $nugetPath
	if ($nugetExists -eq $false) {
		Write-Host "nuget.exe not found. Downloading from dist.nuget.org"
		Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath
	}
	$downloadedNuGet = $true
}

$nugetParams = "restore", $apidocPath
& $nugetPath $nugetParams
	
# Build api-doctor
Install-Module -Name Invoke-MsBuild -Scope CurrentUser -Force
Write-Host "Building API Doctor..."
Invoke-MsBuild -Path "$apidocPath\ApiDoctor.sln" -MsBuildParameters "/t:Rebuild /p:Configuration=Release /p:OutputPath=$apidocPath\bin"
$apidoc = "$apidocPath\bin\apidoc.exe"	

$lastResultCode = 0

# Run validation at the root of the repository
$appVeyorUrl = $env:APPVEYOR_API_URL

$params = "check-all", "--path", $repoPath
if ($appVeyorUrl -ne $null)
{
    $params = $params += "--appveyor-url", $appVeyorUrl
}

& $apidoc $params

if ($LastExitCode -ne 0) { 
    $lastResultCode = $LastExitCode
}

# Clean up the stuff we downloaded
if ($cleanUp -eq $true) {
    if ($downloadedNuGet -eq $true) {
        Remove-Item $nugetPath 
    }
    if ($downloadedApiDoctor -eq $true) {
        Remove-Item $apidocPath -Recurse
    }
}

if ($lastResultCode -ne 0) {
    Write-Host "Errors were detected. This build failed."
    exit $lastResultCode
}
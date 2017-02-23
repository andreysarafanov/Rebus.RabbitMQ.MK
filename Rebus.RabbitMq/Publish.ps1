$repoBasePath = "\\f.altcms.local\mk-Development\NuGet\Components\";

$lsFirstName = (ls "*.csproj").Name;
#Magin number is 7 - length of ".csproj" plus some chars.
if ($lsFirstName -ne $null -and $lsFirstName.Length -ge 7) {
	$projectName = $lsFirstName.Replace(".csproj", "");

	$repoPath = $repoBasePath + $projectName + "\";

	echo ("Update " + $projectName + "...");

	#Full path to project file.
	$currentDirectory = (Resolve-Path .\).Path;
	$projectFilePath = $currentDirectory + "\" + $projectName + ".csproj";
	#Full path to msbuild.exe file.
	$msbuildFilePath = Join-Path ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\14.0").MSBuildToolsPath) -ChildPath "msbuild.exe";

	# /v:n - normal verbosity; /ds - show detailed summary at the end; /nologo - do not show copyright information.
	$buildArgs = "/p:Configuration=Release /v:n /ds /nologo";

	echo ("Attempting to build """ + $projectName + """ project, please wait...");
	echo ("Builder path: " + $msbuildFilePath);
	echo ("Project file path: " + $projectFilePath);
	echo ("Build arguments: " + $buildArgs);

	#MsBuild arguments contains configuration information and full path to project file.
	$buildFullArgs = $buildArgs + " " + $projectFilePath;
	
	echo ("----------------------------------");

	#Start build process with wait for completion.
	$bp = Start-Process $msbuildFilePath -ArgumentList $buildFullArgs -PassThru -Wait -NoNewWindow;

	echo ("----------------------------------");
	echo ("Build result code: " + $bp.ExitCode);

	if ($bp.ExitCode -eq 0) {
		echo ("It's okay!");
		echo ("Create package, wait again please...");
		$nugetFilePath = Join-Path ($env:NUGET_PATH) -ChildPath "nuget.exe";
		$nugetArgs = "pack " + $projectFilePath + " -IncludeReferencedProjects -Prop Configuration=Release -NoDefaultExcludes";
	
		echo ("Packager: " + $nugetFilePath);
		echo ("Packager args: " + $nugetArgs);
		echo ("----------------------------------");

		$np = Start-Process $nugetFilePath -ArgumentList $nugetArgs -PassThru -Wait -NoNewWindow;

		echo ("----------------------------------");
		echo ("Packaging result code: " + $np.ExitCode);

		if ($np.ExitCode -eq 0) {
			echo ("We got it! Mission One - deliver it to master share of all nugets!")
			echo ("Target repository path: " + $repoPath);

			if (!(Test-Path -Path $repoPath)) {
				echo ("Repository for project not exists, try to create new one...");
				echo ("----------------------------------");
				New-Item -ItemType directory -Path $repoPath;
				echo ("----------------------------------");
				echo ("Done");
			}

			echo ("----------------------------------");
			Copy-Item ($currentDirectory + "\*.nupkg") -Destination $repoPath -Force -PassThru;
			echo ("----------------------------------");

			echo ("Yeah! Check " + $repoPath);
			echo ("Cleaning up...");

			Remove-Item ($currentDirectory + "\*.nupkg") -Force;

			echo ("Congratulation, we done here!");
		} else {
			echo ("Oooopssssssssss. Bye.");
		}
	} else {
		echo ("Alarma! Alarma! Check build log somewhere. Bye.");
	}
} else {
	echo ("WHERE IS MY GREAT PROJECT??????????");
}
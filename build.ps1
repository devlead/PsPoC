. ./cake.ps1

######################################################################
## GLOBALS
######################################################################
[FilePath]      $solution      = [Enumerable]::FirstOrDefault([GlobbingAliases]::GetFiles($context, "./src/*.sln"))
[string]        $configuration = "Release"
[DirectoryPath] $nugetRoot     = [DirectoryAliases]::MakeAbsolute($context, "./nuget");

######################################################################
## SETUP / TEARDOWN
######################################################################
Setup([Action[ICakeContext]]{
    param([ICakeContext] $ctx)
})

Teardown([Action[ITeardownContext]]{
    param([ITeardownContext] $ctx)
})

######################################################################
## TASKS
######################################################################
$cleanTask      = "Clean" |`
                    Task |`
                    Does -Action ({
                        [DirectoryAliases]::CleanDirectories($context, "./src/**/bin/$configuration")
                        [DirectoryAliases]::CleanDirectories($context, "./src/**/obj/$configuration")
                        [DirectoryAliases]::CleanDirectory($context, $nugetRoot)
                    })

$restoreTask    = "Restore" |`
                    Task |`
                    IsDependentOn -Dependency $cleanTask |`
                    Does -Action ({
                        [DotNetCoreAliases]::DotNetCoreRestore($context, $solution.FullPath)
                    })

$buildTask      = "Build" |`
                    Task |`
                    IsDependentOn -Dependency $restoreTask |`
                    Does -Action ({
                        [DotNetCoreAliases]::DotNetCoreBuild($context, $solution.FullPath)
                    })

$packTask       = "Pack" |`
                    Task |`
                    IsDependentOn -Dependency $buildTask |`
                    Does -Action ({
                        [DotNetCorePackSettings]   $packSettings = [DotNetCorePackSettings]::new()
                        $packSettings.OutputDirectory = $nugetRoot
                        
                        [DotNetCoreAliases]::DotNetCorePack(
                            $context,
                            $solution.FullPath,
                            $packSettings
                        )
                    })

######################################################################
## EXECUTION
######################################################################
$packTask | RunTarget
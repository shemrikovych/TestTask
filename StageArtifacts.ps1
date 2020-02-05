$target = "C:\inetpub\wwwroot\HelloWorld\" 

function DeleteIfExistsAndCreateEmptyFolder($dir )
{
    if ( Test-Path $dir ) {    
           Get-ChildItem -Path  $dir -Force -Recurse | Remove-Item -force –
							  recurse
           Remove-Item $dir -Force
    }
    New-Item -ItemType Directory -Force -Path $dir
}

DeleteIfExistsAndCreateEmptyFolder($target )

function GetWebArtifactFolderPath($path)
{
    foreach ($item in Get-ChildItem $path)
    {   
        if (Test-Path $item.FullName -PathType Container)
        {   
          
            if (Test-Path ($item.fullname + "\Global.asax"))
            {
              
                return $item.FullName;
            }
            GetWebArtifactFolderPath $item.FullName
        }
    }
}

$path = GetWebArtifactFolderPath("C:\temp\WebApp\HelloWorld")
$path2 = $path + "\*"
Copy-Item $path2 $target -recurse -force
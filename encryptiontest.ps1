Function Reset-Test{
    Remove-Item c:\test\test2.bin -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item C:\test\*.gpg -Recurse -Force -ErrorAction SilentlyContinue
}
Function Show-Test{
    $testMessage = "Running " + $testTypes[$currentTest] + " Test #" + ($cycle + 1) + "..."
    Write-Host $testMessage
}

$numberOfCycles = 2
$compressAlgo = "uncompressed"
$cycles = 0..($numberOfCycles-1)
Set-Clipboard $cycles
$testTimesArray = (Get-Clipboard),(Get-Clipboard),(Get-Clipboard),(Get-Clipboard),(Get-Clipboard),(Get-Clipboard)
$averageTimesArray = 0..5
$testTypes = "Non-Encrypted Compression","Non-Encrypted Decompression","AES256 Encryption & Compression","AES256 Decryption & Decompression","3DES Encryption & Compression","3DES Decryption & Decompression"
if ($compressAlgo = "uncompressed"){
    $testTypes = $testTypes -replace "Non-Encrypted Compression","Non-Encrypted Container Pack" -replace "Non-Encrypted Decompression","Non-Encrypted Container Unpack" -replace " Compression" -replace " Decompression" -replace " &"
}
mkdir c:\test -ErrorAction SilentlyContinue | Out-Null
$randomFile = new-object byte[] 1048576000; (new-object Random).NextBytes($randomFile); [IO.File]::WriteAllBytes('c:\test\test.bin', $randomFile)

foreach ($cycle in $cycles){
    Reset-Test
    $currentTest = 0
    Show-Test
    $testTimesArray[$currentTest][$cycle] = Measure-Command{
        & gpg.exe --store --compress-algo $compressAlgo --quiet c:\test\test.bin
    }
    $currentTest++
    Show-Test
    $testTimesArray[$currentTest][$cycle] = Measure-Command{
        & gpg.exe --output c:\test\test2.bin --quiet -d c:\test\test.bin.gpg
    }
    
    Reset-Test
    $currentTest++
    Show-Test
    $testTimesArray[$currentTest][$cycle] = Measure-Command{
        & gpg.exe -c --cipher-algo AES256 --compress-algo $compressAlgo --allow-old-cipher-algos --passphrase password --batch --yes --quiet c:\test\test.bin
    }
    $currentTest++
    Show-Test
    $testTimesArray[$currentTest][$cycle] = Measure-Command{
        & gpg.exe --output c:\test\test2.bin --passphrase password --batch --yes --quiet -d c:\test\test.bin.gpg 
    }

    Reset-Test
    $currentTest++
    Show-Test
    $testTimesArray[$currentTest][$cycle] = Measure-Command{
        & gpg.exe -c --cipher-algo 3DES --compress-algo $compressAlgo --allow-old-cipher-algos --passphrase password --batch --yes --quiet c:\test\test.bin 2>C:\test\test.log
    }
    $currentTest++
    Show-Test
    $testTimesArray[$currentTest][$cycle] = Measure-Command{
        & gpg.exe --output c:\test\test2.bin --passphrase password --batch --yes --quiet -d c:\test\test.bin.gpg 
    }
    Reset-Test
}
Remove-Item c:\test -Recurse -Force

Write-Host
Write-Host "Average Time in Milliseconds:"
$i = 0
foreach ($array in $testTimesArray){
    $i += 0 
    $averageTimesArray[$i] = ($testTimesArray[$i].TotalMilliseconds | Measure-Object -Average).Average
    Write-Host $testTypes[$i] -NoNewLine
    Write-Host ":"
    $averageTimesArray[$i]
    $i++
}

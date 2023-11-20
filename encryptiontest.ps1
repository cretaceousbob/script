Function Reset-Test{
    Remove-Item c:\test\test2.bin -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item C:\test\*.gpg -Recurse -Force -ErrorAction SilentlyContinue
}
Function Show-Test{
    $testMessage = "Running " + $testTypes[$currentTest] + " Test #" + ($cycle + 1) + "..."
    Write-Host $testMessage
}

$numberOfCycles = 200
$cycles = 0..($numberOfCycles-1)
$compressAlgo = "uncompressed"
$cipherAlgo = "AES","AES256","Camellia128","Camellia256","Blowfish","Twofish","3DES"
Set-Clipboard $cycles
$averageTimesArray = 0..(($cipherAlgo.Count * 2) + 1)
$testTimesArray = 0..(($cipherAlgo.Count * 2) + 1)
foreach ($cell in $averageTimesArray){
    $testTimesArray[$cell] = Get-Clipboard
}

$testTypes = 0..(($cipherAlgo.Count * 2) + 1)
$testTypes[0] = "Non-Encrypted Container Pack"
$testTypes[1] = "Non-Encrypted Container Unpack"
$skip = 0
foreach ($cipher in $cipherAlgo){
    $testTypes[($cipherAlgo.IndexOf($cipher))+2+$skip] = $cipher + " Encryption"
    $testTypes[($cipherAlgo.IndexOf($cipher))+3+$skip] = $cipher + " Decryption"
    $skip++
}
if ($compressAlgo -ne "uncompressed"){
    $testTypes = $testTypes -replace "Non-Encrypted Container Pack","Non-Encrypted Compression" -replace "Non-Encrypted Container Unpack","Non-Encrypted Decompression" -replace " Encryption"," Encryption & Compression" -replace " Decryption"," Decryption & Decompression"
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
    
    foreach ($cipher in $cipherAlgo){
        Reset-Test
        $currentTest++
        Show-Test
        $testTimesArray[$currentTest][$cycle] = Measure-Command{
            & gpg.exe -c --cipher-algo $cipher --compress-algo $compressAlgo --allow-old-cipher-algos --passphrase password --batch --yes --quiet --no-tty c:\test\test.bin 2>C:\test\test.log
        }
        $currentTest++
        Show-Test
        $testTimesArray[$currentTest][$cycle] = Measure-Command{
            & gpg.exe --output c:\test\test2.bin --passphrase password --batch --yes --quiet -d c:\test\test.bin.gpg 
        }
    }
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

Function Reset-Test{
    Remove-Item c:\test\test2.bin -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item C:\test\*.gpg -Recurse -Force -ErrorAction SilentlyContinue
}
Function Show-Test{
    $testMessage = "Running " + $testTypes[$currentTest] + " Test #" + ($cycle + 1) + "..."
    $logMessage = "$date" + " $testMessage"
    Write-Host $testMessage
    Add-Content -path $logPath -value $logMessage
}

$numberOfCycles = 2
$cycles = 0..($numberOfCycles-1)
$date = Get-Date
$logDate = Get-Date -format "MM-dd-yy"
$logDate = $logDate.Clone()
$logPath = "C:\encryptionbenchmark\testlog-" + $logDate + ".txt"
$compressAlgo = "uncompressed"
$cipherAlgo = "AES","AES256","Camellia128","Camellia256","Blowfish","Twofish","3DES"
$averageTimesArray = 0..(($cipherAlgo.Count * 2) + 1)
$testTimesArray = $averageTimesArray.Clone()
foreach ($cell in $averageTimesArray){
    $testTimesArray[$cell] = $cycles.Clone()
}
$testTypes = $averageTimesArray.Clone()
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
mkdir C:\encryptionbenchmark -ErrorAction SilentlyContinue | Out-Null
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

$averageHeader = "$date " + "Average Time in Milliseconds:`n"
Write-Host $averageHeader
Add-Content -path $logPath -value $averageHeader
$i = 0
foreach ($array in $testTimesArray){
    $i += 0 
    $averageTimesArray[$i] = ($testTimesArray[$i].TotalMilliseconds | Measure-Object -Average).Average
    $averageTypeHost = $testTypes[$i] + ":"
    $averageTypeLog = "$date " + $testTypes[$i] + ":"
    $averageLogTimes = "$date " + $averageTimesArray[$i]
    Write-Host $averageTypeHost
    $averageTimesArray[$i]
    Add-Content -path $logPath -value $averageTypeLog
    Add-Content -path $logPath -value $averageLogTimes
    $i++
}

# test_upload.ps1
$credInfo = echo "protocol=https`nhost=github.com" | git credential fill
$token = ""
foreach ($line in $credInfo) {
    if ($line -like "password=*") { $token = $line.Substring(9) }
}
New-Item -ItemType File -Path test_upload.txt -Value "test upload content" -Force
$uploadUrl = "https://uploads.github.com/repos/Nikhilsourav347/Medictrack/releases/344581731/assets?name=test_upload.txt"
& curl.exe -v -X POST -H "Authorization: Bearer $token" -H "Content-Type: text/plain" --data-binary "@test_upload.txt" $uploadUrl

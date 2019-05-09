ARG baseimage
ARG tag
#mcr.microsoft.com/dotnet/framework/aspnet:3.5-windowsservercore-ltsc2019
FROM $baseimage:$tag

LABEL "com.spring.mseries"="Spring Global"
LABEL service="Portal"
LABEL com.spring.mseriesPortal="1.0.0"
LABEL version="1.0"
LABEL maintainer="devops@springglobal.com"

# To set my Root Directory
WORKDIR mseries
# escape=`
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install the mSeries pre reqs
RUN Install-WindowsFeature -Name MSMQ-Server ; \
    Install-WindowsFeature -Name Web-WebSockets ; \
    Install-WindowsFeature -Name NET-HTTP-Activation ; \
    Install-WindowsFeature -Name NET-Non-HTTP-Activ ; \
    Install-WindowsFeature -Name NET-Framework-45-ASPNET ; \
    Install-WindowsFeature -Name Web-Asp-Net45 ; \
    Install-WindowsFeature -Name Web-Net-Ext45 ; \
    Install-WindowsFeature -Name NET-WCF-HTTP-Activation45 ; \
    Install-WindowsFeature -Name NET-WCF-MSMQ-Activation45 ; \
    Install-WindowsFeature -Name NET-WCF-Pipe-Activation45 ; \
    Install-WindowsFeature -Name NET-WCF-TCP-Activation45

# Install IISRewrite Module
ADD http://download.microsoft.com/download/D/D/E/DDE57C26-C62C-4C59-A1BB-31D58B36ADA2/rewrite_amd64_en-US.msi c:/inetpub/rewrite_amd64_en-US.msi
RUN Start-Process c:/inetpub/rewrite_amd64_en-US.msi -ArgumentList "/qn" -Wait

# ENABLE MSDTC FEATEURES
RUN Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name 'NetworkDtcAccess' -Value 1 ; \
    Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name "NetworkDtcAccessClients" -Value 1 ; \
    Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name "NetworkDtcAccessInbound" -Value 1 ; \ 
    Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name "NetworkDtcAccessOutbound" -Value 1 ; \ 
    Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name "NetworkDtcAccessTransactions" -Value 1 ; \ 
    Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name "NetworkDtcAccessTip" -Value 1 ; \ 
    Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name "LuTransactions" -Value 1 ; \ 
    Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name "XaTransactions" -Value 1 ; \ 
    set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC -Name "AllowOnlySecureRpcCalls" -Value 1 ; \ 
    set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC -Name "FallbackToUnsecureRPCIfNecessary" -Value 1 ; \ 
    set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC -Name "TurnOffRpcSecurity" -Value 0

# Create Web Site mSeries and Application Pool Framework 4.5
RUN Import-module IISAdministration; \
    Remove-IISSite -name 'Default Web Site' -Confirm:$false ; \
	New-IISSite -Name "mseries" -PhysicalPath C:\mseries -BindingInformation "*:80:" ; \
    New-WebAppPool DefaultAppPool45 ; \
    Set-ItemProperty IIS:\AppPools\DefaultAppPool45 managedRuntimeVersion v4.0

# Create application folders
RUN mkdir C:\mseries\Portal ; \
    mkdir C:\mseries\WsmSeriesDataService\Logs ; \
    mkdir C:\mseries\SAMLAuthenticator ; \
    mkdir C:\mseries\Product ; \
    mkdir C:\mseries\jobs\envdocker\Dev\FileSync\Tmp ; \
    mkdir C:\mseries\Logs

# Create Web Application 
RUN powershell -NoProfile -Command \
    New-WebApplication "Portal" -Site "mseries" -ApplicationPool "DefaultAppPool" -PhysicalPath "C:\mseries\Portal" ; \
    New-WebApplication "WsmSeriesDataService" -Site "mseries" -ApplicationPool "DefaultAppPool45" -PhysicalPath "C:\mseries\WsmSeriesDataService" ; \
    New-WebApplication "Authenticator" -Site "mseries" -ApplicationPool "DefaultAppPool45" -PhysicalPath "C:\mseries\SAMLAuthenticator" 

# Create volume for mapping shared folder
VOLUME ["S:"]

# Copy mSeries files
COPY files .

#Disable UAC
#RUN New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

# Execute the .ps1 to replace
#RUN powershell -NoProfile -Command set-content replace.ps1 -value (get-content c:\mseries\env_var.ps1,c:\mseries\rep_var.ps1) 
#RUN powershell "c:\mseries\replace.ps1"


EXPOSE 80

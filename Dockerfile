FROM mcr.microsoft.com/dotnet/framework/wcf:4.7.2-windowsservercore-ltsc2019
# ARG baseimage
# ARG tag
# FROM $baseimage:$tag

LABEL "com.spring.mseries"="Spring Global"
LABEL service="advdistribution"
LABEL com.spring.mseriesPortal="1.0.0"
LABEL version="1.0"
LABEL maintainer="devops@springglobal.com"

# To set my Root Directory
WORKDIR mseries
# escape=`
CONTEXT C:\\spring\\containers\\mseries-files\\advdistribution 

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Create application folders
RUN mkdir C:\mseries\WsAdvancedDistributionProcessor ; \
    mkdir C:\mseries\Logs

# Copy mSeries files
COPY C:\\spring\\containers\\mseries-files\\advdistribution\\files .

# Create the windows service and mantein the container running even if the service stop.  
RUN New-Service -name MSeriesWs.AdvancedDistributionProcessor -displayName "\"Spring Wireless - Ws.AdvancedDistributionProcessor\"" -binaryPathName "C:\mseries\WsAdvancedDistributionProcessor\SpringMS.Common.Server.Job.Ws.AdvancedDistributionProcessor.exe" -startupType Automatic -Description "\"Advanced Distribution Processor Service\""

ENTRYPOINT ["powershell"]

# start the service and send the internal log to read in the docker logs command, of container
CMD Start-Service MSeriesWs.AdvancedDistributionProcessor ; \
    Get-EventLog -LogName System -After (Get-Date).AddHours(-1) | Format-List ;\
    $idx = (get-eventlog -LogName System -Newest 1).Index; \
    while ($true) \
    {; \
      start-sleep -Seconds 1; \
      $idx2  = (Get-EventLog -LogName System -newest 1).index; \
      get-eventlog -logname system -newest ($idx2 - $idx) |  sort index | Format-List; \
      $idx = $idx2; \
    }

EXPOSE 80

FROM mcr.microsoft.com/dotnet/runtime:5.0
COPY TestApp/bin/Release/net5.0/publish/ App/
WORKDIR /App
ENTRYPOINT ["dotnet", "TestApp.dll"]
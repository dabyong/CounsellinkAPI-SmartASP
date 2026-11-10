
# Build ASP.NET Core 10 API
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src

COPY CounselLink.API.csproj ./
RUN dotnet restore CounselLink.API.csproj

COPY . .

RUN dotnet publish CounselLink.API.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false

# Run the published application
FROM mcr.microsoft.com/dotnet/aspnet:10.0

WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:10000

EXPOSE 10000

ENTRYPOINT ["dotnet", "CounselLink.API.dll"]

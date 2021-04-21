# Docker 101
## Build
Bygging av et Docker image gjøres med ```docker build``` kommandoen. I denne kommandoen spesifiserer man navnet på imaget som blir byggget, hvilken dockerfile som skal benyttes for bygging samt den lokale contexten for bygget (den lokale contexten er viktig mtp. kopiering av filer inn i imaget). Følgende er eksepel på docker-build kommandoer:
```powershell
docker build -t test:latest .
```
Denne kommandoen bygger imaget ```test:latest``` med lokal context satt til current directory (der kommandoen blir kjørt fra, spesifisert med ```.``` i kommandoen). Dersom dockefile som skal bygges heter **Dockerfile** og ligger i samme directory som den lokale contexten trenger en ikke spesifisere hvilken dockerfile som skal bygges.
```powershell
docker build -t test:latest -f .\Dockerfile2 .
```
Denne kommandoen bygger imaget ```test:latest```med lokal context satt til current directory. Dockerfile som blir benyttet tilgger i current directory og heter **Dockerfile2**

## Nyttige nøkkelord for Dockerfile
Følgende er et par nyttige nøkkelord for å komme igang med bygging av et container-image. Mer detaljert dokumentasjon finnes på [referanse-sidene](https://docs.docker.com/engine/reference/builder/) til Docker.
### FROM [x] AS [y]
Spesifiserer hvilket docker-image ditt image skal basere seg på (x), samt navngir dette imaget i docker build contexten (y). Syntax med eksempel:
``` Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
```
### EXPOSE [x]
Åpner spesifisert port (x) for kommunikasjon med containeren. Syntax med eksempel:
``` Dockerfile
EXPOSE 443
EXPOSE 80
```
Merk. Det er mye mulig at base-image for ASP.NET allerede har eksponert default http og https porter.

### WORKDIR [x]
Setter ```current directory``` i docker-build contexten. Syntax med eksempel:
``` Dockerfile
WORKDIR /App
```

### COPY [x] [y]
Kopierer en fil eller en directory fra lokal context (den lokale contexten spesifiserer ved start av docker build) til docker-build contexten. Syntax med eksempel:
``` Dockerfile
COPY TestApp/ App/
```
Her blir alt innhold i ```TestApp``` mappen kopiert inn i ```App``` mappen i docker-imaget.

### ENTRYPOINT [x, y]
Spesifiserer at docker her skal starte en prosess i containeren. Argument ```x``` spesifiserer en ```executable```, argument ```y``` spesifiserer parameter til ```x```. SYntax med eksempel:
```Dockerfile
ENTRYPOINT ["dotnet", "TestApp.dll"]
```
Merk. ```Entrypoint``` nøkkelordet er knyttet til kjøring av containeren, ikke build.

### RUN x
Spesifiserer at docker skal kjøre en kommando i build prosessen. Resultatet av denne kommandoen blir committet på docker-imaget som er under bygging. Syntax med eksempel:
``` Dockerfile
RUN dotnet build "TestApp.csproj" -c Release -o /app
```

## Eksponer en containers porter til **localhost** hvor docker containeren kjører
For å kunne sende trafikk til en docker-container som kjører på en maskin må docker konfigureres til å mappe TCP-porter fra **localhost** til docker-hosten. I en ```docker run``` kommando gjøres dette med flagget **-p**. Eksempel:
```powershell
docker run -p 8080:80 testapp:latest
```
Denne kommandoen starter en container fra image **testapp:latest** hvor tcp-kommunikasjon sendt til localhost:8080 vil bli sendt til containeres tcp-port 80 (her bindes port 8080 på localhost til port 80 på containeren).
## Send argumenter til en container
Det kan være veldig nyttig å kunne starte en container med argumenter. For eksempel: applikasjonen som kjører i containeren skal ha tilgang til en database. For å gjøre ting fleksibelt er det ikke ønskelig at databasens connectionstring er hardkodet. Her er da connectionstring en god kandidat for et argument som kan sendes til containeren ved oppstart.

Å starte en container med argumenter kan gjøres på et par ulike måter. En kan sende oppstarts-argumenter direkte inn til containeren (disse kan da programmet finne i ```string[] args``` i ```void Main()``` i et C# prosjekt). Eksempel:
```powershell
docker run test:latest 100
```
Denne kommandoen vil starte en container basert på image ```test:latest``` med oppstartsargumentet **100**

En annen mekanisme som kan benyttes for å starte en container med argumenter er miljøvaribler. Denne mekanismen har god synergi met ASP.NET Core sitt **Configuration** api. Ved oppstart vil ASP.NET Core lese mulige konfigurasjons-mekanismer og parse denne informasjonen til applikasjonens **appsettings.json**. Eksempel:
Gitt en ASP.NET Core applikasjon med følgende **appsettings.json** fil:
```json
{
    "Database":{
        "ConnectionString": "connectionString",
        "MigrateOnStartup": false
    }
}
```
Disse to applikasjons-instillingene kan da settes med følgende miljøvariabler:
```
Database__ConnectionString=some_connectionstring
Database__MigratOnStartup=true
```
Dersom en starter en container via ```docker run``` kommandoen kan miljøvariabler spesifiseres med flagget **-e**:
```powershell
docker run -e "Database__ConnectionString=some_connectionstring" -e "Database__MigrateOnStartup=true" testapp:lates
```

## Kjør flere containere sammen
Ved hjelp av **docker-compose** kan en enkelt starte flere containere i samme docker nettverk. Disse containerne vil da automatisk ha enkel tilgang til hverandre, og docker-nettverket tilbyr en innebygget DNS som gjør det enkelt å spesifisere kommunikasjons-parametre mellom ulike containere. Følgende er en docker-compose fil som spesifiserer et sett med containere som kan spille på lag.
```yaml
version: '3.5'
services:
    database-service:
        image: postgres:12
        environment:
            POSTGRES_DB: testdb
            POSTGRES_USER: testuser
            POSTGRES_PASSWORD: 97Kx%
        ports:
            - "5432:5432"
        volumes:
            - "testdb_data:/var/lib/postgresql/data"
    api-service:
        image: some_image:latest
        ports:
            - "8080:80"
            - "8084:443"
        depends_on:
            - database-service
        environment:
            - Database__User=testuser
            - Database__Password=97Kx%
            - Database__Port=5432
            - Database__Database=testdb
            - Database__Host=database-service
volumes:
    testdb_data:
```
Merk. Ved å spesifisere et navngitt ```volume``` i docker-compose filen vil database-containeren beholde data mellom hver gang containeren startes og stoppes. Dette eksempelet baserer seg på at api-ets database-connection kan konfigureres med miljøvariabler. Som eksempelet viser vil docker-nettverket benyttet her oversette kall sendt til ```database-service:5432``` til database-service sin IP i docker-nettverket.


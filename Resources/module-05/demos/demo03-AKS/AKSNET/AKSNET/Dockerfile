FROM microsoft/dotnet:2.2-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM microsoft/dotnet:2.2-sdk AS build
WORKDIR /src
COPY ["AKSNET/AKSNET.csproj", "AKSNET/"]
RUN dotnet restore "AKSNET/AKSNET.csproj"
COPY . .
WORKDIR "/src/AKSNET"
RUN dotnet build "AKSNET.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "AKSNET.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "AKSNET.dll"]
# CounselLink API - Local Recovery Pack (unverified until compiled on Windows)

These files fill gaps observed in the `dabyong/CL-API` repository as of 2026-11-09. This is not an audited deployment release; it is for local development **only**. Source references: GitHub repository `main` tree, 22-10 - Copy.sql, `obj/CounselLink.API.csproj.nuget.dgspec.json`, and the user's Reproduction Guide.

## Important warning

**The repository SQL drops and recreates `CounselLinkDB` at its beginning.** Do not execute it on an existing/shared/production database. Back up first, or use a disposable local SQL Server instance. Your separately uploaded `22-10.sql` is an earlier version and does not contain the same patches.

## Prerequisites

- Windows, PowerShell, Git, Kiro or another editor
- .NET SDK and runtime appropriate for net8.0. `global.json` asks for SDK 9.0.100 or a later major; .NET 10 SDK can satisfy the SDK selection, but a net8.0 application still needs a .NET 8 runtime. Upgrade to net10.0 after reproducing and testing, since .NET 8 and 9 reach end of support on 2026-11-10.
- SQL Server Database Engine (e.g., SQL Server Express) **and** SSMS; SSMS is not the database engine

## Install the source changes

1. Clone the repository: `git clone https://github.com/dabyong/CL-API.git`
2. `cd CL-API`
3. **Check your local files first**: `Get-ChildItem Program.cs, CounselLink.API.csproj, appsettings.json -ErrorAction SilentlyContinue`. If you already have a working local file, back it up and merge manually rather than overwriting it.
4. Copy the pack's `Program.cs`, `CounselLink.API.csproj`, `appsettings.json`, `Repositories/NotificationRepository.cs`, `Repositories/ReportRepository.cs`, `.gitignore`, and `scripts/smoke-test.ps1` into matching repository paths. Preserve your existing Controllers, DTOs, Data, Repositories and Swagger source files.
5. Edit `appsettings.json` if your SQL Server instance isn't `localhost\\SQLEXPRESS`. Keep passwords and secrets out of Git.

## Database setup

1. In SSMS connect to `localhost\\SQLEXPRESS` using Windows Authentication, or use your actual instance.
2. Use a **disposable/empty local instance** and check that `CounselLinkDB` can be reset without losing real data.
3. Open the repository's `22-10 - Copy.sql` and execute the *entire script*; the last `CREATE OR ALTER` statements apply compatibility fixes.
4. Validate with:

```sql
SELECT DB_NAME() AS CurrentDatabase;
SELECT COUNT(*) AS ProcedureCount FROM CounselLinkDB.sys.procedures WHERE is_ms_shipped = 0;
SELECT OBJECT_ID('CounselLinkDB.dbo.spAppointment_Select', 'P') AS AppointmentSelectId;
```

## Run the API

From the repo root in PowerShell:

```powershell
dotnet --list-sdks
dotnet --list-runtimes
dotnet restore
dotnet build
dotnet run --launch-profile http
```

Open `http://localhost:5271/swagger`, `http://localhost:5271/health` and `http://localhost:5271/health/db`. The port is defined in `Properties/launchSettings.json` in the repository. Keep this shell open while testing.

In a second PowerShell window (repo root), run read-only smoke tests:

```powershell
.\scripts\smoke-test.ps1
```

A 200 for `/health` means the API process is alive. A 200 for `/health/db` verifies a SQL connection. For GET endpoints, empty `[]` may be valid, but you must also test authorized writes and database state transitions **using only test data**.

## Before deployment

- Add authentication and role-based authorization for student, counselor, and admin endpoints, including enforcing identity ownership in code/SQL. Currently none is included.
- Add a restricted CORS policy for your real frontend URL, HTTPS, structured exception logging, input validation and secret management. Avoid returning raw SQL errors to clients.
- Upgrade to supported .NET 10 LTS and retest your dependencies and Swagger config.
- Create a real automated test suite with a disposable SQL test database, stored procedure tests and CI build validation.
- Refresh `STORED_PROCEDURE_CONTRACT.md` against the final SQL definitions and implementation. Remove tracked generated `bin/` and `obj/` files after preserving a safe backup and using `git rm -r --cached bin obj` to stop tracking them.

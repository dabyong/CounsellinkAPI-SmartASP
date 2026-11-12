/*
  CounselLink — Staging Database Verification
  Target: CounselLinkStagingDB on SQL Server Express

  Read-only: queries database metadata and object definitions only.
  Does NOT create, alter, drop, insert, update, or delete anything.

  How to use:
  1. Open in SQL Server Management Studio (SSMS).
  2. Connect to the SQL Server instance hosting CounselLinkStagingDB.
  3. Execute the entire script (F5).
  4. Review the Results tab. Core objects should all show FOUND.

  Important: Do not use this as a substitute for functional API tests.
*/

USE [master];
SET NOCOUNT ON;

-- Check that staging exists and is available BEFORE changing the query context.
IF DB_ID(N'CounselLinkStagingDB') IS NULL
BEGIN
    THROW 51001, 'CounselLinkStagingDB does not exist on this SQL Server instance. Verification stopped.', 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM sys.databases
    WHERE [name] = N'CounselLinkStagingDB'
      AND [state_desc] = N'ONLINE'
)
BEGIN
    THROW 51002, 'CounselLinkStagingDB is not ONLINE. Verification stopped.', 1;
END;

-- Single batch: THROW above prevents any later checks running in master.
USE [CounselLinkStagingDB];
SET NOCOUNT ON;

-- 1) Confirm which server and database this window is actually querying.
SELECT
    @@SERVERNAME AS SQLServerInstance,
    DB_NAME() AS CurrentDatabase,
    (SELECT [state_desc] FROM sys.databases WHERE [name] = DB_NAME()) AS DatabaseStatus,
    SYSDATETIME() AS CheckedAtServerTime;

-- 2) Check the total number of application tables and stored procedures.
SELECT
    (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS TableCount,
    (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0) AS ProcedureCount;

-- 3) Confirm core database tables exist.
--    FOUND = object exists; MISSING = schema installation needs review.
SELECT
    N'Table' AS ObjectType,
    expected.ObjectName,
    CASE WHEN OBJECT_ID(N'dbo.' + expected.ObjectName, N'U') IS NULL
         THEN N'MISSING' ELSE N'FOUND' END AS VerificationStatus
FROM (VALUES
    (N'Appointment'),
    (N'AppointmentSchedule'),
    (N'AppointmentConcern'),
    (N'CounselingSession'),
    (N'CONST_AppointmentStatus'),
    (N'CONST_AppointmentType'),
    (N'CONST_AttendanceStatus')
) AS expected(ObjectName)
ORDER BY expected.ObjectName;

-- 4) Confirm core appointment stored procedures exist.
SELECT
    N'Stored procedure' AS ObjectType,
    expected.ObjectName,
    CASE WHEN OBJECT_ID(N'dbo.' + expected.ObjectName, N'P') IS NULL
         THEN N'MISSING' ELSE N'FOUND' END AS VerificationStatus
FROM (VALUES
    (N'spAppointment_Insert'),
    (N'spAppointment_Select'),
    (N'spConfirmAppointment'),
    (N'spStudentConfirmAppointment'),
    (N'spRescheduleAppointment'),
    (N'spStudentAcceptReschedule'),
    (N'spCompleteAppointment')
) AS expected(ObjectName)
ORDER BY expected.ObjectName;

-- 5) One-line summary. Check any MISSING objects listed above.
;WITH ExpectedObjects AS
(
    SELECT N'U' AS ObjectKind, ObjectName
    FROM (VALUES
        (N'Appointment'), (N'AppointmentSchedule'), (N'AppointmentConcern'),
        (N'CounselingSession'), (N'CONST_AppointmentStatus'),
        (N'CONST_AppointmentType'), (N'CONST_AttendanceStatus')
    ) AS t(ObjectName)
    UNION ALL
    SELECT N'P', ObjectName
    FROM (VALUES
        (N'spAppointment_Insert'), (N'spAppointment_Select'),
        (N'spConfirmAppointment'), (N'spStudentConfirmAppointment'),
        (N'spRescheduleAppointment'), (N'spStudentAcceptReschedule'),
        (N'spCompleteAppointment')
    ) AS p(ObjectName)
),
Checks AS
(
    SELECT
        ObjectKind,
        ObjectName,
        CASE WHEN OBJECT_ID(N'dbo.' + ObjectName, ObjectKind) IS NULL
             THEN 0 ELSE 1 END AS IsFound
    FROM ExpectedObjects
)
SELECT
    DB_NAME() AS CurrentDatabase,
    COUNT(*) AS ExpectedCoreObjects,
    SUM(IsFound) AS FoundCoreObjects,
    COUNT(*) - SUM(IsFound) AS MissingCoreObjects,
    CASE WHEN MIN(IsFound) = 1 THEN N'PASS' ELSE N'REVIEW REQUIRED' END AS OverallStatus
FROM Checks;
GO

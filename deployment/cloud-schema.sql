USE db_ad0f7f_clstage;
GO

/* ==============================================================================
   PART 1: DDL SCHEMA & CONSTANTS
   ============================================================================== */

-- 1. Constant / Lookup Tables (With Engine-Level Unique Constraints)
CREATE TABLE CONST_AppointmentStatus
(
    AppointmentStatusID INT NOT NULL,
    AppointmentStatus   VARCHAR(50) NOT NULL,
    CONSTRAINT PK_CONST_AppointmentStatus PRIMARY KEY (AppointmentStatusID),
    CONSTRAINT UQ_CONST_AppointmentStatus UNIQUE (AppointmentStatus)
);
GO

INSERT INTO CONST_AppointmentStatus (AppointmentStatusID, AppointmentStatus)
VALUES
(1, 'Draft'),
(2, 'Requested'),
(3, 'Confirmed'),
(4, 'Completed'),
(5, 'Rescheduled');
GO

CREATE TABLE CONST_AttendanceStatus
(
    AttendanceStatusID INT NOT NULL,
    AttendanceStatus   VARCHAR(50) NOT NULL,
    CONSTRAINT PK_CONST_AttendanceStatus PRIMARY KEY (AttendanceStatusID),
    CONSTRAINT UQ_CONST_AttendanceStatus UNIQUE (AttendanceStatus)
);
GO

INSERT INTO CONST_AttendanceStatus (AttendanceStatusID, AttendanceStatus)
VALUES
(1, 'Pending'),
(2, 'Attended'),
(3, 'No-Show');
GO

CREATE TABLE CONST_ConcernType
(
    ConcernTypeID INT NOT NULL,
    ConcernType   VARCHAR(50) NOT NULL,
    CONSTRAINT PK_CONST_ConcernType PRIMARY KEY (ConcernTypeID),
    CONSTRAINT UQ_CONST_ConcernType UNIQUE (ConcernType)
);
GO

INSERT INTO CONST_ConcernType (ConcernTypeID, ConcernType)
VALUES
(1, 'Academic Concerns'),
(2, 'Personality/Behavioral Issues'),
(3, 'Family Issues/ Concerns'),
(4, 'Peer Issues/ Concerns'),
(5, 'Relationship Concerns'),
(6, 'Career/ Placement Concerns'),
(7, 'Mental Health Concerns'),
(8, 'Others');
GO

CREATE TABLE CONST_AppointmentType
(
    AppointmentTypeID INT NOT NULL,
    AppointmentType   VARCHAR(50) NOT NULL,
    CONSTRAINT PK_CONST_AppointmentType PRIMARY KEY (AppointmentTypeID),
    CONSTRAINT UQ_CONST_AppointmentType UNIQUE (AppointmentType)
);
GO

INSERT INTO CONST_AppointmentType (AppointmentTypeID, AppointmentType)
VALUES
(1, 'Student Initiated'),
(2, 'Walk-in'),
(3, 'Counselor Initiated'),
(4, 'Referred');
GO

CREATE TABLE CONST_SessionType
(
    SessionTypeID INT NOT NULL,
    SessionType   VARCHAR(50) NOT NULL,
    CONSTRAINT PK_CONST_SessionType PRIMARY KEY (SessionTypeID),
    CONSTRAINT UQ_CONST_SessionType UNIQUE (SessionType)
);
GO

INSERT INTO CONST_SessionType (SessionTypeID, SessionType)
VALUES
(1, 'For monitoring'),
(2, 'Follow-up');
GO

CREATE TABLE CONST_SpecialistReferral
(
    SpecialistReferralID INT NOT NULL,
    SpecialistRole       VARCHAR(50) NOT NULL,
    CONSTRAINT PK_CONST_SpecialistReferral PRIMARY KEY (SpecialistReferralID),
    CONSTRAINT UQ_CONST_SpecialistReferral UNIQUE (SpecialistRole)
);
GO

INSERT INTO CONST_SpecialistReferral (SpecialistReferralID, SpecialistRole)
VALUES
(1, 'Psychometrician'),
(2, 'Guidance Director');
GO

-- 2. Core Operational Entities
CREATE TABLE Counselor
(
    EmployeeID VARCHAR(7)  NOT NULL,
    FirstName  VARCHAR(50) NOT NULL,
    LastName   VARCHAR(50) NOT NULL,
    MiddleName VARCHAR(50) NULL,
    CONSTRAINT PK_Counselor PRIMARY KEY (EmployeeID)
);
GO

CREATE TABLE CounselorSchedule
(
    ScheduleID  INT IDENTITY(1,1) NOT NULL,
    EmployeeID  VARCHAR(7)        NOT NULL,
    SchoolYear  DATE              NOT NULL,
    ScheduleDay DATE              NOT NULL,
    StartTime   TIME(0)           NOT NULL,
    EndTime     TIME(0)           NOT NULL,
    IsAvailable BIT               NOT NULL DEFAULT 1,
    CONSTRAINT PK_CounselorSchedule PRIMARY KEY (ScheduleID),
    CONSTRAINT FK_CounselorSchedule_Counselor FOREIGN KEY (EmployeeID) REFERENCES Counselor(EmployeeID),
    CONSTRAINT CK_CounselorSchedule_TimeRange CHECK (EndTime > StartTime)
);
GO

CREATE TABLE CounselorAssignment
(
    AssignmentID     INT IDENTITY(1,1) NOT NULL,
    EmployeeID       VARCHAR(7)        NOT NULL,
    DepartmentID     VARCHAR(10)       NULL,
    ProgramID        VARCHAR(10)       NULL,
    YearOrGradeLevel INT               NULL,
    SchoolYear       DATE              NULL,
    CONSTRAINT PK_CounselorAssignment PRIMARY KEY (AssignmentID),
    CONSTRAINT FK_CounselorAssignment_Counselor FOREIGN KEY (EmployeeID) REFERENCES Counselor(EmployeeID)
);
GO

CREATE TABLE Appointment
(
    AppointmentID        INT IDENTITY(1,1) NOT NULL,
    IDNumber             VARCHAR(7)        NOT NULL,
    GradeOrYearLevel     INT               NULL,
    ProgramOrCourse      VARCHAR(50)       NULL,
    EmployeeID           VARCHAR(7)        NOT NULL,
    AppointmentDate      DATE              NOT NULL,
    AppointmentTime      TIME(0)           NOT NULL,
    AppointmentTypeID    INT               NOT NULL,
    AppointmentStatusID  INT               NOT NULL,
    AttendanceStatusID   INT               NOT NULL,
    RescheduleNote       VARCHAR(MAX)      NULL,
    ConcernDescription   VARCHAR(MAX)      NULL,
    OtherConcernDetail   VARCHAR(255)      NULL,
    ReferredBy           VARCHAR(100)      NULL,
    ReferralDate         DATE              NULL,
    InitialAppointmentID INT               NULL,
    ParentAppointmentID  INT               NULL,
    CONSTRAINT PK_Appointment PRIMARY KEY (AppointmentID),
    CONSTRAINT FK_Appointment_Counselor FOREIGN KEY (EmployeeID) REFERENCES Counselor(EmployeeID),
    CONSTRAINT FK_Appointment_AppointmentType FOREIGN KEY (AppointmentTypeID) REFERENCES CONST_AppointmentType(AppointmentTypeID),
    CONSTRAINT FK_Appointment_AppointmentStatus FOREIGN KEY (AppointmentStatusID) REFERENCES CONST_AppointmentStatus(AppointmentStatusID),
    CONSTRAINT FK_Appointment_AttendanceStatus FOREIGN KEY (AttendanceStatusID) REFERENCES CONST_AttendanceStatus(AttendanceStatusID),
    CONSTRAINT FK_Appointment_InitialAppt FOREIGN KEY (InitialAppointmentID) REFERENCES Appointment(AppointmentID),
    CONSTRAINT FK_Appointment_ParentAppt FOREIGN KEY (ParentAppointmentID) REFERENCES Appointment(AppointmentID)
);
GO

-- 3. Reschedule Tracking Table (Enforcing Single-Record-Per-Appointment)
CREATE TABLE AppointmentSchedule
(
    ScheduleID          INT IDENTITY(1,1) NOT NULL,
    AppointmentID       INT               NOT NULL,
    StartScheduleDate   DATETIME          NOT NULL,
    EndScheduleDate     DATETIME          NOT NULL,
    RescheduleNote      VARCHAR(MAX)      NULL,
    IsAcceptedByStudent BIT               NOT NULL DEFAULT 0,
    UpdatedAt           DATETIME          NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_AppointmentSchedule PRIMARY KEY (ScheduleID),
    CONSTRAINT FK_AppointmentSchedule_Appointment FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID),
    CONSTRAINT UQ_AppointmentSchedule_AppointmentID UNIQUE (AppointmentID),
    CONSTRAINT CK_AppointmentSchedule_DateRange CHECK (EndScheduleDate > StartScheduleDate)
);
GO

CREATE TABLE AppointmentConcern
(
    AppointmentConcernID INT IDENTITY(1,1) NOT NULL,
    AppointmentID        INT               NOT NULL,
    ConcernTypeID        INT               NOT NULL,
    CONSTRAINT PK_AppointmentConcern PRIMARY KEY (AppointmentConcernID),
    CONSTRAINT FK_AppointmentConcern_Appointment FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID),
    CONSTRAINT FK_AppointmentConcern_ConcernType FOREIGN KEY (ConcernTypeID) REFERENCES CONST_ConcernType(ConcernTypeID),
    CONSTRAINT UQ_Appointment_Concern UNIQUE (AppointmentID, ConcernTypeID)
);
GO

CREATE TABLE CounselingSession
(
    SessionID           INT IDENTITY(1,1) NOT NULL,
    AppointmentID       INT               NOT NULL,
    IDNumber            VARCHAR(7)        NOT NULL,
    GradeOrYearLevel    INT               NULL,
    EmployeeID          VARCHAR(7)        NOT NULL,
    ProgramOrCourse     VARCHAR(50)       NULL,
    AppointmentStatusID INT               NOT NULL,
    SessionDate         DATETIME          NOT NULL,
    SessionTypeID       INT               NULL,
    GeneralNotes        VARCHAR(MAX)      NOT NULL,
    SessionStartTime    DATETIME          NOT NULL,
    SessionEndTime      DATETIME          NULL,
    CONSTRAINT PK_CounselingSession PRIMARY KEY (SessionID),
    CONSTRAINT FK_CounselingSession_Appointment FOREIGN KEY (AppointmentID) REFERENCES Appointment(AppointmentID),
    CONSTRAINT FK_CounselingSession_Counselor FOREIGN KEY (EmployeeID) REFERENCES Counselor(EmployeeID),
    CONSTRAINT FK_CounselingSession_SessionType FOREIGN KEY (SessionTypeID) REFERENCES CONST_SessionType(SessionTypeID),
    CONSTRAINT FK_CounselingSession_Status FOREIGN KEY (AppointmentStatusID) REFERENCES CONST_AppointmentStatus(AppointmentStatusID),
    CONSTRAINT UQ_CounselingSession_Appointment UNIQUE (AppointmentID),
    CONSTRAINT CK_CounselingSession_TimeRange CHECK (SessionEndTime IS NULL OR SessionEndTime > SessionStartTime)
);
GO

CREATE TABLE StudentAssessment
(
    AssessmentID         INT IDENTITY(1,1) NOT NULL,
    SessionID            INT               NOT NULL,
    ProgressNotes        VARCHAR(MAX)      NULL,
    IsFollowUpNeeded     BIT               NOT NULL DEFAULT 0,
    IsForMonitoring      BIT               NOT NULL DEFAULT 0,
    SpecialistReferralID INT               NULL,
    CONSTRAINT PK_StudentAssessment PRIMARY KEY (AssessmentID),
    CONSTRAINT FK_StudentAssessment_Session FOREIGN KEY (SessionID) REFERENCES CounselingSession(SessionID),
    CONSTRAINT FK_StudentAssessment_SpecialistReferral FOREIGN KEY (SpecialistReferralID) REFERENCES CONST_SpecialistReferral(SpecialistReferralID),
    CONSTRAINT UQ_StudentAssessment_Session UNIQUE (SessionID)
);
GO

CREATE TABLE SessionFollowUp
(
    FollowUpID       INT IDENTITY(1,1) NOT NULL,
    AssessmentID     INT               NOT NULL,
    TargetDate       DATE              NOT NULL,
    FollowUpStatus   VARCHAR(20)       NOT NULL DEFAULT 'Pending',
    ActionRequired   VARCHAR(MAX)      NOT NULL,
    ResolutionNotes  VARCHAR(MAX)      NULL,
    CONSTRAINT PK_SessionFollowUp PRIMARY KEY (FollowUpID),
    CONSTRAINT FK_SessionFollowUp_StudentAssessment FOREIGN KEY (AssessmentID) REFERENCES StudentAssessment(AssessmentID),
    CONSTRAINT CHK_SessionFollowUp_Status CHECK (FollowUpStatus IN ('Pending', 'Completed', 'Cancelled'))
);
GO

CREATE TABLE Notification
(
    NotificationID     INT IDENTITY(1,1) NOT NULL,
    IDNumber           VARCHAR(7)        NOT NULL,
    [Content]          VARCHAR(MAX)      NOT NULL,
    [Timestamp]        DATETIME          NULL DEFAULT GETDATE(),
    NotificationStatus BIT               NOT NULL DEFAULT 0,
    CONSTRAINT PK_Notification PRIMARY KEY (NotificationID)
);
GO

/* ==============================================================================
   PART 2: REPORTING VIEWS (Excluding Counselor Columns per Requirement)
   ============================================================================== */

CREATE OR ALTER VIEW dbo.vw_AppointmentMasterlist
AS
SELECT 
    a.AppointmentID,
    a.IDNumber AS StudentID,
    a.GradeOrYearLevel,
    a.ProgramOrCourse,
    t.AppointmentType AS ModeOfCounseling,
    a.ReferredBy,
    sr.SpecialistRole AS ReferredTo,
    a.ReferralDate,
    cs.SessionDate AS DateTimeOfCounseling,
    st.SessionType,
    cs.GeneralNotes AS AppointmentNotes,
    ast.AppointmentStatus,
    att.AttendanceStatus
FROM Appointment a
JOIN CONST_AppointmentType t ON a.AppointmentTypeID = t.AppointmentTypeID
JOIN CONST_AppointmentStatus ast ON a.AppointmentStatusID = ast.AppointmentStatusID
JOIN CONST_AttendanceStatus att ON a.AttendanceStatusID = att.AttendanceStatusID
LEFT JOIN CounselingSession cs ON a.AppointmentID = cs.AppointmentID
LEFT JOIN CONST_SessionType st ON cs.SessionTypeID = st.SessionTypeID
LEFT JOIN StudentAssessment sa ON cs.SessionID = sa.SessionID
LEFT JOIN CONST_SpecialistReferral sr ON sa.SpecialistReferralID = sr.SpecialistReferralID;
GO

/* ==============================================================================
   PART 3: STANDARDIZED CRUD STORED PROCEDURES
   ============================================================================== */

-- 1. CONST_AppointmentType
CREATE OR ALTER PROCEDURE dbo.spConstAppointmentType_Insert
    @AppointmentTypeID INT,
    @AppointmentType   VARCHAR(50),
    @Message           VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM CONST_AppointmentType WHERE AppointmentTypeID = @AppointmentTypeID OR AppointmentType = @AppointmentType)
        BEGIN
            SET @Message = 'Duplicate Error: Appointment Type already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO CONST_AppointmentType (AppointmentTypeID, AppointmentType) 
        VALUES (@AppointmentTypeID, @AppointmentType);

        SET @Message = 'Appointment Type inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAppointmentType_Update
    @AppointmentTypeID INT,
    @AppointmentType   VARCHAR(50),
    @Message           VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_AppointmentType WHERE AppointmentTypeID = @AppointmentTypeID)
        BEGIN
            SET @Message = 'Error: Appointment Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CONST_AppointmentType WHERE AppointmentType = @AppointmentType AND AppointmentTypeID <> @AppointmentTypeID)
        BEGIN
            SET @Message = 'Duplicate Error: Appointment Type name already used by another record.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CONST_AppointmentType 
        SET AppointmentType = @AppointmentType 
        WHERE AppointmentTypeID = @AppointmentTypeID;

        SET @Message = 'Appointment Type updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAppointmentType_Delete
    @AppointmentTypeID INT,
    @Message           VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_AppointmentType WHERE AppointmentTypeID = @AppointmentTypeID)
        BEGIN
            SET @Message = 'Error: Appointment Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Appointment WHERE AppointmentTypeID = @AppointmentTypeID)
        BEGIN
            SET @Message = 'Cannot delete: Appointment Type in use.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CONST_AppointmentType WHERE AppointmentTypeID = @AppointmentTypeID;
        SET @Message = 'Appointment Type deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAppointmentType_Select
    @SearchID   INT = NULL,
    @SearchType VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT t.AppointmentTypeID, t.AppointmentType 
    FROM CONST_AppointmentType t
    WHERE (@SearchID IS NULL OR t.AppointmentTypeID = @SearchID)
      AND (@SearchType IS NULL OR t.AppointmentType LIKE '%' + @SearchType + '%');
END;
GO

-- 2. CONST_ConcernType
CREATE OR ALTER PROCEDURE dbo.spConstConcernType_Insert
    @ConcernTypeID INT,
    @ConcernType   VARCHAR(50),
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM CONST_ConcernType WHERE ConcernTypeID = @ConcernTypeID OR ConcernType = @ConcernType)
        BEGIN
            SET @Message = 'Duplicate Error: Concern Type already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO CONST_ConcernType (ConcernTypeID, ConcernType) 
        VALUES (@ConcernTypeID, @ConcernType);

        SET @Message = 'Concern Type inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstConcernType_Update
    @ConcernTypeID INT,
    @ConcernType   VARCHAR(50),
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_ConcernType WHERE ConcernTypeID = @ConcernTypeID)
        BEGIN
            SET @Message = 'Error: Concern Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CONST_ConcernType WHERE ConcernType = @ConcernType AND ConcernTypeID <> @ConcernTypeID)
        BEGIN
            SET @Message = 'Duplicate Error: Concern Type name already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CONST_ConcernType 
        SET ConcernType = @ConcernType 
        WHERE ConcernTypeID = @ConcernTypeID;

        SET @Message = 'Concern Type updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstConcernType_Delete
    @ConcernTypeID INT,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_ConcernType WHERE ConcernTypeID = @ConcernTypeID)
        BEGIN
            SET @Message = 'Error: Concern Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM AppointmentConcern WHERE ConcernTypeID = @ConcernTypeID)
        BEGIN
            SET @Message = 'Cannot delete: Concern Type in use.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CONST_ConcernType WHERE ConcernTypeID = @ConcernTypeID;
        SET @Message = 'Concern Type deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstConcernType_Select
    @SearchID   INT = NULL,
    @SearchType VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.ConcernTypeID, c.ConcernType 
    FROM CONST_ConcernType c
    WHERE (@SearchID IS NULL OR c.ConcernTypeID = @SearchID)
      AND (@SearchType IS NULL OR c.ConcernType LIKE '%' + @SearchType + '%');
END;
GO

-- 3. CONST_AttendanceStatus
CREATE OR ALTER PROCEDURE dbo.spConstAttendanceStatus_Insert
    @AttendanceStatusID INT,
    @AttendanceStatus   VARCHAR(50),
    @Message            VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM CONST_AttendanceStatus WHERE AttendanceStatusID = @AttendanceStatusID OR AttendanceStatus = @AttendanceStatus)
        BEGIN
            SET @Message = 'Duplicate Error: Attendance Status already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO CONST_AttendanceStatus (AttendanceStatusID, AttendanceStatus) 
        VALUES (@AttendanceStatusID, @AttendanceStatus);

        SET @Message = 'Attendance Status inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAttendanceStatus_Update
    @AttendanceStatusID INT,
    @AttendanceStatus   VARCHAR(50),
    @Message            VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_AttendanceStatus WHERE AttendanceStatusID = @AttendanceStatusID)
        BEGIN
            SET @Message = 'Error: Attendance Status does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CONST_AttendanceStatus WHERE AttendanceStatus = @AttendanceStatus AND AttendanceStatusID <> @AttendanceStatusID)
        BEGIN
            SET @Message = 'Duplicate Error: Attendance Status name already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CONST_AttendanceStatus 
        SET AttendanceStatus = @AttendanceStatus 
        WHERE AttendanceStatusID = @AttendanceStatusID;

        SET @Message = 'Attendance Status updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAttendanceStatus_Delete
    @AttendanceStatusID INT,
    @Message            VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_AttendanceStatus WHERE AttendanceStatusID = @AttendanceStatusID)
        BEGIN
            SET @Message = 'Error: Attendance Status does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Appointment WHERE AttendanceStatusID = @AttendanceStatusID)
        BEGIN
            SET @Message = 'Cannot delete: Attendance Status in use.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CONST_AttendanceStatus WHERE AttendanceStatusID = @AttendanceStatusID;
        SET @Message = 'Attendance Status deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAttendanceStatus_Select
    @SearchID     INT = NULL,
    @SearchStatus VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.AttendanceStatusID, a.AttendanceStatus 
    FROM CONST_AttendanceStatus a
    WHERE (@SearchID IS NULL OR a.AttendanceStatusID = @SearchID)
      AND (@SearchStatus IS NULL OR a.AttendanceStatus LIKE '%' + @SearchStatus + '%');
END;
GO

-- 4. CONST_AppointmentStatus
CREATE OR ALTER PROCEDURE dbo.spConstAppointmentStatus_Insert
    @AppointmentStatusID INT,
    @AppointmentStatus   VARCHAR(50),
    @Message             VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM CONST_AppointmentStatus WHERE AppointmentStatusID = @AppointmentStatusID OR AppointmentStatus = @AppointmentStatus)
        BEGIN
            SET @Message = 'Duplicate Error: Appointment Status already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO CONST_AppointmentStatus (AppointmentStatusID, AppointmentStatus) 
        VALUES (@AppointmentStatusID, @AppointmentStatus);

        SET @Message = 'Appointment Status inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAppointmentStatus_Update
    @AppointmentStatusID INT,
    @AppointmentStatus   VARCHAR(50),
    @Message             VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_AppointmentStatus WHERE AppointmentStatusID = @AppointmentStatusID)
        BEGIN
            SET @Message = 'Error: Appointment Status does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CONST_AppointmentStatus WHERE AppointmentStatus = @AppointmentStatus AND AppointmentStatusID <> @AppointmentStatusID)
        BEGIN
            SET @Message = 'Duplicate Error: Appointment Status name already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CONST_AppointmentStatus 
        SET AppointmentStatus = @AppointmentStatus 
        WHERE AppointmentStatusID = @AppointmentStatusID;

        SET @Message = 'Appointment Status updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAppointmentStatus_Delete
    @AppointmentStatusID INT,
    @Message             VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_AppointmentStatus WHERE AppointmentStatusID = @AppointmentStatusID)
        BEGIN
            SET @Message = 'Error: Appointment Status does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check both Appointment and CounselingSession dependencies
        IF EXISTS (SELECT 1 FROM Appointment WHERE AppointmentStatusID = @AppointmentStatusID)
           OR EXISTS (SELECT 1 FROM CounselingSession WHERE AppointmentStatusID = @AppointmentStatusID)
        BEGIN
            SET @Message = 'Cannot delete: Appointment Status in use by appointments or counseling sessions.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CONST_AppointmentStatus WHERE AppointmentStatusID = @AppointmentStatusID;
        SET @Message = 'Appointment Status deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstAppointmentStatus_Select
    @SearchID     INT = NULL,
    @SearchStatus VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.AppointmentStatusID, s.AppointmentStatus 
    FROM CONST_AppointmentStatus s
    WHERE (@SearchID IS NULL OR s.AppointmentStatusID = @SearchID)
      AND (@SearchStatus IS NULL OR s.AppointmentStatus LIKE '%' + @SearchStatus + '%');
END;
GO

-- 5. CONST_SessionType
CREATE OR ALTER PROCEDURE dbo.spConstSessionType_Insert
    @SessionTypeID INT,
    @SessionType   VARCHAR(50),
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM CONST_SessionType WHERE SessionTypeID = @SessionTypeID OR SessionType = @SessionType)
        BEGIN
            SET @Message = 'Duplicate Error: Session Type already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO CONST_SessionType (SessionTypeID, SessionType) 
        VALUES (@SessionTypeID, @SessionType);

        SET @Message = 'Session Type inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstSessionType_Update
    @SessionTypeID INT,
    @SessionType   VARCHAR(50),
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_SessionType WHERE SessionTypeID = @SessionTypeID)
        BEGIN
            SET @Message = 'Error: Session Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CONST_SessionType WHERE SessionType = @SessionType AND SessionTypeID <> @SessionTypeID)
        BEGIN
            SET @Message = 'Duplicate Error: Session Type name already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CONST_SessionType 
        SET SessionType = @SessionType 
        WHERE SessionTypeID = @SessionTypeID;

        SET @Message = 'Session Type updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstSessionType_Delete
    @SessionTypeID INT,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_SessionType WHERE SessionTypeID = @SessionTypeID)
        BEGIN
            SET @Message = 'Error: Session Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CounselingSession WHERE SessionTypeID = @SessionTypeID)
        BEGIN
            SET @Message = 'Cannot delete: Session Type in use.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CONST_SessionType WHERE SessionTypeID = @SessionTypeID;
        SET @Message = 'Session Type deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstSessionType_Select
    @SearchID   INT = NULL,
    @SearchType VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT st.SessionTypeID, st.SessionType 
    FROM CONST_SessionType st
    WHERE (@SearchID IS NULL OR st.SessionTypeID = @SearchID)
      AND (@SearchType IS NULL OR st.SessionType LIKE '%' + @SearchType + '%');
END;
GO

-- 6. CONST_SpecialistReferral
CREATE OR ALTER PROCEDURE dbo.spConstSpecialistReferral_Insert
    @SpecialistReferralID INT,
    @SpecialistRole       VARCHAR(50),
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM CONST_SpecialistReferral WHERE SpecialistReferralID = @SpecialistReferralID OR SpecialistRole = @SpecialistRole)
        BEGIN
            SET @Message = 'Duplicate Error: Specialist Referral already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO CONST_SpecialistReferral (SpecialistReferralID, SpecialistRole) 
        VALUES (@SpecialistReferralID, @SpecialistRole);

        SET @Message = 'Specialist Referral inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstSpecialistReferral_Update
    @SpecialistReferralID INT,
    @SpecialistRole       VARCHAR(50),
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_SpecialistReferral WHERE SpecialistReferralID = @SpecialistReferralID)
        BEGIN
            SET @Message = 'Error: Specialist Referral does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CONST_SpecialistReferral WHERE SpecialistRole = @SpecialistRole AND SpecialistReferralID <> @SpecialistReferralID)
        BEGIN
            SET @Message = 'Duplicate Error: Specialist Referral role already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CONST_SpecialistReferral 
        SET SpecialistRole = @SpecialistRole 
        WHERE SpecialistReferralID = @SpecialistReferralID;

        SET @Message = 'Specialist Referral updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstSpecialistReferral_Delete
    @SpecialistReferralID INT,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CONST_SpecialistReferral WHERE SpecialistReferralID = @SpecialistReferralID)
        BEGIN
            SET @Message = 'Error: Specialist Referral does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM StudentAssessment WHERE SpecialistReferralID = @SpecialistReferralID)
        BEGIN
            SET @Message = 'Cannot delete: Specialist Referral in use.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CONST_SpecialistReferral WHERE SpecialistReferralID = @SpecialistReferralID;
        SET @Message = 'Specialist Referral deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spConstSpecialistReferral_Select
    @SearchID   INT = NULL,
    @SearchRole VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT sr.SpecialistReferralID, sr.SpecialistRole 
    FROM CONST_SpecialistReferral sr
    WHERE (@SearchID IS NULL OR sr.SpecialistReferralID = @SearchID)
      AND (@SearchRole IS NULL OR sr.SpecialistRole LIKE '%' + @SearchRole + '%');
END;
GO

-- 7. Counselor CRUD
CREATE OR ALTER PROCEDURE dbo.spCounselor_Insert
    @EmployeeID VARCHAR(7),
    @FirstName  VARCHAR(50),
    @LastName   VARCHAR(50),
    @MiddleName VARCHAR(50) = NULL,
    @Message    VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM Counselor WHERE EmployeeID = @EmployeeID)
        BEGIN
            SET @Message = 'Duplicate Error: Counselor EmployeeID already exists.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO Counselor (EmployeeID, FirstName, LastName, MiddleName) 
        VALUES (@EmployeeID, @FirstName, @LastName, @MiddleName);

        SET @Message = 'Counselor inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselor_Update
    @EmployeeID VARCHAR(7),
    @FirstName  VARCHAR(50),
    @LastName   VARCHAR(50),
    @MiddleName VARCHAR(50) = NULL,
    @Message    VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Counselor WHERE EmployeeID = @EmployeeID)
        BEGIN
            SET @Message = 'Error: Counselor record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Counselor 
        SET FirstName  = @FirstName, 
            LastName   = @LastName, 
            MiddleName = @MiddleName 
        WHERE EmployeeID = @EmployeeID;

        SET @Message = 'Counselor updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselor_Delete
    @EmployeeID VARCHAR(7),
    @Message    VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Counselor WHERE EmployeeID = @EmployeeID)
        BEGIN
            SET @Message = 'Error: Counselor record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Block if appointments or clinical sessions exist
        IF EXISTS (SELECT 1 FROM Appointment WHERE EmployeeID = @EmployeeID)
           OR EXISTS (SELECT 1 FROM CounselingSession WHERE EmployeeID = @EmployeeID)
        BEGIN
            SET @Message = 'Cannot delete: Counselor has associated appointments or counseling sessions.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Delete dependent schedules and assignments cleanly
        DELETE FROM CounselorSchedule WHERE EmployeeID = @EmployeeID;
        DELETE FROM CounselorAssignment WHERE EmployeeID = @EmployeeID;
        DELETE FROM Counselor WHERE EmployeeID = @EmployeeID;

        SET @Message = 'Counselor deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselor_Select
    @SearchEmployeeID VARCHAR(7) = NULL,
    @SearchFirstName  VARCHAR(50) = NULL,
    @SearchLastName   VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.EmployeeID, c.FirstName, c.LastName, c.MiddleName 
    FROM Counselor c
    WHERE (@SearchEmployeeID IS NULL OR c.EmployeeID = @SearchEmployeeID)
      AND (@SearchFirstName IS NULL OR c.FirstName LIKE '%' + @SearchFirstName + '%')
      AND (@SearchLastName IS NULL OR c.LastName LIKE '%' + @SearchLastName + '%');
END;
GO

-- 8. CounselorAssignment CRUD
CREATE OR ALTER PROCEDURE dbo.spCounselorAssignment_Insert
    @EmployeeID       VARCHAR(7),
    @DepartmentID     VARCHAR(10) = NULL,
    @ProgramID        VARCHAR(10) = NULL,
    @YearOrGradeLevel INT = NULL,
    @SchoolYear       DATE = NULL,
    @NewID            INT OUTPUT,
    @Message          VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Counselor WHERE EmployeeID = @EmployeeID)
        BEGIN
            SET @Message = 'Error: Specified Counselor does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS 
        (
            SELECT 1 FROM CounselorAssignment 
            WHERE EmployeeID = @EmployeeID 
              AND ISNULL(DepartmentID, '') = ISNULL(@DepartmentID, '')
              AND ISNULL(ProgramID, '') = ISNULL(@ProgramID, '')
              AND ISNULL(YearOrGradeLevel, 0) = ISNULL(@YearOrGradeLevel, 0)
              AND ISNULL(SchoolYear, '1900-01-01') = ISNULL(@SchoolYear, '1900-01-01')
        )
        BEGIN
            SET @Message = 'Duplicate Error: Counselor assignment already exists for this cohort/school year.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO CounselorAssignment (EmployeeID, DepartmentID, ProgramID, YearOrGradeLevel, SchoolYear)
        VALUES (@EmployeeID, @DepartmentID, @ProgramID, @YearOrGradeLevel, @SchoolYear);

        SET @NewID = SCOPE_IDENTITY();
        SET @Message = 'Counselor assignment inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselorAssignment_Update
    @AssignmentID     INT,
    @DepartmentID     VARCHAR(10) = NULL,
    @ProgramID        VARCHAR(10) = NULL,
    @YearOrGradeLevel INT = NULL,
    @SchoolYear       DATE = NULL,
    @Message          VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CounselorAssignment WHERE AssignmentID = @AssignmentID)
        BEGIN
            SET @Message = 'Error: Counselor assignment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CounselorAssignment
        SET DepartmentID     = @DepartmentID, 
            ProgramID        = @ProgramID, 
            YearOrGradeLevel = @YearOrGradeLevel, 
            SchoolYear       = @SchoolYear
        WHERE AssignmentID = @AssignmentID;

        SET @Message = 'Counselor assignment updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselorAssignment_Delete
    @AssignmentID INT,
    @Message      VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CounselorAssignment WHERE AssignmentID = @AssignmentID)
        BEGIN
            SET @Message = 'Error: Counselor assignment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CounselorAssignment WHERE AssignmentID = @AssignmentID;
        SET @Message = 'Counselor assignment deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselorAssignment_Select
    @SearchAssignmentID INT = NULL,
    @SearchEmployeeID   VARCHAR(7) = NULL,
    @SearchDepartmentID VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        ca.AssignmentID, 
        ca.EmployeeID, 
        ca.DepartmentID, 
        ca.ProgramID, 
        ca.YearOrGradeLevel, 
        ca.SchoolYear 
    FROM CounselorAssignment ca
    WHERE (@SearchAssignmentID IS NULL OR ca.AssignmentID = @SearchAssignmentID)
      AND (@SearchEmployeeID IS NULL OR ca.EmployeeID = @SearchEmployeeID)
      AND (@SearchDepartmentID IS NULL OR ca.DepartmentID = @SearchDepartmentID);
END;
GO

-- 9. Appointment CRUD
CREATE OR ALTER PROCEDURE dbo.spAppointment_Insert
    @IDNumber             VARCHAR(7),
    @GradeOrYearLevel     INT = NULL,
    @ProgramOrCourse      VARCHAR(50) = NULL,
    @EmployeeID           VARCHAR(7),
    @AppointmentDate      DATE,
    @AppointmentTime      TIME(0),
    @AppointmentTypeID    INT,
    @AppointmentStatusID  INT,
    @AttendanceStatusID   INT,
    @RescheduleNote       VARCHAR(MAX) = NULL,
    @ConcernDescription   VARCHAR(MAX) = NULL,
    @OtherConcernDetail   VARCHAR(255) = NULL,
    @ReferredBy           VARCHAR(100) = NULL,
    @ReferralDate         DATE = NULL,
    @InitialAppointmentID INT = NULL,
    @ParentAppointmentID  INT = NULL,
    @NewID                INT OUTPUT,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Counselor WHERE EmployeeID = @EmployeeID)
        BEGIN
            SET @Message = 'Error: Counselor does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        IF NOT EXISTS (SELECT 1 FROM CONST_AppointmentType WHERE AppointmentTypeID = @AppointmentTypeID)
        BEGIN
            SET @Message = 'Error: Appointment Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Prevent duplicate booking for the exact same student, counselor, date, and time
        IF EXISTS
        (
            SELECT 1 FROM Appointment WITH (UPDLOCK, HOLDLOCK)
            WHERE IDNumber = @IDNumber
              AND EmployeeID = @EmployeeID
              AND AppointmentDate = @AppointmentDate
              AND AppointmentTime = @AppointmentTime
              AND AppointmentStatusID NOT IN (5)
        )
        BEGIN
            SET @Message = 'Duplicate Error: An active appointment already exists for this student and counselor at this time.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO Appointment
        (
            IDNumber, GradeOrYearLevel, ProgramOrCourse, EmployeeID, AppointmentDate, AppointmentTime,
            AppointmentTypeID, AppointmentStatusID, AttendanceStatusID, RescheduleNote, ConcernDescription,
            OtherConcernDetail, ReferredBy, ReferralDate, InitialAppointmentID, ParentAppointmentID
        )
        VALUES
        (
            @IDNumber, @GradeOrYearLevel, @ProgramOrCourse, @EmployeeID, @AppointmentDate, @AppointmentTime,
            @AppointmentTypeID, @AppointmentStatusID, @AttendanceStatusID, @RescheduleNote, @ConcernDescription,
            @OtherConcernDetail, @ReferredBy, @ReferralDate, @InitialAppointmentID, @ParentAppointmentID
        );

        SET @NewID = SCOPE_IDENTITY();
        SET @Message = 'Appointment inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Update
    @AppointmentID        INT,
    @AppointmentStatusID  INT,
    @AttendanceStatusID   INT,
    @RescheduleNote       VARCHAR(MAX) = NULL,
    @ConcernDescription   VARCHAR(MAX) = NULL,
    @OtherConcernDetail   VARCHAR(255) = NULL,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Error: Appointment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Appointment
        SET AppointmentStatusID = @AppointmentStatusID, 
            AttendanceStatusID  = @AttendanceStatusID,
            RescheduleNote      = @RescheduleNote, 
            ConcernDescription  = @ConcernDescription, 
            OtherConcernDetail  = @OtherConcernDetail
        WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Delete
    @AppointmentID INT,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Error: Appointment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CounselingSession WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Cannot delete: Appointment has linked counseling sessions.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Appointment WHERE InitialAppointmentID = @AppointmentID OR ParentAppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Cannot delete: Appointment is referenced as an initial or parent appointment by other records.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM AppointmentSchedule WHERE AppointmentID = @AppointmentID;
        DELETE FROM AppointmentConcern WHERE AppointmentID = @AppointmentID;
        DELETE FROM Appointment WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Select
    @SearchAppointmentID INT = NULL,
    @SearchIDNumber      VARCHAR(7) = NULL,
    @SearchGradeOrYear   INT = NULL,
    @SearchProgram       VARCHAR(50) = NULL,
    @SearchEmployeeID    VARCHAR(7) = NULL,
    @SearchStartDate     DATE = NULL,
    @SearchEndDate       DATE = NULL,
    @SearchAppointmentTime TIME(0) = NULL,
    @SearchTypeID        INT = NULL,
    @SearchStatusID      INT = NULL,
    @SearchAttendanceID  INT = NULL,
    @SearchReferredBy    VARCHAR(100) = NULL,
    @SearchReferralStart DATE = NULL,
    @SearchReferralEnd   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        a.AppointmentID,
        a.IDNumber,
        a.GradeOrYearLevel,
        a.ProgramOrCourse,
        a.EmployeeID,
        a.AppointmentDate,
        a.AppointmentTime,
        a.AppointmentTypeID,
        a.AppointmentStatusID,
        a.AttendanceStatusID,
        a.RescheduleNote,
        a.ConcernDescription,
        a.OtherConcernDetail,
        a.ReferredBy,
        a.ReferralDate,
        a.InitialAppointmentID,
        a.ParentAppointmentID
    FROM Appointment a
    WHERE (@SearchAppointmentID IS NULL OR a.AppointmentID = @SearchAppointmentID)
      AND (@SearchIDNumber IS NULL OR a.IDNumber = @SearchIDNumber)
      AND (@SearchGradeOrYear IS NULL OR a.GradeOrYearLevel = @SearchGradeOrYear)
      AND (@SearchProgram IS NULL OR a.ProgramOrCourse LIKE '%' + @SearchProgram + '%')
      AND (@SearchEmployeeID IS NULL OR a.EmployeeID = @SearchEmployeeID)
      AND (@SearchStartDate IS NULL OR a.AppointmentDate >= @SearchStartDate)
      AND (@SearchEndDate IS NULL OR a.AppointmentDate <= @SearchEndDate)
      AND (@SearchAppointmentTime IS NULL OR a.AppointmentTime = @SearchAppointmentTime)
      AND (@SearchTypeID IS NULL OR a.AppointmentTypeID = @SearchTypeID)
      AND (@SearchStatusID IS NULL OR a.AppointmentStatusID = @SearchStatusID)
      AND (@SearchAttendanceID IS NULL OR a.AttendanceStatusID = @SearchAttendanceID)
      AND (@SearchReferredBy IS NULL OR a.ReferredBy LIKE '%' + @SearchReferredBy + '%')
      AND (@SearchReferralStart IS NULL OR a.ReferralDate >= @SearchReferralStart)
      AND (@SearchReferralEnd IS NULL OR a.ReferralDate <= @SearchReferralEnd);
END;
GO

-- 10. AppointmentConcern CRUD
CREATE OR ALTER PROCEDURE dbo.spAppointmentConcern_Insert
    @AppointmentID INT,
    @ConcernTypeID INT,
    @NewID         INT OUTPUT,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Error: Appointment does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        IF NOT EXISTS (SELECT 1 FROM CONST_ConcernType WHERE ConcernTypeID = @ConcernTypeID)
        BEGIN
            SET @Message = 'Error: Concern Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        IF EXISTS (SELECT 1 FROM AppointmentConcern WHERE AppointmentID = @AppointmentID AND ConcernTypeID = @ConcernTypeID)
        BEGIN
            SET @Message = 'Duplicate Error: Concern already associated with this appointment.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO AppointmentConcern (AppointmentID, ConcernTypeID) 
        VALUES (@AppointmentID, @ConcernTypeID);

        SET @NewID = SCOPE_IDENTITY();
        SET @Message = 'Appointment concern recorded successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointmentConcern_Update
    @AppointmentConcernID INT,
    @ConcernTypeID        INT,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM AppointmentConcern WHERE AppointmentConcernID = @AppointmentConcernID)
        BEGIN
            SET @Message = 'Error: Appointment concern record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        IF NOT EXISTS (SELECT 1 FROM CONST_ConcernType WHERE ConcernTypeID = @ConcernTypeID)
        BEGIN
            SET @Message = 'Error: Concern Type does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE AppointmentConcern 
        SET ConcernTypeID = @ConcernTypeID 
        WHERE AppointmentConcernID = @AppointmentConcernID;

        SET @Message = 'Appointment concern updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointmentConcern_Delete
    @AppointmentConcernID INT,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM AppointmentConcern WHERE AppointmentConcernID = @AppointmentConcernID)
        BEGIN
            SET @Message = 'Error: Appointment concern record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM AppointmentConcern WHERE AppointmentConcernID = @AppointmentConcernID;
        SET @Message = 'Appointment concern deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointmentConcern_Select
    @SearchConcernID     INT = NULL,
    @SearchAppointmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        ac.AppointmentConcernID, 
        ac.AppointmentID, 
        ac.ConcernTypeID 
    FROM AppointmentConcern ac
    WHERE (@SearchConcernID IS NULL OR ac.AppointmentConcernID = @SearchConcernID)
      AND (@SearchAppointmentID IS NULL OR ac.AppointmentID = @SearchAppointmentID);
END;
GO

-- 11. CounselingSession CRUD
CREATE OR ALTER PROCEDURE dbo.spCounselingSession_Insert
    @AppointmentID       INT,
    @IDNumber            VARCHAR(7) = NULL,
    @GradeOrYearLevel    INT = NULL,
    @EmployeeID          VARCHAR(7) = NULL,
    @ProgramOrCourse     VARCHAR(50) = NULL,
    @AppointmentStatusID INT = 4,
    @SessionDate         DATETIME,
    @SessionTypeID       INT = NULL,
    @GeneralNotes        VARCHAR(MAX),
    @SessionStartTime    DATETIME,
    @SessionEndTime      DATETIME = NULL,
    @NewID               INT OUTPUT,
    @Message             VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate parent appointment and derive consistency
        DECLARE @ApptStudentID VARCHAR(7), @ApptCounselorID VARCHAR(7), @ApptGrade INT, @ApptProg VARCHAR(50);
        SELECT 
            @ApptStudentID   = a.IDNumber,
            @ApptCounselorID = a.EmployeeID,
            @ApptGrade       = a.GradeOrYearLevel,
            @ApptProg        = a.ProgramOrCourse
        FROM Appointment a
        WHERE a.AppointmentID = @AppointmentID;

        IF @ApptStudentID IS NULL
        BEGIN
            SET @Message = 'Error: Appointment does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CounselingSession WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Duplicate Error: A counseling session already exists for this appointment.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @SessionEndTime IS NOT NULL AND @SessionEndTime <= @SessionStartTime
        BEGIN
            SET @Message = 'Error: Session end time must be after session start time.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Ensure derived fields strictly match parent appointment
        SET @IDNumber         = @ApptStudentID;
        SET @EmployeeID       = @ApptCounselorID;
        SET @GradeOrYearLevel = COALESCE(@GradeOrYearLevel, @ApptGrade);
        SET @ProgramOrCourse  = COALESCE(@ProgramOrCourse, @ApptProg);

        INSERT INTO CounselingSession 
        (
            AppointmentID, IDNumber, GradeOrYearLevel, EmployeeID, ProgramOrCourse, 
            AppointmentStatusID, SessionDate, SessionTypeID, GeneralNotes, SessionStartTime, SessionEndTime
        )
        VALUES 
        (
            @AppointmentID, @IDNumber, @GradeOrYearLevel, @EmployeeID, @ProgramOrCourse, 
            @AppointmentStatusID, @SessionDate, @SessionTypeID, @GeneralNotes, @SessionStartTime, @SessionEndTime
        );

        SET @NewID = SCOPE_IDENTITY();
        SET @Message = 'Counseling Session recorded successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselingSession_Update
    @SessionID      INT,
    @SessionTypeID  INT = NULL,
    @GeneralNotes   VARCHAR(MAX),
    @SessionEndTime DATETIME = NULL,
    @Message        VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @StartTime DATETIME;
        SELECT @StartTime = SessionStartTime FROM CounselingSession WHERE SessionID = @SessionID;

        IF @StartTime IS NULL
        BEGIN
            SET @Message = 'Error: Counseling Session record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @SessionEndTime IS NOT NULL AND @SessionEndTime <= @StartTime
        BEGIN
            SET @Message = 'Error: Session end time must be after session start time.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE CounselingSession
        SET SessionTypeID  = @SessionTypeID, 
            GeneralNotes   = @GeneralNotes, 
            SessionEndTime = @SessionEndTime
        WHERE SessionID = @SessionID;

        SET @Message = 'Counseling Session updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselingSession_Delete
    @SessionID INT,
    @Message   VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CounselingSession WHERE SessionID = @SessionID)
        BEGIN
            SET @Message = 'Error: Counseling Session record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM StudentAssessment WHERE SessionID = @SessionID)
        BEGIN
            SET @Message = 'Cannot delete: Session has student assessments.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM CounselingSession WHERE SessionID = @SessionID;
        SET @Message = 'Counseling Session deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spCounselingSession_Select
    @SearchSessionID     INT = NULL,
    @SearchAppointmentID INT = NULL,
    @SearchIDNumber      VARCHAR(7) = NULL,
    @SearchEmployeeID    VARCHAR(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        cs.SessionID, 
        cs.AppointmentID, 
        cs.IDNumber,
        cs.GradeOrYearLevel,
        cs.EmployeeID,
        cs.ProgramOrCourse,
        cs.AppointmentStatusID,
        cs.SessionDate, 
        cs.SessionTypeID, 
        cs.GeneralNotes, 
        cs.SessionStartTime, 
        cs.SessionEndTime 
    FROM CounselingSession cs
    WHERE (@SearchSessionID IS NULL OR cs.SessionID = @SearchSessionID)
      AND (@SearchAppointmentID IS NULL OR cs.AppointmentID = @SearchAppointmentID)
      AND (@SearchIDNumber IS NULL OR cs.IDNumber = @SearchIDNumber)
      AND (@SearchEmployeeID IS NULL OR cs.EmployeeID = @SearchEmployeeID);
END;
GO

-- 12. StudentAssessment CRUD
CREATE OR ALTER PROCEDURE dbo.spStudentAssessment_Insert
    @SessionID            INT,
    @ProgressNotes        VARCHAR(MAX) = NULL,
    @IsFollowUpNeeded     BIT = 0,
    @IsForMonitoring      BIT = 0,
    @SpecialistReferralID INT = NULL,
    @NewID                INT OUTPUT,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM CounselingSession WHERE SessionID = @SessionID)
        BEGIN
            SET @Message = 'Error: Counseling Session does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM StudentAssessment WHERE SessionID = @SessionID)
        BEGIN
            SET @Message = 'Duplicate Error: An assessment already exists for this counseling session.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO StudentAssessment (SessionID, ProgressNotes, IsFollowUpNeeded, IsForMonitoring, SpecialistReferralID)
        VALUES (@SessionID, @ProgressNotes, @IsFollowUpNeeded, @IsForMonitoring, @SpecialistReferralID);

        SET @NewID = SCOPE_IDENTITY();
        SET @Message = 'Student Assessment saved successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spStudentAssessment_Update
    @AssessmentID         INT,
    @ProgressNotes        VARCHAR(MAX) = NULL,
    @IsFollowUpNeeded     BIT = 0,
    @IsForMonitoring      BIT = 0,
    @SpecialistReferralID INT = NULL,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM StudentAssessment WHERE AssessmentID = @AssessmentID)
        BEGIN
            SET @Message = 'Error: Student Assessment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE StudentAssessment
        SET ProgressNotes        = @ProgressNotes, 
            IsFollowUpNeeded     = @IsFollowUpNeeded,
            IsForMonitoring      = @IsForMonitoring, 
            SpecialistReferralID = @SpecialistReferralID
        WHERE AssessmentID = @AssessmentID;

        SET @Message = 'Student Assessment updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spStudentAssessment_Delete
    @AssessmentID INT,
    @Message      VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM StudentAssessment WHERE AssessmentID = @AssessmentID)
        BEGIN
            SET @Message = 'Error: Student Assessment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM SessionFollowUp WHERE AssessmentID = @AssessmentID)
        BEGIN
            SET @Message = 'Cannot delete: Assessment has follow-up actions.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM StudentAssessment WHERE AssessmentID = @AssessmentID;
        SET @Message = 'Student Assessment deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spStudentAssessment_Select
    @SearchAssessmentID INT = NULL,
    @SearchSessionID    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        sa.AssessmentID, 
        sa.SessionID, 
        sa.ProgressNotes, 
        sa.IsFollowUpNeeded, 
        sa.IsForMonitoring, 
        sa.SpecialistReferralID 
    FROM StudentAssessment sa
    WHERE (@SearchAssessmentID IS NULL OR sa.AssessmentID = @SearchAssessmentID)
      AND (@SearchSessionID IS NULL OR sa.SessionID = @SearchSessionID);
END;
GO

-- 13. SessionFollowUp CRUD
CREATE OR ALTER PROCEDURE dbo.spSessionFollowUp_Insert
    @AssessmentID    INT,
    @TargetDate      DATE,
    @FollowUpStatus  VARCHAR(20) = 'Pending',
    @ActionRequired  VARCHAR(MAX),
    @ResolutionNotes VARCHAR(MAX) = NULL,
    @NewID           INT OUTPUT,
    @Message         VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM StudentAssessment WHERE AssessmentID = @AssessmentID)
        BEGIN
            SET @Message = 'Error: Student Assessment does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO SessionFollowUp (AssessmentID, TargetDate, FollowUpStatus, ActionRequired, ResolutionNotes)
        VALUES (@AssessmentID, @TargetDate, @FollowUpStatus, @ActionRequired, @ResolutionNotes);

        SET @NewID = SCOPE_IDENTITY();
        SET @Message = 'Session Follow-up inserted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spSessionFollowUp_Update
    @FollowUpID      INT,
    @TargetDate      DATE,
    @FollowUpStatus  VARCHAR(20),
    @ActionRequired  VARCHAR(MAX),
    @ResolutionNotes VARCHAR(MAX) = NULL,
    @Message         VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM SessionFollowUp WHERE FollowUpID = @FollowUpID)
        BEGIN
            SET @Message = 'Error: Session Follow-up record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE SessionFollowUp
        SET TargetDate      = @TargetDate, 
            FollowUpStatus  = @FollowUpStatus, 
            ActionRequired  = @ActionRequired, 
            ResolutionNotes = @ResolutionNotes
        WHERE FollowUpID = @FollowUpID;

        SET @Message = 'Session Follow-up updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spSessionFollowUp_Delete
    @FollowUpID INT,
    @Message    VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM SessionFollowUp WHERE FollowUpID = @FollowUpID)
        BEGIN
            SET @Message = 'Error: Session Follow-up record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM SessionFollowUp WHERE FollowUpID = @FollowUpID;
        SET @Message = 'Session Follow-up deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spSessionFollowUp_Select
    @SearchFollowUpID   INT = NULL,
    @SearchAssessmentID INT = NULL,
    @SearchStatus       VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        sfu.FollowUpID, 
        sfu.AssessmentID, 
        sfu.TargetDate, 
        sfu.FollowUpStatus, 
        sfu.ActionRequired, 
        sfu.ResolutionNotes 
    FROM SessionFollowUp sfu
    WHERE (@SearchFollowUpID IS NULL OR sfu.FollowUpID = @SearchFollowUpID)
      AND (@SearchAssessmentID IS NULL OR sfu.AssessmentID = @SearchAssessmentID)
      AND (@SearchStatus IS NULL OR sfu.FollowUpStatus = @SearchStatus);
END;
GO

-- 14. Notification CRUD
CREATE OR ALTER PROCEDURE dbo.spNotification_Insert
    @IDNumber           VARCHAR(7),
    @Content            VARCHAR(MAX),
    @NotificationStatus BIT = 0,
    @NewID              INT OUTPUT,
    @Message            VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO Notification (IDNumber, [Content], [Timestamp], NotificationStatus)
        VALUES (@IDNumber, @Content, GETDATE(), @NotificationStatus);

        SET @NewID = SCOPE_IDENTITY();
        SET @Message = 'Notification created successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spNotification_Update
    @NotificationID     INT,
    @Content            VARCHAR(MAX) = NULL,
    @NotificationStatus BIT,
    @Message            VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Notification WHERE NotificationID = @NotificationID)
        BEGIN
            SET @Message = 'Error: Notification record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Notification
        SET [Content]          = COALESCE(@Content, [Content]),
            NotificationStatus = @NotificationStatus
        WHERE NotificationID = @NotificationID;

        SET @Message = 'Notification updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spNotification_Delete
    @NotificationID INT,
    @Message        VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM Notification WHERE NotificationID = @NotificationID)
        BEGIN
            SET @Message = 'Error: Notification record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM Notification WHERE NotificationID = @NotificationID;
        SET @Message = 'Notification deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.spNotification_Select
    @SearchNotificationID INT = NULL,
    @SearchIDNumber       VARCHAR(7) = NULL,
    @SearchStatus         BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        n.NotificationID,
        n.IDNumber,
        n.[Content],
        n.[Timestamp],
        n.NotificationStatus
    FROM Notification n
    WHERE (@SearchNotificationID IS NULL OR n.NotificationID = @SearchNotificationID)
      AND (@SearchIDNumber IS NULL OR n.IDNumber = @SearchIDNumber)
      AND (@SearchStatus IS NULL OR n.NotificationStatus = @SearchStatus)
    ORDER BY n.[Timestamp] DESC, n.NotificationID DESC;
END;
GO

/* ==============================================================================
   PART 4: ANALYTICS & ACCURATE SCHOOL-YEAR REPORTING PROCEDURES
   ============================================================================== */

CREATE OR ALTER PROCEDURE dbo.sp_GenerateMonthlyReport_CompletedAppointments
    @SchoolYearStart INT,
    @ReportMonth     INT = NULL,
    @EmployeeID      VARCHAR(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportMonth IS NOT NULL AND (@ReportMonth < 1 OR @ReportMonth > 12)
        THROW 50001, 'Invalid ReportMonth. Month must be between 1 and 12.', 1;

    DECLARE @StartDate DATE, @EndDate DATE;
    IF @ReportMonth IS NOT NULL
    BEGIN
        DECLARE @TargetYear INT = CASE WHEN @ReportMonth >= 8 THEN @SchoolYearStart ELSE @SchoolYearStart + 1 END;
        SET @StartDate = DATEFROMPARTS(@TargetYear, @ReportMonth, 1);
        SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(@SchoolYearStart, 8, 1);
        SET @EndDate   = DATEFROMPARTS(@SchoolYearStart + 1, 8, 1);
    END;

    SELECT 
        YEAR(a.AppointmentDate) AS ReportYear,
        MONTH(a.AppointmentDate) AS ReportMonthNumber,
        DATENAME(MONTH, a.AppointmentDate) AS ReportMonthName,
        ca.DepartmentID, 
        c.EmployeeID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CounselorName,
        COUNT(DISTINCT a.AppointmentID) AS TotalCompletedAppointments
    FROM Appointment a
    JOIN Counselor c ON c.EmployeeID = a.EmployeeID
    OUTER APPLY 
    (
        SELECT TOP 1 ca_sub.DepartmentID 
        FROM CounselorAssignment ca_sub
        WHERE ca_sub.EmployeeID = c.EmployeeID 
          AND (ca_sub.SchoolYear IS NULL OR YEAR(ca_sub.SchoolYear) = @SchoolYearStart)
        ORDER BY ca_sub.AssignmentID DESC
    ) ca
    WHERE a.AppointmentDate >= @StartDate
      AND a.AppointmentDate < @EndDate
      AND a.AppointmentStatusID = 4 -- Completed
      AND (@EmployeeID IS NULL OR c.EmployeeID = @EmployeeID)
    GROUP BY YEAR(a.AppointmentDate), MONTH(a.AppointmentDate), DATENAME(MONTH, a.AppointmentDate), ca.DepartmentID, c.EmployeeID, c.FirstName, c.LastName
    ORDER BY ReportYear, ReportMonthNumber, ca.DepartmentID, CounselorName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GenerateMonthlyReport_ConcernFrequency
    @SchoolYearStart INT,
    @ReportMonth     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportMonth IS NOT NULL AND (@ReportMonth < 1 OR @ReportMonth > 12)
        THROW 50001, 'Invalid ReportMonth. Month must be between 1 and 12.', 1;

    DECLARE @StartDate DATE, @EndDate DATE;
    IF @ReportMonth IS NOT NULL
    BEGIN
        DECLARE @TargetYear INT = CASE WHEN @ReportMonth >= 8 THEN @SchoolYearStart ELSE @SchoolYearStart + 1 END;
        SET @StartDate = DATEFROMPARTS(@TargetYear, @ReportMonth, 1);
        SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(@SchoolYearStart, 8, 1);
        SET @EndDate   = DATEFROMPARTS(@SchoolYearStart + 1, 8, 1);
    END;

    SELECT 
        YEAR(a.AppointmentDate) AS ReportYear,
        MONTH(a.AppointmentDate) AS ReportMonthNumber,
        DATENAME(MONTH, a.AppointmentDate) AS ReportMonthName,
        ct.ConcernType, 
        COUNT(DISTINCT ac.AppointmentConcernID) AS FrequencyCount
    FROM AppointmentConcern ac
    JOIN CONST_ConcernType ct ON ct.ConcernTypeID = ac.ConcernTypeID
    JOIN Appointment a ON a.AppointmentID = ac.AppointmentID
    WHERE a.AppointmentDate >= @StartDate 
      AND a.AppointmentDate < @EndDate
    GROUP BY YEAR(a.AppointmentDate), MONTH(a.AppointmentDate), DATENAME(MONTH, a.AppointmentDate), ct.ConcernType
    ORDER BY ReportYear, ReportMonthNumber, FrequencyCount DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GenerateMonthlyReport_SessionModes
    @SchoolYearStart INT,
    @ReportMonth     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportMonth IS NOT NULL AND (@ReportMonth < 1 OR @ReportMonth > 12)
        THROW 50001, 'Invalid ReportMonth. Month must be between 1 and 12.', 1;

    DECLARE @StartDate DATE, @EndDate DATE;
    IF @ReportMonth IS NOT NULL
    BEGIN
        DECLARE @TargetYear INT = CASE WHEN @ReportMonth >= 8 THEN @SchoolYearStart ELSE @SchoolYearStart + 1 END;
        SET @StartDate = DATEFROMPARTS(@TargetYear, @ReportMonth, 1);
        SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(@SchoolYearStart, 8, 1);
        SET @EndDate   = DATEFROMPARTS(@SchoolYearStart + 1, 8, 1);
    END;

    SELECT 
        YEAR(a.AppointmentDate) AS ReportYear,
        MONTH(a.AppointmentDate) AS ReportMonthNumber,
        DATENAME(MONTH, a.AppointmentDate) AS ReportMonthName,
        t.AppointmentType AS ModeOfCounseling,
        COUNT(*) AS TotalCompletedSessions
    FROM Appointment a
    JOIN CONST_AppointmentType t ON t.AppointmentTypeID = a.AppointmentTypeID
    WHERE a.AppointmentDate >= @StartDate 
      AND a.AppointmentDate < @EndDate
      AND a.AppointmentStatusID = 4 -- Completed
    GROUP BY YEAR(a.AppointmentDate), MONTH(a.AppointmentDate), DATENAME(MONTH, a.AppointmentDate), t.AppointmentType
    ORDER BY ReportYear, ReportMonthNumber, TotalCompletedSessions DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GenerateMonthlyReport_ExternalReferrals
    @SchoolYearStart INT,
    @ReportMonth     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportMonth IS NOT NULL AND (@ReportMonth < 1 OR @ReportMonth > 12)
        THROW 50001, 'Invalid ReportMonth. Month must be between 1 and 12.', 1;

    DECLARE @StartDate DATE, @EndDate DATE;
    IF @ReportMonth IS NOT NULL
    BEGIN
        DECLARE @TargetYear INT = CASE WHEN @ReportMonth >= 8 THEN @SchoolYearStart ELSE @SchoolYearStart + 1 END;
        SET @StartDate = DATEFROMPARTS(@TargetYear, @ReportMonth, 1);
        SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(@SchoolYearStart, 8, 1);
        SET @EndDate   = DATEFROMPARTS(@SchoolYearStart + 1, 8, 1);
    END;

    SELECT 
        YEAR(a.AppointmentDate) AS ReportYear,
        MONTH(a.AppointmentDate) AS ReportMonthNumber,
        DATENAME(MONTH, a.AppointmentDate) AS ReportMonthName,
        a.AppointmentID, 
        a.AppointmentDate, 
        a.IDNumber, 
        a.ReferredBy,
        a.ReferralDate, 
        c.EmployeeID,
        CONCAT(c.FirstName, ' ', c.LastName) AS CounselorName
    FROM Appointment a
    JOIN Counselor c ON c.EmployeeID = a.EmployeeID
    WHERE a.AppointmentDate >= @StartDate 
      AND a.AppointmentDate < @EndDate
      AND a.AppointmentTypeID = 4 -- Referred
    ORDER BY ReportYear, ReportMonthNumber, a.AppointmentDate, a.AppointmentTime;
END;
GO

/* ==============================================================================
   PART 5: WORKFLOW & STATUS TRANSITION ACTIONS
   ============================================================================== */

-- 1. Counselor Confirms Appointment
CREATE OR ALTER PROCEDURE dbo.spConfirmAppointment
    @AppointmentID INT,
    @EmployeeID    VARCHAR(7),
    @ConfirmedDate DATE,
    @ConfirmedTime TIME(0),
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID AND EmployeeID = @EmployeeID)
        BEGIN
            SET @Message = 'Error: Appointment not found or not assigned to counselor.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID AND AppointmentStatusID = 2)
        BEGIN
            SET @Message = 'Error: Only appointments in Requested status can be confirmed.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS 
        (
            SELECT 1 
            FROM Appointment WITH (UPDLOCK, HOLDLOCK)
            WHERE EmployeeID = @EmployeeID 
              AND AppointmentDate = @ConfirmedDate 
              AND AppointmentTime = @ConfirmedTime 
              AND AppointmentStatusID = 3 -- Confirmed
              AND AppointmentID <> @AppointmentID
        )
        BEGIN
            SET @Message = 'Schedule conflict: Counselor already has a confirmed session at this date and time.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Appointment
        SET AppointmentDate     = @ConfirmedDate,
            AppointmentTime     = @ConfirmedTime,
            AppointmentStatusID = 3 -- Confirmed
        WHERE AppointmentID = @AppointmentID 
          AND EmployeeID = @EmployeeID;

        SET @Message = 'Appointment confirmed successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 2. Student Confirms Appointment
CREATE OR ALTER PROCEDURE dbo.spStudentConfirmAppointment
    @AppointmentID INT,
    @IDNumber      VARCHAR(7),
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CounselorID VARCHAR(7), @ApptDate DATE, @ApptTime TIME(0);
        SELECT 
            @CounselorID = EmployeeID,
            @ApptDate    = AppointmentDate,
            @ApptTime    = AppointmentTime
        FROM Appointment WITH (UPDLOCK, HOLDLOCK)
        WHERE AppointmentID = @AppointmentID 
          AND IDNumber = @IDNumber 
          AND AppointmentStatusID = 2; -- Must be Requested

        IF @CounselorID IS NULL
        BEGIN
            SET @Message = 'Error: Appointment not found or not in Requested status for this student.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS
        (
            SELECT 1 FROM Appointment WITH (UPDLOCK, HOLDLOCK)
            WHERE EmployeeID = @CounselorID
              AND AppointmentDate = @ApptDate
              AND AppointmentTime = @ApptTime
              AND AppointmentStatusID = 3
              AND AppointmentID <> @AppointmentID
        )
        BEGIN
            SET @Message = 'Schedule conflict: Counselor slot is no longer available.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Appointment
        SET AppointmentStatusID = 3 -- Confirmed
        WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment confirmed by student.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 3. Complete Appointment
CREATE OR ALTER PROCEDURE dbo.spCompleteAppointment
    @AppointmentID INT,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID AND AppointmentStatusID = 3)
        BEGIN
            SET @Message = 'Error: Only confirmed appointments can be marked as completed.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Appointment
        SET AppointmentStatusID = 4, -- Completed
            AttendanceStatusID  = 2  -- Attended
        WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment marked as completed.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 4. Counselor Proposes Reschedule
CREATE OR ALTER PROCEDURE dbo.spRescheduleAppointment
    @AppointmentID     INT,
    @NewStartDate      DATETIME,
    @NewEndDate        DATETIME,
    @RescheduleNote    VARCHAR(MAX),
    @Message           VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID AND AppointmentStatusID IN (2, 3))
        BEGIN
            SET @Message = 'Error: Only Requested or Confirmed appointments can be rescheduled.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @NewEndDate <= @NewStartDate
        BEGIN
            SET @Message = 'Error: End schedule date must be after start schedule date.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF NULLIF(LTRIM(RTRIM(@RescheduleNote)), '') IS NULL
        BEGIN
            SET @Message = 'Error: Reschedule note cannot be empty.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Concurrency-safe Upsert into AppointmentSchedule
        IF EXISTS (SELECT 1 FROM AppointmentSchedule WITH (UPDLOCK, HOLDLOCK) WHERE AppointmentID = @AppointmentID)
        BEGIN
            UPDATE AppointmentSchedule
            SET StartScheduleDate   = @NewStartDate,
                EndScheduleDate     = @NewEndDate,
                RescheduleNote      = @RescheduleNote,
                IsAcceptedByStudent = 0,
                UpdatedAt           = GETDATE()
            WHERE AppointmentID = @AppointmentID;
        END
        ELSE
        BEGIN
            INSERT INTO AppointmentSchedule (AppointmentID, StartScheduleDate, EndScheduleDate, RescheduleNote, IsAcceptedByStudent)
            VALUES (@AppointmentID, @NewStartDate, @NewEndDate, @RescheduleNote, 0);
        END

        UPDATE Appointment
        SET AppointmentStatusID = 5, -- Rescheduled
            RescheduleNote      = @RescheduleNote
        WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Reschedule proposal saved. Awaiting student acceptance.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 5. Student Accepts Reschedule
CREATE OR ALTER PROCEDURE dbo.spStudentAcceptReschedule
    @AppointmentID INT,
    @IDNumber      VARCHAR(7),
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewStart DATETIME, @AssignedCounselor VARCHAR(7);
        SELECT 
            @NewStart          = sch.StartScheduleDate,
            @AssignedCounselor = a.EmployeeID
        FROM AppointmentSchedule sch WITH (UPDLOCK, HOLDLOCK)
        JOIN Appointment a WITH (UPDLOCK, HOLDLOCK) ON sch.AppointmentID = a.AppointmentID
        WHERE a.AppointmentID = @AppointmentID 
          AND a.IDNumber = @IDNumber 
          AND a.AppointmentStatusID = 5 -- Rescheduled
          AND sch.IsAcceptedByStudent = 0;

        IF @NewStart IS NULL
        BEGIN
            SET @Message = 'Error: No pending reschedule proposal found for this student appointment.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Concurrency guard: Ensure counselor slot was not taken while proposal was pending
        IF EXISTS 
        (
            SELECT 1 FROM Appointment WITH (UPDLOCK, HOLDLOCK)
            WHERE EmployeeID = @AssignedCounselor
              AND AppointmentDate = CAST(@NewStart AS DATE)
              AND AppointmentTime = CAST(@NewStart AS TIME(0))
              AND AppointmentStatusID = 3
              AND AppointmentID <> @AppointmentID
        )
        BEGIN
            SET @Message = 'Schedule conflict: Counselor slot is no longer available. A new slot must be arranged.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE AppointmentSchedule
        SET IsAcceptedByStudent = 1,
            UpdatedAt           = GETDATE()
        WHERE AppointmentID = @AppointmentID;

        UPDATE Appointment
        SET AppointmentDate     = CAST(@NewStart AS DATE),
            AppointmentTime     = CAST(@NewStart AS TIME(0)),
            AppointmentStatusID = 3 -- Confirmed
        WHERE AppointmentID = @AppointmentID 
          AND IDNumber = @IDNumber;

        SET @Message = 'Reschedule accepted and appointment confirmed successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 6. View Counselor Reschedule History
CREATE OR ALTER PROCEDURE dbo.spGetCounselorRescheduleHistory
    @EmployeeID VARCHAR(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        a.AppointmentID,
        a.IDNumber AS StudentID,
        a.EmployeeID,
        sch.StartScheduleDate,
        sch.EndScheduleDate,
        sch.RescheduleNote,
        sch.IsAcceptedByStudent,
        sch.UpdatedAt
    FROM AppointmentSchedule sch
    JOIN Appointment a ON sch.AppointmentID = a.AppointmentID
    WHERE (@EmployeeID IS NULL OR a.EmployeeID = @EmployeeID)
    ORDER BY sch.UpdatedAt DESC;
END;
GO

-- 7. Mark Attendance as No-Show
CREATE OR ALTER PROCEDURE dbo.spSetAppointmentNoShow
    @AppointmentID INT,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID AND AppointmentStatusID = 3)
        BEGIN
            SET @Message = 'Error: Only confirmed appointments can be marked as No-Show.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Appointment
        SET AttendanceStatusID = 3 -- No-Show
        WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment attendance marked as No-Show.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 8. Masterlist Tabular Query
CREATE OR ALTER PROCEDURE dbo.sp_GetAppointmentMasterlist
    @SearchStudentID       VARCHAR(7) = NULL,
    @SearchGradeOrYear     INT = NULL,
    @SearchProgram         VARCHAR(50) = NULL,
    @SearchModeID          INT = NULL,
    @SearchStatusID        INT = NULL,
    @SearchAttendanceID    INT = NULL,
    @SearchStartDate       DATE = NULL,
    @SearchEndDate         DATE = NULL,
    @SearchReferredBy      VARCHAR(100) = NULL,
    @SearchSpecialistRole  VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        m.AppointmentID,
        m.StudentID,
        m.GradeOrYearLevel,
        m.ProgramOrCourse,
        m.ModeOfCounseling,
        m.ReferredBy,
        m.ReferredTo,
        m.ReferralDate,
        m.DateTimeOfCounseling,
        m.SessionType,
        m.AppointmentNotes,
        m.AppointmentStatus,
        m.AttendanceStatus
    FROM dbo.vw_AppointmentMasterlist m
    WHERE (@SearchStudentID IS NULL OR m.StudentID = @SearchStudentID)
      AND (@SearchGradeOrYear IS NULL OR m.GradeOrYearLevel = @SearchGradeOrYear)
      AND (@SearchProgram IS NULL OR m.ProgramOrCourse LIKE '%' + @SearchProgram + '%')
      AND (@SearchModeID IS NULL OR m.ModeOfCounseling = (SELECT AppointmentType FROM CONST_AppointmentType WHERE AppointmentTypeID = @SearchModeID))
      AND (@SearchStatusID IS NULL OR m.AppointmentStatus = (SELECT AppointmentStatus FROM CONST_AppointmentStatus WHERE AppointmentStatusID = @SearchStatusID))
      AND (@SearchAttendanceID IS NULL OR m.AttendanceStatus = (SELECT AttendanceStatus FROM CONST_AttendanceStatus WHERE AttendanceStatusID = @SearchAttendanceID))
      AND (@SearchStartDate IS NULL OR CAST(m.DateTimeOfCounseling AS DATE) >= @SearchStartDate)
      AND (@SearchEndDate IS NULL OR CAST(m.DateTimeOfCounseling AS DATE) <= @SearchEndDate)
      AND (@SearchReferredBy IS NULL OR m.ReferredBy LIKE '%' + @SearchReferredBy + '%')
      AND (@SearchSpecialistRole IS NULL OR m.ReferredTo LIKE '%' + @SearchSpecialistRole + '%')
    ORDER BY m.AppointmentID DESC;
END;
GO

/* ==============================================================================
   PART 6: SEED INITIAL MOCK DATA (Testing & Staging Baseline)
   ============================================================================== */

INSERT INTO Counselor (EmployeeID, FirstName, LastName, MiddleName)
VALUES
('EMP0001', 'Maria', 'Santos', 'Reyes'),
('EMP0002', 'John', 'Dela Cruz', 'Garcia'),
('EMP0003', 'Angela', 'Mendoza', 'Ramos'),
('EMP0004', 'Mark', 'Villanueva', 'Cruz');
GO

INSERT INTO CounselorAssignment (EmployeeID, DepartmentID, ProgramID, YearOrGradeLevel, SchoolYear)
VALUES
('EMP0001', 'SACE', 'BSIT', 4, '2026-08-01'),
('EMP0002', 'SECAP', NULL, NULL, '2026-08-01'),
('EMP0003', 'SHAS', NULL, NULL, '2026-08-01'),
('EMP0004', 'SABH', NULL, NULL, '2026-08-01');
GO

INSERT INTO CounselorSchedule (EmployeeID, SchoolYear, ScheduleDay, StartTime, EndTime, IsAvailable)
VALUES
('EMP0001', '2026-08-01', '2026-09-07', '08:00', '12:00', 1),
('EMP0001', '2026-08-01', '2026-09-09', '08:00', '12:00', 1),
('EMP0002', '2026-08-01', '2026-09-07', '08:00', '12:00', 1),
('EMP0002', '2026-08-01', '2026-09-09', '08:00', '12:00', 1);
GO

SET IDENTITY_INSERT Appointment ON;
INSERT INTO Appointment 
(
    AppointmentID, IDNumber, GradeOrYearLevel, ProgramOrCourse, EmployeeID,
    AppointmentDate, AppointmentTime, AppointmentTypeID, AppointmentStatusID, AttendanceStatusID,
    RescheduleNote, ConcernDescription, OtherConcernDetail, ReferredBy, ReferralDate, InitialAppointmentID, ParentAppointmentID
)
VALUES
(
    1001, '2023001', 4, 'BSIT', 'EMP0001',
    '2026-09-10', '08:30', 2, 4, 2,
    NULL, 'Academic performance and study load stress', NULL, NULL, NULL, NULL, NULL
);
SET IDENTITY_INSERT Appointment OFF;
GO

INSERT INTO AppointmentConcern (AppointmentID, ConcernTypeID)
VALUES (1001, 1);
GO

SET IDENTITY_INSERT CounselingSession ON;
INSERT INTO CounselingSession 
(
    SessionID, AppointmentID, IDNumber, GradeOrYearLevel, EmployeeID, ProgramOrCourse, 
    AppointmentStatusID, SessionDate, SessionTypeID, GeneralNotes, SessionStartTime, SessionEndTime
)
VALUES 
(
    5001, 1001, '2023001', 4, 'EMP0001', 'BSIT', 4,
    '2026-09-10 08:30:00', 1, 'Discussed study habits, time management, and academic goals.', '2026-09-10 08:30:00', '2026-09-10 09:15:00'
);
SET IDENTITY_INSERT CounselingSession OFF;
GO

SET IDENTITY_INSERT StudentAssessment ON;
INSERT INTO StudentAssessment (AssessmentID, SessionID, ProgressNotes, IsFollowUpNeeded, IsForMonitoring, SpecialistReferralID)
VALUES (6001, 5001, 'Student showed willingness to improve academic routine.', 1, 0, NULL);
SET IDENTITY_INSERT StudentAssessment OFF;
GO

SET IDENTITY_INSERT Notification ON;
INSERT INTO Notification (NotificationID, IDNumber, [Content], [Timestamp], NotificationStatus)
VALUES (7001, '2023001', 'Your counseling session has been completed.', '2026-09-10 09:20:00', 1);
SET IDENTITY_INSERT Notification OFF;
GO

USE db_ad0f7f_clstage;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Select
    @SearchAppointmentID     INT = NULL,
    @SearchIDNumber          VARCHAR(7) = NULL,
    @SearchGradeOrYear       INT = NULL,
    @SearchProgram           VARCHAR(50) = NULL,
    @SearchEmployeeID        VARCHAR(7) = NULL,
    @SearchStartDate         DATE = NULL,
    @SearchEndDate           DATE = NULL,
    @SearchAppointmentTime   TIME(0) = NULL,
    @SearchTypeID            INT = NULL,
    @SearchAppointmentTypeID INT = NULL,
    @SearchConcernTypeID     INT = NULL,
    @SearchStatusID          INT = NULL,
    @SearchAttendanceID      INT = NULL,
    @SearchReferredBy        VARCHAR(100) = NULL,
    @SearchReferralStart     DATE = NULL,
    @SearchReferralEnd       DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActualTypeID INT = COALESCE(@SearchAppointmentTypeID, @SearchTypeID);

    SELECT DISTINCT
        a.AppointmentID,
        a.IDNumber,
        a.GradeOrYearLevel,
        a.ProgramOrCourse,
        a.EmployeeID,
        a.AppointmentDate,
        a.AppointmentTime,
        a.AppointmentTypeID,
        a.AppointmentStatusID,
        a.AttendanceStatusID,
        a.RescheduleNote,
        a.ConcernDescription,
        a.OtherConcernDetail,
        a.ReferredBy,
        a.ReferralDate,
        a.InitialAppointmentID,
        a.ParentAppointmentID
    FROM Appointment a
    LEFT JOIN AppointmentConcern ac ON a.AppointmentID = ac.AppointmentID
    WHERE (@SearchAppointmentID IS NULL OR a.AppointmentID = @SearchAppointmentID)
      AND (@SearchIDNumber IS NULL OR a.IDNumber = @SearchIDNumber)
      AND (@SearchGradeOrYear IS NULL OR a.GradeOrYearLevel = @SearchGradeOrYear)
      AND (@SearchProgram IS NULL OR a.ProgramOrCourse LIKE '%' + @SearchProgram + '%')
      AND (@SearchEmployeeID IS NULL OR a.EmployeeID = @SearchEmployeeID)
      AND (@SearchStartDate IS NULL OR a.AppointmentDate >= @SearchStartDate)
      AND (@SearchEndDate IS NULL OR a.AppointmentDate <= @SearchEndDate)
      AND (@SearchAppointmentTime IS NULL OR a.AppointmentTime = @SearchAppointmentTime)
      AND (@ActualTypeID IS NULL OR a.AppointmentTypeID = @ActualTypeID)
      AND (@SearchConcernTypeID IS NULL OR ac.ConcernTypeID = @SearchConcernTypeID)
      AND (@SearchStatusID IS NULL OR a.AppointmentStatusID = @SearchStatusID)
      AND (@SearchAttendanceID IS NULL OR a.AttendanceStatusID = @SearchAttendanceID)
      AND (@SearchReferredBy IS NULL OR a.ReferredBy LIKE '%' + @SearchReferredBy + '%')
      AND (@SearchReferralStart IS NULL OR a.ReferralDate >= @SearchReferralStart)
      AND (@SearchReferralEnd IS NULL OR a.ReferralDate <= @SearchReferralEnd)
    ORDER BY a.AppointmentDate DESC;
END;
GO


USE db_ad0f7f_clstage;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Delete
    @AppointmentID INT,
    @IDNumber      VARCHAR(7) = NULL,
    @EmployeeID    VARCHAR(7) = NULL,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Error: Appointment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM CounselingSession WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Cannot delete: Appointment has linked counseling sessions.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DELETE FROM AppointmentSchedule WHERE AppointmentID = @AppointmentID;
        DELETE FROM AppointmentConcern WHERE AppointmentID = @AppointmentID;
        DELETE FROM Appointment WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

USE db_ad0f7f_clstage;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Update
    @AppointmentID        INT,
    @IDNumber             VARCHAR(7) = NULL,
    @GradeOrYearLevel     INT = NULL,
    @ProgramOrCourse      VARCHAR(50) = NULL,
    @EmployeeID           VARCHAR(7) = NULL,
    @AppointmentDate      DATE = NULL,
    @AppointmentTime      TIME(0) = NULL,
    @AppointmentTypeID    INT = NULL,
    @AppointmentStatusID  INT = NULL,
    @AttendanceStatusID   INT = NULL,
    @RescheduleNote       VARCHAR(MAX) = NULL,
    @ConcernDescription   VARCHAR(MAX) = NULL,
    @OtherConcernDetail   VARCHAR(255) = NULL,
    @ReferredBy           VARCHAR(100) = NULL,
    @ReferralDate         DATE = NULL,
    @InitialAppointmentID INT = NULL,
    @ParentAppointmentID  INT = NULL,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Error: Appointment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Appointment
        SET GradeOrYearLevel    = COALESCE(@GradeOrYearLevel, GradeOrYearLevel),
            ProgramOrCourse     = COALESCE(@ProgramOrCourse, ProgramOrCourse),
            AppointmentDate     = COALESCE(@AppointmentDate, AppointmentDate),
            AppointmentTime     = COALESCE(@AppointmentTime, AppointmentTime),
            AppointmentTypeID   = COALESCE(@AppointmentTypeID, AppointmentTypeID),
            AppointmentStatusID = COALESCE(@AppointmentStatusID, AppointmentStatusID),
            AttendanceStatusID  = COALESCE(@AttendanceStatusID, AttendanceStatusID),
            RescheduleNote      = COALESCE(@RescheduleNote, RescheduleNote),
            ConcernDescription  = COALESCE(@ConcernDescription, ConcernDescription),
            OtherConcernDetail  = COALESCE(@OtherConcernDetail, OtherConcernDetail)
        WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


USE db_ad0f7f_clstage;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Update
    @AppointmentID        INT,
    @AppointmentStatusID  INT,
    @AttendanceStatusID   INT,
    @RescheduleNote       VARCHAR(MAX) = NULL,
    @ConcernDescription   VARCHAR(MAX) = NULL,
    @OtherConcernDetail   VARCHAR(255) = NULL,
    @Message              VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Error: Appointment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Appointment
        SET AppointmentStatusID = @AppointmentStatusID, 
            AttendanceStatusID  = @AttendanceStatusID,
            RescheduleNote      = @RescheduleNote, 
            ConcernDescription  = @ConcernDescription, 
            OtherConcernDetail  = @OtherConcernDetail
        WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment updated successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


USE db_ad0f7f_clstage;
GO

CREATE OR ALTER PROCEDURE dbo.spAppointment_Delete
    @AppointmentID INT,
    @IDNumber      VARCHAR(7) = NULL,
    @EmployeeID    VARCHAR(7) = NULL,
    @Message       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Check if record exists
        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Error: Appointment record does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Clinical Safeguard: Protect session history
        IF EXISTS (SELECT 1 FROM CounselingSession WHERE AppointmentID = @AppointmentID)
        BEGIN
            SET @Message = 'Cannot delete: Appointment has linked counseling sessions.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Clean up dependent child tables before main record deletion
        DELETE FROM AppointmentSchedule WHERE AppointmentID = @AppointmentID;
        DELETE FROM AppointmentConcern WHERE AppointmentID = @AppointmentID;
        DELETE FROM Appointment WHERE AppointmentID = @AppointmentID;

        SET @Message = 'Appointment deleted successfully.';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


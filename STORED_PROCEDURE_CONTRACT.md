# CounselLink.API — Stored Procedure Contract

This is the exact set of stored procedures the API calls and the parameter names it sends via Dapper. Dapper maps by **name**, so each `@Param` below must exist (spelled identically) in your procedure signature. Where your database differs, adjust the `parameters.Add("@...")` keys in the matching repository.

Legend:
- **IN** = input parameter the API sends
- **OUT** = output parameter the API reads back (`@Message VARCHAR(255)`, `@NewID INT`)
- Writes (INSERT/UPDATE/DELETE) return `{ newId, message }` from the two OUT params.
- Reads return the raw result set (`IEnumerable<dynamic>`), so column names are *not* constrained by the API.

---

## 1. Constants — `ConstantRepository`

Procedure name is built as `dbo.spConst{Type}_{Action}`.
Supported `{Type}`: `AppointmentType`, `ConcernType`, `AttendanceStatus`, `AppointmentStatus`, `SessionType`, `SpecialistReferral`.

| Endpoint | Procedure | IN params | OUT params |
|---|---|---|---|
| GET `/api/constants/{type}` | `spConst{Type}_Select` | (none) | — |
| POST `/api/constants/{type}` | `spConst{Type}_Insert` | `@Name`, `@Code`, `@Description`, `@IsActive` | `@Message`, `@NewID` |
| PUT `/api/constants/{type}` | `spConst{Type}_Update` | `@Id`, `@Name`, `@Code`, `@Description`, `@IsActive` | `@Message`, `@NewID` |
| DELETE `/api/constants/{type}/{id}` | `spConst{Type}_Delete` | `@Id` | `@Message`, `@NewID` |

---

## 2. Counselors — `CounselorRepository`

| Endpoint | Procedure | IN params | OUT params |
|---|---|---|---|
| GET `/api/counselors` | `spCounselor_Select` | (none) | — |
| POST `/api/counselors` | `spCounselor_Insert` | `@EmployeeID`, `@FirstName`, `@LastName`, `@Email`, `@ContactNumber`, `@Specialization`, `@IsActive` | `@Message`, `@NewID` |
| PUT `/api/counselors` | `spCounselor_Update` | `@EmployeeID`, `@FirstName`, `@LastName`, `@Email`, `@ContactNumber`, `@Specialization`, `@IsActive` | `@Message`, `@NewID` |
| DELETE `/api/counselors/{employeeId}` | `spCounselor_Delete` | `@EmployeeID` | `@Message`, `@NewID` |

## 2b. Counselor Assignments — `CounselorAssignmentRepository`

| Endpoint | Procedure | IN params | OUT params |
|---|---|---|---|
| GET `/api/counselor-assignments` | `spCounselorAssignment_Select` | (none) | — |
| POST `/api/counselor-assignments` | `spCounselorAssignment_Insert` | `@EmployeeID`, `@Department`, `@Program`, `@YearLevel`, `@SchoolYearStart` | `@Message`, `@NewID` |

---

## 3. Appointments — `AppointmentRepository`

| Endpoint | Procedure | IN params | OUT params |
|---|---|---|---|
| GET `/api/appointments` | `spAppointment_Select` | `@SearchIDNumber`, `@SearchEmployeeID`, `@SearchStatusID`, `@SearchAppointmentTypeID`, `@SearchConcernTypeID`, `@SearchStartDate`, `@SearchEndDate` | — |
| POST `/api/appointments` | `spAppointment_Insert` | `@IDNumber`, `@EmployeeID`, `@AppointmentTypeID`, `@ConcernTypeID`, `@AppointmentStatusID`, `@StartDate`, `@EndDate`, `@Mode`, `@Location`, `@Notes` | `@Message`, `@NewID` |
| PUT `/api/appointments/{id}` | `spAppointment_Update` | `@AppointmentID`, `@IDNumber`, `@EmployeeID`, `@AppointmentTypeID`, `@ConcernTypeID`, `@AppointmentStatusID`, `@StartDate`, `@EndDate`, `@Mode`, `@Location`, `@Notes` | `@Message`, `@NewID` |
| DELETE `/api/appointments/{id}` | `spAppointment_Delete` | `@AppointmentID` | `@Message`, `@NewID` |
| PUT `/api/appointments/{id}/confirm` | `spConfirmAppointment` | `@AppointmentID`, `@EmployeeID`, `@ConfirmedDate`, `@ConfirmedTime` | `@Message`, `@NewID` |
| PUT `/api/appointments/{id}/student-confirm` | `spStudentConfirmAppointment` | `@AppointmentID`, `@IDNumber` | `@Message`, `@NewID` |
| PUT `/api/appointments/{id}/complete` | `spCompleteAppointment` | `@AppointmentID` | `@Message`, `@NewID` |
| POST `/api/appointments/{id}/reschedule` | `spRescheduleAppointment` | `@AppointmentID`, `@NewStartDate`, `@NewEndDate`, `@RescheduleNote` | `@Message`, `@NewID` |
| PUT `/api/appointments/{id}/accept-reschedule` | `spStudentAcceptReschedule` | `@AppointmentID`, `@IDNumber` | `@Message`, `@NewID` |
| PUT `/api/appointments/{id}/no-show` | `spSetAppointmentNoShow` | `@AppointmentID` | `@Message`, `@NewID` |
| GET `/api/appointments/reschedule-history` | `spGetCounselorRescheduleHistory` | `@SearchEmployeeID` | — |

---

## 4. Clinical — `ClinicalRepository`

| Endpoint | Procedure | IN params | OUT params |
|---|---|---|---|
| POST `/api/clinical/sessions` | `spCounselingSession_Insert` | `@AppointmentID`, `@EmployeeID`, `@IDNumber`, `@SessionTypeID`, `@SessionDate`, `@Mode`, `@Notes`, `@AttendanceStatusID` | `@Message`, `@NewID` |
| GET `/api/clinical/sessions` | `spCounselingSession_Select` | `@SearchIDNumber`, `@SearchEmployeeID`, `@SearchAppointmentID` | — |
| POST `/api/clinical/assessments` | `spStudentAssessment_Insert` | `@IDNumber`, `@EmployeeID`, `@SessionID`, `@AssessmentType`, `@RiskLevel`, `@Findings`, `@Recommendations`, `@AssessmentDate` | `@Message`, `@NewID` |
| GET `/api/clinical/assessments` | `spStudentAssessment_Select` | `@SearchIDNumber`, `@SearchEmployeeID`, `@SearchSessionID` | — |
| POST `/api/clinical/follow-ups` | `spSessionFollowUp_Insert` | `@SessionID`, `@EmployeeID`, `@FollowUpDate`, `@Notes`, `@IsCompleted` | `@Message`, `@NewID` |
| GET `/api/clinical/follow-ups` | `spSessionFollowUp_Select` | `@SearchSessionID`, `@SearchEmployeeID` | — |

---

## 5. Reports — `ReportRepository`

| Endpoint | Procedure | IN params | OUT params |
|---|---|---|---|
| GET `/api/reports/monthly/completed` | `sp_GenerateMonthlyReport_CompletedAppointments` | `@SchoolYearStart`, `@ReportMonth` | — |
| GET `/api/reports/monthly/concerns` | `sp_GenerateMonthlyReport_ConcernFrequency` | `@SchoolYearStart`, `@ReportMonth` | — |
| GET `/api/reports/monthly/modes` | `sp_GenerateMonthlyReport_SessionModes` | `@SchoolYearStart`, `@ReportMonth` | — |
| GET `/api/reports/monthly/referrals` | `sp_GenerateMonthlyReport_ExternalReferrals` | `@SchoolYearStart`, `@ReportMonth` | — |
| GET `/api/reports/masterlist` | `sp_GetAppointmentMasterlist` | (none) | — |

---

## 6. Notifications — `NotificationRepository`

| Endpoint | Procedure | IN params | OUT params |
|---|---|---|---|
| GET `/api/notifications` | `spNotification_Select` | `@SearchRecipientID` | — |
| POST `/api/notifications` | `spNotification_Insert` | `@RecipientID`, `@Title`, `@Body`, `@Type`, `@IsRead` | `@Message`, `@NewID` |

---

## Diff checklist

Go procedure by procedure against your database and tick each:

### Constants (per each of the 6 types)
- [ ] `spConst{Type}_Select` exists
- [ ] `spConst{Type}_Insert` accepts `@Name`, `@Code`, `@Description`, `@IsActive` + OUT `@Message`, `@NewID`
- [ ] `spConst{Type}_Update` accepts `@Id`, `@Name`, `@Code`, `@Description`, `@IsActive` + OUT
- [ ] `spConst{Type}_Delete` accepts `@Id` + OUT

### Counselors
- [ ] `spCounselor_Select`
- [ ] `spCounselor_Insert` params match
- [ ] `spCounselor_Update` params match
- [ ] `spCounselor_Delete` takes `@EmployeeID` + OUT
- [ ] `spCounselorAssignment_Select`
- [ ] `spCounselorAssignment_Insert` params match

### Appointments
- [ ] `spAppointment_Select` search params match
- [ ] `spAppointment_Insert` params match
- [ ] `spAppointment_Update` params match (incl. `@AppointmentID`)
- [ ] `spAppointment_Delete` takes `@AppointmentID` + OUT
- [ ] `spConfirmAppointment` takes `@AppointmentID`, `@EmployeeID`, `@ConfirmedDate`, `@ConfirmedTime` + OUT
- [ ] `spStudentConfirmAppointment` takes `@AppointmentID`, `@IDNumber` + OUT
- [ ] `spCompleteAppointment` takes `@AppointmentID` + OUT
- [ ] `spRescheduleAppointment` takes `@AppointmentID`, `@NewStartDate`, `@NewEndDate`, `@RescheduleNote` + OUT
- [ ] `spStudentAcceptReschedule` takes `@AppointmentID`, `@IDNumber` + OUT
- [ ] `spSetAppointmentNoShow` takes `@AppointmentID` + OUT
- [ ] `spGetCounselorRescheduleHistory` takes `@SearchEmployeeID`

### Clinical
- [ ] `spCounselingSession_Insert` params match
- [ ] `spCounselingSession_Select` search params match
- [ ] `spStudentAssessment_Insert` params match
- [ ] `spStudentAssessment_Select` search params match
- [ ] `spSessionFollowUp_Insert` params match
- [ ] `spSessionFollowUp_Select` search params match

### Reports
- [ ] `sp_GenerateMonthlyReport_CompletedAppointments` takes `@SchoolYearStart`, `@ReportMonth`
- [ ] `sp_GenerateMonthlyReport_ConcernFrequency` takes `@SchoolYearStart`, `@ReportMonth`
- [ ] `sp_GenerateMonthlyReport_SessionModes` takes `@SchoolYearStart`, `@ReportMonth`
- [ ] `sp_GenerateMonthlyReport_ExternalReferrals` takes `@SchoolYearStart`, `@ReportMonth`
- [ ] `sp_GetAppointmentMasterlist`

### Notifications
- [ ] `spNotification_Select` takes `@SearchRecipientID`
- [ ] `spNotification_Insert` params match + OUT

---

## Notes on likely mismatches

- **`@SearchRecipientID`** (notifications Select) is an assumption — the spec didn't specify a filter param. If your `spNotification_Select` takes no parameters or a different name, update `NotificationRepository.SelectAsync`.
- **`@SearchEmployeeID`** on `spGetCounselorRescheduleHistory` is likewise assumed. Adjust if your procedure uses a different name or none.
- **Constant columns** (`@Name`, `@Code`, `@Description`, `@IsActive`) are a generic shape. If individual constant tables use different column names (e.g. `@TypeName`), each `spConst{Type}_*` may need per-type parameters rather than the shared set.
- If any write procedure does **not** declare `@Message`/`@NewID` OUT params, calling it will throw. Either add the OUT params to the procedure or remove `parameters.AddStandardOutputs()` for that call.

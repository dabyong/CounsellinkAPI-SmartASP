using System.Data;
using CounselLink.API.Data;
using CounselLink.API.DTOs;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace CounselLink.API.Controllers;

/// <summary>
/// Saves counselor availability changes for the Update Schedule UI.
/// One transaction is used for all selected slots on a day.
/// </summary>
[ApiController]
[Route("api/counselor-schedules/availability")]
public sealed class ScheduleBlockingController : ControllerBase
{
    private readonly IDbConnectionFactory _factory;

    public ScheduleBlockingController(IDbConnectionFactory factory) => _factory = factory;

    // UI slots: Monday-Thursday ends at 17:30; Friday ends at 16:30.
    // The last Friday slot is 16:00-16:30 rather than 16:00-17:00.
    private static readonly (int Start, int End)[] OfficeSlots =
    [
        (450, 510), (510, 570), (570, 630), (630, 690), (690, 750),
        (780, 840), (840, 900), (900, 960), (960, 1020), (1020, 1050),
        (960, 990)
    ];

    [HttpPut]
    public async Task<IActionResult> UpdateDay([FromBody] UpdateBlockedSlotsDto dto)
    {
        if (dto is null || string.IsNullOrWhiteSpace(dto.EmployeeId) ||
            dto.EmployeeId.Length > 7 || dto.Date == default)
        {
            return BadRequest(new { error = "employeeId and date are required." });
        }

        var date = dto.Date.Date;
        var philippineNow = DateTime.UtcNow.AddHours(8);

        if (date < philippineNow.Date)
            return BadRequest(new { error = "Cannot modify past dates." });

        if (dto.Slots is null || dto.Slots.Count == 0)
            return BadRequest(new { error = "Provide one or more slots." });

        if (dto.Slots.Count > 20)
            return BadRequest(new { error = "Too many slots for one day." });

        if (date.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
            return BadRequest(new { error = "No office slots on weekends." });

        var friday = date.DayOfWeek == DayOfWeek.Friday;
        var seen = new HashSet<(int Start, int End)>();

        foreach (var slot in dto.Slots)
        {
            var start = (int)slot.StartTime.TotalMinutes;
            var end = (int)slot.EndTime.TotalMinutes;

            if (start < 0 || end > 24 * 60 || end <= start ||
                !OfficeSlots.Contains((start, end)) ||
                (friday && end > 990) ||
                (!friday && start == 960 && end == 990) ||
                !seen.Add((start, end)))
            {
                return BadRequest(new { error = "Invalid, duplicate, or out-of-hours UI slot." });
            }

            // A past slot would still show Blocked in the availability GET
            // even if its block were removed. Avoid a misleading success.
            if (date == philippineNow.Date && slot.StartTime <= philippineNow.TimeOfDay)
            {
                return BadRequest(new { error = "Cannot modify a slot that has already started." });
            }
        }

        // School-year starts on August 1, matching the existing schedule convention.
        // Change this boundary if your school uses a different school-year start.
        var schoolYearStart = date.Month >= 8
            ? new DateTime(date.Year, 8, 1)
            : new DateTime(date.Year - 1, 8, 1);

        try
        {
            using var db = _factory.CreateConnection();
            db.Open();
            using var tx = db.BeginTransaction(IsolationLevel.Serializable);

            try
            {
                // Same lock resource used by dbo.spCL_ValidateBooking.
                var lockResult = await db.ExecuteScalarAsync<int>(
                    "DECLARE @r INT; EXEC @r = sys.sp_getapplock " +
                    "@Resource = @key, @LockMode = 'Exclusive', " +
                    "@LockOwner = 'Transaction', @LockTimeout = 10000; SELECT @r;",
                    new { key = $"CLSlot:{dto.EmployeeId}:{date:yyyy-MM-dd}" }, tx);

                if (lockResult < 0)
                    throw new InvalidOperationException("Unable to lock selected day.");

                var counselorExists = await db.ExecuteScalarAsync<int>(
                    "SELECT COUNT(1) FROM dbo.Counselor WHERE EmployeeID = @id",
                    new { id = dto.EmployeeId }, tx);

                if (counselorExists == 0)
                    return ConflictAfterRollback(tx, "Counselor does not exist.");

                foreach (var slot in dto.Slots)
                {
                    var args = new
                    {
                        id = dto.EmployeeId,
                        date,
                        start = slot.StartTime,
                        end = slot.EndTime,
                        reason = slot.Reason,
                        schoolYear = schoolYearStart
                    };

                    if (!slot.IsAvailable)
                    {
                        // A temporary block must lie within a scheduled working period.
                        var covered = await db.ExecuteScalarAsync<int>(@"
                            SELECT COUNT(1)
                            FROM dbo.CounselorSchedule
                            WHERE EmployeeID = @id
                              AND ScheduleDay = @date
                              AND IsAvailable = 1
                              AND StartTime <= @start
                              AND EndTime >= @end;", args, tx);

                        if (covered == 0)
                        {
                            return ConflictAfterRollback(tx,
                                "Slot is outside the counselor's available schedule.");
                        }

                        var booked = await db.ExecuteScalarAsync<int>(@"
                            SELECT CASE WHEN EXISTS (
                                SELECT 1 FROM dbo.Appointment a
                                WHERE a.EmployeeID = @id
                                  AND a.AppointmentDate = @date
                                  -- Only actively confirmed appointments occupy normal slots.
                                  -- No-Show (attendance 3) is historical and does not book a slot.
                                  AND a.AppointmentStatusID = 2
                                  AND a.AttendanceStatusID <> 3
                                  AND COALESCE(a.StartTime, a.AppointmentTime) < @end
                                  AND COALESCE(
                                      a.EndTime,
                                      CONVERT(TIME(0), DATEADD(MINUTE,
                                          CASE WHEN a.AppointmentTime >= CONVERT(TIME, '17:00')
                                               THEN 30 ELSE 60 END,
                                          CONVERT(DATETIME2(0), a.AppointmentTime)))) > @start
                            ) OR EXISTS (
                                SELECT 1
                                FROM dbo.AppointmentSchedule ps
                                JOIN dbo.Appointment a
                                  ON a.AppointmentID = ps.AppointmentID
                                WHERE a.EmployeeID = @id
                                  AND a.AppointmentStatusID = 4
                                  AND ps.IsAcceptedByStudent = 0
                                  AND ps.StartScheduleDate < DATEADD(SECOND,
                                      DATEDIFF(SECOND, CONVERT(TIME, '00:00'), @end),
                                      CONVERT(DATETIME2(0), @date))
                                  AND ps.EndScheduleDate > DATEADD(SECOND,
                                      DATEDIFF(SECOND, CONVERT(TIME, '00:00'), @start),
                                      CONVERT(DATETIME2(0), @date))
                            ) THEN 1 ELSE 0 END;", args, tx);

                        if (booked == 1)
                        {
                            return ConflictAfterRollback(tx,
                                "Cannot block a booked slot. Reschedule the existing appointment first.");
                        }

                        // Idempotent: update an existing exact block or insert one.
                        await db.ExecuteAsync(@"
                            IF NOT EXISTS (
                                SELECT 1 FROM dbo.CounselorBlockedSlot
                                WHERE EmployeeID = @id AND SlotDate = @date
                                  AND StartTime = @start AND EndTime = @end
                            )
                                INSERT INTO dbo.CounselorBlockedSlot
                                    (EmployeeID, SlotDate, StartTime, EndTime, Reason)
                                VALUES (@id, @date, @start, @end, @reason);
                            ELSE
                                UPDATE dbo.CounselorBlockedSlot
                                SET Reason = @reason, UpdatedAtUtc = SYSUTCDATETIME()
                                WHERE EmployeeID = @id AND SlotDate = @date
                                  AND StartTime = @start AND EndTime = @end;", args, tx);
                    }
                    else
                    {
                        // Unblock only this selected interval. If a larger time block
                        // overlaps, preserve the portions outside the selected interval.
                        await db.ExecuteAsync(@"
                            DECLARE @RemovedBlocks TABLE (
                                StartTime TIME(0) NOT NULL,
                                EndTime TIME(0) NOT NULL,
                                Reason NVARCHAR(MAX) NULL
                            );

                            DELETE FROM dbo.CounselorBlockedSlot
                            OUTPUT DELETED.StartTime, DELETED.EndTime, DELETED.Reason
                                INTO @RemovedBlocks (StartTime, EndTime, Reason)
                            WHERE EmployeeID = @id
                              AND SlotDate = @date
                              AND StartTime < @end
                              AND EndTime > @start;

                            INSERT INTO dbo.CounselorBlockedSlot
                                (EmployeeID, SlotDate, StartTime, EndTime, Reason)
                            SELECT @id, @date, StartTime, @start, Reason
                            FROM @RemovedBlocks
                            WHERE StartTime < @start;

                            INSERT INTO dbo.CounselorBlockedSlot
                                (EmployeeID, SlotDate, StartTime, EndTime, Reason)
                            SELECT @id, @date, @end, EndTime, Reason
                            FROM @RemovedBlocks
                            WHERE EndTime > @end;", args, tx);

                        // Some databases represent a disabled schedule as a row with
                        // IsAvailable=0 rather than a CounselorBlockedSlot record.
                        // Remove only the selected portion and retain disabled portions
                        // before and after it (if any).
                        await db.ExecuteAsync(@"
                            DECLARE @RemovedDisabled TABLE (
                                SchoolYear DATE NOT NULL,
                                StartTime TIME(0) NOT NULL,
                                EndTime TIME(0) NOT NULL
                            );

                            DELETE FROM dbo.CounselorSchedule
                            OUTPUT DELETED.SchoolYear, DELETED.StartTime, DELETED.EndTime
                                INTO @RemovedDisabled (SchoolYear, StartTime, EndTime)
                            WHERE EmployeeID = @id
                              AND ScheduleDay = @date
                              AND IsAvailable = 0
                              AND StartTime < @end
                              AND EndTime > @start;

                            INSERT INTO dbo.CounselorSchedule
                                (EmployeeID, SchoolYear, ScheduleDay, StartTime, EndTime, IsAvailable)
                            SELECT @id, SchoolYear, @date, StartTime, @start, 0
                            FROM @RemovedDisabled
                            WHERE StartTime < @start;

                            INSERT INTO dbo.CounselorSchedule
                                (EmployeeID, SchoolYear, ScheduleDay, StartTime, EndTime, IsAvailable)
                            SELECT @id, SchoolYear, @date, @end, EndTime, 0
                            FROM @RemovedDisabled
                            WHERE EndTime > @end;", args, tx);

                        // FIX: deleting a temporary block is insufficient if the day
                        // has no available CounselorSchedule row covering the time.
                        // Add a one-day available slot only when coverage is missing.
                        await db.ExecuteAsync(@"
                            INSERT INTO dbo.CounselorSchedule
                                (EmployeeID, SchoolYear, ScheduleDay, StartTime, EndTime, IsAvailable)
                            SELECT @id, @schoolYear, @date, @start, @end, 1
                            WHERE NOT EXISTS (
                                SELECT 1 FROM dbo.CounselorSchedule
                                WHERE EmployeeID = @id
                                  AND ScheduleDay = @date
                                  AND IsAvailable = 1
                                  AND StartTime <= @start
                                  AND EndTime >= @end
                            );", args, tx);
                    }
                }

                tx.Commit();
                return Ok(new
                {
                    employeeId = dto.EmployeeId,
                    date = date.ToString("yyyy-MM-dd"),
                    updatedSlots = dto.Slots.Count,
                    message = "Schedule changes saved."
                });
            }
            catch
            {
                tx.Rollback();
                throw;
            }
        }
        catch (SqlException ex) when (ex.Number >= 51900 && ex.Number < 52000)
        {
            return Conflict(new { error = ex.Message });
        }
        catch (Exception)
        {
            return StatusCode(500, new { error = "Schedule changes could not be saved." });
        }
    }

    private IActionResult ConflictAfterRollback(IDbTransaction tx, string message)
    {
        tx.Rollback();
        return Conflict(new { error = message });
    }
}

param([string]$Base = 'http://localhost:5239')
$ErrorActionPreference = 'Stop'
$year = '2026-08-01'
function Login-Demo([string]$role,[string]$id) {
  $secure = Read-Host "Password for $role $id" -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $pwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    $body = @{role=$role;id=$id;password=$pwd;schoolYear=$year} | ConvertTo-Json
    $res = Invoke-RestMethod -Method Post -Uri "$Base/api/demo-workflow/login" -ContentType 'application/json' -Body $body
    return $res.accessToken
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    Remove-Variable pwd, secure, body -ErrorAction SilentlyContinue
  }
}

$counselorToken = Login-Demo 'counselor' 'EMP0003'
$ch = @{ Authorization = "Bearer $counselorToken" }
$profile = Invoke-RestMethod -Uri "$Base/api/demo-workflow/me" -Headers $ch
Write-Host "Counselor identity: $($profile.id); scope from SQL:"
$profile.assignments | Select-Object employeeID,departmentID,yearOrGradeLevel

$create = @{
  studentID = 'TSTSH01'
  appointmentDate = '2026-11-20'
  appointmentTime = '10:30:00'
  gradeOrYearLevel = 4
  programOrCourse = 'TEST'
  concernDescription = 'Synthetic SHAS workflow test'
} | ConvertTo-Json
$new = Invoke-RestMethod -Uri "$Base/api/demo-workflow/appointments" -Method Post -Headers $ch -ContentType 'application/json' -Body $create
Write-Host "Appointment created: $($new.appointmentID)"

$studentToken = Login-Demo 'student' 'TSTSH01'
$sh = @{ Authorization = "Bearer $studentToken" }
$studentMe = Invoke-RestMethod -Uri "$Base/api/demo-workflow/me" -Headers $sh
Write-Host "Student identity: $($studentMe.id) -> $($studentMe.department)"
$visible = @(Invoke-RestMethod -Uri "$Base/api/demo-workflow/appointments" -Headers $sh)
Write-Host 'Visible student appointment IDs:'
$visible | Select-Object AppointmentID, IDNumber, EmployeeID, AppointmentStatusID | Format-Table

# DO NOT print tokens/passwords or personally identifiable student details.
Remove-Variable counselorToken, studentToken, ch, sh -ErrorAction SilentlyContinue

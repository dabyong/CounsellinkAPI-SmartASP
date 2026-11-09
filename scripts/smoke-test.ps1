# Read-only smoke tests. Does not insert, update or delete data.
param([string]$BaseUrl = 'http://localhost:5271')
$paths = @(
    '/health',
    '/health/db',
    '/api/constants/AppointmentStatus',
    '/api/constants/AppointmentType',
    '/api/counselors',
    '/api/appointments',
    '/api/clinical/sessions',
    '/api/notifications'
)
foreach ($path in $paths) {
    try {
        $res = Invoke-WebRequest -Uri "$BaseUrl$path" -UseBasicParsing -TimeoutSec 15
        Write-Host "PASS $($res.StatusCode) $path" -ForegroundColor Green
    }
    catch {
        $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 'NO RESPONSE' }
        Write-Host "FAIL $status $path : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

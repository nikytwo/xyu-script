
set oracle_sid=orcl
set y=%date:~0,4%
set m=%date:~5,2%
set d=%date:~8,2%
if "%time:~0,2%" lss "10" (set h=0%time:~1,1%) else (set h=%time:~0,2%)
set mi=%time:~3,2%
set s=%time:~6,2%
rman target / log='%y%%m%%d%_%h%%mi%%s%.log' cmdfile='backupWithRmanLv0.rman'



REM set PGPASSWPRD=1234
setlocal enableextensions enabledelayedexpansion
FOR /F "tokens=*" %%a in ('returnNumLines.bat apiKey.txt') do SET numKeys=%%a
FOR /F "tokens=*" %%a in ('returnLine.bat 1 psqlPW.txt') do SET PGPASSWORD=%%a

set dbName=somedb
set tableName=ur_table
set /a count = 1

REM doesn't work in for loop, temp table holds symbol data before on distinct merge is performed over master table
echo CREATE TABLE temp_table (symbol varchar(8), timestamp date, open real, high real,low real,close real,adjusted_close real,volume real,dividend_amount real,split_coefficient real,CONSTRAINT temp_pkey PRIMARY KEY (timestamp,symbol)) WITH (OIDS=FALSE) TABLESPACE pg_default;ALTER TABLE temp_table OWNER to postgres; | psql -U postgres %dbName%

for /F "delims=;" %%a in (c:\test\nasdaqSymbolsNoHeader.csv) do (

	REM key counter
	echo !count!
	FOR /F "tokens=*" %%b in ('returnLine.bat !count! apiKey.txt') do SET APIKEY=%%b
	FOR /F "tokens=*" %%b in ('returnLine.bat !count! proxyList.txt') do SET PROXY=%%b
	echo !APIKEY!
	echo !PROXY!

	set t1=!TIME!
	echo !t1!

	curl -x !PROXY! -L "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=%%a&apikey=!APIKEY!&datatype=csv" -o c:\test\%%a.csv;

	set t2=!TIME!
	echo !t2!
	
	call tdiff.cmd !t1! !t2! > timeDiff.txt
	
	FOR /F "tokens=*" %%b in ('returnLine.bat 3 timeDiff.txt') do SET timeDiff=%%b
	
	echo !timeDiff!

	set startcsec=!timeDiff:~9,2!
	set startsecs=!timeDiff:~6,2!
	
	echo !startsecs!
	
	set /a seconds=!startsecs!
	
	SET noZerosSeconds=!seconds:0=!
	
	echo !noZerosSeconds!
	
	set /a noZeroSecondsMinus4=4-!noZerosSeconds!
	
	awk '{print F,$1,$2,$3,$4,$5,$6,$7,$8,$9}' FS=, OFS=, F=%%a c:\test\%%a.csv > c:\test\%%awSymbols.csv
	
	echo drop table temp_table2;| psql -U postgres somedb
	
	echo create table temp_table2 as table temp_table;|psql -U postgres somedb

	echo copy temp_table2 from 'c:\test\%%awSymbols.csv' DELIMITER ',' CSV HEADER;| psql -U postgres somedb
	
	echo insert into ur_table select distinct * from temp_table2 ON CONFLICT DO NOTHING;| psql -U postgres somedb
	
	echo drop table temp_table2;| psql -U postgres somedb

	if !count! == %numKeys% (set /a count = 0)
	if not !count! == %numKeys% set /a count += 1

 	if !noZerosSeconds! GTR 4 (timeout /t 0)
	
	if !noZerosSeconds! LSS 4 (timeout /t !noZeroSecondsMinus4!)
	
)

echo drop table temp_table;| psql -U postgres somedb
endlocal

:increaseby1
set /a "count+=1"
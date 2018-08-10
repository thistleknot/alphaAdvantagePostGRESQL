REM Called by PopulateDB.bat after bonds have been downloaded.  Creates tables, requires 2 inputs

REM adds symbol to front of columns

set dbName=readyloop

set PGPASSWORD=1234

for /F %%a in (c:\test\ETFNamesSymbolsNoHeader.csv) do (

			awk '{print F,$1,$2,$3,$4,$5,$6,$7}' FS=, OFS=, F=%%a c:\test\share\etf\etf-%%a.csv > c:\test\share\etf\etf-%%awSymbols.csv
	
			echo drop table etf_bond_facts cascade;| psql -U postgres %dbName%

			echo drop table if exists temp_table%%a;| psql -U postgres %dbName%
	
			echo create table bond_facts%%a as table bond_facts_template;|psql -U postgres %dbName%

			echo copy bond_facts%%a from 'c:\test\share\etf\etf-%%awSymbols.csv' DELIMITER ',' CSV HEADER;| psql -U postgres %dbName%

			echo insert into etf_bond_facts select distinct * from bond_facts%%a ON CONFLICT DO NOTHING;| psql -U postgres %dbName%

			echo drop table bond_facts%%a;| psql -U postgres %dbName%
	)
	
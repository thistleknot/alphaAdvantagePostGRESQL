	CREATE OR REPLACE VIEW public.v_eod_indices_2013_2017 AS
	 SELECT dadjclose.symbol,
		dadjclose.timestamp,
		dadjclose.adjusted_close
	   FROM dadjclose
	   WHERE dadjclose.timestamp >= '2012-12-31'::date AND dadjclose.timestamp <= '2018-07-28'::date;
	   
	CREATE OR REPLACE VIEW public.v_eod_indices_2017_2017 AS
	 SELECT dadjclose.symbol,
		dadjclose.timestamp,
		dadjclose.adjusted_close
	   FROM dadjclose
	   WHERE dadjclose.timestamp >= '2017-12-31'::date AND dadjclose.timestamp <= '2018-07-28'::date;	   

Create Materialized View returnsNasdaq AS
		SELECT EOD.symbol,EOD.timestamp,EOD.adjusted_close/NULLIF( PREV_EOD.adjusted_close, 0 )-1.0 AS ret
			FROM v_eod_indices_2013_2017 EOD INNER JOIN custom_calendar CC ON EOD.timestamp=CC.date
			INNER JOIN v_eod_indices_2013_2017 PREV_EOD ON PREV_EOD.symbol=EOD.symbol AND PREV_EOD.timestamp=CC.prev_trading_day;
			REFRESH MATERIALIZED VIEW returnsNasdaq WITH DATA;
			
Create Materialized View returnsNasdaq2 AS
		SELECT EOD.symbol,EOD.timestamp,EOD.adjusted_close/NULLIF( PREV_EOD.adjusted_close, 0 )-1.0 AS ret
			FROM v_eod_indices_2017_2017 EOD INNER JOIN custom_calendar CC ON EOD.timestamp=CC.date
			INNER JOIN v_eod_indices_2017_2017 PREV_EOD ON PREV_EOD.symbol=EOD.symbol AND PREV_EOD.timestamp=CC.prev_trading_day;
			REFRESH MATERIALIZED VIEW returnsNasdaq2 WITH DATA;			
			
			select * from custom_calendar order by date asc;
			
			select * from v_eod_indices_2013_2017 where adjusted_close='0'

		SELECT symbol, 'More than 1% missing' as reason
		INTO exclusions_2013_2017
		FROM dadjclose
		GROUP BY symbol
		HAVING count(*)::real/(SELECT COUNT(*) FROM custom_calendar WHERE trading=1 AND date BETWEEN '2012-12-31' AND '2018-07-28')::real<0.99;					
		
		INSERT INTO exclusions_2013_2017 SELECT DISTINCT symbol, 'Return higher than 100%' as reason FROM returnsNasdaq WHERE ret>1.0;
		
		create view filtered as SELECT * FROM returnsNasdaq WHERE symbol NOT IN  (SELECT DISTINCT symbol FROM exclusions_2013_2017);
		
		select symbol, AVG(NULLIF(ret,0)) as average from filtered group by symbol order by average desc; 
		
		-- Daily prices export
		SELECT PR.* 
		INTO export_daily_prices_2013_2017
		FROM custom_calendar CC LEFT JOIN returnsNasdaq PR ON CC.date=PR.timestamp
		WHERE CC.trading=1;

		COPY export_daily_prices_2013_2017 To 'C:\TEST\export_monthly_prices_2013_2017.csv' With CSV DELIMITER ',';

		-- Monthly (eom) prices export

		SELECT PR.* 
		INTO export_monthly_prices_2013_2017
		FROM custom_calendar CC LEFT JOIN returnsNasdaq PR ON CC.date=PR.timestamp
		WHERE CC.trading=1 AND CC.eom=1;

		COPY export_monthly_prices_2013_2017 To 'C:\TEST\export_monthly_prices_2013_2017.csv' With CSV DELIMITER ',';

		-- Daily returns export

		SELECT PR.* 
		INTO export_daily_returns_2013_2017
		FROM custom_calendar CC LEFT JOIN returnsNasdaq PR ON CC.date=PR.timestamp
		WHERE CC.trading=1;

		COPY export_daily_returns_2013_2017 To 'C:\TEST\export_daily_returns_2013_2017.csv' With CSV DELIMITER ',';			
		
--- Create User

CREATE USER readyloop WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	CONNECTION LIMIT -1
	PASSWORD 'read123';
	
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readyloop;

-- Grant read rights (for future tables and views)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO readyloop;
   
	
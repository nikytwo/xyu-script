
DECLARE 
	@dbname varchar(100),
	@sql varchar(1000)

DECLARE gl_cursor CURSOR FOR 
	select fdbname from KDAcctDB..t_ad_kdAccount_gl
	where FacctNumber like '003.%'
	--select fdbname from KDAcctDB..t_ad_kdAccount_gl
	--where len(facctnumber) = 2
	
OPEN gl_cursor

FETCH NEXT FROM gl_cursor 
INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN	
	print @dbname
	if charindex('2008', @@version) > 0 then
	begin
		-- sql server 2008
		set @sql = ' alter database ' + @dbname + ' set recovery simple '
		set @sql = @sql + ' dbcc shrinkdatabase (' + @dbname + ', 1) '
		set @sql = @sql + ' alter database ' + @dbname + ' set recovery full '
	end
	else
	begin
		-- sql server 2005
		set @sql = ' backup log ' + @dbname + ' with NO_LOG '
		set @sql = @sql + ' dbcc shrinkdatabase (' + @dbname + ')'
	end
	exec (@sql)

	-- Get the next author.
   FETCH NEXT FROM gl_cursor 
   INTO @dbname
END

CLOSE gl_cursor
DEALLOCATE gl_cursor
GO


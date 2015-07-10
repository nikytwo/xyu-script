-- =============================================
-- Create scalar function (FN)
-- 
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'getItemFrom')
	DROP FUNCTION getItemFrom
GO

CREATE FUNCTION getItemFrom 
	(@items varchar(1000), --含多个辅助核算项目的字符串
	 @index int)	----取出第@index个辅助核算项目信息(从1开始)
RETURNS varchar(1000)
AS
BEGIN
	declare @tmpStr varchar(1000),
		@searchStr varchar(2),
		@startP int,
		@endP int,
		@count int
	set @searchStr = '&&'
	set @count = 0
	set @tmpStr = isnull(@items, '')
	if ('' = @tmpStr)
	begin
		RETURN ''
	end
	else
	begin
		set @count = @count + 1	
	end

	set @endP = 0
	set @startP = @endP
	set @endP = charindex(@searchStr, @tmpStr, @endP + 1)
	while (@endP > 0 and @count < @index)
	begin
		set @count = @count + 1
		set @startP = @endP + 1
		set @endP = charindex(@searchStr, @tmpStr, @endP + 1)
	end
	
	if (@endP = 0)
	begin
		set @endP = len(@tmpStr)
	end
	else
	begin
		set @endP = @endP - 2
	end
	
	if (@count < @index)
	begin
		return ''
	end

	RETURN substring(@tmpStr, @startP + 1, @endP - @startP + 1)
END
GO


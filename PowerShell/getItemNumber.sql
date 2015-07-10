-- =============================================
-- Create scalar function (FN)
-- 从字符串中获取需要做辅助核算的ID
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'getItemNumber')
	DROP FUNCTION getItemNumber
GO

CREATE FUNCTION getItemNumber 
	(@item varchar(1000))	--只含单个辅助核算项目的字符串
RETURNS varchar(1000)
AS
BEGIN
	declare @searchStr1 varchar(2),
		@searchStr2 varchar(2),
		@tmpStr varchar(1000),
		@startP int,
		@endP int
	set @searchStr1 = '@@'
	set @searchStr2 = '__'
	set @tmpStr = isnull(@item, '')
	if ('' = @tmpStr)
	begin
		RETURN ''
	end

	set @startP = charindex(@searchStr1, @tmpStr, 1) + 2
	set @endP = charindex(@searchStr2, @tmpStr, 1) - 1
	if (@startP < 3 and @endP < 0)
	begin
		RETURN ''
	end	
	if (@startP < 3)
	begin
		set @startP = 1
	end
	while (@endP <= @startP and @endP > 0)
	begin
		set @endP = charindex(@searchStr2, @tmpStr, @endP + 2) - 1		
	end
	if (@endP < 0)
	begin
		set @endP = len(@tmpStr)
	end

	RETURN substring(@tmpStr, @startP, @endP - @startP + 1)
END
GO



-- =============================================
-- Create scalar function (FN)
-- 从字符串中获取需要做辅助核算的类的名称
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'getItemClass')
	DROP FUNCTION getItemClass
GO

CREATE FUNCTION getItemClass 
	(@item varchar(1000))	--只含单个辅助核算项目的字符串
RETURNS varchar(1000)
AS
BEGIN
	declare @searchStr varchar(2),
		@tmpStr varchar(1000),
		@startP int,
		@endP int
	set @searchStr = '@@'
	set @tmpStr = isnull(@item, '')
	if ('' = @tmpStr)
	begin
		RETURN ''
	end

	set @startP = 1
	set @endP = @startP
	set @endP = charindex(@searchStr, @tmpStr, @endP) - 1
	if (@endP < 0)
	begin
		set @endP = len(@tmpStr)
	end

	RETURN substring(@tmpStr, @startP, @endP - @startP + 1)
END
GO


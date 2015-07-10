-- =============================================
-- Create scalar function (FN)
-- ���ַ����л�ȡ��Ҫ���������������
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'getItemName')
	DROP FUNCTION getItemName
GO

CREATE FUNCTION getItemName 
	(@item varchar(1000))	--ֻ����������������Ŀ���ַ���
RETURNS varchar(1000)
AS
BEGIN
	declare @searchStr varchar(2),
		@tmpStr varchar(1000),
		@startP int,
		@endP int
	set @searchStr = '__'
	set @tmpStr = isnull(@item, '')
	if ('' = @tmpStr)
	begin
		RETURN ''
	end

	set @startP = 1
	set @endP = len(@tmpStr)
	set @startP = charindex(@searchStr, @tmpStr, @startP) + 2
	if (@startP < 3)
	begin
		set @startP = 1
	end

	RETURN substring(@tmpStr, @startP, @endP - @startP + 1)
END
GO



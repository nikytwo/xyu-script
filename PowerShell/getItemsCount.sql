-- =============================================
-- Create scalar function (FN)
-- ���ַ����л�ȡ��Ҫ���������������
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'getItemsCount')
	DROP FUNCTION getItemsCount
GO

CREATE FUNCTION getItemsCount 
	(@items varchar(1000))	--���������������Ŀ���ַ���
RETURNS int
AS
BEGIN
	declare @searchStr varchar(2),
		@count int,
		@tmpStr varchar(1000),
		@startP int
	set @searchStr = '&&'
	set @count = 0
	set @tmpStr = isnull(@items, '')
	if ('' = @tmpStr)
	begin
		RETURN @count
	end
	else
	begin
		set @count = @count + 1	
	end

	set @startP = 0
	set @startP = charindex(@searchStr, @tmpStr, @startP + 1)
	while (@startP > 0)
	begin
		set @count = @count + 1
		set @startP = charindex(@searchStr, @tmpStr, @startP + 1)
	end

	RETURN @count
END
GO


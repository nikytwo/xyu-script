
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_CheckItemDetailID')
	DROP PROCEDURE K_CheckItemDetailID
GO

-- =============================================
-- Create PROCEDURE
-- 检查核算项目@items与给定会计科目的 DetailID 值所对应的是否一样，返回处理过的新的 @newItems
-- 新 @newItems 规则：若新核算项目内包含有旧核算项目，则使用新的，反之使用旧的；若新旧都不相同，则合并。
-- =============================================
--本存储过程可处理多个核算项目（见@items参数）
CREATE  PROCEDURE K_CheckItemDetailID(
	--支持多个核算项目，没有请留空，
	--格式：ItemClassID1@@-1__&&ItemClassID2@@-1__&&ItemClassIDn@@-1__,
	--如:3001@@-1__&&3002@@-1__&&3003@@-1__（-1是会计科目挂载时用的）
	@items varchar(100),		
	@oldDetailID int,			--待比较的 DetailID
	@newItems varchar(100) OUTPUT
)
AS

declare 
	@index int,
	@itemCount int,
	@tmpItemClassID varchar(255)
  
	select @itemCount = dbo.getItemsCount(@items)
	if (@itemCount <= 0)
	begin
		set @newItems = ''
		print 'Count = 0'
	end
	else
	begin
		set @newItems = @items
		print 'Count > 0'
	end

	declare curItemDetailv Cursor for
	Select Convert(varchar,fitemclassid) FROM t_itemdetailv
	where fitemid = -1 and fdetailid = @oldDetailID

	Open curItemDetailv
	Fetch next from curItemDetailv
	Into @tmpItemClassID

	While @@FETCH_STATUS = 0
	begin
		set @index = charindex(@tmpItemClassID, @newItems)
		if (@index <= 0 
		or (@index > 0 and substring(@newItems, @index + len(@tmpItemClassID), 2) <> '@@' 
		or @index - 2 > 0 and substring(@newItems, @index - 2, 2) <> '&&'))
		begin
			-- 原 @items 中 没有 @tmpItemClassID ,增加之
			if (@newItems <> '')
			begin
				set @newItems = @newItems + '&&'
			end
			set @newItems = @newItems + @tmpItemClassID + '@@-1__'
		end

		Fetch next from curItemDetailv
		Into @tmpItemClassID
	end
	Close curItemDetailv
	Deallocate curItemDetailv
  
GO


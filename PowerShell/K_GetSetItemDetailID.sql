
-- =============================================
-- Create PROCEDURE
-- 获取/新增核算项目的DetailID 值
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_GetSetItemDetailID')
	DROP PROCEDURE K_GetSetItemDetailID
GO

--本存储过程可处理多个核算项目（见@items参数）
CREATE  PROCEDURE K_GetSetItemDetailID(
	--多个核算项目，没有请留空，
	--格式：ItemClassID1@@ItemID1__&&ItemClassID2@@ItemID2__&&ItemClassIDn@@ItemIDn__,
	--如:3001@@-1__&&3002@@-1__&&3003@@-1__（-1是会计科目挂载时用的，核算项目挂载到凭证时，ItemID应大于0）
	@items varchar(100),		
	@rst varchar(80) OUTPUT		--返回信息
)
AS

declare 
	@detailID int,
	@itemCount int,
	@index int,
	@tmpItem varchar(255),
	@tmpItemClassID varchar(255),
	@tmpItemID varchar(255),
	@sqlString nvarchar(2000),
	@sqlStr2 nvarchar(1000)
  
--BEGIN TRANSACTION TRAN_GetSetItemDetailID
	print convert(varchar, @@TRANCOUNT)
	print 'BEGIN TRANSACTION TRAN_GetSetItemDetailID'
 	set @rst = ''
	select @itemCount = dbo.getItemsCount(@items)
	if (@itemCount <= 0)
	begin
		set @detailID = 0
		print 'Count = 0'
	end
	else
	begin
		set @sqlString = N'select @detailID = fdetailid from t_itemdetail where fdetailcount = ' 
			+ convert(varchar, @itemCount)	
		set @index = 0		
		while (@index < @itemCount)
		begin
			set @index = @index + 1
			set @tmpItem = dbo.getItemFrom(@items, @index)
			select @tmpItemClassID = dbo.getItemClass(@tmpItem)
			select @tmpItemID = dbo.getItemNumber(@tmpItem)
			set @sqlString = @sqlString + ' and f' + @tmpItemClassID + ' = ' + @tmpItemID
		end
		print @sqlString
		execute sp_executesql @sqlString, N'@detailID int output', @detailID output
		if (@@error<>0) 
		begin
			set @rst = '执行SQL时出错：' + @sqlString + '。'
			goto fail			
		end
		if (isnull(@detailID, -1) < 0)
		begin
			--没有获取到，则插入新的。
			select @detailID = fnext from t_identity where fname='t_ItemDetail'
			set @sqlString = 'insert into t_itemdetail(fdetailid, fdetailcount'
			set @sqlStr2 = 'Values (@detailID, ' + convert(varchar, @itemCount)
			set @index = 0		
			while (@index < @itemCount)
			begin
				set @index = @index + 1
				set @tmpItem = dbo.getItemFrom(@items, @index)
				select @tmpItemClassID = dbo.getItemClass(@tmpItem)
				select @tmpItemID = dbo.getItemNumber(@tmpItem)
				set @sqlString = @sqlString + ', f' + @tmpItemClassID
				set @sqlStr2 = @sqlStr2 + ', ' + @tmpItemID
				insert into t_itemdetailv (FDetailID,FItemClassID,FItemID) values (@detailID, convert(int, @tmpItemClassID), convert(int, @tmpItemID))
				if (@@error<>0) 
				begin
					set @rst = '将[' + @items + ']插入核算项目纵表失败。'
					goto fail			
				end
			end
			set @sqlString = @sqlString + ')' + @sqlStr2 + ')'
			print @sqlString
			execute sp_executesql @sqlString, N'@detailID int', @detailID
			if (@@error<>0) 
			begin
				set @rst = '将[' + @items + ']插入核算项目横表失败。'
				goto fail			
			end
		end
	end
  
	print 'COMMIT TRANSACTION TRAN_GetSetItemDetailID'
--COMMIT TRANSACTION TRAN_GetSetItemDetailID
	print convert(varchar, @@TRANCOUNT)
return @detailID

fail: 
print 'ROLLBACK TRANSACTION TRAN_GetSetItemDetailID'
--ROLLBACK TRANSACTION 
	print convert(varchar, @@TRANCOUNT)
return -1

GO

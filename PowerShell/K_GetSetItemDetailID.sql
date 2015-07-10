
-- =============================================
-- Create PROCEDURE
-- ��ȡ/����������Ŀ��DetailID ֵ
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_GetSetItemDetailID')
	DROP PROCEDURE K_GetSetItemDetailID
GO

--���洢���̿ɴ�����������Ŀ����@items������
CREATE  PROCEDURE K_GetSetItemDetailID(
	--���������Ŀ��û�������գ�
	--��ʽ��ItemClassID1@@ItemID1__&&ItemClassID2@@ItemID2__&&ItemClassIDn@@ItemIDn__,
	--��:3001@@-1__&&3002@@-1__&&3003@@-1__��-1�ǻ�ƿ�Ŀ����ʱ�õģ�������Ŀ���ص�ƾ֤ʱ��ItemIDӦ����0��
	@items varchar(100),		
	@rst varchar(80) OUTPUT		--������Ϣ
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
			set @rst = 'ִ��SQLʱ����' + @sqlString + '��'
			goto fail			
		end
		if (isnull(@detailID, -1) < 0)
		begin
			--û�л�ȡ����������µġ�
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
					set @rst = '��[' + @items + ']���������Ŀ�ݱ�ʧ�ܡ�'
					goto fail			
				end
			end
			set @sqlString = @sqlString + ')' + @sqlStr2 + ')'
			print @sqlString
			execute sp_executesql @sqlString, N'@detailID int', @detailID
			if (@@error<>0) 
			begin
				set @rst = '��[' + @items + ']���������Ŀ���ʧ�ܡ�'
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

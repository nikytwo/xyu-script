
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_CheckItemDetailID')
	DROP PROCEDURE K_CheckItemDetailID
GO

-- =============================================
-- Create PROCEDURE
-- ��������Ŀ@items�������ƿ�Ŀ�� DetailID ֵ����Ӧ���Ƿ�һ�������ش�������µ� @newItems
-- �� @newItems �������º�����Ŀ�ڰ����оɺ�����Ŀ����ʹ���µģ���֮ʹ�þɵģ����¾ɶ�����ͬ����ϲ���
-- =============================================
--���洢���̿ɴ�����������Ŀ����@items������
CREATE  PROCEDURE K_CheckItemDetailID(
	--֧�ֶ��������Ŀ��û�������գ�
	--��ʽ��ItemClassID1@@-1__&&ItemClassID2@@-1__&&ItemClassIDn@@-1__,
	--��:3001@@-1__&&3002@@-1__&&3003@@-1__��-1�ǻ�ƿ�Ŀ����ʱ�õģ�
	@items varchar(100),		
	@oldDetailID int,			--���Ƚϵ� DetailID
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
			-- ԭ @items �� û�� @tmpItemClassID ,����֮
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


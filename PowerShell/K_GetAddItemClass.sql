
-- =============================================
-- ��Ӻ�����Ŀ���
-- =============================================

IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'K_GetAddItemClass' 
	   AND 	  type = 'P')
    DROP PROCEDURE K_GetAddItemClass
GO

CREATE  PROCEDURE K_GetAddItemClass(
	@itemClassName nvarchar(510)
)
AS
	declare @tmpItemClassID int,
			@tmpSqlStr varchar(1000),
			@FDetailFuncID int,
			@FIndex int,
			@FUserID int
	
	if (isnull(@itemClassName,'') = '')
	begin
		return 0
	end
	if Exists(Select FItemClassID FROM t_ItemClass WHERE FName = @itemClassName)
	begin
		SELECT @tmpItemClassID = FItemClassID FROM t_ItemClass WHERE FName = @itemClassName
		return @tmpItemClassID
	end
	
	print '�����ں�����Ŀ'
	-- �����ں�����Ŀ��������֮
	-- ��ȡ��һ�� ItemClassID ��Ϊ FNumber
	Select @tmpItemClassID = FNext From t_Identity where FName = 't_ItemClass'
	-- �����º�����Ŀ
	INSERT INTO t_ItemClass 
	(FNumber,FName,FName_Cht,FName_en,FRemark,FVersion) 
	VALUES (@tmpItemClassID, @itemClassName, @itemClassName, @itemClassName, @itemClassName, 0)
	
	if Not Exists(Select c.Name from syscolumns c,sysobjects o where c.Id=o.Id and c.name = 'F' + convert(varchar,@tmpItemClassID) and o.name='t_ItemDetail')   
	Begin  
		set @tmpSqlStr = 'Alter Table t_ItemDetail Add F' + convert(varchar,@tmpItemClassID) + ' int not null default(0) '
		exec (@tmpSqlStr) 
		set @tmpSqlStr = 'Create Index ix_ItemDetail_' + convert(varchar,@tmpItemClassID) + ' On t_ItemDetail(F' + convert(varchar,@tmpItemClassID) + ') '
		exec (@tmpSqlStr)
	END
	 
	--�ô洢����������װ�½�������Ŀʱ��Ҫ��ӵ����й���Ȩ�ޡ��ֶ�Ȩ�ޡ�����Ȩ�޵�Ԥ������
	exec p_Base_AddItemAuthority @tmpItemClassID
	
	-- ɾ���� t_DataFlowDetailFunc �У����ڹ�������(600201)�ģ���������Ŀ=60020199������Ϣ�����������ĺ�����ټӻ�ȥ��
	DELETE FROM t_DataFlowDetailFunc 
	WHERE FDetailFuncID In( 
		Select b.FDetailFuncID  From t_DataFlowSubFunc A, t_DataFlowDetailFunc B 
		Where A.FSubFuncID=600201 And B.FDetailFuncID=60020199 And A.FSubFuncID=B.FSubFuncID
	)

	-- ��� t_DataFlowDetailFunc ���������ĺ�����Ŀ
	Select @FDetailFuncID = Max(FDetailFuncID) + 1 FROM t_DataFlowDetailFunc Where FSubFuncID = 600201
	Select @FIndex = Max(FIndex) + 1 FROM t_DataFlowDetailFunc Where FSubFuncID = 600201
	Insert Into t_DataFlowDetailFunc 
	(FDetailFuncID,FSubFuncID,FFuncName,FFuncName_CHT,FFuncName_EN,FClassName,FClassParam,FIsNormal,FHelpCode,FVisible,FAcctType,FFuncType,FIndex)  
	Values(@FDetailFuncID,600201,@itemClassName,@itemClassName,@itemClassName,'BaseSys.Application',Convert(varchar, @tmpItemClassID),0,'CUSTOM' + Convert(varchar, @tmpItemClassID),0,'',0,@FIndex)
	-- TODO ȱ����t_UserDetailFunc���������ĺ�����Ŀ
	Update t_UserDetailFunc SET FDetailFuncID = @FDetailFuncID WHERE FSubFuncID = 600201 and FClassParam = Convert(varchar, @tmpItemClassID)
	Update t_DataFlowTimeStamp SET FName = FName 
	UPDATE t_DataFlowTimeStamp SET FName = 'DataFlow' WHERE FName = 'DataFlow'

	-- ���Ӹ������Ϲ���FIndex ���������ĺ�����Ŀ��FDetailFuncID Ϊ��� 60020199
	Select @FIndex = Max(FIndex) + 1 FROM t_DataFlowDetailFunc Where FSubFuncID = 600201
	Insert Into t_DataFlowDetailFunc(FDetailFuncID,FSubFuncID,FFuncName,FFuncName_CHT,FFuncName_EN,FClassName,FClassParam,FIsNormal,FHelpCode,FVisible,FAcctType,FFuncType,FIndex)  
	Values(60020199,600201,'�������Ϲ���','�o���Y�Ϲ���','Aux. data management','BaseSys.Application','500',0,'FZZL',1,'',0,@FIndex)
	Update t_UserDetailFunc SET FDetailFuncID = 60020199 WHERE FSubFuncID = 600201 and FClassParam = '500'
	Update t_DataFlowTimeStamp SET FName = FName 
	UPDATE t_DataFlowTimeStamp SET FName = 'DataFlow' WHERE FName = 'DataFlow'

	-- TODO ��ʲô����??
	DELETE FROM t_UserDetailFunc WHERE FDetailFuncID<0

	-- ��� t_BaseProperty �����Ƿ��������ĺ�����Ŀ����Ϣ��û�������ӡ�
	IF Not EXISTS (Select 1 from t_BaseProperty Where FTypeID = 2 And FItemID = @tmpItemClassID)
	begin
		Insert Into t_BaseProperty(FTypeID, FItemID, FCreateDate, FCreateUser, FLastModDate, FLastModUser, FDeleteDate, FDeleteUser)
		Values(2, @tmpItemClassID, Getdate(), 'administrator', Null, Null, Null, Null)
	end

	-- д��־
	Select @FUserID = FUserID From t_User Where FName = 'Administrator'
	INSERT INTO t_Log (FDate,FUserID,FFunctionID,FStatement,FDescription,FMachineName,FIPAddress) 
	VALUES (Getdate(), @FUserID, 'A00701', 5, '[���ϵͳ]���Ӻ�����Ŀ���:' + @itemClassName, 'LocalHost', '127.0.0.1')
	
	return @tmpItemClassID

GO

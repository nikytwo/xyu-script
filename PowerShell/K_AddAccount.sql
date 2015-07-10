
-- =============================================
-- Create PROCEDURE
-- �����¿�Ŀ
-- ֻ������4�࣬5���Ŀ
-- ��Ӧ�����ϵͳ�Ĵ洢����
-- =============================================
IF EXISTS (SELECT * 
	   FROM   sysobjects 
	   WHERE  name = N'K_AddAccount')
	DROP PROCEDURE K_AddAccount
GO

-- TODO ����ʱ ����δ�ύ��
--���洢���̿ɴ�����������Ŀ����@items������
CREATE  PROCEDURE K_AddAccount(
	@accountnum varchar(80),  	--��Ŀ����(�磺501.01)
	@accountname varchar(255),  	--��Ŀ���ƣ��磺����֧����
	@dc int,      			--�������(1=�跽��-1=����)
	@level int,      		--����501.01 Ϊ 2����
	@detail int,      		--�Ƿ�����ϸ��0=��1=�ǣ�

	--���������Ŀ��û�������գ�
	--��ʽ��ItemClassID1@@ItemID1__&&ItemClassID2@@ItemID2__&&ItemClassIDn@@ItemIDn__,
	--��:3001@@-1__&&3002@@-1__&&3003@@-1__��-1�ǻ�ƿ�Ŀ����ʱ�õģ�������Ŀ���ص�ƾ֤ʱ��ItemIDӦ����0��
	@items varchar(100),	
	@rst varchar(80) OUTPUT		--������Ϣ
)
AS
declare @rootid int,
	@accountid int,      	--��Ŀid
	@detailidt int,
	@parentid int,
	@cha int,
	@tnum varchar(80)
  
--BEGIN TRANSACTION TRAN_AddAccount
	print convert(varchar, @@TRANCOUNT)
	print 'BEGIN TRANSACTION TRAN_AddAccount'
 	
	if exists (select 1 from t_account where fnumber = @accountnum)
	begin
		set @rst = '��Ŀ[' + @accountnum + ']�Ѵ��ڡ�'
		select @accountid = faccountid from t_account where fnumber = @accountnum
	end
	else
	begin		
		set @rst = '';
		select @accountid = fnext from t_identity where fname='t_account'
		
		if @level<>1
		begin
			-- ��һ����Ŀ
			-- ����"."����ȡ�ϼ���Ŀ
			set @cha = len(@accountnum) - charindex('.', reverse(@accountnum))
			set @tnum = substring(@accountnum,1,@cha) --�ϼ���Ŀ
			select @parentid=faccountid from t_account where fnumber=@tnum
			update t_account set FDetail=0 where faccountid=@parentid	--�����ϼ���ĿΪ����ϸ��Ŀ
			select @rootid=frootid from t_account where FAccountID = @parentid
		end
		else
		begin
			-- һ����Ŀ
			set @parentid = 0
			set @rootid = @accountid
		end

		if isnull(@rootid, -1) >= 0 
		begin
			-- �����ϼ���Ŀ��
			declare 
				@recCount int,	--
				@index int,	--
				@itemCount int,	--�¿�Ŀ�ж��ٸ���������Ŀ
				@tmpItemClassID varchar(20),	--����������ĿID����ʱ������
				@sqlString nvarchar(1000),
				@sqlStr2 nvarchar(1000)
		
			exec @detailidt = K_GetSetItemDetailID @items, @rst out

			if (isnull(@dc,0) <> 1 or isnull(@dc,0) <> -1)
			begin
				if (charindex('5',@accountnum) = 1 or charindex('1',@accountnum) = 1)
				begin
					set @dc = 1
				end
				else
				begin
					set @dc = -1
				end
			end

			if charindex('5',@accountnum)=1
			begin
				-- ����֧��
					INSERT INTO t_Account (FAccountID,FNumber,FName,FGroupID,FDC,FHelperCode,FCurrencyID,FAdjustRate,
						   FIsCash,FIsBank,FJournal,FContact,FQuantities,FUnitGroupID,FMeasureUnitID,
						   FDetailID,FIsCashFlow,FAcnt,FInterest,FIsAcnt,FAcctint,FLevel,FDetail,
						   FParentID,FIsBudget,FRootID) VALUES (
						   @accountid,@accountnum,@accountname,503,@dc,NULL, 1, 0,
						   0, 0, 0, 0, 0, 0, 0, 
						   @detailidt, 0, 0, 0, 0, 0, @level, @detail,
						   @parentid, 0,@rootid)	
			end
			else if charindex('4',@accountnum)=1
			begin
				--��������
					INSERT INTO t_Account (FAccountID,FNumber,FName,FGroupID,FDC,FHelperCode,FCurrencyID,FAdjustRate,
						   FIsCash,FIsBank,FJournal,FContact,FQuantities,FUnitGroupID,FMeasureUnitID,
						   FDetailID,FIsCashFlow,FAcnt,FInterest,FIsAcnt,FAcctint,FLevel,FDetail,
						   FParentID,FIsBudget,FRootID) VALUES (
						   @accountid,@accountnum,@accountname,401,@dc,NULL, 1, 0,
						   0, 0, 0, 0, 0, 0, 0, 
						   @detailidt, 0, 0, 0, 0, 0, @level, @detail,
						   @parentid, 0,@rootid)	
			end
			else 
			begin
				--����
					INSERT INTO t_Account (FAccountID,FNumber,FName,FGroupID,FDC,FHelperCode,FCurrencyID,FAdjustRate,
						   FIsCash,FIsBank,FJournal,FContact,FQuantities,FUnitGroupID,FMeasureUnitID,
						   FDetailID,FIsCashFlow,FAcnt,FInterest,FIsAcnt,FAcctint,FLevel,FDetail,
						   FParentID,FIsBudget,FRootID) VALUES (
						   @accountid,@accountnum,@accountname,CONVERT(int, left(@accountnum,1) + '01'),@dc,NULL, 1, 0,
						   0, 0, 0, 0, 0, 0, 0, 
						   @detailidt, 0, 0, 0, 0, 0, @level, @detail,
						   @parentid, 0,@rootid)	
			end
			if (@@error<>0) 
			begin
				set @rst = '���t_Account�����¿�Ŀʧ�ܡ�' + @accountnum + ',' + @accountname + ',' + @level + ',' + @detail
				goto fail			
			end
		end 
		else
		begin
			set @rst = '��Ŀ[' + @accountnum + ']���ϼ���Ŀ�����ڡ�'
			set @accountid = 0;
		end
	end
  
	print 'COMMIT TRANSACTION TRAN_AddAccount'
--COMMIT TRANSACTION TRAN_AddAccount
	print convert(varchar, @@TRANCOUNT)
return @accountid 

fail:
	print 'ROLLBACK TRANSACTION TRAN_AddAccount'
--ROLLBACK TRANSACTION 
	print convert(varchar, @@TRANCOUNT)
return -1

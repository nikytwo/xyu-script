SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

IF EXISTS (SELECT name 
	   FROM   sysobjects 
	   WHERE  name = N'K3_yhrjz' 
	   AND 	  type = 'P')
    DROP PROCEDURE K3_yhrjz
GO

Create  PROCEDURE K3_yhrjz(
	@accountNum varchar(100),--��Ŀ
	@date datetime,--����
	@explanation varchar(500),--ժҪ	
	@gold money,--���
	@dc int,--������� 1.�� 0.��
	@person varchar(255),--�Ƶ�����
	@attachments int,--������
	@ret_value varchar(80) out--������Ϣ
)
AS
	declare	@id int,
		@sqlStr nvarchar(1000),
		@tmpRstStr varchar(1000),
		@kmid int,--��Ŀid
		@year int,--��
		@period int,--�ڼ�
		@debit money,--�跽���
		@credit money--�������
begin transaction
	if exists (select 1 from cn_account where fid=1)
		select @id=max(fid)+1 from cn_account
	else
		set @id=1

	if exists (select 1 from cn_account where fkmdm=@accountNum)
		select @kmid=fid from cn_account where fkmdm=@accountNum
	else
		goto fail

	set @year=year(@date)
	set @period=month(@date)
	-- ��ȡ/�����Ƶ���id
	exec K_AddUser @person, @tmpRstStr out
	print @tmpRstStr

	if @dc=1
	begin
		set @debit=@gold
		set @credit=0
	end
	else
	begin
		set @debit=0
		set @credit=@gold
	end

	set @explanation = isnull(@explanation,' ')
	
	if EXISTS (Select 1 from syscolumns c,sysobjects o where c.Id=o.Id and c.name = 'forderid' and o.name = 'cn_yhrjz')	
	begin
		-- 13.0�棬������ FOrderID ��
		declare @orderid int
		set @sqlStr = '	select @orderid = isnull(MAX(forderid)+1, 1) from cn_yhrjz'
		execute sp_executesql @sqlStr,N'@orderid int output',@orderid output

		set @sqlStr = 'insert into cn_yhrjz '
			+ '(forderid,fkmid,fyear,fperiod,fdate,fgroup,fnum,fexp,fjsfs,fjsh,faccountid2,'
			+ 'facctidside,fdebit,fcredit,fdebitB,fcreditB,FRate,flyr,fdzalready,fdznumber,'
			+ 'fjz,fsource,foldid,foperationdate,fwbbid,fwbamount,fremark,fvoucherid,fgenvch,'
			+ 'fvchyear,fvchperiod,fsourceid,fattachments) '
			+ 'values ('
			+ '@orderid,@kmid,@year,@period,@date,null,0,@explanation,null,null,null,'
			+ 'null,@debit,@credit,@debit,@credit,1.0,@person,0,-1,'
			+ '0,1,@id,getdate(),0,0,null,null,null,   '
			+ '0,0,null,@attachments'
			+ ')'
		execute sp_executesql @sqlStr, 
			N'@orderid int,@kmid int,@year int,@period int,@date datetime,@explanation varchar(500),
			@debit money,@credit money,@person varchar(255),@id int,@attachments int', 
			@orderid,@kmid,@year,@period,@date,@explanation,
			@debit,@credit,@person,@id,@attachments		
	end
	else
	begin
		-- 10.3��
		set @sqlStr = 'insert into cn_yhrjz '
			+ '(fkmid,fyear,fperiod,fdate,fgroup,fnum,fexp,fjsfs,fjsh,faccountid2,'
			+ 'facctidside,fdebit,fcredit,fdebitB,fcreditB,FRate,flyr,fdzalready,fdznumber,'
			+ 'fjz,fsource,foldid,foperationdate,fwbbid,fwbamount,fremark,fvoucherid,fgenvch,'
			+ 'fvchyear,fvchperiod,fsourceid,fattachments) '
			+ 'values ('
			+ '@kmid,@year,@period,@date,null,0,@explanation,null,null,null,'
			+ 'null,@debit,@credit,@debit,@credit,1.0,@person,0,-1,'
			+ '0,1,@id,getdate(),0,0,null,null,null,   '
			+ '0,0,null,@attachments'
			+ ')'
		execute sp_executesql @sqlStr, 
			N'@kmid int,@year int,@period int,@date datetime,@explanation varchar(500),
			@debit money,@credit money,@person varchar(255),@id int,@attachments int', 
			@kmid,@year,@period,@date,@explanation,
			@debit,@credit,@person,@id,@attachments
		
	end

commit transaction--�ύ������
set @ret_value='���'
return

fail:
set @ret_value='ʧ��'
rollback tran--�ع������
return


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO



--create table USER_WEIXIN_TOTAL_20160607_2 as
--select * from USER_WEIXIN_TOTAL
--;

declare
v_count number(10);
v_num number(10) := 10068;
begin
  
  declare cursor wxinfo_cur is
  select * from USER_WEIXIN_TOTAL_20160607
  where uwxt_usermark in (
    select uwxt_usermark from USER_WEIXIN_TOTAL_20160607 r
    group by uwxt_usermark
    having count(*) > 1
  )
  order by uwxt_usermark
  ;
  begin
    FOR wxinfo_rec IN wxinfo_cur 
    LOOP
       select count(*) into v_count from USER_WEIXIN_TOTAL_20160607
       where uwxt_usermark = wxinfo_rec.uwxt_usermark;
       
       declare cursor sam_cur is
       select * from USER_WEIXIN_TOTAL_20160607
       where uwxt_usermark = wxinfo_rec.uwxt_usermark
       and rownum < v_count
       ;
       begin
         for sam_rec in sam_cur
         loop
             v_num := v_num + 1;
             if (v_num >= 10110) then
                v_num := 10029;
                v_num := v_num + 1;
             end if;
             update USER_WEIXIN_TOTAL_20160607 set uwxt_usermark = v_num
             where uwxt_id = sam_rec.uwxt_id;
             dbms_output.put_line('uwxt_usermark is: ' || sam_rec.uwxt_usermark || ',count:' || v_num);         
         end loop;
       end;      
                 
    END LOOP;
  end;  
end;
/


       select * from USER_WEIXIN_TOTAL_20160607
       where uwxt_usermark < 10200
       ;
       
  select m.uwxt_usermark ,tmp.* from USER_WEIXIN_TOTAL_20160607 tmp
  inner join 
  (
    select * from USER_WEIXIN_TOTAL
    where uwxt_usermark in (
      select uwxt_usermark from USER_WEIXIN_TOTAL r
      group by uwxt_usermark
      having count(*) > 1
    )
  ) m
  on tmp.uwxt_id = m.uwxt_id
  order by m.uwxt_usermark
  ;
  
  
    select uwxt_usermark from USER_WEIXIN_TOTAL_20160607 r
    group by uwxt_usermark
    having count(*) > 1
    ;

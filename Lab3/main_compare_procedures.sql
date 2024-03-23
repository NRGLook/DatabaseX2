create or replace procedure SYSTEM.cmp_func(prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number; --Переменная для подсчета количества совпадений.
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000); --Переменная для хранения скрипта создания или изменения объекта.
    v_prod_arg_count number; --Переменная для подсчета количества аргументов процедуры.
begin

    --Этот участок кода итерируется по функциям в схеме dev, которые отсутствуют в схеме prod.
    --Для каждой отсутствующей функции выводится сообщение о том, что она отсутствует в схеме prod.
    for funcs in (select distinct name from all_source where owner = UPPER(dev_name) and type = 'FUNCTION'
                        minus select distinct name from all_source where owner = UPPER(prod_name) and type = 'FUNCTION')
    loop
        dbms_output.put_line('No dev #' || funcs.name || '# function in prod schema');
    end loop;

    dbms_output.put_line('--------');

    --Этот участок кода итерируется по функциям в схеме dev. Для каждой функции проверяется ее наличие в схеме prod.
    --Если функция отсутствует в схеме prod, создается ее скрипт с помощью функции dbms_metadata.get_ddl().
    --Затем скрипт заменяется на имя схемы prod и выводится.
    for dev_func in (select object_name, dbms_metadata.get_ddl('FUNCTION', object_name, dev_name) as func_text from all_objects where object_type = 'FUNCTION' and owner = dev_name)
    loop
        dbms_output.put_line('--------');
    
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = dev_func.object_name and owner = prod_name;
        if v_count = 0 then
            v_script := dev_func.func_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;


    --Этот участок кода итерируется по функциям в схеме prod. Для каждой функции проверяется ее наличие в схеме dev.
    --Если функция отсутствует в схеме dev, выводится сообщение о том, что она должна быть удалена из схемы prod.
    for prod_func in (select object_name from all_objects where object_type = 'FUNCTION' and owner = prod_name) loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = prod_func.object_name and owner = dev_name;
        if v_count = 0 then
            dbms_output.put_line('drop function ' || prod_func.object_name);
            -- execute IMMEDIATE 'drop function ' || prod || '.' || prod_func.object_name;
        end if;
    end loop;

    --Этот участок кода итерируется по процедурам в схеме dev. Для каждой процедуры проверяется ее наличие в схеме prod.
    --Если процедура присутствует в обеих схемах, сравниваются их аргументы.
    --Если в схеме prod отсутствует аргумент, выводится сообщение о том, что объявление процедуры в схеме dev некорректно,
    --и предлагается удалить ее из схемы prod. позицией, типом данных и направлением (входной, выходной или ввод-вывод).
    --Если в процедуре prod отсутствует аргумент, выводится сообщение в окне вывода, предлагающее удалить процедуру из схемы prod.
    for dev_func in (select object_name, dbms_metadata.get_ddl('FUNCTION', object_name, dev_name) as proc_text from all_objects where object_type = 'FUNCTION' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'FUNCTION' and object_name = dev_func.object_name and owner = prod_name;
        if v_count > 0 then
            for tmp in (SELECT argument_name, position, data_type, in_out
                FROM all_arguments
                WHERE owner = dev_name
                AND object_name = dev_func.object_name) loop
        
                select count(*) into v_prod_arg_count from all_arguments
                                                            WHERE owner = prod_name
                                                            AND object_name = dev_func.object_name
                                                            and argument_name = tmp.argument_name
                                                            and position = tmp.position
                                                            and data_type = tmp.data_type
                                                            and in_out = tmp.in_out;
                if v_prod_arg_count = 0 then
                    dbms_output.put_line('incorrect dev proc #' || dev_func.object_name || '# declaration in ' || prod_name || 'schema');
                    dbms_output.put_line('drop procedure ' || prod_name || '.' || dev_func.object_name);
                    v_script := dev_func.proc_text;
                    v_script := replace(v_script, dev_name, prod_name);
                    dbms_output.put_line(v_script);
                end if;
              end loop;
        end if;
    end loop;
end;

-------------------------------------------------------------------------------------------------------

create or replace procedure SYSTEM.cmp_indx(prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number; --Переменная для подсчета количества совпадений.
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000); --Переменная для хранения скрипта создания или изменения объекта.
begin

    --Цикл for итерируется по индексам в схеме dev, которые отсутствуют в схеме prod.
    --Для каждого отсутствующего индекса выводится сообщение о том, что он отсутствует в схеме prod.
    for indxs in (select distinct INDEX_NAME from ALL_INDEXES  where TABLE_OWNER = UPPER(dev_name) and INDEX_NAME not like 'SYS%'
                        minus select distinct INDEX_NAME from ALL_INDEXES where TABLE_OWNER = UPPER(prod_name) and INDEX_NAME not like 'SYS%')
    loop
        dbms_output.put_line('No dev #' || indxs.INDEX_NAME || '# index in prod schema');
    end loop;


    --Итерируемся по результатам подзапроса, который выбирает имена объектов индексов и скрипты создания индексов из схемы dev_name
    --Если индекс отсутствует, создается его скрипт с помощью функции dbms_metadata.get_ddl().
    for dev_indx in (select object_name, dbms_metadata.get_ddl('INDEX', object_name, dev_name) as index_text from all_objects where object_type = 'INDEX' and OWNER = dev_name  and object_name not like 'SYS%')
    loop
        dbms_output.put_line('--------');
    
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'INDEX' and object_name = dev_indx.object_name and OWNER = prod_name;
        if v_count = 0 then
            v_script := dev_indx.index_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;

    --Итерируемся по результатам подзапроса, который выбирает имена индексов из схемы prod_name
    --Если индекс отсутствует, выводится сообщение о том, что он должен быть удален из схемы prod_name.
    --Затем индекс удаляется с помощью оператора execute IMMEDIATE.
    for prod_indx in (select object_name from all_objects where object_type = 'INDEX' and owner = prod_name and object_name not like 'SYS%' and object_name not like '%_PK') loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'INDEX' and object_name = prod_indx.object_name and owner = dev_name and object_name not like 'SYS%' and object_name not like '%_PK';
        if v_count = 0 then
            dbms_output.put_line('drop index ' || prod_indx.object_name);
            execute IMMEDIATE 'drop index ' || prod || '.' || prod_indx.object_name;
        end if;
    end loop;
end;

-------------------------------------------------------------------------------------------------------

create or replace procedure SYSTEM.cmp_prc (prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number; --Переменная для подсчета количества совпадений.
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000); --Переменная для хранения скрипта создания или изменения объекта.
    v_prod_arg_count number; --Переменная для подсчета количества аргументов процедуры.
begin

  --Итерация по процедурам в схеме dev, которые отсутствуют в схеме prod.
  --Вывод сообщения о том, что в схеме prod отсутствует процедура.
  for proc in (select object_name
               from all_procedures -- store all funcs and proc
               where owner = dev_name and OBJECT_TYPE='PROCEDURE'
               minus
               select object_name
               from all_procedures
               where owner = prod_name and OBJECT_TYPE='PROCEDURE')
  loop
    dbms_output.put_line('No dev #' || proc.object_name || '# procedure in prod schema');
  end loop;

    --Итерация по процедурам в схеме dev.
    --Проверка наличия процедуры в схеме prod.
    --Если процедура отсутствует в схеме prod, создание ее с помощью скрипта, полученного из схемы dev, с заменой имени схемы на prod.
    for dev_proc in (select object_name, dbms_metadata.get_ddl('PROCEDURE', object_name, dev_name) as proc_text from all_objects where object_type = 'PROCEDURE' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = dev_proc.object_name and owner = prod_name;
        if v_count = 0 then
            v_script := dev_proc.proc_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;

    --Итерация по процедурам в схеме prod.
    --Проверка наличия процедуры в схеме dev.
    --Если процедура отсутствует в схеме dev, выведение сообщения о том, что она должна быть удалена из схемы prod.
    for prod_proc in (select object_name from all_objects where object_type = 'PROCEDURE' and owner = prod_name) loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = prod_proc.object_name and owner = dev_name;
        if v_count = 0 then
            dbms_output.put_line('drop procedure ' || prod_name || '.' || prod_proc.object_name);
        end if;
    end loop;

    --Итерация по процедурам в схеме dev.
    --Проверка наличия процедуры в схеме prod.
    --Если процедура присутствует в схеме prod, сравнение ее аргументов с аргументами процедуры в схеме dev.
    --Если аргументы не совпадают, вывод сообщения о несоответствии и скрипта для исправления несоответствия.
    for dev_proc in (select object_name, dbms_metadata.get_ddl('PROCEDURE', object_name, dev_name) as proc_text from all_objects where object_type = 'PROCEDURE' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = dev_proc.object_name and owner = prod_name;
        if v_count > 0 then
            for tmp in (SELECT argument_name, position, data_type, in_out
                FROM all_arguments
                WHERE owner = dev_name
                AND object_name = dev_proc.object_name) loop
        
                select count(*) into v_prod_arg_count from all_arguments
                                                            WHERE owner = prod_name
                                                            AND object_name = dev_proc.object_name
                                                            and argument_name = tmp.argument_name
                                                            and position = tmp.position
                                                            and data_type = tmp.data_type
                                                            and in_out = tmp.in_out;
                if v_prod_arg_count = 0 then
                    dbms_output.put_line('incorrect dev proc #' || dev_proc.object_name || '# declaration in ' || prod_name || 'schema');
                    dbms_output.put_line('drop procedure ' || prod_name || '.' || dev_proc.object_name);
                    v_script := dev_proc.proc_text;
                    v_script := replace(v_script, dev_name, prod_name);
                    dbms_output.put_line(v_script);
                end if;
              end loop;
        end if;
    end loop;
end;

-------------------------------------------------------------------------------------------------------

create or replace procedure SYSTEM.cmp_tbl (prod in varchar2, dev in varchar2
) authid current_user is
    v_dev_table_name all_tables.table_name%type;
    v_table_count integer; --Переменная для подсчета количества совпадений.
    v_dev_col_count integer; --количество столбцов в таблице dev.
    v_prod_col_count integer;
    v_script varchar2(4000); --Переменная для хранения скрипта создания или изменения объекта.DDL
    v_count_circular number; --количество циклических ссылок.
    v_missing_cols_in_prod_count number; --количество отсутствующих столбцов в схеме prod.
    prod_name varchar2(100) := upper(prod); --Имя схемы prod в верхнем регистре.
    dev_name varchar2(100) := upper(dev);
    v_sql varchar2(4000); --Переменная для хранения SQL-запроса.
    v_fk_cons_name varchar2(30); --имя ограничения внешнего ключа
    v_table_name varchar2(30);
    v_column_name varchar2(30);
    ddl_script varchar2(10000); --Переменная для хранения скрипта создания или изменения ограничения.
    TYPE string_list_t IS --Тип данных для хранения списка строк.
        TABLE OF VARCHAR2(100);
    dev_constraints_set  string_list_t; --Множество для хранения имен ограничений в схеме dev.
    prod_constraints_set string_list_t;

    type table_list_type is table of varchar2(100); --Список имен таблиц в схеме dev.
    v_table_list table_list_type := table_list_type();
    v_processed_tables table_list_type := table_list_type(); -- Список имен обработанных таблиц.
    cur_dev_table_name varchar2(100); --Переменная для хранения имени таблицы dev в курсоре.

        --Курсор для получения дочерних таблиц, связанных с таблицей dev
    cursor cur_fk_cons is
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'R' and cols.owner = dev_name;

        --Курсор для получения первичных ключей в таблице dev.
    cursor cur_pk_cons is
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'P' and cols.owner = dev_name;

    --Рекурсивная процедура для обработки таблиц и их дочерних таблиц
    procedure process_table(
    p_table_name in varchar2
  ) is
    cursor fk_cur is --Курсор, используемый для получения дочерних таблиц для данной таблицы.
      select cc.table_name as child_table
      from all_constraints pc
      join all_constraints cc on pc.constraint_name = cc.r_constraint_name
      where pc.constraint_type = 'P'
      and cc.constraint_type = 'R'
      and pc.owner = dev_name
      and cc.owner = dev_name
      and pc.table_name = p_table_name;

    v_child_table varchar2(100); --имя дочерней таблицы.
  begin
    if p_table_name not member of v_processed_tables then
      v_processed_tables.extend;
      v_processed_tables(v_processed_tables.last) := p_table_name;

      for fk_rec in fk_cur loop
        v_child_table := fk_rec.child_table;
        process_table(v_child_table);
      end loop;

      v_table_list.extend;
      v_table_list(v_table_list.last) := p_table_name;
    end if;
  end process_table;

begin

    --Поиск циклических ссылок: Цикл итерируется по таблицам в схеме dev.
    --Для каждой таблицы выполняется запрос для получения дочерних таблиц, связанных с таблицей dev.
    --Если дочерние таблицы связаны с таблицей dev, это означает, что существует циклическая ссылка.
    select count(*) into v_count_circular from (with table_hierarchy as (select child_owner, child_table, parent_owner, parent_table
                                         from (select owner child_owner, table_name child_table, r_owner parent_owner, r_constraint_name constraint_name
                                               from all_constraints where constraint_type = 'R' and owner = 'DEV')
                                                  join (select owner parent_owner, constraint_name, table_name parent_table
                                                        from all_constraints where constraint_type = 'P' and owner = 'DEV')
                                                       using (parent_owner, constraint_name))
                select distinct child_owner, child_table
                from (select *
                      from table_hierarchy where (child_owner, child_table) in (select parent_owner, parent_table
                                                           from table_hierarchy)) a
                where connect_by_iscycle = 1
                connect by nocycle (prior child_owner, prior child_table) = ((parent_owner, parent_table))
                );

    -- поиск dev таблицы которой нет в prod
    if v_count_circular > 0 then
        dbms_output.put_line('circular foreign key reference detected in DEV schema.');
        -- return;
    end if;

    -- итерация по всем таблицам в схеме dev_name и вызова процедуры process_table для каждой таблицы.
    for table_rec in (select table_name from all_tables where owner = dev_name order by table_name) loop
        process_table(table_rec.table_name);
    end loop;
    
    

    -- вывод нехватающих столбцов
    -- итерируется в обратном порядке от последнего элемента списка v_table_list до первого элемента.
    -- сравнение каждой таблицы в схеме dev с соответствующей таблицей в схеме prod.
    for i in reverse 1..v_table_list.count loop
    -- for dev_tab_rec in (select table_name from all_tables where owner = dev_name) loop
        v_dev_table_name := v_table_list(i);

        -- подсчет количества таблиц в схеме prod с тем же именем, что и v_dev_table_name.
        select count(*) into v_table_count
        from all_tables
        where owner = prod_name
        and table_name = v_dev_table_name;

        if v_table_count = 0 then
            dbms_output.put_line('No dev table #' || v_dev_table_name || '# is in prod schema.');
        else
            -- compare table structure
            select count(*) into v_dev_col_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name;

            select count(*) into v_prod_col_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name;

            -- dbms_output.put_line('table ' || v_dev_table_name || ' dev: ' || to_char(v_dev_col_count));
            -- dbms_output.put_line('table ' || v_dev_table_name || ' prod: ' || to_char(v_prod_col_count));

            if v_dev_col_count > v_prod_col_count then
                dbms_output.put_line('Table ' || v_dev_table_name || ' has ' || (v_dev_col_count - v_prod_col_count) || ' more columns in development schema.');
            end if;

            for dev_col_rec in (select column_name from all_tab_cols where owner = dev_name and table_name = v_dev_table_name and column_name not like 'SYS%') loop
                select count(*) into v_table_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name and column_name = dev_col_rec.column_name;

                if v_table_count = 0 then
                    dbms_output.put_line('No dev column #' || dev_col_rec.column_name || '# in dev table ' || v_dev_table_name || ' in production schema.');
                end if;
            end loop;
        end if;
    end loop;



    -- итерация по списку таблиц в обратном порядке и генерация скриптов для синхронизации структуры таблиц между схемами dev и prod.
    for i in reverse 1..v_table_list.count loop
    --for dev_tab_rec in (select table_name from all_tables where owner = dev_name) loop
            -- v_dev_table_name := dev_tab_rec.table_name;
            v_dev_table_name := v_table_list(i);

            select count(*) into v_table_count from all_tables where owner = prod_name and table_name = v_dev_table_name;

            if v_table_count = 0 then
                -- no dev table in prod, gen script
                select dbms_metadata.get_ddl('TABLE', v_dev_table_name, dev_name) into v_script from dual;
                v_script := replace(v_script, dev_name, prod_name);
                dbms_output.put_line(v_script);
            else
                -- cmpr table struct
                select count(*) into v_dev_col_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name;

                select count(*) into v_prod_col_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name;

                -- if v_dev_col_count > v_prod_col_count then
                    -- код для добавления нехватающих cols
                    v_missing_cols_in_prod_count := 0;
                    v_script := 'alter table ' || prod_name || '.' || v_dev_table_name || ' add (';
                    for dev_col_rec in (select column_name, data_type, data_length, data_precision, data_scale
                                        from all_tab_cols where owner = dev_name and table_name = v_dev_table_name) loop
                        select count(*) into v_table_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name and column_name = dev_col_rec.column_name;


                        if v_table_count = 0 and dev_col_rec.column_name not like 'SYS%' then
                            v_missing_cols_in_prod_count := v_missing_cols_in_prod_count + 1;
                            v_script := v_script || dev_col_rec.column_name || ' ' || dev_col_rec.data_type;
                            if dev_col_rec.data_type in ('VARCHAR2', 'NVARCHAR2', 'RAW') then
                                v_script := v_script || '(' || dev_col_rec.data_length || ')';
                            elsif dev_col_rec.data_type in ('NUMBER') then
                                if (dev_col_rec.data_precision is not null) then
                                    v_script := v_script || '(' || dev_col_rec.data_precision || ')';
                                end if;
                                if (dev_col_rec.data_scale is not null) then
                                    v_script := v_script || ', ' || dev_col_rec.data_scale || ')';
                                end if;
                            end if;
                            v_script := v_script || ', ';
                        end if;
                    end loop;
                    v_script := rtrim(v_script, ', ') || ')';
                    if (v_missing_cols_in_prod_count > 0) then
                        dbms_output.put_line(v_script);
                    end if;
                -- else
                    -- код для удаления лишних cols
                    for prod_col_rec in (select column_name, data_type, data_length, data_precision, data_scale
                                        from all_tab_cols where owner = prod_name and table_name = v_dev_table_name and column_name not like 'SYS%') loop
                        select count(*) into v_table_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name and column_name = prod_col_rec.column_name;

                        if v_table_count = 0 then
                            v_script := 'alter table ' || prod_name || '.' || v_dev_table_name || ' drop column ' || upper(prod_col_rec.column_name);
                            dbms_output.put_line(v_script);
                        end if;
                    end loop;
                -- end if;
            end if;
        end loop;


        -- проверка на лишние таблицы в prod
        for prod_tab_rec in (select table_name from all_tables where owner = prod_name) loop
            select count(*) into v_table_count from all_tables where owner = dev_name and table_name = prod_tab_rec.table_name;

            if v_table_count = 0 then
                dbms_output.put_line('drop table ' || prod_name || '.' || prod_tab_rec.table_name);
            end if;
        end loop;
        

        
        -- drop constraint from prod
        -- итерации по списку таблиц в обратном порядке и удаления ограничений внешнего ключа из таблиц в схеме prod,
        -- которые больше не существуют в соответствующих таблицах в схеме dev.
        for i in reverse 1..v_table_list.count loop
        v_dev_table_name := v_table_list(i);
        for rec_fk_cons in (
            select distinct cons.constraint_name, cols.table_name, cols.column_name
            from all_constraints cons
            join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
            where cols.owner = prod_name and cols.table_name = v_dev_table_name
        ) loop
        begin
            select rec_fk_cons.constraint_name, rec_fk_cons.table_name, rec_fk_cons.column_name
            into v_fk_cons_name, v_table_name, v_column_name
            from dual
            where not exists (
                select 1
                from all_constraints cons
                join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name and cols.column_name = v_column_name
                where cols.owner = dev_name and cols.table_name = v_table_name and cons.constraint_name = v_fk_cons_name
            );
    
            if v_fk_cons_name is not null and v_fk_cons_name not like 'SYS%' then
                -- drop foreign key constraint from prod_schema
                v_sql := 'alter table ' || prod_name || '.' || v_table_name ||
                         ' drop constraint ' || v_fk_cons_name;
                dbms_output.put_line(v_sql);
            end if;
        exception
           when others then
           if rec_fk_cons.constraint_name not like 'SYS%' then
            dbms_output.put_line('Error removing foreign key ' || rec_fk_cons.constraint_name || ' from table ' || rec_fk_cons.table_name || ': ' || sqlerrm);
            end if;
        end;
        end loop;
        
    end loop;
    
    -- add missing constr
    -- итерации по списку таблиц в обратном порядке и генерации скриптов для добавления ограничений к таблицам
    -- в схеме prod на основе ограничений, определенных в таблицах в схеме dev.
    for i in reverse 1..v_table_list.count loop
        v_dev_table_name := v_table_list(i);
    
        SELECT constraint_name BULK COLLECT INTO dev_constraints_set
            FROM all_constraints
            WHERE owner = dev_name
                AND table_name = v_dev_table_name
                AND constraint_name NOT LIKE 'SYS%'
            ORDER BY constraint_name;
            SELECT constraint_name BULK COLLECT INTO prod_constraints_set
            FROM all_constraints
            WHERE owner = prod_name
                AND table_name = v_dev_table_name
                AND constraint_name NOT LIKE 'SYS%'
            ORDER BY constraint_name;


            -- Проверяется, существует ли ограничение с тем же именем в коллекции prod_constraints_set.
            -- Если ограничения не существует, это означает, что оно было удалено из схемы prod и его необходимо добавить обратно.
            -- Если ограничение не существует в схеме prod, генерируется скрипт для добавления ограничения в схему prod.
            -- Скрипт генерируется с помощью встроенной функции dbms_metadata.get_ddl.
            -- Генерируемый скрипт выводится в выходные данные с помощью процедуры dbms_output.put_line.
            FOR i IN 1..dev_constraints_set.count LOOP
                IF dev_constraints_set(i) NOT MEMBER OF prod_constraints_set THEN
                    DECLARE
                        ddl_script      CLOB;
                        constraint_type VARCHAR2(20);
                    BEGIN
                        SELECT constraint_type INTO constraint_type
                        FROM all_constraints
                        WHERE owner = dev_name
                            AND table_name = v_dev_table_name
                            AND constraint_name = dev_constraints_set(i);
                        -- 'REF_CONSTRAINT' для ссылочных ограничений и 'CONSTRAINT' для других типов ограничений.
                        ddl_script := dbms_metadata.get_ddl(CASE WHEN constraint_type = 'R' THEN 'REF_CONSTRAINT' ELSE 'CONSTRAINT' END, dev_constraints_set(i), dev_name);
                        ddl_script:=replace(ddl_script, dev_name, prod_name);
                        dbms_output.put_line(ddl_script);
                    END;
                END IF;
            END LOOP;
        end loop;
end;


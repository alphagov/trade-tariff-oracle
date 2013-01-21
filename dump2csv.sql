-- Ensure that the named DIRECTORY object is defined for later use when exporting data.
CREATE OR REPLACE DIRECTORY TMP_EXPORTS as '/tmp/import_data';

-- Create the procedure used to dump a table to CSV.
create or replace procedure dump_table_to_csv( p_tname in varchar2 )
  is
      l_output        utl_file.file_type;
      l_theCursor     integer default dbms_sql.open_cursor;
      l_columnValue   varchar2(4000);
      l_status        integer;
      l_query         varchar2(1000)
                       default 'select * from ' || p_tname;
      l_colCnt        number := 0;
      l_separator     varchar2(1);
      l_descTbl       dbms_sql.desc_tab;
  begin
      -- Note that this takes the name of a directory object. Not the name of a directory!
      l_output := utl_file.fopen( 'TMP_EXPORTS', p_tname || '.csv', 'w', 32767 );
      execute immediate 'alter session set nls_date_format=''yyyy-mm-dd"T"hh24:mi:ss'' ';

      dbms_sql.parse(  l_theCursor,  l_query, dbms_sql.native );
      dbms_sql.describe_columns( l_theCursor, l_colCnt, l_descTbl );
  
      for i in 1 .. l_colCnt loop
          utl_file.put( l_output, l_separator || '"' || l_descTbl(i).col_name || '"');
          dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
          l_separator := ',';
      end loop;
      utl_file.new_line( l_output );
  
      l_status := dbms_sql.execute(l_theCursor);
  
      while ( dbms_sql.fetch_rows(l_theCursor) > 0 ) loop
          l_separator := '';
          for i in 1 .. l_colCnt loop
              dbms_sql.column_value( l_theCursor, i, l_columnValue );
              utl_file.put( l_output, l_separator || '"' || replace(l_columnValue, '"', '""') || '"');
              l_separator := ',';
          end loop;
          utl_file.new_line( l_output );
      end loop;
      dbms_sql.close_cursor(l_theCursor);
      utl_file.fclose( l_output );
  
      execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
  exception
      when others then
          execute immediate 'alter session set nls_date_format=''dd-MON-yy'' ';
          raise;
  end;
/
quit;
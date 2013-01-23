-- Script which exports the desired tables from the Oracle database into CSV format.
-- Add table names to this as required.
exec dump_table_to_csv('COMM');
exec dump_table_to_csv('MFCM');
exec dump_table_to_csv('TAME');
exec dump_table_to_csv('TAMF');
exec dump_table_to_csv('TBL9');
quit;
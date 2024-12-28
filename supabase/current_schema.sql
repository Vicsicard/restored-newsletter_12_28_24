-- Get detailed information about all tables and their columns
SELECT 
    t.table_name,
    c.column_name,
    c.data_type,
    c.column_default,
    c.is_nullable,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    c.udt_name,
    tc.constraint_type,
    cc.table_name as referenced_table,
    cc.column_name as referenced_column
FROM 
    information_schema.tables t
    JOIN information_schema.columns c ON t.table_name = c.table_name
    LEFT JOIN information_schema.table_constraints tc 
        ON tc.table_name = t.table_name 
        AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE')
    LEFT JOIN information_schema.constraint_column_usage cc
        ON tc.constraint_name = cc.constraint_name
WHERE 
    t.table_schema = 'public'
    AND t.table_type = 'BASE TABLE'
    AND t.table_name IN (
        'companies',
        'compiled_newsletters',
        'contacts',
        'csv_uploads',
        'image_generation_history',
        'industry_insights',
        'newsletter_contacts',
        'newsletter_sections',
        'newsletters'
    )
ORDER BY 
    t.table_name,
    c.ordinal_position;

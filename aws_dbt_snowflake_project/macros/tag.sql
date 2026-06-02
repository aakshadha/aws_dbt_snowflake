{% macro tag(column) %}
   
    CASE
        WHEN {{column}} < 100 THEN 'low'
        WHEN {{column}} < 200 THEN 'medium'
        ELSE 'high'
    END
    {% endmacro %}
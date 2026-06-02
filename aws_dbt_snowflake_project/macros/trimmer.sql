{% macro trimmer(column, node) %}
    TRIM({{ column | trim | upper  }})
{% endmacro %}
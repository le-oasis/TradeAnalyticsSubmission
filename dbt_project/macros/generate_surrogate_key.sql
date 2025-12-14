-- macros/generate_surrogate_key.sql
-- Fallback if dbt_utils not available

{% macro generate_surrogate_key(field_list) %}
    {% if execute %}
        {{ return(dbt_utils.generate_surrogate_key(field_list)) }}
    {% else %}
        md5(concat_ws('||', {% for field in field_list %}{{ field }}{% if not loop.last %}, {% endif %}{% endfor %}))
    {% endif %}
{% endmacro %}

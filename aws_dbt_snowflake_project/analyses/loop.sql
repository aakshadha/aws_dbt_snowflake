{% set col = ['nights_booked', 'booking_id', 'booking_amount'] %}

Select 
{% for col in col %}
    {{ col }}
    {% if not loop.last %},{% endif %}
{% endfor %}
from {{ ref ( 'bronze_bookings' ) }}
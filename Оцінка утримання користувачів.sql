select * from cohort_users_raw
limit 10;

-----


select * from cohort_events_raw 
limit 10;

-----


with cleaned_users as (
select 
  u.user_id,
  u.full_name,
  u.email,
  u.country,
  u.signup_source,
  u.signup_device,
  u.promo_signup_flag,
    case
       when u.signup_datetime is null then null 
          else to_date(
            case
               when regexp_replace(trim(u.signup_datetime), '\s.*$', '') 
                         ~ '^[0-9]{4}[-/.][0-9]{2}[-/.][0-9]{2}$'
               then replace(replace(replace(trim(u.signup_datetime), '.', '-'), '/', '-'), ' ', '')
               else null
               end,
                'YYYY-MM-D'
                )
       end as signup_ts
from cohort_users_raw u
)
select *
from cleaned_users;

-----


with cleaned_events as(
select
      e.event_id,
      e.user_id,
      e.event_type,
      e.revenue,
  case
      when e.event_datetime is null then null 
      else to_date(
          case
          when regexp_replace(trim(e.event_datetime), '\s.*$', '') 
                         ~ '^[0-9]{4}[-/.][0-9]{2}[-/.][0-9]{2}$'
          then replace(replace(replace(trim(e.event_datetime), '.', '-'), '/', '-'), ' ', '')
          else null
          end,
             'YYYY-MM-DD'
            )
       end as event_ts
from cohort_events_raw e
)
select *
from cleaned_events;

-----


with users_parsed as (
select
      u.user_id,
      u.full_name,
      u.email,
      u.country,
      u.signup_source,
      u.signup_device,
      u.promo_signup_flag,
   case
       when u.signup_datetime is null then null 
       else to_date(
           case
           when regexp_replace(trim(u.signup_datetime), '\s.*$', '') 
                         ~ '^[0-9]{4}[-/.][0-9]{2}[-/.][0-9]{2}$'
           then replace(replace(replace(trim(u.signup_datetime), '.', '-'), '/', '-'), ' ', '')
           else null
           end,
            'YYYY-MM-DD'
            )
end as signup_ts
from cohort_users_raw u
),
events_parsed as(
select
     e.event_id,
     e.user_id,
     e.event_type,
     e.revenue,
     case
       when e.event_datetime is null then null 
       else to_date(
          case
          when regexp_replace(trim(e.event_datetime), '\s.*$', '') 
               ~ '^[0-9]{4}[-/.][0-9]{2}[-/.][0-9]{2}$'
          then replace(replace(replace(trim(e.event_datetime), '.', '-'), '/', '-'), ' ', '')
          else null
          end,
             'YYYY-MM-DD'
              )
          end event_ts
from cohort_events_raw e
)
select
    u.user_id,
    u.promo_signup_flag,
    date_trunc('month', u.signup_ts)::date as cohort_month,
    date_trunc('month', e.event_ts)::date as activity_month,
    e.event_type,
    (
      (extract(year from e.event_ts) * 12 + extract(month from e.event_ts))
       - (extract(year from u.signup_ts) * 12 + extract(month from u.signup_ts))
    ) as month_offset
from users_parsed u
join events_parsed e
on u.user_id = e.user_id
where u.signup_ts is not null
and e.event_ts is not null
and e.event_type is not null
and e.event_type <> 'test_event';

-----



with users_parsed as (
select
      u.user_id,
      u.promo_signup_flag,
    case
      when u.signup_datetime is null then null 
    else to_date(
         left(
               replace(replace(replace(trim(u.signup_datetime), '.', '-'), '/', '-'), ' ', ''),10
                ),
                'DD-MM-YYYY'   
            )
      end as signup_ts
from cohort_users_raw u
),
events_parsed as(
select
      e.event_id,
      e.user_id,
      e.event_type,
case
    when e.event_datetime is null then null
    else to_date(
         left(
                replace(replace(replace(trim(e.event_datetime), '.', '-'), '/', '-'), ' ',''),10
                ),
                'DD-MM-YYYY'
            )
    end as event_ts
from cohort_events_raw e
),
joined as (
select
      u.user_id,
      u.promo_signup_flag,
      date_trunc('month', u.signup_ts)::date as cohort_month,
      date_trunc('month', e.event_ts)::date as activity_month,
      e.event_type,
        (
          (extract(year from e.event_ts) * 12 + extract(month from e.event_ts))
            - (extract(year from u.signup_ts) * 12 + extract(month from u.signup_ts))
        ) as month_offset
from users_parsed u
join events_parsed e on u.user_id = e.user_id
where u.signup_ts is not null
     and e.event_ts is not null
     and e.event_type is not null
     and e.event_type <> 'test_event'
     and e.event_ts >= u.signup_ts 
     )
select
    promo_signup_flag,
    cohort_month,
    month_offset,
    count(distinct user_id) as users_total
from joined
where activity_month between date '2025-01-01' and date '2025-06-30'
group by promo_signup_flag, cohort_month, month_offset
order by promo_signup_flag, cohort_month, month_offset;




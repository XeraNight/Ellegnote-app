-- KSIS "Detail páru" shows "Posledná zmena" (the date the points last changed, i.e. the last scoring
-- competition), not the date the class started. Name the columns after what KSIS really publishes.
-- Applied by hand on 9. 10. 2026.
alter table public.user_couples rename column stt_class_since to stt_last_change;
alter table public.user_couples rename column lat_class_since to lat_last_change;

--
-- Beach cleanup upcoming event data
-- Source: https://ecolife2.moenv.gov.tw/BeachCleanup/Home/JoinCleanUp
-- Generated at: 2026-05-02 02:49:08+0000
--

CREATE TABLE IF NOT EXISTS public.beach_cleanup_events (
    event_id text PRIMARY KEY,
    city text,
    district text,
    event_name text,
    organizer text,
    start_time timestamp with time zone,
    location text,
    rendezvous text,
    event_url text,
    photo_url text,
    scraped_at timestamp with time zone DEFAULT NOW()
);

TRUNCATE TABLE public.beach_cleanup_events;

COPY public.beach_cleanup_events (event_id, city, district, event_name, organizer, start_time, location, rendezvous, event_url, photo_url, scraped_at) FROM stdin;
795a9a3c-2f5b-42a4-ac3a-7d58fbf6de09	新北市	\N	2026 安聯人壽 x RE-THINK 淨灘	社團法人台灣重新思考環境教育協會	2026-05-02 15:00:00+0800	https://maps.app.goo.gl/VQzQab3scCAvh5KE7	https://maps.app.goo.gl/VQzQab3scCAvh5KE7	https://ecolife2.moenv.gov.tw/Coastal/SeaCleanEvent/SeaCleanEventApply.aspx?EventID=795a9a3c-2f5b-42a4-ac3a-7d58fbf6de09	\N	2026-05-02 02:49:08+0000
4f4952cd-4c22-4fc2-9c99-4123978dd8c4	新北市	淡水區	一起淨灘趣	國泰人壽 昌峰通訊處	2026-05-09 10:00:00+0800	淡水沙崙海灘	淡水沙崙海灘	https://ecolife2.moenv.gov.tw/Coastal/SeaCleanEvent/SeaCleanEventApply.aspx?EventID=4f4952cd-4c22-4fc2-9c99-4123978dd8c4	\N	2026-05-02 02:49:08+0000
7ce2d0f5-115c-4bb8-b606-cc77c3deae85	新北市	萬里區	藥師淨灘，疼惜海洋	台北市藥師公會	2026-05-24 10:00:00+0800	翡翠灣	翡翠灣	https://ecolife2.moenv.gov.tw/Coastal/SeaCleanEvent/SeaCleanEventApply.aspx?EventID=7ce2d0f5-115c-4bb8-b606-cc77c3deae85	\N	2026-05-02 02:49:08+0000
\.

CREATE INDEX IF NOT EXISTS beach_cleanup_events_city_start_time_idx
ON public.beach_cleanup_events (city, start_time);

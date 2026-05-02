--
-- Metro Taipei beach cleanup upcoming events component seed data
--

BEGIN;

SELECT pg_catalog.setval('public.contributors_id_seq', (SELECT COALESCE(MAX(id), 0) FROM public.contributors), true);

INSERT INTO public.contributors (
    user_id, user_name, image, link, identity, description, include, created_at, updated_at
)
SELECT
    'moenv',
    '環境部環境管理署',
    'text',
    'https://ecolife2.moenv.gov.tw/BeachCleanup/Home/JoinCleanUp#apply-cleanup-info',
    '資料來源',
    '提供海岸清理與淨灘活動公開資訊。',
    false,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM public.contributors WHERE user_id = 'moenv'
);

UPDATE public.contributors
SET image = 'text',
    updated_at = NOW()
WHERE user_id = 'moenv';

INSERT INTO public.components ("index", name)
VALUES ('beach_cleanup_events', '雙北淨灘活動快訊')
ON CONFLICT ("index") DO UPDATE
SET name = EXCLUDED.name;

DELETE FROM public.query_charts
WHERE "index" = 'beach_cleanup_events'
  AND city = 'metrotaipei';

DELETE FROM public.component_charts
WHERE "index" = 'beach_cleanup_events';

INSERT INTO public.component_charts ("index", color, types, unit)
VALUES (
    'beach_cleanup_events',
    ARRAY['#55C7F2', '#F8CF58', '#68C174', '#E170A6'],
    ARRAY['BeachCleanupEventsChart'],
    '場'
);

INSERT INTO public.query_charts (
    "index", history_config, map_config_ids, map_filter, time_from, time_to,
    update_freq, update_freq_unit, source, short_desc, long_desc, use_case,
    links, contributors, created_at, updated_at, query_type, query_chart,
    query_history, city
)
VALUES (
    'beach_cleanup_events',
    NULL,
    ARRAY[]::integer[],
    '{}'::json,
    'current', NULL, 6, 'hour',
    '環境部環境管理署海岸清理平台',
    '顯示雙北近期可參與的淨灘活動',
    '本組件定期從環境部環境管理署海岸清理平台抓取尚未過期的淨灘活動，篩選臺北市與新北市活動，整理活動名稱、活動時間、活動地點、集合點、主辦單位與官方報名連結。畫面上方會顯示目前選取的活動詳情，下方活動按鈕可切換不同場次並快速前往報名頁。',
    '一般民眾可以用它快速找到近期可參與的環境行動，不需要自己到各網站搜尋活動。對永續環境儀表板而言，這個組件補足了「民眾參與」面向，讓儀表板不只呈現固定設施、回收點或統計數據，也能呈現當下可以實際參加的環境行動。',
    ARRAY['https://ecolife2.moenv.gov.tw/BeachCleanup/Home/JoinCleanUp#apply-cleanup-info'],
    ARRAY['moenv'],
    '2026-05-02 00:00:00+00',
    NOW(),
    'three_d',
    $$
    SELECT
        '近期活動' AS x_axis,
        event_name AS y_axis,
        concat_ws(
            '｜',
            city,
            to_char(start_time AT TIME ZONE 'Asia/Taipei', 'YYYY-MM-DD HH24:MI'),
            COALESCE(NULLIF(location, ''), '未提供地點'),
            COALESCE(NULLIF(rendezvous, ''), '未提供集合點'),
            COALESCE(NULLIF(organizer, ''), '未提供主辦單位'),
            event_url
        ) AS icon,
        GREATEST(
            0,
            CEIL(EXTRACT(EPOCH FROM ((start_time AT TIME ZONE 'Asia/Taipei') - (NOW() AT TIME ZONE 'Asia/Taipei'))) / 86400.0)
        )::int AS data
    FROM public.beach_cleanup_events
    WHERE city IN ('臺北市', '新北市')
      AND start_time >= NOW() - INTERVAL '12 hours'
    ORDER BY start_time ASC
    LIMIT 8
    $$,
    NULL,
    'metrotaipei'
);

DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id FROM public.components WHERE "index" = 'beach_cleanup_events';
    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" = 'sustainable_env_newtpe'
          AND NOT (v_id = ANY(components));
    END IF;
END $$;

SELECT pg_catalog.setval('public.components_id_seq', (SELECT COALESCE(MAX(id), 0) FROM public.components), true);

COMMIT;

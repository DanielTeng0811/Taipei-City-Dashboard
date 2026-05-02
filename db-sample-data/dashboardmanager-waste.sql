--
-- Waste statistics component seed data
--

BEGIN;

INSERT INTO public.components ("index", name)
VALUES ('waste_statistics', '一般廢棄物清理情況')
ON CONFLICT ("index") DO UPDATE
SET name = EXCLUDED.name;

INSERT INTO public.component_charts ("index", color, types, unit)
VALUES (
    'waste_statistics',
    ARRAY['#24B0DD', '#56B96D', '#F8CF58'],
    ARRAY['ColumnChart', 'BarPercentChart'],
    '公克/人日'
)
ON CONFLICT ("index") DO UPDATE
SET color = EXCLUDED.color,
    types = EXCLUDED.types,
    unit = EXCLUDED.unit;

DELETE FROM public.query_charts
WHERE "index" = 'waste_statistics'
  AND city IN ('taipei', 'metrotaipei');

INSERT INTO public.query_charts (
    "index",
    history_config,
    map_config_ids,
    map_filter,
    time_from,
    time_to,
    update_freq,
    update_freq_unit,
    source,
    short_desc,
    long_desc,
    use_case,
    links,
    contributors,
    created_at,
    updated_at,
    query_type,
    query_chart,
    query_history,
    city
)
VALUES
(
    'waste_statistics',
    NULL,
    NULL,
    NULL,
    'static',
    NULL,
    0,
    '',
    '環境部資料',
    '一般廢棄物處理統計',
    '呈現最新年度一般垃圾清運、資源回收與廚餘回收的人均每日處理量。',
    '可用於觀察臺北市一般廢棄物處理結構，評估垃圾減量與資源回收成效。',
    ARRAY['https://data.moenv.gov.tw/dataset/detail/STAT_P_45']::text[],
    ARRAY['doit'],
    NOW(),
    NOW(),
    'three_d',
    $sql$
WITH latest AS (
    SELECT MAX(year) AS year
    FROM public.waste_statistics
),
selected AS (
    SELECT
        '臺北市' AS x_axis,
        garbageclearance,
        garbagerecycled,
        foodwastesrecycled
    FROM public.waste_statistics
    WHERE year = (SELECT year FROM latest)
      AND county = 'Taipei'
)
SELECT x_axis, y_axis, data
FROM (
    SELECT x_axis, '一般垃圾清運' AS y_axis, ROUND(garbageclearance)::int AS data, 1 AS sort_order FROM selected
    UNION ALL
    SELECT x_axis, '資源回收' AS y_axis, ROUND(garbagerecycled)::int AS data, 2 AS sort_order FROM selected
    UNION ALL
    SELECT x_axis, '廚餘回收' AS y_axis, ROUND(foodwastesrecycled)::int AS data, 3 AS sort_order FROM selected
) result
ORDER BY sort_order
    $sql$,
    NULL,
    'taipei'
),
(
    'waste_statistics',
    NULL,
    NULL,
    NULL,
    'static',
    NULL,
    0,
    '',
    '環境部資料',
    '一般廢棄物處理統計',
    '呈現最新年度臺北市、新北市與其他縣市一般垃圾清運、資源回收與廚餘回收的人均每日處理量。',
    '可用於比較臺北市、新北市與其他縣市一般廢棄物處理結構，評估垃圾減量與資源回收成效。',
    ARRAY['https://data.moenv.gov.tw/dataset/detail/STAT_P_45']::text[],
    ARRAY['doit'],
    NOW(),
    NOW(),
    'three_d',
    $sql$
WITH latest AS (
    SELECT MAX(year) AS year
    FROM public.waste_statistics
),
selected AS (
    SELECT
        CASE county
            WHEN 'Taipei' THEN '臺北市'
            WHEN 'NewTaipei' THEN '新北市'
            ELSE '其他縣市'
        END AS x_axis,
        CASE county
            WHEN 'Taipei' THEN 1
            WHEN 'NewTaipei' THEN 2
            ELSE 3
        END AS city_order,
        garbageclearance,
        garbagerecycled,
        foodwastesrecycled
    FROM public.waste_statistics
    WHERE year = (SELECT year FROM latest)
)
SELECT x_axis, y_axis, data
FROM (
    SELECT x_axis, city_order, '一般垃圾清運' AS y_axis, ROUND(garbageclearance)::int AS data, 1 AS sort_order FROM selected
    UNION ALL
    SELECT x_axis, city_order, '資源回收' AS y_axis, ROUND(garbagerecycled)::int AS data, 2 AS sort_order FROM selected
    UNION ALL
    SELECT x_axis, city_order, '廚餘回收' AS y_axis, ROUND(foodwastesrecycled)::int AS data, 3 AS sort_order FROM selected
) result
ORDER BY city_order, sort_order
    $sql$,
    NULL,
    'metrotaipei'
);

DO $$
DECLARE
    v_id integer;
BEGIN
    SELECT id::integer INTO v_id
    FROM public.components
    WHERE "index" = 'waste_statistics';

    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" = 'sustainable_env_tpe'
          AND NOT (v_id = ANY(components));

        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" = 'sustainable_env_newtpe'
          AND NOT (v_id = ANY(components));
    END IF;
END $$;

SELECT pg_catalog.setval(
    'public.components_id_seq',
    (SELECT COALESCE(MAX(id), 0) FROM public.components),
    true
);

COMMIT;

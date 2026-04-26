-- eco 15min manager
DELETE FROM public.query_charts WHERE index = 'eco_living_15min';
DELETE FROM public.component_charts WHERE index = 'eco_living_15min';
DELETE FROM public.component_maps WHERE index = 'eco_living_15min_taipei';
DELETE FROM public.component_maps WHERE index = 'eco_living_15min_metrotaipei';
DELETE FROM public.components WHERE index = 'eco_living_15min';

INSERT INTO public.components (id, index, name)
VALUES (310, 'eco_living_15min', '15分鐘無痕生活圈');

INSERT INTO public.component_charts (index, color, types, unit)
VALUES (
    'eco_living_15min',
    ARRAY['#3CB371', '#F8CF58', '#5CA8D8', '#8B4513'],
    ARRAY['DistrictChart', 'ColumnChart'],
    '個'
);

INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
VALUES (
    150,
    'eco_living_15min_taipei',
    '無痕生活點位(臺北)',
    'circle',
    'geojson',
    NULL,
    NULL,
    '{"circle-radius":4,"circle-color":["match",["get","category"],"綠色商店","#3CB371","環保餐廳","#F8CF58","充電站","#5CA8D8","資源回收","#8B4513","#cccccc"],"circle-stroke-color":"#ffffff","circle-stroke-width":1}',
    '[{"key":"name","name":"名稱"},{"key":"category","name":"類別"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"}]'
),
(
    151,
    'eco_living_15min_metrotaipei',
    '無痕生活點位(雙北)',
    'circle',
    'geojson',
    NULL,
    NULL,
    '{"circle-radius":4,"circle-color":["match",["get","category"],"綠色商店","#3CB371","環保餐廳","#F8CF58","充電站","#5CA8D8","資源回收","#8B4513","#cccccc"],"circle-stroke-color":"#ffffff","circle-stroke-width":1}',
    '[{"key":"name","name":"名稱"},{"key":"category","name":"類別"},{"key":"district","name":"行政區"},{"key":"address","name":"地址"}]'
);

INSERT INTO public.query_charts (
    index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit, source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at, query_type, query_chart, query_history, city
) VALUES
(
    'eco_living_15min', NULL, '{150}', '{}', 'static', NULL, 0, '', '環保局資料', '顯示臺北市無痕生活圈分布', '包含綠色商店、環保餐廳、資源回收與充電站。', '鼓勵市民參與15分鐘無痕生活。', ARRAY['#'], ARRAY['doit'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'three_d',
    'SELECT district AS x_axis, category AS y_axis, COUNT(*)::int AS data FROM public.eco_living_15min WHERE city = ''臺北市'' AND district IS NOT NULL AND length(district) > 0 GROUP BY district, category ORDER BY district',
    NULL, 'taipei'
),
(
    'eco_living_15min', NULL, '{151}', '{}', 'static', NULL, 0, '', '雙北環保局資料', '顯示雙北無痕生活圈分布', '包含綠色商店、環保餐廳、資源回收與充電站。', '鼓勵市民參與跨域15分鐘無痕生活。', ARRAY['#'], ARRAY['doit', 'ntpc'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'three_d',
    'SELECT district AS x_axis, category AS y_axis, COUNT(*)::int AS data FROM public.eco_living_15min WHERE district IS NOT NULL AND length(district) > 0 GROUP BY district, category ORDER BY district',
    NULL, 'metrotaipei'
);

UPDATE public.dashboards
SET components = array_append(components, 310)
WHERE index = 'map-layers-taipei' AND NOT (310 = ANY(components));

UPDATE public.dashboards
SET components = array_append(components, 310)
WHERE index = 'map-layers-metrotaipei' AND NOT (310 = ANY(components));

SELECT pg_catalog.setval('public.components_id_seq', (SELECT COALESCE(MAX(id), 0) FROM public.components), true);
SELECT pg_catalog.setval('public.component_maps_id_seq', (SELECT COALESCE(MAX(id), 0) FROM public.component_maps), true);

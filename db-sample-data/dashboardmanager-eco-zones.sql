-- eco zones manager
DELETE FROM public.query_charts WHERE index IN ('eco_zone1', 'eco_zone2', 'eco_zone3', 'eco_zone4');
DELETE FROM public.component_charts WHERE index IN ('eco_zone1', 'eco_zone2', 'eco_zone3', 'eco_zone4');
DELETE FROM public.component_maps WHERE index IN ('eco_zone2_taipei', 'eco_zone2_metro', 'eco_zone3_taipei', 'eco_zone3_metro', 'eco_zone4_taipei', 'eco_zone4_metro');
DELETE FROM public.components WHERE index IN ('eco_zone1', 'eco_zone2', 'eco_zone3', 'eco_zone4');

-- Register Components
INSERT INTO public.components (id, index, name) VALUES 
(320, 'eco_zone1', '第一區：溫室氣體與隱形碳排'),
(330, 'eco_zone2', '第二區：民生垃圾與資源回收'),
(340, 'eco_zone3', '第三區：綠色消費與餐飲地圖'),
(350, 'eco_zone4', '第四區：低碳通勤充電站地圖');

-- Charts Registration
INSERT INTO public.component_charts (index, color, types, unit) VALUES 
('eco_zone1', ARRAY['#FF7F50', '#4682B4'], ARRAY['TimelineStackedChart', 'ColumnChart'], '萬公噸'),
('eco_zone2', ARRAY['#32CD32', '#8B4513'], ARRAY['ColumnChart', 'DistrictChart'], ''),
('eco_zone3', ARRAY['#3CB371', '#F8CF58', '#4682B4'], ARRAY['DonutChart', 'TreemapChart'], '家'),
('eco_zone4', ARRAY['#5CA8D8'], ARRAY['RadarChart', 'ColumnChart'], '站');

-- Maps Registration
INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property) VALUES 
(201, 'eco_zone2_taipei', '資源回收點(臺北)', 'circle', 'geojson', NULL, NULL, '{"circle-radius":5,"circle-color":"#8B4513","circle-stroke-color":"#ffffff","circle-stroke-width":1}', '[{"key":"name","name":"名稱"},{"key":"address","name":"地址"}]'),
(202, 'eco_zone2_metro', '資收站(雙北)', 'circle', 'geojson', NULL, NULL, '{"circle-radius":5,"circle-color":"#8B4513","circle-stroke-color":"#ffffff","circle-stroke-width":1}', '[{"key":"name","name":"名稱"},{"key":"address","name":"地址"}]'),
(203, 'eco_zone3_taipei', '綠色消費(臺北)', 'circle', 'geojson', NULL, NULL, '{"circle-radius":4,"circle-color":["match",["get","category"],"綠色商店","#3CB371","環保餐廳","#F8CF58","#cccccc"],"circle-stroke-color":"#ffffff","circle-stroke-width":1}', '[{"key":"name","name":"名稱"},{"key":"category","name":"類別"},{"key":"address","name":"地址"}]'),
(204, 'eco_zone3_metro', '綠色消費(雙北)', 'circle', 'geojson', NULL, NULL, '{"circle-radius":4,"circle-color":["match",["get","category"],"綠色商店","#3CB371","環保餐廳","#F8CF58","#cccccc"],"circle-stroke-color":"#ffffff","circle-stroke-width":1}', '[{"key":"name","name":"名稱"},{"key":"category","name":"類別"},{"key":"address","name":"地址"}]'),
(205, 'eco_zone4_taipei', '充電站(臺北)', 'circle', 'geojson', NULL, NULL, '{"circle-radius":4,"circle-color":"#5CA8D8","circle-stroke-color":"#ffffff","circle-stroke-width":1}', '[{"key":"name","name":"名稱"},{"key":"address","name":"地址"}]'),
(206, 'eco_zone4_metro', '充電站(雙北)', 'circle', 'geojson', NULL, NULL, '{"circle-radius":4,"circle-color":"#5CA8D8","circle-stroke-color":"#ffffff","circle-stroke-width":1}', '[{"key":"name","name":"名稱"},{"key":"address","name":"地址"}]');

-- Query Charts
INSERT INTO public.query_charts (index, history_config, map_config_ids, map_filter, time_from, time_to, update_freq, update_freq_unit, source, short_desc, long_desc, use_case, links, contributors, created_at, updated_at, query_type, query_chart, query_history, city) VALUES
(
    'eco_zone1', NULL, '{}', '{}', 'static', NULL, 0, '', '環保局資料', '溫室氣體總量趨勢', '臺北市歷年溫室氣體總排放量趨勢(萬公噸)。', '檢視減碳成效', ARRAY['#'], ARRAY['doit'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'time',
    'SELECT (year || ''-01-01T00:00:00+08:00'')::timestamptz AS x_axis, ''總排放量'' AS y_axis, total_emission::int AS data FROM public.eco_zone1_emissions ORDER BY year',
    NULL, 'taipei'
),
(
    'eco_zone2', NULL, '{201}', '{}', 'static', NULL, 0, '', '環保局資料', '資源回收量(噸)', '臺北市各區清潔隊資源回收量統計。', '檢視回收行動力', ARRAY['https://data.moenv.gov.tw/dataset/detail/STAT_P_46', 'https://data.moenv.gov.tw/dataset/detail/STAT_P_45', 'https://data.moenv.gov.tw/dataset/detail/STAT_P_127', 'https://data.moenv.gov.tw/dataset/detail/STAT_P_132'], ARRAY['doit'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT district AS x_axis, SUM(amount)::int AS data FROM public.eco_zone2_stats WHERE year=''113'' GROUP BY district ORDER BY data DESC',
    NULL, 'taipei'
),
(
    'eco_zone2', NULL, '{202}', '{}', 'static', NULL, 0, '', '雙北環保局資料', '資收站數量(個)', '雙北各區黃金資收站與收受點數量統計。', '新北市黃金資收站可將回收物換為生活用品，展現基層回收行動力。', ARRAY['https://data.moenv.gov.tw/dataset/detail/STAT_P_46', 'https://data.moenv.gov.tw/dataset/detail/STAT_P_45', 'https://data.moenv.gov.tw/dataset/detail/STAT_P_127', 'https://data.moenv.gov.tw/dataset/detail/STAT_P_132'], ARRAY['doit', 'ntpc'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT district AS x_axis, count(*) AS data FROM public.eco_zone2_map GROUP BY district ORDER BY data DESC',
    NULL, 'metrotaipei'
),
(
    'eco_zone3', NULL, '{203}', '{}', 'static', NULL, 0, '', '環保局資料', '商店與餐廳比例', '臺北市綠色商店與環保餐廳佔比。', '鼓勵綠色消費', ARRAY['https://data.moenv.gov.tw/dataset/detail/GP_P_01', 'https://data.moenv.gov.tw/dataset/detail/GIS_P_11', 'https://data.moenv.gov.tw/dataset/detail/GP_P_42'], ARRAY['doit'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT category AS x_axis, count(*) AS data FROM public.eco_zone3_map WHERE city=''臺北市'' GROUP BY category',
    NULL, 'taipei'
),
(
    'eco_zone3', NULL, '{204}', '{}', 'static', NULL, 0, '', '雙北環保局資料', '綠色消費分佈', '雙北各區綠色生活節點分佈。', '鼓勵綠色消費', ARRAY['https://data.moenv.gov.tw/dataset/detail/GP_P_01', 'https://data.moenv.gov.tw/dataset/detail/GIS_P_11', 'https://data.moenv.gov.tw/dataset/detail/GP_P_42'], ARRAY['doit', 'ntpc'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT district AS x_axis, count(*) AS data FROM public.eco_zone3_map WHERE district IS NOT NULL AND length(district)>0 GROUP BY district ORDER BY data DESC',
    NULL, 'metrotaipei'
),
(
    'eco_zone4', NULL, '{205}', '{}', 'static', NULL, 0, '', '環保局資料', '各區充電佈建', '臺北市各行政區充電站佈建均衡度。', '鼓勵低碳通勤', ARRAY['#'], ARRAY['doit'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT district AS x_axis, count(*) AS data FROM public.eco_zone4_map WHERE city=''臺北市'' AND district IS NOT NULL AND length(district)>0 GROUP BY district ORDER BY district',
    NULL, 'taipei'
),
(
    'eco_zone4', NULL, '{206}', '{}', 'static', NULL, 0, '', '雙北環保局資料', '各區充電佈建', '雙北各行政區充電站佈建。', '鼓勵低碳通勤', ARRAY['#'], ARRAY['doit', 'ntpc'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT district AS x_axis, count(*) AS data FROM public.eco_zone4_map WHERE district IS NOT NULL AND length(district)>0 GROUP BY district ORDER BY data DESC',
    NULL, 'metrotaipei'
);

UPDATE public.dashboards SET components = array_append(components, 320) WHERE index = 'map-layers-taipei' AND NOT (320 = ANY(components));
UPDATE public.dashboards SET components = array_append(components, 330) WHERE index = 'map-layers-taipei' AND NOT (330 = ANY(components));
UPDATE public.dashboards SET components = array_append(components, 340) WHERE index = 'map-layers-taipei' AND NOT (340 = ANY(components));
UPDATE public.dashboards SET components = array_append(components, 350) WHERE index = 'map-layers-taipei' AND NOT (350 = ANY(components));

UPDATE public.dashboards SET components = array_append(components, 320) WHERE index = 'map-layers-metrotaipei' AND NOT (320 = ANY(components));
UPDATE public.dashboards SET components = array_append(components, 330) WHERE index = 'map-layers-metrotaipei' AND NOT (330 = ANY(components));
UPDATE public.dashboards SET components = array_append(components, 340) WHERE index = 'map-layers-metrotaipei' AND NOT (340 = ANY(components));
UPDATE public.dashboards SET components = array_append(components, 350) WHERE index = 'map-layers-metrotaipei' AND NOT (350 = ANY(components));

SELECT pg_catalog.setval('public.components_id_seq', (SELECT COALESCE(MAX(id), 0) FROM public.components), true);
SELECT pg_catalog.setval('public.component_maps_id_seq', (SELECT COALESCE(MAX(id), 0) FROM public.component_maps), true);

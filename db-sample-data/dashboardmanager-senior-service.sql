--
-- Senior service distribution component seed data
--

DELETE FROM public.query_charts
WHERE index = 'senior_service_distribution';

DELETE FROM public.component_charts
WHERE index = 'senior_service_distribution';

DELETE FROM public.component_maps
WHERE index IN (
    'senior_service_distribution_taipei',
    'senior_service_distribution_metrotaipei'
);

DELETE FROM public.components
WHERE index = 'senior_service_distribution';

INSERT INTO public.components (id, index, name)
VALUES (219, 'senior_service_distribution', '銀髮族服務機構分布');

INSERT INTO public.component_charts (index, color, types, unit)
VALUES (
    'senior_service_distribution',
    ARRAY['#24B0DD','#56B96D','#F8CF58','#F5AD4A','#E170A6','#ED6A45','#AF4137','#10294A'],
    ARRAY['DistrictChart','ColumnChart'],
    '家'
);

INSERT INTO public.component_maps (id, index, title, type, source, size, icon, paint, property)
VALUES
(
    102,
    'senior_service_distribution_taipei',
    '銀髮族服務機構',
    'circle',
    'geojson',
    'big',
    NULL,
    '{
        "circle-color": ["match", ["get", "service_type"],
            "居家服務", "#24B0DD",
            "社區喘息服務單位", "#56B96D",
            "社區整合型服務中心(A單位)", "#F8CF58",
            "老人住宅(公寓)", "#F5AD4A",
            "老人日間照顧中心", "#E170A6",
            "#24B0DD"
        ],
        "circle-stroke-color": "#ffffff",
        "circle-stroke-width": 1,
        "circle-opacity": 0.85
    }',
    '[
        {"key": "name", "name": "機構名稱"},
        {"key": "service_type", "name": "機構類型"},
        {"key": "district", "name": "行政區"},
        {"key": "address", "name": "地址"},
        {"key": "phone", "name": "電話"},
        {"key": "approved_date", "name": "立案日期"}
    ]'
),
(
    103,
    'senior_service_distribution_metrotaipei',
    '銀髮族服務機構',
    'circle',
    'geojson',
    'big',
    NULL,
    '{
        "circle-color": ["match", ["get", "service_type"],
            "居家服務", "#24B0DD",
            "社區喘息服務單位", "#56B96D",
            "社區整合型服務中心(A單位)", "#F8CF58",
            "老人住宅(公寓)", "#F5AD4A",
            "老人日間照顧中心", "#E170A6",
            "#24B0DD"
        ],
        "circle-stroke-color": "#ffffff",
        "circle-stroke-width": 1,
        "circle-opacity": 0.85
    }',
    '[
        {"key": "name", "name": "機構名稱"},
        {"key": "service_type", "name": "機構類型"},
        {"key": "district", "name": "行政區"},
        {"key": "address", "name": "地址"},
        {"key": "phone", "name": "電話"},
        {"key": "approved_date", "name": "立案日期"}
    ]'
);

INSERT INTO public.query_charts (
    index,
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
) VALUES
(
    'senior_service_distribution',
    NULL,
    '{103}',
    '{}',
    'static',
    NULL,
    0,
    '',
    '臺北市政府資料',
    '顯示雙北銀髮族服務機構分布',
    '統計雙北銀髮族服務相關機構，依行政區與服務類型呈現分布情形。基隆市資料已排除。',
    '可用於比較臺北市與新北市的銀髮照護與服務資源配置，支援跨區域長照與社福政策分析。',
    ARRAY['臺北市銀髮族服務相關機構.csv'],
    ARRAY['doit'],
    '2026-04-18 12:36:52.393042+00',
    '2026-04-18 12:36:52.393042+00',
    'three_d',
    'WITH districts AS (SELECT DISTINCT district FROM public.taipei_senior_service_orgs WHERE district IS NOT NULL AND (address LIKE U&''\81FA\5317\5E02%'' OR address LIKE U&''\53F0\5317\5E02%'' OR address LIKE U&''\65B0\5317\5E02%'')), service_types AS (SELECT DISTINCT service_type FROM public.taipei_senior_service_orgs), counts AS (SELECT district, service_type, COUNT(*)::int AS data FROM public.taipei_senior_service_orgs WHERE district IS NOT NULL AND (address LIKE U&''\81FA\5317\5E02%'' OR address LIKE U&''\53F0\5317\5E02%'' OR address LIKE U&''\65B0\5317\5E02%'') GROUP BY district, service_type) SELECT d.district AS x_axis, s.service_type AS y_axis, COALESCE(c.data, 0) AS data FROM districts d CROSS JOIN service_types s LEFT JOIN counts c ON c.district = d.district AND c.service_type = s.service_type ORDER BY d.district, s.service_type',
    NULL,
    'metrotaipei'
),
(
    'senior_service_distribution',
    NULL,
    '{102}',
    '{}',
    'static',
    NULL,
    0,
    '',
    '臺北市政府資料',
    '顯示臺北市銀髮族服務機構分布',
    '統計臺北市銀髮族服務相關機構，依行政區與服務類型呈現分布情形。',
    '可用於盤點臺北市各行政區銀髮照護與服務資源配置，支援長照與社福政策分析。',
    ARRAY['臺北市銀髮族服務相關機構.csv'],
    ARRAY['doit'],
    '2026-04-18 12:36:52.393042+00',
    '2026-04-18 12:36:52.393042+00',
    'three_d',
    'WITH districts AS (SELECT DISTINCT district FROM public.taipei_senior_service_orgs WHERE district IS NOT NULL AND (address LIKE U&''\81FA\5317\5E02%'' OR address LIKE U&''\53F0\5317\5E02%'')), service_types AS (SELECT DISTINCT service_type FROM public.taipei_senior_service_orgs), counts AS (SELECT district, service_type, COUNT(*)::int AS data FROM public.taipei_senior_service_orgs WHERE district IS NOT NULL AND (address LIKE U&''\81FA\5317\5E02%'' OR address LIKE U&''\53F0\5317\5E02%'') GROUP BY district, service_type) SELECT d.district AS x_axis, s.service_type AS y_axis, COALESCE(c.data, 0) AS data FROM districts d CROSS JOIN service_types s LEFT JOIN counts c ON c.district = d.district AND c.service_type = s.service_type ORDER BY d.district, s.service_type',
    NULL,
    'taipei'
);

UPDATE public.dashboards
SET components = '{214,215,216,218,219}'
WHERE index = 'ltc_care_tpe';

UPDATE public.dashboards
SET components = '{214,215,216,218,219}'
WHERE index = 'ltc_care_newtpe';

SELECT pg_catalog.setval(
    'public.component_maps_id_seq',
    (SELECT COALESCE(MAX(id), 0) FROM public.component_maps),
    true
);

SELECT pg_catalog.setval(
    'public.components_id_seq',
    (SELECT COALESCE(MAX(id), 0) FROM public.components),
    true
);

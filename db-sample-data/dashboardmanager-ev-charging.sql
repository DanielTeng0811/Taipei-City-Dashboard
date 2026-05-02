INSERT INTO public.components ("index", name)
VALUES ('taipei_ev_charging', '雙北充電站基本資料')
ON CONFLICT ("index") DO UPDATE
SET name = EXCLUDED.name;

INSERT INTO public.component_charts ("index", color, types, unit)
VALUES (
  'taipei_ev_charging',
  ARRAY['#E6DF44', '#F4633C'],
  ARRAY['TreemapChart', 'DonutChart'],
  '處'
)
ON CONFLICT ("index") DO UPDATE
SET color = EXCLUDED.color,
    types = EXCLUDED.types,
    unit = EXCLUDED.unit;

INSERT INTO public.component_maps (
  "index",
  title,
  type,
  source,
  size,
  icon,
  paint,
  property
)
VALUES (
  'taipei_ev_charging',
  '雙北充電站基本資料',
  'symbol',
  'geojson',
  NULL,
  'power',
  '{}',
  '[
    {"key":"city","name":"縣市"},
	{"key":"station_name","name":"站點名稱"},
	{"key":"charging_points","name":"充電數量"},
	{"key":"telephone","name":"電話"},
	{"key":"description","name":"描述"}
  ]'::json
);

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
  'taipei_ev_charging',
  NULL,
  ARRAY[
    (SELECT id::integer FROM public.component_maps WHERE "index" = 'taipei_ev_charging' ORDER BY id DESC LIMIT 1)
  ],
  NULL,
  'current',
  NULL,
  NULL,
  NULL,
  '交通部',
  '顯示充電站相關資訊',
  '顯示充電站資料的詳細說明',
  '可用於觀察充電站分布或服務情形',
  ARRAY['https://data.gov.tw/dataset/170220'],
  ARRAY['doit'],
  NOW(),
  NOW(),
  'two_d',
  $sql$
SELECT
  CASE 
    WHEN city = 'Taipei' THEN '臺北'
    WHEN city = 'NewTaipei' THEN '新北'
    ELSE city
  END AS x_axis,
  COUNT(*) AS data
FROM public.taipei_ev_charging
GROUP BY 
  CASE 
    WHEN city = 'Taipei' THEN '臺北'
    WHEN city = 'NewTaipei' THEN '新北'
    ELSE city
  END;
  $sql$,
  NULL,
  'metrotaipei'
);

-- ── Hook into sustainable-env dashboard ──────────────────────────────────────
DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id 
    FROM public.components 
    WHERE "index" = 'taipei_ev_charging';

    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" IN ('sustainable_env_tpe', 'sustainable_env_newtpe')
          AND NOT (v_id = ANY(components));
    END IF;
END $$;

-- Update sequence
SELECT pg_catalog.setval(
    'public.components_id_seq',
    (SELECT COALESCE(MAX(id), 0) FROM public.components),
    true
);

COMMIT;

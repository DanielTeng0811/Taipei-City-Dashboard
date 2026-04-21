# 建立 Dashboard 組件流程

本專案的資料分成兩個 PostgreSQL database：

- `dashboard`：放原始資料表，例如從 CSV 匯入後的資料。
- `dashboardmanager`：放 component 設定，例如 `components`、`component_charts`、`query_charts`、`component_maps`、`dashboards`。

## 1. 取得 CSV

以銀髮族服務機構為例：

```text
臺北市銀髮族服務相關機構.csv
```

先確認欄位，例如：

```text
序號
機構類型
機構名稱
地址
行政區代碼
電話
立案日期
```

如果 CSV 內有地址但沒有座標，後續若要做地圖點位，需要額外 geocoding 或使用既有點位資料。

## 2. 規劃 component

先決定 component 要呈現什麼。

範例：`銀髮族服務機構分布`

- component index：`senior_service_distribution`
- component name：`銀髮族服務機構分布`
- query type：`three_d`
- chart types：`DistrictChart`, `ColumnChart`
- unit：`家`
- city versions：`taipei`, `metrotaipei`

如果要可以切換臺北市/雙北，做法不是建兩個 component，而是：

- `components` 一筆
- `component_charts` 一筆
- `query_charts` 兩筆
  - `city = 'taipei'`
  - `city = 'metrotaipei'`

## 3. 建 dashboard 原始資料 SQL

在 `db-sample-data` 新增一個 dashboard database 的 patch SQL。

範例：

```text
db-sample-data/dashboard-senior-service.sql
```

內容通常包含：

```sql
DROP TABLE IF EXISTS public.taipei_senior_service_orgs;

CREATE TABLE public.taipei_senior_service_orgs (
    serial_no integer,
    service_type text,
    org_name text,
    address text,
    district_code text,
    phone text,
    approved_date text,
    district text
);
```

接著用 `COPY ... FROM stdin` 放入整理後資料：

```sql
COPY public.taipei_senior_service_orgs (
    serial_no,
    service_type,
    org_name,
    address,
    district_code,
    phone,
    approved_date,
    district
) FROM stdin;
1	居家服務	機構名稱	臺北市萬華區...	63000070	02-xxxx-xxxx	1070709	萬華區
\.
```

注意：如果要用 `DistrictChart`，`district` 必須能對上行政區名稱，例如 `萬華區`、`中山區`。

## 4. 寫 chart query

`three_d` 圖表需要查詢回傳三欄：

```sql
x_axis
y_axis
data
```

範例：

```sql
SELECT
    district AS x_axis,
    service_type AS y_axis,
    COUNT(*)::int AS data
FROM public.taipei_senior_service_orgs
WHERE district IS NOT NULL
  AND (address LIKE '臺北市%' OR address LIKE '台北市%')
GROUP BY district, service_type
ORDER BY district, service_type;
```

```sql
WITH districts AS (
    SELECT DISTINCT district
    FROM public.taipei_senior_service_orgs
    WHERE district IS NOT NULL
),
service_types AS (
    SELECT DISTINCT service_type
    FROM public.taipei_senior_service_orgs
),
counts AS (
    SELECT district, service_type, COUNT(*)::int AS data
    FROM public.taipei_senior_service_orgs
    WHERE district IS NOT NULL
    GROUP BY district, service_type
)
SELECT
    d.district AS x_axis,
    s.service_type AS y_axis,
    COALESCE(c.data, 0) AS data
FROM districts d
CROSS JOIN service_types s
LEFT JOIN counts c
    ON c.district = d.district
   AND c.service_type = s.service_type
ORDER BY d.district, s.service_type;
```

## 5. 建 dashboardmanager metadata SQL

在 `db-sample-data` 新增一個 dashboardmanager database 的 patch SQL。

範例：

```text
db-sample-data/dashboardmanager-senior-service.sql
```

基本內容包含：

```sql
DELETE FROM public.query_charts
WHERE index = 'senior_service_distribution';

DELETE FROM public.component_charts
WHERE index = 'senior_service_distribution';

DELETE FROM public.components
WHERE index = 'senior_service_distribution';

INSERT INTO public.components (id, index, name)
VALUES (219, 'senior_service_distribution', '銀髮族服務機構分布');

INSERT INTO public.component_charts (index, color, types, unit)
VALUES (
    'senior_service_distribution',
    ARRAY['#24B0DD', '#56B96D', '#F8CF58', '#F5AD4A', '#E170A6'],
    ARRAY['DistrictChart', 'ColumnChart'],
    '家'
);
```

接著新增 `query_charts`。如果要支援臺北市和雙北，要新增兩筆：

```sql
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
    '{}',
    '{}',
    'static',
    NULL,
    0,
    '',
    '臺北市政府資料',
    '顯示臺北市銀髮族服務機構分布',
    '統計臺北市銀髮族服務相關機構，依行政區與服務類型呈現分布情形。',
    '可用於盤點臺北市各行政區銀髮照護與服務資源配置。',
    ARRAY['臺北市銀髮族服務相關機構.csv'],
    ARRAY['doit'],
    NOW(),
    NOW(),
    'three_d',
    'SELECT district AS x_axis, service_type AS y_axis, COUNT(*)::int AS data FROM public.taipei_senior_service_orgs WHERE district IS NOT NULL GROUP BY district, service_type ORDER BY district, service_type',
    NULL,
    'taipei'
);
```

## 6. 掛到 dashboard

component 建好後，還要把 component id 掛到 dashboard 的 `components` 陣列。

範例：把 `219` 掛到長照關懷 dashboard。

```sql
UPDATE public.dashboards
SET components = '{214,215,216,218,219}'
WHERE index = 'ltc_care_tpe';

UPDATE public.dashboards
SET components = '{214,215,216,218,219}'
WHERE index = 'ltc_care_newtpe';
```

最後更新 sequence：

```sql
SELECT pg_catalog.setval(
    'public.components_id_seq',
    (SELECT COALESCE(MAX(id), 0) FROM public.components),
    true
);
```

## 7. 如果需要地圖點位

如果 component 要在 `/mapview` 顯示點位，需要兩件事：

1. 在前端放 GeoJSON：

```text
Taipei-City-Dashboard-FE/public/mapData/senior_service_distribution_taipei.geojson
Taipei-City-Dashboard-FE/public/mapData/senior_service_distribution_metrotaipei.geojson
```

GeoJSON 格式：

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "機構名稱",
        "service_type": "居家服務",
        "district": "萬華區",
        "address": "臺北市萬華區...",
        "phone": "02-xxxx-xxxx"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [121.5, 25.03]
      }
    }
  ]
}
```

2. 在 `dashboardmanager` 新增 `component_maps`，再把 id 放進 `query_charts.map_config_ids`。

範例：

```sql
INSERT INTO public.component_maps (
    id,
    index,
    title,
    type,
    source,
    size,
    icon,
    paint,
    property
) VALUES (
    102,
    'senior_service_distribution_taipei',
    '銀髮族服務機構',
    'circle',
    'geojson',
    'big',
    NULL,
    '{"circle-color": "#24B0DD", "circle-stroke-color": "#ffffff", "circle-stroke-width": 1}',
    '[
        {"key": "name", "name": "機構名稱"},
        {"key": "service_type", "name": "機構類型"},
        {"key": "district", "name": "行政區"},
        {"key": "address", "name": "地址"},
        {"key": "phone", "name": "電話"}
    ]'
);
```

`component_maps.index` 必須對應到前端檔名：

```text
component_maps.index = senior_service_distribution_taipei
GeoJSON path = /mapData/senior_service_distribution_taipei.geojson
```

然後 `query_charts.map_config_ids` 要設定：

```sql
-- taipei
map_config_ids = '{102}'

-- metrotaipei
map_config_ids = '{103}'
```

## 8. 接進 init 流程

在 `db-sample-data/dashboard-demo.sql` 最後加：

```sql
\i /opt/db-sample-data/dashboard-senior-service.sql
```

在 `db-sample-data/dashboardmanager-demo.sql` 最後加：

```sql
\i /opt/db-sample-data/dashboardmanager-senior-service.sql
```

路徑必須用 container 內的路徑：

```text
/opt/db-sample-data/...
```

不要寫 Windows 本機路徑。
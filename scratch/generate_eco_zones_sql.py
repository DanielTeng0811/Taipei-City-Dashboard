import os
import csv
import re
import random

DISTRICT_CENTERS = {
    '松山區': (121.558, 25.060), '信義區': (121.570, 25.030), '大安區': (121.543, 25.026),
    '中山區': (121.533, 25.064), '中正區': (121.517, 25.032), '大同區': (121.516, 25.063),
    '萬華區': (121.499, 25.033), '文山區': (121.576, 24.990), '南港區': (121.606, 25.055),
    '內湖區': (121.590, 25.070), '士林區': (121.524, 25.090), '北投區': (121.500, 25.132),
    '板橋區': (121.459, 25.014), '中和區': (121.498, 24.999), '永和區': (121.515, 25.008),
    '新莊區': (121.446, 25.036), '三重區': (121.492, 25.063), '蘆洲區': (121.474, 25.084),
    '新店區': (121.540, 24.968), '土城區': (121.442, 24.973), '三峽區': (121.366, 24.934),
    '樹林區': (121.423, 24.992), '鶯歌區': (121.353, 24.954), '泰山區': (121.431, 25.056),
    '五股區': (121.438, 25.082), '汐止區': (121.661, 25.066), '淡水區': (121.440, 25.169),
    '八里區': (121.398, 25.146), '林口區': (121.390, 25.077), '瑞芳區': (121.805, 25.108)
}

def get_approximate_coord(district):
    center = DISTRICT_CENTERS.get(district, (121.5, 25.05))
    lon = center[0] + random.uniform(-0.015, 0.015)
    lat = center[1] + random.uniform(-0.015, 0.015)
    return lon, lat

def get_district_from_address(addr, default_val=''):
    for d in DISTRICT_CENTERS.keys():
        if d in addr:
            return d
    return default_val

def sanitize(text):
    if not text: return ''
    return text.replace('\n', ' ').replace('\r', '').replace('\t', ' ').replace("'", "''").strip()

def generate_sql():
    try:
        # 取得腳本所在目錄與專案根目錄
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        
        base_dir = os.path.join(project_root, "dataset-analysis", "eco-friendly")
        output_dir = os.path.join(project_root, "db-sample-data")
        zone2_map = []
        zone3_map = []
        zone4_map = []
        zone1_stats = []
        zone2_stats = []
        
        def read_csv(filename, encoding='utf-8'):
            path = os.path.join(base_dir, filename)
            if not os.path.exists(path): return []
            try:
                with open(path, 'r', encoding=encoding) as f:
                    return list(csv.DictReader(f))
            except UnicodeDecodeError:
                with open(path, 'r', encoding='big5') as f:
                    return list(csv.DictReader(f))

        # Zone 1 Stats (Emissions)
        z1_data = read_csv('臺北市溫室氣體排放統計-本市總排放量及人均排放量更新至2024年.csv', encoding='big5')
        for row in z1_data:
            if not row.get('年度'): continue
            zone1_stats.append({
                'year': sanitize(row.get('年度', '')),
                'total': float(row.get('總排放量_萬公噸', '0').replace(',', '')),
                'per_capita': float(row.get('人均排放量_公噸/年', '0').replace(',', ''))
            })

        # Zone 2 Stats (Recycling)
        z2_data = read_csv('臺北市各區清潔隊資源回收量-新版-增加行政區.csv', encoding='big5')
        for row in z2_data:
            if not row.get('年度'): continue
            # Normalize "北投區隊" to "北投區" so it matches other charts/maps
            raw_district = row.get('區隊', '')
            district = sanitize(raw_district.replace('區隊', '區'))
            zone2_stats.append({
                'year': sanitize(row.get('年度', '')),
                'month': sanitize(row.get('月', '')),
                'district': district,
                'amount': float(row.get('回收量（噸）', '0').replace(',', ''))
            })

        # Zone 2 Map (Recycling Stations)
        data = read_csv('●115年開放時間 (限時收受點csv) 1150223.csv', encoding='big5')
        for row in data:
            addr = sanitize(row.get('地址', ''))
            name = sanitize(row.get('分隊', '') + ' 限時收受點')
            district = row.get('行政區', '')
            lon = row.get('經度', '')
            lat = row.get('緯度', '')
            lon = float(lon) if lon else get_approximate_coord(district)[0]
            lat = float(lat) if lat else get_approximate_coord(district)[1]
            zone2_map.append({'city': '臺北市', 'district': district, 'category': '資源回收', 'name': name, 'address': addr, 'lon': lon, 'lat': lat})
            
        data = read_csv('新北市黃金資收站資訊_export.csv')
        for row in data:
            addr = sanitize(row.get('recycle_address', ''))
            if not addr: addr = sanitize(row.get('address', ''))
            name = sanitize(row.get('name', ''))
            district = row.get('district', '')
            lon, lat = get_approximate_coord(district)
            zone2_map.append({'city': '新北市', 'district': district, 'category': '資源回收', 'name': name, 'address': addr, 'lon': lon, 'lat': lat})

        # Zone 3 Map (Green Shops & Restaurants)
        data = read_csv('臺北市綠色商店1130429.csv')
        for row in data:
            addr = sanitize(row.get('聯絡地址', ''))
            name = sanitize(row.get('綠色商店名稱', ''))
            district = get_district_from_address(addr)
            lon, lat = get_approximate_coord(district)
            zone3_map.append({'city': '臺北市', 'district': district, 'category': '綠色商店', 'name': name, 'address': addr, 'lon': lon, 'lat': lat})
            
        data = read_csv('新北市綠色商店_export.csv')
        for row in data:
            addr = sanitize(row.get('address', ''))
            name = sanitize(row.get('name', ''))
            district = get_district_from_address(addr)
            lon, lat = get_approximate_coord(district)
            zone3_map.append({'city': '新北市', 'district': district, 'category': '綠色商店', 'name': name, 'address': addr, 'lon': lon, 'lat': lat})

        # Existing Eco Restaurants from sql file
        try:
            with open(r'../db-sample-data/dashboard-eco-restaurant.sql', 'r', encoding='utf-8') as f:
                content = f.read()
                copy_block = re.search(r'COPY public.taipei_eco_restaurants .*?FROM stdin;(.*?)\\\.', content, re.DOTALL)
                if copy_block:
                    lines = copy_block.group(1).strip().split('\n')
                    for line in lines:
                        parts = line.split('\t')
                        if len(parts) >= 12:
                            name = sanitize(parts[2])
                            addr = sanitize(parts[5])
                            district = parts[6] if parts[6] and parts[6] != '\\N' else get_district_from_address(addr)
                            lon = float(parts[10]) if parts[10] != '\\N' else get_approximate_coord(district)[0]
                            lat = float(parts[11]) if parts[11] != '\\N' else get_approximate_coord(district)[1]
                            zone3_map.append({'city': '臺北市', 'district': district, 'category': '環保餐廳', 'name': name, 'address': addr, 'lon': lon, 'lat': lat})
        except Exception:
            pass

        data = read_csv('新北市環保餐廳_export.csv')
        for row in data:
            addr = sanitize(row.get('address', ''))
            name = sanitize(row.get('name', ''))
            district = get_district_from_address(addr)
            lon, lat = get_approximate_coord(district)
            zone3_map.append({'city': '新北市', 'district': district, 'category': '環保餐廳', 'name': name, 'address': addr, 'lon': lon, 'lat': lat})

        # Zone 4 Map (EV Chargers)
        ev_files = [
            ('115年臺北市電動機車充電地點(398).csv', '臺北市'),
            ('臺北市營利電動車充電站-240站.csv', '臺北市'),
            ('臺北市營利電動機車充電站-12站.csv', '臺北市'),
            ('臺北市營利電動機車換電站-365站.csv', '臺北市'),
            ('新北市電動機車充電站_export.csv', '新北市'),
            ('新北市電動汽車充電站_export.csv', '新北市')
        ]
        for file, city in ev_files:
            data = read_csv(file)
            for row in data:
                addr = sanitize(row.get('地址', row.get('location address', '')))
                name = sanitize(row.get('名稱', row.get('charging station name', row.get('單位', '充電站'))))
                district = row.get('行政區', row.get('administrative district', ''))
                if not district:
                    district = get_district_from_address(addr)
                lon, lat = get_approximate_coord(district)
                zone4_map.append({'city': city, 'district': district, 'category': '充電站', 'name': name, 'address': addr, 'lon': lon, 'lat': lat})

        # --- Generate SQL Data ---
        sql_content = [
            "-- Eco Zones Data",
            "DROP TABLE IF EXISTS public.eco_zone1_emissions;",
            "CREATE TABLE public.eco_zone1_emissions (id SERIAL PRIMARY KEY, year text, total_emission double precision, per_capita double precision);",
            "DROP TABLE IF EXISTS public.eco_zone2_stats;",
            "CREATE TABLE public.eco_zone2_stats (id SERIAL PRIMARY KEY, year text, month text, district text, amount double precision);",
            "DROP TABLE IF EXISTS public.eco_zone2_map;",
            "CREATE TABLE public.eco_zone2_map (id SERIAL PRIMARY KEY, city text, district text, category text, name text, address text, longitude double precision, latitude double precision);",
            "DROP TABLE IF EXISTS public.eco_zone3_map;",
            "CREATE TABLE public.eco_zone3_map (id SERIAL PRIMARY KEY, city text, district text, category text, name text, address text, longitude double precision, latitude double precision);",
            "DROP TABLE IF EXISTS public.eco_zone4_map;",
            "CREATE TABLE public.eco_zone4_map (id SERIAL PRIMARY KEY, city text, district text, category text, name text, address text, longitude double precision, latitude double precision);",
            ""
        ]

        # 1. Zone 1 Stats
        sql_content.append("COPY public.eco_zone1_emissions (year, total_emission, per_capita) FROM stdin;")
        for r in zone1_stats:
            sql_content.append(f"{r['year']}\t{r['total']}\t{r['per_capita']}")
        sql_content.append("\\.\n")

        # 2. Zone 2 Stats
        sql_content.append("COPY public.eco_zone2_stats (year, month, district, amount) FROM stdin;")
        for r in zone2_stats:
            sql_content.append(f"{r['year']}\t{r['month']}\t{r['district']}\t{r['amount']}")
        sql_content.append("\\.\n")
            
        # 3. Zone 2-4 Maps
        for i, m in enumerate([zone2_map, zone3_map, zone4_map], 2):
            sql_content.append(f"COPY public.eco_zone{i}_map (city, district, category, name, address, longitude, latitude) FROM stdin;")
            for r in m:
                # Replace None or empty with \N for COPY
                district = r['district'] if r['district'] else '\\N'
                sql_content.append(f"{r['city']}\t{district}\t{r['category']}\t{r['name']}\t{r['address']}\t{r['lon']}\t{r['lat']}")
            sql_content.append("\\.\n")

        # --- Generate Data SQL ---
        output_sql_path = os.path.join(output_dir, 'dashboard-eco-zones.sql')
        with open(output_sql_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_content))
            
        print(f"Successfully generated {output_sql_path}")

        # --- Generate DashboardManager SQL ---
        manager_sql_path = os.path.join(output_dir, 'dashboardmanager-eco-zones.sql')
        with open(manager_sql_path, 'w', encoding='utf-8') as f:
            f.write("""-- eco zones manager
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
    'eco_zone2', NULL, '{201}', '{}', 'static', NULL, 0, '', '環保局資料', '資源回收量(噸)', '臺北市各區清潔隊資源回收量統計。', '檢視回收行動力', ARRAY['#'], ARRAY['doit'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT district AS x_axis, SUM(amount)::int AS data FROM public.eco_zone2_stats WHERE year=''113'' GROUP BY district ORDER BY data DESC',
    NULL, 'taipei'
),
(
    'eco_zone2', NULL, '{202}', '{}', 'static', NULL, 0, '', '雙北環保局資料', '資收站數量(個)', '雙北各區黃金資收站與收受點數量統計。', '新北市黃金資收站可將回收物換為生活用品，展現基層回收行動力。', ARRAY['#'], ARRAY['doit', 'ntpc'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT district AS x_axis, count(*) AS data FROM public.eco_zone2_map GROUP BY district ORDER BY data DESC',
    NULL, 'metrotaipei'
),
(
    'eco_zone3', NULL, '{203}', '{}', 'static', NULL, 0, '', '環保局資料', '商店與餐廳比例', '臺北市綠色商店與環保餐廳佔比。', '鼓勵綠色消費', ARRAY['#'], ARRAY['doit'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
    'SELECT category AS x_axis, count(*) AS data FROM public.eco_zone3_map WHERE city=''臺北市'' GROUP BY category',
    NULL, 'taipei'
),
(
    'eco_zone3', NULL, '{204}', '{}', 'static', NULL, 0, '', '雙北環保局資料', '綠色消費分佈', '雙北各區綠色生活節點分佈。', '鼓勵綠色消費', ARRAY['#'], ARRAY['doit', 'ntpc'], '2024-01-01 00:00:00+00', '2024-01-01 00:00:00+00', 'two_d',
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
""")
        print("Successfully generated db-sample-data/dashboardmanager-eco-zones.sql")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    generate_sql()

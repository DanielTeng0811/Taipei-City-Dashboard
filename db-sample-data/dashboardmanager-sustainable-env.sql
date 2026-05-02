--
-- 永續環境 (Sustainable Environment) Dashboard seed data
--
-- Depends on (run first):
--   dashboardmanager-demo.sql
--   dashboardmanager-eco-zones.sql          (eco_zone1=320, eco_zone2=330, eco_zone3=340, eco_zone4=350)
--   dashboardmanager-eco-restaurant.sql     (eco_restaurant_taipei=223)
--   dashboardmanager-clothing-recycle-bins.sql
--   dashboardmanager-medical-garbage.sql    (garbage_truck)
--

BEGIN;

-- ─── Create Dashboards ────────────────────────────────────────────────────────

INSERT INTO public.dashboards ("index", name, components, icon, updated_at, created_at)
SELECT 'sustainable_env_tpe', '永續環境', ARRAY[]::integer[], 'eco', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.dashboards WHERE "index" = 'sustainable_env_tpe');

INSERT INTO public.dashboards ("index", name, components, icon, updated_at, created_at)
SELECT 'sustainable_env_newtpe', '永續環境', ARRAY[]::integer[], 'eco', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM public.dashboards WHERE "index" = 'sustainable_env_newtpe');

-- ─── 臺北市 Dashboard Components ─────────────────────────────────────────────

-- 第一區：溫室氣體與隱形碳排 (eco_zone1, id=320)
UPDATE public.dashboards
SET components = array_append(components, 320)
WHERE "index" = 'sustainable_env_tpe' AND NOT (320 = ANY(components));

-- 第二區：民生垃圾與資源回收 (eco_zone2, id=330)
UPDATE public.dashboards
SET components = array_append(components, 330)
WHERE "index" = 'sustainable_env_tpe' AND NOT (330 = ANY(components));

-- 第三區：綠色消費與餐飲地圖 (eco_zone3, id=340)
UPDATE public.dashboards
SET components = array_append(components, 340)
WHERE "index" = 'sustainable_env_tpe' AND NOT (340 = ANY(components));

-- 第四區：低碳通勤充電站地圖 (eco_zone4, id=350)
UPDATE public.dashboards
SET components = array_append(components, 350)
WHERE "index" = 'sustainable_env_tpe' AND NOT (350 = ANY(components));

-- 臺北市環保餐廳分布 (eco_restaurant_taipei, id=223)
UPDATE public.dashboards
SET components = array_append(components, 223)
WHERE "index" = 'sustainable_env_tpe' AND NOT (223 = ANY(components));

-- 垃圾車收運點位 (garbage_truck, id auto-assigned)
DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id FROM public.components WHERE "index" = 'garbage_truck';
    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" = 'sustainable_env_tpe' AND NOT (v_id = ANY(components));
    END IF;
END $$;

-- 舊衣回收箱分布 (clothing_recycle_bins, id auto-assigned)
DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id FROM public.components WHERE "index" = 'clothing_recycle_bins';
    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" = 'sustainable_env_tpe' AND NOT (v_id = ANY(components));
    END IF;
END $$;

-- ─── 雙北 Dashboard Components ───────────────────────────────────────────────

-- 第一區：溫室氣體與隱形碳排 (eco_zone1, id=320)
UPDATE public.dashboards
SET components = array_append(components, 320)
WHERE "index" = 'sustainable_env_newtpe' AND NOT (320 = ANY(components));

-- 第二區：民生垃圾與資源回收 (eco_zone2, id=330)
UPDATE public.dashboards
SET components = array_append(components, 330)
WHERE "index" = 'sustainable_env_newtpe' AND NOT (330 = ANY(components));

-- 第三區：綠色消費與餐飲地圖 (eco_zone3, id=340)
UPDATE public.dashboards
SET components = array_append(components, 340)
WHERE "index" = 'sustainable_env_newtpe' AND NOT (340 = ANY(components));

-- 第四區：低碳通勤充電站地圖 (eco_zone4, id=350)
UPDATE public.dashboards
SET components = array_append(components, 350)
WHERE "index" = 'sustainable_env_newtpe' AND NOT (350 = ANY(components));

-- 臺北市環保餐廳分布 (eco_restaurant_taipei, id=223)
UPDATE public.dashboards
SET components = array_append(components, 223)
WHERE "index" = 'sustainable_env_newtpe' AND NOT (223 = ANY(components));

-- 舊衣回收箱分布 (clothing_recycle_bins, id auto-assigned)
DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id FROM public.components WHERE "index" = 'clothing_recycle_bins';
    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" = 'sustainable_env_newtpe' AND NOT (v_id = ANY(components));
    END IF;
END $$;

-- ─── Assign to City Groups ────────────────────────────────────────────────────

INSERT INTO public.dashboard_groups (dashboard_id, group_id)
SELECT d.id, g.id
FROM public.dashboards d
JOIN public.groups g ON g.name = 'taipei'
WHERE d."index" = 'sustainable_env_tpe'
ON CONFLICT DO NOTHING;

INSERT INTO public.dashboard_groups (dashboard_id, group_id)
SELECT d.id, g.id
FROM public.dashboards d
JOIN public.groups g ON g.name = 'metrotaipei'
WHERE d."index" = 'sustainable_env_newtpe'
ON CONFLICT DO NOTHING;

COMMIT;

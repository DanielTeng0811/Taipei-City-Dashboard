--
-- 永續環境 (Sustainable Environment) Dashboard seed data
--
-- Depends on (run first):
--   dashboardmanager-demo.sql
--   dashboardmanager-eco-restaurant.sql     (eco_restaurant_taipei=223)
--   dashboardmanager-clothing-recycle-bins.sql
--   dashboardmanager-garbage-truck.sql      (garbage_truck)
--   dashboardmanager-resource-recycling.sql (resource_recycling_per_capita=370)
--   dashboardmanager-waste.sql              (waste_statistics)
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

-- 各縣市人均資源回收量 (resource_recycling_per_capita, id=370)
UPDATE public.dashboards
SET components = array_append(components, 370)
WHERE "index" = 'sustainable_env_tpe' AND NOT (370 = ANY(components));

-- 空氣品質總覽 (air_quality_overview, id=360)
UPDATE public.dashboards
SET components = array_append(components, 360)
WHERE "index" = 'sustainable_env_tpe' AND NOT (360 = ANY(components));

-- 環保餐廳分布 (eco_restaurant_taipei, id=223)
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

-- 一般廢棄物清理情況 (waste_statistics, id auto-assigned)
DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id FROM public.components WHERE "index" = 'waste_statistics';
    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" = 'sustainable_env_tpe' AND NOT (v_id = ANY(components));
    END IF;
END $$;

-- ─── 雙北 Dashboard Components ───────────────────────────────────────────────

-- 各縣市人均資源回收量 (resource_recycling_per_capita, id=370)
UPDATE public.dashboards
SET components = array_append(components, 370)
WHERE "index" = 'sustainable_env_newtpe' AND NOT (370 = ANY(components));

-- 空氣品質總覽 (air_quality_overview, id=360)
UPDATE public.dashboards
SET components = array_append(components, 360)
WHERE "index" = 'sustainable_env_newtpe' AND NOT (360 = ANY(components));

-- 環保餐廳分布 (eco_restaurant_taipei, id=223)
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

-- 全台資源回收量 (resource_recycling_tw, id auto-assigned, timeline enabled)
DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id FROM public.components WHERE "index" = 'resource_recycling_tw';
    IF v_id IS NOT NULL THEN
        UPDATE public.dashboards
        SET components = array_append(components, v_id)
        WHERE "index" IN ('sustainable_env_tpe', 'sustainable_env_newtpe')
          AND NOT (v_id = ANY(components));
-- 一般廢棄物清理情況 (waste_statistics, id auto-assigned)
DO $$
DECLARE v_id integer;
BEGIN
    SELECT id INTO v_id FROM public.components WHERE "index" = 'waste_statistics';
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

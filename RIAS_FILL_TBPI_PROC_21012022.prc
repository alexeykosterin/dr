CREATE OR REPLACE PROCEDURE IDB_PROD.RIAS_FILL_TBPI_PROC
/**
* ������������ ������ ��� IDB_PH2_TBPI_INT
* @param ip_thread$i     - ����� ������ ����������
* @param ip_thread_cnt$i - ����� ������� � ����������
* @param ip_slog_id$i    - ������������ ���.������ � ����
*
* �������� 16.01.2020 ������� �.�.
*/
(
  ip_thread$i     IN PLS_INTEGER,
  ip_thread_cnt$i IN PLS_INTEGER,
  ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
--  ,phase_id$i      IN PLS_INTEGER DEFAULT 2
)
IS
  phase_id$i CONSTANT PLS_INTEGER := trash_from_odi.getPhase;
  SUBTYPE t_cache_key       IS VARCHAR2(2000);
  SUBTYPE t_cache_str_value IS VARCHAR2(300);
  date$d            DATE := RIAS_MGR_SUPPORT.get_current_date();

  --================================
  -- ����������
  --================================
  dml_errors EXCEPTION; -- ORA-24381 error(s) in array DML
  PRAGMA EXCEPTION_INIT(dml_errors, -24381);
  --================================
  -- ���������
  --================================
  -- ID ������� IDB_PH2_TBPI_INT
  lc_table_id$i CONSTANT INTEGER := rias_mgr_const.gc_tbpi_int;
  -- ��� ������� IDB_PH2_TBPI_INT
  lc_table_name$c CONSTANT VARCHAR2(50) := rias_mgr_const.get_table_name(lc_table_id$i);
  -- ���� ��� COMMIT �� ���������� ������
  lc_commit    CONSTANT BOOLEAN := TRUE;
  -- ���� ��� COMMIT ����� ������� ������
  lc_commit_after_city CONSTANT BOOLEAN := TRUE;
  -- ��� �������
  lc_action    CONSTANT BOOLEAN := TRUE;
  -- ������� ������� ����� � ��������� �� ������� �����
  lc_rec_limit CONSTANT PLS_INTEGER := 5000;
  --
  lc_koef_bss_mrc CONSTANT PLS_INTEGER := 100000;
  --
  lc_work_module_name CONSTANT VARCHAR2(100) := rias_mgr_const.get_process_prefix(lc_table_id$i) || '_THREAD:'||TO_CHAR(ip_thread$i)||'/'||TO_CHAR(ip_thread_cnt$i);
  -- ������� ����
  lc_current_date CONSTANT DATE := rias_mgr_support.get_current_date();
  -- 17.02.2021 feature_toggle for [ERT-24315] (���������� ������ ������� ������������)
  lv_swtch_value_ert_24315 CONSTANT INTEGER := rias_mgr_core.get_feature_toggle(1);
  --17.02.2021 feature_toggle for [ERT-19486] (���.ip � �������)
  lv_swtch_value_ert_19486 CONSTANT INTEGER := rias_mgr_core.get_feature_toggle(7);

  --================================
  -- ����������
  --================================
  lv_slog_id      PLS_INTEGER;
  lv_err_slog_id  PLS_INTEGER;

  lv_num_iteration PLS_INTEGER;
  lv_count_rows      PLS_INTEGER;
  --lv_num_all_rows  PLS_INTEGER;
  lv_time_start    NUMBER;
  lv_curr_billing  PLS_INTEGER;
  lv_cnt           PLS_INTEGER;
  --lv_char$c        t_cache_str_value;
  lv_incl_ip4addr  VARCHAR2(500);

  -- ����
  -- ����
  TYPE t_mrc_rec IS RECORD(koef_nds  NUMBER,      -- ���������� ��� (��������, 1.2)
                           serv_cost NUMBER,      -- ��������� ������ �/��� ���
                           mrc_cupon NUMBER,      -- % ������ �� ���������� ������ ��� �� ������ ������
                           mrc_discount NUMBER,   -- ����� ������
                           --mrc_without_nds NUMBER, -- ��������� ������ � ������ ������
                           mrc       NUMBER,
                           tax_mrc   NUMBER
                           --,mrc_cupon_mnt NUMBER
  );
  lv_mrc_rec t_mrc_rec;
  -- ��� ������ ������ �� �������
  TREC IDB_PH2_TBPI_INT%ROWTYPE;
  --
  TYPE T_REC_ARR IS TABLE OF IDB_PH2_TBPI_INT%ROWTYPE INDEX BY PLS_INTEGER;
  -- ����������� ������� ��� ������� � �������
  gv_rec_arr T_REC_ARR;
  -- ��� ����
  TYPE t_char_arr IS TABLE OF t_cache_str_value INDEX BY t_cache_key;
  gv_char_arr t_char_arr;

  -- ������ �� ������ ������ ����
  --TYPE t_unload_field IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(100);
  -- ������ ��������� ��� ���� SERVICE_ID
  TYPE t_offer_prefix IS TABLE OF VARCHAR2(200) INDEX BY VARCHAR2(100);
  -- ��� ���������� ������� IDB_PH2_BUNDLES
  TYPE t_bundles_rec IS RECORD(idb_id VARCHAR2(150), descount NUMBER);
  TYPE t_bundles_arr IS TABLE OF t_bundles_rec INDEX BY PLS_INTEGER;

  -- ������ ������� ��� ��������� � ������
  lv_cities_list RIAS_MGR_CORE.t_cities_list;
  -- ������ �� ������ ������ ����
  --lv_unload_field t_unload_field;
  -- ������ ��������� ��� ���� SERVICE_ID
  lv_offer_prefix t_offer_prefix;
  -- ������ ��� ���������� ������� IDB_PH2_BUNDLES
  lv_bundles_arr t_bundles_arr;
  -- ���������� ��������. ���� � ������������
  lv_speed_night NUMBER;
  TYPE t_arr_main_cur_tlo IS TABLE OF aak_tmp_main_cur_2%ROWTYPE;
  lv_arr_main_cur_tlo t_arr_main_cur_tlo;
  
  CURSOR main_cur_tlo(P_BILLING_ID NUMBER) IS

with  
table_plans_all as (
SELECT pl.plan_name,
pl.plan_id,
pl.billing_id,
pl.plan_group_id
FROM plans_all         pl
where pl.billing_id = P_BILLING_ID
AND INSTR(UPPER(pl.plan_name), 'BGP') = 0
), 
table_plan_groups_all as (
SELECT pg.plan_group_id,
pg.billing_id,
pg.product_id
FROM plan_groups_all   pg
where pg.billing_id = P_BILLING_ID
AND pg.product_id = 7
AND pg.plan_group_id IN (41, 86, 77)
), 
table_many as (
SELECT /*+ parallel (pp, 4)*/ distinct
acc.source_id,
acc.legacy_account_num,
acc.parent_id,
acc.idb_id,
acc.barring_toms_bpi,
acc.phase,
acc.source_system,
acc.source_system_type,

ad.billing_id,
ad.addendum_id,
ad.agreement_id,
ad.addendum_number,
ad.plan_id,

pp.house_id,
pp.point_plugin_id

FROM point_plugins_all pp, addenda_all ad, teo_all t, teo_link_addenda_all tla, idb_ph2_account   acc
where pp.billing_id = ad.billing_id
and pp.agreement_id = ad.agreement_id
and ad.billing_id = P_BILLING_ID
and t.point_plugin_id = pp.point_plugin_id
AND t.billing_id = ad.billing_id
AND t.teo_id = tla.teo_id
AND t.billing_id = tla.billing_id
AND tla.addendum_id = ad.addendum_id
AND tla.billing_id = ad.billing_id
AND tla.active_from <= lc_current_date
AND COALESCE(tla.active_to, lc_current_date + 1) > TRUNC(lc_current_date, 'mm')
and acc.phase = phase_id$i
and acc.source_system_type = '1'
AND acc.source_system = ad.billing_id
AND ad.agreement_id = acc.source_id
)
SELECT SOURCE_ID, LEGACY_ACCOUNT_NUM, 
PARENT_ID, IDB_ID, BARRING_TOMS_BPI, PHASE, SOURCE_SYSTEM, pp.BILLING_ID, 
ADDENDUM_ID, pp.AGREEMENT_ID, ADDENDUM_NUMBER, pl.PLAN_ID, PLAN_NAME,  
pg.PLAN_GROUP_ID,HOUSE_ID, POINT_PLUGIN_ID

FROM 
table_plans_all pl, table_plan_groups_all pg, table_many pp
where 1=1
   and pl.billing_id = pg.billing_id
   and pg.billing_id = pp.billing_id
   AND pl.plan_id = pp.plan_id
   AND pg.plan_group_id = pl.plan_group_id;
  
  TYPE t_arr_actual_start_date IS TABLE OF tmp_aak_actual_start_date%ROWTYPE;
  lv_arr_actual_start_date t_arr_actual_start_date;
  CURSOR actual_start_date_cur(P_BILLING_ID NUMBER) IS
  SELECT 
  TRUNC(MIN(alf.active_from) over (partition by alf.addendum_id, alf.billing_id, alf.plan_item_id)) as MIN_active_from ,
  case when active_to is NULL THEN NULL ELSE TRUNC(MAX(alf.active_to) over (partition by alf.addendum_id, 
    alf.billing_id, alf.plan_item_id)) end
    as MAX_active_to,
  --TRUNC(MAX(alf.active_to) over (partition by alf.addendum_id, alf.billing_id, alf.plan_item_id)) as MAX_active_to, 
  alf.addendum_id, alf.billing_id, alf.plan_item_id, pi.service_id, alf.active_from, alf.active_to,
  (case when pi.service_id = 237 and alf.active_from <= lc_current_date and (alf.active_to IS NULL OR alf.active_to > lc_current_date) then 1 
  when pi.service_id IN (867, 102749, 103257) and alf.active_from <= lc_current_date and (alf.active_to IS NULL OR alf.active_to > lc_current_date) then 2
  end)
  as ext_bpi_status, alf.activity_id
  
              FROM activate_license_fee_all alf,
                   plan_items_all pi
             WHERE alf.plan_item_id = pi.plan_item_id
               AND alf.billing_id = pi.billing_id
               AND alf.billing_id = P_BILLING_ID
               AND pi.service_id in (867, 102749, 103257, 237);
  CURSOR LC_TBPI_INT_2(P_BILLING_ID NUMBER)
  IS
  select * from aak_main_cur where billing_id = P_BILLING_ID;
  -- ������ �� ������� (237 TOP Level )
  CURSOR LC_TBPI_INT(P_BILLING_ID NUMBER)
  IS
         SELECT
           billing_id,
           to_number(source_id) agreement_id,
           legacy_account_num   agreement_number,
           parent_id            parent_id,
           idb_id               account_idb_id,
           addendum_id,
           addendum_number,
           plan_name,
           plan_id,
           plan_group_id,
           -- ��������
           --(SELECT TO_CHAR(ROUND(TRUNC(TO_NUMBER(TRIM(MAX(pp.prop_value)))/1000)/1024, 0))
           (SELECT TRUNC(TO_NUMBER(TRIM(MAX(pp.prop_value)))/1000)/1024
            FROM plan_properties_all pp
            WHERE pp.plan_id = ad.plan_id
              AND pp.property_type_id in (12, 13)
              AND pp.active_from <= lc_current_date
              AND (pp.active_to is null or pp.active_to > lc_current_date)
              AND pp.billing_id = ad.billing_id
           ) AS speed_night,
           --
           (SELECT MIN_active_from FROM tmp_aak_actual_start_date alf
           WHERE alf.addendum_id = ad.addendum_id
           AND alf.billing_id = ad.billing_id
           FETCH NEXT 1 ROWS ONLY
           ) AS actual_start_date,
           --
           (SELECT MAX_active_to FROM tmp_aak_actual_start_date alf
             WHERE alf.addendum_id = ad.addendum_id
               AND alf.billing_id = ad.billing_id
               AND alf.active_from <= lc_current_date
               AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
               FETCH NEXT 1 ROWS ONLY
           ) AS actual_end_date,
           --
           (SELECT TRUNC(MIN(fta.time_stamp))
            FROM tmp_aak_actual_start_date      alf,
                 activate_lic_fee_timestamp_all fta
            WHERE alf.addendum_id = ad.addendum_id
              AND alf.billing_id = ad.billing_id
              AND alf.service_id = 237
              AND fta.activity_id = alf.activity_id
              AND fta.billing_id = alf.billing_id
           ) created_when,
           --
           (SELECT cl.idb_id
              FROM idb_ph2_customer_location cl
             WHERE 1 = 1
               AND cl.source_system_type = '1'
               AND cl.source_id = ad.point_plugin_id
               AND cl.source_system = ad.billing_id
               AND rownum <= 1
           ) AS customer_location,
           --
           CASE
             WHEN 1 = 
              (SELECT ext_bpi_status -- ���� ���� �������� ������ �� �� ������� ����, �� ��������
               FROM tmp_aak_actual_start_date alf
               WHERE alf.addendum_id = ad.addendum_id
                 AND alf.billing_id = ad.billing_id
                 AND alf.active_from <= lc_current_date
                 AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
                 AND alf.service_id = 237
                 AND rownum <= 1) THEN
              'Active'
             WHEN 2 = 
              (SELECT ext_bpi_status -- ���� ���� �������� ��������������� �� ������� ����, �� ����������������
               FROM tmp_aak_actual_start_date alf
               WHERE alf.addendum_id = ad.addendum_id
                 AND alf.billing_id = ad.billing_id
                 AND alf.active_from <= lc_current_date
                 AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
                 AND alf.service_id IN (867, 102749, 103257)
                 AND rownum <= 1) THEN
              'Suspended'
             ELSE
              'Disconnected'
           END ext_bpi_status,
           'TI_1/' || to_char(billing_id) || '/' || to_char(agreement_id) || '/' || to_char(addendum_id) || '/' || to_char(point_plugin_id) AS idb_id,
           house_id,
           lc_current_date AS cur_date,
           barring_toms_bpi,
           point_plugin_id,
           phase
  FROM aak_tmp_main_cur_2 ad
   where 1=1
   and ad.billing_id = P_BILLING_ID
   AND (EXISTS ( -- ���� �������� ������
                SELECT 1
                  FROM tmp_aak_actual_start_date alf
                 WHERE alf.addendum_id = ad.addendum_id
                   AND alf.billing_id = ad.billing_id
                   AND alf.active_from <= lc_current_date
                   AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
                   AND (alf.service_id IN (237, 867, 102749)
                        OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))
                   AND rownum <= 1
                   ))
   AND (EXISTS ( -- ���� ����� ����������� �� ������� ����
                SELECT 1
                  FROM teo_all t, teo_link_addenda_all tla
                 WHERE t.point_plugin_id = ad.point_plugin_id
                   AND t.billing_id = ad.billing_id
                   AND t.teo_id = tla.teo_id
                   AND t.billing_id = tla.billing_id
                   AND tla.addendum_id = ad.addendum_id
                   AND tla.billing_id = ad.billing_id
                   AND tla.active_from <= lc_current_date
                   AND (tla.active_to IS NULL OR tla.active_to > lc_current_date)
                   AND rownum<=1
                ))
  UNION ALL
         SELECT
           ad.billing_id,
           to_number(source_id) agreement_id,
           legacy_account_num   agreement_number,
           parent_id            parent_id,
           idb_id               account_idb_id,
           addendum_id,
           addendum_number,
           plan_name,
           plan_id,
           plan_group_id,
           -- ��������
           --(SELECT TO_CHAR(ROUND(TRUNC(TO_NUMBER(TRIM(MAX(pp.prop_value)))/1000)/1024, 0))
           (SELECT TRUNC(TO_NUMBER(TRIM(MAX(pp.prop_value)))/1000)/1024
            FROM plan_properties_all pp
            WHERE pp.plan_id = ad.plan_id
              AND pp.property_type_id in (12, 13)
              AND pp.active_from <= lc_current_date
              AND (pp.active_to IS NULL OR pp.active_to > trunc(lc_current_date, 'mm'))
              --AND pp.active_to between trunc(lc_current_date, 'mm') AND lc_current_date
              AND pp.billing_id = ad.billing_id
           ) AS speed_night,
           --
           (SELECT MIN_active_from
              FROM tmp_aak_actual_start_date alf
             WHERE alf.addendum_id = ad.addendum_id
               AND alf.billing_id = ad.billing_id
               AND alf.service_id in (867, 102749, 103257, 237)
               FETCH NEXT 1 ROWS ONLY
           ) AS actual_start_date,
           --
           (SELECT MAX_active_to
              FROM tmp_aak_actual_start_date alf
             WHERE alf.addendum_id = ad.addendum_id
               AND alf.billing_id = ad.billing_id
               AND alf.active_from <= lc_current_date
               AND alf.active_to between trunc(lc_current_date, 'mm') AND lc_current_date
               AND alf.service_id IN (237, 867, 102749, 103257)
               FETCH NEXT 1 ROWS ONLY
           ) AS actual_end_date,
           --
           (SELECT TRUNC(MIN(fta.time_stamp))
            FROM tmp_aak_actual_start_date      alf,
                 activate_lic_fee_timestamp_all fta
            WHERE alf.addendum_id = ad.addendum_id
              AND alf.billing_id = ad.billing_id
              AND alf.service_id = 237
              AND fta.activity_id = alf.activity_id
              AND fta.billing_id = alf.billing_id
           ) created_when,
           --
           (SELECT cl.idb_id
              FROM idb_ph2_customer_location cl
             WHERE 1 = 1
               AND cl.source_system_type = '1'
               AND cl.source_id = ad.point_plugin_id
               AND cl.source_system = ad.billing_id
           ) AS customer_location,
           --
           CASE
             WHEN 1 =
              (SELECT ext_bpi_status -- ���� ���� �������� ������ �� �� ������� ����, �� ��������
               FROM tmp_aak_actual_start_date alf
               WHERE alf.addendum_id = ad.addendum_id
                 AND alf.billing_id = ad.billing_id
                 AND alf.active_from <= lc_current_date
                 AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
                 AND alf.service_id = 237
                 AND rownum <= 1) THEN
              'Active'
             WHEN 2 =
              (SELECT ext_bpi_status -- ���� ���� �������� ��������������� �� ������� ����, �� ����������������
               FROM tmp_aak_actual_start_date alf
               WHERE alf.addendum_id = ad.addendum_id
                 AND alf.billing_id = ad.billing_id
                 AND alf.active_from <= lc_current_date
                 AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
                 AND alf.service_id IN (867, 102749, 103257)
                 AND rownum <= 1) THEN
              'Suspended'
             ELSE
              'Disconnected'
           END ext_bpi_status,

           'TI_1/' || to_char(ad.billing_id) || '/' || to_char(ad.agreement_id) || '/' || to_char(ad.addendum_id) || '/' || to_char(ad.point_plugin_id) AS idb_id,
           house_id,
           trunc(lc_current_date, 'mm') AS cur_date,
           barring_toms_bpi,
           point_plugin_id,
           phase
  FROM aak_tmp_main_cur_2 ad
 WHERE 1 = 1
    and ad.billing_id = P_BILLING_ID
   AND (EXISTS ( -- ���� �������� ������
                SELECT 1
                  FROM tmp_aak_actual_start_date alf
                 WHERE alf.addendum_id = ad.addendum_id
                   AND alf.billing_id = ad.billing_id
                   AND alf.active_from <= lc_current_date
                   AND alf.active_to > TRUNC(lc_current_date, 'mm') AND alf.active_to <= lc_current_date
                   AND (alf.service_id IN (237, 867, 102749)
                        OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))
                   AND rownum <= 1
                   ))
   AND (EXISTS ( -- ���� ����� ����������� �� ������� ����
                SELECT 1
                  FROM teo_all t, teo_link_addenda_all tla
                 WHERE t.point_plugin_id = ad.point_plugin_id
                   AND t.billing_id = ad.billing_id
                   AND t.teo_id = tla.teo_id
                   AND t.billing_id = tla.billing_id
                   AND tla.addendum_id = ad.addendum_id
                   AND tla.billing_id = ad.billing_id
                   AND tla.active_from <= lc_current_date
                   AND tla.active_to > TRUNC(lc_current_date, 'mm') AND tla.active_to <= lc_current_date
                   --AND tla.active_to BETWEEN TRUNC(lc_current_date, 'mm') AND lc_current_date
                   AND rownum<=1
                ))
   UNION ALL
         SELECT
           billing_id,
           to_number(source_id) agreement_id,
           legacy_account_num   agreement_number,
           parent_id            parent_id,
           idb_id               account_idb_id,
           addendum_id,
           addendum_number,
           plan_name,
           plan_id,
           plan_group_id,
           -- ��������
           --(SELECT TO_CHAR(ROUND(TRUNC(TO_NUMBER(TRIM(MAX(pp.prop_value)))/1000)/1024, 0))
           (SELECT TRUNC(TO_NUMBER(TRIM(MAX(pp.prop_value)))/1000)/1024
            FROM plan_properties_all pp
            WHERE pp.plan_id = ad.plan_id
              AND pp.property_type_id in (12, 13)
              AND pp.active_from <= lc_current_date
              AND pp.active_from =(SELECT MAX(active_from)
                                  FROM plan_properties_all pp1
                                  WHERE pp1.plan_id = ad.plan_id
                                    AND pp1.billing_id = ad.billing_id
                                    AND pp1.active_from <= lc_current_date
                                    AND pp1.property_type_id in (12, 13))
              AND pp.billing_id = ad.billing_id
           ) AS speed_night,
           --
           (SELECT MIN_active_from
              FROM tmp_aak_actual_start_date alf
             WHERE alf.addendum_id = ad.addendum_id
               AND alf.billing_id = ad.billing_id
               AND alf.service_id in (867, 102749, 103257, 237)
               FETCH NEXT 1 ROWS ONLY
           ) AS actual_start_date,
           --
           (SELECT max(fl.active_to)
            FROM teo_link_addenda_all tla,
                 teo_all              te,
                 teo_flag_links_all   fl,
                 agreement_flags_all  af
            WHERE 1 = 1
              AND tla.addendum_id = ad.addendum_id
              AND tla.billing_id  = ad.billing_id
              AND tla.active_from <= current_date
              AND (tla.active_to IS NULL OR tla.active_to > current_date)
              --
              AND te.teo_id =  tla.teo_id
              AND te.billing_id = tla.billing_id
              --
              AND te.point_plugin_id = ad.point_plugin_id
              AND te.billing_id = ad.billing_id
              --
              AND fl.teo_id = te.teo_id
              AND fl.billing_id = te.billing_id
              AND fl.active_from <= current_date
              AND (fl.active_to IS NULL OR fl.active_to > current_date)
              AND af.flag_id = fl.flag_id
              AND af.billing_id = fl.billing_id
              AND af.active_from <= current_date
              AND (af.active_to IS NULL OR af.active_to > current_date)
              AND af.flag_type_id = 16
              AND af.flag_id != 1083487 -- �������������� ���������� �� �� (��������������� �������������)
              -- AND NOT (af.flag_name like '�������������� ���������� �� ��%')
           ) as actual_end_date,
           
           --
           (SELECT TRUNC(MIN(fta.time_stamp))
            FROM tmp_aak_actual_start_date      alf,
                 activate_lic_fee_timestamp_all fta
            WHERE alf.addendum_id = ad.addendum_id
              AND alf.billing_id = ad.billing_id
              AND alf.service_id = 237
              AND fta.activity_id = alf.activity_id
              AND fta.billing_id = alf.billing_id
           ) created_when,
           --
           (SELECT cl.idb_id
              FROM idb_ph2_customer_location cl
             WHERE 1 = 1
               AND cl.source_system_type = '1'
               AND cl.source_id = ad.point_plugin_id
               AND cl.source_system = ad.billing_id
               AND rownum <= 1
           ) AS customer_location,
           --

           'Suspended' AS ext_bpi_status,

           'TI_1/' || to_char(ad.billing_id) || '/' || to_char(ad.agreement_id) || '/' || to_char(ad.addendum_id) || '/' || to_char(ad.point_plugin_id) AS idb_id,
           house_id,
           lc_current_date AS cur_date,
           barring_toms_bpi,
           point_plugin_id,
           phase
  FROM aak_tmp_main_cur_2 ad
 WHERE 1 = 1
    and ad.billing_id = P_BILLING_ID
   -- ��� �������� ������
   AND NOT EXISTS (
                SELECT 1
                  FROM tmp_aak_actual_start_date alf
                 WHERE alf.addendum_id = ad.addendum_id
                   AND alf.billing_id = ad.billing_id
                   AND alf.active_from <= lc_current_date
                   AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
                   AND (alf.service_id IN (237, 867, 102749)
                        OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))
                   AND rownum <= 1
                   )
    -- ������ ����������� � �������
    AND ((SELECT MAX(alf.active_to)
         FROM tmp_aak_actual_start_date alf
         WHERE alf.addendum_id = ad.addendum_id
           AND alf.billing_id = ad.billing_id
           AND alf.active_from <= lc_current_date
           AND (alf.service_id IN (237, 867, 102749)
                OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))) <= TRUNC(lc_current_date, 'mm')
         --A.Kosterin 05.07.2021 ��������� ������� OR ��� ������������, ������� ��������� � ������� ������
         or 
         2 = (SELECT nvl2(MAX(alf.ACTIVE_to),1,0)
         FROM tmp_aak_actual_start_date alf
         WHERE alf.addendum_id = ad.addendum_id
           AND alf.billing_id = ad.billing_id
           AND alf.active_from <= lc_current_date
           and alf.ACTIVE_to <= TRUNC(lc_current_date, 'mm')
           AND (alf.service_id IN (237, 867, 102749)
                OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))) + 
(
SELECT nvl2(alf.ACTIVE_to,1,1) as tim
         FROM tmp_aak_actual_start_date alf
         WHERE alf.addendum_id = ad.addendum_id
           AND alf.billing_id = ad.billing_id
           AND alf.active_from > lc_current_date
           AND (alf.service_id IN (237, 867, 102749)
           OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))
           and rownum =1 
)
         )
   -- ���� ����� ����������� �� ������� ����
   AND EXISTS (
                SELECT 1
                  FROM teo_all t, teo_link_addenda_all tla
                 WHERE t.point_plugin_id = ad.point_plugin_id
                   AND t.billing_id = ad.billing_id
                   AND t.teo_id = tla.teo_id
                   AND t.billing_id = tla.billing_id
                   AND tla.addendum_id = ad.addendum_id
                   AND tla.billing_id = ad.billing_id
                   AND tla.active_from <= current_date
                   AND (tla.active_to IS NULL OR tla.active_to > current_date)
                   AND rownum<=1
                )
    --���� ���� ������������ �� ������� ����
    AND EXISTS (
            SELECT 1
            FROM teo_link_addenda_all tla,
                 teo_all              te,
                 teo_flag_links_all   fl,
                 agreement_flags_all  af
            WHERE 1 = 1
              AND tla.addendum_id = ad.addendum_id
              AND tla.billing_id  = ad.billing_id
              AND tla.active_from <= lc_current_date
              AND (tla.active_to IS NULL OR tla.active_to > lc_current_date)
              --
              AND te.teo_id =  tla.teo_id
              AND te.billing_id = tla.billing_id
              --
              AND te.point_plugin_id = ad.point_plugin_id
              AND te.billing_id = ad.billing_id
              --
              AND fl.teo_id = te.teo_id
              AND fl.billing_id = te.billing_id
              AND fl.active_from <= lc_current_date
              AND (fl.active_to IS NULL OR fl.active_to > lc_current_date)
              AND af.flag_id = fl.flag_id
              AND af.billing_id = fl.billing_id
              AND af.active_from <= lc_current_date
              AND (af.active_to IS NULL OR af.active_to > lc_current_date)
              AND af.flag_type_id = 16
              AND af.flag_id != 1083487 -- �������������� ���������� �� �� (��������������� �������������)
              --AND NOT (af.flag_name like '�������������� ���������� �� ��%')
              AND rownum <= 1
   )
   UNION ALL
SELECT
ad.billing_id,
to_number(source_id) agreement_id,
legacy_account_num   agreement_number,
parent_id            parent_id,
ad.idb_id               account_idb_id,
ad.addendum_id,
ad.addendum_number,
ad.plan_name,
ad.plan_id,
plan_group_id,
(SELECT TRUNC(TO_NUMBER(TRIM(MAX(pp.prop_value)))/1000)/1024
FROM plan_properties_all pp
WHERE pp.plan_id = ad.plan_id
AND pp.property_type_id in (12, 13)
AND pp.active_from <= lc_current_date
AND pp.active_from =(SELECT MAX(active_from)
FROM plan_properties_all pp1
WHERE pp1.plan_id = ad.plan_id
AND pp1.billing_id = ad.billing_id
AND pp1.active_from <= lc_current_date
AND pp1.property_type_id in (12, 13))
AND pp.billing_id = ad.billing_id
) AS speed_night,
--
(SELECT MIN_active_from
FROM tmp_aak_actual_start_date alf
WHERE alf.addendum_id = ad.addendum_id
AND alf.billing_id = ad.billing_id
AND alf.service_id in (867, 102749, 103257, 237)
FETCH NEXT 1 ROWS ONLY
) AS actual_start_date,

NULL as actual_end_date,
           
--
(SELECT TRUNC(MIN(fta.time_stamp))
FROM tmp_aak_actual_start_date       alf,
activate_lic_fee_timestamp_all fta
WHERE alf.addendum_id = ad.addendum_id
AND alf.billing_id = ad.billing_id
AND alf.service_id = 237
AND fta.activity_id = alf.activity_id
AND fta.billing_id = alf.billing_id
) created_when,
--
(SELECT cl.idb_id
FROM idb_ph2_customer_location cl
WHERE 1 = 1
AND cl.source_system_type = '1'
AND cl.source_id = ad.point_plugin_id
AND cl.source_system = ad.billing_id
AND rownum <= 1
) AS customer_location,
  
'Suspended' AS ext_bpi_status,

'TI_1/' || to_char(ad.billing_id) || '/' || to_char(ad.agreement_id) || '/' || to_char(ad.addendum_id) || '/' || to_char(ad.point_plugin_id) AS idb_id,
house_id,
lc_current_date AS cur_date,
ad.barring_toms_bpi,
ad.point_plugin_id,
ad.phase
FROM aak_tmp_main_cur_2 ad,
teo_all t, teo_link_addenda_all tla,
teo_flag_links_all   fl1,
agreement_flags_all  af
WHERE 1 = 1
   and ad.billing_id = P_BILLING_ID
-- ��� �������� ������
AND NOT EXISTS (
SELECT 1
FROM tmp_aak_actual_start_date alf
WHERE alf.addendum_id = ad.addendum_id
AND alf.billing_id = ad.billing_id
AND alf.active_from <= lc_current_date
AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
AND (alf.service_id IN (237, 867, 102749)
OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))
AND rownum <= 1
)
-- ������ ����������� � �������
AND (SELECT MAX(alf.active_to)
FROM tmp_aak_actual_start_date alf
WHERE alf.addendum_id = ad.addendum_id
AND alf.billing_id = ad.billing_id
AND alf.active_from <= lc_current_date
AND (alf.service_id IN (237, 867, 102749)
OR (lv_swtch_value_ert_24315 > 0 AND alf.service_id = 103257))) <= TRUNC(lc_current_date, 'mm')

AND t.point_plugin_id = ad.point_plugin_id
AND t.billing_id = ad.billing_id
AND t.teo_id = tla.teo_id
AND t.billing_id = tla.billing_id
AND tla.addendum_id = ad.addendum_id
AND tla.billing_id = ad.billing_id
AND tla.active_from <= lc_current_date
AND (tla.active_to IS NULL OR tla.active_to > lc_current_date)
AND fl1.teo_id = t.teo_id
AND fl1.billing_id = t.billing_id
AND fl1.active_from <= lc_current_date


--AND (fl.active_to IS NULL OR fl.active_to > current_date)



AND af.flag_id = fl1.flag_id
AND af.billing_id = fl1.billing_id
AND af.active_from <= lc_current_date
AND (af.active_to IS NULL OR af.active_to > lc_current_date)
AND af.flag_type_id = 16
AND af.flag_id = 1083487 

and (select max(tf2.active_from) from teo_flag_links_all tf2,agreement_flags_all af2 where 1=1
    AND tf2.teo_id = t.teo_id
    AND tf2.billing_id = t.billing_id
    AND af2.flag_id = tf2.flag_id
    AND af2.billing_id = tf2.billing_id  
    AND af2.flag_type_id = 16
    ) = fl1.active_from


AND NOT EXISTS (
SELECT 1
FROM teo_link_addenda_all tla,
teo_all              te,
teo_flag_links_all   fl,
agreement_flags_all  af
WHERE 1 = 1
AND tla.addendum_id = ad.addendum_id
AND tla.billing_id  = ad.billing_id
AND tla.active_from <= lc_current_date
AND (tla.active_to IS NULL OR tla.active_to > lc_current_date)
--
AND te.teo_id =  tla.teo_id
AND te.billing_id = tla.billing_id
--
AND te.point_plugin_id = ad.point_plugin_id
AND te.billing_id = ad.billing_id
--
AND fl.teo_id = te.teo_id
AND fl.billing_id = te.billing_id
AND fl.active_from <= lc_current_date
AND af.flag_id = fl.flag_id
AND af.billing_id = fl.billing_id
AND af.active_from <= lc_current_date
AND (af.active_to IS NULL OR af.active_to > lc_current_date)
AND af.flag_type_id = 24
AND af.flag_name = '������� �� ���������������'
AND (fl.active_from >= fl1.active_to
---11.08.2021 A.Kosterin ��������� ������� fl.active_from = fl1.active_from https://kb.ertelecom.ru/pages/viewpage.action?pageId=377699730
or fl.active_from = fl1.active_from)
AND rownum <= 1
)
;
/*
      SELECT
           AD.BILLING_ID,
           AC.SOURCE_ID AGREEMENT_ID,
           AC.LEGACY_ACCOUNT_NUM AGREEMENT_NUMBER,
           AD.ADDENDUM_ID,
           AD.ADDENDUM_NUMBER,
           ALF.PLAN_ITEM_ID,
           ALF.ACTIVITY_ID,
           ALF.ACTIVE_FROM,
           ALF.ACTIVE_TO,
           PI.SERVICE_ID,
           AC.PARENT_ID PARENT_ID,
           AC.IDB_ID    ACCOUNT_IDB_ID,
           (SELECT TRUNC(FTA.TIME_STAMP)
              FROM ACTIVATE_LIC_FEE_TIMESTAMP_ALL FTA
             WHERE FTA.ACTIVITY_ID = ALF.ACTIVITY_ID
               AND FTA.BILLING_ID = ALF.BILLING_ID
               AND FTA.BILLING_ID = P_BILLING_ID
           ) CREATED_WHEN,
           PA.PLAN_NAME,
           PA.PLAN_ID,
           PG.PLAN_GROUP_ID,
           (AC.NEXT_BILL_DATE - 1) BILLED_TO_DAT,
           --
           ('TI_1/' || AD.BILLING_ID || '/' ||
                      TRIM(AC.SOURCE_ID)  || '/' ||
                      TO_CHAR(AD.ADDENDUM_ID) || '/' ||
                      TO_CHAR(ALF.PLAN_ITEM_ID) || '/' ||
                      TO_CHAR(ALF.ACTIVITY_ID)
           ) AS IDB_ID,
           --
           (CASE
             WHEN EXISTS(SELECT 1
                         FROM PLAN_ITEMS_ALL           PI1,
                              ACTIVATE_LICENSE_FEE_ALL ALF1
                         WHERE ALF1.ADDENDUM_ID = AD.ADDENDUM_ID
                           AND ALF1.BILLING_ID = AD.BILLING_ID
                           AND ALF1.ACTIVE_FROM <= CURRENT_DATE
                           AND (ALF1.ACTIVE_TO IS NULL OR ALF1.ACTIVE_TO > CURRENT_DATE)
                           AND PI1.PLAN_ITEM_ID = ALF1.PLAN_ITEM_ID
                           AND PI1.BILLING_ID = ALF1.BILLING_ID
                           AND PI1.SERVICE_ID IN (867, 102749, 103257)
                           AND ROWNUM <= 1) THEN
               'Suspended'
             WHEN ALF.ACTIVE_TO BETWEEN TRUNC(CURRENT_DATE, 'MM') AND CURRENT_DATE --OR AC.ACCOUNT_STATUS = 'Awaiting final bill'
             THEN
               'Disconnected'
             ELSE
               'Active'
           END) AS EXT_BPI_STATUS,
           -- ��������
           (SELECT TO_CHAR(ROUND(TRUNC(TO_NUMBER(TRIM(MAX(PP.PROP_VALUE)))/1000)/1024, 0))
            FROM PLAN_PROPERTIES_ALL PP
            WHERE PP.PLAN_ID = PA.PLAN_ID
              AND PP.PROPERTY_TYPE_ID IN (12, 13)
              AND PP.ACTIVE_FROM <= CURRENT_DATE
              AND (PP.ACTIVE_TO IS NULL OR PP.ACTIVE_TO > CURRENT_DATE)
              AND PP.BILLING_ID = PA.BILLING_ID
              AND PP.BILLING_ID = P_BILLING_ID
           ) AS SPEED_NIGHT
           --
           \*
           ,(SELECT TRUNC(MAX(TIMESTAMP)) + 1 CHARGE
            FROM CHARGES_ALL CH
            WHERE CH.ADDENDUM_ID = AD.ADDENDUM_ID
              AND CH.SERVICE_ID = 237
              AND CH.BILLING_ID = AD.BILLING_ID
              AND CH.BILLING_ID = P_BILLING_ID
           ) AS PREV_BILL_TO_DAT
           *\
           ,AC.ORGANIZATION
      FROM PRODUCTS_ALL             PR,
           PLAN_GROUPS_ALL          PG,
           PLANS_ALL                PA,
           ADDENDA_ALL              AD,
           PLAN_ITEMS_ALL           PI,
           ACTIVATE_LICENSE_FEE_ALL ALF,
           SERVICES_ALL             SE,
           AGREEMENTS_ALL           AG,
           IDB_PH2_ACCOUNT          AC
      WHERE 1 = 1
        AND PR.PRODUCT_ID = 7
        AND PR.BILLING_ID = P_BILLING_ID
        -- ������ �������� ������
        AND PG.PRODUCT_ID = PR.PRODUCT_ID
        AND PG.BILLING_ID = PR.BILLING_ID
        AND PG.BILLING_ID = P_BILLING_ID
        AND PG.PLAN_GROUP_ID IN (41, 86, 77)
        --����� � ��������� �������
        AND PA.PLAN_GROUP_ID = PG.PLAN_GROUP_ID
        AND PA.BILLING_ID = PG.BILLING_ID
        AND PA.BILLING_ID = P_BILLING_ID
        -- �������� ����� PGP
        AND UPPER(PA.PLAN_NAME) NOT LIKE '%BGP%'
        --����� � ������������ ���������
        AND AD.PLAN_ID = PA.PLAN_ID
        AND AD.BILLING_ID = PA.BILLING_ID
        AND AD.BILLING_ID = P_BILLING_ID
        --================================ TEST
        -- AND AD.ADDENDUM_ID = 4871461
        --================================
        --����� � ����������
        AND AG.AGREEMENT_ID = AD.AGREEMENT_ID
        AND AG.BILLING_ID = AD.BILLING_ID
        AND AG.BILLING_ID = P_BILLING_ID
        AND AC.SOURCE_ID = AG.AGREEMENT_ID
        AND AC.SOURCE_SYSTEM = AG.BILLING_ID
        AND AC.SOURCE_SYSTEM = P_BILLING_ID
        AND AC.SOURCE_SYSTEM_TYPE = '1'
        --����� � ����������� ����� ���������� � ������� �����
        AND ALF.ADDENDUM_ID = AD.ADDENDUM_ID
        AND ALF.BILLING_ID = AD.BILLING_ID
        AND ALF.BILLING_ID = P_BILLING_ID
        AND ALF.ACTIVE_FROM <= CURRENT_DATE --��������
        AND COALESCE(ALF.ACTIVE_TO, CURRENT_DATE + 1) > TRUNC(CURRENT_DATE, 'MM') -- �� ��� ������ ���� ������ ��������� � ������� ������, �� ���� �� ���������
        --����� � ��������
        AND PI.PLAN_ITEM_ID = ALF.PLAN_ITEM_ID
        AND PI.BILLING_ID = ALF.BILLING_ID
        AND PI.BILLING_ID = P_BILLING_ID
        AND PI.SERVICE_ID = 237 --������ TOP Level
        --����� � ��������
        AND SE.SERVICE_ID = PI.SERVICE_ID
        AND SE.BILLING_ID = PI.BILLING_ID
        AND SE.BILLING_ID = P_BILLING_ID;
*/  --
  TYPE t_tbpi_int_arr IS TABLE OF LC_TBPI_INT%ROWTYPE INDEX BY BINARY_INTEGER;
  gv_tbpi_int_arr t_tbpi_int_arr;

--==========================================================================
-- ���������/�������
--==========================================================================
  /**
  * �������� �������� �������� �� ���� ��������
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - ������ � ����
  * @return �������� ������������ ��������� �� ���� (NULL, ���� ��� � ����)
  */
  FUNCTION get_char_cache(ip_cache_key$c IN VARCHAR2) RETURN VARCHAR2
  IS
    lv_res$c t_cache_str_value;
  BEGIN
    IF gv_char_arr.EXISTS(ip_cache_key$c) THEN
      lv_res$c := gv_char_arr(ip_cache_key$c);
      --dbms_output.put_line('��������� � ���');
    END IF;
    RETURN lv_res$c;
  END get_char_cache;

  /**
  * ��������� �������� �������� � ����
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - ������ � ����
  * @param ip_value$c   - ��������
  */
  PROCEDURE set_char_cache(
    ip_cache_key$c IN VARCHAR2,
    ip_value$c     IN VARCHAR2
  )
  IS
  BEGIN
    IF ip_cache_key$c IS NOT NULL /*AND ip_value$c IS NOT NULL*/ THEN
      gv_char_arr(ip_cache_key$c) := ip_value$c;
    END IF;
  END set_char_cache;

  /**
  * �������� ��� �������
  * @author
  * @version
  */
  PROCEDURE clear_props_cache
  IS
  BEGIN
    gv_char_arr.delete;
  END clear_props_cache;

  /**
  * ���������� ������ � ������
  */
  PROCEDURE prepareWorkData
  IS
  BEGIN
    /*
    -- �������� ������ �� �������� �����
    -- ������� �� ���������
    FOR rec IN (SELECT idb_column_name, d.off_id_for_migr
                  FROM idb_ph2_offers_chr_inv_dic d
                 WHERE 1 = 1
                   AND d.idb_table_name = lc_table_name$c
                   AND d.value_nnl_majority != 'Major')
    LOOP
      lv_unload_field(UPPER(TRIM(rec.idb_column_name)) || '/' || UPPER(TRIM(rec.off_id_for_migr))) := 0;
    END LOOP;
    */
    -- �������� PREFIX ��� SERVICE_ID
    FOR rec IN (SELECT d.off_id_for_migr, d.prefix
                FROM IDB_PH2_OFFERINGS_DIC d
                WHERE d.idb_table_name = lc_table_name$c
                )
    LOOP
      lv_offer_prefix(UPPER(TRIM(rec.off_id_for_migr))) := rec.prefix;
    END LOOP;
  END prepareWorkData;

  /**
  * �������� ������/���������� �� ����� ����
  *
  */
  FUNCTION is_unload_field(
    column_name$c IN VARCHAR2,
    off_id_for_migr$c IN VARCHAR2
  ) RETURN INTEGER
  IS
    lv_res$i INTEGER;
  BEGIN
    lv_res$i := rias_mgr_support.is_unload_field(table_name$c => 'IDB_PH2_TBPI_INT',
                                                 column_name$c => column_name$c,
                                                 off_id_for_migr$c => off_id_for_migr$c);
/*
    IF lv_unload_field.exists(UPPER(TRIM(column_name$c))||'/'|| UPPER(TRIM(off_id_for_migr$c))) THEN
      lv_res$i := 0;
    ELSE
      lv_res$i := 1;
    END IF;
*/
    RETURN lv_res$i;
  END is_unload_field;

  /**
  * �������� PREFIX ��� SERVICE_ID ����� OFF_ID_FOR_MIGR
  */
  FUNCTION get_prefix4offer(off_id_for_migr$c IN VARCHAR2) RETURN VARCHAR2
  IS
    lv_res$c VARCHAR2(200);
  BEGIN
    BEGIN
      lv_res$c := lv_offer_prefix(UPPER(TRIM(off_id_for_migr$c)));
    EXCEPTION
      WHEN OTHERS THEN
        lv_res$c := 'NO_FOUND';
    END;
    RETURN lv_res$c;
  END get_prefix4offer;

 /**
  * ���������� INV_NAME � OFF_ID_FOR_MIGR
  */
  PROCEDURE GET_TLO_NAME(
    P_PLAN_NAME        IN VARCHAR2,
    P_SPEED            IN NUMBER,--VARCHAR2,
    P_ADDENDUM_ID      IN INTEGER,
    P_BILLING_ID       IN INTEGER,
    LS_INV_NAME        IN OUT VARCHAR2,
    LS_OFF_ID_FOR_MIGR IN OUT VARCHAR2
  )
  IS
    lv_cnt PLS_INTEGER;
  BEGIN
    LS_INV_NAME        := NULL;
    LS_OFF_ID_FOR_MIGR := NULL;
    -- ���� �������� ���� ERT-24618 (https://jsd.netcracker.com/browse/ERT-24618)
    IF rias_mgr_core.get_feature_toggle(5) = 1 THEN
      IF rias_mgr_support.get_organiz_of_communicat(P_ADDENDUM_ID,
                                                    P_BILLING_ID,
                                                    trunc(lc_current_date,'mm'),
                                                    lc_current_date) = '3/4G' THEN
        IF P_SPEED IN (2, 5) AND (LOWER(P_PLAN_NAME) LIKE '%�����%' OR LOWER(P_PLAN_NAME) LIKE '%���������%') THEN
          LS_INV_NAME        := '�������� ��������� ������';
          LS_OFF_ID_FOR_MIGR := '121000355';
        ELSE
          LS_INV_NAME        := '�������� ��������������';
          LS_OFF_ID_FOR_MIGR := '121000390';
        END IF;
      END IF;
    END IF;

    -- ���� LS_INV_NAME �� ���������
    IF LS_INV_NAME IS NULL THEN
      IF INSTR(LOWER(P_PLAN_NAME), '3/4g') > 0 OR P_PLAN_NAME LIKE '�����%' THEN
        LS_INV_NAME        := '�������� ��������� ������';
        LS_OFF_ID_FOR_MIGR := '121000355';
      -- ph2it6
      ELSIF LOWER(P_PLAN_NAME) like '��������%+%' THEN
        LS_INV_NAME        := '��������+';
        LS_OFF_ID_FOR_MIGR := '121000879';
      -- ph2it6
      ELSIF LOWER(P_PLAN_NAME) like '��������%' THEN
        LS_INV_NAME        := '��������';
        LS_OFF_ID_FOR_MIGR := '121000837';
      ELSIF INSTR(LOWER(P_PLAN_NAME), '������ �������') > 0 THEN
        LS_INV_NAME        := '�������� ������������ ������';
        LS_OFF_ID_FOR_MIGR := '121000296';
      ELSIF -- ������� �������� �������� �� ��� � ����� "���������� �� ����" (PROP_TYPE_ID = 39, PROP_VALUE = 8)
            -- ������ �� ������� "���������� �� ���� - �������.sql"
          RIAS_MGR_SUPPORT.is_prop_teo_on_addendum(addendum_id$i      => P_ADDENDUM_ID,
                                                   billing_id$i       => P_BILLING_ID,
                                                   teo_prop_type_id$i => 39,
                                                   teo_prop_value$i   => 8) > 0
      THEN
        -- ���� �������� ���� ERT-24618 (https://jsd.netcracker.com/browse/ERT-24618)
        IF rias_mgr_core.get_feature_toggle(5) = 1 THEN
          IF rias_mgr_support.get_organiz_of_communicat(P_ADDENDUM_ID,
                                                       P_BILLING_ID,
                                                       trunc(lc_current_date,'mm'),
                                                       lc_current_date) IN ('������ ������ ����� � ���������� ���������',
                                                                            '������������ ����� ����� ��P2MP',
                                                                            '������������ ����� ����� ��P2P'
                                                                           ) 
          THEN
            IF P_SPEED IN (1,10,2,20,3,30,4,40,5,50,6,60,7,70,8,80,9,90,100) THEN
              LS_INV_NAME        := '�������� ������������ ������';
              LS_OFF_ID_FOR_MIGR := '121000296';
            ELSE
              LS_INV_NAME        := '�������� ��������������';
              LS_OFF_ID_FOR_MIGR := '121000390';
            END IF;
          ELSE
            LS_INV_NAME        := '�������� ������������ ������';
            LS_OFF_ID_FOR_MIGR := '121000296';
          END IF;
        ELSE
          LS_INV_NAME        := '�������� ������������ ������';
          LS_OFF_ID_FOR_MIGR := '121000296';
        END IF;
      ELSIF P_SPEED > 100 THEN
        LS_INV_NAME        := '�������� ��������������';
        LS_OFF_ID_FOR_MIGR := '121000390';
      ELSE
        LS_INV_NAME        := '�������� ������� ������';
        LS_OFF_ID_FOR_MIGR := '121000121';
      END IF;

      -- ������ �� ��������� ������ ���������� 18.02.2020 16:33 ����:�������������� ������� ��� ������������� ��������� � ip-�������� �� TLO
      -- ��������� ��������
      SELECT COUNT(1) INTO lv_cnt
      FROM
        IDB_PH2_OFFERS_CHR_VAL_DIC dic_val
      WHERE 1 = 1
        AND dic_val.OFF_ID_FOR_MIGR = LS_OFF_ID_FOR_MIGR
        AND dic_val.IDB_TABLE_NAME  = 'IDB_PH2_TBPI_INT'
        AND dic_val.IDB_COLUMN_NAME = 'ACCESS_SPEED'
        AND dic_val.po_char_value = P_SPEED || ' ����/�'
        AND dic_val.PO_CHAR_VALUE is not null;
      IF lv_cnt = 0 THEN
        LS_INV_NAME        := '�������� ��������������';
        LS_OFF_ID_FOR_MIGR := '121000390';
      END IF;
      -- ������ �� ��������� ������ ���������� �� 31.03.2020 12:47 ����:������������� �� TLO
      IF LS_OFF_ID_FOR_MIGR IN ('121000296', '121000355') AND
         rias_mgr_support.is_active_service_in_month(service_id$i => 1678,
                                                     addendum_id$i=> P_ADDENDUM_ID,
                                                     billing_id$i => P_BILLING_ID) = 1
      THEN
        LS_INV_NAME        := '�������� ��������������';
        LS_OFF_ID_FOR_MIGR := '121000390';
      END IF;
    END IF;
  END GET_TLO_NAME;

  /**
  * ��������� ���� ��������� ����� �������
  * @author  BikulovMD
  * @created 25.10.2019
  * @see (<a href="https://kb.ertelecom.ru/display/Netcracker/10.02.27+IDB_PH2_TBPI_INT#id-10.02.27IDB_PH2_TBPI_INT-UNINSTL_DATE"></a>)
  * @param P_AGREEMENT_ID IN ������������� ��������
  * @param P_BILLING_ID   IN ����� ��������
  * @return ���� ��������� ��
  */
  FUNCTION GET_UNINSTL_DATE(
    P_AGREEMENT_ID IN INTEGER,
    P_BILLING_ID  IN INTEGER
  )
  RETURN DATE
  IS
    lc_close_flag_id CONSTANT INTEGER := 1138061; -- �������� �����
    lc_res DATE;
  BEGIN
    FOR rec IN (
      SELECT fl.active_from
      FROM teo_flag_links_all  fl,
           agreement_flags_all af,
           teo_all             te,
           -- ����� ����������� �������� ��� ��������
           (
             SELECT p.point_plugin_id
             FROM point_plugins_all p
             WHERE p.billing_id = P_BILLING_ID
               AND  p.agreement_id = P_AGREEMENT_ID
           ) ppi
      WHERE te.point_plugin_id = ppi.point_plugin_id
        AND te.billing_id = P_BILLING_ID
        AND te.teo_id = fl.teo_id AND te.billing_id = fl.billing_id
        AND fl.flag_id = af.flag_id AND fl.billing_id = af.billing_id
        AND af.flag_id = lc_close_flag_id -- �������� �����
        AND fl.active_from is not null
        AND ROWNUM<=1) --
    LOOP
      lc_res := rec.active_from;
      EXIT;
    END LOOP;

    RETURN lc_res;
  END GET_UNINSTL_DATE;

  /**
  * ���������� �������� ����, ����� ������� ���������� ������ (����, �������)
  * @author
  * @version 2 (21.10.2019)
  * @see (<a href="https://kb.ertelecom.ru/display/Netcracker/10.02.27+IDB_PH2_TBPI_INT#id-10.02.27IDB_PH2_TBPI_INT-NETWORK"></a>)
  * @param P_AGREEMENT_ID IN ������������� ��������
  * @param P_ADDENDUM_ID  IN ������������� ����������
  * @param P_BILLING_ID   IN ����� ��������
  * @throws PROGRAM_ERROR ORA-20001
  * @return �������� ����
  */
  FUNCTION GET_NETWORK(
    P_AGREEMENT_ID INTEGER,
    P_ADDENDUM_ID  INTEGER,
    P_BILLING_ID   INTEGER,
    P_POINT_PLUGIN_ID IN INTEGER DEFAULT NULL
  ) RETURN VARCHAR2
  IS
    lv_res$c VARCHAR2(200);
  BEGIN


--21.01.2022 A.Kosterin ��������� ��� billing_id = 49 �.�. ��� ���� ���������� �� ��� ������ � ������� �������� NETWORK
if P_BILLING_ID = 49 then
  
      SELECT LISTAGG(company_name, ', ') WITHIN GROUP(ORDER BY company_name) as company_name
      INTO lv_res$c
      FROM (
        SELECT DISTINCT cn.company_name
        FROM addenda_all          ad,
             point_plugins_all    pp,
             teo_link_addenda_all tla,
             teo_all              teo,
             teo_properties_all   tp,
             other_companies_network_all cn
        WHERE 1=1
          AND ad.addendum_id = P_ADDENDUM_ID
          AND ad.billing_id = P_BILLING_ID
          AND (P_AGREEMENT_ID IS NULL OR ad.agreement_id = P_AGREEMENT_ID)
          -- ��
          AND pp.agreement_id = ad.agreement_id
          AND pp.billing_id = ad.billing_id
          AND (P_POINT_PLUGIN_ID IS NULL OR pp.point_plugin_id = P_POINT_PLUGIN_ID)
          -- ���
          AND tla.addendum_id = ad.addendum_id
          AND tla.billing_id = ad.billing_id
          AND tla.active_from <= date$d AND (tla.active_to IS NULL OR tla.active_to > date$d)
          --
          AND teo.point_plugin_id = pp.point_plugin_id
          AND teo.billing_id = pp.billing_id
          --
          AND teo.teo_id = tla.teo_id
          AND teo.billing_id = tla.billing_id
           -- Property
          AND tp.teo_id = teo.teo_id
          AND tp.billing_id = teo.billing_id
          AND tp.prop_type_id = 39 -- ����������� �� ����
          AND tp.active_from <= date$d
          AND (tp.active_to IS NULL OR tp.active_to > date$d)
          AND cn.company_id = tp.prop_value
          AND cn.billing_id = tp.billing_id
          AND cn.active_from <= date$d AND (cn.active_to IS NULL OR cn.active_to > date$d)
      );
      
if lv_res$c is null and P_AGREEMENT_ID is not null then
select
   LISTAGG (itg.network_alias, ', ') 
  WITHIN GROUP(ORDER BY itg.network_alias)
into lv_res$c from
  excellent.clients_all cl,
  excellent.agreements_all ag,
  excellent.addenda_all ad,
  excellent.teo_link_addenda_all tla,
  excellent.teo_properties_all tp ,excellent.itg_networks_all itg
where 1=1
  and cl.client_id=ag.client_id and cl.billing_id=ag.billing_id
  and exists(
    select 0 from idb_ph2_account where source_system_type='1' 
    and source_system=ag.billing_id and source_id=ag.agreement_id 
    and source_id=P_AGREEMENT_ID and source_system=P_BILLING_ID
  )
  and ag.agreement_id=ad.agreement_id and ag.billing_id=ad.billing_id
  and ad.addendum_id=tla.addendum_id and ad.billing_id=tla.billing_id
  and tla.teo_id=tp.teo_id and tla.billing_id=tp.billing_id
  and tp.prop_type_id=39 and  tp.prop_value<>0
  and tp.active_from < date$d
  and coalesce(tp.active_to, date$d + 1) >= date$d
  and tla.active_from < date$d
  and coalesce(tla.active_to, date$d + 1) >= date$d
  and itg.network_id=tp.prop_value and itg.billing_id = tp.billing_id and rownum = 1;
end if;      
      
      IF lv_res$c IS NULL THEN
        SELECT LISTAGG (company_name, ', ') WITHIN GROUP(ORDER BY company_name)
        INTO lv_res$c
        FROM (SELECT DISTINCT ocn.company_name
              FROM house_feature_links_all hfl
                  , point_plugins_all pp
                  , house_features_all hf
                  , other_companies_network_all ocn
                  , house_feature_links_cls_all ocnc
                  ,(
                     SELECT pp.point_plugin_id
                     FROM addendum_resources_all     ar,
                          resource_contents_all      rc,
                          teo_terminal_resources_all tr,
                          teo_all                    ta,
                          point_plugins_all          pp
                     WHERE ar.addendum_id = P_ADDENDUM_ID
                       AND ar.billing_id = P_BILLING_ID
                       AND ar.active_from <= date$d --��������*/
                       AND coalesce(ar.active_to, date$d + 1) > date$d
                       AND rc.resource_id = ar.resource_id
                       AND rc.billing_id = ar.billing_id
                       AND rc.active_from <= date$d --��������*/
                       AND coalesce(rc.active_to, date$d + 1) > date$d
                       AND tr.terminal_resource_id = rc.terminal_resource_id
                       AND tr.billing_id = rc.billing_id
                       AND tr.active_from <= date$d --��������*/
                       AND coalesce(tr.active_to, date$d + 1) > date$d
                       AND ta.teo_id = tr.teo_id
                       AND ta.billing_id = tr.billing_id
                       AND pp.point_plugin_id = ta.point_plugin_id
                       AND pp.billing_id = ta.billing_id
                       AND pp.agreement_id = P_AGREEMENT_ID
                     GROUP BY pp.point_plugin_id
                    ) ppi
              WHERE hfl.feature_id = hf.feature_id
                AND hfl.house_id = pp.house_id

                AND pp.point_plugin_id = ppi.point_plugin_id

                AND nvl(hf.company_id, 0) = ocn.company_id
                AND ocn.active_from <= date$d
                AND coalesce(ocn.active_to, date$d+1) > date$d
                AND ocnc.feature_id = hfl.feature_id
                AND ocnc.class_id in (1,10)
                AND ocnc.active_from <= date$d
                AND coalesce(ocnc.active_to, date$d+1) > date$d
                AND ocnc.billing_id=ocn.billing_id
                AND ocn.billing_id=hf.billing_id
                AND hf.billing_id= pp.billing_id
                AND pp.billing_id= hfl.billing_id
                AND hfl.billing_id= P_BILLING_ID
        );
      END IF;
      --��� 49 ������ ����������� � billing_id; �������� ������� �� ������� ��������
if lv_res$c is null then
  select
   LISTAGG (itg.network_alias, ', ') 
  WITHIN GROUP(ORDER BY itg.network_alias)
into lv_res$c from
  excellent.clients_all cl,
  excellent.agreements_all ag,
  excellent.addenda_all ad,
  excellent.teo_link_addenda_all tla,
  excellent.teo_properties_all tp ,excellent.itg_networks_all itg
where 1=1
  and cl.client_id=ag.client_id and cl.billing_id=ag.billing_id
  and exists(
    select 0 from idb_ph2_account where source_system_type='1' 
    and source_system=ag.billing_id and source_id=ag.agreement_id 
    and source_id=P_AGREEMENT_ID and source_system=P_BILLING_ID
  )
  and ag.agreement_id=ad.agreement_id and ag.billing_id=ad.billing_id
  and ad.addendum_id=tla.addendum_id and ad.billing_id=tla.billing_id
  and tla.teo_id=tp.teo_id and tla.billing_id=tp.billing_id
  and tp.prop_type_id=39 and  tp.prop_value<>0
  and tp.active_from < date$d
  and coalesce(tp.active_to, date$d + 1) >= date$d
  and tla.active_from < date$d
  and coalesce(tla.active_to, date$d + 1) >= date$d
  and itg.network_id=tp.prop_value and rownum = 1;
  end if;
else
  lv_res$c := rias_mgr_support.get_network(addendum_id$i => P_ADDENDUM_ID,
                                             billing_id$i => P_BILLING_ID,
                                             agreement_id$i => P_AGREEMENT_ID);
end if;

    RETURN NVL(lv_res$c, '����');
  EXCEPTION
    WHEN OTHERS THEN
      DECLARE
        errmsg VARCHAR2(500);
      BEGIN
        errmsg := SUBSTR(
          'P_AGREEMENT_ID = '|| TO_CHAR(P_AGREEMENT_ID) || chr(10) || chr(13) ||
          ' P_ADDENDUM_ID = '||  TO_CHAR(P_ADDENDUM_ID) || chr(10) || chr(13) ||
          ' P_BILLING_ID = '||   TO_CHAR(P_BILLING_ID)  || chr(10) || chr(13) ||
          ' SQLCODE = ' ||TO_CHAR(SQLCODE)              || chr(10) || chr(13) ||
          ' SQLERRM = ' || SUBSTR(SQLERRM, 1 , 64), 1, 500);
        RAISE_APPLICATION_ERROR(-20001, errmsg);
      END;
  END GET_NETWORK;

  /**
  * �������� ��� �����������
  * @param addendum_id$i     - ������������� ����������
  * @param billing_id$i      - ����� ��������
  * @param off_id_for_migr$c - ������������� ������������ �����������
  * @return ��� �����������
  */
  FUNCTION get_connect_type(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    house_id$i        IN INTEGER,
    off_id_for_migr$c IN VARCHAR2 DEFAULT NULL,
    date$d            IN DATE DEFAULT lc_current_date
  ) RETURN VARCHAR2
  IS
    --lv_cnt         PLS_INTEGER;
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
    lv_mku         VARCHAR2(300);
  BEGIN
    -- �������� �������� �� ����
    lv_cache_key$c := 'gct'||TO_CHAR(addendum_id$i)||'&'||TO_CHAR(billing_id$i)||CASE WHEN off_id_for_migr$c IS NOT NULL THEN '&'||off_id_for_migr$c ELSE '' END;
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- � ���� ��� ��������, �������� ����������
    IF lv_res$c IS NULL THEN
      IF off_id_for_migr$c = '121000355' THEN
          lv_res$c := '3G/4G ����';
      ELSE
        lv_res$c := rias_mgr_support.get_organiz_of_communicat(addendum_id$i, billing_id$i, trunc(lc_current_date,'mm'), lc_current_date);
        -- ������������ CONNECT_TYPE
        IF lv_res$c IS NULL THEN
          IF off_id_for_migr$c = '121000296' THEN
            lv_res$c := '������ ������ ����';
          --ELSIF off_id_for_migr$c = '121000355' THEN
          --  lv_res$c := '3G/4G ����';
          ELSE
            -- �������� ���
            lv_mku := rias_mgr_support.get_mku(house_id$i   => house_id$i,
                                               billing_id$i => billing_id$i,
                                               date$d       => date$d);
            IF instr(UPPER(lv_mku), '����') > 0 THEN
              lv_res$c := 'FTTB RIAS';
            ELSE
              lv_res$c := '����������';/*
                             TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="19.03.2020"
                             text="��������.
                                   ����������� � ������
                                   ������ �� ������������� � ������� CONNECT_TYPE"
                             */
            END IF;
          END IF;
        ELSE -- ������ �� ������ ��������
          IF off_id_for_migr$c = '121000296' THEN
            lv_res$c := CASE
                        WHEN lv_res$c = '������ ������ ����� � ���������� ���������' THEN '������ ������ ����'
                        WHEN lv_res$c = '������������ ����� ����� ��P2MP' THEN '��������� ����'
                        WHEN lv_res$c = '������������ ����� ����� ��P2P' THEN '��������� ����'
                        WHEN lv_res$c = '����' THEN 'FTTB RIAS'
                        WHEN lv_res$c = '������ ������' THEN 'FTTB RIAS'
                        WHEN lv_res$c = '�������' THEN '������ ������ ����'
                        WHEN lv_res$c = '3/4G' THEN '3G/4G ����'
                        ELSE lv_res$c
                      END;
          ELSE
            lv_res$c := CASE
                        WHEN lv_res$c = '������ ������ ����� � ���������� ���������' THEN '������ ������ RIAS'
                        WHEN lv_res$c = '������������ ����� ����� ��P2MP' THEN '��������� RIAS'
                        WHEN lv_res$c = '������������ ����� ����� ��P2P' THEN '��������� RIAS'
                        WHEN lv_res$c = '����' THEN 'FTTB RIAS'
                        WHEN lv_res$c = '������ ������' THEN 'FTTB RIAS'
                        WHEN lv_res$c = '�������' THEN '������ ������ RIAS'
                        WHEN lv_res$c = '3/4G' THEN '3G/4G ����'
                        ELSE lv_res$c
                      END;
          END IF;
        END IF;
      END IF;
      -- �������� �������� � ���
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;

    RETURN lv_res$c;
  END get_connect_type;

  /**
  * �������� ������������ ���� �����������
  * @param  addendum_id$i    - ������������� ����������
  * @param billing_id$i      - ������������� ��������
  * @param  plan_group_id$i  - ������������� ������ ������
  * @param  ip_date$d        - �� ����� ���� �������
  * @return ������������ ���� �����������
  */
  FUNCTION get_auth_type(
    addendum_id$i   IN INTEGER,
    billing_id$i    IN INTEGER,
    plan_group_id$i IN INTEGER DEFAULT NULL,
    ip_date$d       IN DATE DEFAULT lc_current_date
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_net_name$c VARCHAR2(100);
    --lv_cache_key$c t_cache_key;
  BEGIN
    lv_res$c := rias_mgr_support.get_auth_type(addendum_id$i   => addendum_id$i,
                                               billing_id$i    => billing_id$i,
                                               plan_group_id$i => plan_group_id$i,
                                               ip_date$d       => ip_date$d);
                                               
   --A.Kosterin 22.09.2021 add IF interzet; 01.12.2021 correction
    IF
      billing_id$i = 556 and lv_res$c is not null THEN
      select decode(rias_mgr_support.get_network(addendum_id$i => addendum_id$i, billing_id$i => billing_id$i), 'InterZet',1, 0) into lv_net_name$c from dual;
           IF
                  lv_net_name$c = 1 THEN lv_res$c :=  'IPoE';      
           END IF;
    END IF;
    /*
    -- �������� �������� �� ����
    lv_cache_key$c := 'gat'||TO_CHAR(addendum_id$i)||'&'||TO_CHAR(billing_id$i);
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- � ���� ��� ��������, �������� ����������
    IF lv_res$c IS NULL THEN
      FOR i_rec IN (
            SELECT CASE WHEN max(pv.val_dict_id) = 6 THEN 'PPPoE' ELSE 'IPoE' END AS auth_type
            FROM teo_link_addenda_all      tla,
                 dc_serv_prop_link_teo_all pt,
                 dc_serv_prop_val_all      pv,
                 dc_serv_link_pt_all       lp
            WHERE 1 = 1
              AND tla.addendum_id = addendum_id$i
              AND tla.billing_id = billing_id$i
              AND pt.teo_id = tla.teo_id
              AND pt.billing_id = tla.billing_id
              AND pt.active_from <= current_date
              AND (pt.active_to IS NULL OR pt.active_to > current_date)
              AND pv.prop_id = pt.prop_id
              AND pv.billing_id = pt.billing_id
              AND pv.active_from <= current_date
              AND (pv.active_to IS NULL OR pv.active_to > current_date)
              AND lp.dslp_id = pv.dslp_id
              AND lp.billing_id = pv.billing_id
              AND lp.prop_type_id = 5
      ) LOOP
        lv_res$c := i_rec.auth_type;
      END LOOP;
      -- �������� �������� � ���
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    */
    RETURN lv_res$c;
  END get_auth_type;

  /**
  * �������� ��� �����������
  * @param addendum_id$i - ������������� ����������
  * @param billing_id$i  - ����� ��������
  * @param isgray$i      - ������������ "�����" IP - ��(1)/���(0)
  * @return ��� �����������
  */
  FUNCTION get_incl_ip4addr(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    isgray$i          IN INTEGER DEFAULT 0
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
    lv_isgray$i    INTEGER := NVL(isgray$i, 0);
  BEGIN
    -- �������� �������� �� ����
    lv_cache_key$c := 'giiad'||TO_CHAR(addendum_id$i)||'&'||TO_CHAR(billing_id$i);
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- � ���� ��� ��������, �������� ����������
    IF lv_res$c IS NULL THEN
      FOR i_rec IN (
            SELECT NVL(IP.IDB_ID, NVL(IPP.IDB_ID, '����������� IP:'||TO_CHAR(i.IP))) || '|' ||
                   --������� ���������� � IP_METHOD_ASSIGN, DEDICATED_IPADDRESSING, IPV4_TYPE
                   -- ������ IDB_ID|IP_METHOD_ASSIGN|DEDICATED_IPADDRESSING|IPV4_TYPE
                     CASE
                       WHEN IP.IDB_ID IS NOT NULL THEN '�����������'
                       WHEN IPP.IDB_ID IS NOT NULL THEN '������������'
                       ELSE '�����������'
                     END || '|' ||
                     CASE
                       WHEN IP.IDB_ID IS NOT NULL THEN '��'
                       WHEN IPP.IDB_ID IS NOT NULL THEN '���'
                       ELSE '�����������'
                     END || '|' ||
                     CASE
                       WHEN IP.IDB_ID IS NOT NULL THEN '���������'
                       WHEN IPP.IDB_ID IS NOT NULL THEN '���������'
                       ELSE '�����������'
                     END AS incl_ip4addr
                   ,rias_mgr_support.is_ip_local(rias_mgr_support.ip_number_to_char(ip)) as is_ip_lcl
            FROM ADDENDUM_RESOURCES_ALL        AR,
                 RESOURCE_CONTENTS_ALL         RC,
                 IP_FOR_DEDICATED_CLIENTS_ALL  I,
                 IDB_PH2_IP_V4ADDRESS          IP,
                 IDB_PH2_IP_V4ADDRESS_PRIVATE  IPP
            WHERE 1 = 1
            and (IP.phase = phase_id$i or IPP.phase = phase_id$i)
              AND AR.ADDENDUM_ID = addendum_id$i
              AND AR.BILLING_ID = billing_id$i
              AND AR.ACTIVE_FROM <= lc_current_date
              AND (AR.ACTIVE_TO IS NULL OR AR.ACTIVE_TO > lc_current_date)
              --
              AND RC.RESOURCE_ID = AR.RESOURCE_ID
              AND RC.BILLING_ID = AR.BILLING_ID
              AND RC.ACTIVE_FROM <= lc_current_date
              AND (RC.ACTIVE_TO IS NULL OR RC.ACTIVE_TO > lc_current_date)
              --
              AND I.TERMINAL_RESOURCE_ID = RC.TERMINAL_RESOURCE_ID
              AND I.BILLING_ID = RC.BILLING_ID
              -- ������������ ip ������� ������� �� ����� �������� �������������
              -- ������������  (�������� "�����" ������)
              AND (lv_isgray$i = 1 OR
                                   NOT (   i.ip between 10000000000 and 10255255255   /* 10.0.0.0 � 10.255.255.255 */
                                        or i.ip between 100064000000 and 100127255255 /* 100.64.0.0 � 100.127.255.255 */
                                        or i.ip between 172016000000 and 172031255255 /* 172.16.0.0 � 172.31.255.255 */
                                        or i.ip between 192168000000 and 192168255255 /* 192.168.0.0 � 192.168.255.255 */
                                        or i.ip between 127000000000 and 127255255255 /* 127.0.0.0 � 127.255.255.255 */
                                       )
              )
              -- �������� �� ��������� IP � �������
              AND (lv_swtch_value_ert_19486 = 0
                   OR NOT EXISTS(SELECT 1
                              FROM  addendum_resources_all    ar,
                                    resource_contents_all     rc,
                                    cable_city_ip_subnets_all csa
                              WHERE (1=1)
                                AND ar.addendum_id = addendum_id$i
                                AND ar.billing_id = billing_id$i
                                AND (ar.active_from<= lc_current_date)
                                AND (ar.active_to is null or ar.active_to > lc_current_date)
                                AND rc.resource_id = ar.resource_id
                                AND rc.billing_id = ar.billing_id
                                AND (rc.active_from<= lc_current_date)
                                AND (rc.active_to IS NULL OR rc.active_to > lc_current_date)
                                AND csa.terminal_resource_id  = rc.terminal_resource_id
                                AND csa.billing_id = rc.billing_id
                                AND (csa.ip_v6 IS NULL)
                                AND i.ip >= csa.ip_v4
                                AND i.ip < csa.ip_v4 + POWER(2, 32-csa.netmask))
/*              
                   OR rias_mgr_support.ip_in_subnet(addendum_id$i => addendum_id$i,
                                                    billing_id$i  => billing_id$i,
                                                    ip$n          => i.ip,
                                                    date$d        => lc_current_date) = 0
*/
              )
              --
              AND IP.SOURCE_ID(+) = I.TERMINAL_RESOURCE_ID
              AND IP.SOURCE_SYSTEM(+) = I.BILLING_ID
              AND IP.SOURCE_SYSTEM_TYPE(+) = '1'
              --
              AND IPP.SOURCE_ID(+) = I.TERMINAL_RESOURCE_ID
              AND IPP.SOURCE_SYSTEM(+) = I.BILLING_ID
              AND IPP.SOURCE_SYSTEM_TYPE(+) = '1'
            ORDER BY is_ip_lcl, i.ip
      ) LOOP
        lv_res$c := i_rec.incl_ip4addr;
        EXIT;
      END LOOP;
      -- �������� �������� � ���
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_incl_ip4addr;

  /**
  * ��� ������� � IDB_PH2_BUNDLES
  */
  PROCEDURE insert_4_bundles(
    bpi_idb_id$c IN VARCHAR2,
    descount$n   IN NUMBER
  )
  IS
    lv_cnt$i PLS_INTEGER;
  BEGIN
    lv_cnt$i := lv_bundles_arr.count + 1;
    lv_bundles_arr(lv_cnt$i).idb_id := bpi_idb_id$c;
    lv_bundles_arr(lv_cnt$i).descount := descount$n;
  END;

  /**
  * �������� MRC
  */
  FUNCTION get_cost(
    bpi_idb_id$c  IN VARCHAR2,
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    service_id$i  IN INTEGER,
    date$d        IN DATE DEFAULT lc_current_date,
    with_nds$i    IN INTEGER DEFAULT 1
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
    lv_chk$i INTEGER;
  BEGIN
    -- �������� �� ����� ������� = 95
    lv_chk$i := rias_mgr_support.get_calculation_rule(addendum_id$i => addendum_id$i,
                                                      billing_id$i  => billing_id$i,
                                                      service_id$i  => service_id$i,
                                                      date$d        => date$d);

    IF lv_chk$i = 95 THEN
      lv_res$n := rias_mgr_support.get_abon_pays(addendum_id$i => addendum_id$i,
                                                 billing_id$i  => billing_id$i,
                                                 service_id$i  => service_id$i,
                                                 date$d        => date$d,
                                                 with_nds$i    => with_nds$i);
    ELSE
      lv_res$n := rias_mgr_support.get_service_cost(addendum_id$i => addendum_id$i,
                                                    billing_id$i  => billing_id$i,
                                                    service_id$i => service_id$i,
                                                    date$d       => date$d,
                                                    with_nds$i => with_nds$i);
    END IF;

    -- �������� ����������� ����� service_id = 101254
    SELECT COUNT(1) INTO lv_chk$i
    FROM activate_license_fee_all alf, plan_items_all pi
    WHERE alf.addendum_id = addendum_id$i
      AND alf.billing_id = billing_id$i
      AND alf.active_from <= date$d
      AND (alf.active_to IS NULL OR alf.active_to > date$d)
      AND alf.plan_item_id = pi.plan_item_id
      AND alf.billing_id = pi.billing_id
      AND pi.service_id = 101254;
    IF lv_chk$i > 0 THEN
      FOR rec IN (
             select MAX(dc.value) val
             from activate_license_fee_all alf
                , plan_items_all pi
                , adv_teo_link_activate_lf_all tla
                , adv_disc_charges_all dc
             where alf.addendum_id = addendum_id$i
               and alf.billing_id = billing_id$i
               and alf.active_from <= date$d
               and coalesce(alf.active_to, date$d + 1) > date$d
               and alf.plan_item_id = pi.plan_item_id
               and alf.billing_id = pi.billing_id
               and pi.service_id = 101254
               and alf.activity_id = tla.activity_id
               and tla.action_id = dc.action_id
               and tla.billing_id = dc.billing_id
               and dc.service_disc_id = pi.service_id
      ) LOOP
        lv_res$n := rec.val;
      END LOOP;
      -- ���� ���� �������� ���
      IF with_nds$i = 1 THEN
        lv_res$n := ROUND(lv_res$n * rias_mgr_support.get_nds(service_id$i, billing_id$i), 2);
      END IF;
    END IF;

    -- �������� ����������� ����� service_id IN (102243, 102241)
    -- ������� ��������, �.�. ��� ��� ���� ����� ��������� � ������� IDB_PH2_BUNDLES
    SELECT COUNT(1) INTO lv_chk$i
    FROM activate_license_fee_all alf, plan_items_all pi
    WHERE alf.addendum_id = addendum_id$i
      AND alf.billing_id = billing_id$i
      AND alf.active_from <= date$d
      AND (alf.active_to IS NULL OR alf.active_to > date$d)
      AND alf.plan_item_id = pi.plan_item_id
      AND alf.billing_id = pi.billing_id
      AND pi.service_id IN (102243, 102241 , 103305, 103343);
    IF lv_chk$i > 0 THEN
      FOR rec IN (
             select MAX(dc.value) val
             from activate_license_fee_all alf
                , plan_items_all pi
                , adv_teo_link_activate_lf_all tla
                , adv_disc_charges_all dc
             where alf.addendum_id = addendum_id$i
               and alf.billing_id = billing_id$i
               and alf.active_from <= date$d
               and coalesce(alf.active_to, date$d + 1) > date$d
               and alf.plan_item_id = pi.plan_item_id
               and alf.billing_id = pi.billing_id
               and pi.service_id in (102243, 102241, 103305, 103343)
               and alf.activity_id = tla.activity_id
               and tla.action_id = dc.action_id
               and tla.billing_id = dc.billing_id
               and dc.service_disc_id = pi.service_id
      ) LOOP
        lv_res$n := rec.val;
      END LOOP;
      -- ���������� ������� � ������� IDB_PH2_BUNDLES
      insert_4_bundles(bpi_idb_id$c => bpi_idb_id$c, descount$n => 0);
      -- ���� ���� �������� ���
      IF with_nds$i = 1 THEN
        lv_res$n := ROUND(lv_res$n * rias_mgr_support.get_nds(service_id$i, billing_id$i), 2);
      END IF;
    END IF;

    RETURN NVL(lv_res$n, 0);
  END get_cost;

  /**
  * �������� ������ �� "��������� ����� (�����������)"
  */
  FUNCTION get_discount(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    date$d        IN DATE DEFAULT lc_current_date
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    FOR rec IN (
           select MAX(dc.value) val
           from activate_license_fee_all alf
              , plan_items_all pi
              , adv_teo_link_activate_lf_all tla
              , adv_disc_charges_all dc
           where alf.addendum_id = addendum_id$i
             and alf.billing_id = billing_id$i
             and alf.active_from <= date$d
             and coalesce(alf.active_to, date$d + 1) > date$d
             and alf.plan_item_id = pi.plan_item_id
             and alf.billing_id = pi.billing_id
             and pi.service_id in (101394, 101395, 101396)
             and alf.activity_id = tla.activity_id
             and tla.action_id = dc.action_id
             and tla.billing_id = dc.billing_id
             and dc.service_disc_id = pi.service_id
    ) LOOP
      lv_res$n := rec.val;
    END LOOP;
    RETURN nvl(lv_res$n, 0);
  END get_discount;
--=====================
  /**
  * ����������� ���������� ������ � ������
  */
  PROCEDURE prepare_int_data
  IS
  BEGIN
    -- �������� ���
    RIAS_MGR_SUPPORT.clear_all_cache;
    -- �������� ������� ���
    clear_props_cache();
  END;

  /**
  * "�������" ����������� ������ � �������
  */
  PROCEDURE INSERT_ROWS
  IS
  BEGIN
    IF gv_rec_arr.COUNT > 0  AND lc_action THEN
      BEGIN
        FORALL lv_idx IN 1 .. gv_rec_arr.COUNT
        SAVE EXCEPTIONS
          INSERT /*+ APPEND */ INTO IDB_PH2_TBPI_INT
          VALUES gv_rec_arr(lv_idx);
      EXCEPTION
        WHEN dml_errors THEN
          FOR lv_idx_err IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
          LOOP
            -- �������� ���������� �� ������
            lv_err_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => lc_table_id$i,
                                                            ip_message => SUBSTR('Err: ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace || --chr(13) ||
                                                                                 'DEBUG_INFO:'        || chr(13) ||
                                                                                 '�������: '          || TO_CHAR(lv_curr_billing) || CHR(13) ||
                                                                                 'IDB_ID: '           || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).IDB_ID                  || CHR(13) ||
                                                                                 'ACCOUNT_IDB_ID: '   || TO_CHAR(gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).ACCOUNT_IDB_ID) || CHR(13) ||
                                                                                 'SOURCE_ID: '        || TO_CHAR(gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).SOURCE_ID)      || CHR(13) ||
                                                                                 'OFF_ID_FOR_MIGR: '  || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).OFF_ID_FOR_MIGR    || CHR(13) ||
                                                                                 'PARENT_ID: '        || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).PARENT_ID          || CHR(13) ||
                                                                                 'PLAN_NAME: '        || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).LEGACY_OBJECT_NAME
                                                                                 , 1, 2000),
                                                            ip_err_code => SUBSTR('SQLCODE = ' || TO_CHAR(-SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_CODE) ||' SQLERRM = ' || SQLERRM(-SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_CODE), 1, 200),
                                                            ip_thread_id => ip_thread$i,
                                                            ip_city_id => lv_curr_billing,
                                                            ip_slog_slog_id => lv_slog_id);

          END LOOP;
      END;

      --=================
      -- �������� ������ ��� ������� IDB_PH2_BUNDLES
      --=================
      IF lv_bundles_arr.COUNT > 0 THEN
        FORALL i IN 1..lv_bundles_arr.COUNT
          INSERT /*+ APPEND */ INTO IDB_PH2_BUNDLES(bpi_idb_id, legacy_bundle_discount)
          VALUES(lv_bundles_arr(i).idb_id, lv_bundles_arr(i).descount);
      END IF;

      -- ����������, ������ ���������� �������
      COMMIT;
    END IF;
    -- ������� ������� ������
    gv_rec_arr.delete;
    lv_bundles_arr.delete;

  END INSERT_ROWS;

--=============================================================================
BEGIN
  RIAS_MGR_CORE.save_session_state;
  dbms_application_info.set_module(module_name => lc_work_module_name,
                                   action_name => 'PrepareWorkData');
  -- �������� ������� ������
  prepareWorkData;
  -- �������������� ������ ����� DBG-����������
  rias_mgr_core.dbg_start(ip_table_id => lc_table_id$i);
  --
  dbms_application_info.set_action(action_name => 'GET CITIES LIST');
  -- �������� ������ �������
  lv_cities_list := RIAS_MGR_CORE.get_cities_list(ip_table_id$i   => lc_table_id$i,
                                                  ip_thread$i     => ip_thread$i,
                                                  ip_thread_cnt$i => ip_thread_cnt$i,
                                                  ip_slog_id$i    => ip_slog_id$i);
  -- ������������ ���������,���� ��� ������ �������� ���������� � ����� �������
  IF ip_thread_cnt$i > 1 THEN
    sys.dbms_lock.sleep(5);
  END IF;

  --lv_num_all_rows := 0;
  -- ����� �� �������
  FOR ct IN 1..lv_cities_list.COUNT
  LOOP
    -- ��������� ����� ������
    lv_time_start := dbms_utility.get_time;
    --
    lv_curr_billing := lv_cities_list(ct);
    -- �������� ����������
    lv_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => lc_table_id$i,
                                                ip_message => '��������� ������ '|| to_char(lv_curr_billing),
                                                ip_thread_id => TO_CHAR(ip_thread$i),
                                                ip_city_id => to_char(lv_curr_billing),
                                                ip_slog_slog_id => ip_slog_id$i);
    --
    lv_num_iteration := 0;
    lv_count_rows := 0;
    -- ���������� ���������� ������ � ������ �� ��������� ��������
    prepare_int_data;
    IF phase_id$i = 4 and lv_curr_billing = 0 THEN
      /*begin
          aak_main_tlo_for_holding.prepare_work_table(0);
          aak_main_tlo_for_holding.start_chain_for_holding;
          INSERT INTO aak_tmp_main_cur_2 SELECT * FROM aak_tmp_main_cur_for_holdint;
      end;*/
      begin
          aak_main_tlo.prepare_work_table(P_BILLING_ID => 0);
          aak_main_tlo.start_chains(P_BILLING_ID => 0);
      end;
      OPEN LC_TBPI_INT_2(lv_curr_billing);
    ELSE
    BEGIN
        OPEN main_cur_tlo(lv_curr_billing);
        LOOP
          FETCH main_cur_tlo BULK COLLECT
            INTO lv_arr_main_cur_tlo LIMIT 1000;
          EXIT WHEN lv_arr_main_cur_tlo.count = 0;
          FORALL i IN 1 .. lv_arr_main_cur_tlo.count
      INSERT INTO aak_tmp_main_cur_2(source_id,
                                     legacy_account_num,
                                     parent_id,
                                     idb_id,
                                     barring_toms_bpi,
                                     phase,
                                     source_system,
                                     billing_id,
                                     addendum_id,
                                     agreement_id,
                                     addendum_number,
                                     plan_id,
                                     plan_name,
                                     plan_group_id,
                                     house_id,
                                     point_plugin_id)
      VALUES
        (lv_arr_main_cur_tlo(i).source_id,
lv_arr_main_cur_tlo(i).legacy_account_num,
lv_arr_main_cur_tlo(i).parent_id,
lv_arr_main_cur_tlo(i).idb_id,
lv_arr_main_cur_tlo(i).barring_toms_bpi,
lv_arr_main_cur_tlo(i).phase,
lv_arr_main_cur_tlo(i).source_system,
lv_arr_main_cur_tlo(i).billing_id,
lv_arr_main_cur_tlo(i).addendum_id,
lv_arr_main_cur_tlo(i).agreement_id,
lv_arr_main_cur_tlo(i).addendum_number,
lv_arr_main_cur_tlo(i).plan_id,
lv_arr_main_cur_tlo(i).plan_name,
lv_arr_main_cur_tlo(i).plan_group_id,
lv_arr_main_cur_tlo(i).house_id,
lv_arr_main_cur_tlo(i).point_plugin_id);
        END LOOP;
        CLOSE main_cur_tlo;


end;


BEGIN
        OPEN actual_start_date_cur(lv_curr_billing);
        LOOP
          FETCH actual_start_date_cur BULK COLLECT
            INTO lv_arr_actual_start_date LIMIT 1000;
          EXIT WHEN lv_arr_actual_start_date.count = 0;
          FORALL i IN 1 .. lv_arr_actual_start_date.count
      INSERT INTO tmp_aak_actual_start_date(min_active_from,
                                      max_active_to,
                                      addendum_id,
                                      billing_id,
                                      plan_item_id,
                                      service_id,
                                      active_from,
                                      active_to,
                                      ext_bpi_status,
                                      activity_id)
      VALUES
        (lv_arr_actual_start_date(i).min_active_from,
         lv_arr_actual_start_date(i).max_active_to,
         lv_arr_actual_start_date(i).addendum_id,
         lv_arr_actual_start_date(i).billing_id,
         lv_arr_actual_start_date(i).plan_item_id,
         lv_arr_actual_start_date(i).service_id,
         lv_arr_actual_start_date(i).active_from,
         lv_arr_actual_start_date(i).active_to,
         lv_arr_actual_start_date(i).ext_bpi_status,
         lv_arr_actual_start_date(i).activity_id);
        END LOOP;
        CLOSE actual_start_date_cur;
end;


    -- �������� ������ �� �������
    
    OPEN LC_TBPI_INT(lv_curr_billing);
END IF;
    LOOP
      --
      lv_num_iteration := lv_num_iteration + 1;
      dbms_application_info.set_action(action_name => TO_CHAR(lv_curr_billing)||'/FETCH CRS('|| TO_CHAR(lv_num_iteration)||')' );
      -- ������� ������ �� ��������
IF phase_id$i = 4 and lv_curr_billing = 0 THEN
      FETCH LC_TBPI_INT_2 BULK COLLECT INTO gv_tbpi_int_arr LIMIT lc_rec_limit;
else
      FETCH LC_TBPI_INT BULK COLLECT INTO gv_tbpi_int_arr LIMIT lc_rec_limit;
end if;
      EXIT WHEN gv_tbpi_int_arr.COUNT = 0;
      -- �������� �� ������
      FOR i IN 1..gv_tbpi_int_arr.COUNT LOOP
      BEGIN
        -- ������� ������
        TREC := NULL;
        -- ��� ����������� �����������
        --lv_num_all_rows := lv_num_all_rows + 1;
        lv_count_rows := lv_count_rows + 1;
        IF MOD(lv_count_rows, 50) = 0 THEN
          dbms_application_info.set_action(action_name => TO_CHAR(lv_curr_billing)||'/ROW:'||TO_CHAR(lv_count_rows) || '/' || TO_CHAR(gv_tbpi_int_arr.COUNT) || ' ('|| TO_CHAR(lv_num_iteration)||')');
        END IF;
        -- ��������� ������
        DECLARE
          lv_curr_date date := gv_tbpi_int_arr(i).cur_date;
        BEGIN
          -- ��� �������� 'Suspended', 'Disconnected' ������������ ���� �� ��������� ������������ ������ 237
          IF gv_tbpi_int_arr(i).ext_bpi_status IN ('Suspended', 'Disconnected') THEN
            lv_curr_date := NVL(rias_mgr_support.get_service_active_to(service_id$i => 237,
                                                                   addendum_id$i => gv_tbpi_int_arr(i).addendum_id,
                                                                   billing_id$i => gv_tbpi_int_arr(i).billing_id,
                                                                   ip_date$d => NULL)-1, gv_tbpi_int_arr(i).cur_date);
          END IF;
          -- ���������� ���
          lv_mrc_rec.koef_nds  := NVL(RIAS_MGR_SUPPORT.get_nds(service_id$i => 237, billing_id$i => gv_tbpi_int_arr(i).billing_id), 1);
          lv_mrc_rec.koef_nds := CASE WHEN lv_mrc_rec.koef_nds = 0 THEN 1 ELSE lv_mrc_rec.koef_nds END;
          -- ��������� ������ � ���
          lv_mrc_rec.serv_cost := get_cost(bpi_idb_id$c  => gv_tbpi_int_arr(i).idb_id,
                                           addendum_id$i => gv_tbpi_int_arr(i).addendum_id,
                                           billing_id$i  => gv_tbpi_int_arr(i).billing_id,
                                           service_id$i  => 237,
                                           date$d        => lv_curr_date,
                                           with_nds$i    => 1);
          -- % ������ �� ���������� ������ ��� �� ������ ������
          lv_mrc_rec.mrc_cupon := NVL(RIAS_MGR_SUPPORT.get_cupon_4_service(addendum_id$i => gv_tbpi_int_arr(i).addendum_id,
                                                                           billing_id$i  => gv_tbpi_int_arr(i).billing_id,
                                                                           service_id$i  =>  1800,
                                                                           date$d        => lv_curr_date), 0);
          -- �������� ������ (���)
          lv_mrc_rec.mrc_discount := get_discount(addendum_id$i => gv_tbpi_int_arr(i).addendum_id,
                                                  billing_id$i  => gv_tbpi_int_arr(i).billing_id,
                                                  date$d        => lv_curr_date);
          -- ���� ������ ����, �� ������� ��� ������� IDB_PH2_BUNDLES
          IF NVL(lv_mrc_rec.mrc_discount, 0) > 0 THEN
            -- ������� ���
            lv_mrc_rec.mrc_discount := ROUND(lv_mrc_rec.mrc_discount * lv_mrc_rec.koef_nds, 2);
            -- ���������� ������� � ������� IDB_PH2_BUNDLES
            insert_4_bundles(
              bpi_idb_id$c => gv_tbpi_int_arr(i).idb_id,
              descount$n => lv_mrc_rec.mrc_discount * lc_koef_bss_mrc
            );
          ELSE
            lv_mrc_rec.mrc_discount := ROUND(lv_mrc_rec.serv_cost * lv_mrc_rec.mrc_cupon/100, 2);
          END IF;
          --
          lv_mrc_rec.mrc := ROUND(lv_mrc_rec.serv_cost - lv_mrc_rec.mrc_discount, 2);
          lv_mrc_rec.tax_mrc := ROUND(lv_mrc_rec.mrc - lv_mrc_rec.mrc/lv_mrc_rec.koef_nds, 2);

/*
if lv_mrc_cupon is null then
  mrc_price := round ((price * 1.2),2) ----------* 100000;
  tax_mrc_price := (round((price * 1.2-price),2)) -------* 100000;
else
  mrc_price_ndc := round ((price * 1.2),2);
  discount  := round ((mrc_price_ndc * 0.01 * lv_mrc_cupon),2);

  mrc_price := round((mrc_price_ndc - discount),2) -----------* 100000;
  tax_mrc_price := round((mrc_price_ndc - mrc_price_ndc/1.2),2) --------* 100000;
  lv_MRC_CUPON_MNT := discount ---------* 100000;
end if;
*/
        END;
        --=========================
        -- ����
        --=========================
        -- ��������
        lv_speed_night := CASE
                            WHEN gv_tbpi_int_arr(i).SPEED_NIGHT < 1 THEN
                              gv_tbpi_int_arr(i).SPEED_NIGHT
                            ELSE
                              ROUND(gv_tbpi_int_arr(i).SPEED_NIGHT, 0)
                            END;
        -- OFF_ID_FOR_MIGR - ������������� ������������ ����������� �� �������� ����������� �����������. ��������� �� ���� OFF_ID_FOR_MIGR � ������� IDB_PH2_OFFERINGS_DIC
        -- INV_NAME        - ��� � �����
        GET_TLO_NAME(
          P_PLAN_NAME        => gv_tbpi_int_arr(i).plan_name,
          P_SPEED            => lv_speed_night,--gv_tbpi_int_arr(i).speed_night,
          P_ADDENDUM_ID      => gv_tbpi_int_arr(i).addendum_id,
          P_BILLING_ID       => gv_tbpi_int_arr(i).billing_id,
          LS_INV_NAME        => TREC.inv_name,
          LS_OFF_ID_FOR_MIGR => TREC.off_id_for_migr
        );
        -- �������� �������, �� (����/�)
        IF is_unload_field('ACCESS_SPEED', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          --A.Kosterin 09.12.2021 add if
          if lv_speed_night < 1 then 
             TREC.ACCESS_SPEED := to_char(lv_speed_night, 'FM90.9999999999') || ' ����/�';
          elsif lv_speed_night = 2048 THEN
                              TREC.ACCESS_SPEED := '2100 ����/�';
                              TREC.MAX_IN_SPEED := 2100;
                              TREC.MAX_OUT_SPEED := 2100;
          elsif lv_speed_night = 5120 THEN
                              TREC.ACCESS_SPEED := '5200 ����/�';
                              TREC.MAX_IN_SPEED := 5200;
                              TREC.MAX_OUT_SPEED := 5200;
          else 
             TREC.ACCESS_SPEED := TO_CHAR(lv_speed_night) || ' ����/�';
          end if;
        END IF;
        -- �������� �������, ���������, �� (����/�)
        -- ph2i5
        IF is_unload_field('ACCESS_SPEED_UP', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.ACCESS_SPEED_UP := TREC.ACCESS_SPEED;
        END IF;
        -- ������ �� ����������� �������
        IF is_unload_field('ACCOUNT_IDB_ID', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.ACCOUNT_IDB_ID := gv_tbpi_int_arr(i).ACCOUNT_IDB_ID;
        END IF;
        -- ����, ����� ������ ���������� �������� ���� "�����������"
        -- ph2i5
        IF is_unload_field('ACTUAL_END_DATE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.ACTUAL_END_DATE := gv_tbpi_int_arr(i).ACTUAL_END_DATE;
          -- ���������������
          TREC.ACTUAL_END_DATE := CASE
                                    WHEN TREC.ACTUAL_END_DATE > lc_current_date THEN
                                      NULL
                                    ELSE
                                      TREC.ACTUAL_END_DATE - 1
                                  END;
        END IF;
        -- ����, ����� ������ ���������� �������� ���� "��������"
        IF is_unload_field('ACTUAL_START_DATE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.ACTUAL_START_DATE := COALESCE(gv_tbpi_int_arr(i).actual_start_date,
                                             -- ERT-24546 bikulov 26.01.2021
                                             rias_mgr_support.get_service_active_from(867,    gv_tbpi_int_arr(i).addendum_id, gv_tbpi_int_arr(i).billing_id),
                                             rias_mgr_support.get_service_active_from(102749, gv_tbpi_int_arr(i).addendum_id, gv_tbpi_int_arr(i).billing_id),
                                             rias_mgr_support.get_service_active_from(103257, gv_tbpi_int_arr(i).addendum_id, gv_tbpi_int_arr(i).billing_id)
          );
        END IF;
        -- ��� ����������� (PPPoE;IPoE;BGP � �.�.)
        IF is_unload_field('AUTH_TYPE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.AUTH_TYPE := get_auth_type(addendum_id$i   => gv_tbpi_int_arr(i).addendum_id,
                                          billing_id$i    => gv_tbpi_int_arr(i).billing_id,
                                          plan_group_id$i => gv_tbpi_int_arr(i).plan_group_id,
                                          ip_date$d       => lc_current_date);
        END IF;
        -- ���� ����������� ����� �� ������� ��������
        IF is_unload_field('BILLED_TO_DAT', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.BILLED_TO_DAT := CASE WHEN TREC.ACTUAL_START_DATE < TRUNC(lc_current_date, 'mm') THEN TRUNC(lc_current_date, 'mm')-1 ELSE NULL END;
        END IF;
        -- ��� ����������� (FTTB;GPON;WiMax;WNGN;Mobile � �.�.)
        IF is_unload_field('CONNECT_TYPE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.CONNECT_TYPE := GET_CONNECT_TYPE(
            addendum_id$i     => gv_tbpi_int_arr(i).addendum_id,
            billing_id$i      => gv_tbpi_int_arr(i).billing_id,
            house_id$i        => gv_tbpi_int_arr(i).house_id,
            off_id_for_migr$c => TREC.off_id_for_migr,
            date$d            => gv_tbpi_int_arr(i).cur_date
          );
        END IF;
        -- ���� �������� �������
        IF is_unload_field('CREATED_WHEN', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.CREATED_WHEN := gv_tbpi_int_arr(i).CREATED_WHEN;
        END IF;
        -- ������ �� ������� �������, ��� ��������������� ������
        IF is_unload_field('CUSTOMER_LOCATION', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.CUSTOMER_LOCATION := gv_tbpi_int_arr(i).customer_location;
        END IF;
        -- ������ ���������� ��������
        IF is_unload_field('EXT_BPI_STATUS', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.EXT_BPI_STATUS := gv_tbpi_int_arr(i).EXT_BPI_STATUS;
        END IF;
        -- ����, ����� ��� ���������� ������� ������ �������� EXT_BPI_STATUS
        -- ph2i5
        IF is_unload_field('EXT_BPI_STATUS_DATE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          IF TREC.EXT_BPI_STATUS = 'Suspended' THEN
            -- �������� ��� 867, ����� 102749, ����� 103257 ������
            TREC.EXT_BPI_STATUS_DATE := COALESCE(rias_mgr_support.get_service_active_from(867,    gv_tbpi_int_arr(i).addendum_id, gv_tbpi_int_arr(i).billing_id),
                                                 rias_mgr_support.get_service_active_from(102749, gv_tbpi_int_arr(i).addendum_id, gv_tbpi_int_arr(i).billing_id),
                                                 rias_mgr_support.get_service_active_from(103257, gv_tbpi_int_arr(i).addendum_id, gv_tbpi_int_arr(i).billing_id)
                                        );
          ELSE
            TREC.EXT_BPI_STATUS_DATE := CASE
                                         WHEN TREC.EXT_BPI_STATUS = 'Active' THEN
                                           TREC.ACTUAL_START_DATE
                                         WHEN TREC.EXT_BPI_STATUS = 'Disconnected' THEN
                                           TREC.ACTUAL_END_DATE
                                       END;
          END IF;
        END IF;
        -- ��������� ���� ������� ������� ������������ ��� ����������� ��������� ��������-������� � ������������ ����� ���������.
        TREC.IDB_ID := gv_tbpi_int_arr(i).IDB_ID;
        --16.11.2021 add PHASE
        TREC.PHASE := gv_tbpi_int_arr(i).PHASE;
        lv_incl_ip4addr := get_incl_ip4addr(addendum_id$i => gv_tbpi_int_arr(i).addendum_id,
                                            billing_id$i  => gv_tbpi_int_arr(i).billing_id);
        -- ���� � "�����" �� �������, �� ���� � "�����"
        IF lv_incl_ip4addr IS NULL THEN
          lv_incl_ip4addr := get_incl_ip4addr(addendum_id$i => gv_tbpi_int_arr(i).addendum_id,
                                              billing_id$i  => gv_tbpi_int_arr(i).billing_id,
                                              isgray$i      => 1);
        END IF;
        -- IPv4 ����� � ������� ������
        IF is_unload_field('INCL_IP4ADDR', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.INCL_IP4ADDR := SUBSTR(lv_incl_ip4addr, 1, INSTR(lv_incl_ip4addr,'|', 1, 1) - 1);
        END IF;
        -- ����� ���������� IP-������
        -- !!! �� ������ �� ��������� ������ ����������  (����: IP_METHOD_ASSIGN)   �� 24.09
        --     Update � ODI (��������� RIAS_IDB_PH2_TBPI_INT)
        IF is_unload_field('IP_METHOD_ASSIGN', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          -- � ������� � ���� "INCL_IP4ADDR" �� �������� �������� ��� IP_METHOD_ASSIGN, DEDICATED_IPADDRESSING, IPV4_TYPE
          TREC.IP_METHOD_ASSIGN := NVL(SUBSTR(lv_incl_ip4addr,
                                          INSTR(lv_incl_ip4addr,'|', 1, 1) + 1,
                                          INSTR(lv_incl_ip4addr,'|', 1, 2) - INSTR(lv_incl_ip4addr,'|', 1, 1) - 1), '�����������');
        END IF;
        -- ���������� IP-���������
        IF is_unload_field('DEDICATED_IPADDRESSING', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          IF TREC.IP_METHOD_ASSIGN = '�����������' THEN
            TREC.DEDICATED_IPADDRESSING := '��';
          ELSIF TREC.IP_METHOD_ASSIGN = '������������' THEN
            TREC.DEDICATED_IPADDRESSING := '���';
          ELSE
            TREC.DEDICATED_IPADDRESSING := '�����������';
          END IF;
          /*
          TREC.DEDICATED_IPADDRESSING := NVL(SUBSTR(lv_incl_ip4addr,
                                   INSTR(lv_incl_ip4addr,'|', 1, 2) + 1,
                                   INSTR(lv_incl_ip4addr,'|', 1, 3) - INSTR(lv_incl_ip4addr,'|', 1, 2)-1), '��');
          */
        END IF;
        -- ��� IPv4 ������
        IF is_unload_field('IPV4_TYPE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.IPV4_TYPE :=  NVL(SUBSTR(lv_incl_ip4addr, instr(lv_incl_ip4addr,'|', -1, 1) + 1, 500), '���������');
        END IF;
        -- �������� ���� ���������� ��������� (����� 3/4G, ��������� 3/4G)
        -- ������������ ����� INV_NAME
        IF is_unload_field('MOB_INT_TARIF_PLAN', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.MOB_INT_TARIF_PLAN := CASE
                                       WHEN INSTR(UPPER(gv_tbpi_int_arr(i).PLAN_NAME), '�����') > 0 THEN '����� 3/4G'
                                       WHEN INSTR(UPPER(gv_tbpi_int_arr(i).PLAN_NAME), '���������') > 0 THEN '��������� 3/4G'
                                       ELSE NULL
                                     END;
        END IF;
        -- ������� ������ (�����) �� ������� ����. ����������� �� ��������� ������ �� �������� �������.
        -- ph2i5
        IF is_unload_field('MRC_CUPON', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.MRC_CUPON := lv_mrc_rec.mrc_cupon;
        END IF;
        -- ����������� ����� � �������� �� ������� ��������� �������� � ������� Active ��� Disconnected
        -- ��� ����� ���� �� ���������� ��������� ����������� �������. �������� ������ ���� �������� �� 100 000
        IF is_unload_field('MRC', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.MRC := lv_mrc_rec.mrc * lc_koef_bss_mrc;
          --TREC.MRC := ROUND(lv_mrc_rec.mrc_without_nds * lv_mrc_rec.koef_nds, 2) * lc_koef_bss_mrc;
        END IF;
        -- ��� �������, ������������ � ���������������� ����������
        IF is_unload_field('LEGACY_OBJECT_NAME', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.LEGACY_OBJECT_NAME := gv_tbpi_int_arr(i).PLAN_NAME;
        END IF;
        -- ������ �� ������������ ������ - �������� ������� (IDB_PH2_CUSTOMER.IDB_ID)
        IF is_unload_field('PARENT_ID', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.PARENT_ID := gv_tbpi_int_arr(i).PARENT_ID;
        END IF;
        -- ���� ����������� ����������� ����� �� �������.
        -- �� ������ ��  ��������� �������� ��������� <veronika.gorbunova@domru.ru>   13.02.2020 15:05
        /*
        IF is_unload_field('PREV_BILL_TO_DAT', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.PREV_BILL_TO_DAT := CASE WHEN TREC.BILLED_TO_DAT IS NULL THEN NULL ELSE add_months(TREC.BILLED_TO_DAT, -1) END;
        END IF;
        */
        -- �������� ������� ����� ������� ��������
        -- �������������� ������� ����� ������� ��������
        IF is_unload_field('PRIMARY_STATUS_REASON', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.PRIMARY_STATUS_REASON := NULL;
          TREC.SECOND_STATUS_REASON  := NULL;
          FOR rec IN (
            select af.flag_name,
                   (select afg.group_name
                      from flag_link_groups_all flg,
                           agreement_flag_groups_all afg
                      where 1=1
                        and flg.flag_id = fl.flag_id
                        and flg.billing_id = fl.billing_id
                        and afg.agreement_flag_group_id = flg.agreement_flag_group_id
                        and afg.billing_id = flg.billing_id
                        and afg.agree_flag_group_type_id+0 in (7 ,8)
                        and rownum = 1
                   ) group_name
              from teo_link_addenda_all tla,
                   teo_all             te,
                   teo_flag_links_all  fl,
                   agreement_flags_all af,
                   flag_types_all      ft
              where 1 = 1
                and tla.addendum_id = gv_tbpi_int_arr(i).ADDENDUM_ID
                and tla.billing_id  = gv_tbpi_int_arr(i).BILLING_ID
                and tla.active_from <= lc_current_date
                and nvl(tla.active_to, lc_current_date + 1) > lc_current_date
                --
                and te.teo_id =  tla.teo_id
                and te.billing_id = tla.billing_id
                --
                -- and te.point_plugin_id =
                --
                and fl.teo_id = te.teo_id
                and fl.billing_id = te.billing_id
                and fl.active_from <= lc_current_date
                and nvl(fl.active_to, lc_current_date + 1) > lc_current_date
                and af.flag_id = fl.flag_id
                and af.billing_id = fl.billing_id
                and af.active_from <= lc_current_date
                and nvl(af.active_to, lc_current_date + 1) > lc_current_date
                -- and af.flag_name like '��������� �������%'
                and ft.flag_type_id = 4
                and ft.flag_type_id = af.flag_type_id
                and ft.billing_id = af.billing_id
                and rownum = 1
                and not exists
                (SELECT 1 -- ���� ���� �������� ������ �� �� ������� ����, �� ext_bpi_status = 'Active'; SECOND_STATUS_REASON ��� ACTIVE �� �����������
                 FROM activate_license_fee_all alf, plan_items_all pi
                 WHERE alf.addendum_id = tla.addendum_id
                 AND alf.billing_id = tla.billing_id
                 AND alf.active_from <= lc_current_date
                 AND (alf.active_to IS NULL OR alf.active_to > lc_current_date)
                 AND alf.plan_item_id = pi.plan_item_id
                 AND alf.billing_id = pi.billing_id
                 AND pi.service_id = 237
                 AND rownum <= 1)
                
          ) LOOP
            TREC.PRIMARY_STATUS_REASON := rec.group_name;
            TREC.SECOND_STATUS_REASON  := rec.flag_name;
          END LOOP;
        END IF;
        -- ������������� ������� ������ �������� �������
        IF is_unload_field('SOURCE_ID', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.SOURCE_ID := gv_tbpi_int_arr(i).ADDENDUM_ID;
        END IF;
        -- ������������� ���������� �������� �������
        TREC.SOURCE_SYSTEM := gv_tbpi_int_arr(i).BILLING_ID;
        -- ������������� ���� �������� ������� (����, ����, ������,...)
        TREC.SOURCE_SYSTEM_TYPE := '1';
        -- ����� �� ����������� ����� �������� ��������. �������� ������ ���� �������� �� 100 000
        IF is_unload_field('TAX_MRC', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.TAX_MRC := lv_mrc_rec.tax_mrc * lc_koef_bss_mrc;
          --TREC.TAX_MRC := ROUND(lv_mrc_rec.mrc_without_nds * (lv_mrc_rec.koef_nds - 1), 2) * lc_koef_bss_mrc;
        END IF;
        -- ���� ���������
        /*
        -- ������� � ��25 03.03.2021
        IF is_unload_field('UNINSTL_DATE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.UNINSTL_DATE := GET_UNINSTL_DATE(P_AGREEMENT_ID => gv_tbpi_int_arr(i).AGREEMENT_ID,
                                                P_BILLING_ID   => gv_tbpi_int_arr(i).BILLING_ID);
        END IF;
        */
        -- ������ ������-����������
        -- https://kb.ertelecom.ru/display/Netcracker/10.02.27+IDB_PH2_TBPI_INT#id-10.02.27IDB_PH2_TBPI_INT-DIRECT_PROH_INT
        IF is_unload_field('DIRECT_PROH', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.DIRECT_PROH := '��';
        END IF;

        --===============
        -- #��6#It6#
        --===============
        IF is_unload_field('MA_FLAG', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.MA_FLAG := '�������� ������';
        END IF;
        IF is_unload_field('MA_FLAG_DATE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.MA_FLAG_DATE := TRUNC(lc_current_date);
        END IF;
        -- ����� �������
        TREC.ACCESS_MODE := NULL;
        --TREC.ACCESS_MODE_END_DATE := NULL;
        --
        IF is_unload_field('BPI_TIME_ZONE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          IF lv_curr_billing = 0 then
          TREC.BPI_TIME_ZONE := rias_mgr_support.get_time_zone_pp(ip_pp_id$i => gv_tbpi_int_arr(i).point_plugin_id, 
                                                                  ip_billing_id$i => lv_curr_billing);
          else
          TREC.BPI_TIME_ZONE := rias_mgr_support.get_time_zone(ip_city_id$i => lv_curr_billing,
                                                               ip_what_give$c => 'N');
          end if;
        END IF;
        --
        IF is_unload_field('NETWORK', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.NETWORK := GET_NETWORK(P_AGREEMENT_ID => gv_tbpi_int_arr(i).agreement_id,
                                      P_ADDENDUM_ID  => gv_tbpi_int_arr(i).addendum_id,
                                      P_BILLING_ID   => gv_tbpi_int_arr(i).billing_id);
        END IF;
        -- ���� ��������� ��������� ����� � �������� �������
        --IF is_unload_field('RATE_PLAN_ACTIVATION_DATE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.RATE_PLAN_ACTIVATION_DATE := gv_tbpi_int_arr(i).actual_start_date;
        --END IF;
        -- ��� ��������� ����� � �������� �������
        --IF is_unload_field('RATE_PLAN_CODE', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.RATE_PLAN_CODE := gv_tbpi_int_arr(i).addendum_id;
        --END IF;
        -- ������������� ��������� ����� � �������� �������
        --IF is_unload_field('RATE_PLAN_ID', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.RATE_PLAN_ID := gv_tbpi_int_arr(i).plan_id;
          
          TREC.RATE_PLAN_NAME := gv_tbpi_int_arr(i).plan_name;

        --END IF;

        IF is_unload_field('SUSPEND_REASON', TREC.OFF_ID_FOR_MIGR) = 1 AND TREC.EXT_BPI_STATUS = 'Suspended' THEN
          TREC.SUSPEND_REASON := rias_mgr_support.get_map_value_str('IDB_PH2_TBPI_INT',
                                                                    'SUSPEND_REASON',
                                                                    rias_mgr_support.get_teo_flag_name(gv_tbpi_int_arr(i).addendum_id,
                                                                                                       gv_tbpi_int_arr(i).billing_id,
                                                                                                       16,
                                                                                                       gv_tbpi_int_arr(i).cur_date,
                                                                                                       gv_tbpi_int_arr(i).agreement_id,
                                                                                                       gv_tbpi_int_arr(i).point_plugin_id
                                                                    ));
        END IF;

        --===============
        -- #��8#It8#
        --===============
        TREC.IS_BASED_MRC := NULL;

        --===============
        --It12��12
        --===============
        IF is_unload_field('BARRING', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.BARRING := NVL(gv_tbpi_int_arr(i).barring_toms_bpi, 'N');
        END IF;
        --
        IF is_unload_field('MRC_CUPON_MNT', TREC.OFF_ID_FOR_MIGR) = 1 THEN
          TREC.MRC_CUPON_MNT := lv_mrc_rec.mrc_discount * lc_koef_bss_mrc;
          --TREC.MRC_CUPON_MNT := ROUND(NVL(TREC.MRC, 0)/100000*NVL(TREC.MRC_CUPON, 0)/100, 2)*100000;
        END IF;

        --================================== Mapping
        -- 1. https://jsd.netcracker.com/browse/ERT-19300
        IF TREC.OFF_ID_FOR_MIGR = '121000296' AND TREC.CONNECT_TYPE = 'FTTB RIAS' THEN
          IF lv_speed_night IN (1,10,100,15,2,20,3,30,4,5,50,6,7,8,9) THEN
            TREC.OFF_ID_FOR_MIGR := '121000121';
            TREC.INV_NAME        := '�������� ������� ������';
          ELSE
            TREC.OFF_ID_FOR_MIGR := '121000390';
            TREC.INV_NAME        := '�������� ��������������';
          END IF;
        END IF;
        --A.Kosterin 09.12.2021 ��������� ������������� �� ���
        IF (gv_tbpi_int_arr(i).plan_name like '%�������%' or TREC.NETWORK = '�������') 
          and gv_tbpi_int_arr(i).plan_group_id in (41, 77, 86)
          THEN
            if lv_speed_night IN (1, 3, 4, 6, 7, 8, 9, 15, 40, 60, 80, 90, 100) then
               TREC.OFF_ID_FOR_MIGR := '121000296';
               TREC.INV_NAME        := '�������� ������������ ������';
            elsif lv_speed_night IN (2, 5, 10, 20, 30, 50, 70) then
               TREC.OFF_ID_FOR_MIGR := '9161228920313303218';
               TREC.INV_NAME        := '�������� ������������';
            end if;
        END IF;
        
        IF TREC.SOURCE_SYSTEM = 556 AND TREC.OFF_ID_FOR_MIGR in (121000121, 121000296) 
          AND gv_tbpi_int_arr(i).plan_group_id in (77) THEN 
          IF gv_tbpi_int_arr(i).plan_name like '%���������%' AND gv_tbpi_int_arr(i).plan_name not like '%����%' 
             THEN
               TREC.OFF_ID_FOR_MIGR := '9161358501513727314';
               TREC.INV_NAME        := '�������� ���������';
          ELSIF gv_tbpi_int_arr(i).plan_name like '%���������%����%' THEN
               TREC.OFF_ID_FOR_MIGR := '9161358500513727314';
               TREC.INV_NAME        := '�������� ���������-����';
          ELSIF gv_tbpi_int_arr(i).plan_name like '%����%' THEN
               TREC.OFF_ID_FOR_MIGR := '9161358502513727314';
               TREC.INV_NAME        := '�������� ����';
          END IF;
        END IF;
        
        --================================== End Mapping

        --============================
        -- ������� � ������ ��� �������
        --============================
        gv_rec_arr(gv_rec_arr.COUNT +1) := TREC;

          -- �������� DBG-����������
          rias_mgr_core.insert_dbg_info(
            ip_table_id  => lc_table_id$i,
            ip_dbg_info  =>
              SUBSTR('�������: '         || TO_CHAR(lv_curr_billing)                  || CHR(13) ||
                     '�������: '         || gv_tbpi_int_arr(I).AGREEMENT_NUMBER       || CHR(13) ||
                     'AGREEMENT_ID: '    || TO_CHAR(gv_tbpi_int_arr(I).AGREEMENT_ID)  || CHR(13) ||
                     '����� ����������: '|| gv_tbpi_int_arr(I).ADDENDUM_NUMBER        || CHR(13) ||
                     'P_ADDENDUM_ID: '   || TO_CHAR(gv_tbpi_int_arr(I).ADDENDUM_ID)   || CHR(13) ||
                     'PLAN_GROUP_ID: '   || TO_CHAR(gv_tbpi_int_arr(I).PLAN_GROUP_ID) || CHR(13) ||
                     'PLAN_ID: '         || TO_CHAR(gv_tbpi_int_arr(I).PLAN_ID)       || CHR(13) ||
                     'PLAN_NAME: '       || gv_tbpi_int_arr(I).PLAN_NAME              || CHR(13) ||
--                     'PLAN_ITEM_ID: '    || TO_CHAR(gv_tbpi_int_arr(I).PLAN_ITEM_ID)  || CHR(13) ||
--                     'SERVICE_ID: '      || TO_CHAR(gv_tbpi_int_arr(I).service_id)    || CHR(13) ||
                     'ACTUAL_START_DATE: '     || TO_CHAR(gv_tbpi_int_arr(i).actual_start_date,'dd.mm.yyyy') || CHR(13) ||
                     'ACTUAL_END_DATE: '       || TO_CHAR(gv_tbpi_int_arr(i).actual_end_date,'dd.mm.yyyy')   || CHR(13) ||
                     '������:'                                                                            || CHR(13) ||
                     '  KOEF_NDS: '      || TO_CHAR(lv_mrc_rec.koef_nds)                                  || CHR(13) ||
                     '  ��������� ������ ��� ���: '                || TO_CHAR(lv_mrc_rec.serv_cost)       || CHR(13) ||
                     '  % ������: '                                || TO_CHAR(lv_mrc_rec.mrc_cupon)
                     --|| CHR(13) || '  ��������� ������ � ������ ������ ��� ���: '|| TO_CHAR(lv_mrc_rec.mrc_without_nds)
                , 1, 4000
              ),
            ip_idb_id    => TREC.IDB_ID
          );

      EXCEPTION
        WHEN OTHERS THEN
          -- �������� ���������� �� ������
          lv_err_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => lc_table_id$i,
                                                          ip_message => SUBSTR('Err: ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace || --chr(13) ||
                                                                               'DEBUG_INFO:' || chr(13) ||
                                                                               '�������: '          ||lv_curr_billing || CHR(13) ||
                                                                               '�������: '          || gv_tbpi_int_arr(I).AGREEMENT_NUMBER || '(' || TO_CHAR(gv_tbpi_int_arr(I).AGREEMENT_ID)|| ')' || CHR(13) ||
                                                                               '����� ����������: ' || gv_tbpi_int_arr(I).ADDENDUM_NUMBER  || '(' || TO_CHAR(gv_tbpi_int_arr(I).ADDENDUM_ID) || ')' || CHR(13) ||
                                                                               'IDB_ID: '           || gv_tbpi_int_arr(I).IDB_ID || CHR(13) ||
                                                                               'PARENT_ID: '        || gv_tbpi_int_arr(I).PARENT_ID || CHR(13) ||
                                                                               'PLAN_ID: '          || TO_CHAR(gv_tbpi_int_arr(I).PLAN_ID)
                                                                               --'PLAN_ITEM_ID: '     || TO_CHAR(gv_tbpi_int_arr(I).PLAN_ITEM_ID) || CHR(13) ||
                                                                               --'ACTIVITY_ID: '      || TO_CHAR(gv_tbpi_int_arr(I).ACTIVITY_ID)
                                                                               , 1, 2000),
                                                          ip_err_code => SUBSTR('SQLCODE = ' || TO_CHAR(SQLCODE) ||' SQLERRM = ' || SQLERRM, 1, 200),
                                                          ip_thread_id => ip_thread$i,
                                                          ip_city_id => lv_curr_billing,
                                                          ip_slog_slog_id => lv_slog_id);
      --RAISE;
      END;
      END LOOP; -- LOOP SERVICES LIMIT
      -- ������� �������������� ������ � �������
      INSERT_ROWS();
    END LOOP; -- LOOP SERVICES

    -- ������� ������ �� �������
    IF phase_id$i = 4 and lv_curr_billing = 0 THEN

      CLOSE LC_TBPI_INT_2;
    else
      CLOSE LC_TBPI_INT;
    end if;
    -- ������� ����������� ������ � ������� (�� ������ ���� �������)
    INSERT_ROWS();

    -- ���� ���� ����������� ����� ������� ������, �� ������ ���
    IF lc_action AND lc_commit_after_city THEN
      COMMIT;
    END IF;

    -- �������� ����� ������ �� ������
    RIAS_MGR_CORE.update_log_info(ip_slog_id => lv_slog_id,
                                  ip_reccount => lv_count_rows,
                                  ip_duration => rias_mgr_support.get_elapsed_time(lv_time_start, dbms_utility.get_time),
                                  ip_date_end => sysdate);
  END LOOP; -- LOOP BILLING


  -- ����� �������� ������
  INSERT_ROWS();
  


  dbms_application_info.set_action(action_name => 'COMMIT after LOOP');
  IF lc_commit AND lc_action THEN
    COMMIT;
  END IF;

  RIAS_MGR_CORE.restore_session_state;

  -- �������� ������ ����� DBG-����������
  rias_mgr_core.dbg_stop;
/*
EXCEPTION
  WHEN OTHERS THEN
    IF LC_TBPI_INT%ISOPEN THEN
      CLOSE LC_TBPI_INT;
    END IF;
    RIAS_MGR_SUPPORT.restore_session_state;
    dbms_output.put_line('ALL TIME (error)= ' || to_char(get_elapsed_time(lv_time_start, dbms_utility.get_time)) || ' �.');
    RAISE_APPLICATION_ERROR(-20001, SUBSTR(dbms_utility.format_error_stack || dbms_utility.format_error_backtrace, 1, 2000));
*/
END RIAS_FILL_TBPI_PROC;
/

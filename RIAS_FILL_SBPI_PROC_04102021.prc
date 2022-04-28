CREATE OR REPLACE PROCEDURE IDB_PROD.RIAS_FILL_SBPI_PROC
/**
* ������������ ������ ��� IDB_PH2_SBPI_INT
* @param ip_thread$i     - ����� ������ ����������
* @param ip_thread_cnt$i - ����� ������� � ����������
* @param ip_slog_id$i    - ������������ ���.������ � ����
*
* �������� 16.01.2020 ������� �.�.
*
* � ��������� ������������ SERVICE_ID=237. ����� ������� ������� ����������� (SERVICE_ID=163), ��������� �� ���
*/
(
  ip_thread$i     IN PLS_INTEGER,
  ip_thread_cnt$i IN PLS_INTEGER,
  ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
)
IS
  dml_errors EXCEPTION; -- ORA-24381 error(s) in array DML
  PRAGMA EXCEPTION_INIT(dml_errors, -24381);

  --================================
  -- ���������
  --================================
  -- ID ������� IDB_PH2_SBPI_INT
  lc_table_id$i CONSTANT INTEGER := rias_mgr_const.gc_sbpi_int;
  -- ��� ������� IDB_PH2_SBPI_INT
  lc_table_name$c CONSTANT VARCHAR2(50) := rias_mgr_const.get_table_name(lc_table_id$i);
  -- ���� ��� COMMIT ����� ������� ������
  lc_commit_after_city CONSTANT BOOLEAN := TRUE;
  -- ��� "����� �������� �������" � "����������� ����� � ��������"
  lc_koef_bss_mrc CONSTANT PLS_INTEGER := 100000;
  -- ��� ������ �������� � ���������� ������
  lc_work_module_name CONSTANT VARCHAR2(100) := rias_mgr_const.get_process_prefix(lc_table_id$i) || '_THREAD:'||TO_CHAR(ip_thread$i)||'/'||TO_CHAR(ip_thread_cnt$i);
  -- ������� ������� ����� � ��������� �� ������� �����
  lc_rec_limit CONSTANT PLS_INTEGER := 5000;
  -- ������� ����
  lc_current_date CONSTANT DATE := rias_mgr_support.get_current_date();
  --17.02.2021 feature_toggle for [ERT-19486] (���.ip � �������)
  lv_swtch_value_ert_19486 CONSTANT INTEGER := rias_mgr_core.get_feature_toggle(7);

  --================================
  -- ����
  --================================
  TYPE t_mrc_rec IS RECORD(koef_nds  NUMBER,      -- ���������� ��� (��������, 1.2)
                           serv_cost NUMBER,      -- ��������� ������ ��� ���
                           mrc_cupon NUMBER,      -- % ������ �� ���������� ������ ��� �� ������ ������
                           mrc_without_nds NUMBER,-- ��������� ������ � ������ ������
                           mrc_with_nds NUMBER    -- ��������� ������ � ������ ���
  );
  TYPE t_rec_arr IS TABLE OF idb_ph2_sbpi_int%ROWTYPE INDEX BY PLS_INTEGER;
  -- ��� ������ ���������� � ������������ TBPI
  TYPE t_tbpi_rec IS RECORD(access_speed      idb_ph2_tbpi_int.access_speed%TYPE,
                            auth_type         idb_ph2_tbpi_int.auth_type%TYPE,
                            parent_service_id idb_ph2_tbpi_int.service_id%TYPE,
                            off_id_for_migr   idb_ph2_tbpi_int.off_id_for_migr%TYPE,
                            actual_start_date idb_ph2_tbpi_int.actual_start_date%TYPE,
                            bpi_market        idb_ph2_tbpi_int.bpi_market%TYPE,
                            bpi_organization  idb_ph2_tbpi_int.bpi_organization%TYPE,
                            barring           idb_ph2_tbpi_int.barring%TYPE,
                            customer_location idb_ph2_tbpi_int.customer_location%TYPE
  );
  -- ������ �� ������ ������ ����
  --TYPE t_unload_field IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(100);
  -- ������ ��������� ��� ���� SERVICE_ID
  TYPE t_offer_prefix IS TABLE OF VARCHAR2(200) INDEX BY VARCHAR2(100);

  --================================
  -- ����������
  --================================
  lv_slog_id      PLS_INTEGER;
  lv_err_slog_id  PLS_INTEGER;
  lv_curr_billing PLS_INTEGER;
  lv_time_start   NUMBER;
  lv_prefix       VARCHAR2(50);
  lv_task_id      INTEGER;
  -- ������ ����
  lv_mrc_rec t_mrc_rec;
  -- ����������� ��������� �������
  SREC       IDB_PH2_SBPI_INT%ROWTYPE;
  SREC_CHILD IDB_PH2_SBPI_INT%ROWTYPE;
  -- ������� ������������ �������
  lv_count_rows   PLS_INTEGER := 0;
  lv_count_adr_all PLS_INTEGER := 0;
  lv_num_iteration PLS_INTEGER := 0;
  -- ��� ������ ���������� � ������������ TBPI
  lv_tbpi_rec t_tbpi_rec;
  -- ������ ��� ����� ���������� (������������ � FORALL)
  gv_rec_arr T_REC_ARR;
  -- ������ ������� ��� ��������� � ������
  lv_cities_list RIAS_MGR_CORE.t_cities_list;
  -- ������ �� ������ ������ ����
  --lv_unload_field t_unload_field;
  -- ������ ��������� ��� ���� SERVICE_ID
  lv_offer_prefix t_offer_prefix;
  -- IP-����� "�����" ��� "�����"
  lv_ip_is_local$i PLS_INTEGER;

  --������ �� ������� (Secondary Level )
  CURSOR LC_SBPI_INT(P_BILLING_ID INTEGER, P_TASK_ID INTEGER) IS
    WITH tbl AS(
      -- �� �������
      SELECT
           --CASE WHEN PI.SERVICE_ID = 101646 THEN 1 ELSE 0 END AS GRP,
           0 AS GRP,
           AD.AGREEMENT_ID,
           AC.LEGACY_ACCOUNT_NUM AGREEMENT_NUMBER,
           AD.BILLING_ID,
           AD.ADDENDUM_ID,
           AD.ADDENDUM_NUMBER,
           ALF.PLAN_ITEM_ID,
           ALF.ACTIVITY_ID,
           ALF.ACTIVE_FROM,
           ALF.ACTIVE_TO,
           PA.PLAN_NAME,
           AC.PARENT_ID CUSTOMER_IDB_ID,
           AC.IDB_ID    ACCOUNT_IDB_ID,
           SE.SERVICE_ID,
           PA.PLAN_ID,
           (CASE
            WHEN pi.SERVICE_ID = 163          THEN '121000020' -- �������������� ������� � ������ �����   (������� ������)
            WHEN pi.SERVICE_ID = 101572       THEN '121000093'
            WHEN pi.SERVICE_ID = 101392       THEN '121000072' -- ������ �� DDoS (SP)
            WHEN pi.SERVICE_ID = 102233       THEN '121000614' -- ������ �� DDoS ����
            WHEN pi.SERVICE_ID IN (1799, 534) THEN '121000087'
            WHEN pi.SERVICE_ID = 102271 THEN
              CASE WHEN EXISTS(SELECT 1 /*
                                        TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="18.12.2019"
                                        text="����������� �� ������ ����� �� ��� ������"
                                        */
                               FROM addendum_resources_all    ar1,
                                    resource_contents_all     rc1,
                                    cable_city_ip_subnets_all sn
                               WHERE 1 = 1
                                 AND ar1.addendum_id = ad.addendum_id
                                 AND ar1.billing_id = ad.billing_id
                                 AND ar1.billing_id = P_BILLING_ID
                                 AND ar1.active_from <= lc_current_date
                                 AND (ar1.active_to IS NULL OR ar1.active_to > trunc(lc_current_date,'mm')) -- ??
                                 /*
                                 AND ar1.active_from <= nvl(rc1.active_to, ar1.active_from + 1)
                                 AND nvl(ar1.active_to, rc1.active_from + 1) > rc1.active_from
                                 */
                                 AND rc1.resource_id = ar1.resource_id
                                 AND rc1.billing_id = ar1.billing_id
                                 AND rc1.billing_id = P_BILLING_ID
                                 AND rc1.active_from <= lc_current_date
                                 AND (rc1.active_to IS NULL OR rc1.active_to > trunc(lc_current_date,'mm')) -- ??
                                 AND sn.terminal_resource_id = rc1.terminal_resource_id
                                 AND sn.billing_id = rc1.billing_id
                                 AND sn.billing_id = P_BILLING_ID
                                 AND sn.ip_v6 IS NULL
                                 AND ROWNUM <= 1) THEN
                 '121000102'
              ELSE
                 '121000501'
              END
            WHEN pi.SERVICE_ID = 101169 THEN '121000021'
            WHEN pi.SERVICE_ID = 101171 THEN '121000021'
            WHEN pi.SERVICE_ID = 101161 THEN '121000021'
            WHEN pi.SERVICE_ID = 101170 THEN '121000021'
            WHEN pi.SERVICE_ID = 1678   THEN '121000117'
            WHEN pi.SERVICE_ID = 101646 THEN '121000080'
           END) AS OFF_ID_FOR_MIGR,
           TLO.IDB_ID AS TLO_IDB_ID,
           NULL AS connect_pays_id -- ���������� ��� ������� �����, ��������� �� ���
      FROM IDB_PH2_TBPI_INT         TLO,
           PLANS_ALL                PA,
           ADDENDA_ALL              AD,
           PLAN_ITEMS_ALL           PI,
           ACTIVATE_LICENSE_FEE_ALL ALF,
           SERVICES_ALL             SE,
           AGREEMENTS_ALL           AG,
           IDB_PH2_ACCOUNT          AC
      WHERE 1=1
        AND TLO.SOURCE_SYSTEM_TYPE='1'
        AND TLO.SOURCE_SYSTEM = TO_CHAR(P_BILLING_ID)
        AND TLO.IDB_ID LIKE 'TI_1/%'
        --
        AND TLO.SOURCE_ID = AD.ADDENDUM_ID
        AND TLO.SOURCE_SYSTEM = AD.BILLING_ID
       -- ����� � ������������ ���������
       AND AD.PLAN_ID = PA.PLAN_ID
       AND AD.BILLING_ID = PA.BILLING_ID
       AND AD.BILLING_ID = P_BILLING_ID
       -- �������� ����� BGP
       AND INSTR(UPPER(PA.PLAN_NAME), 'BGP') = 0
       -- ����� � ����������
       AND AG.AGREEMENT_ID = AD.AGREEMENT_ID
       AND AG.BILLING_ID = AD.BILLING_ID
       AND AG.BILLING_ID = P_BILLING_ID
       AND AC.SOURCE_ID = TO_CHAR(AG.AGREEMENT_ID)
       AND AC.SOURCE_SYSTEM = TO_CHAR(AG.BILLING_ID)
       AND AC.SOURCE_SYSTEM = TO_CHAR(P_BILLING_ID)
       AND AC.SOURCE_SYSTEM_TYPE = '1'
       -- ����� � ����������� ����� ���������� � ������� �����
       AND ALF.ADDENDUM_ID = AD.ADDENDUM_ID
       AND ALF.BILLING_ID = AD.BILLING_ID
       AND ALF.BILLING_ID = P_BILLING_ID
       AND ALF.ACTIVE_FROM <= lc_current_date --��������
       AND COALESCE(ALF.ACTIVE_TO, lc_current_date + 1) > TRUNC(lc_current_date, 'MM')
       -- ����� � ��������
       AND PI.PLAN_ITEM_ID = ALF.PLAN_ITEM_ID
       AND PI.BILLING_ID = ALF.BILLING_ID
       AND PI.BILLING_ID = P_BILLING_ID
       AND PI.SERVICE_ID IN (163,    -- ��������� - �������������� ������� � ������� ����� "������ � ��������"
                             1678, -- ������������� �������� - ����� "���������� ��������"
                             534,    -- ��������� ��������������� IP-������
                             1799,   -- ����������� ����� �� �������������� ip-������
                             101161, -- ����������� ����� �� ������ "�������-����������" (��� �������)
                             101169, -- ����������� ����� �� ������ "�������-����������" (��� ����)
                             101170, -- ����������� ����� �� ������ "�������-����������" (������ +)
                             101171, -- ����������� ����� �� ������ "�������-����������" (��� ����������)
                             101392, -- ����������� ����� �� ������ "���������� ������� � ������ �� DDoS- ����" (ServicePipe)
                             101572, -- IPv6
                             101646, -- ������������� �������� - ������� ����� "���������� ��������"
                             102233, -- ����������� ����� �� ������ "���������� ������� � ������ �� DDoS- ����" (DDoS-GUARD)
                             102271  -- ����������� ����� �� ������� IP
                             ) --������ Secondary Level
          -- ����� � ��������
       AND SE.SERVICE_ID = PI.SERVICE_ID
       AND SE.BILLING_ID = PI.BILLING_ID
       AND SE.BILLING_ID = P_BILLING_ID
       --=======
       -- and ad.agreement_id= 5113654;
       --=======
       AND EXISTS (SELECT 1 --���� �������� ��������
                   FROM ADDENDA_ALL              AD_1,
                        ACTIVATE_LICENSE_FEE_ALL ALF_1,
                        PLAN_ITEMS_ALL           PI_1
                   WHERE 1 = 1
                     AND AD_1.ADDENDUM_ID = AD.ADDENDUM_ID
                     AND AD_1.BILLING_ID = AD.BILLING_ID
                     AND AD_1.BILLING_ID = P_BILLING_ID
                     AND ALF_1.ADDENDUM_ID = AD_1.ADDENDUM_ID
                     AND ALF_1.BILLING_ID = AD_1.BILLING_ID
                     AND ALF_1.BILLING_ID = P_BILLING_ID
                     AND ALF_1.ACTIVE_FROM <= lc_current_date
                     AND (ALF_1.ACTIVE_TO IS NULL OR ALF_1.ACTIVE_TO > TRUNC(lc_current_date, 'MM'))
                     AND PI_1.PLAN_ITEM_ID = ALF_1.PLAN_ITEM_ID
                     AND PI_1.BILLING_ID = ALF_1.BILLING_ID
                     AND PI_1.BILLING_ID = P_BILLING_ID
                     AND PI_1.SERVICE_ID = 237
                     AND rownum <= 1
       )
       -- !!!! ����� �������� !!!!
       AND (PI.SERVICE_ID != 163 OR (ALF.ACTIVE_FROM >= TRUNC(lc_current_date, 'MM')))
       --
       AND (SE.SERVICE_ID != 163 OR NOT EXISTS(SELECT 1
                      FROM RIAS_MGR_TMP_LIST tl
                      WHERE 1 = 1
                        AND tl.task_id = P_TASK_ID
                        AND tl.billing_id = ad.billing_id
                        --AND tl.agreement_id = ad.agreement_id
                        AND tl.addendum_id = ad.addendum_id
                        AND rownum<=1)
       )

       UNION ALL
       -- �� ���
       SELECT
           0 AS GRP,
           agreement_id,     -- AGREEMENT_ID
           str1,             -- AGREEMENT_NUMBER
           billing_id,       -- BILLING_ID
           addendum_id,      -- ADDENDUM_ID
           str3,             -- ADDENDUM_NUMBER
           plan_item_id,     -- PLAN_ITEM_ID
           activity_id,      -- ACTIVITY_ID
           active_from,      -- ACTIVE_FROM
           active_to,        -- ACTIVE_TO
           str2,             -- PLAN_NAME
           customer_idb_id,  -- CUSTOMER_IDB_ID
           account_idb_id,   -- ACCOUNT_IDB_ID
           service_id,       -- SERVICE_ID
           plan_id,          -- PLAN_ID
           off_id_for_migr,  -- OFF_ID_FOR_MIGR
           str4,             -- TLO.IDB_ID
           id1               -- CONNECT_PAYS_ID
      FROM RIAS_MGR_TMP_LIST tl
      WHERE tl.task_id = P_TASK_ID
  )
  SELECT BILLING_ID,
         AGREEMENT_ID,
         AGREEMENT_NUMBER,
         ADDENDUM_ID,
         ADDENDUM_NUMBER,
         PLAN_ITEM_ID,
         ACTIVITY_ID,
         ACTIVE_FROM,
         ACTIVE_TO,
         PLAN_NAME,
         CUSTOMER_IDB_ID,
         ACCOUNT_IDB_ID,
         --PARENT_ID,
         SERVICE_ID,
         PLAN_ID,
         --CREATED_WHEN,
/*
           (SELECT 'TI_1/'                      ||
                   TO_CHAR(AD_1.BILLING_ID)     || '/' ||
                   TO_CHAR(AD_1.AGREEMENT_ID)   || '/' ||
                   TO_CHAR(AD_1.ADDENDUM_ID)    || '/' ||
                   TO_CHAR(ALF_1.PLAN_ITEM_ID)  || '/' ||
                   TO_CHAR(ALF_1.ACTIVITY_ID)
            FROM ADDENDA_ALL              AD_1,
                 ACTIVATE_LICENSE_FEE_ALL ALF_1,
                 PLAN_ITEMS_ALL           PI_1
            WHERE 1 = 1
              AND AD_1.ADDENDUM_ID  = t.ADDENDUM_ID
              AND AD_1.BILLING_ID   = t.BILLING_ID
              AND ALF_1.ADDENDUM_ID = AD_1.ADDENDUM_ID
              AND ALF_1.BILLING_ID  = AD_1.BILLING_ID
              AND ALF_1.BILLING_ID  = t.BILLING_ID
              AND ALF_1.ACTIVE_FROM <= lc_current_date --��������*\
              AND COALESCE(ALF_1.ACTIVE_TO, lc_current_date + 1) > TRUNC(lc_current_date, 'MM')
              AND PI_1.PLAN_ITEM_ID = ALF_1.PLAN_ITEM_ID
              AND PI_1.BILLING_ID   = ALF_1.BILLING_ID
              AND PI_1.BILLING_ID   = t.BILLING_ID
              AND PI_1.SERVICE_ID   = 237
              AND rownum<=1\*
                           TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="19.03.2020"
                           text="������������ ������.
                                 ������� ������������ ������ � ������� alf.acive_to <= lc_current_date, ����� � ������ alf.acive_to is null ��� alf.acive_to > lc_current_date"
                           *\
           ) PARENT_ID,
*/
            (SELECT TRUNC(FTA.TIME_STAMP)
              FROM ACTIVATE_LIC_FEE_TIMESTAMP_ALL FTA
             WHERE FTA.ACTIVITY_ID = t.ACTIVITY_ID
               AND FTA.BILLING_ID = t.BILLING_ID) CREATED_WHEN
         ,(CASE
             WHEN OFF_ID_FOR_MIGR IS NOT NULL THEN OFF_ID_FOR_MIGR
             WHEN SERVICE_ID IN (163, 237) THEN '121000020' -- �������������� ������� � ������ �����   (������� ������)
             WHEN SERVICE_ID = 101572 THEN '121000093' -- �������������� IPv6 �������
             WHEN SERVICE_ID = 101392 THEN '121000072' -- ���������� ������� � ������ �� DDOS-����
             WHEN SERVICE_ID = 102233 THEN '121000614' -- ���������� ������� � ������ �� DDOS-����
             WHEN SERVICE_ID = 1799 OR SERVICE_ID = 534 THEN '121000087' -- �������������� IPv4 �����
             WHEN SERVICE_ID = 102271 THEN             --
               CASE WHEN EXISTS(SELECT 1 /*
                                         TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="18.12.2019"
                                         text="����������� �� ������ ����� �� ��� ������"
                                         */
                                FROM addendum_resources_all    ar1,
                                     resource_contents_all     rc1,
                                     cable_city_ip_subnets_all sn
                                WHERE 1 = 1
                                  AND ar1.addendum_id = t.addendum_id
                                  AND ar1.billing_id = t.billing_id
                                  AND ar1.active_from <= nvl(rc1.active_to, ar1.active_from + 1)
                                  AND nvl(ar1.active_to, rc1.active_from + 1) > rc1.active_from
                                  AND rc1.resource_id = ar1.resource_id
                                  AND rc1.billing_id = ar1.billing_id
                                  AND sn.terminal_resource_id = rc1.terminal_resource_id
                                  AND sn.billing_id = rc1.billing_id
                                  AND sn.ip_v6 IS NULL
                                  AND ROWNUM <= 1) THEN
                  '121000102' -- ���������������� IPv4 �������
               ELSE
                  '121000501' -- �������������� IPv4 �������
               END
             WHEN SERVICE_ID = 101169 THEN '121000021'
             WHEN SERVICE_ID = 101171 THEN '121000021'
             WHEN SERVICE_ID = 101161 THEN '121000021'
             WHEN SERVICE_ID = 101170 THEN '121000021'

             WHEN SERVICE_ID = 1678   THEN '121000117'
             WHEN SERVICE_ID = 101646 THEN '121000080'
           END
           ) AS OFF_ID_FOR_MIGR
        ,(CASE
            WHEN SERVICE_ID IN (101572, 102271, 1799, 534) THEN '��'
            ELSE NULL
          END) AS DIRECT_PROH
         ,(CASE
           WHEN SERVICE_ID IN (163, 237) THEN '����� �� ����������� � ������ �����'
           WHEN SERVICE_ID = 101572 THEN '�������������� IPv6 �������'
           WHEN SERVICE_ID = 101392 THEN '���������� ������� � ������ �� DDOS-����'
           WHEN SERVICE_ID = 102233 THEN '���������� ������� � ������ �� DDOS-����'
           WHEN SERVICE_ID = 1799 OR SERVICE_ID = 534 THEN '�������������� IPv4 �����'
           -- ��� ����������� �� �������, ����� ������������� ��� OFF_ID_FOR_MIGR = 121000501 (�������������� (Secondary) IPv4 �������)
           WHEN SERVICE_ID = 102271 THEN '���������������� IPv4 �������'
           -- ��������� ������ ���������� �� ������ TARIFF_PLAN_NAME
           WHEN SERVICE_ID = 101169 THEN '�������-����������'
           WHEN SERVICE_ID = 101171 THEN '�������-����������'
           WHEN SERVICE_ID = 101161 THEN '�������-����������'
           WHEN SERVICE_ID = 101170 THEN '�������-����������'
           --
           WHEN SERVICE_ID = 1678   THEN '����� ���������� ��������'
           WHEN SERVICE_ID = 101646 THEN '��������� ���������� ��������'
           -- ��� ����������� �� ���
           WHEN OFF_ID_FOR_MIGR = '121000809' THEN '�������� ����������� 2000'
           WHEN OFF_ID_FOR_MIGR = '121000805' THEN '�������� ����������� 1500'
           WHEN OFF_ID_FOR_MIGR = '121000803' THEN '�������� ����������� 1000'
           WHEN OFF_ID_FOR_MIGR = '121000807' THEN '�������� ����������� 1700'
           WHEN OFF_ID_FOR_MIGR = '121000801' THEN '�������� ����������� 120'
          END) AS INV_NAME
          ,(CASE
             WHEN SERVICE_ID IN (163, 237) THEN
               'Completed'
             WHEN EXISTS(SELECT 1
                         FROM PLAN_ITEMS_ALL           PI1,
                              ACTIVATE_LICENSE_FEE_ALL ALF1
                         WHERE ALF1.ADDENDUM_ID = t.ADDENDUM_ID
                           AND ALF1.BILLING_ID = t.BILLING_ID
                           AND ALF1.ACTIVE_FROM <= lc_current_date --��������
                           AND COALESCE(ALF1.ACTIVE_TO, lc_current_date + 1) > lc_current_date
                           AND PI1.PLAN_ITEM_ID = ALF1.PLAN_ITEM_ID
                           AND PI1.BILLING_ID = ALF1.BILLING_ID
                           AND PI1.BILLING_ID = t.BILLING_ID
                           AND PI1.SERVICE_ID IN (867, 102749)
                           AND ROWNUM <= 1) THEN
               'Suspended'
             WHEN ACTIVE_TO BETWEEN TRUNC(lc_current_date, 'MM') AND lc_current_date THEN /*
                                                                                      TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="22.12.2019"
                                                                                      text="Disconnected - ������ �� BPI, ������� ���� ��������� � ����� �������� (���� ""������� ��"" ������ � ����� ��������) � �� ������� �� ��� ��������� ����.
                                                                                            ��������� ����������� �����."
                                                                                        */
               'Disconnected'
             ELSE
               'Active'
           END
         ) AS EXT_BPI_STATUS
         --
         ,('SI_1/'      ||
           BILLING_ID   || '/' ||
           AGREEMENT_ID || '/' ||
           ADDENDUM_ID  || '/' ||
           PLAN_ITEM_ID || '/' ||
           ACTIVITY_ID  ||
           CASE WHEN SERVICE_ID=237 THEN '/' || connect_pays_id ELSE '' END -- ��� ��������� �� ��� ������� ������������� ����������� �������� �� ���
           -- ��� SERVICE_ID IN (1799, 534) ���� ���������:  || '/' || LT_IPV4ADR(II).IDB_ID
          ) AS IDB_ID
         ,(t.AGREEMENT_ID || '/' || t.ADDENDUM_ID || '/' || t.PLAN_ITEM_ID || '/' || t.ACTIVITY_ID) AS SOURCE_ID
         ,TO_CHAR(t.BILLING_ID) AS SOURCE_SYSTEM
         ,'1' AS SOURCE_SYSTEM_TYPE
         ,(-- ������ ��� ������� -���������
           CASE
             WHEN SERVICE_ID IN (101169, 101171) THEN '�����'
             WHEN SERVICE_ID = 101161 THEN '������'
             WHEN SERVICE_ID = 101170 THEN '������+'
             ELSE NULL
           END
         ) AS TARIFF_PLAN_NAME
         -- �������� (12,13)
         ,(SELECT TO_CHAR(trunc(trunc(to_number(trim(MAX(PP.PROP_VALUE)))/1000)/1024,1)) -- || ' ����/�'
           FROM PLAN_PROPERTIES_ALL PP
           WHERE 1 = 1
             AND PP.PLAN_ID = t.PLAN_ID
             AND PP.BILLING_ID = t.BILLING_ID
             AND PP.PROPERTY_TYPE_ID IN (12, 13) -- [12] �����.�������� ������ �����
             AND COALESCE(PP.ACTIVE_TO, TO_DATE('01015100', 'ddmmyyyy')) > TRUNC(lc_current_date, 'mm')
             AND PP.ACTIVE_FROM <= COALESCE(TRUNC(ADD_MONTHS(lc_current_date, 1), 'mm'), PP.ACTIVE_FROM + 1)
         ) AS SPEED_NIGHT
         --
         ,(SELECT TO_NUMBER(REGEXP_REPLACE(DB.BONUS_NAME, '[^[[:digit:]]]*')) UP
           FROM ACTIVATE_LF_LINK_BONUS_ALL LB,
                DOMRU_BONUSES_ALL          DB
           WHERE 1 = 1
             AND LB.ACTIVITY_ID = t.ACTIVITY_ID
             AND LB.BILLING_ID = t.BILLING_ID
             AND DB.BONUS_ID = LB.BONUS_ID
             AND DB.BILLING_ID = LB.BILLING_ID
         ) AS UP
         --
         /*
         ,(SELECT TRUNC(MAX(TIMESTAMP)) + 1 CHARGE
           FROM CHARGES_ALL CH
           WHERE CH.ADDENDUM_ID = t.ADDENDUM_ID
             AND CH.SERVICE_ID  = t.SERVICE_ID
             AND CH.BILLING_ID  = t.BILLING_ID
         ) AS PREV_BILL_TO_DAT
         */
         , TLO_IDB_ID
         , connect_pays_id
  FROM(
  SELECT BILLING_ID,
         AGREEMENT_ID,
         AGREEMENT_NUMBER,
         ADDENDUM_ID,
         ADDENDUM_NUMBER,
         PLAN_ITEM_ID,
         ACTIVITY_ID,
         ACTIVE_FROM,
         ACTIVE_TO,
         PLAN_NAME,
         CUSTOMER_IDB_ID,
         ACCOUNT_IDB_ID,
--         PARENT_ID,
         SERVICE_ID,
         PLAN_ID,
--         CREATED_WHEN,
         OFF_ID_FOR_MIGR,
         TLO_IDB_ID,
         connect_pays_id
  FROM tbl t
  WHERE t.grp = 0
  UNION ALL
  SELECT BILLING_ID,
         AGREEMENT_ID,
         AGREEMENT_NUMBER,
         ADDENDUM_ID,
         ADDENDUM_NUMBER,
         MAX(PLAN_ITEM_ID) AS PLAN_ITEM_ID,
         ACTIVITY_ID,
         ACTIVE_FROM,
         ACTIVE_TO,
         PLAN_NAME,
         CUSTOMER_IDB_ID,
         ACCOUNT_IDB_ID,
--         PARENT_ID,
         MAX(SERVICE_ID) as SERVICE_ID,
         PLAN_ID,
--         CREATED_WHEN,
         OFF_ID_FOR_MIGR,
         TLO_IDB_ID,
         NULL as connect_pays_id -- ������ ��� �������, � ��� �� ������������
  FROM tbl t
  WHERE t.grp = 1
      GROUP BY BILLING_ID,
         AGREEMENT_ID,
         AGREEMENT_NUMBER,
         ADDENDUM_ID,
         ADDENDUM_NUMBER,
         ACTIVITY_ID,
         ACTIVE_FROM,
         ACTIVE_TO,
         PLAN_NAME,
         CUSTOMER_IDB_ID,
         ACCOUNT_IDB_ID,
--         PARENT_ID,
         PLAN_ID,
--         CREATED_WHEN,
         OFF_ID_FOR_MIGR,
         TLO_IDB_ID
  ) t;

  TYPE LTT_SBPI_INT IS TABLE OF LC_SBPI_INT%ROWTYPE INDEX BY BINARY_INTEGER;
  gv_sbpi_int_arr LTT_SBPI_INT;

  --======================
  -- ��� SERVICE_ID = 1799 � SERVICE_ID = 534
  -- ���� ����� ��� ����� 1 IP-������
  --======================
  CURSOR LC_IPV4ADR(P_ADDENDUM_ID NUMBER, P_BILLING_ID NUMBER) IS
    SELECT NVL(IP_IDB_ID, NVL(IPP_IDB_ID, IP))|| '|' ||
           TO_CHAR(rias_mgr_support.is_ip_local(rias_mgr_support.ip_number_to_char(ip))) || '|' || -- 0-�����/�����
                          --������� ���������� � IPV4_TYPE
                          -- ������ 0|IDB_ID|IPV4_TYPE
                          CASE
                            WHEN IP_IDB_ID  IS NOT NULL THEN '���������'
                            WHEN IPP_IDB_ID IS NOT NULL THEN '���������'
                            ELSE '���������'--'�����������'
                                                            /*
                                                            TODO: owner="bikulov.md" created="28.02.2020"
                                                            text="������, ���� �� ������ � �������� � ��������"
                                                            */
                          END AS IDB_ID
    FROM (SELECT IP.IDB_ID AS IP_IDB_ID, IPP.IDB_ID AS IPP_IDB_ID, I.IP, row_number() over (order by rias_mgr_support.is_ip_local(rias_mgr_support.ip_number_to_char(i.ip)), i.ip) AS CN
          FROM IP_FOR_DEDICATED_CLIENTS_ALL I,
               RESOURCE_CONTENTS_ALL        RC,
               ADDENDUM_RESOURCES_ALL       AR,
               IDB_PH2_IP_V4ADDRESS          IP,
               IDB_PH2_IP_V4ADDRESS_PRIVATE  IPP
          WHERE AR.ADDENDUM_ID = P_ADDENDUM_ID
            AND AR.BILLING_ID = P_BILLING_ID
            AND AR.ACTIVE_FROM <= lc_current_date
            AND COALESCE(AR.ACTIVE_TO, lc_current_date +1 ) >= TRUNC(lc_current_date, 'MM') --07.06.2021
--            AND COALESCE(AR.ACTIVE_TO, lc_current_date +1 ) >= lc_current_date--04.06.2021
            AND AR.ACTIVE_FROM < NVL(RC.ACTIVE_TO, AR.ACTIVE_FROM + 1)
            AND NVL(AR.ACTIVE_TO, RC.ACTIVE_FROM + 1) > RC.ACTIVE_FROM
            AND AR.RESOURCE_ID = RC.RESOURCE_ID
            AND AR.BILLING_ID = RC.BILLING_ID
            AND RC.ACTIVE_FROM <= lc_current_date
            AND COALESCE(RC.ACTIVE_TO, lc_current_date +1 ) >= TRUNC(lc_current_date, 'MM') --07.06.2021
--            AND COALESCE(RC.ACTIVE_TO, lc_current_date +1 ) >= lc_current_date--04.06.2021
            AND RC.TERMINAL_RESOURCE_ID = I.TERMINAL_RESOURCE_ID
            AND RC.BILLING_ID = I.BILLING_ID
            --
            AND IP.SOURCE_ID(+) = I.TERMINAL_RESOURCE_ID
            AND IP.SOURCE_SYSTEM(+) = I.BILLING_ID
            AND IP.SOURCE_SYSTEM_TYPE(+) = '1'
            --
            AND IPP.SOURCE_ID(+) = I.TERMINAL_RESOURCE_ID
            AND IPP.SOURCE_SYSTEM(+) = I.BILLING_ID
            AND IPP.SOURCE_SYSTEM_TYPE(+) = '1'
            -- ������������ ip ������� ������� �� ����� �������� �������������
            -- ������������  (�������� "�����" ������)
            --AND NOT (   i.ip between 10000000000  and 10255255255   /* 10.0.0.0 � 10.255.255.255 */
            --         or i.ip between 100064000000 and 100127255255 /* 100.64.0.0 � 100.127.255.255 */
            --         or i.ip between 172016000000 and 172031255255 /* 172.16.0.0 � 172.31.255.255 */
            --         or i.ip between 192168000000 and 192168255255 /* 192.168.0.0 � 192.168.255.255 */
            --         or i.ip between 127000000000 and 127255255255 /* 127.0.0.0 � 127.255.255.255 */
            --       )
            -- 17.02.2021
            -- �������� �� ��������� IP � �������
            AND (lv_swtch_value_ert_19486 = 0
                 OR NOT EXISTS(SELECT 1
                            FROM  addendum_resources_all    ar,
                                  resource_contents_all     rc,
                                  cable_city_ip_subnets_all csa
                            WHERE (1=1)
                              AND ar.addendum_id = P_ADDENDUM_ID
                              AND ar.billing_id = P_BILLING_ID
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

     )
     WHERE CN > 1
     ORDER BY 1 ASC;

  --======================
  -- ��� SERVICE_ID = 102271
  --======================
  CURSOR LC_SUBNETS(P_ADDENDUM_ID NUMBER, P_BILLING_ID NUMBER) IS
    SELECT '/' || sn.netmask AS netmask
      FROM cable_city_ip_subnets_all sn,
           resource_contents_all     rc,
           addendum_resources_all    ar
     WHERE 1 = 1
       AND ar.addendum_id = P_ADDENDUM_ID
       AND ar.billing_id = P_BILLING_ID
       AND ar.active_from <= nvl(rc.active_to, ar.active_from + 1)
       AND nvl(ar.active_to, rc.active_from + 1) > rc.active_from
       AND rc.resource_id = ar.resource_id
       AND rc.billing_id = ar.billing_id
       AND sn.terminal_resource_id = rc.terminal_resource_id
       AND sn.billing_id = rc.billing_id
       AND sn.ip_v6 IS NULL;

  --======================
  -- ��� ���� ���������
  --======================
  CURSOR LC_TEMP IS SELECT '1' FROM DUAL;

  -- ��� ������ ���.����������
  -- TYPE t_ipv4adr_rec IS RECORD(IDB_ID VARCHAR2
  TYPE LTT_IPV4ADR IS TABLE OF VARCHAR2(200) INDEX BY BINARY_INTEGER;
  LT_IPV4ADR LTT_IPV4ADR;

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
                WHERE d.idb_table_name = lc_table_name$c)
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
    lv_res$i := rias_mgr_support.is_unload_field(table_name$c => 'IDB_PH2_SBPI_INT',
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
  * �������� �������������� "�������"
  * ������ �� IDB_PH2_IP_V4RANGE.IDB_ID; IDB_PH2_IP_V4RANGE_PRIVATE.IDB_ID
  */
  FUNCTION GET_SUBNET(
    ip_addendum_id$i IN INTEGER,
    ip_billing_id$i  IN INTEGER
  )
  RETURN VARCHAR2
  IS
  BEGIN
/*
    SELECT '/' || sn.netmask AS netmask
      FROM cable_city_ip_subnets_all sn,
           resource_contents_all     rc,
           addendum_resources_all    ar
     WHERE 1 = 1
       AND ar.addendum_id = ip_addendum_id$i
       AND ar.billing_id = ip_billing_id$i
       AND ar.active_from <= nvl(rc.active_to, ar.active_from + 1)
       AND nvl(ar.active_to, rc.active_from + 1) > rc.active_from
       AND rc.resource_id = ar.resource_id
       AND rc.billing_id = ar.billing_id
       AND sn.terminal_resource_id = rc.terminal_resource_id
       AND sn.billing_id = rc.billing_id
       AND sn.ip_v6 IS NULL;
*/
    RETURN NULL;
  END GET_SUBNET;

  /**
  * �������� ������ �� RIAS_MGR_TMP_LIST
  */
  FUNCTION get_tmp_list_number(
    ip_task_id$i     IN INTEGER,
    ip_id$i          IN INTEGER,
    ip_num_flag      IN INTEGER
  ) RETURN NUMBER
  IS
    lv_num1 NUMBER; lv_num2 NUMBER; lv_num3 NUMBER; lv_res NUMBER;
  BEGIN
    SELECT nvl(min(t.num1),0), nvl(min(t.num2),0), nvl(min(t.num3),0)
    INTO lv_num1, lv_num2, lv_num3
    FROM RIAS_MGR_TMP_LIST t
    WHERE t.task_id = ip_task_id$i
      AND id1 = ip_id$i;
    lv_res := CASE
                WHEN ip_num_flag = 1 THEN lv_num1 -- TOTAL_PRICE_TAX_NRC
                WHEN ip_num_flag = 2 THEN lv_num2 -- NRC_CUPON
                WHEN ip_num_flag = 3 THEN lv_num3 -- NRC_CUPON_MNT
                ELSE 0
              END;
    RETURN lv_res;
  END;
/*
  FUNCTION get_tmp_list_number(
    ip_task_id$i     IN INTEGER,
    ip_billing_id$i  IN INTEGER,
    ip_addendum_id$i IN INTEGER,
    ip_activity_id$i IN INTEGER,
    ip_num_flag      IN INTEGER
  ) RETURN NUMBER
  IS
    lv_num1 NUMBER; lv_num2 NUMBER; lv_num3 NUMBER; lv_res NUMBER;
  BEGIN
    SELECT nvl(min(t.num1),0), nvl(min(t.num3),0), nvl(min(t.num3),0)
    INTO lv_num1, lv_num2, lv_num3
    FROM RIAS_MGR_TMP_LIST t
    WHERE t.task_id = ip_task_id$i
      AND billing_id  = ip_billing_id$i
      AND addendum_id = ip_addendum_id$i
      AND activity_id = ip_activity_id$i;
    lv_res := CASE
                WHEN ip_num_flag = 1 THEN lv_num1
                WHEN ip_num_flag = 2 THEN lv_num2
                WHEN ip_num_flag = 3 THEN lv_num3
                ELSE 0
              END;
    RETURN lv_res;
  END;
*/
  /**
  * ��������
  * @param addendum_id$i - ������������� ����������
  * @param billing_id$i  - ����� ��������
  * @param date$d        - ���� ��������� ����������
  */
  FUNCTION get_additional_line_num(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    date$d        IN DATE DEFAULT rias_mgr_support.get_current_date
  ) RETURN INTEGER
  IS
    lv_res$i INTEGER;
  BEGIN
    SELECT SUM(expenses_number) -- ���������� ������
    INTO lv_res$i
    FROM addenda_all ad_1,
         teo_link_addenda_all la_1,
         expenses_all e_1,
         materials_all m_1
    WHERE 1 = 1
       AND ad_1.addendum_id = addendum_id$i
       AND ad_1.billing_id  = billing_id$i
       AND la_1.addendum_id = ad_1.addendum_id
       AND la_1.billing_id  = ad_1.billing_id
       AND la_1.active_from <= date$d
       AND (la_1.active_to IS NULL OR la_1.active_to > date$d)
       AND e_1.teo_id = la_1.teo_id
       AND e_1.billing_id = la_1.billing_id
       AND m_1.Attr_Entity_Id = e_1.Attr_Entity_Id
       AND m_1.billing_id = e_1.billing_id
       AND m_1.Material_Name in ('��_����������� ��������������� ������������ ������ �� 1-� (������) ��������� ��������� (�� 1 �������)',
                                 '��_����������� ��������������� ������������ ������ �� 2-� (������) ��������� ��������� (�� 1 �������)');
    RETURN lv_res$i;
  END get_additional_line_num;

  /**
  * ��������� ������� �� ���������� �������
  */
  FUNCTION prepare_teo_data(
    ip_billing_id$i IN INTEGER,
    ip_date$d       IN DATE := rias_mgr_support.get_current_date
  ) RETURN INTEGER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    lv_res_task INTEGER;
    lv_tmp_task INTEGER;
  BEGIN
      lv_tmp_task := RIAS_MGR_TASK_SEQ.nextval;
      lv_res_task := RIAS_MGR_TASK_SEQ.nextval;
      INSERT INTO /*+ append */ RIAS_MGR_TMP_LIST(
        task_id
        ,agreement_id
        ,str1             --AGREEMENT_NUMBER
        ,billing_id
        ,customer_idb_id
        ,account_idb_id
        ,plan_id
        ,str2             --PLAN_NAME
        ,addendum_id
        ,str3             --ADDENDUM_NUMBER
        ,plan_item_id
        ,activity_id
        ,active_from
        ,active_to
        ,service_id
        ,str4             --TLO.IDB_ID
        ,id1
      )
      SELECT
           lv_tmp_task,
           ac.source_id AS agreement_id,
           ac.legacy_account_num agreement_number,
           ad.billing_id,
           ac.parent_id customer_idb_id,
           ac.idb_id    account_idb_id,
           pa.plan_id,
           pa.plan_name,
           ad.addendum_id,
           ad.addendum_number,
           pi.plan_item_id as plan_item_id,
           alf.activity_id as activity_id,
           tpi.actual_start_date as actual_start_date,
           (tpi.actual_start_date + 1) as actual_end_date,
           /*
           (CASE WHEN tla.active_from < trunc(current_date,'mm') THEN trunc(current_date,'mm') ELSE tla.active_from END) as ACTUAL_START_DATE,
           (CASE WHEN tla.active_from < trunc(current_date,'mm') THEN trunc(current_date,'mm') ELSE tla.active_from END) + 1 as ACTUAL_END_DATE,
           */
           pi.service_id,
           tpi.idb_id
           ,t.teo_id
      FROM idb_ph2_tbpi_int         tpi,
           idb_ph2_account          ac,
           addenda_all              ad,
           plans_all                pa,
           plan_items_all           pi,
           activate_license_fee_all alf,
           teo_link_addenda_all     tla,
           teo_all                  t
      WHERE 1=1
        AND tpi.source_system_type = '1'
        AND tpi.source_system = TO_CHAR(ip_billing_id$i)
        AND tpi.idb_id like 'TI_1%'
        -- ����� � �������������� ����������
        AND ac.idb_id = tpi.account_idb_id
        AND ac.source_system = tpi.source_system
        -- ����� � ������������ ���������
        AND ad.addendum_id = tpi.source_id
        AND ad.billing_id = tpi.source_system
        AND ad.billing_id = ip_billing_id$i
        -- ����� � ��������� �������
        AND pa.plan_id    = ad.plan_id
        AND pa.billing_id = ad.billing_id
        AND pa.billing_id = ip_billing_id$i
        -- �������� ����� PGP
        AND UPPER(pa.plan_name) NOT LIKE '%BGP%'
        --����� � ����������� ����� ���������� � ������� �����
        AND ALF.ADDENDUM_ID = AD.ADDENDUM_ID
        AND ALF.BILLING_ID = AD.BILLING_ID
        AND ALF.BILLING_ID = ip_billing_id$i
        AND ALF.ACTIVE_FROM <= ip_date$d --��������
        AND (ALF.ACTIVE_TO IS NULL OR ALF.ACTIVE_TO > ip_date$d/*TRUNC(CURRENT_DATE, 'MM')*/) -- �� ��� ������ ���� ������ ��������� � ������� ������, �� ���� �� ���������
        --����� � ��������
        AND PI.PLAN_ITEM_ID = ALF.PLAN_ITEM_ID
        AND PI.BILLING_ID = ALF.BILLING_ID
        AND PI.BILLING_ID = ip_billing_id$i
        AND PI.SERVICE_ID = 237 --������ TOP Level
        -- ���
        AND tla.addendum_id = ad.addendum_id
        AND tla.billing_id   = ad.billing_id
        AND tla.billing_id   = ip_billing_id$i
        AND tla.active_from <= ip_date$d
        AND (tla.active_to IS NULL OR tla.active_to > ip_date$d/*trunc(current_date,'MM')*/) -- �������� ����������� � ������� ������
        AND tla.teo_id = t.teo_id
        AND tla.billing_id = t.billing_id;
    COMMIT;
    ---
    INSERT INTO /*+ append */ RIAS_MGR_TMP_LIST(
        task_id
        ,agreement_id
        ,str1             --AGREEMENT_NUMBER
        ,billing_id
        ,customer_idb_id
        ,account_idb_id
        ,plan_id
        ,str2             --PLAN_NAME
        ,addendum_id
        ,str3             --ADDENDUM_NUMBER
        ,plan_item_id
        ,activity_id
        ,active_from
        ,active_to
        ,service_id
        ,off_id_for_migr
        ,num1             --TOTAL_PRICE_TAX_NRC
        ,num2             --NRC_CUPON
        ,num3             --NRC_CUPON_MNT
        ,str4             --TLO.IDB_ID
        ,id1
    )
    SELECT lv_res_task
           ,agreement_id
           ,str1
           ,t.billing_id
           ,customer_idb_id
           ,account_idb_id
           ,plan_id
           ,str2
           ,addendum_id
           ,str3
           ,plan_item_id
           ,activity_id
           ,active_from
           ,active_to
           ,service_id
           , CASE
               WHEN cp.connect_pays_type2_id = 54  THEN '121000803'
               WHEN cp.connect_pays_type2_id = 55  THEN '121000801'
               WHEN cp.connect_pays_type2_id = 69  THEN '121000803'
               WHEN cp.connect_pays_type2_id = 70  THEN '121000801'
               WHEN cp.connect_pays_type2_id = 210 THEN '121000805'
               WHEN cp.connect_pays_type2_id = 211 THEN '121000805'
               WHEN cp.connect_pays_type2_id = 221 THEN '121000807'
               WHEN cp.connect_pays_type2_id = 226 THEN '121000809'
             END AS off_id_for_migr
           ,NVL(cp.payments_number * cp.payments_cost, 0) AS total_price_tax_nrc
           ,NULL AS nrc_cupon
           ,NULL AS nrc_cupon_mnt
           ,str4
           ,cp.connect_pays_id
    FROM rias_mgr_tmp_list t,
         connect_pays_all  cp
    WHERE t.task_id = lv_tmp_task
            AND cp.teo_id = t.id1
            AND cp.billing_id = t.billing_id
            AND cp.connect_pays_type2_id IS NOT NULL
            AND cp.connect_pays_type2_id IN (54,55,69,70,210,211,221,226)
            AND cp.date_create >= ADD_MONTHS(lc_current_date, -24)

    UNION ALL

    SELECT lv_res_task
           ,agreement_id
           ,str1
           ,t.billing_id
           ,customer_idb_id
           ,account_idb_id
           ,plan_id
           ,str2
           ,addendum_id
           ,str3
           ,plan_item_id
           ,activity_id
           ,active_from
           ,active_to
           ,service_id
           ,'121000020' as off_id_for_migr
           ,cp.payments_number * cp.payments_cost AS total_price_tax_nrc
           ,(CASE
               WHEN con2.connect_pays_type_name LIKE '%�����%' THEN
                 TO_NUMBER(regexp_replace(con2.connect_pays_type_name,'[^[[:digit:]]]*'))
               ELSE
                 NULL
             END) AS nrc_cupon
           ,(CASE
               WHEN con2.connect_pays_type_name like '%�����%' THEN
                 ROUND((cp.payments_number*cp.payments_cost/(100-regexp_replace(con2.connect_pays_type_name,'[^[[:digit:]]]*')))*regexp_replace(con2.connect_pays_type_name,'[^[[:digit:]]]*'),2)
               ELSE
                 NULL
             END) AS nrc_cupon_mnt
           ,str4
           ,cp.connect_pays_id
    FROM rias_mgr_tmp_list t,
         connect_pays_all  cp
         ,excellent.connect_pays_type_all con
         ,excellent.connect_pays_type_all con2
    WHERE t.task_id = lv_tmp_task
          AND cp.teo_id = t.id1
          AND cp.billing_id = t.billing_id
          AND NOT EXISTS(SELECT 1
                         FROM connect_pays_all cpa
                         WHERE cpa.teo_id = t.id1
                           AND cpa.billing_id = t.billing_id
                           AND cpa.connect_pays_type2_id IN (54,55,69,70,210,211,221,226))
          AND cp.date_create >= ADD_MONTHS(lc_current_date, -24)

          AND con.connect_pays_type_id = cp.connect_pays_type_id
          AND con.billing_id = cp.billing_id
          AND (con.connect_pays_type_name LIKE '%��������������%' OR
               con.connect_pays_type_name LIKE '%�������%')
          and con2.connect_pays_type_id=cp.connect_pays_type2_id
          and con2.billing_id=cp.billing_id
  /*
          AND EXISTS(SELECT 1
                         FROM excellent.connect_pays_type_all con
                         WHERE con.connect_pays_type_id = cp.connect_pays_type_id
                           AND con.billing_id = cp.billing_id
                           AND (con.connect_pays_type_name LIKE '%��������������%' OR
                                con.connect_pays_type_name LIKE '%�������%')
                     )
  */

    UNION ALL

    SELECT lv_res_task
           ,agreement_id
           ,str1
           ,t.billing_id
           ,customer_idb_id
           ,account_idb_id
           ,plan_id
           ,str2
           ,addendum_id
           ,str3
           ,plan_item_id
           ,activity_id
           ,active_from
           ,active_to
           ,service_id
           ,'121000020' AS off_id_for_migr
           ,0 AS total_price_tax_nrc
           ,NULL AS nrc_cupon
           ,NULL AS nrc_cupon_mnt
           ,str4
           ,cp.connect_pays_id
    FROM rias_mgr_tmp_list t,
         connect_pays_all  cp
    WHERE t.task_id = lv_tmp_task
          AND cp.teo_id = t.id1
          AND cp.billing_id = t.billing_id
          AND (SELECT MAX(cp1.date_create) FROM connect_pays_all cp1 WHERE cp1.teo_id = cp.teo_id AND cp1.billing_id = cp.billing_id) < ADD_MONTHS(lc_current_date, -24);
    --dbms_output.put_line('lv_res_task = '||lv_res_task||' lv_tmp_task = '||lv_tmp_task);

    -- ������� ��������� �������
    DELETE /*+ append */ FROM RIAS_MGR_TMP_LIST WHERE task_id = lv_tmp_task;

    COMMIT;

    RETURN lv_res_task;
  END prepare_teo_data;

/*
  FUNCTION prepare_teo_data(
    ip_billing_id$i IN INTEGER,
    ip_date$d       IN DATE := rias_mgr_support.get_current_date
  ) RETURN INTEGER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    lv_res INTEGER;
  BEGIN
      lv_res := RIAS_MGR_TASK_SEQ.nextval;
      INSERT INTO \*+ append *\ RIAS_MGR_TMP_LIST(
        task_id
        ,agreement_id
        ,str1             --AGREEMENT_NUMBER
        ,billing_id
        ,customer_idb_id
        ,account_idb_id
        ,plan_id
        ,str2             --PLAN_NAME
        ,addendum_id
        ,str3             --ADDENDUM_NUMBER
        ,plan_item_id
        ,activity_id
        ,active_from
        ,active_to
        ,service_id
        ,off_id_for_migr
        ,num1
        ,num2
        ,num3
        ,str4             --TLO.IDB_ID
      )
      SELECT
           lv_res,
           AC.SOURCE_ID AGREEMENT_ID,
           AC.LEGACY_ACCOUNT_NUM AGREEMENT_NUMBER,
           AD.BILLING_ID,
           AC.PARENT_ID CUSTOMER_IDB_ID,
           AC.IDB_ID    ACCOUNT_IDB_ID,
           PA.PLAN_ID,
           PA.PLAN_NAME,
           AD.ADDENDUM_ID,
           AD.ADDENDUM_NUMBER,
           pi.plan_item_id as PLAN_ITEM_ID,
           alf.activity_id as ACTIVITY_ID,
           (CASE WHEN tla.active_from < trunc(lc_current_date,'mm') THEN trunc(lc_current_date,'mm') ELSE tla.active_from END) as ACTUAL_START_DATE,
           (CASE WHEN tla.active_from < trunc(lc_current_date,'mm') THEN trunc(lc_current_date,'mm') ELSE tla.active_from END) + 1 as ACTUAL_END_DATE,
           pi.service_id,
           CASE
             WHEN cp.connect_pays_type2_id = 54  THEN '121000803'
             WHEN cp.connect_pays_type2_id = 55  THEN '121000801'
             WHEN cp.connect_pays_type2_id = 69  THEN '121000803'
             WHEN cp.connect_pays_type2_id = 70  THEN '121000801'
             WHEN cp.connect_pays_type2_id = 210 THEN '121000805'
             WHEN cp.connect_pays_type2_id = 211 THEN '121000805'
             WHEN cp.connect_pays_type2_id = 221 THEN '121000807'
             WHEN cp.connect_pays_type2_id = 226 THEN '121000809'
           END AS OFF_ID_FOR_MIGR,
           cp.payments_number payments_number,
           cp.payments_cost,
           cp.payments_number*cp.payments_cost cp_all_wnds,
           tpi.idb_id
      FROM idb_ph2_tbpi_int         tpi,
           idb_ph2_account          ac,
           addenda_all              ad,
           plans_all                pa,
           plan_items_all           pi,
           activate_license_fee_all alf,
           teo_link_addenda_all     tla,
           teo_all                  t,
           connect_pays_all         cp
      WHERE 1=1
        AND tpi.source_system_type = '1'
        AND tpi.source_system = TO_CHAR(ip_billing_id$i)
        AND tpi.idb_id like 'TI_1%'
        -- ����� � �������������� ����������
        AND ac.idb_id = tpi.account_idb_id
        AND ac.source_system = tpi.source_system
        -- ����� � ������������ ���������
        AND ad.addendum_id = tpi.source_id
        AND ad.billing_id = tpi.source_system
        AND ad.billing_id = ip_billing_id$i
        -- ����� � ��������� �������
        AND pa.plan_id    = ad.plan_id
        AND pa.billing_id = ad.billing_id
        AND pa.billing_id = ip_billing_id$i
        -- �������� ����� PGP
        AND UPPER(pa.plan_name) NOT LIKE '%BGP%'
        --����� � ����������� ����� ���������� � ������� �����
        AND ALF.ADDENDUM_ID = AD.ADDENDUM_ID
        AND ALF.BILLING_ID = AD.BILLING_ID
        AND ALF.BILLING_ID = ip_billing_id$i
        AND ALF.ACTIVE_FROM <= ip_date$d --��������
        AND (ALF.ACTIVE_TO IS NULL OR ALF.ACTIVE_TO > ip_date$d\*TRUNC(lc_current_date, 'MM')*\) -- �� ��� ������ ���� ������ ��������� � ������� ������, �� ���� �� ���������
        --����� � ��������
        AND PI.PLAN_ITEM_ID = ALF.PLAN_ITEM_ID
        AND PI.BILLING_ID = ALF.BILLING_ID
        AND PI.BILLING_ID = ip_billing_id$i
        AND PI.SERVICE_ID = 237 --������ TOP Level
        -- ���
        AND tla.addendum_id = ad.addendum_id
        AND tla.billing_id   = ad.billing_id
        AND tla.billing_id   = ip_billing_id$i
        AND tla.active_from <= ip_date$d
        AND (tla.active_to IS NULL OR tla.active_to > ip_date$d\*trunc(lc_current_date,'MM')*\) -- �������� ����������� � ������� ������
        AND tla.teo_id = t.teo_id
        AND tla.billing_id = t.billing_id
        --
        AND cp.teo_id = t.teo_id
        AND cp.billing_id = t.billing_id
        AND cp.billing_id = ip_billing_id$i
        AND cp.connect_pays_type2_id is not null
        AND cp.connect_pays_type2_id in (54,55,69,70,210,211,221,226)
        AND cp.payments_cost = (SELECT MIN(cp1.payments_cost)
                                FROM connect_pays_all cp1
                                WHERE cp1.teo_id = cp.teo_id
                                  AND cp1.billing_id = cp.billing_id
                                  AND cp1.connect_pays_type2_id is not null
                                  AND cp1.connect_pays_type2_id IN (54,55,69,70,210,211,221,226));
    COMMIT;
    RETURN lv_res;
  END prepare_teo_data;
*/
  /**
  * �������� ��������� �������
  */
  PROCEDURE clear_rias_mgr_tmp_list(ip_task_id$i IN INTEGER)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    DELETE /*+ append */ FROM RIAS_MGR_TMP_LIST WHERE task_id = ip_task_id$i;
    COMMIT;
  END clear_rias_mgr_tmp_list;

  /**
  * "�������" ����������� ������ � �������
  */
  PROCEDURE INSERT_ROWS
  IS
  BEGIN
    IF gv_rec_arr.COUNT > 0 THEN
      BEGIN
        FORALL lv_idx IN 1 .. gv_rec_arr.COUNT
        SAVE EXCEPTIONS
          INSERT INTO /*+ append */ IDB_PH2_SBPI_INT
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
                                                                                 'IDB_ID: '           || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).IDB_ID             || CHR(13) ||
                                                                                 'ACCOUNT_IDB_ID: '   || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).ACCOUNT_IDB_ID     || CHR(13) ||
                                                                                 'CUSTOMER_IDB_ID: '  || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).CUSTOMER_IDB_ID    || CHR(13) ||
                                                                                 'SOURCE_ID: '        || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).SOURCE_ID          || CHR(13) ||
                                                                                 'OFF_ID_FOR_MIGR: '  || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).OFF_ID_FOR_MIGR    || CHR(13) ||
                                                                                 'PARENT_ID: '        || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).PARENT_ID          || CHR(13) ||
                                                                                 'PLAN_NAME: '        || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).LEGACY_OBJECT_NAME || CHR(13) ||
                                                                                 'TARIFF_PLAN_NAME: ' || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).TARIFF_PLAN_NAME   || CHR(13) ||
                                                                                 'PREFIX: '           || gv_rec_arr(SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_INDEX).PREFIX
                                                                                 , 1, 2000),
                                                            ip_err_code => SUBSTR('SQLCODE = ' || TO_CHAR(-SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_CODE) ||' SQLERRM = ' || SQLERRM(-SQL%BULK_EXCEPTIONS(lv_idx_err).ERROR_CODE), 1, 200),
                                                            ip_thread_id => ip_thread$i,
                                                            ip_city_id => lv_curr_billing,
                                                            ip_slog_slog_id => lv_slog_id);

          END LOOP;
      END;
    END IF;
    -- ������� ������� ������
    gv_rec_arr.delete;
  END INSERT_ROWS;
--=============================================================================
BEGIN
  RIAS_MGR_CORE.save_session_state;
  dbms_application_info.set_module(module_name => lc_work_module_name,
                                   action_name => 'PrepareWorkData');
  -- �������� ������� ������
  prepareWorkData;

  -- �������������� ������ ����� DBG-����������
  RIAS_MGR_CORE.dbg_start(ip_table_id => lc_table_id$i);
  --
  dbms_application_info.set_action(action_name => 'GET CITIES LIST');
  -- �������� ������ �������
  lv_cities_list := RIAS_MGR_CORE.get_cities_list(ip_table_id$i   => lc_table_id$i,
                                                   ip_thread$i     => ip_thread$i,
                                                   ip_thread_cnt$i => ip_thread_cnt$i,
                                                   ip_slog_id$i    => ip_slog_id$i);
  -- ������������ ���������,���� ��� ������ �������� ���������� � ����� �������
  IF ip_thread_cnt$i > 1 THEN
    sys.dbms_lock.sleep(3);
  END IF;

  -- ����� �� �������
  FOR idx_ct IN 1..lv_cities_list.COUNT
  LOOP
    -- ��������� ����� ������
    lv_time_start := dbms_utility.get_time;
    -- �������� ����������
    lv_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => lc_table_id$i,
                                                ip_message => '��������� ������ '|| to_char(lv_cities_list(idx_ct)),
                                                ip_thread_id => TO_CHAR(ip_thread$i),
                                                ip_city_id => to_char(lv_cities_list(idx_ct)),
                                                ip_slog_slog_id => ip_slog_id$i);
    lv_curr_billing := lv_cities_list(idx_ct);

    dbms_application_info.set_action(action_name => 'ROWS FETCH FOR '|| TO_CHAR(lv_curr_billing));
    lv_count_rows := 0;
    lv_num_iteration := 0;
    -- ������� ������ �� ��� �� "�������������� ������� � ������ �����"
    lv_task_id := prepare_teo_data(lv_curr_billing);
    -- ������� ������ �� �������
    OPEN LC_SBPI_INT(lv_curr_billing, lv_task_id);
    LOOP
      lv_num_iteration := lv_num_iteration + 1;
      dbms_application_info.set_action(action_name => TO_CHAR(lv_curr_billing)||'/FETCH CRS('|| TO_CHAR(lv_num_iteration)||')' );
      -- ������� ��������� ������ ������
      FETCH LC_SBPI_INT BULK COLLECT INTO gv_sbpi_int_arr LIMIT lc_rec_limit;
      EXIT WHEN gv_sbpi_int_arr.COUNT = 0;
      -- �������� �� ������
      -- ����������� ���������� � ������
      dbms_application_info.set_action(action_name => 'SBPI.CNT= '|| TO_CHAR(gv_sbpi_int_arr.COUNT) || ' FOR ' || TO_CHAR(lv_curr_billing));
      --
      FOR I IN 1..gv_sbpi_int_arr.COUNT LOOP
        BEGIN
          --====================================
          -- ��NULL��� ����������
          SREC := NULL;
          --
          srec_child := NULL;
          --
          LT_IPV4ADR.DELETE();
          --====================================
          -- ������� �� TLO ������
          -- ���� ������ �� ����� �������, �� ������� ���������� (���� ���� ���������) � ������� � ���.
          -- ����� ������ � �������� ����� ���������� (����� ���� ��� ������� TLO.IDB_ID
          SELECT access_speed, auth_type, service_id, off_id_for_migr, actual_start_date, bpi_market, bpi_organization, barring, customer_location
          INTO lv_tbpi_rec.access_speed, lv_tbpi_rec.auth_type, lv_tbpi_rec.parent_service_id, lv_tbpi_rec.off_id_for_migr, lv_tbpi_rec.actual_start_date,
               lv_tbpi_rec.bpi_market, lv_tbpi_rec.bpi_organization, lv_tbpi_rec.barring, lv_tbpi_rec.customer_location
          FROM idb_ph2_tbpi_int tbi
          WHERE 1=1
            AND tbi.IDB_ID = gv_sbpi_int_arr(i).TLO_IDB_ID;


          -- ��� ������ ������ ����� ���������� � ���
          -- ���������: ��������� - ����� (��������� * %������) * ����.���
          -- ���������� ���
          IF gv_sbpi_int_arr(I).SERVICE_ID = 237 THEN -- 237 - ��� ��� ��� SLO, ��� ��������� �� ���
            NULL;
            /*
            lv_mrc_rec.koef_nds  := NVL(RIAS_MGR_SUPPORT.get_nds(billing_id$i => gv_sbpi_int_arr(i).billing_id), 1);
            lv_mrc_rec.koef_nds := CASE WHEN lv_mrc_rec.koef_nds = 0 THEN 1 ELSE lv_mrc_rec.koef_nds END;
            lv_mrc_rec.serv_cost := get_tmp_list_number(ip_task_id$i     => lv_task_id,
                                                        ip_billing_id$i  => gv_sbpi_int_arr(i).billing_id,
                                                        ip_addendum_id$i => gv_sbpi_int_arr(i).addendum_id,
                                                        ip_activity_id$i => gv_sbpi_int_arr(i).activity_id,
                                                        ip_num_flag      => 2)/lv_mrc_rec.koef_nds;
            lv_mrc_rec.mrc_cupon := null;
            lv_mrc_rec.mrc_with_nds := get_tmp_list_number(ip_task_id$i     => lv_task_id,
                                                           ip_billing_id$i  => gv_sbpi_int_arr(i).billing_id,
                                                           ip_addendum_id$i => gv_sbpi_int_arr(i).addendum_id,
                                                           ip_activity_id$i => gv_sbpi_int_arr(i).activity_id,
                                                           ip_num_flag      => 3);
            lv_mrc_rec.mrc_without_nds := lv_mrc_rec.mrc_with_nds/lv_mrc_rec.koef_nds;
            */
          ELSE
            lv_mrc_rec.koef_nds  := NVL(RIAS_MGR_SUPPORT.get_nds(service_id$i => gv_sbpi_int_arr(i).service_id,
                                                                 billing_id$i => gv_sbpi_int_arr(i).billing_id), 1);
            lv_mrc_rec.koef_nds := CASE WHEN lv_mrc_rec.koef_nds = 0 THEN 1 ELSE lv_mrc_rec.koef_nds END;
            -- ��������� ������ ��� ���
            lv_mrc_rec.serv_cost := NVL(RIAS_MGR_SUPPORT.get_service_cost(addendum_id$i  => gv_sbpi_int_arr(i).addendum_id,
                                                                          plan_item_id$i => gv_sbpi_int_arr(i).plan_item_id,
                                                                          billing_id$i   => gv_sbpi_int_arr(i).billing_id,
                                                                          service_id$i   => gv_sbpi_int_arr(i).service_id,
                                                                          with_nds$i     => 0), 0);
            -- % ������ �� ���������� ������ ��� �� ������ ������
            lv_mrc_rec.mrc_cupon := null;--NVL(RIAS_MGR_SUPPORT.get_cupon_4_service(addendum_id$i => gv_sbpi_int_arr(i).addendum_id,billing_id$i  => gv_sbpi_int_arr(i).billing_id), 0);
            -- ��������� ������ � ������ ������ ��� ���
            lv_mrc_rec.mrc_without_nds := lv_mrc_rec.serv_cost-lv_mrc_rec.serv_cost*NVL(lv_mrc_rec.mrc_cupon, 0)/100;
            --
            lv_mrc_rec.mrc_with_nds := lv_mrc_rec.mrc_without_nds * lv_mrc_rec.koef_nds;
          END IF;
          -- ������� "������" ���������� ������
          IF (gv_sbpi_int_arr(I).SERVICE_ID = 1799 OR gv_sbpi_int_arr(I).SERVICE_ID = 534) THEN
            OPEN LC_IPV4ADR(gv_sbpi_int_arr(I).ADDENDUM_ID, gv_sbpi_int_arr(I).BILLING_ID);
            FETCH LC_IPV4ADR BULK COLLECT INTO LT_IPV4ADR;
            CLOSE LC_IPV4ADR;
          ELSIF gv_sbpi_int_arr(I).SERVICE_ID = 102271 THEN
            OPEN LC_SUBNETS(gv_sbpi_int_arr(I).ADDENDUM_ID, gv_sbpi_int_arr(I).BILLING_ID);
            FETCH LC_SUBNETS BULK COLLECT INTO LT_IPV4ADR;
            CLOSE LC_SUBNETS;
          ELSE
            OPEN LC_TEMP;
            FETCH LC_TEMP BULK COLLECT INTO LT_IPV4ADR;
            CLOSE LC_TEMP;
          END IF;
          --
          dbms_application_info.set_action(action_name => 'SBPI.CNT= '|| TO_CHAR(gv_sbpi_int_arr.COUNT) || ' ADR.CNT= '|| TO_CHAR(LT_IPV4ADR.COUNT) || ' FOR ' || TO_CHAR(lv_curr_billing));
          lv_count_adr_all := 0;
          FOR II IN 1..LT_IPV4ADR.COUNT LOOP
            BEGIN
              --====================================
              -- ��NULL��� ����������
              SREC := NULL;
              --
              srec_child := NULL;
              --
              lv_ip_is_local$i := NULL;
              --====================================
              --������� �� �������
              lv_count_rows    := lv_count_rows + 1;
              --������� ����������
              lv_count_adr_all := lv_count_adr_all +1;
              -- ����� ������ n (50) ������� ��������� SessionInfo
              IF mod(lv_count_rows, 50) = 0 THEN
                dbms_application_info.set_action(action_name => 'Rec '                     ||
                                                                TO_CHAR(lv_count_adr_all)  || '/'||
                                                                TO_CHAR(LT_IPV4ADR.COUNT)  || '//'||
                                                                TO_CHAR(lv_count_rows)      || '/'||
                                                                TO_CHAR(gv_sbpi_int_arr.COUNT) ||
                                                                ' FOR '|| TO_CHAR(lv_curr_billing));
              END IF;
              -- ������������� ������������ ����������� �� �������� ����������� �����������.
              -- ��������� �� ���� OFF_ID_FOR_MIGR � ������� IDB_PH2_OFFERINGS_DIC
              SREC.OFF_ID_FOR_MIGR := gv_sbpi_int_arr(I).OFF_ID_FOR_MIGR;

              -- ���� ���. IP-�����, �� ��������� "�����" �� ��� "�����"
              IF SREC.OFF_ID_FOR_MIGR = '121000087' THEN --SERVICE_ID IN (1799, 534)
                lv_ip_is_local$i := TO_NUMBER(SUBSTR(LT_IPV4ADR(II), INSTR(LT_IPV4ADR(II),'|', 1, 1) + 1, INSTR(LT_IPV4ADR(II),'|', 1, 2) - INSTR(LT_IPV4ADR(II),'|', 1, 1) - 1));
              END IF;

              -- �������� �������, �� (����/�) ������ ��������: 1;2;3;4;5;6;7;8;9;10;15;20;30;50;100;200;300;400;500;1024 � �.�.
              IF is_unload_field('ACCESS_SPEED', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.ACCESS_SPEED := lv_tbpi_rec.ACCESS_SPEED;
              END IF;
              -- ������ �� ����������� �������
              IF is_unload_field('ACCOUNT_IDB_ID', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.ACCOUNT_IDB_ID := gv_sbpi_int_arr(I).ACCOUNT_IDB_ID;
              END IF;
              -- ����, ����� ������ ���������� �������� ���� ��������. ���� ��������� (��� �� ���������� ��������)
              IF is_unload_field('ACTUAL_START_DATE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.ACTUAL_START_DATE := CASE
                                            WHEN gv_sbpi_int_arr(I).ACTIVE_FROM < lv_tbpi_rec.ACTUAL_START_DATE THEN lv_tbpi_rec.ACTUAL_START_DATE
                                            ELSE gv_sbpi_int_arr(I).ACTIVE_FROM
                                          END;
              END IF;
              -- ����, ����� ������ ���������� �������� ���� �����������
              -- ph2i5
              -- ���� EXT_BPI_STATUS = Active, � � ������ � ������ ���� active_to > current date, �� ACTUAL_END_DATE = NULL
              IF is_unload_field('ACTUAL_END_DATE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.ACTUAL_END_DATE :=
                  CASE
                    WHEN gv_sbpi_int_arr(I).EXT_BPI_STATUS = 'Active' AND gv_sbpi_int_arr(I).ACTIVE_TO > lc_current_date THEN
                      NULL
                    ELSE
                      gv_sbpi_int_arr(I).ACTIVE_TO-1
                  END;
              END IF;
              -- ���������� �������������� ����� (������ ��� "�������������� ������� � ������ �����")
              -- ph2i5
              IF is_unload_field('ADDITIONAL_LINE_NUM', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.ADDITIONAL_LINE_NUM := NVL(get_additional_line_num(gv_sbpi_int_arr(I).addendum_id, gv_sbpi_int_arr(I).billing_id), 0);
              END IF;

              -- ��� �����������. ������� ��������:PPPoE;IPoE;BGP � �.�.
              -- ph2i5
              IF is_unload_field('AUTH_TYPE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.AUTH_TYPE := lv_tbpi_rec.AUTH_TYPE;
              ELSE
                SREC.AUTH_TYPE := NULL;
              END IF;
              -- ���� ����������� ����� �� ������� ��������.
              IF is_unload_field('BILLED_TO_DAT', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.BILLED_TO_DAT := CASE
                                        WHEN SREC.ACTUAL_START_DATE/*gv_sbpi_int_arr(I).ACTIVE_FROM*/ < TRUNC(lc_current_date, 'mm') THEN TRUNC(lc_current_date, 'mm')-1
                                        ELSE NULL
                                      END;
              END IF;
              -- ���� �������� �������
              IF is_unload_field('CREATED_WHEN', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.CREATED_WHEN := CASE
                                       WHEN SREC.ACTUAL_START_DATE/*gv_sbpi_int_arr(I).ACTIVE_FROM*/ < lv_tbpi_rec.ACTUAL_START_DATE THEN SREC.ACTUAL_START_DATE--gv_sbpi_int_arr(I).ACTIVE_FROM
                                       ELSE gv_sbpi_int_arr(I).CREATED_WHEN
                                      END;
              END IF;
              -- ������ �� �������, �������� ����������� ���� ��������� ��������
              IF is_unload_field('CUSTOMER_IDB_ID', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.CUSTOMER_IDB_ID := gv_sbpi_int_arr(I).CUSTOMER_IDB_ID;
              END IF;
              -- ������ �� ������� �������, ��� ��������������� ������
              IF is_unload_field('CUSTOMER_LOCATION', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.CUSTOMER_LOCATION := lv_tbpi_rec.customer_location;
                /*
                SREC.CUSTOMER_LOCATION := rias_mgr_support.get_customer_location(addendum_id$i => gv_sbpi_int_arr(I).ADDENDUM_ID,
                                                                                 billing_id$i  => gv_sbpi_int_arr(I).BILLING_ID);
                */
              END IF;
              -- ������ ������-����������
              IF is_unload_field('DIRECT_PROH', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.DIRECT_PROH := gv_sbpi_int_arr(I).DIRECT_PROH;
              END IF;
              -- ���� ���������
              IF is_unload_field('END_DATE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                IF SREC.OFF_ID_FOR_MIGR IN ('121000080', '121000117')
                   AND (gv_sbpi_int_arr(I).ACTIVE_TO IS NULL OR gv_sbpi_int_arr(I).ACTIVE_TO > to_date('31.12.2037', 'dd.mm.yyyy'))
                THEN
                   SREC.END_DATE := to_date('31.12.2037', 'dd.mm.yyyy');
                ELSE
                  SREC.END_DATE := gv_sbpi_int_arr(I).ACTIVE_TO - 1;--29.03.2021
                END IF;
              END IF;
              -- ������ ���������� ��������
              IF is_unload_field('EXT_BPI_STATUS', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.EXT_BPI_STATUS := gv_sbpi_int_arr(I).EXT_BPI_STATUS;
              END IF;
              -- ����, ����� ��� ���������� ������� ������ �������� EXT_BPI_STATUS
              IF is_unload_field('EXT_BPI_STATUS_DATE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SELECT
                  CASE
                    WHEN SREC.EXT_BPI_STATUS = 'Completed'    THEN SREC.ACTUAL_END_DATE -- ������� ������ ����� ���������
                    WHEN SREC.EXT_BPI_STATUS = 'Active'       THEN SREC.ACTUAL_START_DATE
                    WHEN SREC.EXT_BPI_STATUS = 'Disconnected' THEN SREC.ACTUAL_END_DATE
                    WHEN SREC.EXT_BPI_STATUS = 'Suspended'    THEN
                      -- �������� DATE_FROM ��� ������ ID=867, 102749
                      (SELECT MAX(alf.active_from) -- ���� �� �������� �� NO_DATA_FOUND
                       FROM plan_items_all pi,
                            activate_license_fee_all alf
                       WHERE 1 = 1
                         AND alf.addendum_id = gv_sbpi_int_arr(I).ADDENDUM_ID
                         AND alf.billing_id  = gv_sbpi_int_arr(I).BILLING_ID
                         AND alf.active_from <= lc_current_date --��������
                         AND COALESCE(alf.active_to, lc_current_date + 1) > lc_current_date
                         AND pi.plan_item_id = alf.plan_item_id
                         AND pi.billing_id = alf.billing_id
                         AND pi.service_id IN (867, 102749))
                    ELSE
                      NULL
                  END
                  INTO SREC.EXT_BPI_STATUS_DATE
                FROM DUAL;
              END IF;
              -- ����������� ������
              -- �� ������� GW_IP ������� ��������� �� �����. ������ ��������� ������ ���������� <marina.luchenkova@domru.ru> �� �� 09.09.2020 12:51
/*
              IF is_unload_field('GW_IP', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                IF SREC.OFF_ID_FOR_MIGR = '121000102' THEN -- �������������� ���������������� IPv4 �������
                  \*
                  TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="02.12.2019"
                  text="��������! ����������. !!! �� ���� ��� ���������� ������������ ����� !!!"
                  *\
                  FOR rec IN (SELECT NVL(IP.IDB_ID, IPP.IDB_ID) AS IDB_ID
                              FROM resource_contents_all        rc,
                                   addendum_resources_all       ar,
                                   ip_for_dedicated_clients_all i,
                                   idb_ph2_ip_v4address         ip,
                                   idb_ph2_ip_v4address_private ipp
                              WHERE 1 = 1
                                AND ar.addendum_id = gv_sbpi_int_arr(i).addendum_id
                                AND ar.billing_id  = gv_sbpi_int_arr(i).billing_id
                                AND ar.active_from <= nvl(rc.active_to, ar.active_from + 1)
                                AND nvl(ar.active_to, rc.active_from + 1) > rc.active_from
                                AND ar.resource_id=rc.resource_id
                                AND ar.billing_id = rc.billing_id
                                AND i.terminal_resource_id = rc.terminal_resource_id
                                AND i.billing_id = rc.billing_id
                                -- ������������ ip ������� ������� �� ����� �������� �������������
                                -- ������������  (�������� "�����" ������)
                                --AND NOT (   i.ip between 10000000000  and 10255255255   \* 10.0.0.0 � 10.255.255.255 *\
                                --         or i.ip between 100064000000 and 100127255255 \* 100.64.0.0 � 100.127.255.255 *\
                                --         or i.ip between 172016000000 and 172031255255 \* 172.16.0.0 � 172.31.255.255 *\
                                --         or i.ip between 192168000000 and 192168255255 \* 192.168.0.0 � 192.168.255.255 *\
                                --         or i.ip between 127000000000 and 127255255255 \* 127.0.0.0 � 127.255.255.255 *\
                                --)
                                --
                                AND ip.source_id(+) = i.terminal_resource_id
                                AND ip.source_system(+) = i.billing_id
                                AND ip.source_system_type(+) = '1'
                                AND ipp.source_id(+) = i.terminal_resource_id
                                AND ipp.source_system(+) = i.billing_id
                                AND ipp.source_system_type(+) = '1')
                  LOOP
                    SREC.GW_IP := rec.IDB_ID;
                    EXIT;
                  END LOOP;
                ELSIF SREC.OFF_ID_FOR_MIGR = '121000093' THEN -- �������������� IPv6 �������
                  SREC.GW_IP := NULL;
                ELSE
                  SREC.GW_IP := NULL;
                END IF;
              END IF;
*/
              -- ����������� IPv6 �������
              -- ph2i5
              IF is_unload_field('GW_IPV6PREFIX', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.GW_IPV6PREFIX := NULL;
              END IF;
              -- ��������� ���� ������� ������� ������������ ��� ����������� ��������� ��������-������� � ������������ ����� ���������.
              SREC.IDB_ID := gv_sbpi_int_arr(I).IDB_ID;
              IF gv_sbpi_int_arr(I).SERVICE_ID IN (1799, 534) THEN
                SREC.IDB_ID := SREC.IDB_ID || '/' || SUBSTR(LT_IPV4ADR(II), 1, INSTR(LT_IPV4ADR(II),'|', 1, 1) -1);
              END IF;
              -- ��� � �����
              -- ������� ����� UPDATE �������� � �������� IDB_PH2_OFFERINGS_DIC
              IF SREC.OFF_ID_FOR_MIGR = '121000501' THEN
                SREC.INV_NAME := '�������������� IPv4 �������';
              ELSE
                SREC.INV_NAME := gv_sbpi_int_arr(I).INV_NAME;
              END IF;
              -- IPv4 �����
              IF is_unload_field('IPV4ADR', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.IPV4ADR := SUBSTR(LT_IPV4ADR(II), 1, INSTR(LT_IPV4ADR(II),'|', 1, 1) -1); -- ���. IPV4
              END IF;
              -- ��� IPv4 ������
              IF is_unload_field('IPV4_TYPE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                IF SREC.OFF_ID_FOR_MIGR IN ('121000087') THEN
                  SREC.IPV4_TYPE := NVL(SUBSTR(LT_IPV4ADR(II), INSTR(LT_IPV4ADR(II),'|', -1, 1)+1, 500), '���������');
                ELSIF SREC.OFF_ID_FOR_MIGR IN ('121000102', '121000501', '121000493') THEN
                  SREC.IPV4_TYPE := '���������';
                                         /*
                                         TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="22.12.2019"
                                         text="�� �������, ��� ��� ���� �����. ��� �������� ����������� �����?"
                                         */
                ELSE
                  SREC.IPV4_TYPE := NULL;
                END IF;
              END IF;
              -- IPv6 Range. ������ �� IDB_PH2_IP_V6RANGE.IDB_ID
              IF is_unload_field('IPV6RANGE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.IPV6RANGE := rias_mgr_support.get_linked_subnets(addendum_id$i => gv_sbpi_int_arr(i).addendum_id,
                                                                      billing_id$i => gv_sbpi_int_arr(i).billing_id);
              END IF;

              -- ����������� ����� � �������� �� ������� ��������� �������� � ������� Active ��� Disconnected ��� ����� ���� �� ���������� ��������� ����������� �������. �������� ������ ���� �������� �� 100 000
              -- ����� �� ����������� ����� �������� ��������. �������� ������ ���� �������� �� 100 000
              -- ����� �������� �������: �������� ���� � ������ ������. �������� ������ ���� �������� �� 100 000

    /*
      TYPE t_mrc_rec IS RECORD(koef_nds  NUMBER,      -- ���������� ��� (��������, 1.2)
                               serv_cost NUMBER,      -- ��������� ������ ��� ���
                               mrc_cupon NUMBER,      -- % ������ �� ���������� ������ ��� �� ������ ������
                               mrc_without_nds NUMBER -- ��������� ������ � ������ ������
                               mrc_with_nds NUMBER    -- ��������� ������ � ������ ���
      );
    */
              IF gv_sbpi_int_arr(I).SERVICE_ID = 237 THEN
                SREC.MRC := 0;
                SREC.TAX_MRC := 0;
                SREC.TOTAL_PRICE_TAX_NRC := ROUND(get_tmp_list_number(ip_task_id$i => lv_task_id,
                                                                      ip_id$i      => gv_sbpi_int_arr(i).connect_pays_id,
                                                                      ip_num_flag  => 1), 2) * lc_koef_bss_mrc;
                SREC.NRC_CUPON := get_tmp_list_number(ip_task_id$i => lv_task_id,
                                                      ip_id$i      => gv_sbpi_int_arr(i).connect_pays_id,
                                                      ip_num_flag  => 2);
                SREC.NRC_CUPON_MNT := get_tmp_list_number(ip_task_id$i => lv_task_id,
                                                          ip_id$i      => gv_sbpi_int_arr(i).connect_pays_id,
                                                          ip_num_flag  => 3) * lc_koef_bss_mrc;
              ELSIF gv_sbpi_int_arr(I).SERVICE_ID = 163 THEN
                SREC.MRC          := 0;
                SREC.TAX_MRC      := 0;
                SREC.TOTAL_PRICE_TAX_NRC := 0;
                -- ����� ����� ������ ���� ������ ���������� � ����� ��������
                IF SREC.ACTUAL_START_DATE BETWEEN TRUNC(lc_current_date, 'MM') AND (TRUNC(ADD_MONTHS(lc_current_date,1), 'MM')-1) THEN
                  SREC.TOTAL_PRICE_TAX_NRC := ROUND(lv_mrc_rec.mrc_with_nds, 2) * lc_koef_bss_mrc;
                END IF;
              ELSIF gv_sbpi_int_arr(I).SERVICE_ID IN (1678) THEN
                SREC.MRC     := 0;
                SREC.TAX_MRC := 0;
                SREC.TOTAL_PRICE_TAX_NRC := 0;
              ELSIF gv_sbpi_int_arr(I).SERVICE_ID = 534 THEN -- ������� ��� ������� IP-������
                IF lv_ip_is_local$i = 0 OR gv_sbpi_int_arr(i).billing_id = 556 THEN -- "�����" IP-����� ��� �����-��������� (https://jsd.netcracker.com/browse/ERT-19304)
                  SREC.MRC     := ROUND(lv_mrc_rec.mrc_with_nds/LT_IPV4ADR.COUNT, 2) * lc_koef_bss_mrc;
                  SREC.TAX_MRC := ROUND(lv_mrc_rec.mrc_without_nds * (lv_mrc_rec.koef_nds - 1)/LT_IPV4ADR.COUNT, 2) * lc_koef_bss_mrc;
                  SREC.TOTAL_PRICE_TAX_NRC := 0;
                ELSE
                  SREC.MRC     := 0;
                  SREC.TAX_MRC := 0;
                  SREC.TOTAL_PRICE_TAX_NRC := 0;
                END IF;
              ELSIF gv_sbpi_int_arr(I).SERVICE_ID = 1799 THEN -- ����� ��� ������� ��������� ��� ������� IP-������
                IF lv_ip_is_local$i = 0 THEN -- "�����" IP-�����
                  SREC.MRC     := ROUND(lv_mrc_rec.mrc_with_nds, 2) * lc_koef_bss_mrc;
                  SREC.TAX_MRC := ROUND(lv_mrc_rec.mrc_without_nds * (lv_mrc_rec.koef_nds - 1), 2) * lc_koef_bss_mrc;
                  SREC.TOTAL_PRICE_TAX_NRC := 0;
                ELSE                         -- "�����" IP-�����
                  SREC.MRC     := 0;
                  SREC.TAX_MRC := 0;
                  SREC.TOTAL_PRICE_TAX_NRC := 0;
                END IF;
              ELSIF gv_sbpi_int_arr(I).SERVICE_ID = 101646 THEN
                DECLARE
                  lv_number_bonus$n NUMBER;
                  lv_price$n NUMBER;
                  lv_nds$n NUMBER;
                BEGIN
                  -- ������ ���
                  lv_nds$n := rias_mgr_support.get_nds(service_id$i => gv_sbpi_int_arr(i).service_id,
                                                       billing_id$i => gv_sbpi_int_arr(i).billing_id);
                  -- ������ �������� ������
                  lv_number_bonus$n := rias_mgr_support.get_number_bonus(activity_id$i => gv_sbpi_int_arr(i).activity_id,
                                                                         billing_id$i => gv_sbpi_int_arr(i).billing_id);
                  -- ������ �������� ���� �� 1 ��
                  lv_price$n := rias_mgr_support.get_price_4_bonus(plan_item_id$i => gv_sbpi_int_arr(i).plan_item_id,
                                                                   billing_id$i   => gv_sbpi_int_arr(i).billing_id,
                                                                   service_id$i   => gv_sbpi_int_arr(i).service_id,
                                                                   threshold$i  => lv_number_bonus$n);
                  -- ������ ����� ���������
                  SREC.MRC := ROUND(lv_price$n * lv_number_bonus$n, 2);
                  SREC.TAX_MRC := ROUND(SREC.MRC - SREC.MRC/lv_nds$n, 2) * lc_koef_bss_mrc;
                  SREC.MRC := SREC.MRC * lc_koef_bss_mrc;
                  SREC.TOTAL_PRICE_TAX_NRC := 0;
                END;
              ELSE
                IF gv_sbpi_int_arr(I).PLAN_NAME LIKE '%��������� ������%' OR
                   gv_sbpi_int_arr(I).PLAN_NAME LIKE '%��������������%' OR
                   gv_sbpi_int_arr(I).PLAN_NAME LIKE '%���� ������ %' OR
                   gv_sbpi_int_arr(I).PLAN_NAME LIKE '%���� ������+%'
                THEN
                  SREC.MRC := 0;
                  SREC.TAX_MRC := 0;
                  SREC.TOTAL_PRICE_TAX_NRC := 0;
                ELSE
                  SREC.MRC := ROUND(lv_mrc_rec.mrc_with_nds, 2) * lc_koef_bss_mrc;
                  SREC.TAX_MRC := ROUND(lv_mrc_rec.mrc_without_nds * (lv_mrc_rec.koef_nds - 1), 2) * lc_koef_bss_mrc;
                  SREC.TOTAL_PRICE_TAX_NRC := 0;
                END IF;

    /*
                -- ����������� ����� � �������� �� ������� ��������� �������� ��� ����� ����
                -- �� ���������� ��������� ����������� �������. �������� ������ ���� �������� �� 100 000
                SREC.MRC := lv_charges_value.value_w_nds;
                -- ����� �� ����������� ����� �������� ��������. �������� ������ ���� �������� �� 100 000
                SREC.TAX_MRC := (lv_charges_value.value_w_nds - lv_charges_value.value_not_nds);
                -- ����� �������� �������: �������� ���� � ������ ������. �������� ������ ���� �������� �� 100 000
                SREC.TOTAL_PRICE_TAX_NRC := 0;
    */
              END IF;
              -- ������� ������ (�����) �� ������� ����. ����������� �� ��������� ������ �� �������� �������.
              -- ph2i5
              IF is_unload_field('MRC_CUPON', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.MRC_CUPON := lv_mrc_rec.mrc_cupon;
              END IF;
              -- ��� �������, ������������ � ���������������� ����������
              IF is_unload_field('LEGACY_OBJECT_NAME', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.LEGACY_OBJECT_NAME := gv_sbpi_int_arr(I).PLAN_NAME;
              END IF;
              -- ������ ��������� �������������� ������
              -- ���� �� ������� ������ ��� ���������, �� ���� �� �����������
              -- ��������������� � ������ Billed ���� ��������� ��������� ���������.
              -- ��������������� � ������ Unbilled ���� ��������� �� ���������
              IF is_unload_field('OTS_STATUS', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.OTS_STATUS := 'Billed';
              END IF;
              -- ������ �� ������� ��������� ������������ ����������� � ��������� (BPI_ID)
              IF is_unload_field('PARENT_ID', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.PARENT_ID := gv_sbpi_int_arr(i).TLO_IDB_ID;
              END IF;
              -- ��������������: ������������� ������������� �������
              -- ph2i5
              IF is_unload_field('PARENT_SERVICE_ID', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.PARENT_SERVICE_ID := lv_tbpi_rec.PARENT_SERVICE_ID;
              END IF;
              --�������!!!!!!!
              IF is_unload_field('PREFIX', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.PREFIX := LT_IPV4ADR(II);
              END IF;
              -- ������ ��������
              -- ph2i5
              IF is_unload_field('PREFIX_SIZE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.PREFIX_SIZE := '/64';
              END IF;
              -- ���� ����������� ����������� ����� �� �������.
              -- �� ������ ��  ��������� �������� ��������� <veronika.gorbunova@domru.ru>   13.02.2020 15:05
              --SREC.PREV_BILL_TO_DAT := add_months(gv_sbpi_int_arr(I).BILLED_TO_DAT,-1);--gv_sbpi_int_arr(I).PREV_BILL_TO_DAT;
              /*
              IF is_unload_field('PREV_BILL_TO_DAT', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.PREV_BILL_TO_DAT := CASE WHEN SREC.BILLED_TO_DAT IS NULL THEN NULL ELSE add_months(SREC.BILLED_TO_DAT, -1) END;
              END IF;
              */
              -- ������ ������ IPv6
              -- ph2i5
              IF is_unload_field('PROTECTED_OBJ_IP6', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.PROTECTED_OBJ_IP6 := NULL; /*
                                                TODO: owner="bikulov.md" category="Fix" priority="2 - Medium" created="22.12.2019"
                                                text="�� �������� �� ������� ��� ���������
                                                */
              END IF;
              -- ������������� �������. ���������� �������������, ������������� ������� �������.
              -- ph2i5
              IF is_unload_field('SERVICE_ID', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                lv_prefix := get_prefix4offer(off_id_for_migr$c => SREC.OFF_ID_FOR_MIGR);
                SREC.SERVICE_ID := lv_prefix || '-' || to_char(SREC.ACTUAL_START_DATE, 'ddmmyyyy') || '1'; -- ������� ����� ���������  !!! PREFIX � PH2IT6!!!
              END IF;
              -- ������������� ������� ������ �������� �������
              IF is_unload_field('SOURCE_ID', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.SOURCE_ID := gv_sbpi_int_arr(I).SOURCE_ID;
              END IF;
              -- ������������� ���������� �������� �������
              IF is_unload_field('SOURCE_SYSTEM', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.SOURCE_SYSTEM := gv_sbpi_int_arr(I).SOURCE_SYSTEM;
              END IF;
              -- ������������� ���� �������� ������� (����, ����, ������,...)
              IF is_unload_field('SOURCE_SYSTEM_TYPE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.SOURCE_SYSTEM_TYPE := gv_sbpi_int_arr(I).SOURCE_SYSTEM_TYPE;
              END IF;
              -- IPv4 ������� �������!!!!!!!
              -- ������ �� IDB_PH2_IP_V4RANGE.IDB_ID; IDB_PH2_IP_V4RANGE_PRIVATE.IDB_ID; IDB_PH2_IP_V6RANGE.IDB_ID; IDB_PH2_IP_V6RANGE_PRIVATE.IDB_ID;  ????
              IF is_unload_field('SUBNET', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                                                            /*
                                                                       TODO: owner="bikulov.md" category="Fix" priority="2 - Medium" created="02.12.2019"
                                                                       text="�������� ������� ����������. ������ ������� ���������� NULL
                                                                            ��� ���� ������. ������ ��� ������������"
                                                                     */
                SREC.SUBNET := GET_SUBNET(ip_addendum_id$i => gv_sbpi_int_arr(i).addendum_id,
                                          ip_billing_id$i  => gv_sbpi_int_arr(i).billing_id);
              END IF;
              -- ��� ��������� �����. ������� ��������: �����;������;������+; � �.�.
              IF is_unload_field('TARIFF_PLAN_NAME', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.TARIFF_PLAN_NAME := gv_sbpi_int_arr(I).TARIFF_PLAN_NAME;
              END IF;
              -- ���������� �������� �� (����/�). ������� ����������: 10;20;30;50 �.�.�.
              IF gv_sbpi_int_arr(I).SERVICE_ID = 1678 THEN
                IF is_unload_field('UP_ON', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                  SREC.UP_ON := ROUND(NVL(gv_sbpi_int_arr(I).UP, 0)  - NVL(gv_sbpi_int_arr(I).SPEED_NIGHT, 0), 0);
                END IF;
              END IF;
              -- ���������� �������� �� (����/�). ������� ����������: 10, 30, 50, �.�.�.
              IF gv_sbpi_int_arr(I).SERVICE_ID IN (101646) THEN
                IF is_unload_field('UP_TO', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                  SREC.UP_TO := gv_sbpi_int_arr(I).UP;
                END IF;
              END IF;
              -- ��������� ����/�
              SREC.UP_ON := SREC.UP_ON || CASE WHEN SREC.UP_ON IS NOT NULL THEN ' ����/�' ELSE '' END;
              SREC.UP_TO := SREC.UP_TO || CASE WHEN SREC.UP_TO IS NOT NULL THEN ' ����/�' ELSE '' END;

              -- ������ (ph2i5)
              IF is_unload_field('VENDOR', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                IF SREC.OFF_ID_FOR_MIGR = '121000072' THEN
                  SREC.VENDOR := 'Service Pipe';
                ELSIF SREC.OFF_ID_FOR_MIGR = '121000614' THEN
                  SREC.VENDOR := 'Guard';
                ELSE
                  SREC.VENDOR := NULL;
                END IF;
              END IF;
              --============================
              -- #��6#It6#
              --============================
              -- M&A ����
              IF is_unload_field('MA_FLAG', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.MA_FLAG := '�������� ������';
              END IF;
              -- ���� ��������� M&A �����
              IF is_unload_field('MA_FLAG_DATE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.MA_FLAG_DATE := TRUNC(lc_current_date);
              END IF;
              --
              IF is_unload_field('BPI_TIME_ZONE', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.BPI_TIME_ZONE := rias_mgr_support.get_time_zone(ip_city_id$i => lv_curr_billing,
                                                                     ip_what_give$c => 'N');
              END IF;
              -- ��������� �������. ��������� ������� � ������� ������; ��������� PPPoE �������
              -- ��� ��������
              IF is_unload_field('ACCESS_CRED_PPPOE_ACC', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.ACCESS_CRED_PPPOE_ACC := NULL;
              END IF;
              -- IPv4 �������
                             /*
                             TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="23.05.2020"
                             text="�� ������� ��� ����"
                             */
              IF is_unload_field('SUBNET_ADD', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.SUBNET_ADD := NULL;
              END IF;

              --============================
              -- #��8#It8#
              --============================
              IF is_unload_field('BPI_MARKET', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.BPI_MARKET := lv_tbpi_rec.BPI_MARKET;
              END IF;
              IF is_unload_field('BPI_ORGANIZATION', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.BPI_ORGANIZATION := lv_tbpi_rec.BPI_ORGANIZATION;
              END IF;

              --It12��12
              IF is_unload_field('BARRING', SREC.OFF_ID_FOR_MIGR) = 1 THEN
                SREC.BARRING := lv_tbpi_rec.BARRING;
              END IF;

              --============================
              -- ������� � ������ ��� �������
              --============================
              gv_rec_arr(gv_rec_arr.COUNT +1 ) := SREC;


              -- �������� DBG-����������
              rias_mgr_core.insert_dbg_info(
                ip_table_id  => lc_table_id$i,
                ip_dbg_info  =>
                  SUBSTR('�������: '         || TO_CHAR(lv_curr_billing)                  || CHR(13) ||
                         '�������: '         || gv_sbpi_int_arr(I).AGREEMENT_NUMBER       || CHR(13) ||
                         'AGREEMENT_ID: '    || TO_CHAR(gv_sbpi_int_arr(I).AGREEMENT_ID)  || CHR(13) ||
                         '����� ����������: '|| gv_sbpi_int_arr(I).ADDENDUM_NUMBER        || CHR(13) ||
                         'P_ADDENDUM_ID: '   || TO_CHAR(gv_sbpi_int_arr(I).ADDENDUM_ID)   || CHR(13) ||
                         'PLAN_ID: '         || TO_CHAR(gv_sbpi_int_arr(I).PLAN_ID)       || CHR(13) ||
                         'PLAN_NAME: '       || gv_sbpi_int_arr(I).PLAN_NAME              || CHR(13) ||
                         'PLAN_ITEM_ID: '    || TO_CHAR(gv_sbpi_int_arr(I).PLAN_ITEM_ID)  || CHR(13) ||
                         'SERVICE_ID: '      || TO_CHAR(gv_sbpi_int_arr(I).service_id)    || CHR(13) ||
                         'ACTIVE_FROM: '     || TO_CHAR(gv_sbpi_int_arr(i).ACTIVE_FROM,'dd.mm.yyyy') || CHR(13) ||
                         'ACTIVE_TO: '       || TO_CHAR(gv_sbpi_int_arr(i).ACTIVE_TO,'dd.mm.yyyy')   || CHR(13) ||
                         '������:'                                                                            || CHR(13) ||
                         '  KOEF_NDS: '      || TO_CHAR(lv_mrc_rec.koef_nds)                                  || CHR(13) ||
                         '  ��������� ������ ��� ���: '                || TO_CHAR(lv_mrc_rec.serv_cost)       || CHR(13) ||
                         '  % ������: '                                || TO_CHAR(lv_mrc_rec.mrc_cupon)       || CHR(13) ||
                         '  ��������� ������ � ������ ������ ��� ���: '|| TO_CHAR(lv_mrc_rec.mrc_without_nds) || CHR(13) ||
                         '  ��������� ������ � ������ ������ � ���: '  || TO_CHAR(lv_mrc_rec.mrc_with_nds)
                    , 1, 4000
                  ),
                ip_idb_id    => SREC.IDB_ID
              );

              --�������� ����� "�������� ��������" (121000964) ��� SLO �������-���������� (��������) (121000021)
              IF SREC.OFF_ID_FOR_MIGR = '121000021' THEN

                FOR rec_child IN (
                  SELECT alf.active_from,
                         alf.active_to,
                         alf.activity_id,
                         pi.plan_item_id

                  FROM activate_license_fee_all alf,
                       plan_items_all           pi
                  WHERE 1=1
                    AND alf.addendum_id = gv_sbpi_int_arr(i).addendum_id
                    AND alf.billing_id = lv_curr_billing
                    -- ������ ��������� � ����� ��������
                    AND alf.active_from BETWEEN trunc(lc_current_date, 'MM') AND lc_current_date - 1 /*
                                                                                               TODO: owner="bikulov.md" category="Fix" priority="1 - High" created="09.04.2020"
                                                                                               text="�������� �����/�� ����� ���.����"
                                                                                               */
                    -- AND (ALF.ACTIVE_TO IS NULL OR ALF.ACTIVE_TO > lc_current_date)
                    AND pi.plan_item_id = alf.plan_item_id
                    AND pi.billing_id = alf.billing_id
                    AND pi.billing_id = lv_curr_billing
                    AND pi.service_id = 101180
                ) LOOP
                  srec_child.off_id_for_migr := '121000964';
                  IF is_unload_field('ACCOUNT_IDB_ID', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.account_idb_id := srec.account_idb_id;
                  END IF;
                  IF is_unload_field('ACTUAL_START_DATE', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.actual_start_date := rec_child.active_from;
                  END IF;
                  IF is_unload_field('ACTUAL_END_DATE', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.actual_end_date := rec_child.active_to;
                  END IF;
                  IF is_unload_field('CUSTOMER_IDB_ID', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.customer_idb_id := srec.customer_idb_id;
                  END IF;
                  IF is_unload_field('CUSTOMER_LOCATION', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.customer_location := srec.customer_location;
                  END IF;
                  IF is_unload_field('EXT_BPI_STATUS', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.ext_bpi_status := srec.ext_bpi_status;
                  END IF;
                  srec_child.idb_id := 'SI_1/'|| to_char(lv_curr_billing) || '/' ||
                                        to_char(gv_sbpi_int_arr(i).agreement_id) || '/' ||
                                        to_char(gv_sbpi_int_arr(i).addendum_id)  || '/' ||
                                        to_char(rec_child.plan_item_id) || '/' ||
                                        to_char(rec_child.activity_id);
                  IF is_unload_field('inv_name', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.inv_name  := '�������-���������� (��������)';
                  END IF;
                  IF is_unload_field('parent_id', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.parent_id := srec.idb_id;
                  END IF;
                  IF is_unload_field('source_id', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.source_id := srec.source_id;
                  END IF;
                  IF is_unload_field('source_system', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.source_system := srec.source_system;
                  END IF;
                  IF is_unload_field('source_system_type', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.source_system_type := srec.source_system_type;
                  END IF;
                  IF is_unload_field('ext_bpi_status_date', srec_child.off_id_for_migr) = 1 THEN
                  srec_child.ext_bpi_status_date := srec.ext_bpi_status_date;
                  END IF;
                  IF is_unload_field('ma_flag', srec_child.off_id_for_migr) = 1 THEN
                  srec_child.ma_flag := srec.ma_flag;
                  END IF;
                  IF is_unload_field('ma_flag_date', srec_child.off_id_for_migr) = 1 THEN
                  srec_child.ma_flag_date := srec.ma_flag_date;
                  END IF;
                  IF is_unload_field('mrc', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.mrc := 1.20 * lc_koef_bss_mrc;
                  END IF;
                  IF is_unload_field('tax_mrc', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.tax_mrc := 0.2 * lc_koef_bss_mrc;
                  END IF;
                  IF is_unload_field('service_id', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.service_id := get_prefix4offer(srec_child.off_id_for_migr) || '-' || to_char(rec_child.active_from, 'ddmmyyyy') || '1'; -- ������� ����� ���������  !!! PREFIX � PH2IT6!!!
                  END IF;
                  IF is_unload_field('parent_service_id', srec_child.off_id_for_migr) = 1 THEN
                    srec_child.parent_service_id := srec.service_id;
                  END IF;
                  IF is_unload_field('bpi_time_zone', srec_child.off_id_for_migr) = 1 THEN
                  srec_child.bpi_time_zone := rias_mgr_support.get_time_zone(ip_city_id$i => lv_curr_billing, ip_what_give$c => 'N');
                  END IF;
                  IF is_unload_field('bpi_market', srec_child.off_id_for_migr) = 1 THEN
                  srec_child.bpi_market := srec.bpi_market;
                  END IF;
                  IF is_unload_field('bpi_organization', srec_child.off_id_for_migr) = 1 THEN
                  srec_child.bpi_organization := srec.bpi_organization;
                  END IF;
                END LOOP;
                IF srec_child.idb_id IS NOT NULL THEN
                --============================
                -- ������� � ������ ��� �������
                --============================
                  gv_rec_arr(gv_rec_arr.COUNT +1 ) := srec_child;
                  -- �������� DBG-����������
                  rias_mgr_core.insert_dbg_info(
                    ip_table_id  => lc_table_id$i,
                    ip_dbg_info  =>
                      SUBSTR('����� SLO:'|| CHR(13) ||
                             '�������: '         || TO_CHAR(lv_curr_billing)                  || CHR(13) ||
                             '�������: '         || gv_sbpi_int_arr(I).AGREEMENT_NUMBER       || CHR(13) ||
                             'AGREEMENT_ID: '    || TO_CHAR(gv_sbpi_int_arr(I).AGREEMENT_ID)  || CHR(13) ||
                             '����� ����������: '|| gv_sbpi_int_arr(I).ADDENDUM_NUMBER        || CHR(13) ||
                             'P_ADDENDUM_ID: '   || TO_CHAR(gv_sbpi_int_arr(I).ADDENDUM_ID)   || CHR(13) ||
                             'PLAN_ID: '         || TO_CHAR(gv_sbpi_int_arr(I).PLAN_ID)       || CHR(13) ||
                             'PLAN_NAME: '       || gv_sbpi_int_arr(I).PLAN_NAME              || CHR(13) ||
                             'PLAN_ITEM_ID: '    || NULL/*rec_child.plan_item_id*/                    || CHR(13) ||
                             'SERVICE_ID: '      || TO_CHAR(101180)                           || CHR(13) ||
                             'ACTIVE_FROM: '     || TO_CHAR(srec_child.actual_start_date,'dd.mm.yyyy') || CHR(13) ||
                             'ACTIVE_TO: '       || NULL/*TO_CHAR(rec_child.active_to,'dd.mm.yyyy')*/  || CHR(13) ||
                             'TOTAL_PRICE_TAX_NRC: '||TO_CHAR(srec_child.total_price_tax_nrc)
                        , 1, 4000
                      ),
                    ip_idb_id    => srec_child.idb_id
                  );
                END IF;
              END IF;

            EXCEPTION
              WHEN OTHERS THEN
                -- �������� ���������� �� ������
                lv_err_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => lc_table_id$i,
                                                                ip_message => SUBSTR('Err: ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace || --chr(13) ||
                                                                                     'DEBUG_INFO:' || chr(13) ||
                                                                                     '�������: '          ||lv_curr_billing || CHR(13) ||
                                                                                     '�������: '          || gv_sbpi_int_arr(I).AGREEMENT_NUMBER || '(' || TO_CHAR(gv_sbpi_int_arr(I).AGREEMENT_ID)|| ')' || CHR(13) ||
                                                                                     '����� ����������: ' || gv_sbpi_int_arr(I).ADDENDUM_NUMBER  || '(' || TO_CHAR(gv_sbpi_int_arr(I).ADDENDUM_ID) || ')' || CHR(13) ||
                                                                                     'IDB_ID: '           || gv_sbpi_int_arr(I).IDB_ID || CHR(13) ||
                                                                                     'PARENT_ID: '        || gv_sbpi_int_arr(i).TLO_IDB_ID || CHR(13) ||
                                                                                     'PLAN_ID: '          || TO_CHAR(gv_sbpi_int_arr(I).PLAN_ID) || CHR(13) ||
                                                                                     'PLAN_ITEM_ID: '     || TO_CHAR(gv_sbpi_int_arr(I).PLAN_ITEM_ID) || CHR(13) ||
                                                                                     'ACTIVITY_ID: '      || TO_CHAR(gv_sbpi_int_arr(I).ACTIVITY_ID)
                                                                                     , 1, 2000),
                                                                ip_err_code => SUBSTR('SQLCODE = ' || TO_CHAR(SQLCODE) ||' SQLERRM = ' || SQLERRM, 1, 200),
                                                                ip_thread_id => ip_thread$i,
                                                                ip_city_id => lv_curr_billing,
                                                                ip_slog_slog_id => lv_slog_id);
            --RAISE;
            END;
          END LOOP; -- LOOP LT_IPV4ADR

        EXCEPTION
          WHEN OTHERS THEN
              -- �������� ���������� �� ������
              lv_err_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => lc_table_id$i,
                                                              ip_message => SUBSTR('Err: ' || dbms_utility.format_error_stack || dbms_utility.format_error_backtrace || --chr(13) ||
                                                                                   'DEBUG_INFO:' || chr(13) ||
                                                                                   '�������: '          ||lv_curr_billing || CHR(13) ||
                                                                                   '�������: '          || gv_sbpi_int_arr(I).AGREEMENT_NUMBER || '(' || TO_CHAR(gv_sbpi_int_arr(I).AGREEMENT_ID)|| ')' || CHR(13) ||
                                                                                   '����� ����������: ' || gv_sbpi_int_arr(I).ADDENDUM_NUMBER  || '(' || TO_CHAR(gv_sbpi_int_arr(I).ADDENDUM_ID) || ')' || CHR(13) ||
                                                                                   'IDB_ID: '           || gv_sbpi_int_arr(I).IDB_ID || CHR(13) ||
                                                                                   'PARENT_ID: '        || gv_sbpi_int_arr(i).TLO_IDB_ID || CHR(13) ||
                                                                                   'PLAN_ID: '          || TO_CHAR(gv_sbpi_int_arr(I).PLAN_ID) || CHR(13) ||
                                                                                   'PLAN_ITEM_ID: '     || TO_CHAR(gv_sbpi_int_arr(I).PLAN_ITEM_ID) || CHR(13) ||
                                                                                   'ACTIVITY_ID: '      || TO_CHAR(gv_sbpi_int_arr(I).ACTIVITY_ID)
                                                                                   , 1, 2000),
                                                              ip_err_code => SUBSTR('SQLCODE = ' || TO_CHAR(SQLCODE) ||' SQLERRM = ' || SQLERRM, 1, 200),
                                                              ip_thread_id => ip_thread$i,
                                                              ip_city_id => lv_curr_billing,
                                                              ip_slog_slog_id => lv_slog_id);
        --RAISE;
        END;
      END LOOP; -- LOOP gv_sbpi_int_arr
      -- ������� �������������� ������ � �������
      INSERT_ROWS();
    END LOOP; --
    -- ������� ������ �� �������
    CLOSE LC_SBPI_INT;
    -- ������-�� �� ������ ���������� ������� � �������
    INSERT_ROWS();
    -- ������� ��������� �������
    clear_rias_mgr_tmp_list(lv_task_id);
    -- ���� ���� ����������� ����� ������� ������, �� ������ ���
    IF lc_commit_after_city THEN
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
  -- �������� ������ ����� DBG-����������
  rias_mgr_core.dbg_stop;
  --
  RIAS_MGR_CORE.restore_session_state;

END RIAS_FILL_SBPI_PROC;
/

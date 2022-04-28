CREATE OR REPLACE PACKAGE IDB_PROD_PH4.RIAS_MGR_CORE
/**
* ����� ������������ ��������
* ������ 001.00
*
* 30.01.2020 ������� �.�. ��������
*
*/
AS
  --------------------------
  -- ����
  --------------------------
  TYPE t_cities_list IS TABLE OF INTEGER INDEX BY PLS_INTEGER;
  -- ��� ���������� DBG-����������
  TYPE t_dbg_info_rec IS RECORD(dbg_id    INTEGER,          -- ��������� ����
                                table_id  INTEGER,          -- ������������� ������� ��� ���������� DBG-����������
                                tbl_rowid ROWID,            -- ROWID ������ �� �������� �������
                                idb_id    VARCHAR2(150),    -- IDB_ID ��� ������ �� �������� �������
                                dbg_info  VARCHAR2(4000)    -- DBG-����������
  );
  TYPE t_dbg_info_list IS TABLE OF t_dbg_info_rec INDEX BY PLS_INTEGER;

  --------------------------
  -- ���������� ����������
  --------------------------
  gv_dbg_info_list t_dbg_info_list;

  /**
  * ��������: �������� �� ����� ��������
  */
  PROCEDURE package_is_valid;

  /**
  * ���������� �������� ��������� session info
  * @author
  * @version
  */
  PROCEDURE save_session_state;

  /**
  * �������������� �������� ��������� session info
  * @author BikulovMD
  * @version
  */
  PROCEDURE restore_session_state;

  /**
  * ������� ������ ����
  * @param ip_table_id       - ������������� ������� ��� ����������
  * @param ip_message        - ���������
  * @param ip_err_code       - ��������� �� ������
  * @param ip_thread_id      - ������������� ������ ����������
  * @param ip_city_id        - ������������� ������
  * @param ip_reccount       - ���������� �������
  * @param ip_duration       - ����� ���������� (���.)
  * @param ip_date_start     - ���� ������
  * @param ip_date_end       - ���� ���������
  * @param ip_slog_slog_id   - ������������� ������������ ������ � ����
  * @return ������������� ����������� ������
  */
  FUNCTION insert_log_info(
    ip_table_id     IN INTEGER,
    ip_message      IN VARCHAR2 DEFAULT NULL,
    ip_err_code     IN VARCHAR2 DEFAULT NULL,
    ip_thread_id    IN INTEGER  DEFAULT NULL,
    ip_city_id      IN INTEGER  DEFAULT NULL,
    ip_reccount     IN INTEGER  DEFAULT NULL,
    ip_duration     IN NUMBER   DEFAULT NULL,
    ip_date_start   IN DATE DEFAULT SYSDATE,
    ip_date_end     IN DATE     DEFAULT NULL,
    ip_slog_slog_id IN INTEGER  DEFAULT NULL
  ) RETURN INTEGER;

  /**
  * Update ���������� ������ ����
  * @param ip_slog_id        - ������������� ������ � ����
  * @param ip_message        - ���������
  * @param ip_err_code       - ��������� �� ������
  * @param ip_thread_id      - ������������� ������ ����������
  * @param ip_city_id        - ������������� ������
  * @param ip_reccount       - ���������� �������
  * @param ip_duration       - ����� ���������� (���.)
  * @param ip_date_end       - ���� ���������
  * @param ip_slog_slog_id   - ������������� ������������ ������ � ����
  */
  PROCEDURE update_log_info(
    ip_slog_id      IN INTEGER,
    --ip_table_id     IN INTEGER,
    ip_message      IN VARCHAR2 DEFAULT NULL,
    ip_err_code     IN VARCHAR2 DEFAULT NULL,
    ip_thread_id    IN INTEGER  DEFAULT NULL,
    ip_city_id      IN INTEGER  DEFAULT NULL,
    ip_reccount     IN INTEGER  DEFAULT NULL,
    ip_duration     IN NUMBER   DEFAULT NULL,
    --ip_date_start   IN DATE DEFAULT SYSDATE,
    ip_date_end     IN DATE     DEFAULT NULL,
    ip_slog_slog_id IN INTEGER  DEFAULT NULL
  );

  /**
  * ������� �� ���� ���������� ������ � � ������
  * @param ip_slog_id        - ������������� ������ � ����
  */
  PROCEDURE delete_log_info(ip_slog_id IN INTEGER);

  /**
  * ���� ���������� �� ���������� DBG-����������
  * @param ip_table_id - ������������� ������� ��� ���������� DBG-����������
  */
  FUNCTION get_is_save_dbg(ip_table_id IN INTEGER) RETURN BOOLEAN;

  /**
  * ������������� ������ ������ � DBG-����������
  * @param ip_table_id  - ������������� ������� ��� ���������� DBG-����������
  */
  PROCEDURE dbg_start(ip_table_id IN INTEGER);

  /**
  * ��������� ������ � DBG-����������
  */
  PROCEDURE dbg_stop;

  /**
  * ��������� DBG-����������
  * @param ip_table_id       - ������������� ������� ��� ���������� DBG-����������
  * @param ip_dbg_info       - DBG-����������
  * @param ip_idb_id         - IDB_ID ��� ������ �� �������� �������
  * @param ip_tbl_rowid      - ROWID ������ �� �������� �������
  */
  PROCEDURE insert_dbg_info(
    ip_table_id  IN INTEGER,
    ip_dbg_info  IN VARCHAR2,
    ip_idb_id    IN VARCHAR2 DEFAULT NULL,
    ip_tbl_rowid IN ROWID    DEFAULT NULL
  );

  /**
  * ������ ���������� ������� ���������
  * @param ip_thread_cnt$i - ���������� ������� ����������
  */
  PROCEDURE set_thread_count(ip_thread_cnt$i IN PLS_INTEGER);

  /**
  * �������� �������� ���������� ������� ����������
  */
  FUNCTION get_thread_count RETURN PLS_INTEGER;

  /**
  * �������� ������ ������� ��� ������ ����������
  * @param ip_table_id$i   - ������������ ������� ��� ����������
  * @param ip_thread$i     - ����� ������ ����������
  * @param ip_thread_cnt$i - ����� ������� � ����������
  * @param ip_slog_id$i    - ������������ ���.������ � ����
  */
  FUNCTION get_cities_list(
    ip_table_id$i   IN PLS_INTEGER,
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  ) RETURN t_cities_list;

  /**
  * ������������ ������ ��� �������� �������
  * ������������� ���������
  * ���������� � ���������� ������
  * @param ip_table_id$i   - ������������ ������� ��� ����������
  * @param ip_thread$i     - ����� ������ ����������
  * @param ip_thread_cnt$i - ����� ������� � ����������
  * @param ip_slog_id$i    - ������������ ���.������ � ����
  */
  PROCEDURE fill_table_thread(
    ip_table_id$i   IN INTEGER,
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  );

  /**
  * ����������� ������� ����������
  * @param ip_prefix_job_name#c - ������� ��� ����� ������
  */
  PROCEDURE p_drop_job(ip_prefix_job_name#c IN VARCHAR2);

  /**
  * ������ �������� �������� ��� ������� � �������������� ip_table_id$i
  *   �������� ��������������� �������������� ������ �������� � ������ RIAS_MGR_CONST
  * @param ip_table_id$i - ������������ ������� ��� ����������
  */
  PROCEDURE start_threads(ip_table_id$i IN INTEGER);

  /**
  * ������������ �������� �� ��������� �������� �������� ��� �������� �������
  * @param ip_table_id$i - ������������ �������
  */
  --PROCEDURE request_stop(ip_table_id$i IN INTEGER);

  /**
  * �������� �������� �����
  * @param ip_ftrtgl_id$i - ������������� ������
  * @return �������� �����
  */
  FUNCTION get_feature_toggle(ip_ftrtgl_id$i IN INTEGER) RETURN INTEGER;

  /**
  * �������� �������� �����
  * @param ip_tsk_num$c - ����� ������
  * @return �������� �����
  */
  FUNCTION get_feature_toggle(ip_tsk_num$c IN VARCHAR2) RETURN INTEGER;

END RIAS_MGR_CORE;
/
CREATE OR REPLACE PACKAGE BODY IDB_PROD_PH4.RIAS_MGR_CORE
/**
*
*/
AS
  --========================
  -- ���������� ���������
  --------------------------
  gc_time_sleep CONSTANT NUMBER := rias_mgr_support.get_mgr_number_parameter(2, 120);--120; -- �� ����������� ����� 10 �����
  gc_maket_prefix_job_name CONSTANT VARCHAR2(50) := 'JOB_#TABLENAME#_';
  -- ���� ��� COMMIT �� ���������� ������
  lc_commit    CONSTANT BOOLEAN := FALSE;

  --------------------------
  -- ���������� ����������
  --------------------------
  gv_thread_all PLS_INTEGER := 1;
  -- ���� ������ ���������� DBG-����������
  gv_is_dbg_info BOOLEAN := TRUE;
  --gv_dbg_info_rec_cnt PLS_INTEGER;
  gv_thread_max PLS_INTEGER := 9;

  --------------------------
  -- ���������� ����������
  --------------------------
  gv_module_name VARCHAR2(100);
  gv_action_name VARCHAR2(100);

  --------------------------
  -- ����
  --------------------------
  SUBTYPE t_prefix IS VARCHAR2(50);

  --======================== ���������/������� ========================
  /**
  * ������������� ������
  */
  PROCEDURE init_package
  IS
  BEGIN
    gv_thread_max := rias_mgr_support.get_mgr_number_parameter(mgr_prmt_id$i => 1, default_value$n => 5);
  END init_package;

  /**
  * ��������: �������� �� ����� ��������
  */
  PROCEDURE package_is_valid
  IS
  BEGIN
    NULL;
  END package_is_valid;

  /**
  * ���������� �������� ��������� session info
  * @author BikulovMD
  * @version
  */
  PROCEDURE save_session_state
  IS
  BEGIN
    dbms_application_info.read_module(module_name => gv_module_name,
                                      action_name => gv_action_name);

  END save_session_state;

  /**
  * �������������� �������� ��������� session info
  * @author BikulovMD
  * @version
  */
  PROCEDURE restore_session_state
  IS
  BEGIN
    dbms_application_info.set_module(module_name => gv_module_name,
                                     action_name => gv_action_name);
  END restore_session_state;

  /**
  * ������� ������ ����
  * @param ip_table_id       - ������������� ������� ��� ����������
  * @param ip_message        - ���������
  * @param ip_err_code       - ��������� �� ������
  * @param ip_thread_id      - ������������� ������ ����������
  * @param ip_city_id        - ������������� ������
  * @param ip_reccount       - ���������� �������
  * @param ip_duration       - ����� ���������� (���.)
  * @param ip_date_start     - ���� ������
  * @param ip_date_end       - ���� ���������
  * @param ip_slog_slog_id   - ������������� ������������ ������ � ����
  * @return ������������� ����������� ������
  */
  FUNCTION insert_log_info(
    ip_table_id     IN INTEGER,
    ip_message      IN VARCHAR2 DEFAULT NULL,
    ip_err_code     IN VARCHAR2 DEFAULT NULL,
    ip_thread_id    IN INTEGER  DEFAULT NULL,
    ip_city_id      IN INTEGER  DEFAULT NULL,
    ip_reccount     IN INTEGER  DEFAULT NULL,
    ip_duration     IN NUMBER   DEFAULT NULL,
    ip_date_start   IN DATE DEFAULT SYSDATE,
    ip_date_end     IN DATE     DEFAULT NULL,
    ip_slog_slog_id IN INTEGER  DEFAULT NULL
  ) RETURN INTEGER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    lv_slog_id INTEGER := rias_mgr_log_info_seq.nextval;
  BEGIN
    INSERT /*+ append */ INTO RIAS_MGR_LOG_INFO(
      slog_id,
      table_id,
      message,
      err_code,
      thread_id,
      city_id,
      reccount,
      duration,
      date_start,
      date_end,
      slog_slog_id
    )
    VALUES(
      lv_slog_id,
      ip_table_id,
      ip_message,
      ip_err_code,
      ip_thread_id,
      ip_city_id,
      ip_reccount,
      ip_duration,
      ip_date_start,
      ip_date_end,
      ip_slog_slog_id
    );
    COMMIT;
    RETURN lv_slog_id;
  END insert_log_info;

  /**
  * Update ���������� ������ ����
  * ���������� �������
  * @param ip_slog_id        - ������������� ������ � ����
  * @param ip_message        - ���������
  * @param ip_err_code       - ��������� �� ������
  * @param ip_thread_id      - ������������� ������ ����������
  * @param ip_city_id        - ������������� ������
  * @param ip_reccount       - ���������� �������
  * @param ip_duration       - ����� ���������� (���.)
  * @param ip_date_end       - ���� ���������
  * @param ip_slog_slog_id   - ������������� ������������ ������ � ����
  */
  PROCEDURE i_update_log_info(
    ip_slog_id      IN INTEGER,
    ip_message      IN VARCHAR2 DEFAULT NULL,
    ip_err_code     IN VARCHAR2 DEFAULT NULL,
    ip_thread_id    IN INTEGER  DEFAULT NULL,
    ip_city_id      IN INTEGER  DEFAULT NULL,
    ip_reccount     IN INTEGER  DEFAULT NULL,
    ip_duration     IN NUMBER   DEFAULT NULL,
    ip_date_end     IN DATE     DEFAULT NULL,
    ip_slog_slog_id IN INTEGER  DEFAULT NULL
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    UPDATE /*+ append */ RIAS_MGR_LOG_INFO t SET
      t.message      = nvl(ip_message     ,t.message),
      t.err_code     = nvl(ip_err_code    ,t.err_code),
      t.thread_id    = nvl(ip_thread_id   ,t.thread_id),
      t.city_id      = nvl(ip_city_id     ,t.city_id),
      t.reccount     = nvl(ip_reccount    ,t.reccount),
      t.duration     = nvl(ip_duration    ,t.duration),
      t.date_end     = nvl(ip_date_end    ,t.date_end),
      t.slog_slog_id = nvl(ip_slog_slog_id,t.slog_slog_id)
    WHERE t.slog_id = ip_slog_id;
    COMMIT;
  END i_update_log_info;

  /**
  * Update ���������� ������ ����
  * @param ip_slog_id        - ������������� ������ � ����
  * @param ip_message        - ���������
  * @param ip_err_code       - ��������� �� ������
  * @param ip_thread_id      - ������������� ������ ����������
  * @param ip_city_id        - ������������� ������
  * @param ip_reccount       - ���������� �������
  * @param ip_duration       - ����� ���������� (���.)
  * @param ip_date_end       - ���� ���������
  * @param ip_slog_slog_id   - ������������� ������������ ������ � ����
  */
  PROCEDURE update_log_info(
    ip_slog_id      IN INTEGER,
    ip_message      IN VARCHAR2 DEFAULT NULL,
    ip_err_code     IN VARCHAR2 DEFAULT NULL,
    ip_thread_id    IN INTEGER  DEFAULT NULL,
    ip_city_id      IN INTEGER  DEFAULT NULL,
    ip_reccount     IN INTEGER  DEFAULT NULL,
    ip_duration     IN NUMBER   DEFAULT NULL,
    ip_date_end     IN DATE     DEFAULT NULL,
    ip_slog_slog_id IN INTEGER  DEFAULT NULL
  )
  IS
    lv_slog_id RIAS_MGR_LOG_INFO.slog_id%TYPE;
  BEGIN
    -- ���� ��������
/*
    -- �������� ���� ��������� ������?
    BEGIN
      SELECT t.slog_id
      INTO lv_slog_id
      FROM RIAS_MGR_LOG_INFO t
      WHERE t.slog_id = ip_slog_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN;
    END IF;
*/
    IF ip_slog_id IS NOT NULL THEN
      -- ������� ������
      i_update_log_info(
        ip_slog_id      => ip_slog_id,
        ip_message      => ip_message,
        ip_err_code     => ip_err_code,
        ip_thread_id    => ip_thread_id,
        ip_city_id      => ip_city_id,
        ip_reccount     => ip_reccount,
        ip_duration     => ip_duration,
        ip_date_end     => ip_date_end,
        ip_slog_slog_id => ip_slog_slog_id
      );
    END IF;
  END update_log_info;

  /**
  * ������� �� ���� ���������� ������ � � ������
  * @param ip_slog_id        - ������������� ������ � ����
  */
  PROCEDURE delete_log_info(ip_slog_id IN INTEGER)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    IF ip_slog_id IS NOT NULL THEN
      DELETE /*+ append */ FROM RIAS_MGR_LOG_INFO s
      WHERE s.slog_id IN (SELECT sl.slog_id
                          FROM RIAS_MGR_LOG_INFO sl
                          CONNECT BY sl.slog_slog_id = PRIOR sl.slog_id
                          START WITH sl.slog_id = ip_slog_id);
      COMMIT;
    END IF;
  END delete_log_info;

  /**
  * ���� ���������� �� ���������� DBG-����������
  * @param ip_table_id - ������������� ������� ��� ���������� DBG-����������
  */
  FUNCTION get_is_save_dbg(ip_table_id IN INTEGER) RETURN BOOLEAN
  IS
  BEGIN
    RETURN gv_is_dbg_info;
  END get_is_save_dbg;

  /**
  * ��������� DBG-����������
  */
  PROCEDURE save_dbg_info
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    FORALL i IN 1..gv_dbg_info_list.COUNT
      INSERT INTO /*+ append */ RIAS_MGR_DEBUG_INFO(DBG_ID, TABLE_ID, TBL_ROWID, IDB_ID, DBG_INFO)
      VALUES(gv_dbg_info_list(i).dbg_id,
             gv_dbg_info_list(i).table_id,
             gv_dbg_info_list(i).tbl_rowid,
             gv_dbg_info_list(i).idb_id,
             gv_dbg_info_list(i).dbg_info);
    COMMIT;
    gv_dbg_info_list.delete;
  END save_dbg_info;

  /**
  * ��������� DBG-����������
  * @param ip_table_id       - ������������� ������� ��� ���������� DBG-����������
  * @param ip_dbg_info       - DBG-����������
  * @param ip_idb_id         - IDB_ID ��� ������ �� �������� �������
  * @param ip_tbl_rowid      - ROWID ������ �� �������� �������
  */
  PROCEDURE insert_dbg_info(
    ip_table_id  IN INTEGER,
    ip_dbg_info  IN VARCHAR2,
    ip_idb_id    IN VARCHAR2 DEFAULT NULL,
    ip_tbl_rowid IN ROWID    DEFAULT NULL
  )
  IS
    --PRAGMA AUTONOMOUS_TRANSACTION;
    lv_dbg_id INTEGER := rias_mgr_debug_info_seq.nextval;
    lv_dbg_info_rec t_dbg_info_rec;
  BEGIN
    -- �������� ������� ���������
    IF (ip_table_id IS NULL) OR (ip_dbg_info) IS NULL THEN
      RETURN;
    END IF;
    -- �������� ���������� �� ���������� DBG-����������
    IF NOT get_is_save_dbg(ip_table_id) THEN
      RETURN;
    END IF;
    -- � "������"
    lv_dbg_info_rec.dbg_id   := lv_dbg_id;
    lv_dbg_info_rec.table_id := ip_table_id;
    lv_dbg_info_rec.tbl_rowid:= ip_tbl_rowid;
    lv_dbg_info_rec.dbg_info := ip_dbg_info;
    lv_dbg_info_rec.idb_id   := ip_idb_id;
    -- � ������
    gv_dbg_info_list(gv_dbg_info_list.COUNT + 1) := lv_dbg_info_rec;
    -- ���������� ����������, ������
    IF gv_dbg_info_list.COUNT >= 1000 THEN
      save_dbg_info;
    END IF;
/*
    INSERT INTO RIAS_MGR_DEBUG_INFO(DBG_ID, TABLE_ID, TBL_ROWID, IDB_ID, DBG_INFO)
    VALUES(lv_dbg_id, ip_table_id, ip_tbl_rowid, ip_idb_id, ip_dbg_info);
    COMMIT;
*/
  END insert_dbg_info;

  /**
  * ������� ������� � DBG-�������
  * @param ip_table_id  - ������������� ������� ��� ���������� DBG-����������
  */
  PROCEDURE clear_dbg_info(ip_table_id IN INTEGER)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- ����� ���������. ��-����� ���������� "TRUNCATE TABLE  " ������ ���������� COMMIT
    IF ip_table_id IS NULL THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE RIAS_MGR_DEBUG_INFO';
    ELSE
      DELETE /*+ append */ FROM RIAS_MGR_DEBUG_INFO t WHERE t.table_id = ip_table_id;
    END IF;
    COMMIT;
  END clear_dbg_info;

  /**
  * ������������� ������ ������ � DBG-����������
  * @param ip_table_id  - ������������� ������� ��� ���������� DBG-����������
  */
  PROCEDURE dbg_start(ip_table_id IN INTEGER)
  IS
  BEGIN
    -- �������� ���������� �� ���������� DBG-����������
    IF NOT get_is_save_dbg(ip_table_id) THEN
      RETURN;
    END IF;
    -- ������� �������
    clear_dbg_info(ip_table_id);
    -- ������� ������
    gv_dbg_info_list.delete;
    -- �������...
    gv_is_dbg_info := TRUE;
  END dbg_start;

  /**
  * ��������� ������ � DBG-����������
  */
  PROCEDURE dbg_stop
  IS
  BEGIN
    save_dbg_info;
    gv_is_dbg_info := FALSE;
  END dbg_stop;

  /**
  * ������ ���������� ������� ���������
  * @param ip_thread_cnt$i - ���������� ������� ����������
  */
  PROCEDURE set_thread_count(ip_thread_cnt$i IN PLS_INTEGER)
  IS
  BEGIN
    gv_thread_all := NVL(ip_thread_cnt$i, 1);
    gv_thread_all := LEAST(gv_thread_all, gv_thread_max);
  END set_thread_count;

  /**
  * �������� �������� ���������� ������� ����������
  */
  FUNCTION get_thread_count RETURN PLS_INTEGER
  IS
  BEGIN
    RETURN gv_thread_all;
  END get_thread_count;

  /**
  * �������� "������������" �������� ��� ������� ���������
  * ���� ��������� �������������...
  */
  FUNCTION get_thr_time_sleep(ip_table_id$i IN INTEGER) RETURN NUMBER
  IS
    lv_res$n NUMBER := gc_time_sleep;
  BEGIN
    FOR rec IN (
      SELECT MAX(duration) AS tmr
      FROM rias_mgr_log_info l
      WHERE 1 = 1
        AND table_id = ip_table_id$i
        AND l.message LIKE '����� ���������� ������%'
        -- ����� ������ ��� ���������������
        AND SUBSTR(l.message, LENGTH(l.message)-1, 5) > 1
    ) LOOP
      lv_res$n := nvl(rec.tmr, gc_time_sleep);
    END LOOP;
    -- ������ �������� �� ������, ��� gc_time_sleep � �� 0
    IF NOT (lv_res$n BETWEEN 1 AND gc_time_sleep) THEN
      lv_res$n := gc_time_sleep;
    END IF;
    --
    RETURN lv_res$n;
  END get_thr_time_sleep;

  /**
  * �������� ������ ������� ��� ������ ����������
  * @param ip_table_id$i   - ������������ ������� ��� ����������
  * @param ip_thread$i     - ����� ������ ����������
  * @param ip_thread_cnt$i - ����� ������� � ����������
  * @param ip_slog_id$i    - ������������ ���.������ � ����
  */
  FUNCTION get_cities_list(
    ip_table_id$i   IN PLS_INTEGER,
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  ) RETURN t_cities_list
  IS
    lv_mod_thread$i PLS_INTEGER := ip_thread$i - 1;
    lv_cities_list  t_cities_list;
    lv_slog_id      INTEGER;
  BEGIN
    /*
    ������������ ������ �����.
    �������� ���������� ��������� �������� �� �������
    */
    SELECT city_id
    BULK COLLECT INTO lv_cities_list
    FROM
    (
      SELECT ct.city_id, (CASE WHEN srt.rn IS NULL THEN ct.rn ELSE srt.rn END) AS rn
      FROM
        -- �������� ������ �������
        (
         SELECT city_id, row_number() OVER (ORDER BY city_id) as rn
         FROM (SELECT city_id
               FROM actual_cities
              ----- WHERE city_id not in (7234, 9326, 178, 447))
               WHERE city_id not in (7234, 9326, 178))  ----- 22.06.2021 �������� ����-���
        ) ct,
        -- ��������� � ������� �������
        (
         SELECT city_id, cnt, row_number() over (ORDER BY cnt DESC/*, city_id ASC*/) AS rn
         FROM (SELECT city_id, AVG(sl.reccount) AS cnt
               FROM rias_mgr_log_info sl
               WHERE 1 = 1
                 AND sl.city_id  IS NOT NULL
                 AND sl.reccount IS NOT NULL AND sl.reccount > 0
                 AND sl.message like '��������� ������%'
                 AND sl.table_id = ip_table_id$i
               GROUP BY city_id)
        ) srt
      WHERE ct.city_id = srt.city_id(+)
    )
    WHERE MOD(rn, ip_thread_cnt$i) = lv_mod_thread$i
    ORDER BY rn, city_id;

    --
    IF ip_slog_id$i IS NOT NULL THEN
      lv_slog_id := insert_log_info(ip_table_id => ip_table_id$i,
                                    ip_message => '����� ������� ��� ��������� � ������: '|| TO_CHAR(lv_cities_list.COUNT),
                                    ip_thread_id =>  TO_CHAR(ip_thread$i),
                                    ip_slog_slog_id => ip_slog_id$i);
    END IF;
    RETURN lv_cities_list;
  END get_cities_list;

  --============================================= ������������ �������
  /**
  * ��������, ��� ������ ��������� ���� ������
  * @param ip_saction - ������������ ������ ����������
  */
  PROCEDURE p_job_session(ip_job_name$c IN VARCHAR2, ip_thr_time_sleep$n NUMBER)
  IS
    lv_cnt$n PLS_INTEGER;
  BEGIN
    BEGIN
      --select 1 into lv_cnt$n from v$session v where v.ACTION = ip_job_name$c;
      SELECT 1
        INTO lv_cnt$n
        FROM user_scheduler_jobs
       WHERE job_name = ip_job_name$c
         AND state = 'RUNNING';
    EXCEPTION
      WHEN OTHERS THEN
        lv_cnt$n := 0;
    END;
    IF (lv_cnt$n > 0) THEN
      sys.dbms_lock.sleep(30/*ip_thr_time_sleep$n*/);
      -- ��������
      p_job_session(ip_job_name$c, ip_thr_time_sleep$n);
    END IF;
  END p_job_session;

  /**
  * ������� ����������� ���������� ������� ����������
  * @param ip_table_id$i        - ������������ ������� ��� ����������
  * @param ip_prefix_job_name#c - ������� ��� ����� ������
  * @param ip_slog_id#i         - ������������ ���.������ � ����
  */
  PROCEDURE p_create_job(
    ip_table_id$i        IN INTEGER,
    ip_prefix_job_name#c IN VARCHAR2,
    ip_slog_id#i         IN PLS_INTEGER DEFAULT NULL
  )
  IS
    lv_thread_cnt$i PLS_INTEGER := get_thread_count();
  BEGIN
    -- ������� ������ ����������
    FOR i IN 1..lv_thread_cnt$i LOOP
      sys.dbms_scheduler.create_job(job_name   => ip_prefix_job_name#c || TO_CHAR(i),
                                    job_type   => 'STORED_PROCEDURE',
                                    job_action => 'RIAS_MGR_CORE.FILL_TABLE_THREAD',
                                    number_of_arguments => 4,
                                    enabled => FALSE);
      sys.dbms_scheduler.set_job_argument_value(
        job_name => ip_prefix_job_name#c || TO_CHAR(i),
        argument_position => 1,
        argument_value => ip_table_id$i
      );
      sys.dbms_scheduler.set_job_argument_value(
        job_name => ip_prefix_job_name#c || TO_CHAR(i),
        argument_position => 2,
        argument_value => i
      );
      sys.dbms_scheduler.set_job_argument_value(
        job_name => ip_prefix_job_name#c || TO_CHAR(i),
        argument_position => 3,
        argument_value => lv_thread_cnt$i
      );
      sys.dbms_scheduler.set_job_argument_value(
        job_name => ip_prefix_job_name#c || TO_CHAR(i),
        argument_position => 4,
        argument_value => ip_slog_id#i
      );
    END LOOP;
  END p_create_job;

/*  PROCEDURE p_create_job(
    ip_job_action#c      IN VARCHAR2,
    ip_prefix_job_name#c IN VARCHAR2,
    ip_slog_id#i         IN PLS_INTEGER DEFAULT NULL
  )
  IS
    lv_thread_cnt$i PLS_INTEGER := get_thread_count();
  BEGIN
    FOR i IN 1..lv_thread_cnt$i LOOP
      sys.dbms_scheduler.create_job(job_name   => ip_prefix_job_name#c || TO_CHAR(i),
                                    job_type   => 'STORED_PROCEDURE',
                                    job_action => ip_job_action#c,
                                    number_of_arguments => 3,
                                    enabled => FALSE);
      sys.dbms_scheduler.set_job_argument_value(
        job_name => ip_prefix_job_name#c || TO_CHAR(i),
        argument_position => 1,
        argument_value => i
      );
      sys.dbms_scheduler.set_job_argument_value(
        job_name => ip_prefix_job_name#c || TO_CHAR(i),
        argument_position => 2,
        argument_value => lv_thread_cnt$i
      );
      sys.dbms_scheduler.set_job_argument_value(
        job_name => ip_prefix_job_name#c || TO_CHAR(i),
        argument_position => 3,
        argument_value => ip_slog_id#i
      );
      --sys.dbms_scheduler.enable(ip_prefix_job_name#c || TO_CHAR(i));
    END LOOP;
  END p_create_job;
*/
  /**
  * ������ ������� ����������
  * @param ip_prefix_job_name#c - ������� ��� ����� ������
  */
  PROCEDURE p_run_job(ip_prefix_job_name#c IN VARCHAR2)
  IS
    lv_thread_cnt$i PLS_INTEGER := get_thread_count();
  BEGIN
    FOR i IN 1 .. lv_thread_cnt$i LOOP
      dbms_scheduler.run_job(ip_prefix_job_name#c || TO_CHAR(i), FALSE);
    END LOOP;
  END;

  /**
  * ����������� ������� ����������
  * @param ip_prefix_job_name#c - ������� ��� ����� ������
  */
  PROCEDURE p_drop_job(ip_prefix_job_name#c IN VARCHAR2)
  IS
    lv_thread_cnt$i PLS_INTEGER := get_thread_count();
  BEGIN
    FOR i IN 1..lv_thread_cnt$i LOOP
      BEGIN
        dbms_scheduler.drop_job(ip_prefix_job_name#c || TO_CHAR(i), TRUE);
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END LOOP;
  END;

  /**
  * ������������ ������ ��� �������� �������
  * ������������� ���������
  * ���������� � ���������� ������
  * @param ip_table_id$i   - ������������ ������� ��� ����������
  * @param ip_thread$i     - ����� ������ ����������
  * @param ip_thread_cnt$i - ����� ������� � ����������
  * @param ip_slog_id$i    - ������������ ���.������ � ����
  */
  PROCEDURE fill_table_thread(
    ip_table_id$i   IN INTEGER,
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  )
  IS
    --
    lv_job_action#c VARCHAR2(200);
    -- �����������
    lv_main_slog_id INTEGER;
    lv_slog_id      INTEGER;
    lv_rec_cnt$i    PLS_INTEGER;
    -- ��� ����������� ������� ����������
    lv_time_start   NUMBER;
  BEGIN
    -- ��������� ����� ������
    lv_time_start := dbms_utility.get_time;
    lv_main_slog_id := insert_log_info(ip_table_id => ip_table_id$i,
                                       ip_message => '����� ���������� ������ ' || TO_CHAR(ip_thread$i) || ' �� ' || TO_CHAR(ip_thread_cnt$i),
                                       ip_thread_id =>  ip_thread$i,
                                       ip_slog_slog_id => ip_slog_id$i);
    -- ��� ������� �������� ��� � ������������� ���������
    lv_job_action#c := RIAS_MGR_CONST.get_proc_name(ip_table_id$i => ip_table_id$i);
    IF lv_job_action#c IS NOT NULL THEN
      -- ������ ��������� ������������
      EXECUTE IMMEDIATE
        'BEGIN' || chr(13) ||
           lv_job_action#c ||'(ip_thread$i     => :ip_thread$i,'     ||chr(13)||
        '                      ip_thread_cnt$i => :ip_thread_cnt$i,' ||chr(13)||
        '                      ip_slog_id$i    => :lv_main_slog_id);'||chr(13)||
        'END;'
      USING ip_thread$i, ip_thread_cnt$i, lv_main_slog_id;
    END IF;
    -- �������� ����� ������
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_main_slog_id;
    --
    update_log_info(ip_slog_id => lv_main_slog_id,
                    ip_reccount => lv_rec_cnt$i,
                    ip_duration => rias_mgr_support.get_elapsed_time(lv_time_start, dbms_utility.get_time),
                    ip_date_end => rias_mgr_support.get_current_date);
  EXCEPTION
    WHEN OTHERS THEN
      -- �������� ���������� �� ������
      lv_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => ip_table_id$i,
                                                      ip_message => SUBSTR('Error IN thread � '||to_char(ip_thread$i) || ' of ' || to_char(ip_thread_cnt$i)  || chr(13) ||
                                                                           'error_stack: '||dbms_utility.format_error_stack || dbms_utility.format_error_backtrace
                                                                           , 1, 2000),
                                                      ip_err_code => SUBSTR('SQLCODE = ' || TO_CHAR(SQLCODE) ||' SQLERRM = ' || SQLERRM, 1, 200),
                                                      ip_thread_id => ip_thread$i,
                                                      ip_slog_slog_id => lv_main_slog_id);
  END fill_table_thread;

  /**
  * ������ �������� ������������
  * @param ip_table_id$i - ������������ ������� ��� ����������
  */
  PROCEDURE start_threads(ip_table_id$i IN INTEGER)
  IS
    lv_thread_cnt$i PLS_INTEGER := get_thread_count();
    lv_slog_id      INTEGER;
    lv_rec_cnt$i    PLS_INTEGER;
    lv_table_name$c VARCHAR2(50);
    lv_prefix_job_name#c VARCHAR2(50);
    lv_time_start    NUMBER;
    lv_thr_time_sleep$n NUMBER;
  BEGIN
    -- ��������� ����� ������
    lv_time_start := dbms_utility.get_time;
    --
    lv_table_name$c := RIAS_MGR_CONST.get_table_name(ip_table_id$i);
    lv_prefix_job_name#c := REPLACE(gc_maket_prefix_job_name, '#TABLENAME#', lv_table_name$c);
    -- �������� ������ ����
    lv_slog_id := insert_log_info(ip_table_id => ip_table_id$i,
                                  ip_message => '����� ��������� �������� �������� ��� ������� ' || lv_table_name$c);
    -- �������� ����-��� �������� ��������� ������ ������
    lv_thr_time_sleep$n := get_thr_time_sleep(ip_table_id$i);
    -- ���� ������ �������� ���� �����, �� � �� ����� ��������� �������� ������
    IF lv_thread_cnt$i = 1 THEN
      FILL_TABLE_THREAD(ip_table_id$i   => ip_table_id$i,
                        ip_thread$i     => 1,
                        ip_thread_cnt$i => 1,
                        ip_slog_id$i    => lv_slog_id);
    -- ���� ������ �������� ����� ������ ������
    ELSIF lv_thread_cnt$i > 1 THEN
      -- ������� ������ ����������
      p_create_job(
        ip_table_id$i        => ip_table_id$i,
        ip_prefix_job_name#c => lv_prefix_job_name#c,
        ip_slog_id#i         => lv_slog_id
      );
      -- ������ ������� ����������
      p_run_job(lv_prefix_job_name#c);
      -- ������
      sys.dbms_lock.sleep(lv_thr_time_sleep$n);
      -- �������� ��������� �� ������ ������
      FOR i IN 1 .. lv_thread_cnt$i LOOP
        p_job_session(lv_prefix_job_name#c || TO_CHAR(i), lv_thr_time_sleep$n);
      END LOOP;
      -- ��������� ������ ����������
      p_drop_job(lv_prefix_job_name#c);
    END IF;

    -- ������� ��� ��� �������� ������
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_slog_id;
    -- ������� ������ ����
    update_log_info(ip_slog_id => lv_slog_id,
                    ip_reccount => lv_rec_cnt$i,
                    ip_duration => rias_mgr_support.get_elapsed_time(lv_time_start, dbms_utility.get_time),
                    ip_date_end => sysdate);
  END start_threads;

/*
  PROCEDURE start_threads(ip_table_id$i IN INTEGER)
  IS
    lv_thread_cnt$i PLS_INTEGER := get_thread_count();
    lv_slog_id      INTEGER;
    lv_rec_cnt$i    PLS_INTEGER;
    lv_table_name$c VARCHAR2(50);
    lv_prefix_job_name#c VARCHAR2(50);
    lv_job_action#c VARCHAR2(200);
    lv_time_start    NUMBER;
    lv_thr_time_sleep$n NUMBER;
  BEGIN
    -- ��������� ����� ������
    lv_time_start := dbms_utility.get_time;
    --
    lv_table_name$c := RIAS_MGR_CONST.get_table_name(ip_table_id$i);
    lv_prefix_job_name#c := REPLACE(gc_maket_prefix_job_name, '#TABLENAME#', lv_table_name$c);
    lv_job_action#c := CASE
                         WHEN ip_table_id$i = rias_mgr_const.gc_tbpi_int     THEN 'RIAS_MGR_INTERNET.FILL_TBPI_THREAD'
                         WHEN ip_table_id$i = rias_mgr_const.gc_sbpi_int     THEN 'RIAS_MGR_INTERNET.FILL_SBPI_THREAD'
                         WHEN ip_table_id$i = rias_mgr_const.gc_subscription THEN 'RIAS_MGR_INTERNET.FILL_SUBSCRIPTION_THREAD'
                       END;
    -- ���� �� ������ ��������� ���������, �� �������
    IF lv_job_action#c IS NULL THEN
      RETURN;
    END IF;
    -- �������� ������ ����
    lv_slog_id := insert_log_info(ip_table_id => ip_table_id$i,
                                  ip_message => '����� ��������� �������� �������� ��� ������� ' || lv_table_name$c);
    -- �������� ����-��� �������� ��������� ������ ������
    lv_thr_time_sleep$n := get_thr_time_sleep(ip_table_id$i);
    -- ���� ������ �������� ���� �����, �� � �� ����� ��������� �������� ������
    IF lv_thread_cnt$i = 1 THEN
      -- TBPI
      IF ip_table_id$i = rias_mgr_const.gc_tbpi_int THEN
        RIAS_MGR_INTERNET.FILL_TBPI_THREAD(ip_thread$i => 1,ip_thread_cnt$i => 1,ip_slog_id$i => lv_slog_id);
      -- SBPI
      ELSIF ip_table_id$i = rias_mgr_const.gc_sbpi_int THEN
        RIAS_MGR_INTERNET.FILL_SBPI_THREAD(ip_thread$i => 1,ip_thread_cnt$i => 1,ip_slog_id$i => lv_slog_id);
      -- SUBSCRIPTION
      ELSIF ip_table_id$i = rias_mgr_const.gc_subscription THEN
        RIAS_MGR_INTERNET.FILL_SUBSCRIPTION_THREAD(ip_thread$i => 1,ip_thread_cnt$i => 1,ip_slog_id$i => lv_slog_id);
      END IF;

    -- ���� ������ �������� ����� ������ ������
    ELSIF lv_thread_cnt$i > 1 THEN
      -- ������� ������ ����������
      p_create_job(
        ip_job_action#c      => lv_job_action#c,
        ip_prefix_job_name#c => lv_prefix_job_name#c,
        ip_slog_id#i         => lv_slog_id
      );
      -- ������ ������� ����������
      p_run_job(lv_prefix_job_name#c);
      -- ������
      sys.dbms_lock.sleep(lv_thr_time_sleep$n);
      -- �������� ��������� �� ������ ������
      FOR i IN 1 .. lv_thread_cnt$i LOOP
        p_job_session(lv_prefix_job_name#c || TO_CHAR(i), lv_thr_time_sleep$n);
      END LOOP;
      -- ��������� ������ ����������
      p_drop_job(lv_prefix_job_name#c);
    END IF;

    -- ������� ��� ��� �������� ������
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_slog_id;
    -- ������� ������ ����
    update_log_info(ip_slog_id => lv_slog_id,
                    ip_reccount => lv_rec_cnt$i,
                    ip_duration => rias_mgr_support.get_elapsed_time(lv_time_start, dbms_utility.get_time),
                    ip_date_end => sysdate);
  END start_threads;
*/
/*
  \**
  * ��������� �������� ip_prefix
  * ��������� ������� ����� � ���������� ���� ��������� 'STOP'
  * %param ip_prefix - ������� ��������
  *\
  PROCEDURE i_request_stop(ip_prefix IN VARCHAR2)
  IS
    lv_res_create_pipe  INTEGER;
    lv_res_send_message INTEGER;
    lv_message          VARCHAR2(100);
    lv_name_canal       VARCHAR2(128);
    lv_schema           VARCHAR2(30) := sys_context('USERENV', 'CURRENT_SCHEMA');
  BEGIN
    lv_name_canal := UPPER(ip_prefix);
    lv_message    := lv_schema || ': STOP ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss');
    -- ������� �����
    lv_res_create_pipe := dbms_pipe.create_pipe(pipename    => lv_name_canal,
                                                maxpipesize => 8192,
                                                private     => FALSE);
    -- ��������� ���������
    IF lv_res_create_pipe = 0 THEN
      -- ������� �����, ���� ����� �� ��� ���������� � � ��� ���� ���������
      dbms_pipe.purge(pipename => lv_name_canal);
      -- ����������� ������
      dbms_pipe.pack_message(lv_message);
      -- �������� ������
      lv_res_send_message := dbms_pipe.send_message(pipename => lv_name_canal, timeout  => 0);
      -- ��������� ���������
\*
      IF lv_res_send_message = 0 THEN
        RETURN;
      ELSE
        aim_utils.raise_error(ip_error_id => 0,
                              ip_appl_id => gc_appl_id,
                              ip_message => 'Error sending message.');
      END IF;
    ELSE
      aim_utils.raise_error(ip_error_id => 0,
                            ip_appl_id => gc_appl_id,
                            ip_message => 'Error creation of canal.' || lv_name_canal);
*\
    END IF;
  END i_request_stop;

  \**
  * ������������ �������� �� ��������� �������� �������� ��� �������� �������
  * @param ip_table_id$i - ������������ �������
  *\
  PROCEDURE request_stop(ip_table_id$i IN INTEGER)
  IS
    lv_prefix      t_prefix;
    lv_check_while BOOLEAN := TRUE;
  BEGIN
    -- �������� ������� ��������
    lv_prefix := rias_mgr_const.get_process_prefix(ip_table_id$i);
    -- ������� �����, ���� ����� �� ��� ���������� � � ��� ���� ���������
    BEGIN
      dbms_pipe.purge(pipename => UPPER(lv_prefix));
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- ������� ������ �������������, ������� ��� � �������� "STOP"
    -- ���������� ������ ��������������� ����� ��������� �������
    WHILE lv_check_while
    LOOP
      lv_check_while := FALSE;
      FOR i IN (SELECT \*+ FIRST_ROWS(1) *\ NULL
                FROM sys.v_$session s
                WHERE s.module LIKE lv_prefix || '%'
                  AND s.status = 'ACTIVE')
      LOOP
        i_request_stop(ip_prefix => lv_prefix);
        dbms_lock.sleep(2);
        lv_check_while := TRUE;
        EXIT;
      END LOOP;
    END LOOP;
  END request_stop;
*/

  /**
  * �������� �������� �����
  * @param ip_ftrtgl_id$i - ������������� ������
  * @return �������� �����
  */
  FUNCTION get_feature_toggle(ip_ftrtgl_id$i IN INTEGER) RETURN INTEGER
  IS
    lv_res$i INTEGER;
  BEGIN
    SELECT t.swtch_value
    INTO lv_res$i
    FROM rias_mgr_feature_toggle t
    WHERE t.ftrtgl_id = ip_ftrtgl_id$i;
    RETURN lv_res$i;
  END get_feature_toggle;

  /**
  * �������� �������� �����
  * @param ip_tsk_num$c - ����� ������
  * @return �������� �����
  */
  FUNCTION get_feature_toggle(ip_tsk_num$c IN VARCHAR2) RETURN INTEGER
  IS
    lv_res$i INTEGER;
  BEGIN
    SELECT t.swtch_value
    INTO lv_res$i
    FROM rias_mgr_feature_toggle t
    WHERE t.tsk_num = ip_tsk_num$c;
    RETURN lv_res$i;
  END get_feature_toggle;

BEGIN
  init_package;
END RIAS_MGR_CORE;
/

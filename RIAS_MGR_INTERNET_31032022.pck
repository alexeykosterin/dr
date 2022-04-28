CREATE OR REPLACE PACKAGE IDB_PROD.RIAS_MGR_INTERNET
/**
* Пакет обслуживания миграции Продукта "Интернет"
* Версия 001.00
*
* 25.12.2019 Бикулов М.Д. Создание
*
*/
AS
  /**
  * Проверка: является ли пакет валидным
  */
  PROCEDURE package_is_valid;

  /**
  * Задать количество потоков обработки
  * @param ip_thread_cnt$i - Количество потоков исполнения
  */
  PROCEDURE set_thread_count(ip_thread_cnt$i IN PLS_INTEGER);

  /**
  * Формирование данных
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  PROCEDURE fill_tbpi_thread(
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  );

  /**
  * Формирование данных для SBPI
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  PROCEDURE fill_sbpi_thread(
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  );

  /**
  * Формирование данных для SUBSCRIPTION
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  PROCEDURE fill_subscription_thread(
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  );

  /**
  * Запуск механизма многопоточности для заполнения TBPI
  */
  PROCEDURE fill_tbpi;

  /**
  * Запуск механизма многопоточности для заполнения SBPI
  */
  PROCEDURE fill_sbpi;

  /**
  * Запуск механизма многопоточности для заполнения SUBSCRIPTION
  */
  PROCEDURE fill_subscription;

  /**
  * Запуск механизма многопоточности для заполнения CUSTOMER_MANY_ALL
  */
  PROCEDURE fill_customers;

  /**
  * Удалить один из двух активных SLO бонус увеличение скорости
  */
  PROCEDURE del_slo_dbl_speed_bonus;

  /**
  * Заполнить приостановки
  */
  PROCEDURE fill_suspended;

  /**
  * Удалить рабочие данные из таблицы RIAS_MGR_TMP_LIST
  */
  PROCEDURE clear_tmp_data(ip_task_id IN PLS_INTEGER);

  /**
  * Заполнить IDB_PH2_BPI_MRC_PRICEOVERRIDE
  */
  PROCEDURE fill_priceoverride;

  /**
  * Очистить данные для обработки IDB_PH2_ACCESS_CRED
  */
  PROCEDURE clear_access_cred;
  
  /*
  */
   function inser_work_data_test return pls_integer;

  /**
  * Заполнить таблицу IDB_PH2_ACCESS_CRED
  *   1. Очистить
  *   2. Очистить ссылки на AC из таблиц IDB_PH2_TBPI_INT и IDB_PH2_SBPI_INT
  *   2. Заполнить
  */
  PROCEDURE fill_access_cred;

  /**
  * Заполнение IDB_PH2_ACCESS_CRED для SkyDNS
  */
  PROCEDURE fill_access_cred_skydns;

  /**
  * Заполнить таблицу IDB_PH2_NET_ACCESS
  *   1. Очистить
  *   2. Заполнить
  */
  PROCEDURE fill_net_access;

  /**
  * Заполнить таблицу IDB_PH2_SBPI_INT
  *   OFF_ID_FOR_MIGR = '121000093'
  */
  PROCEDURE fill_idb_ph2_sbpi_121000093;

  /**
  *
  */
  FUNCTION get_source_id_seq RETURN NUMBER;
  PRAGMA RESTRICT_REFERENCES (get_source_id_seq, WNDS, WNPS, RNPS);

  /**
  * Заполнение таблицы IDB_PH2_NE_SERVICE_ID_P
  */
  PROCEDURE fill_idb_ph2_ne_service_id_p;

  /**
  * Не учтена АП за белые ip в Иркутске в IDB
  * https://jsd.netcracker.com/browse/ERT-20421
  */
  PROCEDURE upd_903_121000087;

  /**
  * Перекинуть "белые" IP из TLO в SLO (с созданием новых)
  */
  PROCEDURE upd_903_121000087_tlo_white;

  /**
  * Обновить ссылки в таблицах IDB_PH2_ACCESS_CRED и IDB_PH2_NET_ACCESS
  * вновь созданных SLO из TLO для "былых" доп.IP
  * Иркутск
  */
  PROCEDURE upd_903_121000087_na_ac;

  /**
  * Заполнение таблицы IDB_PH2_CUSTOMER_USERS
  * Подписчики клиента
  *
  * @param ip_phase - Фаза миграции
  */
  PROCEDURE fill_customer_users(ip_phase IN PLS_INTEGER DEFAULT 2);

  /**
  * Обновление поля IS_ACCOUNT_IN_SSO таблицы IDB_PH2_CUSTOMER
  * Признак наличия учетной записи абонента в системе самообслуживания
  *
  * @param ip_phase - Фаза миграции
  */
  PROCEDURE upd_customer_is_account_in_sso(ip_phase IN PLS_INTEGER DEFAULT 2);

  /**
  * Заполнение таблицы IDB_PH2_GENERIC_CPE
  * Данные об устройствах, сохраняемые как ресурсы
  */
  PROCEDURE fill_generic_cpe;

  /**
  * Заполнение таблицы IDB_PH2_GCPE_SERVICE_ID_P
  * Параметрическая таблица для задания множественного значения Service ID  для Generic CPE
  */
  PROCEDURE fill_gcpe_service_id_p;

  /**
  * Создание SLO 'Оборудование "Роутер"'
  */
  PROCEDURE fill_idb_ph2_sbpi_303000018;

  /**
  * Создание SLO 'Ответственное хранение Роутера'
  */
  PROCEDURE fill_idb_ph2_sbpi_111000248;
  procedure sbpi_update_for_networks;
END RIAS_MGR_INTERNET;
/
CREATE OR REPLACE PACKAGE BODY IDB_PROD.RIAS_MGR_INTERNET
/**
*
*/
AS
  phase_id$i CONSTANT PLS_INTEGER := trash_from_odi.getPhase;
  type t_TRANSFER_WAY is table of rowid;
  v_TRANSFER_WAY  t_TRANSFER_WAY;
  cursor c_TRANSFER_WAY is select rowid as row_id from idb_prod.IDB_PH2_SBPI_INT where PHASE = phase_id$i AND OFF_ID_FOR_MIGR=303000018 and TRANSFER_WAY = 'Рассрочка';
  TYPE t_MRC IS TABLE OF ROWID;
  v_MRC t_MRC;
  CURSOR c_MRC IS SELECT tab.rowid AS row_id FROM IDB_PH2_SBPI_INT tab JOIN IDB_PH2_OFFERINGS_DIC dic ON (dic.OFF_ID_FOR_MIGR = tab.OFF_ID_FOR_MIGR AND
  dic.IDB_TABLE_NAME = 'IDB_PH2_SBPI_INT' AND dic.TAX_SET_ID = '2') LEFT JOIN IDB_PH2_OFF_NOCHARGE_DIC noch
    ON     (noch.FLAT_OFFERING_ID = dic.FLAT_OFFERING_ID AND noch.NO_CHARGE = 1 AND noch.PRICE_SPEC_NAME = 'Monthly Fee' AND
           (dic.OFF_TYPE != 'Equipment Offering' OR
           (dic.OFF_TYPE = 'Equipment Offering' AND
           noch.SALE_TYPE_NAME = tab.TRANSFER_WAY)))
    WHERE  1 = 1 AND tab.PHASE = phase_id$i AND tab.IS_BASED_MRC IS NULL
    AND EXISTS (SELECT 1
            FROM   IDB_PH2_OFF_NOCHARGE_DIC act
            WHERE  1 = 1
            AND    act.FLAT_OFFERING_ID = dic.FLAT_OFFERING_ID
            AND    act.PRICE_SPEC_NAME = 'Monthly Fee'
            AND    (dic.OFF_TYPE != 'Equipment Offering' OR
                  (dic.OFF_TYPE = 'Equipment Offering' AND
                  act.SALE_TYPE_NAME = tab.TRANSFER_WAY)))
    AND    noch.rowid IS NULL
    AND    ROUND(nvl(tab.MRC, 0) / 600000, 2) <> nvl(tab.TAX_MRC, 0) / 100000;


 /**
  * Проверка: является ли пакет валидным
  */
  PROCEDURE package_is_valid
  IS
  BEGIN
    NULL;
  END package_is_valid;

  /**
  * Задать количество потоков обработки
  * @param ip_thread_cnt$i - Количество потоков исполнения
  */
  PROCEDURE set_thread_count(ip_thread_cnt$i IN PLS_INTEGER)
  IS
  BEGIN
    rias_mgr_core.set_thread_count(ip_thread_cnt$i => ip_thread_cnt$i);
  END set_thread_count;

  /**
  * Формирование данных для TBPI
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  PROCEDURE fill_tbpi_thread(
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  )
  IS
    -- Константы
    lc_table_id$i CONSTANT INTEGER := rias_mgr_const.gc_tbpi_int;
    -- Логирование
    lv_main_slog_id INTEGER;
    lv_slog_id      INTEGER;
    lv_rec_cnt$i    PLS_INTEGER;
    -- Для определения времени исполнения
    lv_main_time_start NUMBER;
    lv_time_start      NUMBER;
  BEGIN
    -- Фиксируем время старта
    lv_main_time_start := dbms_utility.get_time;
    lv_main_slog_id := rias_mgr_core.insert_log_info(ip_table_id => lc_table_id$i,
                                                     -- Править 'Старт исполнения потока..' осторожно используется для поиска (ищем в пакете RIAS_MGR_CORE)
                                                     ip_message => 'Старт исполнения потока ' || TO_CHAR(ip_thread$i) || ' из ' || TO_CHAR(ip_thread_cnt$i),
                                                     ip_thread_id =>  TO_CHAR(ip_thread$i),
                                                     ip_slog_slog_id => ip_slog_id$i);
    -- Запуск процедуры формирования
    EXECUTE IMMEDIATE
    'BEGIN' || chr(13) ||
    '  RIAS_FILL_TBPI_PROC(ip_thread$i     => :ip_thread$i,'     ||chr(13)||
    '                      ip_thread_cnt$i => :ip_thread_cnt$i,' ||chr(13)||
    '                      ip_slog_id$i    => :lv_main_slog_id);'||chr(13)||
    'END;'
    USING ip_thread$i, ip_thread_cnt$i, lv_main_slog_id;

    -- Подведем итоги работы
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_main_slog_id;
    --
    rias_mgr_core.update_log_info(ip_slog_id => lv_main_slog_id,
                                  ip_reccount => lv_rec_cnt$i,
                                  ip_duration => rias_mgr_support.get_elapsed_time(lv_main_time_start, dbms_utility.get_time),
                                  ip_date_end => CURRENT_DATE);
  END fill_tbpi_thread;

  /**
  * Формирование данных для SBPI
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  PROCEDURE fill_sbpi_thread(
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  )
  IS
    -- Константы
    lc_table_id$i CONSTANT INTEGER := rias_mgr_const.gc_sbpi_int;
    -- Логирование
    lv_main_slog_id INTEGER;
    lv_slog_id      INTEGER;
    lv_rec_cnt$i    PLS_INTEGER;
    -- Для определения времени исполнения
    lv_main_time_start NUMBER;
    lv_time_start      NUMBER;
  BEGIN
    -- Фиксируем время старта
    lv_main_time_start := dbms_utility.get_time;
    lv_main_slog_id := rias_mgr_core.insert_log_info(ip_table_id => lc_table_id$i,
                                                     -- Править 'Старт исполнения потока..' осторожно используется для поиска (ищем в пакете rias_mgr_core)
                                                     ip_message => 'Старт исполнения потока ' || TO_CHAR(ip_thread$i) || ' из ' || TO_CHAR(ip_thread_cnt$i),
                                                     ip_thread_id =>  TO_CHAR(ip_thread$i),
                                                     ip_slog_slog_id => ip_slog_id$i);
    -- Запуск процедуры формирования
    EXECUTE IMMEDIATE
    'BEGIN' || chr(13) ||
    '  RIAS_FILL_SBPI_PROC(ip_thread$i     => :ip_thread$i,'     ||chr(13)||
    '                      ip_thread_cnt$i => :ip_thread_cnt$i,' ||chr(13)||
    '                      ip_slog_id$i    => :lv_main_slog_id);'||chr(13)||
    'END;'
    USING ip_thread$i, ip_thread_cnt$i, lv_main_slog_id;
/*
    RIAS_FILL_SBPI_PROC(ip_thread$i     => ip_thread$i,
                        ip_thread_cnt$i => ip_thread_cnt$i,
                        ip_slog_id$i    => lv_main_slog_id);
*/
    -- Подведем итоги работы
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_main_slog_id;
    --
    rias_mgr_core.update_log_info(ip_slog_id => lv_main_slog_id,
                                  ip_reccount => lv_rec_cnt$i,
                                  ip_duration => rias_mgr_support.get_elapsed_time(lv_main_time_start, dbms_utility.get_time),
                                  ip_date_end => CURRENT_DATE);
  END fill_sbpi_thread;

  /**
  * Формирование данных для SUBSCRIPTION
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  PROCEDURE fill_subscription_thread(
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  )
  IS
    -- Константы
    lc_table_id$i CONSTANT INTEGER := rias_mgr_const.gc_subscription;
    -- Логирование
    lv_main_slog_id INTEGER;
    lv_slog_id      INTEGER;
    lv_rec_cnt$i    PLS_INTEGER;
    -- Для определения времени исполнения
    lv_main_time_start NUMBER;
    lv_time_start      NUMBER;
  BEGIN
    -- Фиксируем время старта
    lv_main_time_start := dbms_utility.get_time;
    lv_main_slog_id := rias_mgr_core.insert_log_info(ip_table_id => lc_table_id$i,
                                                     -- Править 'Старт исполнения потока..' осторожно используется для поиска (ищем в пакете rias_mgr_core)
                                                     ip_message => 'Старт исполнения потока ' || TO_CHAR(ip_thread$i) || ' из ' || TO_CHAR(ip_thread_cnt$i),
                                                     ip_thread_id =>  TO_CHAR(ip_thread$i),
                                                     ip_slog_slog_id => ip_slog_id$i);
    -- Запуск процедуры формирования
    EXECUTE IMMEDIATE
    'BEGIN' || chr(13) ||
    '  RIAS_FILL_SUBSCRIPTION_PROC(ip_thread$i     => :ip_thread$i,'     ||chr(13)||
    '                              ip_thread_cnt$i => :ip_thread_cnt$i,' ||chr(13)||
    '                              ip_slog_id$i    => :lv_main_slog_id);'||chr(13)||
    'END;'
    USING ip_thread$i, ip_thread_cnt$i, lv_main_slog_id;
/*
    RIAS_FILL_SUBSCRIPTION_PROC(ip_thread$i     => ip_thread$i,
                                ip_thread_cnt$i => ip_thread_cnt$i,
                                ip_slog_id$i    => lv_main_slog_id);
*/
    -- Подведем итоги работы
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_main_slog_id;
    --
    rias_mgr_core.update_log_info(ip_slog_id => lv_main_slog_id,
                                  ip_reccount => lv_rec_cnt$i,
                                  ip_duration => rias_mgr_support.get_elapsed_time(lv_main_time_start, dbms_utility.get_time),
                                   ip_date_end => CURRENT_DATE);
  END fill_subscription_thread;

  /**
  * Запуск механизма многопоточности для TBPI
  */
  PROCEDURE fill_tbpi
  IS
  BEGIN
    -- Запустим формирование данных для TBPI
    RIAS_MGR_CORE.start_threads(ip_table_id$i => rias_mgr_const.gc_tbpi_int);
  END fill_tbpi;

  /**
  * Запуск механизма многопоточности для заполнения SBPI
  */
  PROCEDURE fill_sbpi
  IS
  BEGIN
    -- Запустим формирование данных для SBPI
    RIAS_MGR_CORE.start_threads(ip_table_id$i => rias_mgr_const.gc_sbpi_int);
  END fill_sbpi;

  /**
  * Запуск механизма многопоточности для заполнения SUBSCRIPTION
  */
  PROCEDURE fill_subscription
  IS
  BEGIN
    -- Запустим формирование данных для subscription
    RIAS_MGR_CORE.start_threads(ip_table_id$i => rias_mgr_const.gc_subscription);
  END fill_subscription;

  /**
  * Запуск механизма многопоточности для заполнения CUSTOMER_MANY_ALL
  */
  PROCEDURE fill_customers
  IS
  BEGIN
    NULL;
    -- Запустим формирование данных для customer_many_all
    -- RIAS_MGR_CORE.start_threads(ip_table_id$i => rias_mgr_const.gc_customer_many_all);
  END fill_customers;

  /**
  * Удалить один из двух активных SLO бонус увеличение скорости
  */
  PROCEDURE del_slo_dbl_speed_bonus
  IS
    TYPE t_slo_rec IS RECORD(
      parent_id VARCHAR2(150),
      off_off_id_for_migr VARCHAR2(150)
    );
    TYPE t_slo_arr IS TABLE OF t_slo_rec INDEX BY PLS_INTEGER;
    lv_slo_arr$arr t_slo_arr;
    lv_off_off_id_for_migr$c VARCHAR2(150);
    lv_rec_num$i PLS_INTEGER;
    lv_access_speed NUMBER;
    lv_curr_date$d DATE := rias_mgr_support.get_current_date();
  BEGIN
    FOR rec IN (
      -- 619
      WITH tbl AS (
      SELECT t.idb_id, t.phase
      FROM idb_ph2_tbpi_int t,
           idb_ph2_sbpi_int s
      WHERE 1 = 1
      and t.phase = phase_id$i
        AND t.idb_id LIKE 'TI_1/%'
        AND s.parent_id = t.idb_id
        AND s.actual_start_date <= lv_curr_date$d
        AND (s.actual_end_date IS NULL OR s.actual_end_date > lv_curr_date$d)
        AND s.off_id_for_migr = '121000111'
      UNION ALL
      SELECT t.idb_id, t.phase
      FROM idb_ph2_tbpi_int t,
           idb_ph2_sbpi_int s
      WHERE 1 = 1
      and t.phase = phase_id$i
        AND t.idb_id LIKE 'TI_1/%'
        AND s.parent_id = t.idb_id
        AND s.actual_start_date <= lv_curr_date$d
        AND (s.actual_end_date IS NULL OR s.actual_end_date > lv_curr_date$d)
        AND s.off_id_for_migr = '121000080'
      UNION ALL
      SELECT t.idb_id, t.phase
      FROM idb_ph2_tbpi_int t,
           idb_ph2_sbpi_int s
      WHERE 1 = 1
      and t.phase = phase_id$i
        AND t.idb_id LIKE 'TI_1/%'
        AND s.parent_id = t.idb_id
        AND s.actual_start_date <= lv_curr_date$d
        AND (s.actual_end_date IS NULL OR s.actual_end_date > lv_curr_date$d)
        AND s.off_id_for_migr = '121000117'
      )
      SELECT idb_id,
             sum(nvl(s_access_speed_local_up,0)) as sm_121000111,
             sum(nvl(s_up_to,0)) as sm_121000080,
             sum(nvl(s_up_on, 0)) as sm_121000117
             --sum(nvl(t_access_speed,0) + nvl(s_up_on, 0)) as sm_121000117
      FROM(
        SELECT t.idb_id, --t.access_speed, s.idb_id as s_idb_id, s.actual_start_date, s.actual_start_date, s.off_id_for_migr, s.access_speed_local_up, s.up_to, s.up_on
             --(CASE WHEN t.access_speed IS NULL THEN NULL ELSE TO_NUMBER(REGEXP_REPLACE(t.access_speed, '[^[[:digit:]]]*')) END) as t_access_speed,
             (CASE WHEN s.access_speed_local_up IS NULL THEN NULL ELSE  TO_NUMBER(REGEXP_REPLACE(s.access_speed_local_up, '[^[[:digit:]]]*')) END) as s_access_speed_local_up,
             (CASE WHEN s.up_to IS NULL THEN NULL ELSE  TO_NUMBER(REGEXP_REPLACE(s.up_to, '[^[[:digit:]]]*')) END) as s_up_to,
             (CASE WHEN s.up_on IS NULL THEN NULL ELSE  TO_NUMBER(REGEXP_REPLACE(s.up_on, '[^[[:digit:]]]*')) END) as s_up_on
        FROM (SELECT idb_id, COUNT(1) AS cnt
                FROM tbl
                where PHASE = phase_id$i
               GROUP BY idb_id) tlo
        ,idb_ph2_tbpi_int t
        ,idb_ph2_sbpi_int s
       WHERE tlo.cnt > 1
         AND t.idb_id = tlo.idb_id
         AND s.parent_id = t.idb_id
        AND s.actual_start_date <= lv_curr_date$d
        AND (s.actual_end_date IS NULL OR s.actual_end_date > lv_curr_date$d)
         AND s.off_id_for_migr IN ('121000111', '121000080', '121000117')
      )
      GROUP BY idb_id
    ) LOOP
      --
      SELECT nvl(TO_NUMBER(REGEXP_REPLACE(t.access_speed, '[^[[:digit:]]]*')), 0)
      INTO lv_access_speed
      FROM idb_ph2_tbpi_int t
      WHERE t.idb_id = rec.idb_id;

      lv_off_off_id_for_migr$c := NULL;
      IF rec.sm_121000080 > 0 THEN
        IF (rec.sm_121000111 - rec.sm_121000080) > 0 THEN
          --A.Kosterin 19.10.2021
          --lv_off_off_id_for_migr$c := '121000080';
          lv_off_off_id_for_migr$c := '121000111';
        ELSE
          lv_off_off_id_for_migr$c := '121000111';
        END IF;
      ELSIF rec.sm_121000117 > 0 THEN
        IF (rec.sm_121000111 - (lv_access_speed + rec.sm_121000117)) > 0 THEN
          --lv_off_off_id_for_migr$c := '121000117';
          lv_off_off_id_for_migr$c := '121000111';
        ELSE
          lv_off_off_id_for_migr$c := '121000111';
        END IF;
      END IF;
      IF lv_off_off_id_for_migr$c IS NOT NULL THEN
        lv_rec_num$i := lv_slo_arr$arr.count + 1;
        lv_slo_arr$arr(lv_rec_num$i).parent_id := rec.idb_id;
        lv_slo_arr$arr(lv_rec_num$i).off_off_id_for_migr := lv_off_off_id_for_migr$c;
      END IF;
    END LOOP;
    -- Вывод данных для удаления
    /*
    FOR i IN 1..lv_slo_arr$arr.count LOOP
      dbms_output.put_line(lv_slo_arr$arr(i).parent_id || ' - ' || lv_slo_arr$arr(i).off_off_id_for_migr);
    END LOOP;
    */
    -- Удаляем "лишние" записии
    FORALL i IN 1..lv_slo_arr$arr.count
      DELETE FROM idb_ph2_sbpi_int s
      WHERE s.parent_id = lv_slo_arr$arr(i).parent_id
        AND s.off_id_for_migr = lv_slo_arr$arr(i).off_off_id_for_migr
        and s.phase = phase_id$i;
  END del_slo_dbl_speed_bonus;

  /**
  * Создать рабочие данные в таблице RIAS_MGR_TMP_LIST
  * для заполнения приостановок
  */
  FUNCTION inser_work_data RETURN PLS_INTEGER
  IS
    lv_task_id PLS_INTEGER;
    -- 16.12.2020 feature_toggle for [ERT-24315]
    lv_swtch_value CONSTANT INTEGER := rias_mgr_core.get_feature_toggle(1);
    -- Текущая дата
    lc_current_date CONSTANT DATE := rias_mgr_support.get_current_date();

    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    lv_task_id := rias_mgr_task_seq.nextval;
    --dbms_output.put_line(lv_task_id);
    --/*+ append */
    -- Собирем все услуги приостановки
    INSERT INTO rias_mgr_tmp_list(task_id, account_idb_id, customer_idb_id, billing_id, addendum_id, str1,
                                  active_from, active_to, plan_item_id, activity_id, service_id, str2, off_id_for_migr,
                                  num1
                                  ,str5, num2
    )
      SELECT lv_task_id,
             t.account_idb_id,
             t.parent_id,
             alf.billing_id,
             alf.addendum_id,
             t.idb_id,
             trunc(alf.active_from) as active_from,
             trunc(alf.active_to)-1 as active_to,
             alf.plan_item_id,
             alf.activity_id,
             pi.service_id,
             'SERV',
             t.off_id_for_migr,
             ROUND(rias_mgr_support.get_service_cost(alf.addendum_id,pi.plan_item_id,alf.billing_id,pi.service_id), 2)*100000 as mrc,
             --t.mrc_cupon,
             --rias_mgr_support.get_nds(pi.service_id,alf.billing_id) as koefNDS,
             (SELECT
                rias_mgr_support.get_map_value_str('IDB_PH2_TBPI_INT', 'SUSPEND_REASON', af.flag_name)
              FROM teo_link_addenda_all tla,
                   agreement_flags_all  af,
                   teo_flag_links_all   tfl
              WHERE 1=1
                AND tla.addendum_id = alf.addendum_id
                AND tla.billing_id = alf.billing_id
                --
                AND tfl.teo_id = tla.teo_id
                AND tfl.billing_id = tla.billing_id
                AND tfl.active_from = alf.active_from
                --
                AND af.flag_id = tfl.flag_id
                AND af.billing_id = tfl.billing_id
                AND af.flag_type_id = 16
                AND NOT (af.flag_name like 'Автоматическое отключение по ДЗ%')
                AND af.flag_name IS NOT NULL
                AND rownum<=1
             ),
           (CASE
             WHEN (SELECT count(1)
                   FROM plan_items_all pi1, activate_license_fee_all alf1
                   WHERE 1=1
                     AND alf1.addendum_id = to_number(t.source_id)
                     AND alf1.billing_id = to_number(t.source_system)
                     AND pi1.plan_item_id = alf1.plan_item_id
                     AND pi1.billing_id = alf1.billing_id
                     AND pi1.service_id = 237
                     AND alf1.active_from >= alf.active_to
                     --AND alf1.active_from <= coalesce(alf.active_to, lc_current_date)
                     --AND coalesce(alf1.active_to, lc_current_date + 1)  > alf.active_from
                   ) > 0 THEN
               1
             ELSE
               0
           END) AS is_237
        FROM idb_ph2_tbpi_int t,
             plan_items_all pi,
             activate_license_fee_all alf
       WHERE 1 = 1
       and t.phase = phase_id$i
         AND t.source_system_type = '1'
         AND t.idb_id LIKE 'TI_1/%'
         AND alf.addendum_id = to_number(t.source_id)
         AND alf.billing_id = to_number(t.source_system)
         AND pi.plan_item_id = alf.plan_item_id
         AND pi.billing_id = alf.billing_id
         AND (pi.service_id IN (867, 102749)
              -- Используем feature_toggle для задачи ERT-24315
              -- 16.12.2020 Добавлена услуга 103257 [Временная блокировка услуг связи]
              OR (lv_swtch_value > 0 AND pi.service_id = 103257)
         )
         AND ((alf.active_from <= lc_current_date AND
             (alf.active_to IS NULL OR alf.active_to > lc_current_date)) OR -- Действующий
             (alf.active_from <= lc_current_date AND alf.active_to >= trunc(lc_current_date, 'mm') AND alf.active_to < lc_current_date) OR -- Изменился в этом месяце
             (alf.active_from >= lc_current_date) -- В будущем
         );
    -------------------
    --commit;
    -------------------
    -- ТЭО
    INSERT INTO RIAS_MGR_TMP_LIST (task_id, account_idb_id, customer_idb_id, billing_id, addendum_id,
                                   str1, active_from, active_to, service_id, str2, str5, off_id_for_migr,
                                   num1, num2)
    SELECT lv_task_id, tlo.account_idb_id, tlo.parent_id, ad.billing_id, ad.addendum_id, tlo.idb_id, trunc(tfl.active_from), trunc(tfl.active_to) -1, t.teo_id, 'TEO',
           rias_mgr_support.get_map_value_str('IDB_PH2_TBPI_INT', 'SUSPEND_REASON', af.flag_name) as flag_name,
           tlo.off_id_for_migr,
           0,
           (CASE
             WHEN (SELECT count(1)
                   FROM plan_items_all pi, activate_license_fee_all alf
                   WHERE 1=1
                     AND alf.addendum_id = to_number(tlo.source_id)
                     AND alf.billing_id = to_number(tlo.source_system)
                     AND pi.plan_item_id = alf.plan_item_id
                     AND pi.billing_id = alf.billing_id
                     AND pi.service_id = 237
                     AND alf.active_from >= tla.active_to
                     --AND alf.active_from <= coalesce(tla.active_to, lc_current_date)
                     --AND coalesce(alf.active_to, lc_current_date + 1)  > tla.active_from
                   ) > 0 THEN
               1
             ELSE
               0
           END) AS is_237
    FROM idb_ph2_tbpi_int     tlo,
         addenda_all          ad,
         teo_link_addenda_all tla,
         teo_all              t,
         point_plugins_all    pp,
         agreement_flags_all  af,
         teo_flag_links_all   tfl
    WHERE 1=1
    and tlo.phase = phase_id$i
      AND tlo.source_system_type = '1'
      AND tlo.idb_id like 'TI_1/%'
      --
      AND ad.addendum_id = to_number(tlo.source_id)
      AND ad.billing_id = to_number(tlo.source_system)
      --
      AND tla.addendum_id = ad.addendum_id
      AND tla.billing_id = ad.billing_id
      AND (
         (tla.active_from <= lc_current_date AND (tla.active_to IS NULL OR tla.active_to > lc_current_date)) OR                     -- Действующий
         (tla.active_from <= lc_current_date AND tla.active_to >= TRUNC(lc_current_date, 'mm') AND tla.active_to < lc_current_date) OR -- Изменился в этом месяце
         (tla.active_from >= lc_current_date)                                                                                    -- В будущем
      )
      --
      AND t.teo_id = tla.teo_id
      AND t.billing_id = tla.billing_id
      --
      AND pp.point_plugin_id = t.point_plugin_id
      AND pp.billing_id = t.billing_id
      AND pp.agreement_id = ad.agreement_id
      AND pp.billing_id = ad.billing_id
      AND pp.point_plugin_id = SUBSTR(tlo.IDB_ID, INSTR(tlo.IDB_ID,'/', -1, 1)+1, 500)
      --
      AND tfl.teo_id = t.teo_id
      AND tfl.billing_id = t.billing_id
      AND (
         (tfl.active_from <= lc_current_date AND (tfl.active_to IS NULL OR tfl.active_to > lc_current_date)) OR                     -- Действующий
         (tfl.active_from <= lc_current_date AND tfl.active_to >= TRUNC(lc_current_date, 'mm') AND tfl.active_to < lc_current_date) OR -- Изменился в этом месяце
         (tfl.active_from >= lc_current_date)                                                                                    -- В будущем
      )
      -- Берем только действующие (в рамках данного приложения) флаги.
      -- Т.к могут открыть новое приложение и забрать туда точку подключения со "старыми" атрибутами
      AND (tfl.active_to IS NULL OR tfl.active_to > tlo.actual_start_date)
      --
      AND af.flag_id = tfl.flag_id
      AND af.billing_id = tfl.billing_id
      AND af.flag_type_id = 16
      AND NOT (af.flag_name like 'Автоматическое отключение по ДЗ%')
      -- Откинем, ктр прошли по услугам
      AND NOT EXISTS(SELECT 1
                     FROM RIAS_MGR_TMP_LIST r
                     WHERE r.task_id = lv_task_id
                       AND r.billing_id = ad.billing_id
                       AND r.addendum_id = ad.addendum_id
                       AND r.str1 = tlo.idb_id
                       --1
                       -- пересечение диапазонов
                       AND COALESCE(tfl.active_to, lc_current_date) >= COALESCE(r.ACTIVE_FROM, lc_current_date)
                       AND COALESCE(tfl.active_from, lc_current_date) <= COALESCE(r.ACTIVE_TO, lc_current_date)
                       --2
                       -- Даты одинаковые
                       --AND COALESCE(TRUNC(tfl.active_from), lc_current_date) = COALESCE(TRUNC(r.active_from), lc_current_date)
                       --AND COALESCE(TRUNC(tfl.active_to), lc_current_date) = COALESCE(TRUNC(r.active_to), lc_current_date)
                     );
    -------------------
    -- COMMIT;
    -------------------
    -- Очистим от услуг, ктр заканчиваются и тут же начинаются
    DELETE FROM RIAS_MGR_TMP_LIST
    WHERE ROWID IN (SELECT t2.rowid
                      FROM RIAS_MGR_TMP_LIST t1, RIAS_MGR_TMP_LIST t2
                     WHERE 1=1
                       AND t1.task_id = lv_task_id
                       AND t2.task_id = lv_task_id
                       AND t1.str1 = t2.str1
                       AND COALESCE(t1.active_from, lc_current_date) = COALESCE(t2.active_to, lc_current_date));

    -- ТЭО
    -- Автоматическое отключение по ДЗ (устанавливается автоматически)
    -- Если работа фича разрешена, то работаем
    -- ERT-24320 - Приостановка по ДЗ
    IF rias_mgr_core.get_feature_toggle(3) > 0 THEN

      INSERT INTO RIAS_MGR_TMP_LIST (task_id, account_idb_id, customer_idb_id, billing_id, addendum_id,
                                     str1, active_from, active_to, service_id, str2, str4, str5, off_id_for_migr,
                                     num1, num2)
      SELECT lv_task_id,
             tlo.account_idb_id, tlo.parent_id, tla.billing_id, tla.addendum_id, tlo.idb_id, trunc(tfl.active_from),
             NULL as active_to,
             tla.teo_id,
             'TEO',
             af.flag_name,
             rias_mgr_support.get_map_value_str('IDB_PH2_TBPI_INT', 'SUSPEND_REASON', af.flag_name) as flag_name,
             tlo.off_id_for_migr,
             0,
             0 AS is_237
    FROM idb_ph2_tbpi_int    tlo,
         teo_link_addenda_all tla,
         agreement_flags_all  af,
         teo_flag_links_all   tfl
    WHERE 1=1
    and tlo.phase = phase_id$i
      AND tlo.source_system_type = '1'
      AND tlo.idb_id LIKE 'TI_1/%'
      --AND tlo.idb_id = 'TI_1/556/6995445/19293332/241688'
      AND tla.addendum_id = to_number(tlo.source_id)
      AND tla.billing_id  = to_number(tlo.source_system)
      --Проверка на действующий статус привязки приложения к тео_ид
      AND tla.active_from <= lc_current_date
      AND (tla.active_to IS NULL OR tla.active_to > lc_current_date)
      AND tfl.teo_id = tla.teo_id
      AND tfl.billing_id = tla.billing_id
      AND tfl.active_from <= lc_current_date
      -- Учтем, что флаг "однодневка"
      --AND TRUNC(tfl.active_from) = TRUNC(tfl.active_to) - 1
      AND (tfl.active_to -1) = tfl.active_from
      --
      AND af.flag_id = tfl.flag_id
      AND af.billing_id = tfl.billing_id
      --Проверка на флаг
      --AND af.flag_type_id = 16
      -- Автоматическое отключение по ДЗ (устанавливается автоматически)
      AND af.flag_id = 1083487

      -- Проверка на отсутствия флага возврата из приостановления следующего за флагом Автом. отклю.
      --
      and tfl.active_from > COALESCE((select max(flv.active_from)
                                      from teo_flag_links_all flv,
                                           agreement_flags_all afv
                                      where flv.teo_id = tfl.teo_id
                                        and flv.billing_id = tfl.billing_id
                                        and flv.flag_id = afv.flag_id
                                        and flv.billing_id = afv.billing_id
                                        --and afv.flag_type_id = 24
                                        -- 'Возврат из приостановления'
                                        and afv.flag_id = 1083312
                                      ), tfl.active_from - 1)
      --Проверка на то, что флаг явл-ся максимальным по дате из всех флагов на приложении с типом 16.
      and ((select max(tf2.active_from)
                from teo_flag_links_all tf2,
                    agreement_flags_all af2
                where 1=1
                 AND tf2.teo_id = tfl.teo_id
                 AND tf2.billing_id = tfl.billing_id
                 AND af2.flag_id = tf2.flag_id
                 AND af2.billing_id = tf2.billing_id
                 --AND af2.flag_type_id = 16
                 AND af2.flag_id = 1083487
                ) = tfl.active_from)
/*
      --Проверка на отсутствия флага возврата из приостановления следующего за флагом Автом. отклю.
      and (select count(1)
           from agreement_flags_all af5,
                teo_flag_links_all tfl5
           where 1=1
             --AND af5.flag_type_id = 24
             -- Возврат из приостановления
             AND af5.flag_id = 1083312
             AND af5.flag_id = tfl5.flag_id
             AND af5.billing_id = tfl5.billing_id
             and tfl5.teo_id = tfl.teo_id
             and tfl5.billing_id = tfl.billing_id
             AND tfl5.active_from > tfl.active_from) = 0
      --Проверка на то, что возврат из приостановления не открытался той же датой, что и флаг Автоматическое отключение по ДЗ
      AND COALESCE((select min(tfl5.active_from)
               from agreement_flags_all af5,
                    teo_flag_links_all tfl5
               where 1=1
                 --AND af5.flag_type_id = 24
                 -- Возврат из приостановления
                 AND af5.flag_id = 1083312
                 AND af5.flag_id = tfl5.flag_id
                 AND af5.billing_id = tfl5.billing_id
                 and tfl5.teo_id = tfl.teo_id
                 and tfl5.billing_id = tfl.billing_id
                 AND tfl5.active_from >= tfl.active_from),  tfl.active_from - 1) < tfl.active_from
*/
      -- не должно быть активной услуги АП
      AND (SELECT count(1)
           FROM plan_items_all pi,
                activate_license_fee_all alf
           WHERE 1=1
             AND alf.addendum_id = tla.addendum_id
             AND alf.billing_id = tla.billing_id
             AND pi.plan_item_id = alf.plan_item_id
             AND pi.billing_id = alf.billing_id
             AND pi.service_id = 237
             -- пересечение диапазонов
             AND lc_current_date/* COALESCE(tfl.active_to, lc_current_date)*/ >= COALESCE(alf.ACTIVE_FROM, lc_current_date)
             AND COALESCE(tfl.active_from, lc_current_date) <= COALESCE(alf.ACTIVE_TO, lc_current_date)-1
             --AND alf.active_from <= lc_current_date
             --AND alf.active_from >= tfl.active_to-- ???
           ) = 0;

    END IF; -- IF rias_mgr_core.get_feature_toggle(3) > 0 THEN
    -------------------
    COMMIT;
    -------------------

    RETURN lv_task_id;
  END inser_work_data;

  /**
  * Заполнить приостановки
  */
  PROCEDURE fill_suspended
  IS
    lv_task_id PLS_INTEGER;
  BEGIN
    rias_mgr_core.save_session_state;
    -- Зачистим таблицы
    DELETE FROM idb_ph2_sbpi_int f WHERE f.source_system_type = 1 AND f.idb_id LIKE 'SUS_TI_1/%' and f.phase = phase_id$i;
    DELETE FROM idb_ph2_bpi_suspend_req WHERE bpi_idb_id LIKE 'TI_1%' and phase = phase_id$i;
    --
    dbms_application_info.set_action('Insert Work Data');
    --
    lv_task_id := inser_work_data();
    --
    -- IDB_PH2_BPI_SUSPEND_REQ
    -------------------
    
    --06.12.2021 A.Kosterin непонятная вставка в самом конце действий пакета ODI; перенёс вверх, чтобы не повторять шаг inser_work_date
  delete from aak_tmp_idb_ph2_bpi_suspend_req where idb_id like 'SUSP_CH%' and phase = phase_id$i;
  delete from idb_ph2_bpi_suspend_req where idb_id like 'SUSP_CH%' and phase = phase_id$i;


    
    dbms_application_info.set_action('Insert Suspended Data (Future)');
    -- Кейс на будущую дату
    -- NUM2 - есть/нет АП в будущем (за остановкой)
    INSERT INTO idb_ph2_bpi_suspend_req(bpi_idb_id, idb_id, susp_end_date, susp_start_date, susp_descr, phase)
    SELECT t.str1, 'SUS_'||t.str1, CASE WHEN t.num2 = 1 THEN t.active_to +1 ELSE NULL END, t.active_from, t.str5, phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1 = 1
      AND t.task_id = lv_task_id
      AND t.active_from > current_date
      AND t.active_to IS NOT NULL; -- 28.08.2020 (TOMS_IDB_PH2_BPI_SUSPEND_REQ_BPI_IDB_ID_3_CST)

    dbms_application_info.set_action('Insert Suspended Data (Current)');
    -- Кейс классический
    INSERT INTO idb_ph2_bpi_suspend_req(bpi_idb_id, idb_id, susp_end_date, susp_start_date, susp_descr, phase)
    SELECT t.str1, 'SUS_'||t.str1, t.active_to +1, t.active_from, NULL /*Заполняется для TLO --t.str5*/, phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1 = 1
      AND t.num2 = 1 -- Есть АП в будующем
      AND t.task_id = lv_task_id
      AND t.active_from <= current_date
      AND (t.active_to IS NULL OR t.active_to > current_date)
      AND t.active_to IS NOT NULL; -- 28.08.2020 (TOMS_IDB_PH2_BPI_SUSPEND_REQ_BPI_IDB_ID_3_CST)
  
  --06.12.2021 A.Kosterin
  insert into aak_tmp_idb_ph2_bpi_suspend_req(bpi_idb_id,
                                      idb_id,
                                      isvalid,
                                      susp_end_date,
                                      susp_start_date,
                                      susp_descr, phase)
  select
  str1,'SUSP_CH'||str1,null,t.active_to+1,t.active_from,case when t.active_from > current_date then t.str5 else null end, phase_id$i 
  from rias_mgr_tmp_list t
  where 1=1
  and task_id = lv_task_id
  and active_to > current_date
  and not exists(select 1 from idb_ph2_bpi_suspend_req r where r.bpi_idb_id = t.str1 and r.susp_start_date = t.active_from and r.susp_end_date = t.active_to + 1);
  

    dbms_application_info.set_action('Update IDB_PH2_TBPI_INT');
    -------------------
    -- IDB_PH2_TBPI_INT
    -------------------
    UPDATE IDB_PH2_TBPI_INT ti
    SET
      ti.ext_bpi_status = 'Suspended',
      ti.ext_bpi_status_date =
        (SELECT max(t.active_from)
        FROM rias_mgr_tmp_list t
        WHERE 1 = 1
          AND t.task_id = lv_task_id
          AND t.active_from <= current_date
          AND (t.active_to IS NULL OR t.active_to > current_date)
          --AND t.str2 = 'TEO'
          AND t.str1 = ti.idb_id),
       ti.suspend_reason = (select t.str5
           FROM rias_mgr_tmp_list t
           WHERE 1 = 1
             AND t.task_id = lv_task_id
             AND t.str5 IS NOT NULL
             AND t.active_from <= current_date
             AND (t.active_to IS NULL OR t.active_to > current_date)
             AND t.str1 = ti.idb_id
             AND rownum<=1),
       ti.suspend_reason_descr = (select t.str4
           FROM rias_mgr_tmp_list t
           WHERE 1 = 1
             AND t.task_id = lv_task_id
             AND t.str5 IS NOT NULL
             AND t.active_from <= current_date
             AND (t.active_to IS NULL OR t.active_to > current_date)
             AND t.str1 = ti.idb_id
             AND rownum<=1)
/*,
-- !!!!! где надо не забываем умножить на 100 000
       ti.mrc = (CASE
                   WHEN (SELECT num2
                         FROM rias_mgr_tmp_list t
                         WHERE t.task_id = lv_task_id
                           AND t.str1 = ti.idb_id
                           AND t.active_from <= current_date
                           AND (t.active_to IS NULL OR t.active_to > current_date)) = 0 THEN
                     ti.mrc
                   ELSE
                     NULL
\*
                     rias_mgr_support.get_service_cost_tlo( -- Перенести из заполнения TLO -get_cost в части только получения COST

                                                                     date$d => (SELECT MAX(alf1.ac -- в общем, взять active_from будущей АП
                   FROM plan_items_all pi1, activate_license_fee_all alf1
                   WHERE 1=1
                     AND alf1.addendum_id = to_number(t.source_id)
                     AND alf1.billing_id = t.billing_id
                     AND pi1.plan_item_id = alf1.plan_item_id
                     AND pi1.billing_id = alf1.billing_id
                     AND pi1.service_id = 237
                     AND alf1.active_from > alf.active_to
*\              END),

       ti.mrc_cupon = (CASE
                   WHEN (SELECT num2
                         FROM rias_mgr_tmp_list t
                         WHERE t.task_id = lv_task_id
                           AND t.str1 = ti.idb_id
                           AND t.active_from <= current_date
                           AND (t.active_to IS NULL OR t.active_to > current_date)) = 0 THEN
                           ti.mrc_cupon
                         ELSE
                           NULL
\*
                           NVL(RIAS_MGR_SUPPORT.get_cupon_4_service(addendum_id$i => to_number(ti.source_id),
                                                                    billing_id$i  => to_number(ti.source_system),
                                                                    service_id$i  =>  1800,
                                                                    date$d        => -- взять active_from будущей 1800 (если есть)
                                                                    ), 0);
*\
                       END),
\*
         -- переписать MRC в зависимости от %скидки (mrc_cupon)
         mrc := ROUND(lv_mrc_rec.serv_cost - lv_mrc_rec.mrc_discount, 2);
         tax_mrc := ROUND(lv_mrc_rec.mrc - lv_mrc_rec.mrc/lv_mrc_rec.koef_nds, 2);
         mrc_cupon_mnt = сумма скидки
*\
         ti.tax_mrc =
           (CASE
                   WHEN (SELECT num2
                         FROM rias_mgr_tmp_list t
                         WHERE t.task_id = lv_task_id
                           AND t.str1 = ti.idb_id
                           AND t.active_from <= current_date
                           AND (t.active_to IS NULL OR t.active_to > current_date)) = 0 THEN
                ti.tax_mrc
              ELSE
                NULL
            END),

         ti.mrc_cupon_mnt =
           (CASE
                   WHEN (SELECT num2
                         FROM rias_mgr_tmp_list t
                         WHERE t.task_id = lv_task_id
                           AND t.str1 = ti.idb_id
                           AND t.active_from <= current_date
                           AND (t.active_to IS NULL OR t.active_to > current_date)) = 0 THEN
                ti.mrc_cupon_mnt
              ELSE
                NULL
            END)
*/
/* -- Устаревшее
      ,ti.mrc = (select max(num1)
           FROM rias_mgr_tmp_list t
           WHERE 1 = 1
             AND t.task_id = lv_task_id
             AND t.active_from <= current_date
             AND (t.active_to IS NULL OR t.active_to > current_date)
             AND t.str1 = ti.idb_id)
*/
    WHERE 1=1
      --AND ti.ext_bpi_status != 'Suspended' -- ???
      AND ti.idb_id IN (
        SELECT distinct t.str1
        FROM rias_mgr_tmp_list t
        WHERE 1 = 1
          AND t.task_id = lv_task_id
          AND t.active_from <= current_date
          AND (t.active_to IS NULL OR t.active_to > current_date)
          --AND t.str2 = 'TEO'
      );
------------
  /*
    SELECT * FROM IDB_PH2_TBPI_INT ti
    WHERE 1=1
      AND ti.ext_bpi_status != 'Suspended' -- ???
      AND ti.idb_id IN (
        SELECT distinct t.str1
        FROM rias_mgr_tmp_list t
        WHERE 1 = 1
          AND t.task_id = 3746--lv_task_id
          AND t.active_from <= current_date
          AND (t.active_to IS NULL OR t.active_to > current_date)
          AND t.str2 = 'TEO'
      );
      --select * from rias_mgr_tmp_list t where t.task_id = 3746 and t.str1 = 'TI_1/1/6442535/10835752/152292';
  */
    dbms_application_info.set_action('Insert Suspended Data (IDB_PH2_TBPI_INT)');
    -------------------
    -- IDB_PH2_SBPI_INT
    -------------------
    INSERT INTO idb_ph2_sbpi_int
      (account_idb_id,
       actual_end_date,
       actual_start_date,
       billed_to_dat,
       bpi_market,
       bpi_organization,
       bpi_time_zone,
       created_when,
       customer_idb_id,
       customer_location,
       ext_bpi_status,
       ext_bpi_status_date,
       idb_id,
       inv_name,
       ma_flag,
       ma_flag_date,
       mrc,
       off_id_for_migr,
       parent_id,
       --parent_service_id,
       service_id,
       source_id,
       source_system,
       source_system_type,
       tax_mrc,
       barring,
       phase)
      SELECT fin.account_idb_id,
             CASE
               WHEN fin.active_to < trunc(current_date) THEN
                 fin.active_to
               ELSE
                 NULL
             END AS actual_end_date,
             CASE
               WHEN fin.active_from < rec.actual_start_date THEN
                 rec.actual_start_date
               ELSE
                 fin.active_from
             END AS actual_start_date,
             CASE
               WHEN fin.active_from < trunc(current_date, 'mm') THEN
                trunc(current_date, 'mm') - 1
               ELSE
                NULL
             END AS billed_to_dat,
             rec.bpi_market,
             rec.bpi_organization,
             rec.bpi_time_zone,
             rec.created_when,
             fin.customer_idb_id,
             rec.customer_location,
             CASE
               WHEN (fin.active_from <= current_date AND
                      (fin.active_to = trunc(current_date) OR -- 09.03.2021 Не учитывался "сегодняшний" день в действии приостановки
                       coalesce(fin.active_to, current_date + 1) > current_date)) THEN
                'Active'
               ELSE
                'Disconnected'
             END AS ext_bpi_status,
             CASE
               WHEN (fin.active_from <= current_date AND
                      (fin.active_to = trunc(current_date) OR -- 09.03.2021 Не учитывался "сегодняшний" день в действии приостановки
                       coalesce(fin.active_to, current_date + 1) > current_date)) THEN
                fin.active_from
               ELSE
                fin.active_to
             END AS ext_bpi_status_date,
             'SUS_' || rec.idb_id || chernov_seqa.nextval  AS idb_id,
             CASE
               WHEN fin.off_id_for_migr = 121000390 THEN
                'Приостановка Интернет Индивидуальный'
               WHEN fin.off_id_for_migr = 121000879 THEN
                'Приостановка Интернет "Скорость +"'
               WHEN fin.off_id_for_migr = 121000837 THEN
                'Приостановка Интернет "Скорость"'
               WHEN fin.off_id_for_migr = 121000121 THEN
                'Приостановка Интернет Базовый Бизнес'
               WHEN fin.off_id_for_migr = 121000296 THEN
                'Приостанов Интернет Беспроводной Бизнес'
               WHEN fin.off_id_for_migr = 121000355 THEN
                'Приостановка Интернет Мобильный Бизнес'
               WHEN fin.off_id_for_migr = 9161228920313303218 THEN
                'Приостановка Интернет Беспроводной'
               WHEN fin.off_id_for_migr = 9161358500513727314 THEN
                'Приостановка Интернет Эксклюзив-Лайт'
               WHEN fin.off_id_for_migr = 9161358501513727314 THEN
                'Приостановка Интернет Эксклюзив'
               WHEN fin.off_id_for_migr = 9161358502513727314 THEN
                'Приостановка Интернет Люкс'
             END AS inv_name,
             'Основной проект' AS ma_flag,
             trunc(current_date) AS ma_flag_date,
             num1 as mrc,
             /*
             CASE
               WHEN fin.plan_item_id IS NOT NULL THEN
                round(rias_mgr_support.get_service_cost(fin.addendum_id, fin.plan_item_id, fin.billing_id, fin.service_id), 2)
               ELSE
                0
             END * 100000 mrc,
             */
             CASE
               WHEN fin.off_id_for_migr = 121000390 THEN
                '121001233'
               WHEN fin.off_id_for_migr = 121000879 THEN
                '121001269'
               WHEN fin.off_id_for_migr = 121000837 THEN
                '121001260'
               WHEN fin.off_id_for_migr = 121000121 THEN
                '121001179'
               WHEN fin.off_id_for_migr = 121000296 THEN
                '121001206'
               WHEN fin.off_id_for_migr = 121000355 THEN
                '121001224'
               WHEN fin.off_id_for_migr = 9161228920313303218 THEN
                '121001206'
               WHEN fin.off_id_for_migr in (9161358500513727314, 9161358501513727314, 9161358502513727314) THEN
                '121001179'
             END AS off_id_for_migr,
             rec.idb_id AS parent_id,
             --rec.service_id AS parent_service_id,
             CASE
               WHEN fin.off_id_for_migr = 121000390 THEN
                'INTINDSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
               WHEN fin.off_id_for_migr = 121000879 THEN
                'INTSPEEDPLSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
               WHEN fin.off_id_for_migr = 121000837 THEN
                'INTSPEEDSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
               WHEN fin.off_id_for_migr = 121000121 THEN
                'INTBEZLIMSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
               WHEN fin.off_id_for_migr = 121000296 THEN
                'INTWIUNLIMSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
               WHEN fin.off_id_for_migr = 121000355 THEN
                'INTMOUNLIMSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
               WHEN fin.off_id_for_migr = 9161228920313303218 THEN
                'INTWIUNLIMSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
               WHEN fin.off_id_for_migr in (9161358500513727314, 9161358501513727314, 9161358502513727314) THEN
                'INTLIMITSUSP-' || to_char(fin.active_from, 'ddmmyyyy') || '1'
             END AS service_id,
             (to_char(fin.agreement_id) || '/' || to_char(fin.addendum_id) ||
              CASE
                WHEN fin.plan_item_id IS NOT NULL THEN
                 '/' || to_char(fin.plan_item_id)
                ELSE
                 ''
              END ||
              CASE
                WHEN fin.activity_id IS NOT NULL THEN
                 '/' || to_char(fin.activity_id)
                ELSE
                 ''
              END) AS source_id,
             rec.source_system,
             rec.source_system_type,
             CASE
               WHEN fin.plan_item_id IS NOT NULL THEN
                (round(((excellent.chernov_migr.get_customer_smrs_chernov2(v_addendum_id => fin.addendum_id, v_billing_id => fin.billing_id, v_plan_item_id => fin.plan_item_id, v_serv => fin.service_id) / 1.2 -
                       excellent.chernov_migr.get_customer_smrs_chernov2(v_addendum_id => fin.addendum_id, v_billing_id => fin.billing_id, v_plan_item_id => fin.plan_item_id, v_serv => fin.service_id)) * '-1'), 2) *
                100000)
               ELSE
                0
             END tax_mrc,
             'N' barring,
             rec.phase
        FROM rias_mgr_tmp_list fin, idb_ph2_tbpi_int rec
       WHERE 1 = 1
       and rec.phase = phase_id$i
         AND fin.task_id = lv_task_id
         AND fin.active_from <= current_date
         AND fin.str1 = rec.idb_id;

    UPDATE /*+ append */ idb_ph2_sbpi_int f
       SET f.actual_end_date = CASE
                                 WHEN ext_bpi_status = 'Active' THEN
                                   NULL
                                 ELSE
                                   actual_end_date
                                 END
     WHERE f.actual_end_date > current_date
       AND idb_id like 'SUS_TI_1/%';

     -- Взято из проверки...
      UPDATE idb_ph2_tbpi_int tl
         SET tl.ext_bpi_status_date =
             (SELECT max(t.ext_bpi_status_date) + 1
                FROM idb_ph2_sbpi_int t
               WHERE t.parent_id = tl.idb_id
                 AND t.idb_id LIKE 'SUS_TI_1/%'
                 AND t.ext_bpi_status = 'Disconnected'
                 AND t.ext_bpi_status_date <> tl.ext_bpi_status_date)
       WHERE tl.rowid IN
             (SELECT tlo.rowid
              --tlo.idb_id, tlo.ext_bpi_status, tlo.ext_bpi_status_date, t.ext_bpi_status, t.ext_bpi_status_date
              --count(1)
                FROM idb_ph2_sbpi_int t
                JOIN idb_ph2_tbpi_int tlo
                  ON tlo.idb_id = t.parent_id
               WHERE 1 = 1
               and t.phase = phase_id$i
                 AND t.idb_id LIKE 'SUS_TI_1/%'
                 AND t.ext_bpi_status = 'Disconnected'
                 AND tlo.ext_bpi_status = 'Active'
                 AND tlo.ext_bpi_status_date <> t.ext_bpi_status_date);
    -- Зачистить временную таблицу
    DELETE /*+ append */ FROM RIAS_MGR_TMP_LIST t WHERE t.task_id = lv_task_id;
    -- Восстановить инфу в сессии
    RIAS_MGR_CORE.restore_session_state;
  END fill_suspended;

  ------------------------------
  -- Удалить рабочие данные
  ------------------------------
  PROCEDURE clear_tmp_data(ip_task_id IN PLS_INTEGER)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    DELETE /*+ append */ FROM rias_mgr_tmp_list where task_id = ip_task_id;
    COMMIT;
  END clear_tmp_data;

  /**
  * Заполнить IDB_PH2_BPI_MRC_PRICEOVERRIDE
  * V2.22 и выше
  */
  PROCEDURE fill_priceoverride_after_2_22
  IS
    -- Идентификатор записи в рабочей таблице
    lv_task_id PLS_INTEGER;
    -- Идентификатор записи в рабочей таблице для приложений, где более одной услуги в месяй миграции
    lv_task_many_id PLS_INTEGER;
    -- Флаг промежуточного COMMIT'а
    gv_commit BOOLEAN := TRUE;
    ------------------------------
    -- Делаем COMMIT если нужно
    ------------------------------
    PROCEDURE fn_commit
    IS
    BEGIN
      IF gv_commit THEN COMMIT; END IF;
    END fn_commit;
    ------------------------------
    -- Стоимости для оверрайдов
    ------------------------------
    /*
    FUNCTION get_cost_service(addendum_id$i  INTEGER,
                              billing_id$i   INTEGER,
                              service_id     INTEGER,
                              service_cup_id INTEGER DEFAULT NULL,
                              date$d         DATE DEFAULT rias_mgr_support.get_current_date(),
                              with_nds$i     INTEGER DEFAULT 1,-- 0/1
                              with_cupon     INTEGER DEFAULT 0 -- 0/1
    )
    RETURN NUMBER
    IS
      lv_res$n   NUMBER;
      lv_cost$n  NUMBER;
      lv_cupon$n NUMBER;
    BEGIN
      --IF (with_cupon = 1 AND service_cup_id) IS NULL THEN EXCEPTION...; END IF;
      lv_cost$n := rias_mgr_support.get_service_cost(addendum_id$i, NULL, billing_id$i, service_id, date$d, with_nds$i);
      IF with_cupon = 1 AND service_cup_id IS NOT NULL THEN
        lv_cupon$n := NVL(rias_mgr_support.get_cupon_4_service(addendum_id$i => addendum_id$i,
                                                               billing_id$i  => billing_id$i,
                                                               service_id$i  => service_cup_id,
                                                               date$d        => date$d), 0);
      END IF;
      lv_res$n := ROUND(lv_cost$n - lv_cost$n * lv_cupon$n/100, 2);
      RETURN lv_res$n;
    END;
    */
    ------------------------------
    -- Заполнить рабочую таблицу
    ------------------------------
    FUNCTION prepare_data
    RETURN PLS_INTEGER
    IS
      lv_res_id PLS_INTEGER;
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      lv_res_id := rias_mgr_task_seq.nextval;
      INSERT /*+ append */ INTO rias_mgr_tmp_list(task_id, idb_id, str2, d1, d2, num1, str3, str4, service_id, active_from, active_to, num2)
      SELECT lv_res_id,
             tbl.idb_id,
             tbl.str2,
             tbl.d1,
             tbl.d2,
             tbl.num1,
             tbl.str3,
             tbl.str4,
             tbl.service_id,
             tbl.active_from,
             tbl.active_to,
             CASE
               WHEN tbl.service_id = 1800 THEN
                 NVL(RIAS_MGR_SUPPORT.get_cupon_4_service(addendum_id$i => TO_NUMBER(tbl.str3),
                                                          billing_id$i  => TO_NUMBER(tbl.str4),
                                                          service_id$i  => tbl.service_id,
                                                          date$d        => tbl.active_from
                                                          ), 0)
               ELSE
                 NULL
             END AS cupon
      FROM(
        SELECT DISTINCT
               t.idb_id         AS idb_id,          -- idb_id
               t.ext_bpi_status AS str2,            -- str2
               TRUNC(t.actual_start_date) AS d1,    -- d1
               TRUNC(t.actual_end_date)   AS d2,    -- d2
               t.mrc            AS num1,            -- num1
               t.source_id      AS str3,            -- str3
               t.source_system  AS str4,            -- str4
               pi.service_id    AS service_id,      -- service_id
               TRUNC(
                 case
                   when alf.active_from < t.actual_start_date then
                     t.actual_start_date
                   else
                     alf.active_from
                 end
               )                    AS active_from, -- active_from
               TRUNC(alf.active_to) AS active_to    -- active_to
         FROM idb_ph2_tbpi_int t,
              plan_items_all pi,
              activate_license_fee_all alf
        WHERE 1=1
        and t.phase = phase_id$i
          AND t.source_system_type = '1'
          AND t.idb_id LIKE 'TI_1/%'
          --AND t.idb_id = 'TI_1/241/1743010/5691918/23183'
          --AND t.idb_id = 'TI_1/1/6942221/11015429/152464'
          --AND t.idb_id = 'TI_1/1/6940215/10837387/275888'
          AND t.off_id_for_migr IN (SELECT d.off_id_for_migr
                                    FROM idb_ph2_offerings_dic d
                                    WHERE d.idb_table_name = 'IDB_PH2_TBPI_INT'
                                      AND d.act_price_spec_nc_id IS NOT NULL
                                      AND d.no_charge IS NULL)
          AND alf.addendum_id = to_number(t.source_id)
          AND alf.billing_id = to_number(t.source_system)
          AND alf.active_from <= current_date
          AND (alf.active_to IS NULL OR alf.active_to >= trunc(current_date, 'mm'))
          --
          AND pi.plan_item_id = alf.plan_item_id
          AND pi.billing_id = alf.billing_id
          -- А если несколько будет на 1 приложении? Что надо создавать записи для каждой услуги?
          AND pi.service_id IN (1800, 102243, 102241, 101394, 101395, 101396, 101254, 103305, 103343)
        ) tbl;
/*
      INSERT INTO rias_mgr_tmp_list(task_id, str1, str2, d1, d2, num1, str3, str4, service_id, active_from, active_to, num2)
      SELECT DISTINCT
             lv_res_id,           -- task_id
             t.idb_id,            -- str1
             t.ext_bpi_status,    -- str2
             TRUNC(t.actual_start_date), -- d1
             TRUNC(t.actual_end_date),   -- d2
             t.mrc,               -- num1
             t.source_id,         -- str3
             t.source_system,     -- str4
             pi.service_id,       -- service_id
             TRUNC(
               case
                 when alf.active_from < t.actual_start_date then
                   t.actual_start_date
                 else
                   alf.active_from
               end
             ) as active_from,     -- active_from
             TRUNC(alf.active_to), -- active_to
             CASE
               WHEN pi.service_id = 1800 THEN
                 NVL(RIAS_MGR_SUPPORT.get_cupon_4_service(addendum_id$i => alf.addendum_id,
                                                          billing_id$i  => alf.billing_id,
                                                          service_id$i  =>  1800,
                                                          date$d        => TRUNC(CASE
                                                                                   WHEN alf.active_from < t.actual_start_date THEN
                                                                                     t.actual_start_date
                                                                                   ELSE
                                                                                     alf.active_from
                                                                                   END)
                                                          ), 0)
               ELSE
                 NULL
             END AS cupon
       FROM idb_ph2_tbpi_int t,
            plan_items_all pi,
            activate_license_fee_all alf
      WHERE 1=1
        AND t.source_system_type = '1'
        AND t.idb_id LIKE 'TI_1/%'
        --AND t.idb_id = 'TI_1/241/1743010/5691918/23183'
        --AND t.idb_id = 'TI_1/1/6942221/11015429/152464'
        --AND t.idb_id = 'TI_1/1/6940215/10837387/275888'
        AND t.off_id_for_migr IN (SELECT d.off_id_for_migr
                                  FROM idb_ph2_offerings_dic d
                                  WHERE d.idb_table_name = 'IDB_PH2_TBPI_INT'
                                    AND d.act_price_spec_nc_id IS NOT NULL
                                    AND d.no_charge IS NULL)
        AND alf.addendum_id = to_number(t.source_id)
        AND alf.billing_id = to_number(t.source_system)
        AND alf.active_from <= current_date
        AND (alf.active_to IS NULL OR alf.active_to >= trunc(current_date, 'mm'))
        --
        AND pi.plan_item_id = alf.plan_item_id
        AND pi.billing_id = alf.billing_id
        -- А если несколько будет на 1 приложении? Что надо создавать записи для каждой услуги?
        AND pi.service_id IN (1800, 102243, 102241, 101394, 101395, 101396, 101254);
*/
      COMMIT;
      RETURN lv_res_id;
    END prepare_data;

    ------------------------------
    -- Схлопнуть записи
    -- Одинаковые IDB_ID с одинаковыми скидочными купонами,
    -- где одна историческая запись заканчивается и тут же начинается другая
    ------------------------------
    PROCEDURE prepare_data_2(
      task_id$i    IN PLS_INTEGER,
      service_id$i IN PLS_INTEGER DEFAULT 1800
    )
    IS
      TYPE t_rec IS RECORD  (
        idb_id      rias_mgr_tmp_list.idb_id%type,
        str2        rias_mgr_tmp_list.str2%type,
        d1          rias_mgr_tmp_list.d1%type,
        d2          rias_mgr_tmp_list.d2%type,
        num1        rias_mgr_tmp_list.num1%type,
        str3        rias_mgr_tmp_list.str3%type,
        str4        rias_mgr_tmp_list.str4%type,
        cupon       rias_mgr_tmp_list.num2%type,
        active_from rias_mgr_tmp_list.active_from%type,
        active_to   rias_mgr_tmp_list.active_to%type
      );
      TYPE t_arr IS TABLE OF t_rec INDEX BY PLS_INTEGER;
      lv_arr t_arr;
      lv_curr_rec t_rec;
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      FOR rec IN (
        SELECT t.idb_id, str2, d1, d2, num1, str3, str4, num2, service_id, active_from, active_to
        FROM rias_mgr_tmp_list t,
             (SELECT idb_id--, count(1) as cnt
              FROM rias_mgr_tmp_list
              WHERE task_id = task_id$i
                AND service_id = service_id$i
              GROUP BY idb_id
              HAVING COUNT(1) > 1) tbl
        WHERE 1=1
          AND t.task_id = task_id$i
          AND t.idb_id = tbl.idb_id
        ORDER BY t.idb_id, active_from, active_to
      ) LOOP
        -- Первый заход
        IF lv_curr_rec.idb_id IS NULL THEN
          lv_curr_rec.idb_id      := rec.idb_id;
          lv_curr_rec.str2        := rec.str2;
          lv_curr_rec.d1          := rec.d1  ;
          lv_curr_rec.d2          := rec.d2  ;
          lv_curr_rec.num1        := rec.num1;
          lv_curr_rec.str3        := rec.str3;
          lv_curr_rec.str4        := rec.str4;
          lv_curr_rec.cupon       := rec.num2;
          lv_curr_rec.active_from := rec.active_from;
          lv_curr_rec.active_to   := rec.active_to;
        ELSE
          -- IDB_ID повторяется
          IF lv_curr_rec.idb_id = rec.idb_id THEN
            -- Если купон не изменился и один и тот же заканчивается и тут же начинается
            IF lv_curr_rec.cupon = rec.num2 AND
               NVL(lv_curr_rec.active_to, to_date('01.01.3000', 'mm.dd.yyyy')) = rec.active_from
            THEN
               lv_curr_rec.active_to := rec.active_to;
            ELSE
              -- Запомнить полученный элемент в массив
              lv_arr(lv_arr.count + 1) := lv_curr_rec;
              -- Переопределить текущий элемент
              lv_curr_rec.idb_id      := rec.idb_id;
              lv_curr_rec.str2        := rec.str2;
              lv_curr_rec.d1          := rec.d1  ;
              lv_curr_rec.d2          := rec.d2  ;
              lv_curr_rec.num1        := rec.num1;
              lv_curr_rec.str3        := rec.str3;
              lv_curr_rec.str4        := rec.str4;
              lv_curr_rec.cupon       := rec.num2;
              lv_curr_rec.active_from := rec.active_from;
              lv_curr_rec.active_to   := rec.active_to;
            END IF;
          ELSE
            -- Запомнить полученный элемент в массив
            lv_arr(lv_arr.count + 1) := lv_curr_rec;
            -- Переопределить текущий элемент
            lv_curr_rec.idb_id      := rec.idb_id;
            lv_curr_rec.str2        := rec.str2;
            lv_curr_rec.d1          := rec.d1  ;
            lv_curr_rec.d2          := rec.d2  ;
            lv_curr_rec.num1        := rec.num1;
            lv_curr_rec.str3        := rec.str3;
            lv_curr_rec.str4        := rec.str4;
            lv_curr_rec.cupon       := rec.num2;
            lv_curr_rec.active_from := rec.active_from;
            lv_curr_rec.active_to   := rec.active_to;
          END IF;
        END IF;

      END LOOP;
      -- Скинем последний элемент в массив
      lv_arr(lv_arr.count + 1) := lv_curr_rec;
      -- Удалим Задвоенные записи
      FORALL i IN 1 .. lv_arr.count
        DELETE rias_mgr_tmp_list t
        WHERE 1=1
          AND task_id = task_id$i
          AND service_id = service_id$i
          AND t.idb_id = lv_arr(i).idb_id;
      -- Вставим "схлопнутые" записи, вместо задвоенных
      FORALL i IN 1 .. lv_arr.count
        INSERT /*+ append */ INTO rias_mgr_tmp_list(task_id, idb_id, str2, d1, d2, num1, str3, str4, num2, service_id, active_from, active_to, str5)
        VALUES(task_id$i,
               lv_arr(i).idb_id,
               lv_arr(i).str2,
               lv_arr(i).d1,
               lv_arr(i).d2,
               lv_arr(i).num1,
               lv_arr(i).str3,
               lv_arr(i).str4,
               lv_arr(i).cupon,
               service_id$i,
               lv_arr(i).active_from,
               lv_arr(i).active_to,
               'N');
      COMMIT;
    END prepare_data_2;

    /**
    * Заполнить рабочую таблицу для приложений, где более одной услуги в месяй миграции
    * @param task_id - Идентификатор записи в рабочей таблице
    * @Return Идентификатор записи в рабочей таблице
    */
    FUNCTION prepare_data4many_service(task_id$i IN PLS_INTEGER)
    RETURN PLS_INTEGER
    IS
      lv_res_id PLS_INTEGER;
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      lv_res_id := rias_mgr_task_seq.nextval;
      INSERT /*+ append */ INTO rias_mgr_tmp_list(task_id, str3, str4)
      SELECT lv_res_id , str3, str4
      FROM (SELECT t.str4, t.str3, COUNT(1) AS cnt
            FROM rias_mgr_tmp_list t
            WHERE task_id = task_id$i
            GROUP BY t.str4, t.str3)
      WHERE cnt > 1;
      COMMIT;
      RETURN lv_res_id;
    END prepare_data4many_service;

  BEGIN
    -- Сохранить первоначальное значение информации о сессии
    RIAS_MGR_CORE.save_session_state;
    -- Занести свою информацию в сессию
    dbms_application_info.set_module(module_name => 'FILL IDB_PH2_BPI_MRC_PRICEOVERRIDE',
                                     action_name => 'CLEAR TABLES');
    -- Зачистить таблицу
    -- TLO
    DELETE /*+ append */ /*select count(1)*/ FROM idb_ph2_bpi_mrc_priceoverride tab WHERE tab.fk_product_otc_bpi_idb LIKE 'TI_1/%'
    and phase = phase_id$i;

    fn_commit;

    -- SLO
    DELETE /*+ append */ /*select count(1)*/
    FROM idb_ph2_bpi_mrc_priceoverride tab
    WHERE (tab.fk_product_otc_bpi_idb LIKE 'SI_1/%'    OR
          tab.fk_product_otc_bpi_idb LIKE 'SIFD_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SIFI_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SISU_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SICF_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SIZD_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SIRTR_1/%' OR
          tab.fk_product_otc_bpi_idb LIKE 'SUS_TI_1/%')
          and tab.phase = phase_id$i;

    fn_commit;

    --===============================
    -- SLO
    --===============================
    dbms_application_info.set_action(action_name => 'SLO');
    -- Относится к "Для рассматриваемого BPI не предусмотрен Купон (Скидка)"
    INSERT /*+ append */ INTO idb_ph2_bpi_mrc_priceoverride(
      end_dat,
      fk_product_otc_bpi_idb,
      idb_id,
      override_amount,
      source_id,
      source_system,
      source_system_type,
      start_dat,
      phase
    )
    SELECT CASE
            WHEN slo.ext_bpi_status IN ('Active', 'Suspended') THEN
             NULL
            ELSE
             slo.actual_end_date
          END AS end_dat,
          slo.idb_id fk_product_otc_bpi_idb,
          'MPO_1_' /*|| TO_CHAR(rownum)|| '_'*/ || slo.idb_id idb_id,
          nvl(slo.mrc, 0) override_amount,
          slo.source_id source_id,
          slo.source_system source_system,
          slo.source_system_type source_system_type,
          slo.actual_start_date start_dat,
          slo.phase
    FROM idb_ph2_sbpi_int slo
    WHERE (1 = 1)
    and slo.phase = phase_id$i
      AND slo.source_system_type = '1'
      AND (slo.idb_id LIKE 'SI_1/%'   OR
           slo.idb_id LIKE 'SIFD_1/%' OR
           slo.idb_id LIKE 'SIFI_1/%' OR
           slo.idb_id LIKE 'SISU_1/%' OR
           slo.idb_id LIKE 'SICF_1/%' OR
           slo.idb_id LIKE 'SIZD_1/%' OR
           -- 27.07.2021 BikulovMD изменения, связанные с оборудованием.
           -- По оборудованию сейчас не создаем. Перекрутили справочники
           --slo.idb_id LIKE 'SIRTR_1/%' OR -- Роутер
           slo.idb_id LIKE 'SUS_TI_1/%')  -- Приостановки
      AND slo.off_id_for_migr IN (SELECT d.off_id_for_migr
                                  FROM idb_ph2_offerings_dic d
                                  WHERE d.idb_table_name = 'IDB_PH2_SBPI_INT'
                                    AND d.act_price_spec_nc_id IS NOT NULL
                                    AND d.no_charge IS NULL);

    fn_commit;

    --===============================
    -- TLO
    --===============================
    -- Подготовить данные для работы
    dbms_application_info.set_action(action_name => 'PREPARE_DATA');
    -- Заполним временную таблицу
    lv_task_id := prepare_data();
    -- Схлопним "повторяющиеся" записи
    -- Одинаковые IDB_ID с одинаковыми скидочными купонами,
    -- где одна историческая запись заканчивается и тут же начинается другая
    prepare_data_2(lv_task_id);
    -- Заполнить временную таблицу для приложений, где более одной услуги в месяй миграции
    lv_task_many_id := prepare_data4many_service(lv_task_id);
    -- Вывести номер
    dbms_output.put_line('lv_task_id = ' || TO_CHAR(lv_task_id));
    --
  /*
  Для рассматриваемого BPI не предусмотрен или отсутствует Купон (Скидка)
    В таком случае создаем искусственную запись в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE, где:
      - для активных и приостановленных BPI: IDB_PH2_BPI_MRC_PRICEOVERRIDE.START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и IDB_PH2_BPI_MRC_PRICEOVERRIDE.END_DAT = null.
      - для закрытых BPI: IDB_PH2_BPI_MRC_PRICEOVERRIDE.START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и IDB_PH2_BPI_MRC_PRICEOVERRIDE.END_DAT = IDB_PH2_%BPI_%.ACTUAL_END_DATE.
  */
    dbms_application_info.set_action(action_name => 'TLO/1');
    --
    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT,
      phase
    )
    SELECT (CASE WHEN t.ext_bpi_status IN ('Active','Suspended') THEN NULL ELSE t.actual_end_date END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         MRC,
         t.source_id,
         t.source_system,
         '1',
         t.actual_start_date,
         t.phase
  --SELECT count(1)
    FROM IDB_PH2_TBPI_INT t
    WHERE 1=1
    and t.phase = phase_id$i
      AND t.source_system_type = '1'
      AND t.idb_id LIKE 'TI_1/%'
      AND t.off_id_for_migr IN (SELECT d.off_id_for_migr
                                FROM IDB_PH2_OFFERINGS_DIC d
                                WHERE d.idb_table_name = 'IDB_PH2_TBPI_INT'
                                  AND d.act_price_spec_nc_id IS NOT NULL)
      -- Нет ссылки на услуги
      AND NOT EXISTS(SELECT 1
                     FROM plan_items_all pi,
                          activate_license_fee_all alf
                     WHERE alf.addendum_id = to_number(t.source_id)
                       AND alf.billing_id = to_number(t.source_system)
                       AND alf.active_from <= current_date
                       AND (alf.active_to IS NULL OR alf.active_to > trunc(current_date, 'mm'))
                       AND pi.plan_item_id = alf.plan_item_id
                       AND pi.billing_id = alf.billing_id
                       AND pi.service_id IN (1800, 102243, 102241, 101394, 101395, 101396, 101254, 103305, 103343)
                       AND rownum<=1);

    fn_commit;

  /*
  -- 2
  Для рассматриваемого BPI предусмотрен Купон (Скидка),
    и дата активации BPI совпадает с датой начала действия Купона (Скидки),
    а так же Купон (Скидка) активен на протяжении всего месяца миграции

  В таком случае создаем одну запись на основе купона, где:
    - для активных и приостановленных BPI: START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и END_DAT = null.
    - для закрытых BPI: START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и IDB_PH2_BPI_MRC_PRICEOVERRIDE.END_DAT = IDB_PH2_%BPI_%.ACTUAL_END_DATE.
  */
    dbms_application_info.set_action(action_name => 'TLO/2/A');

  /*
  t.idb_id            idb_id
  t.ext_bpi_status    STR2
  t.actual_start_date D1
  t.actual_end_date   D2
  t.mrc               NUM1
  t.source_id         STR3
  t.source_system     STR4
  alf.active_from     active_from
  alf.active_to       active_to
  */
    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT,
      phase
    )
    SELECT (CASE WHEN t.STR2 IN ('Active','Suspended') THEN NULL ELSE t.d2 END) AS END_DAT,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_2A_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         num1,
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
     FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from < TRUNC(current_date, 'mm')           -- Купон (Скидка) начинает действовать до месяца миграции
      AND (t.active_to is null or t.active_to > current_date) -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND t.active_from >= t.d1                               -- дата активации BPI совпадает или меньше даты начала действия Купона (Скидки)
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;
/*
    dbms_application_info.set_action(action_name => 'TLO/2/B');

    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT
    )
    SELECT (CASE WHEN t.STR2 IN ('Active','Suspended') THEN NULL ELSE t.d2 END) AS END_DAT,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_2B_' || TO_CHAR(rownum) ||'_'|| t.idb_id AS idb_id,
         num1,
         t.str3,
         t.str4,
         '1',
         t.d1
     FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from >= TRUNC(current_date, 'mm')          -- Купон (Скидка) начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date) -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND t.active_from >= t.d1;                              -- дата активации BPI совпадает или меньше даты начала действия Купона (Скидки)

    fn_commit;
*/
  /*
  -- 3
  Для рассматриваемого BPI предусмотрен Купон (Скидка):
  */
  /*
  a. Дата активации Купона (Скидки) больше, чем дата активации BPI:
     В таком случае мы создаем две записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE;
       1 запись. Создаем искусственную запись. За дату начала берем дату активации BPI, за дату окончания берем дату начала действия купона минус один день.
       2 запись. Создаем запись на основе Купона (Скидки).
  */
  -- 3.a.1
    dbms_application_info.set_action(action_name => 'TLO/3/A');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (t.active_from - 1) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3A1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, NULL, t.d1) * 100000 as mrc, -- Берем полную стоимость 237 услуги (с НДС)
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                              -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy') -- Купон начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date)               -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.a.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (case when t.str2 in ('Active','Suspended') then null else (t.active_to-1) end) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3A2_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                              -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy') -- Купон начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date)               -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  /*
  b. Дата активации Купона (Скидки) равна дате активации BPI и Купон (Скидка) прекращает свое действие в месяц миграции, а BPI остается активен

     В таком случае мы создаем две записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE:
       1 запись. Создаем запись на основе Купона (Скидки).
       2 запись. Создаем искусственную запись. За дату начала берем дату окончания действия купона. За дату окончания берем дату начала действия нового купона,
       либо дату окончания действия BPI.
  */

    dbms_application_info.set_action(action_name => 'TLO/3/B');
  -- 3.b.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
         (t.active_to -1),
--         (CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3B1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      --AND t.active_to-1 between TRUNC(current_date, 'mm') and last_day(TRUNC(current_date,'MM')) AND t.active_to < current_date
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.b.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3B2_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      --AND t.active_to-1 between TRUNC(current_date, 'mm') and last_day(TRUNC(current_date,'MM')) AND t.active_to < current_date
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  /*
  k. Дата активации Купона (Скидки) больше, чем дата активации BPI,
     Купон начинает действовать раньше месяца миграции,
     Купон (Скидка) прекращает свое действие в месяц миграции, а BPI остается активен

     В таком случае мы создаем две записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE:
       1 запись. Создаем запись на основе Купона (Скидки).
       2 запись. Создаем искусственную запись. За дату начала берем дату окончания действия купона. За дату окончания берем дату начала действия нового купона,
       либо дату окончания действия BPI.
  */

    dbms_application_info.set_action(action_name => 'TLO/3/K');
  -- 3.k.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
        (t.active_to -1),
        --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3K1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') <  to_char(current_date,'mmyyyy')       -- Купон начинает действовать раньше месяца миграции
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.k.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3K2_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') <  to_char(current_date,'mmyyyy')       -- Купон начинает действовать раньше месяца миграции
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  /*
  c. Дата активации Купона (Скидки) больше, чем дата активации BPI, Купон начинает действовать в месяц миграции и Купон (Скидка) прекращает свое действие в месяц миграции, а BPI остается активен

     В таком случае мы создаем три записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE:
       1 запись. Создаем искусственную запись. За дату начала берем дату активации BPI, за дату окончания берем дату начала действия купона минус один день.
       2 запись. Создаем запись на основе Купона (Скидки).
       3 запись. Создаем искусственную запись. За дату начала берем дату окончания действия купона. За дату окончания берем дату начала действия нового купона, либо дату окончания действия BPI.

  !Необходимо создавать записи в таблице  IDB_PH2_BPI_MRC_PRICEOVERRIDE таким образом, чтобы они покрывали собой весь период действия BPI. Если нет активного купона, должна быть создана искусственная запись, которая будет покрывать временной промежуток, когда не было активного купона.
  */
    dbms_application_info.set_action(action_name => 'TLO/3/С');
  -- 3.c.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (t.active_from - 1) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3C1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, NULL, t.d1) * 100000 as mrc, -- Берем полную стоимость 237 услуги (с НДС)
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')       -- Купон начинает действовать в месяц миграции
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.c.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
        (t.active_to -1),
        --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3C2_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')       -- Купон начинает действовать в месяц миграции
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.c.3
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3C3_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')       -- Купон начинает действовать в месяц миграции
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;


---------------------------------
/*
  -- 3.d.1 (на основе a))
    dbms_application_info.set_action(action_name => 'TLO/3/D');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat)
    SELECT (t.active_from - 1) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3D1_' || TO_CHAR(rownum) ||'_'|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1 -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')
      AND t.d2 < current_date;-- Закрытие BPI в месяц миграции

    fn_commit;

  -- 3.d.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat)
    SELECT (case when t.str2 in ('Active','Suspended') then null else t.d2 end) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3D2_' || TO_CHAR(rownum) ||'_'|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1 -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')--???
      AND t.d2 < current_date; -- BPI закрывается в месяц миграции

    fn_commit;
*/
    dbms_application_info.set_action(action_name => 'TLO/3/E');
  -- 3.e.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
         (t.active_to -1),
         --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3E1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.e.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3E2_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/3/F');
  -- 3.f.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (t.active_from - 1) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3F1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, NULL, t.d1) * 100000 as mrc, -- Берем полную стоимость 237 услуги (с НДС)
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.f.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
         (t.active_to -1),
         --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3F2_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

  -- 3.f.3
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_3F3_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/G');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_G_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                     -- Дата активации Купона (Скидки) равна дате активации BPI
      AND (t.active_to-1) = t.d2                                                   -- BPI закрывается вместе с купоном
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date  -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/I');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_I_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1, -- 19.02.2021 t.active_from BikulovMD (Валидация 9155045671413262028)
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                     -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND (t.active_to-1) = t.d2                                                   -- BPI закрывается вместе с купоном
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date  -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/J');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (case when t.str2 in ('Active','Suspended') then null else t.d2 end) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_J_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                              -- Дата активации Купона (Скидки) равна дате активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy') -- Купон начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date)               -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.str3 and tm.str4 = t.str4);

    fn_commit;

----===========================
-- для 2 и более купонов
    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT,
      phase
    )
    SELECT (CASE WHEN t.ext_bpi_status IN ('Active','Suspended') THEN NULL ELSE t.actual_end_date END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_1_' /*|| TO_CHAR(rownum) ||'_'*/|| t.idb_id AS idb_id,
         MRC,
         t.source_id,
         t.source_system,
         '1',
         t.actual_start_date,
         t.phase
  --SELECT count(1)
    FROM IDB_PH2_TBPI_INT t
    WHERE 1=1
    and t.phase = phase_id$i
      AND t.source_system_type = '1'
      AND t.idb_id LIKE 'TI_1/%'
      AND t.off_id_for_migr IN (SELECT d.off_id_for_migr
                                FROM IDB_PH2_OFFERINGS_DIC d
                                WHERE d.idb_table_name = 'IDB_PH2_TBPI_INT'
                                  AND d.act_price_spec_nc_id IS NOT NULL)
      AND EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.str3 = t.source_id and tm.str4 = t.source_system);

    fn_commit;
----===========================

    -- Очистить рабочие данные
    clear_tmp_data(ip_task_id => lv_task_id);
    clear_tmp_data(ip_task_id => lv_task_many_id);
  EXCEPTION
    WHEN OTHERS THEN
      IF lv_task_id IS NOT NULL THEN
        clear_tmp_data(ip_task_id => lv_task_id);
      END IF;
      IF lv_task_many_id IS NOT NULL THEN
        clear_tmp_data(ip_task_id => lv_task_many_id);
      END IF;
      RAISE_APPLICATION_ERROR(-20001, SUBSTR(dbms_utility.format_error_stack || dbms_utility.format_error_backtrace, 1, 2000));

  END fill_priceoverride_after_2_22;

  /**
  * Заполнить IDB_PH2_BPI_MRC_PRICEOVERRIDE
  * до V2.22
  */
  PROCEDURE fill_priceoverride_before_2_22
  IS
    -- Идентификатор записи в рабочей таблице
    lv_task_id PLS_INTEGER;
    -- Идентификатор записи в рабочей таблице для приложений, где более одной услуги в месяй миграции
    lv_task_many_id PLS_INTEGER;
    -- Флаг промежуточного COMMIT'а
    gv_commit BOOLEAN := TRUE;
    ------------------------------
    -- Делаем COMMIT если нужно
    ------------------------------
    PROCEDURE fn_commit
    IS
    BEGIN
      IF gv_commit THEN COMMIT; END IF;
    END fn_commit;
    ------------------------------
    -- Стоимости для оверрайдов
    ------------------------------
    /*
    FUNCTION get_cost_service(addendum_id$i  INTEGER,
                              billing_id$i   INTEGER,
                              service_id     INTEGER,
                              service_cup_id INTEGER DEFAULT NULL,
                              date$d         DATE DEFAULT rias_mgr_support.get_current_date(),
                              with_nds$i     INTEGER DEFAULT 1,-- 0/1
                              with_cupon     INTEGER DEFAULT 0 -- 0/1
    )
    RETURN NUMBER
    IS
      lv_res$n   NUMBER;
      lv_cost$n  NUMBER;
      lv_cupon$n NUMBER;
    BEGIN
      --IF (with_cupon = 1 AND service_cup_id) IS NULL THEN EXCEPTION...; END IF;
      lv_cost$n := rias_mgr_support.get_service_cost(addendum_id$i, NULL, billing_id$i, service_id, date$d, with_nds$i);
      IF with_cupon = 1 AND service_cup_id IS NOT NULL THEN
        lv_cupon$n := NVL(rias_mgr_support.get_cupon_4_service(addendum_id$i => addendum_id$i,
                                                               billing_id$i  => billing_id$i,
                                                               service_id$i  => service_cup_id,
                                                               date$d        => date$d), 0);
      END IF;
      lv_res$n := ROUND(lv_cost$n - lv_cost$n * lv_cupon$n/100, 2);
      RETURN lv_res$n;
    END;
    */
    ------------------------------
    -- Заполнить рабочую таблицу
    ------------------------------
    FUNCTION prepare_data
    RETURN PLS_INTEGER
    IS
      lv_res_id PLS_INTEGER;
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      lv_res_id := rias_mgr_task_seq.nextval;
      INSERT /*+ append */ INTO rias_mgr_tmp_list(task_id, str1, str2, d1, d2, num1, str3, str4, service_id, active_from, active_to)
      SELECT lv_res_id,           -- task_id
             t.idb_id,            -- str1
             t.ext_bpi_status,    -- str2
             TRUNC(t.actual_start_date), -- d1
             TRUNC(t.actual_end_date),   -- d2
             t.mrc,               -- num1
             t.source_id,         -- str3
             t.source_system,     -- str4
             pi.service_id,       -- service_id
             TRUNC(
               case
                 when alf.active_from < t.actual_start_date then
                   t.actual_start_date
                 else
                   alf.active_from
               end
             ) as active_from,     -- active_from
             TRUNC(alf.active_to)  -- active_to
       FROM idb_ph2_tbpi_int t,
            plan_items_all pi,
            activate_license_fee_all alf
      WHERE 1=1
      and t.phase = phase_id$i
        AND t.source_system_type = '1'
        AND t.idb_id LIKE 'TI_1/%'
        --AND t.idb_id = 'TI_1/241/1743010/5691918/23183'
        --AND t.idb_id = 'TI_1/1/6942221/11015429/152464'
        --AND t.idb_id = 'TI_1/1/6940215/10837387/275888'
        AND t.off_id_for_migr IN (SELECT d.off_id_for_migr
                                  FROM idb_ph2_offerings_dic d
                                  WHERE d.idb_table_name = 'IDB_PH2_TBPI_INT'
                                    AND d.act_price_spec_nc_id IS NOT NULL
                                    AND d.no_charge IS NULL)
        AND alf.addendum_id = to_number(t.source_id)
        AND alf.billing_id = to_number(t.source_system)
        AND alf.active_from <= current_date
        AND (alf.active_to IS NULL OR alf.active_to >= trunc(current_date, 'mm'))
        --
        AND pi.plan_item_id = alf.plan_item_id
        AND pi.billing_id = alf.billing_id
        -- А если несколько будет на 1 приложении? Что надо создавать записи для каждой услуги?
        AND pi.service_id IN (1800, 102243, 102241, 101394, 101395, 101396, 101254, 103305, 103343);
      COMMIT;
      RETURN lv_res_id;
    END prepare_data;

    /**
    * Заполнить рабочую таблицу для приложений, где более одной услуги в месяй миграции
    * @param task_id - Идентификатор записи в рабочей таблице
    * @Return Идентификатор записи в рабочей таблице
    */
    FUNCTION prepare_data4many_service(task_id$i IN PLS_INTEGER)
    RETURN PLS_INTEGER
    IS
      lv_res_id PLS_INTEGER;
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      lv_res_id := rias_mgr_task_seq.nextval;
      INSERT /*+ append */ INTO rias_mgr_tmp_list(task_id, addendum_id)
      SELECT lv_res_id , TO_NUMBER(str3)
      FROM (SELECT t.str3, COUNT(1) AS cnt
            FROM rias_mgr_tmp_list t
            WHERE task_id = task_id$i
            GROUP BY t.str3)
      WHERE cnt > 1;
      COMMIT;
      RETURN lv_res_id;
    END prepare_data4many_service;

  BEGIN
    -- Сохранить первоначальное значение информации о сессии
    RIAS_MGR_CORE.save_session_state;
    -- Занести свою информацию в сессию
    dbms_application_info.set_module(module_name => 'FILL IDB_PH2_BPI_MRC_PRICEOVERRIDE',
                                     action_name => 'CLEAR TABLES');
    -- Зачистить таблицу
    -- TLO
    DELETE /*+ append */ /*select count(1)*/ FROM idb_ph2_bpi_mrc_priceoverride tab WHERE tab.fk_product_otc_bpi_idb LIKE 'TI_1/%'
    and phase = phase_id$i;

    fn_commit;

    -- SLO
    DELETE /*+ append */ /*select count(1)*/
    FROM idb_ph2_bpi_mrc_priceoverride tab
    WHERE (tab.fk_product_otc_bpi_idb LIKE 'SI_1/%'    OR
          tab.fk_product_otc_bpi_idb LIKE 'SIFD_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SIFI_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SISU_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SICF_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SIZD_1/%'  OR
          tab.fk_product_otc_bpi_idb LIKE 'SIRTR_1/%' OR
          tab.fk_product_otc_bpi_idb LIKE 'SUS_TI_1/%')
          and tab.phase = phase_id$i;

    fn_commit;

    --===============================
    -- SLO
    --===============================
    dbms_application_info.set_action(action_name => 'SLO');
    -- Относится к "Для рассматриваемого BPI не предусмотрен Купон (Скидка)"
    INSERT /*+ append */ INTO idb_ph2_bpi_mrc_priceoverride(
      end_dat,
      fk_product_otc_bpi_idb,
      idb_id,
      override_amount,
      source_id,
      source_system,
      source_system_type,
      start_dat,
      phase
    )
    SELECT CASE
            WHEN slo.ext_bpi_status IN ('Active', 'Suspended') THEN
             NULL
            ELSE
             slo.actual_end_date
          END AS end_dat,
          slo.idb_id fk_product_otc_bpi_idb,
          'MPO_1_' || '_' || to_char(rownum)|| '_' || slo.idb_id idb_id,
          nvl(slo.mrc, 0) override_amount,
          slo.source_id source_id,
          slo.source_system source_system,
          slo.source_system_type source_system_type,
          slo.actual_start_date start_dat,
          slo.phase
    FROM idb_ph2_sbpi_int slo
    WHERE (1 = 1)
    and slo.phase = phase_id$i
      AND slo.source_system_type = '1'
      AND (slo.idb_id LIKE 'SI_1/%'   OR
           slo.idb_id LIKE 'SIFD_1/%' OR
           slo.idb_id LIKE 'SIFI_1/%' OR
           slo.idb_id LIKE 'SISU_1/%' OR
           slo.idb_id LIKE 'SICF_1/%' OR
           slo.idb_id LIKE 'SIZD_1/%' OR
           slo.idb_id LIKE 'SIRTR_1/%' OR -- Роутер
           slo.idb_id LIKE 'SUS_TI_1/%')  -- Приостановки
      AND slo.off_id_for_migr IN (SELECT d.off_id_for_migr
                                  FROM idb_ph2_offerings_dic d
                                  WHERE d.idb_table_name = 'IDB_PH2_SBPI_INT'
                                    AND d.act_price_spec_nc_id IS NOT NULL
                                    AND d.no_charge IS NULL);

    fn_commit;

    --===============================
    -- TLO
    --===============================
    -- Подготовить данные для работы
    dbms_application_info.set_action(action_name => 'PREPARE_DATA');
    -- Заполним временную таблицу
    lv_task_id := prepare_data();
    -- Заполнить временную таблицу для приложений, где более одной услуги в месяй миграции
    lv_task_many_id := prepare_data4many_service(lv_task_id);
    -- Вывести номер
    dbms_output.put_line('lv_task_id = ' || TO_CHAR(lv_task_id));
    --
  /*
  Для рассматриваемого BPI не предусмотрен или отсутствует Купон (Скидка)
    В таком случае создаем искусственную запись в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE, где:
      - для активных и приостановленных BPI: IDB_PH2_BPI_MRC_PRICEOVERRIDE.START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и IDB_PH2_BPI_MRC_PRICEOVERRIDE.END_DAT = null.
      - для закрытых BPI: IDB_PH2_BPI_MRC_PRICEOVERRIDE.START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и IDB_PH2_BPI_MRC_PRICEOVERRIDE.END_DAT = IDB_PH2_%BPI_%.ACTUAL_END_DATE.
  */
    dbms_application_info.set_action(action_name => 'TLO/1');
    --
    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT,
      phase
    )
    SELECT (CASE WHEN t.ext_bpi_status IN ('Active','Suspended') THEN NULL ELSE t.actual_end_date END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_1_' || TO_CHAR(rownum) ||'_'|| t.idb_id AS idb_id,
         MRC,
         t.source_id,
         t.source_system,
         '1',
         t.actual_start_date,
         t.phase
  --SELECT count(1)
    FROM IDB_PH2_TBPI_INT t
    WHERE 1=1
    and t.phase = phase_id$i
      AND t.source_system_type = '1'
      AND t.idb_id LIKE 'TI_1/%'
      AND t.off_id_for_migr IN (SELECT d.off_id_for_migr
                                FROM IDB_PH2_OFFERINGS_DIC d
                                WHERE d.idb_table_name = 'IDB_PH2_TBPI_INT'
                                  AND d.act_price_spec_nc_id IS NOT NULL)
      -- Нет ссылки на услуги
      AND NOT EXISTS(SELECT 1
                     FROM plan_items_all pi,
                          activate_license_fee_all alf
                     WHERE alf.addendum_id = to_number(t.source_id)
                       AND alf.billing_id = to_number(t.source_system)
                       AND alf.active_from <= current_date
                       AND (alf.active_to IS NULL OR alf.active_to > trunc(current_date, 'mm'))
                       AND pi.plan_item_id = alf.plan_item_id
                       AND pi.billing_id = alf.billing_id
                       AND pi.service_id IN (1800, 102243, 102241, 101394, 101395, 101396, 101254, 103305, 103343)
                       AND rownum<=1);

    fn_commit;

  /*
  -- 2
  Для рассматриваемого BPI предусмотрен Купон (Скидка),
    и дата активации BPI совпадает с датой начала действия Купона (Скидки),
    а так же Купон (Скидка) активен на протяжении всего месяца миграции

  В таком случае создаем одну запись на основе купона, где:
    - для активных и приостановленных BPI: START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и END_DAT = null.
    - для закрытых BPI: START_DAT = IDB_PH2_%BPI_%.ACTUAL_START_DATE и IDB_PH2_BPI_MRC_PRICEOVERRIDE.END_DAT = IDB_PH2_%BPI_%.ACTUAL_END_DATE.
  */
    dbms_application_info.set_action(action_name => 'TLO/2/A');

  /*
  t.idb_id            STR1
  t.ext_bpi_status    STR2
  t.actual_start_date D1
  t.actual_end_date   D2
  t.mrc               NUM1
  t.source_id         STR3
  t.source_system     STR4
  alf.active_from     active_from
  alf.active_to       active_to
  */
    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT,
      phase
    )
    SELECT (CASE WHEN t.STR2 IN ('Active','Suspended') THEN NULL ELSE t.d2 END) AS END_DAT,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_2A_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         num1,
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
     FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from < TRUNC(current_date, 'mm')           -- Купон (Скидка) начинает действовать до месяца миграции
      AND (t.active_to is null or t.active_to > current_date) -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND t.active_from >= t.d1                               -- дата активации BPI совпадает или меньше даты начала действия Купона (Скидки)
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;
/*
    dbms_application_info.set_action(action_name => 'TLO/2/B');

    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT
    )
    SELECT (CASE WHEN t.STR2 IN ('Active','Suspended') THEN NULL ELSE t.d2 END) AS END_DAT,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_2B_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         num1,
         t.str3,
         t.str4,
         '1',
         t.d1
     FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from >= TRUNC(current_date, 'mm')          -- Купон (Скидка) начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date) -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND t.active_from >= t.d1;                              -- дата активации BPI совпадает или меньше даты начала действия Купона (Скидки)

    fn_commit;
*/
  /*
  -- 3
  Для рассматриваемого BPI предусмотрен Купон (Скидка):
  */
  /*
  a. Дата активации Купона (Скидки) больше, чем дата активации BPI:
     В таком случае мы создаем две записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE;
       1 запись. Создаем искусственную запись. За дату начала берем дату активации BPI, за дату окончания берем дату начала действия купона минус один день.
       2 запись. Создаем запись на основе Купона (Скидки).
  */
  -- 3.a.1
    dbms_application_info.set_action(action_name => 'TLO/3/A');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (t.active_from - 1) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3A1_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, NULL, t.d1) * 100000 as mrc, -- Берем полную стоимость 237 услуги (с НДС)
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                              -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy') -- Купон начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date)               -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.a.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (case when t.str2 in ('Active','Suspended') then null else (t.active_to-1) end) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3A2_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                              -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy') -- Купон начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date)               -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  /*
  b. Дата активации Купона (Скидки) равна дате активации BPI и Купон (Скидка) прекращает свое действие в месяц миграции, а BPI остается активен

     В таком случае мы создаем две записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE:
       1 запись. Создаем запись на основе Купона (Скидки).
       2 запись. Создаем искусственную запись. За дату начала берем дату окончания действия купона. За дату окончания берем дату начала действия нового купона,
       либо дату окончания действия BPI.
  */

    dbms_application_info.set_action(action_name => 'TLO/3/B');
  -- 3.b.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
         (t.active_to -1),
--         (CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3B1_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      --AND t.active_to-1 between TRUNC(current_date, 'mm') and last_day(TRUNC(current_date,'MM')) AND t.active_to < current_date
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.b.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3B2_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      --AND t.active_to-1 between TRUNC(current_date, 'mm') and last_day(TRUNC(current_date,'MM')) AND t.active_to < current_date
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  /*
  k. Дата активации Купона (Скидки) больше, чем дата активации BPI,
     Купон начинает действовать раньше месяца миграции,
     Купон (Скидка) прекращает свое действие в месяц миграции, а BPI остается активен

     В таком случае мы создаем две записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE:
       1 запись. Создаем запись на основе Купона (Скидки).
       2 запись. Создаем искусственную запись. За дату начала берем дату окончания действия купона. За дату окончания берем дату начала действия нового купона,
       либо дату окончания действия BPI.
  */

    dbms_application_info.set_action(action_name => 'TLO/3/K');
  -- 3.k.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
        (t.active_to -1),
        --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3K1_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') <  to_char(current_date,'mmyyyy')       -- Купон начинает действовать раньше месяца миграции
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.k.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3K2_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') <  to_char(current_date,'mmyyyy')       -- Купон начинает действовать раньше месяца миграции
      AND (t.active_to-1) >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  /*
  c. Дата активации Купона (Скидки) больше, чем дата активации BPI, Купон начинает действовать в месяц миграции и Купон (Скидка) прекращает свое действие в месяц миграции, а BPI остается активен

     В таком случае мы создаем три записи в таблице IDB_PH2_BPI_MRC_PRICEOVERRIDE:
       1 запись. Создаем искусственную запись. За дату начала берем дату активации BPI, за дату окончания берем дату начала действия купона минус один день.
       2 запись. Создаем запись на основе Купона (Скидки).
       3 запись. Создаем искусственную запись. За дату начала берем дату окончания действия купона. За дату окончания берем дату начала действия нового купона, либо дату окончания действия BPI.

  !Необходимо создавать записи в таблице  IDB_PH2_BPI_MRC_PRICEOVERRIDE таким образом, чтобы они покрывали собой весь период действия BPI. Если нет активного купона, должна быть создана искусственная запись, которая будет покрывать временной промежуток, когда не было активного купона.
  */
    dbms_application_info.set_action(action_name => 'TLO/3/С');
  -- 3.c.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (t.active_from - 1) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3C1_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, NULL, t.d1) * 100000 as mrc, -- Берем полную стоимость 237 услуги (с НДС)
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')       -- Купон начинает действовать в месяц миграции
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.c.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
        (t.active_to -1),
        --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3C2_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')       -- Купон начинает действовать в месяц миграции
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.c.3
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3C3_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')       -- Купон начинает действовать в месяц миграции
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND (t.d2 IS NULL OR t.d2 > current_date)                                   -- BPI остается активен
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;


---------------------------------
/*
  -- 3.d.1 (на основе a))
    dbms_application_info.set_action(action_name => 'TLO/3/D');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat)
    SELECT (t.active_from - 1) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3D1_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1 -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')
      AND t.d2 < current_date;-- Закрытие BPI в месяц миграции

    fn_commit;

  -- 3.d.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat)
    SELECT (case when t.str2 in ('Active','Suspended') then null else t.d2 end) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3D2_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1 -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy')--???
      AND t.d2 < current_date; -- BPI закрывается в месяц миграции

    fn_commit;
*/
    dbms_application_info.set_action(action_name => 'TLO/3/E');
  -- 3.e.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
         (t.active_to -1),
         --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3E1_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.e.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3E2_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                    -- Дата активации Купона (Скидки) равна дате активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/3/F');
  -- 3.f.1
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (t.active_from - 1) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3F1_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, NULL, t.d1) * 100000 as mrc, -- Берем полную стоимость 237 услуги (с НДС)
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.f.2
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT
         (t.active_to -1),
         --(CASE WHEN t.str2 in ('Active','Suspended') THEN NULL ELSE t.d2 END) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3F2_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         rias_mgr_support.get_service_cost_override(to_number(t.str3), to_number(t.str4), 237, t.service_id, t.active_from, 1, 1) * 100000 as mrc, -- АП по сервису 237 * % купона * 100000
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

  -- 3.f.3
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_3F3_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_to,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                    -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND t.d2 < current_date                                                     -- BPI закрывается в месяц миграции
      AND t.d2 > (t.active_to-1)                                                  -- BPI закрывается позже купона
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/G');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_G_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.active_from,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                                     -- Дата активации Купона (Скидки) равна дате активации BPI
      AND (t.active_to-1) = t.d2                                                   -- BPI закрывается вместе с купоном
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date  -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/I');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT t.d2 AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_I_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1, -- 19.02.2021 t.active_from BikulovMD (Валидация 9155045671413262028)
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from > t.d1                                                     -- Дата активации Купона (Скидки) больше, чем дата активации BPI
      AND (t.active_to-1) = t.d2                                                   -- BPI закрывается вместе с купоном
      AND t.active_to >= TRUNC(current_date, 'mm') AND t.active_to < current_date  -- Купон (Скидка) прекращает свое действие в месяц миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

    dbms_application_info.set_action(action_name => 'TLO/J');
    INSERT INTO idb_ph2_bpi_mrc_priceoverride(
        end_dat,
        fk_product_otc_bpi_idb,
        idb_id,
        override_amount,
        source_id,
        source_system,
        source_system_type,
        start_dat,
        phase)
    SELECT (case when t.str2 in ('Active','Suspended') then null else t.d2 end) AS end_dat,
         t.str1 AS fk_product_otc_bpi_idb,
         'MPO_J_' || TO_CHAR(rownum) ||'_'|| t.str1 AS idb_id,
         t.num1,
         t.str3,
         t.str4,
         '1',
         t.d1,
         phase_id$i
    FROM rias_mgr_tmp_list t
    WHERE 1=1
      AND t.task_id = lv_task_id
      AND t.active_from = t.d1                                              -- Дата активации Купона (Скидки) равна дате активации BPI
      AND to_char(t.active_from,'mmyyyy') =  to_char(current_date,'mmyyyy') -- Купон начинает действовать в месяц миграции
      AND (t.active_to is null or t.active_to > current_date)               -- Купон (Скидка) активен на протяжении всего месяца миграции
      AND NOT EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.str3);

    fn_commit;

----===========================
-- для 2 и более купонов
    INSERT INTO IDB_PH2_BPI_MRC_PRICEOVERRIDE(
      END_DAT,
      FK_PRODUCT_OTC_BPI_IDB,
      IDB_ID,
      OVERRIDE_AMOUNT,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      START_DAT,
      phase
    )
    SELECT (CASE WHEN t.ext_bpi_status IN ('Active','Suspended') THEN NULL ELSE t.actual_end_date END) AS end_dat,
         t.idb_id AS fk_product_otc_bpi_idb,
         'MPO_1_' || TO_CHAR(rownum) ||'_'|| t.idb_id AS idb_id,
         MRC,
         t.source_id,
         t.source_system,
         '1',
         t.actual_start_date,
         t.phase
  --SELECT count(1)
    FROM IDB_PH2_TBPI_INT t
    WHERE 1=1
    and t.phase = phase_id$i
      AND t.source_system_type = '1'
      AND t.idb_id LIKE 'TI_1/%'
      AND t.off_id_for_migr IN (SELECT d.off_id_for_migr
                                FROM IDB_PH2_OFFERINGS_DIC d
                                WHERE d.idb_table_name = 'IDB_PH2_TBPI_INT'
                                  AND d.act_price_spec_nc_id IS NOT NULL)
      AND EXISTS(SELECT 1 FROM rias_mgr_tmp_list tm WHERE tm.task_id = lv_task_many_id and tm.addendum_id = t.source_id);

    fn_commit;
----===========================

    -- Очистить рабочие данные
    clear_tmp_data(ip_task_id => lv_task_id);
    clear_tmp_data(ip_task_id => lv_task_many_id);
  EXCEPTION
    WHEN OTHERS THEN
      IF lv_task_id IS NOT NULL THEN
        clear_tmp_data(ip_task_id => lv_task_id);
      END IF;
      IF lv_task_many_id IS NOT NULL THEN
        clear_tmp_data(ip_task_id => lv_task_many_id);
      END IF;
      RAISE_APPLICATION_ERROR(-20001, SUBSTR(dbms_utility.format_error_stack || dbms_utility.format_error_backtrace, 1, 2000));
  END fill_priceoverride_before_2_22;

  /**
  * Заполнить IDB_PH2_BPI_MRC_PRICEOVERRIDE
  */
  PROCEDURE fill_priceoverride
  IS
  BEGIN
    IF rias_mgr_core.get_feature_toggle(6) = 0 THEN
      fill_priceoverride_before_2_22;
    ELSE
      fill_priceoverride_after_2_22;
    END IF;
  END;

  /**
  * Очистить данные для обработки IDB_PH2_ACCESS_CRED
  */
  PROCEDURE clear_access_cred
  IS
  BEGIN
    -- Сбросить ACCESS_CRED_TBPI_INT в IDB_PH2_TBPI_INT
    UPDATE /*+ append */ idb_ph2_tbpi_int s set s.access_cred_tbpi_int = NULL
    WHERE 1=1
    and s.phase = phase_id$i
      and s.idb_id like 'TI_1/%'
      and access_cred_tbpi_int is not null;
    -- Удаляем продукт Интернет TLO
    DELETE /*+ append */ FROM idb_ph2_access_cred ac WHERE ac.bpi_idb_id like 'TI_1/%' and ac.phase = phase_id$i;
    COMMIT;
    -- Сбросить ACCESS_CRED_PPPOE_ACC в IDB_PH2_SBPI_INT
    UPDATE /*+ append */ idb_ph2_sbpi_int s SET s.access_cred_pppoe_acc = NULL
    WHERE 1=1 and s.phase = phase_id$i and s.off_id_for_migr = '121000087' AND (idb_id LIKE 'SI_1/%' OR idb_id LIKE 'SIFI_1/%') AND access_cred_pppoe_acc IS NOT NULL;
    -- Удаляем продукт Интернет SLO
    DELETE /*+ append */ FROM idb_ph2_access_cred ac WHERE 1=1 and ac.phase = phase_id$i and (ac.bpi_idb_id LIKE 'SI_1/%' OR ac.bpi_idb_id LIKE 'SIFI_1/%');
    COMMIT;

    --=============
    --Контент-фильтрация
    --=============
    -- Сбросить ACCESS_CRED_PPPOE_ACC в IDB_PH2_SBPI_INT
    UPDATE /*+ append */ idb_ph2_sbpi_int s SET s.access_cred = NULL
    WHERE 1=1 and s.phase = phase_id$i and s.off_id_for_migr = '121000021' AND (idb_id LIKE 'SI_1/%' OR idb_id LIKE 'SICF_1/%') AND access_cred IS NOT NULL;
    -- Удаляем продукты Интернет SLO
    DELETE /*+ append */ FROM idb_ph2_access_cred ac WHERE ac.phase = phase_id$i and (ac.bpi_idb_id LIKE 'SI_1/%' OR ac.bpi_idb_id LIKE 'SICF_1/%');
    COMMIT;

  END clear_access_cred;

  /**
  * Заполнить таблицу IDB_PH2_ACCESS_CRED
  *   1. Очистить
  *   2. Очистить ссылки на AC из таблиц IDB_PH2_TBPI_INT и IDB_PH2_SBPI_INT
  *   2. Заполнить
  */
/*
  PROCEDURE fill_access_cred
  IS
    lv_task_tbi_id NUMBER;
    lv_task1_id NUMBER;
    lv_task2_id NUMBER;
  BEGIN
    lv_task_tbi_id := rias_mgr_task_seq.nextval;
    --
    INSERT \*+ append *\ INTO rias_mgr_tmp_list (task_id, str1, addendum_id, billing_id, str3, str4, str5)
    SELECT lv_task_tbi_id as task_id,
           tbpi.idb_id as str1,
           TO_NUMBER(tbpi.source_id) as addendum_id,
           TO_NUMBER(tbpi.source_system) as billing_id,
           tbpi.auth_type as str3,
           (SELECT b.eab_id
            FROM idb_ph2_customer_location cl,
                 rias_customer_location_ext b
            WHERE 1=1
              AND tbpi.customer_location = cl.idb_id
              AND b.customer_location = cl.idb_id) AS str4,--address_unit_id
           tbpi.service_id as str5
    FROM idb_ph2_offers_oss_dic    dic,
         idb_ph2_tbpi_int          tbpi
    WHERE 1 = 1
      AND dic.migration_category = 'Интернет'
      AND dic.creds_mandatory IN ('Yes', 'Major', 'Minor')
      AND tbpi.source_system_type = '1'
      AND tbpi.idb_id LIKE 'TI_1/%'
      AND tbpi.auth_type = 'PPPoE'
      AND tbpi.off_id_for_migr = dic.off_id_for_migr;
    COMMIT;

    ---------- Подготовим TLO + SLO
    lv_task1_id := rias_mgr_task_seq.nextval;

    INSERT \*+ append *\ INTO rias_mgr_tmp_list(task_id, addendum_id, billing_id, str1, str2, str3, str4, num1)
    SELECT lv_task1_id,
           addendum_id,
           billing_id,
           idb_id,
           address_unit_id,
           service_id,
           auth_type,
           rnum
    FROM (
      SELECT idb_id, service_id, auth_type, addendum_id, billing_id, address_unit_id, row_number() over (partition by billing_id, addendum_id order by billing_id, addendum_id,nm) rnum
      FROM (
              SELECT t.str1 as idb_id, t.str5 as service_id, t.str3 as auth_type, t.addendum_id, t.billing_id, t.str4 as address_unit_id, 1 nm
              FROM rias_mgr_tmp_list t
              WHERE task_id = lv_task_tbi_id
              --
              UNION ALL
              --
              SELECT sbpi.idb_id, sbpi.service_id, sbpi.auth_type, t.addendum_id, t.billing_id, t.str4 as address_unit_id, 2 nm
              FROM rias_mgr_tmp_list t,
                   idb_ph2_sbpi_int sbpi
              WHERE 1 = 1
              AND t.task_id = lv_task_tbi_id
              AND sbpi.parent_id = t.str1
              AND sbpi.source_system = TO_CHAR(t.billing_id)
              AND sbpi.off_id_for_migr = '121000087'
      ) tbl
    );
    COMMIT;
    ---------- Подготовим Логины
    lv_task2_id := rias_mgr_task_seq.nextval;
    --
    INSERT \*+append *\ INTO rias_mgr_tmp_list (task_id, addendum_id, billing_id, str1, str2, id1, num1)
    SELECT lv_task2_id,
           addendum_id,
           billing_id,
           login_name,
           login_password,
           terminal_resource_id,
           rnum
    FROM(
      SELECT lo.login_name,
             lo.terminal_resource_id,
             lo.login_password,
             t.addendum_id,
             t.billing_id,
             row_number() OVER (PARTITION BY ar.billing_id, ar.addendum_id ORDER BY ar.billing_id, ar.addendum_id, lo.login_name) rnum
         FROM rias_mgr_tmp_list      t,
              addendum_resources_all ar,
              resource_contents_all  rc,
              logins_all             lo
        WHERE 1 = 1
          AND t.task_id = lv_task_tbi_id
          AND ar.addendum_id = t.addendum_id
          AND ar.billing_id = t.billing_id
          AND ar.active_from <= current_date
          AND (ar.active_to IS NULL OR ar.active_to > current_date)
          AND rc.resource_id = ar.resource_id
          AND rc.billing_id = ar.billing_id
          AND rc.active_from <= current_date
          AND (rc.active_to IS NULL OR rc.active_to > current_date)
          AND lo.terminal_resource_id = rc.terminal_resource_id
          AND lo.billing_id = rc.billing_id
    );
    COMMIT;
    -- Окончательная вставка
    INSERT \*+ append *\ INTO IDB_PH2_ACCESS_CRED(
       account_name,
       address_unit_id,
       bpi_idb_id,
       bss_service_id,
       client_domain,
       client_login,
       client_password,
       client_pin,
       credential_type,
       description,
       idb_id,
       name,
       source_id,
       source_system,
       source_system_type
     )
     SELECT NULL AS account_name,
            t1.str2 as address_unit_id,
            t1.str1 AS bpi_idb_id,
            t1.str3 AS bss_service_id,
            NULL AS client_domain,
            t2.str1 AS client_login,
            t2.str2 AS client_password,
            NULL AS client_pin,
            t1.str4 AS credential_type,
            NULL AS description,
            'AC_1/' || t1.str1 AS idb_id,
            t1.str3 || '-' || to_char(rownum) AS name,
            to_char(t2.id1) as source_id,
            to_char(t1.billing_id) as source_system,
            '1' as source_system_type
    FROM rias_mgr_tmp_list t1
    JOIN rias_mgr_tmp_list t2 on t1.addendum_id = t2.addendum_id and t1.billing_id = t2.billing_id and t1.num1 = t2.num1
    WHERE t1.task_id = lv_task1_id
      AND t2.task_id = lv_task2_id;
    -- Очистить временную таблицу
    clear_tmp_data(ip_task_id => lv_task_tbi_id);
    clear_tmp_data(ip_task_id => lv_task1_id);
    clear_tmp_data(ip_task_id => lv_task2_id);
  END fill_access_cred;
*/

  PROCEDURE fill_access_cred
  IS
    lv_credential_type_default$c VARCHAR2(200);
  BEGIN
    -- Считаем параметр
    lv_credential_type_default$c := rias_mgr_support.get_mgr_string_parameter(mgr_prmt_id$i => 5);
    --организуем цикл по городам
    FOR city_cr IN (SELECT to_char(city_id) city_id
                    FROM idb_ph1_city_dic
                    --WHERE city_id = 1
    ) LOOP

        INSERT /*+ append */ INTO IDB_PH2_ACCESS_CRED(
           account_name,
           address_unit_id,
           bpi_idb_id,
           bss_service_id,
           client_domain,
           client_login,
           client_password,
           client_pin,
           credential_type,
           description,
           idb_id,
           name,
           source_id,
           source_system,
           source_system_type,
           phase
          )
      with cr as (
        SELECT tbpi.rowid cr_row,
              tbpi.idb_id,
              tbpi.auth_type,
              (SELECT b.eab_id
               FROM idb_ph2_customer_location cl,
                    rias_customer_location_ext b
               WHERE 1=1
                 AND tbpi.customer_location = cl.idb_id
                 AND b.customer_location = cl.idb_id) AS address_unit_id,
              tbpi.service_id,
              tbpi.source_id,
              tbpi.source_system,
              tbpi.source_system_type,
              tbpi.phase
         FROM idb_ph2_offers_oss_dic    dic,
              idb_ph2_tbpi_int          tbpi
        WHERE 1 = 1
        and tbpi.phase = phase_id$i
          AND dic.migration_category in ('Интернет', 'Корпоративный Интернет')
          -- bikulovMD 04.12.2020 Добавил, что '121000296' берем всегда
          AND (dic.creds_mandatory IN ('Yes', 'Major', 'Minor') or dic.off_id_for_migr = '121000296')
          AND tbpi.source_system = city_cr.city_id
          AND tbpi.source_system_type = '1'
          AND tbpi.idb_id LIKE 'TI_1/%'
          AND tbpi.auth_type IN ('PPPoE', 'IPoE')
          AND tbpi.off_id_for_migr = dic.off_id_for_migr
        )
          SELECT /*+ use_hash(bpi) */
                 NULL AS account_name,
                 bpi.address_unit_id,
                 bpi.idb_id AS bpi_idb_id,
                 bpi.service_id AS bss_service_id,
                 NULL AS client_domain,
                 lg.login_name AS client_login,
                 lg.login_password AS client_password,
                 NULL AS client_pin,
                 NVL(lv_credential_type_default$c, bpi.auth_type) AS credential_type,
                 NULL AS description,
                 'AC_1/' || bpi.idb_id AS idb_id,
                 bpi.service_id || '-' || to_char(rownum) AS name,
                 --to_char(bpi.addendum_id) || '/' || lg.login_name as source_id,
                 to_char(lg.terminal_resource_id) as source_id,
                 city_cr.city_id,
                 '1',
                 bpi.phase
        FROM
        --A.Kosterin 19.08.2021 изменение row_num шаг2
        (SELECT idb_id, service_id, auth_type, addendum_id, address_unit_id, 
        row_number() over (partition by addendum_id, source_system order by sbpi_rowid) rnum, phase
          from (
                  SELECT (SELECT rowid FROM dual) as sbpi_rowid, cr.idb_id, cr.service_id, cr.auth_type, to_number(cr.source_id) as addendum_id, 
                  source_system, address_unit_id, 1 nm, phase
                  FROM cr
                  --
                  UNION ALL
                  --
                  select sbpi.rowid as sbpi_rowid, sbpi.idb_id, sbpi.service_id, sbpi.auth_type, to_number(cr.source_id) as addendum_id, 
                  sbpi.source_system, address_unit_id, 2 nm, cr.phase
                  from idb_ph2_sbpi_int sbpi,
                       cr
                  where 1 = 1
                  and sbpi.parent_id = cr.idb_id
                  and sbpi.phase = phase_id$i
                  and sbpi.source_system = cr.source_system
                  and sbpi.off_id_for_migr in ('121000087', '121000102') --20.09.2021 add '121000102'
          )
        ) bpi,
        /*(
          SELECT idb_id, service_id, auth_type, addendum_id, address_unit_id, row_number() over (partition by addendum_id order by nm) rnum
          from (
                  SELECT cr.idb_id, cr.service_id, cr.auth_type, to_number(cr.source_id) as addendum_id, address_unit_id, 1 nm
                  FROM cr
                  --
                  UNION ALL
                  --
                  select sbpi.idb_id, sbpi.service_id, sbpi.auth_type, to_number(cr.source_id) as addendum_id, address_unit_id, 2 nm
                  from idb_ph2_sbpi_int sbpi,
                       cr
                  where 1 = 1
                  and sbpi.parent_id = cr.idb_id
                  and sbpi.source_system = cr.source_system
                  and sbpi.off_id_for_migr = '121000087'
          )
        ) bpi,*/
        (
                 SELECT lo.login_name, lo.terminal_resource_id,
                         lo.login_password,
                         ar.addendum_id,
                         row_number() over (PARTITION BY ar.addendum_id ORDER BY lo.login_name) rnum
                    FROM addendum_resources_all ar,
                         resource_contents_all  rc,
                         logins_all             lo,
                         cr
                   WHERE 1 = 1
                     AND ar.billing_id = cr.source_system
                     AND ar.addendum_id = cr.source_id
                     AND ar.active_from <= current_date
                     AND (ar.active_to IS NULL OR ar.active_to > current_date)
                     AND rc.resource_id = ar.resource_id
                     AND rc.billing_id = ar.billing_id
                     AND rc.active_from <= current_date
                     AND (rc.active_to IS NULL OR rc.active_to > current_date)
                     AND lo.terminal_resource_id = rc.terminal_resource_id
                     AND lo.billing_id = rc.billing_id
        ) lg
        WHERE bpi.addendum_id = lg.addendum_id
          and bpi.rnum = lg.rnum;
        COMMIT;
    END LOOP;
  END fill_access_cred;

  /**
  * Заполнение IDB_PH2_ACCESS_CRED для SkyDNS
  */
  PROCEDURE fill_access_cred_skydns
  IS
    CURSOR cr IS
      SELECT NULL AS account_name,
             (SELECT b.eab_id
                FROM idb_ph2_customer_location  cl,
                     rias_customer_location_ext b
               WHERE 1 = 1
                 AND t.customer_location = cl.idb_id
                 AND b.customer_location = cl.idb_id) AS address_unit_id,
             s.idb_id AS bpi_idb_id,
             s.service_id AS bss_service_id,
             NULL AS client_domain,
             lo.login_name AS client_login,
             lo.password AS client_password,
             NULL AS client_pin,
             'SkyDNS' AS credential_type,
             NULL AS description,
             'AC_1/' || s.idb_id || '/' || lo.login_name AS idb_id,
             s.service_id || '-' || to_char(rownum) AS NAME,
             --to_char(bpi.addendum_id) || '/' || lg.login_name as source_id,
             rias_mgr_source_id_revers_seq.nextval /*to_char(lo.terminal_resource_id)*/ AS source_id,
             s.source_system,
             '1' source_system_type,
             t.phase
        FROM idb_ph2_sbpi_int       s,
             idb_ph2_tbpi_int       t,
             addendum_resources_all ar,
             resource_contents_all  rc,
             skydns_logins_all      lo
       WHERE 1 = 1
       and s.phase = phase_id$i
         AND s.source_system_type = '1'
         AND s.off_id_for_migr = '121000021'
         AND s.parent_id = t.idb_id
         AND t.source_system_type = '1'
         AND t.idb_id LIKE 'TI_1/%'
         AND ar.billing_id = t.source_system
         AND ar.addendum_id = t.source_id
         AND ar.active_from <= current_date
         AND (ar.active_to IS NULL OR ar.active_to > current_date)
         AND rc.resource_id = ar.resource_id
         AND rc.billing_id = ar.billing_id
         AND rc.active_from <= current_date
         AND (rc.active_to IS NULL OR rc.active_to > current_date)
         AND lo.terminal_resource_id = rc.terminal_resource_id
         AND lo.billing_id = rc.billing_id;
    TYPE t_arr IS TABLE OF cr%ROWTYPE;
    lv_arr t_arr;
  BEGIN
    OPEN cr;
    LOOP
      FETCH cr BULK COLLECT INTO lv_arr LIMIT 5000;
      EXIT WHEN lv_arr.count = 0;

      FORALL i IN 1 .. lv_arr.count
        INSERT INTO idb_ph2_access_cred
          (account_name,
           address_unit_id,
           bpi_idb_id,
           bss_service_id,
           client_domain,
           client_login,
           client_password,
           client_pin,
           credential_type,
           description,
           idb_id,
           NAME,
           source_id,
           source_system,
           source_system_type,
           phase)
        VALUES
          (lv_arr(i).account_name,
           lv_arr(i).address_unit_id,
           lv_arr(i).bpi_idb_id,
           lv_arr(i).bss_service_id,
           lv_arr(i).client_domain,
           lv_arr(i).client_login,
           lv_arr(i).client_password,
           lv_arr(i).client_pin,
           lv_arr(i).credential_type,
           lv_arr(i).description,
           lv_arr(i).idb_id,
           lv_arr(i).name,
           lv_arr(i).source_id,
           lv_arr(i).source_system,
           lv_arr(i).source_system_type,
           lv_arr(i).phase);
      --dbms_output.put_line(sql%rowcount);
      FORALL i IN 1 .. lv_arr.count
        UPDATE idb_ph2_sbpi_int s SET s.access_cred = lv_arr(i).idb_id
         WHERE s.idb_id = lv_arr(i).bpi_idb_id and s.phase = lv_arr(i).phase;
      --dbms_output.put_line(sql%rowcount);
    END LOOP;
    CLOSE cr;
  EXCEPTION
    WHEN OTHERS THEN
      IF cr%ISOPEN THEN
        CLOSE cr;
      END IF;
      RAISE_APPLICATION_ERROR(-20001, rias_mgr_support.get_error_stack);
  END fill_access_cred_skydns;

  /**
  * Заполнить таблицу IDB_PH2_NET_ACCESS
  *   1. Очистить
  *   2. Заполнить
  */
  PROCEDURE fill_net_access
  IS
    v_idb_id varchar2(150);
    v_ipv6 varchar2(150);
    v_nat varchar2(5) := 'Нет';
    v_auth_type varchar2(200);
    v_mac varchar(200);
    lv_idb_PRODUCTSTATUS      VARCHAR2(150);
    lv_num_lines$n                 NUMBER;
    lv_sys_guid               VARCHAR2(32);
    lv_cnt                    NUMBER := 0;
    lv_cnt_for_com            PLS_INTEGER;
    lv_ACTUAL_START_DATE_24$d DATE;
    lv_ACTUAL_START_DATE_16$d DATE;
    --09.12.2021 A.Kostein для вставки 4
    lv_elap_time_start number;
    lv_flag_date PLS_INTEGER;
     
  begin
  --удаляем продукты Интернет
  delete /*+ parallel (na,4)*/ from idb_ph2_net_access na where substr(idb_id,1,6) = 'NEA_TI' and phase = phase_id$i;
  lv_elap_time_start := dbms_utility.get_time;
  execute immediate 'truncate table aak_tmp_for_interzet_ipoe';
  insert into aak_tmp_for_interzet_ipoe SELECT * FROM aak_for_interzet_ipoe where CNT_ALL_IP < 5; --for aak_test_get_interzet; aak_for_interzet_ipoe - view
  ----
  select NVL2((SELECT navi_date  FROM aak_tmp_for_interzet_ip 
  where navi_date = TRUNC(SYSDATE) FETCH NEXT 1 ROWS ONLY), 1, 0) 
  into lv_flag_date from dual;
  ----
    --IF lv_flag_date = 0 THEN
    IF 1=1 THEN
    EXECUTE IMMEDIATE 'truncate table aak_tmp_for_interzet_ip';
    insert into aak_tmp_for_interzet_ip
    SELECT ar.ADDENDUM_ID, i.*, trunc(sysdate) FROM excellent.ADDENDUM_RESOURCES_ALL       AR,
           excellent.RESOURCE_CONTENTS_ALL        RC,
           excellent.IP_FOR_DEDICATED_CLIENTS_ALL I,
           aak_tmp_for_interzet_ipoe ai
    WHERE  1 = 1
    AND    RC.RESOURCE_ID = AR.RESOURCE_ID
    AND    RC.BILLING_ID = AR.BILLING_ID
    AND    COALESCE(RC.ACTIVE_TO, current_date + 1) > current_date
    AND    RC.ACTIVE_FROM <= current_date
    AND    coalesce(ar.active_to, current_date + 1) >= current_date
    AND    ar.active_from <= current_date
    AND    I.TERMINAL_RESOURCE_ID = RC.TERMINAL_RESOURCE_ID
    AND    I.BILLING_ID = RC.BILLING_ID
    AND    ai.billing_id = ar.billing_id
    AND    ai.addendum_id = ar.addendum_id;
  END IF;
  commit;
  
  -- insert into idb_ph2_net_access
begin
  fill_net_access_chain.start_chains;
end;



    --Вычисляем NAT
    merge into idb_ph2_net_access dest
    using (
    select /*+ USE_HASH(r) */
    r.rowid cr_row, nvl2(max(p.prop_value), 'Да', 'Нет') nat_val
    from idb_ph2_net_access r
    , cable_city_term_res_props_all p
    where r.phase = phase_id$i and substr(r.idb_id,1,6) = 'NEA_TI'
    and service_credentials is not null
    and p.billing_id(+) = r.source_system
    and p.terminal_resource_id(+) = r.nat
    and p.prop_id(+) = 16
    and coalesce(p.active_to(+), current_date + 1) > current_date
    group by r.rowid
    ) sour on (dest.rowid = sour.cr_row)
    when matched then update set dest.nat = sour.nat_val
    ;
    commit;
    

  
    merge into idb_ph2_net_access dest
    using (
    select net.rowid cr_row, ip.source_id
    from idb_ph2_net_access net,
    (select idb_id, source_id from idb_ph2_ip_v4address
    union all
    select idb_id, source_id from idb_ph2_ip_v4address_private) ip
    where net.phase = phase_id$i and substr(net.idb_id,1,6) = 'NEA_TI'
    and net.assigned_ipv4addresses = ip.idb_id
    ) sour on (dest.rowid = sour.cr_row)
    when matched then update set dest.source_id = sour.source_id;

    commit;



    -- V4Subnet
    merge into idb_ph2_net_access dest
    using (
    select net.rowid cr_row, ip.source_id
    from idb_ph2_net_access net,
    (select idb_id, source_id from idb_ph2_ip_v4range
    union all
    select idb_id, source_id from idb_ph2_ip_v4range_private) ip
    where net.phase = phase_id$i and substr(net.idb_id,1,6) = 'NEA_TI'
    and net.assigned_ipv4addresses = ip.idb_id
    ) sour on (dest.rowid = sour.cr_row)
    when matched then update set dest.source_id = sour.source_id;



    -- V6Subnet
    merge into idb_ph2_net_access dest
    using (
    select net.rowid cr_row, ip.source_id
    from idb_ph2_net_access net,
    (select idb_id, source_id from idb_ph2_ip_v6range) ip
    where net.phase = phase_id$i and substr(net.idb_id,1,6) = 'NEA_TI'
    and net.assigned_ipv6addresses = ip.idb_id
    ) sour on (dest.rowid = sour.cr_row)
    when matched then update set dest.source_id = sour.source_id;

/*  lv_elap_time_start := DBMS_UTILITY.GET_TIME-lv_elap_time_start;
  insert into aak_time_fill(phase, navi_date, time_elap_min, block_number) 
  select phase_id$i, sysdate, lv_elap_time_start, 6 from dual;
  lv_elap_time_start := dbms_utility.get_time;
*/












--20.04.2021 NEW NET_ACCESS DNS
begin
--1 Шаг
for rec in (select t.addendum_id,t.source_system,t.idb_id,t.primary_dns from (
select (case
when n.bpi_idb_id like 'SI%' then 
  (select source_id from idb_ph2_tbpi_int inta where inta.idb_id = (select parent_id from idb_ph2_sbpi_int sinta where sinta.phase = phase_id$i and sinta.idb_id = n.bpi_idb_id))
  else (select rate_plan_code from idb_ph2_tbpi_int inta where inta.idb_id = n.bpi_idb_id)
end) addendum_id,n.* from idb_ph2_net_access n 
where n.phase = phase_id$i and (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') and n.vlan is null
and (n.assigned_ipv4addresses is not null or n.assigned_ipv6addresses is not null)) t
where exists
(select 1 from ACTIVATE_LICENSE_FEE_ALL ALF,PLAN_ITEMS_ALL PI
where 
alf.addendum_id = t.addendum_id and alf.billing_id = t.source_system
AND ALF.ACTIVE_FROM <= CURRENT_DATE
AND COALESCE(ALF.ACTIVE_TO, CURRENT_DATE + 1) > CURRENT_DATE
AND PI.PLAN_ITEM_ID = ALF.PLAN_ITEM_ID
AND PI.BILLING_ID = ALF.BILLING_ID
AND PI.SERVICE_ID IN (101171,101170,101161,101169))) loop
  update idb_ph2_net_access n set n.primary_dns = '193.58.251.251',n.secondary_dns = '193.58.251.251' 
  where n.phase = phase_id$i
  and idb_id = rec.idb_id;
end loop;

--https://kb.ertelecom.ru/pages/viewpage.action?spaceKey=Netcracker&title=10.02.49.02+DNS
--A.Kosterin 16.12.2021 шаг 3 должен идти перед 2.1/2.2 т.к. 
--апдейтит основную часть 556 billing_id и в последующих шагах проходит по POOL_TYPE_ID

--3 шаг для 556 billing_id
update idb_ph2_net_access n set 
n.primary_dns = 
(select attr_value from excellent.cable_city_attr_pool_values_all where attr_pool_id = 8 and attr_id = 31 and billing_id = n.source_system),
n.secondary_dns = 
(select attr_value from excellent.cable_city_attr_pool_values_all where attr_pool_id = 8 and attr_id = 32 and billing_id = n.source_system)
where n.phase = phase_id$i and (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') 
and n.vlan is null
--днсы заполняются для всех записей и для IP, и для LOGIN
--and (n.assigned_ipv4addresses is not null or n.assigned_ipv6addresses is not null)
--and n.primary_dns is null 
and n.source_system in (556);

--2.1 шаг
UPDATE IDB_PH2_NET_ACCESS N SET
N.PRIMARY_DNS = '192.168.248.21',N.secondary_dns = '192.168.251.21'
where n.phase = phase_id$i 
and parent_id in (select 
n.parent_id from idb_ph2_net_access n ,IP_FOR_DEDICATED_CLIENTS_ALL I,CABLE_CITY_NET_IP_POOL_ALL PA
where n.phase = phase_id$i and (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') and n.vlan is null
and (n.assigned_ipv4addresses is not null or n.assigned_ipv6addresses is not null) 
--and n.primary_dns is null
and n.source_system = 556 and I.TERMINAL_RESOURCE_ID = 
(case
  when n.assigned_ipv4addresses in (select pr.idb_id from idb_ph2_ip_v4address_private pr where 
  pr.idb_id = n.assigned_ipv4addresses) then 
  (select source_id from idb_ph2_ip_v4address_private pr where 
  pr.idb_id = n.assigned_ipv4addresses)
  else (select source_id from idb_ph2_ip_v4address pub where 
  pub.idb_id = n.assigned_ipv4addresses)
end) and i.billing_id = n.source_system
and 
I.IP BETWEEN PA.IP_START(+) AND PA.IP_STOP(+)
AND PA.BILLING_ID(+) = I.BILLING_ID
AND PA.IP_START > 0 
AND PA.IP_STOP > 0 
AND PA.ACTIVE_FROM(+) <= CURRENT_DATE
AND COALESCE(PA.ACTIVE_TO(+), CURRENT_DATE + 1) > CURRENT_DATE
AND PA.POOL_TYPE_ID in(23,24));

--2.2 шаг
UPDATE IDB_PH2_NET_ACCESS N SET
N.PRIMARY_DNS = '188.134.0.21',N.secondary_dns = '188.134.64.21'
where n.phase = phase_id$i and parent_id in (select 
n.parent_id from idb_ph2_net_access n ,IP_FOR_DEDICATED_CLIENTS_ALL I,CABLE_CITY_NET_IP_POOL_ALL PA
where n.phase = phase_id$i and (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') and n.vlan is null
and (n.assigned_ipv4addresses is not null or n.assigned_ipv6addresses is not null) 
--and n.primary_dns is null
and n.source_system = 556 and I.TERMINAL_RESOURCE_ID = 
(case
when n.assigned_ipv4addresses in (select pr.idb_id from idb_ph2_ip_v4address_private pr where 
  pr.idb_id = n.assigned_ipv4addresses) 
  then (select source_id from idb_ph2_ip_v4address_private pr where 
  pr.idb_id = n.assigned_ipv4addresses)
  else (select source_id from idb_ph2_ip_v4address pub where 
  pub.idb_id = n.assigned_ipv4addresses)
end) and i.billing_id = n.source_system
and 
I.IP BETWEEN PA.IP_START(+) AND PA.IP_STOP(+)
AND PA.BILLING_ID(+) = I.BILLING_ID
AND PA.IP_START > 0 
AND PA.IP_STOP > 0 
AND PA.ACTIVE_FROM(+) <= CURRENT_DATE
AND COALESCE(PA.ACTIVE_TO(+), CURRENT_DATE + 1) > CURRENT_DATE
AND PA.POOL_TYPE_ID in(99,100));

update idb_ph2_net_access n set 
n.primary_dns = (select attr_value from excellent.cable_city_attr_pool_values_all where attr_pool_id = 8 and attr_id = 31 and billing_id = n.source_system),
n.secondary_dns = (select attr_value from excellent.cable_city_attr_pool_values_all where attr_pool_id = 8 and attr_id = 32 and billing_id = n.source_system)
where n.phase = phase_id$i and (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') and n.vlan is null
--and (n.assigned_ipv4addresses is not null or n.assigned_ipv6addresses is not null)
and n.primary_dns is null and n.source_system not in (556,0);





--16.12.2021 убрал update
/*
update idb_ph2_net_access n set n.primary_dns = 
(
select n1.primary_dns from idb_ph2_net_access n1
where n1.phase = phase_id$i and (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') and n1.vlan is null
and n1.primary_dns is not null and n1.bpi_idb_id = n.bpi_idb_id),
n.secondary_dns = (
select n1.secondary_dns from idb_ph2_net_access n1
where n1.phase = phase_id$i and (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') and n1.vlan is null
and n1.primary_dns is not null and n1.bpi_idb_id = n.bpi_idb_id)

where idb_id like 'NEA_%' and (n.assigned_ipv4addresses is null and n.assigned_ipv6addresses is null) and bpi_idb_id  LIKE 'TI_1/%'
and bpi_idb_id in (
select bpi_idb_id from idb_ph2_net_access n
where (bpi_idb_id like 'TI_1/%' OR bpi_idb_id like 'SIFI_1/%' OR bpi_idb_id like 'SI_1/%') and n.vlan is null
and n.primary_dns is not null)
and phase = phase_id$i;
*/
end;







/*
begin
for rec in (
select ac.idb_id,n.rowid from idb_ph2_net_access n,idb_ph2_sbpi_int s,idb_ph2_access_cred ac
where s.idb_id = n.bpi_idb_id and s.off_id_for_migr = 121000087
and s.parent_id like 'TI%' and ac.bpi_idb_id = n.bpi_idb_id and ac.bpi_idb_id = s.idb_id) loop
update idb_ph2_net_access 
set service_credentials = rec.idb_id
where rowid = rec.rowid;
end loop;
end;
*/

  
  
begin
for rec in (
select ac.idb_id,n.rowid from idb_ph2_net_access n,idb_ph2_sbpi_int s,idb_ph2_access_cred ac
where s.phase = phase_id$i and s.idb_id = n.bpi_idb_id and s.off_id_for_migr = 121000087
and s.parent_id like 'TI%' and ac.bpi_idb_id = n.bpi_idb_id and ac.bpi_idb_id = s.idb_id
--A.Kosterin 20.08.2021 add "and n.ASSIGNED_IPV4ADDRESSES is null"
and n.ASSIGNED_IPV4ADDRESSES is null
) loop
update idb_ph2_net_access 
set service_credentials = rec.idb_id
where rowid = rec.rowid;
end loop;

--A.Kosterin 09.12.2021 del 2 update + 1 delete + 3 update


/*
update idb_ph2_tbpi_int set access_speed = replace(access_speed,'2048','2100'), MAX_OUT_SPEED = replace(access_speed,access_speed,2100),
MAX_IN_SPEED = replace(access_speed,access_speed,2100)
where access_speed like '2048%'
and idb_id like 'TI%'
and phase = phase_id$i;


update idb_ph2_tbpi_int set access_speed = replace(access_speed,'5120','5200'), MAX_OUT_SPEED = replace(access_speed,access_speed,5200),
MAX_IN_SPEED = replace(access_speed,access_speed,5200)
where access_speed like '5120%'
and idb_id like 'TI%'
and phase = phase_id$i;


delete from idb_ph2_productstatus p where p.parent_id in ('TI_1/215/2199076/7885410/83395',
'TI_1/215/2199076/7885414/83397',
'TI_1/215/2199076/7715881/83399',
'TI_1/215/2199076/7962811/129601'
)
and phase = phase_id$i;

update idb_ph2_tbpi_int t
set t.ACCESS_SPEED_UP = '0'|| replace(ACCESS_SPEED_UP,',','.') where ACCESS_SPEED_UP like ',%' and phase = phase_id$i;

update idb_ph2_tbpi_int t
set t.ACCESS_SPEED = '0'|| replace(ACCESS_SPEED,',','.') where ACCESS_SPEED like ',%' and phase = phase_id$i;

update idb_ph2_tbpi_int t
set t.ACCESS_SPEED = replace(ACCESS_SPEED,',','.'), ACCESS_SPEED_UP =replace(ACCESS_SPEED,',','.') where phase = phase_id$i;
*/

end;




--CHERNOV_FOR_INT 27.04.2021
declare
  lv_task_id PLS_INTEGER;
begin
  --delete from rias_mgr_tmp_list;
  delete from idb_ph2_bpi_suspend_req where idb_id like 'SUSP_CH%' and phase = phase_id$i;
  --
  --lv_task_id := inser_work_data;
  --06.12.2021 A.Kosterin
  insert into idb_ph2_bpi_suspend_req
    (bpi_idb_id,
     idb_id,
     isvalid,
     susp_end_date,
     susp_start_date,
     susp_descr, phase)
    select bpi_idb_id,
           idb_id,
           isvalid,
           susp_end_date,
           susp_start_date,
           susp_descr,
           phase
    from aak_tmp_idb_ph2_bpi_suspend_req t;
  --clear_tmp_data(lv_task_id);
end;




begin
for rec in (select IDB_ID,(rias_mgr_support.get_service_cost(addendum_id$i => t.source_id,
                                                    billing_id$i  => t.source_system,
                                                    service_id$i => 237,
                                                    date$d       => current_date,
                                                    with_nds$i => 1) * 100000 - t.Mrc) MRC_CUPON_MNT, round((
                                                    
                                                    (rias_mgr_support.get_service_cost(addendum_id$i => t.source_id,
                                                    billing_id$i  => t.source_system,
                                                    service_id$i => 237,
                                                    date$d       => current_date,
                                                    with_nds$i => 1) * 100000 - t.Mrc) * 100 / (rias_mgr_support.get_service_cost(addendum_id$i => t.source_id,
                                                    billing_id$i  => t.source_system,
                                                    service_id$i => 237,
                                                    date$d       => current_date,
                                                    with_nds$i => 1) * 100000)),0) MRC_CUPON
from idb_ph2_tbpi_int t,activate_license_fee_all alf, plan_items_all pi 
where t.phase = phase_id$i and t.idb_id like 'TI_1/%'
and alf.addendum_id = t.source_id
      AND alf.billing_id = t.source_system
      AND alf.active_from <= current_date
      AND (alf.active_to IS NULL OR alf.active_to > current_date)
      AND alf.plan_item_id = pi.plan_item_id
      AND alf.billing_id = pi.billing_id
      AND pi.service_id IN (102243, 102241 , 103305, 103343)) loop
      
      UPDATE IDB_Ph2_tbpi_int t
      set
      t.mrc_cupon_mnt = rec.mrc_cupon_mnt, t.mrc_cupon=rec.mrc_cupon
      where t.idb_id = rec.idb_id and t.phase = phase_id$i;
      
      end loop;

end;





--28.05.2021
begin
  delete from idb_ph2_productstatus where idb_id like 'TI_STXNEW%' and phase = phase_id$i;
  
  
  insert into idb_ph2_productstatus ps (CUSTOMER_IDB_ID,EFFECTIVE_DTM,
  IDB_ID,ISVALID,parent_id,PRODUCT_STATUS,source_id,source_system,source_system_type, phase)
  select 
  s.customer_idb_id,s.actual_start_date,'TI_STXNEW'||s.idb_id,null,s.idb_id,'Active',s.source_id,
  s.source_system,s.source_system_type, t.phase
  from idb_ph2_sbpi_int s,idb_ph2_tbpi_int t where s.phase = phase_id$i and s.parent_id = t.idb_id and t.idb_id like 'TI_1/%'
  and s.off_id_for_migr = 303000018
  and s.ext_bpi_status <> 'Suspended' and t.ext_bpi_status = 'Suspended';
  
  update idb_ph2_sbpi_int s
  set s.ext_bpi_status = 'Suspended',
  s.ext_bpi_status_date = (select t.ext_bpi_status_date from idb_ph2_tbpi_int t where t.idb_id = s.parent_id)
  ,s.suspend_reason = (select t.suspend_reason from idb_ph2_tbpi_int t where t.idb_id = s.parent_id)
  where s.phase = phase_id$i and 
  s.off_id_for_migr  = 303000018 and s.parent_id like 'TI_1/%'
  and s.ext_bpi_status <> 'Suspended' 
  and (select t.ext_bpi_status from idb_ph2_tbpi_int t where t.idb_id = s.parent_id) = 'Suspended';
 
end;



update idb_ph2_sbpi_int s 
set s.ext_bpi_status_date = (select t.ext_bpi_status_date from idb_ph2_tbpi_int t where t.idb_id = s.parent_id)
where rowid in( SELECT  
        IDB_PH2_SBPI_INT.rowid
                FROM IDB_PH2_SBPI_INT
                /*JOIN PART OF VALIDATION RULE*/
                
                WHERE
                /* Part of validation rule */
                IDB_PH2_SBPI_INT.EXT_BPI_STATUS_DATE IS NULL and phase = phase_id$i and parent_id like 'TI%' and ext_bpi_status = 'Suspended'); 



update IDB_PH2_SBPI_INT s set s.suspend_reason = (select t.suspend_reason from idb_ph2_tbpi_int t where t.idb_id = s.parent_id)
where rowid in (select
  tab.rowid
from
  IDB_PH2_SBPI_INT tab,
  IDB_PH2_OFFERS_CHR_INV_DIC dic
where 1 = 1
and tab.phase = phase_id$i
  and tab.EXT_BPI_STATUS = 'Suspended'
  and tab.SUSPEND_REASON is null
  and dic.OFF_ID_FOR_MIGR = tab.OFF_ID_FOR_MIGR
  and dic.IDB_COLUMN_NAME = 'SUSPEND_REASON'
  and dic.IDB_TABLE_NAME = 'IDB_PH2_SBPI_INT');


insert into idb_ph2_productstatus ps (CUSTOMER_IDB_ID,EFFECTIVE_DTM,
  IDB_ID,ISVALID,parent_id,PRODUCT_STATUS,source_id,source_system,source_system_type, phase) 
 select 
s.customer_idb_id,s.actual_start_date,'TI_STXNEW'||s.idb_id,null
  ,s.idb_id,'Active',s.source_id,s.source_system,s.source_system_type, t.phase  from idb_ph2_sbpi_int s,idb_ph2_tbpi_int t where s.parent_id = t.idb_id and t.idb_id like 'TI_1/%'
  and s.off_id_for_migr = 303000018
  and s.phase = phase_id$i
  and s.ext_bpi_status = 'Suspended' and t.ext_bpi_status = 'Suspended'
  and to_char(s.ext_bpi_status_date,'mmyyyy') = to_char(current_date,'mmyyyy')
  and not exists(select 1 from idb_ph2_productstatus ps where ps.parent_id = s.idb_id
  and ps.effective_dtm = s.actual_start_date and ps.product_status = 'Active');

begin
  open c_TRANSFER_WAY;
  loop
    fetch c_TRANSFER_WAY bulk collect into v_TRANSFER_WAY limit 200;
    forall i in 1 .. v_TRANSFER_WAY.count
      update idb_prod.IDB_PH2_SBPI_INT set TRANSFER_WAY = 'Продажа', TOTAL_PRICE_TAX_NRC = 0 where rowid = v_TRANSFER_WAY(i);
    exit when c_TRANSFER_WAY%notfound;
    end loop;
  close c_TRANSFER_WAY;
end;




BEGIN
  OPEN c_MRC;
  LOOP
    FETCH c_MRC BULK COLLECT
      INTO v_MRC LIMIT 200;
    FORALL i IN 1 .. v_MRC.count
      UPDATE idb_prod.IDB_PH2_SBPI_INT
      SET    TAX_MRC = round(((mrc / 100000 / 1.2 - mrc / 100000) * '-1'), 2) *
                       100000
      WHERE  ROWID = v_MRC(i);
    EXIT WHEN c_MRC%NOTFOUND;
  END LOOP;
  CLOSE c_MRC;
END;


--A.Kosterin update SBPI status возврат из приостановки/Автоматическое отключение по ДЗ 28.06.2021

BEGIN
  
  execute immediate 'truncate table idb_prod.aak_sbpi_int';

  SELECT MAX(to_number(substr(t.service_id, -6))) - 100000
  INTO   lv_cnt
  FROM   idb_ph2_sbpi_int t
  WHERE 1=1
    AND (idb_id LIKE 'SI_1/%'   OR
         idb_id LIKE 'SIFD_1/%' OR
         idb_id LIKE 'SIFI_1/%' OR
         idb_id LIKE 'SISU_1/%' OR
         idb_id LIKE 'SICF_1/%' OR
         idb_id LIKE 'SIZD_1/%' OR
         idb_id LIKE 'SIRTR_1/%' OR
         idb_id LIKE 'SUS_TI_1/%');

  FOR rec IN (SELECT 
                tbpi.rowid AS tbpi_rowid,
                pi.plan_item_id,
                         ad.addendum_id,
                         ad.addendum_number,
                         ad.billing_id,
                         ac.legacy_account_num,
                         ad.agreement_id,
                         tbpi.source_id as tbpi_source_id,
                         tbpi.parent_id,
                         tbpi.source_system,
                         tbpi.SERVICE_ID,
                         ACCOUNT_IDB_ID,
                         tfl.active_from,
                         tfl.active_to,
                         tbpi.mrc,
                         tbpi.tax_mrc,
                         ext_bpi_status,
                         tbpi.idb_id as tbpi_idb_id,
                         ext_bpi_status_date,
                         tbpi.off_id_for_migr as tbpi_off_id_for_migr,
                         tbpi.CREATED_WHEN as tbpi_CREATED_WHEN,
                         tbpi.CUSTOMER_LOCATION as tbpi_CUSTOMER_LOCATION,
                         tbpi.source_system_type,
                         tbpi.bpi_market,
                         tbpi.ACTUAL_START_DATE as tbpi_ACTUAL_START_DATE,
                         tbpi.BPI_ORGANIZATION as tbpi_BPI_ORGANIZATION,
                         tbpi.NETWORK as tbpi_NETWORK,
                         tbpi.phase
                FROM   idb_ph2_tbpi_int                             tbpi,
                       plan_groups_all          pg,
                       plans_all                pa,
                       addenda_all              ad,
                       plan_items_all           pi,
                       activate_license_fee_all alf,
                       idb_ph2_account                    ac,
                       teo_link_addenda_all               tla,
                       teo_all                            t,
                       agreement_flags_all                af,
                       teo_flag_links_all       tfl
                WHERE  1 = 1
                and tbpi.idb_id like 'TI_1%'
                and ac.phase = phase_id$i
                and ac.IDB_ID = tbpi.ACCOUNT_IDB_ID
                AND    tbpi.source_id = ad.addendum_id
                AND    tbpi.source_system = ad.billing_id
                AND    pg.product_id = 7
                AND    pg.plan_group_id IN (41, 86, 77)
                AND    tla.addendum_id = ad.addendum_id
                AND    tla.billing_id = ad.billing_id
                AND    tla.active_from <= current_date
                AND    coalesce(tla.active_to, current_date + 1) > current_date
                AND    t.teo_id = tla.teo_id
                AND    t.billing_id = tla.billing_id
                AND    tfl.teo_id = t.teo_id
                AND    tfl.billing_id = t.billing_id
                AND    tfl.active_from <= current_date
                AND    tfl.active_from >= alf.active_to
                AND    tfl.active_from <> tfl.active_to
                AND    to_char(tfl.active_from, 'mmyyyy') =
                       to_char(current_date, 'mmyyyy')
                AND    af.flag_id = tfl.flag_id
                AND    af.billing_id = tfl.billing_id
                AND    af.flag_type_id = 24
                AND    af.flag_name = 'Возврат из приостановления'
                AND    tfl.active_from > trunc(current_date, 'MM')
                      
                AND    (SELECT MAX(tf2.active_from)
                        FROM   teo_flag_links_all  tf2,
                               agreement_flags_all af2
                        WHERE  1 = 1
                        AND    tf2.teo_id = t.teo_id
                        AND    tf2.billing_id = t.billing_id
                        AND    af2.flag_id = tf2.flag_id
                        AND    af2.billing_id = tf2.billing_id
                        AND    af2.flag_type_id = 24) = tfl.active_from
                      
                AND    NVL((SELECT MIN(tfl5.active_from)
                           FROM   agreement_flags_all af5,
                                  teo_flag_links_all  tfl5
                           WHERE  af5.flag_type_id = 16
                           AND    af5.flag_name =
                                  'Автоматическое отключение по ДЗ (устанавливается автоматически).'
                           AND    af5.flag_id = tfl5.flag_id
                           AND    af5.billing_id = tfl5.billing_id
                           AND    tfl5.teo_id = tfl.teo_id
                           AND    tfl5.billing_id = tfl.billing_id
                           AND    tfl5.active_from >= tfl.active_from),
                           to_date('01.01.2000', 'dd.mm.yyyy')) <>
                       tfl.active_from
                      
                AND    (SELECT MAX(tf2.active_from)
                        FROM   teo_flag_links_all  tf2,
                               agreement_flags_all af2,
                               agreement_flags_all af3
                        WHERE  1 = 1
                        AND    tf2.teo_id = t.teo_id
                        AND    tf2.billing_id = t.billing_id
                        AND    af3.flag_id = tf2.flag_id
                        AND    af3.billing_id = tf2.billing_id
                        AND    af2.flag_id = tf2.flag_id
                        AND    af2.billing_id = tf2.billing_id
                        AND    af2.flag_type_id = 16
                        AND    af3.flag_name LIKE '%ДЗ%') < tfl.active_from
                      
                AND    pa.plan_group_id = pg.plan_group_id
                AND    pa.billing_id = pg.billing_id
                AND    ad.plan_id = pa.plan_id
                AND    ad.billing_id = pa.billing_id
                AND    ac.source_id = ad.agreement_id
                AND    ac.source_system = ad.billing_id
                AND    ac.source_system_type = 1
                AND    alf.addendum_id = ad.addendum_id
                AND    alf.billing_id = ad.billing_id
                AND    alf.active_from <= current_date
                AND    alf.active_to IS NOT NULL
                AND    pi.plan_item_id = alf.plan_item_id
                AND    pi.billing_id = alf.billing_id
                AND    pi.service_id = 237
                AND    alf.active_from <= current_date
                AND    ext_bpi_status = 'Active'
                AND    pi.plan_item_id IN
                       (SELECT MAX(alf.plan_item_id)
                         FROM   teo_link_addenda_all               tla,
                                agreement_flags_all                af,
                                excellent.teo_flag_links_all       tfa,
                                excellent.activate_license_fee_all alf,
                                excellent.plan_items_all           pi
                         WHERE  1 = 1
                         AND    af.billing_id = tla.billing_id
                         AND    tfa.flag_id = af.flag_id
                         AND    tfa.billing_id = tla.billing_id
                         AND    tfa.teo_id = tla.teo_id
                         AND    alf.billing_id = tfa.billing_id
                         AND    alf.addendum_id = tla.addendum_id
                         AND    pi.billing_id = alf.billing_id
                         AND    pi.plan_item_id = alf.plan_item_id
                         AND    tla.addendum_id = ad.addendum_id
                         AND    service_id = 237
                         AND    af.billing_id = ad.billing_id)
                AND    af.flag_type_id IN
                       (WITH table_rank AS
                         (SELECT dense_rank() over(PARTITION BY tfl.BILLING_ID, tfl.TEO_ID ORDER BY tfl.ACTIVE_FROM) AS PREV_FLAG_TYPE,
                                 tfl.*,
                                 af5.FLAG_TYPE_ID,
                                 af5.flag_name
                          FROM   agreement_flags_all          af5,
                                 excellent.teo_flag_links_all tfl
                          WHERE  af5.flag_id = tfl.flag_id
                          AND    af5.billing_id = tfl.billing_id),
                         table_rank2 AS (SELECT t.*,
                                 MAX(PREV_FLAG_TYPE) over(PARTITION BY BILLING_ID, TEO_ID) AS MAX_PREV_FLAG_TYPE
                          FROM   table_rank t)
                          SELECT DISTINCT CASE
                                            WHEN FLAG_TYPE_ID = 16 THEN
                                             24
                                          END
                          FROM   table_rank2 tt
                          WHERE  PREV_FLAG_TYPE = MAX_PREV_FLAG_TYPE - 1
                          AND    teo_id = t.teo_id
                          AND    billing_id = t.billing_id
                          AND    flag_name LIKE '%ДЗ%'
                         ))
  LOOP
    lv_cnt_for_com := lv_cnt_for_com +1;
    if lv_cnt_for_com = 3 then commit;
    lv_cnt_for_com := 0;
    end if;
    BEGIN
    
      SELECT MAX(tfl.active_from)
      INTO   lv_ACTUAL_START_DATE_24$d
      FROM   excellent.teo_flag_links_all tfl, agreement_flags_all af5
      WHERE  tfl.billing_id = af5.billing_id
      AND    tfl.flag_id = af5.flag_id
      AND    af5.billing_id = rec.billing_id
      AND    tfl.teo_id IN (SELECT MAX(teo_id)
                            FROM   excellent.teo_link_addenda_all tla
                            WHERE  billing_id = rec.billing_id
                            AND    addendum_id = rec.addendum_id
                            AND    coalesce(active_to, current_date + 1) >
                                   trunc(current_date, 'MM'))
      AND    af5.FLAG_TYPE_ID IN (24)
      AND    rownum >= 1
      ORDER  BY tfl.active_from DESC;
    
      SELECT MAX(tfl.active_from)
      INTO   lv_ACTUAL_START_DATE_16$d
      FROM   excellent.teo_flag_links_all tfl, agreement_flags_all af5
      WHERE  tfl.billing_id = af5.billing_id
      AND    tfl.flag_id = af5.flag_id
      AND    af5.billing_id = rec.billing_id
      AND    tfl.teo_id IN (SELECT MAX(teo_id)
                            FROM   excellent.teo_link_addenda_all tla
                            WHERE  billing_id = rec.billing_id
                            AND    addendum_id = rec.addendum_id
                            AND    coalesce(active_to, current_date + 1) >
                                   trunc(current_date, 'MM'))
      AND    af5.FLAG_TYPE_ID IN (16)
      AND    FLAG_NAME LIKE '%ДЗ%'
      AND    rownum >= 1
      ORDER  BY tfl.active_from DESC;
    
      lv_cnt := lv_cnt + 1;
    
      SELECT regexp_replace(rawtohex(sys_guid()),
                            '([A-F0-9]{8})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{4})([A-F0-9]{12})',
                            '\1\2\3\4\5')
      INTO   lv_sys_guid
      FROM   dual;
    
      SELECT SUM(expenses_number)
      INTO   lv_num_lines$n
      FROM   addenda_all          ad_1,
             teo_link_addenda_all la_1,
             expenses_all         e_1,
             materials_all        m_1
      WHERE  1 = 1
      AND    ad_1.addendum_id = rec.addendum_id
      AND    ad_1.billing_id = rec.billing_id
      AND    la_1.addendum_id = ad_1.addendum_id
      AND    la_1.billing_id = ad_1.billing_id
      AND    la_1.active_from <= rias_mgr_support.get_current_date
      AND    (la_1.active_to IS NULL OR
            la_1.active_to > rias_mgr_support.get_current_date)
      AND    e_1.teo_id = la_1.teo_id
      AND    e_1.billing_id = la_1.billing_id
      AND    m_1.Attr_Entity_Id = e_1.Attr_Entity_Id
      AND    m_1.billing_id = e_1.billing_id
      AND    m_1.Material_Name IN
             ('СП_Организация дополнительного абонентского отвода по 1-й (первой) категории сложности (за 1 единицу)',
               'СП_Организация дополнительного абонентского отвода по 2-й (второй) категории сложности (за 1 единицу)')
      
      ;
      UPDATE idb_ph2_tbpi_int tbpi
      SET    ext_bpi_status_date = lv_ACTUAL_START_DATE_24$d
      WHERE  ROWID = rec.tbpi_rowid;
      SELECT MAX(ips.PARENT_ID)
      INTO   lv_idb_PRODUCTSTATUS
      FROM   IDB_PH2_PRODUCTSTATUS ips
      WHERE  ips.PARENT_ID = rec.tbpi_idb_id;
      IF lv_idb_PRODUCTSTATUS IS NOT NULL THEN
        DELETE FROM IDB_PH2_PRODUCTSTATUS ips
        WHERE  ips.PARENT_ID = lv_idb_PRODUCTSTATUS and ips.phase = phase_id$i;
      END IF;
    
      INSERT INTO IDB_PH2_PRODUCTSTATUS (CUSTOMER_IDB_ID,
                                   EFFECTIVE_DTM,
                                   IDB_ID,
                                   ISVALID,
                                   PARENT_ID,
                                   PRODUCT_STATUS,
                                   SOURCE_ID,
                                   SOURCE_SYSTEM,
                                   SOURCE_SYSTEM_TYPE,
                                   STATUS_REASON_TXT,
                                   phase)
        SELECT rec.parent_id CUSTOMER_IDB_ID,
               lv_ACTUAL_START_DATE_16$d EFFECTIVE_DTM,
               'ST' || rec.tbpi_idb_id IDB_ID,
               NULL ISVALID,
               rec.tbpi_idb_id PARENT_ID,
               'Suspended' PRODUCT_STATUS,
               rec.tbpi_source_id SOURCE_ID,
               rec.SOURCE_SYSTEM SOURCE_SYSTEM,
               rec.SOURCE_SYSTEM_TYPE SOURCE_SYSTEM_TYPE,
               'Нет данных' STATUS_REASON_TXT,
               rec.phase
        FROM   DUAL;
    
      INSERT INTO IDB_PH2_SBPI_INT (ACCOUNT_IDB_ID,
ACTUAL_END_DATE,
ACTUAL_START_DATE,
ADDITIONAL_LINE_NUM,
BILLED_TO_DAT,
BPI_MARKET,
BPI_ORGANIZATION,
BPI_TIME_ZONE,
CREATED_WHEN,
CUSTOMER_IDB_ID,
CUSTOMER_LOCATION,
EXT_BPI_STATUS,
EXT_BPI_STATUS_DATE,
IDB_ID,
INV_NAME,
MA_FLAG,
MA_FLAG_DATE,
MRC,
NETWORK,
OFF_ID_FOR_MIGR,
PARENT_ID,
SERVICE_ID,
SOURCE_ID,
SOURCE_SYSTEM,
SOURCE_SYSTEM_TYPE,
TAX_MRC,
BARRING,
phase)
SELECT rec.ACCOUNT_IDB_ID ACCOUNT_IDB_ID,
       lv_ACTUAL_START_DATE_24$d - 1 ACTUAL_END_DATE,
       lv_ACTUAL_START_DATE_16$d ACTUAL_START_DATE,
       lv_num_lines$n ADDITIONAL_LINE_NUM,
       CASE
         WHEN (to_char(rec.tbpi_ACTUAL_START_DATE, 'mmyyyy') !=
              to_char(current_date, 'mmyyyy')) THEN
          trunc(last_day(add_months(current_date, -1)))
         ELSE
          NULL
       END BILLED_TO_DAT,
       rec.bpi_market BPI_MARKET,
       rec.tbpi_BPI_ORGANIZATION BPI_ORGANIZATION,
       rias_mgr_support.get_time_zone(rec.source_system) BPI_TIME_ZONE, ---
       rec.tbpi_CREATED_WHEN CREATED_WHEN,
       rec.parent_id CUSTOMER_IDB_ID,
       rec.tbpi_CUSTOMER_LOCATION CUSTOMER_LOCATION,
       'Disconnected' EXT_BPI_STATUS,
       lv_ACTUAL_START_DATE_24$d - 1 EXT_BPI_STATUS_DATE,
       ('SUS_TI_1/' || rec.BILLING_ID || '/' || rec.AGREEMENT_ID || '/' ||
       rec.ADDENDUM_ID || '/' || rec.PLAN_ITEM_ID || '/' || lv_sys_guid) IDB_ID,
       CASE
         WHEN rec.tbpi_off_id_for_migr = 121000121 THEN
          'Приостановка Интернет Базовый Бизнес'
         WHEN rec.tbpi_off_id_for_migr = 121000355 THEN
          'Приостановка Интернет Мобильный Бизнес'
         WHEN rec.tbpi_off_id_for_migr = 121000837 THEN
          'Приостановка Интернет "Скорость"'
         WHEN rec.tbpi_off_id_for_migr = 121000879 THEN
          'Приостановка Интернет "Скорость +"'
         WHEN rec.tbpi_off_id_for_migr = 121000296 THEN
          'Приостановка Интернет Беспроводной Бизнес'
         WHEN rec.tbpi_off_id_for_migr = 121000390 THEN
          'Приостановка Интернет Индивидуальный'
         WHEN rec.tbpi_off_id_for_migr = 9161228920313303218 THEN
          'Приостановка Интернет Беспроводной'
         WHEN rec.tbpi_off_id_for_migr = 9161358500513727314 THEN
          'Приостановка Интернет Эксклюзив-Лайт'
         WHEN rec.tbpi_off_id_for_migr = 9161358501513727314 THEN
          'Приостановка Интернет Эксклюзив'
         WHEN rec.tbpi_off_id_for_migr = 9161358502513727314 THEN
          'Приостановка Интернет Люкс'
       END INV_NAME,
       'Основной проект' MA_FLAG,
       lv_ACTUAL_START_DATE_24$d - 1 MA_FLAG_DATE,
       0 MRC,
       rec.tbpi_NETWORK NETWORK,
       CASE
         WHEN rec.tbpi_off_id_for_migr = 121000121 THEN
          121001179
         WHEN rec.tbpi_off_id_for_migr = 121000355 THEN
          121001224
         WHEN rec.tbpi_off_id_for_migr = 121000837 THEN
          121001260
         WHEN rec.tbpi_off_id_for_migr = 121000879 THEN
          121001269
         WHEN rec.tbpi_off_id_for_migr = 121000296 THEN
          121001206
         WHEN rec.tbpi_off_id_for_migr = 121000390 THEN
          121001233
         WHEN rec.tbpi_off_id_for_migr = 9161228920313303218 THEN
                121001206
         WHEN rec.tbpi_off_id_for_migr in (9161358500513727314, 9161358501513727314, 9161358502513727314) THEN
                121001179
       END OFF_ID_FOR_MIGR,
       rec.tbpi_idb_id PARENT_ID,
       CASE
         WHEN rec.tbpi_off_id_for_migr = 121000390 THEN
          'INTINDSUSP-' || to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' ||
          lv_cnt
         WHEN rec.tbpi_off_id_for_migr = 121000879 THEN
          'INTSPEEDPLSUSP-' ||
          to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' || lv_cnt
         WHEN rec.tbpi_off_id_for_migr = 121000837 THEN
          'INTSPEEDSUSP-' || to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' ||
          lv_cnt
         WHEN rec.tbpi_off_id_for_migr = 121000121 THEN
          'INTBEZLIMSUSP-' || to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' ||
          lv_cnt
         WHEN rec.tbpi_off_id_for_migr = 121000296 THEN
          'INTWIUNLIMSUSP-' ||
          to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' || lv_cnt
         WHEN rec.tbpi_off_id_for_migr = 121000355 THEN
          'INTMOUNLIMSUSP-' ||
          to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' || lv_cnt
         WHEN rec.tbpi_off_id_for_migr = 9161228920313303218 THEN
                'INTWIUNLIMSUSP-' || to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' || lv_cnt
         WHEN rec.tbpi_off_id_for_migr in (9161358500513727314, 9161358501513727314, 9161358502513727314) THEN
                'INTLIMITSUSP-' || to_char(lv_ACTUAL_START_DATE_16$d, 'ddmmyyyy') || '1' || lv_cnt
       END service_id,
       (rec.AGREEMENT_ID || '/' || rec.ADDENDUM_ID || '/' ||
       rec.PLAN_ITEM_ID || '/' || lv_sys_guid) SOURCE_ID,
       rec.source_system SOURCE_SYSTEM,
       rec.source_system_type SOURCE_SYSTEM_TYPE,
       0 tax_mrc,
       'N' BARRING,
       rec.phase
        FROM   dual;
    
      INSERT INTO IDB_PH2_PRODUCTSTATUS (CUSTOMER_IDB_ID,
                                   EFFECTIVE_DTM,
                                   IDB_ID,
                                   ISVALID,
                                   PARENT_ID,
                                   PRODUCT_STATUS,
                                   SOURCE_ID,
                                   SOURCE_SYSTEM,
                                   SOURCE_SYSTEM_TYPE,
                                   STATUS_REASON_TXT,
                                   phase)
        SELECT rec.PARENT_ID CUSTOMER_IDB_ID,
               lv_ACTUAL_START_DATE_16$d EFFECTIVE_DTM,
               ('PRST_1/TI_1/' || rec.BILLING_ID || '/' || rec.AGREEMENT_ID || '/' ||
               rec.ADDENDUM_ID || '/' || rec.PLAN_ITEM_ID || '/' ||
               lv_sys_guid) IDB_ID,
               NULL ISVALID,
               ('SUS_TI_1/' || rec.BILLING_ID || '/' || rec.AGREEMENT_ID || '/' ||
               rec.ADDENDUM_ID || '/' || rec.PLAN_ITEM_ID || '/' ||
               lv_sys_guid) PARENT_ID,
               'Active' PRODUCT_STATUS,
               (rec.AGREEMENT_ID || '/' || rec.ADDENDUM_ID || '/' ||
               rec.PLAN_ITEM_ID || '/' || lv_sys_guid) SOURCE_ID,
               rec.SOURCE_SYSTEM SOURCE_SYSTEM,
               rec.SOURCE_SYSTEM_TYPE SOURCE_SYSTEM_TYPE,
               'Нет данных' STATUS_REASON_TXT,
               rec.phase
        FROM   DUAL;
---A.Kosterin 30.06.2021 заполнение idb_ph2_bpi_mrc_priceoverride для ДЗ
INSERT INTO idb_ph2_bpi_mrc_priceoverride
  (end_dat,
   fk_product_otc_bpi_idb,
   idb_id,
   isvalid,
   override_amount,
   source_id,
   source_system,
   source_system_type,
   start_dat,
   phase)
  SELECT lv_ACTUAL_START_DATE_24$d - 1,
         ('SUS_TI_1/' || rec.BILLING_ID || '/' || rec.AGREEMENT_ID || '/' ||
         rec.ADDENDUM_ID || '/' || rec.PLAN_ITEM_ID || '/' || lv_sys_guid) as fk_product_otc_bpi_idb,
         ('MPO_1_SUS_TI_1/' || rec.BILLING_ID || '/' || rec.AGREEMENT_ID || '/' ||
         rec.ADDENDUM_ID || '/' || rec.PLAN_ITEM_ID || '/' || lv_sys_guid) as idb_id,
         NULL isvalid,
         0 mrc,
         rec.addendum_id,
         rec.source_system,
         rec.source_system_type,
         lv_ACTUAL_START_DATE_16$d,
         rec.phase
  FROM   dual;
    
      INSERT INTO aak_sbpi_int
        (parent_id, sys_gu, date_up)
        SELECT rec.tbpi_idb_id,
               ('SUS_TI_1/' || rec.BILLING_ID || '/' || rec.AGREEMENT_ID || '/' ||
               rec.ADDENDUM_ID || '/' || rec.PLAN_ITEM_ID || '/' ||
               lv_sys_guid),
               trunc(SYSDATE)
        FROM   dual;
    
    EXCEPTION
      WHEN no_data_found THEN
        dbms_output.put_line('no_data_found: ' || rec.addendum_id || ' ' ||
                             rec.billing_id || ' ' || rec.plan_item_id || ' ' ||
                             rec.active_from || ' ' || rec.tbpi_idb_id);
      WHEN TOO_MANY_ROWS THEN
        dbms_output.put_line('TOO_MANY_ROWS: ' || rec.addendum_id || ' ' ||
                             rec.billing_id || ' ' || rec.plan_item_id || ' ' ||
                             rec.active_from || ' ' || rec.tbpi_idb_id);
      WHEN INVALID_NUMBER THEN
        dbms_output.put_line('INVALID_NUMBER: ' || rec.addendum_id || ' ' ||
                             rec.billing_id || ' ' || rec.plan_item_id || ' ' ||
                             rec.active_from || ' ' || rec.tbpi_idb_id);
      
    END;
  
  END LOOP;
END;



--A.Kosterin 29.06.2021 update для mrc=null значений service_id = 103257

begin
  for rec in (
WITH service_table_103257 AS
  (select rias_mgr_support.get_abon_pays(addendum_id$i => ad.addendum_id,
                                      billing_id$i  => pi.billing_id,
                                      service_id$i  => pi.service_id,
                                      date$d        => rias_mgr_support.get_current_date(),
                                      with_nds$i    => 1) as price_$ , 
         pi.billing_id,
         sbpi.IDB_ID,
         alf.ACTIVE_FROM,
         alf.active_to,
         ad.ADDENDUM_ID,
         mrc, tax_mrc,
         MAX(ACTIVE_FROM) over(PARTITION BY pi.PLAN_ITEM_ID, pi.SERVICE_ID, ad.ADDENDUM_ID, ad.billing_id) AS max_ACTIVE_FROM
  FROM   addenda_all ad, plan_items_all pi, activate_license_fee_all alf, idb_ph2_sbpi_int sbpi
  where sbpi.phase = phase_id$i and REGEXP_SUBSTR(sbpi.IDB_ID , '[^/]+' , 1 , 4 ) = ad.addendum_id
  AND    alf.billing_id = ad.billing_id
  AND    alf.addendum_id = ad.addendum_id
  AND    pi.billing_id = ad.billing_id
  AND    pi.plan_item_id = alf.plan_item_id
  AND    pi.service_id = 103257
  AND    pi.billing_id = sbpi.source_system
  and    idb_id like 'SUS_TI_%' and mrc is null
  and    coalesce(alf.active_to, current_date + 1) > trunc(current_date, 'MM')
)
SELECT *
FROM   service_table_103257
WHERE  ACTIVE_FROM = MAX_ACTIVE_FROM) loop
    update idb_ph2_sbpi_int set mrc=rec.price_$*100000, tax_mrc=(rec.price_$ - rec.price_$/1.2)*100000 where idb_id = rec.idb_id;
    update idb_ph2_bpi_mrc_priceoverride set OVERRIDE_AMOUNT = rec.price_$*100000 where FK_PRODUCT_OTC_BPI_IDB = rec.idb_id;
  end loop;
  commit;
end;


--A.Kosterin 06.07.2021 добавление INDEXATION_DATE для tbpi/sbpi
begin
  for rec in (
with t_INDEXATION_DATE as (SELECT count(1) over (partition by tfl.teo_id, tfl.billing_id) as ct, 
           max(tfl.active_from) over (partition by tfl.teo_id, tfl.billing_id) as INDEXATION_DATE, af.*, tfl.teo_id
           FROM agreement_flags_all af,teo_flag_links_all tfl
           WHERE tfl.flag_id = af.flag_id and tfl.billing_id = af.billing_id --and tfl.billing_id = 556 --and tfl.teo_id = tla.teo_id
           and af.flag_name in ('Индексация (автоматическая)','Индексация (ручная)')
           and tfl.active_from <= trunc(current_date)
           AND COALESCE(tfl.ACTIVE_TO, CURRENT_DATE + 1) > CURRENT_DATE
           ), t_INDEXATION_DATE_1 as (
           select distinct tid.INDEXATION_DATE, tid.BILLING_ID, tbpi.IDB_ID  as tbpi_idb_id, tbpi.rowid as tbpi_rowid, sbpi.idb_id as sbpi_idb_id, sbpi.rowid as sbpi_rowid,  
           cpa.connect_pays_id, tid.teo_id, REGEXP_SUBSTR(sbpi.idb_id , '[^/]+' , 1 , 7 ) as sbpi_connect_pays_id, tbpi.INDEXATION_DATE as tbpi_INDEXATION_DATE, sbpi.INDEXATION_DATE as sbpi_INDEXATION_DATE
           from t_INDEXATION_DATE tid,
           teo_link_addenda_all tlaa, ADDENDA_ALL aa
           , IDB_PH2_TBPI_INT tbpi, IDB_PH2_SBPI_INT sbpi,
           connect_pays_all cpa
           where sbpi.phase = phase_id$i and tlaa.teo_id = tid.teo_id and tlaa.billing_id = tid.billing_id
           and aa.addendum_id = tlaa.addendum_id and aa.billing_id = tlaa.billing_id
           and tbpi.source_id = aa.addendum_id and tbpi.source_system = aa.billing_id
           and cpa.teo_id = tlaa.teo_id and cpa.billing_id = tlaa.billing_id
           and tbpi.IDB_ID = sbpi.PARENT_ID
           AND tbpi.IDB_ID LIKE 'TI_1/%'
           and sbpi.idb_id like 'SI_1/%'
           and sbpi.EXT_BPI_STATUS <> 'Completed'
           ), t_INDEXATION_DATE_2 as (
           SELECT f.* FROM t_INDEXATION_DATE_1 f
           )
           select * from t_INDEXATION_DATE_2
           ) loop
    if COALESCE(rec.TBPI_INDEXATION_DATE, to_date('01.01.1000','dd.mm.yyyy')) != rec.indexation_date then
    update IDB_PH2_TBPI_INT set INDEXATION_DATE = rec.indexation_date where rowid = rec.tbpi_rowid;
    end if;
    if COALESCE(rec.SBPI_INDEXATION_DATE, to_date('01.01.1000','dd.mm.yyyy')) != rec.indexation_date then
    update IDB_PH2_SBPI_INT set INDEXATION_DATE = rec.indexation_date where rowid = rec.sbpi_rowid;
    end if;
  end loop;
  commit;
end;


--28.07.2021 A.Kosterin валидация service_id

begin
  for rec in (
select
ACTUAL_START_DATE,
regexp_replace(tab.SERVICE_ID,'-\d{8}','-'||to_char(trunc(tab.ACTUAL_START_DATE),'DDMMYYYY')) as NEW_SERVICE_ID,
tab.rowid as row_id
from
  IDB_PH2_SBPI_INT tab,
  IDB_PH2_OFFERINGS_DIC dic
where
tab.phase = phase_id$i and 
  tab.SERVICE_ID is not null
  and dic.OFF_ID_FOR_MIGR = tab.OFF_ID_FOR_MIGR
  and dic.IDB_TABLE_NAME = 'IDB_PH2_SBPI_INT'
  and (
    substr(tab.SERVICE_ID, 1, length(dic.PREFIX) + 9) <> dic.PREFIX || '-' || to_char(tab.ACTUAL_START_DATE, 'DDMMYYYY')
    or not regexp_like(substr(tab.SERVICE_ID, length(dic.PREFIX) + 10), '^\d{7}$')
  )
  and ACTUAL_START_DATE is not null
) loop
  update IDB_PH2_SBPI_INT tbpi set tbpi.SERVICE_ID = rec.new_service_id where tbpi.rowid = rec.row_id;
end loop;
end;
--12.08.2021 A.Kosterin update IPV4
update idb_ph2_tbpi_int t 
set
incl_ip4addr = (case 
when KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(substr(t.incl_ip4addr,16))) = 0 then 
  (select idb_id from IDB_PH2_IP_V4ADDRESS ad where ad.source_system = t.source_system and ad.ip_address = bss_migrate_support.IP_NUMBER_TO_CHAR(substr(t.incl_ip4addr,16)))
when KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(substr(t.incl_ip4addr,16))) = 1 then 
  (select idb_id from IDB_PH2_IP_V4ADDRESS_PRIVATE ad where ad.source_system = t.source_system and ad.ip_address = bss_migrate_support.IP_NUMBER_TO_CHAR(substr(t.incl_ip4addr,16)))
end)
where incl_ip4addr like 'Неизвестный%' and t.phase = phase_id$i;

update IDB_PH2_NET_ACCESS s set s.assigned_ipv4addresses = (case
  when KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(substr(assigned_ipv4addresses,instr(assigned_ipv4addresses,':',-1)+1,99))) = 0 then
  (select idb_id from idb_prod.idb_ph2_ip_v4address a where a.source_system = s.source_system 
  and a.ip_address = Excellent.bss_migrate_support.IP_NUMBER_TO_CHAR(ip$n => substr(assigned_ipv4addresses,instr(assigned_ipv4addresses,':',-1)+1,99)))
  else 
(select idb_id from idb_prod.idb_ph2_ip_v4address_private a where a.source_system = s.source_system 
  and a.ip_address = Excellent.bss_migrate_support.IP_NUMBER_TO_CHAR(ip$n => substr(assigned_ipv4addresses,instr(assigned_ipv4addresses,':',-1)+1,99)))
end)
where s.phase = phase_id$i and s.assigned_ipv4addresses like '%Неизвестный%'/*  and s.off_id_for_migr = 121000087*/;


--08.10.2021 A.Kosterin
begin
for rec in (
SELECT rownum as f_rownum, ctf.* FROM CONNECT_TYPE_FOR_TECHNICAL_SERV ctf
order by ADD_TIME
) loop
update IDB_PH2_TBPI_INT set CONNECT_TYPE = rec.connect_type where idb_id like 'TI_1/'||rec.billing_id||'/'||rec.agreement_id||'/'||rec.addendum_id||'%';
if rec.f_rownum mod 1000 = 0 then
  commit;
end if;
end loop;
end;


--01.11.2021 A.Kosterin
BEGIN
  FOR rec IN (SELECT rownum AS n_rownum,
                     ipnh.rowid AS n_rowid,
                     i.ip,
                     i.terminal_resource_id,
                     (SELECT rias_mgr_support.ip_number_to_char(i2.ip)
                      FROM   EXCELLENT.Z_IPADDR_ALL_ALL   zia,
                             IP_FOR_DEDICATED_CLIENTS_ALL i2
                      WHERE  zia.addendum_id = ar.addendum_id
                      AND    zia.billing_id = ar.billing_id
                      AND    zia.billing_id = i2.billing_id
                      AND    zia.IPEXT_TERM_RES = i2.terminal_resource_id
                      AND    zia.terminal_resource_id =
                             i.terminal_resource_id
                      AND    IPEXT_TERM_RES IS NOT NULL) AS connect_ip
              
              FROM   IDB_PH2_NET_ACCESS                     ipnh,
                     excellent.ADDENDUM_RESOURCES_ALL       AR,
                     excellent.RESOURCE_CONTENTS_ALL        RC,
                     excellent.IP_FOR_DEDICATED_CLIENTS_ALL I
              WHERE  1 = 1
              and ipnh.phase = phase_id$i
              AND    RC.RESOURCE_ID = AR.RESOURCE_ID
              AND    RC.BILLING_ID = AR.BILLING_ID
              AND    COALESCE(RC.ACTIVE_TO, CURRENT_DATE + 1) > CURRENT_DATE
              AND    RC.ACTIVE_FROM <= CURRENT_DATE
              AND    coalesce(ar.active_to, current_date + 1) >=
                     current_date
              AND    ar.active_from <= current_date
              AND    I.TERMINAL_RESOURCE_ID = RC.TERMINAL_RESOURCE_ID
              AND    I.BILLING_ID = RC.BILLING_ID
              AND    ar.billing_id = ipnh.source_system
              AND    ar.addendum_id =
                     REGEXP_SUBSTR(ipnh.IDB_ID, '[^/]+', 1, 4)
              AND    ipnh.source_system = 556
              AND    auth_type IN
                     ('IPoE белый IP за NAT',
                       'IPoE белый IP за NAT(через радиомост)')
              AND    REGEXP_SUBSTR(ipnh.ASSIGNED_IPV4ADDRESSES,
                                   '[^/]+',
                                   1,
                                   3) =
                     rias_mgr_support.ip_number_to_char(i.ip)
              --AND    ar.addendum_id = 20237850
              AND    EXISTS (SELECT 1
                      FROM   EXCELLENT.Z_IPADDR_ALL_ALL zia
                      WHERE  zia.addendum_id = ar.addendum_id
                      AND    zia.billing_id = ar.billing_id
                      AND    zia.terminal_resource_id =
                             i.terminal_resource_id
                      AND    IPEXT_TERM_RES IS NOT NULL))
  LOOP
    IF rec.n_rownum MOD 1000 = 0 THEN
      COMMIT;
    END IF;
  UPDATE IDB_PH2_NET_ACCESS na
  SET    na.NAT_IPV4_ADDR = 'V4AP/556/'||rec.connect_ip
  WHERE  na.rowid = rec.n_rowid;
  END LOOP;
END;

    commit;
  end fill_net_access;

/**
  * Заполнить таблицу IDB_PH2_SBPI_INT
  *   OFF_ID_FOR_MIGR = '121000093'
  */
PROCEDURE fill_idb_ph2_sbpi_121000093
  IS
  lv_current_date date := rias_mgr_support.get_current_date;
    CURSOR cr_121000093 IS
      SELECT
      TLO.ACCOUNT_IDB_ID    AS ACCOUNT_IDB_ID,
      (ar.ACTIVE_TO - 1)    AS ACTUAL_END_DATE,
      (CASE
        WHEN ar.ACTIVE_FROM < TLO.ACTUAL_START_DATE THEN
          TLO.ACTUAL_START_DATE
        ELSE
          ar.ACTIVE_FROM
      END)                  AS ACTUAL_START_DATE,
      TLO.AUTH_TYPE         AS AUTH_TYPE,
      TLO.BILLED_TO_DAT     AS BILLED_TO_DAT,
      TLO.CREATED_WHEN      AS CREATED_WHEN,
      TLO.PARENT_ID         AS CUSTOMER_IDB_ID,
      TLO.CUSTOMER_LOCATION AS CUSTOMER_LOCATION,
      'Да'                  AS DIRECT_PROH,
      'Active'              AS EXT_BPI_STATUS,
      (CASE
        WHEN ar.ACTIVE_FROM < TLO.ACTUAL_START_DATE THEN
          TLO.ACTUAL_START_DATE
        ELSE
          ar.ACTIVE_FROM
      END)                  AS EXT_BPI_STATUS_DATE,
      'SI_1'||SUBSTR(TLO.IDB_ID, 5, 150) || '/' || sn.ip_v6 AS idb_id,
      'Дополнительный IPv6 префикс' AS INV_NAME,
      0                     AS MRC,
      0                     AS MRC_CUPON,
      TLO.LEGACY_OBJECT_NAME AS LEGACY_OBJECT_NAME,
      '121000093'           AS OFF_ID_FOR_MIGR,
      TLO.IDB_ID            AS PARENT_ID,
      TLO.SERVICE_ID        AS PARENT_SERVICE_ID,
      'DOPIP6' || '-' || to_char((CASE WHEN ar.ACTIVE_FROM < TLO.ACTUAL_START_DATE THEN TLO.ACTUAL_START_DATE ELSE ar.ACTIVE_FROM END), 'ddmmyyyy') || '1' AS SERVICE_ID, -- Обновим потом счетчиком
      SUBSTR(TLO.IDB_ID, instr(TLO.IDB_ID,'/', 1, 2) + 1, 100) AS SOURCE_ID, -- Из TLO.IDB_ID Выкинуть TI_ и биллинг
      TLO.SOURCE_SYSTEM     AS SOURCE_SYSTEM,
      TLO.SOURCE_SYSTEM_TYPE AS SOURCE_SYSTEM_TYPE,
      0                     AS TAX_MRC,
      0                     AS TOTAL_PRICE_TAX_NRC,
      tlo.ma_flag           AS ma_flag,
      tlo.ma_flag_date      AS ma_flag_date,
      rias_mgr_support.get_time_zone(ar.billing_id, 'N') AS BPI_TIME_ZONE,
      TLO.barring,
      '/64' AS PREFIX_SIZE,
      'V6RP/' || tlo.source_system || '/' || sn.ip_v6 || '/'|| sn.netmask AS IPV6RANGE,
      tlo.phase
    FROM idb_ph2_tbpi_int tlo,
         addendum_resources_all ar,
         resource_contents_all rc,
         cable_city_ip_subnets_all sn
    WHERE 1=1
    and tlo.phase = phase_id$i
      AND tlo.idb_id like 'TI_1/%'
      AND tlo.source_system_type = '1'
      AND ar.addendum_id = to_number(tlo.source_id)
      AND ar.billing_id = to_number(tlo.source_system)
      AND ar.active_from <= lv_current_date
      AND (ar.active_to IS NULL OR ar.active_to > lv_current_date)
      AND rc.resource_id = ar.resource_id
      AND rc.billing_id = ar.billing_id
      AND rc.active_from <= lv_current_date
      AND (rc.active_to IS NULL OR rc.active_to > lv_current_date)
      AND rc.terminal_resource_id=sn.terminal_resource_id
      AND rc.billing_id = sn.billing_id
      AND sn.ip_v6 IS NOT NULL
      AND NOT EXISTS (
              SELECT 1
                FROM activate_license_fee_all alf,
                     plan_items_all pi
               WHERE alf.addendum_id = ar.addendum_id
                 AND alf.billing_id = ar.billing_id
                 AND alf.active_from <= lv_current_date
                 AND (alf.active_to IS NULL OR alf.active_to > lv_current_date)
                 AND alf.plan_item_id = pi.plan_item_id
                 AND alf.billing_id = pi.billing_id
                 AND pi.service_id = 101572
                 AND rownum <= 1
      );
    TYPE t_arr IS TABLE OF cr_121000093%ROWTYPE;
    lv_arr t_arr;
  BEGIN
    OPEN cr_121000093;
    LOOP
      FETCH cr_121000093 BULK COLLECT INTO lv_arr LIMIT 100;
      EXIT WHEN lv_arr.count = 0;

      FORALL i IN 1 .. lv_arr.count
        INSERT INTO IDB_PH2_SBPI_INT(
      ACCOUNT_IDB_ID,
      ACTUAL_END_DATE,
      ACTUAL_START_DATE,
      AUTH_TYPE,
      BILLED_TO_DAT,
      CREATED_WHEN,
      CUSTOMER_IDB_ID,
      CUSTOMER_LOCATION,
      DIRECT_PROH,
      EXT_BPI_STATUS,
      EXT_BPI_STATUS_DATE,
      IDB_ID,
      INV_NAME,
      MRC,
      MRC_CUPON,
      LEGACY_OBJECT_NAME,
      OFF_ID_FOR_MIGR,
      PARENT_ID,
      PARENT_SERVICE_ID,
      SERVICE_ID,
      SOURCE_ID,
      SOURCE_SYSTEM,
      SOURCE_SYSTEM_TYPE,
      TAX_MRC,
      TOTAL_PRICE_TAX_NRC,
      MA_FLAG,
      MA_FLAG_DATE,
      BPI_TIME_ZONE,
      BARRING,
      PREFIX_SIZE,
      IPV6RANGE,
      phase
    )
        VALUES
          (
		lv_arr(i).ACCOUNT_IDB_ID,
      lv_arr(i).ACTUAL_END_DATE,
      lv_arr(i).ACTUAL_START_DATE,
      lv_arr(i).AUTH_TYPE,
      lv_arr(i).BILLED_TO_DAT,
      lv_arr(i).CREATED_WHEN,
      lv_arr(i).CUSTOMER_IDB_ID,
      lv_arr(i).CUSTOMER_LOCATION,
      lv_arr(i).DIRECT_PROH,
      lv_arr(i).EXT_BPI_STATUS,
      lv_arr(i).EXT_BPI_STATUS_DATE,
      lv_arr(i).IDB_ID,
      lv_arr(i).INV_NAME,
      lv_arr(i).MRC,
      lv_arr(i).MRC_CUPON,
      lv_arr(i).LEGACY_OBJECT_NAME,
      lv_arr(i).OFF_ID_FOR_MIGR,
      lv_arr(i).PARENT_ID,
      lv_arr(i).PARENT_SERVICE_ID,
      lv_arr(i).SERVICE_ID,
      lv_arr(i).SOURCE_ID,
      lv_arr(i).SOURCE_SYSTEM,
      lv_arr(i).SOURCE_SYSTEM_TYPE,
      lv_arr(i).TAX_MRC,
      lv_arr(i).TOTAL_PRICE_TAX_NRC,
      lv_arr(i).MA_FLAG,
      lv_arr(i).MA_FLAG_DATE,
      lv_arr(i).BPI_TIME_ZONE,
      lv_arr(i).BARRING,
      lv_arr(i).PREFIX_SIZE,
      lv_arr(i).IPV6RANGE,
      lv_arr(i).phase
);

    END LOOP;
    CLOSE cr_121000093;
  EXCEPTION
    WHEN OTHERS THEN
      IF cr_121000093%ISOPEN THEN
        CLOSE cr_121000093;
      END IF;
      RAISE_APPLICATION_ERROR(-20001, rias_mgr_support.get_error_stack);
  END fill_idb_ph2_sbpi_121000093;

  /**
  *
  */
  FUNCTION get_source_id_seq RETURN NUMBER
  IS
  BEGIN
    RETURN rias_mgr_source_id_revers_seq.nextval;
    --RETURN RIAS_MGR_SOURCE_ID_SEQ.NEXTVAL;
  END get_source_id_seq;

  /**
  * Заполнение таблицы IDB_PH2_NE_SERVICE_ID_P
  */
  PROCEDURE fill_idb_ph2_ne_service_id_p
  IS
  BEGIN
    INSERT /*+ append */ INTO IDB_PH2_NE_SERVICE_ID_P(
      NE_IDB_ID,
      SERVICE_ID,
      SHOW_ORDER,
      phase
    )
    SELECT
      NE.IDB_ID NE_IDB_ID,
      TLO.SERVICE_ID SERVICE_ID,
      --TO_CHAR((SELECT MAX(TO_NUMBER(SHOW_ORDER)) FROM IDB_PH2_NE_SERVICE_ID_P) + ROWNUM) SHOW_ORDER
      TO_CHAR(ROWNUM) SHOW_ORDER,
      tlo.phase
    FROM IDB_PH2_TBPI_INT TLO,
         IDB_PH2_NE NE
    WHERE 1 = 1
    and tlo.phase = phase_id$i
      AND TLO.IDB_ID LIKE 'TI_1/%'
      AND 'NE_' || TLO.IDB_ID = NE.IDB_ID;

  END fill_idb_ph2_ne_service_id_p;

  /**
  * Не учтена АП за белые ip в Иркутске в IDB
  * https://jsd.netcracker.com/browse/ERT-20421
  */
  PROCEDURE upd_903_121000087
  IS
    lv_task_1_id$i PLS_INTEGER;
    lv_task_2_id$i PLS_INTEGER;

    -- Подготовка данных. Этап 1
    FUNCTION prepare_data_1 RETURN PLS_INTEGER
    IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      lv_res$i PLS_INTEGER;
    BEGIN
      lv_res$i := rias_mgr_task_seq.nextval;
      INSERT /*+ append */ INTO rias_mgr_tmp_list(
        task_id,
        addendum_id,
        billing_id,
        num1,
        str1,
        str2,
        str3,
        str4,
        id1,
        num2,
        num3,
        customer_idb_id  --Воспользуемся не по назначению
      )
      SELECT lv_res$i,
             addendum_id,
             billing_id,
             case when is_ip_local = 1 then 0 else rias_mgr_support.get_service_cost(addendum_id,null,billing_id,1799,current_date,0) end mrc_calc,
             idb_id,
             ip_address,
             idb_id_addr,
             idb_id_old,
             is_ip_local, -- 0-белый/1-серый
             row_number() OVER (PARTITION BY billing_id, addendum_id ORDER BY billing_id, addendum_id, nm) AS cnt,
             row_number() OVER (PARTITION BY billing_id, addendum_id ORDER BY billing_id ASC, addendum_id ASC, is_ip_local DESC) AS cnt1,
             ipv4_type
        FROM (
              SELECT to_number(tb.source_id) AS addendum_id,
                      to_number(tb.source_system) AS billing_id,
                      null as mrc,
                      tb.idb_id,
                      tb.idb_id as idb_id_old,
                      nvl(ipt.ip_address, ippt.ip_address) AS ip_address,
                      tb.incl_ip4addr as idb_id_addr,
                      rias_mgr_support.is_ip_local(nvl(ipt.ip_address, ippt.ip_address)) AS is_ip_local,
                      1 AS nm, -- TLO
                      NVL((SELECT MAX(rup.threshold)
                        FROM activate_license_fee_all alf,
                             plan_items_all           pi,
                             plan_contents_all        pc,
                             simple_plan_items_all    sp,
                             ri_ulf_ps_contents_all   rup
                       WHERE 1 = 1
                         AND alf.addendum_id = to_number(tb.source_id)
                         AND alf.billing_id = to_number(tb.source_system)
                         AND alf.active_from <= current_date
                         AND (alf.active_to IS NULL OR alf.active_to > current_date)
                         AND pi.plan_item_id = alf.plan_item_id
                         AND pi.billing_id = alf.billing_id
                         AND pi.service_id = 1799
                         AND pc.plan_item_id = pi.plan_item_id
                         AND pc.billing_id = pi.billing_id
                         AND pc.active_from <= current_date
                         AND (pc.active_to IS NULL OR pc.active_to > current_date)
                         AND sp.plan_item_id = pc.plan_item_id
                         AND sp.billing_id = pc.billing_id
                         AND rup.rule_id = sp.rule_id
                         AND rup.billing_id = sp.billing_id
                         AND rup.threshold > 0), 0) AS threshold,
                     ipv4_type
                FROM idb_ph2_tbpi_int tb
                LEFT JOIN idb_ph2_ip_v4address ipt ON ipt.idb_id = tb.incl_ip4addr
                LEFT JOIN idb_ph2_ip_v4address_private ippt ON ippt.idb_id = tb.incl_ip4addr
               WHERE 1 = 1
               and tb.phase = phase_id$i
                 -- Иркутск
                 AND tb.source_system = 903
                 AND EXISTS (SELECT 1
                             FROM idb_ph2_sbpi_int t
                             WHERE 1 = 1
                               AND t.parent_id = tb.idb_id
                               -- Дополнительный IPv4 адрес
                               AND t.off_id_for_migr = '121000087'
                               -- Интернет
                               AND t.idb_id LIKE 'SI_1/%')
              UNION ALL

              SELECT to_number(substr(t.idb_id, instr(t.idb_id, '/', 1, 3) + 1, instr(t.idb_id, '/', 1, 4) - instr(t.idb_id, '/', 1, 3) - 1)) AS addendum_id,
                      to_number(t.source_system) AS billing_id,
                      t.mrc,
                      substr(t.idb_id, 1, instr(t.idb_id, t.ipv4adr)-2) as idb_id,
                      t.idb_id as idb_id_old,
                      nvl(ip.ip_address, ipp.ip_address) AS slo_ip_address,
                      t.ipv4adr as idb_id_adr,
                      rias_mgr_support.is_ip_local(nvl(ip.ip_address, ipp.ip_address)) AS is_ip_local,
                      2 AS nm, -- SLO
                      NVL((SELECT MAX(rup.threshold)
                            FROM activate_license_fee_all alf,
                                 plan_items_all           pi,
                                 plan_contents_all        pc,
                                 simple_plan_items_all    sp,
                                 ri_ulf_ps_contents_all   rup
                           WHERE 1 = 1
                             AND alf.addendum_id = to_number(substr(t.idb_id, instr(t.idb_id, '/', 1, 3) + 1, instr(t.idb_id, '/', 1, 4) - instr(t.idb_id, '/', 1, 3) - 1))
                             AND alf.billing_id = to_number(t.source_system)
                             AND alf.active_from <= current_date
                             AND (alf.active_to IS NULL OR alf.active_to > current_date)
                             AND pi.plan_item_id = alf.plan_item_id
                             AND pi.billing_id = alf.billing_id
                             AND pi.service_id = 1799
                             AND pc.plan_item_id = pi.plan_item_id
                             AND pc.billing_id = pi.billing_id
                             AND pc.active_from <= current_date
                             AND (pc.active_to IS NULL OR pc.active_to > current_date)
                             AND sp.plan_item_id = pc.plan_item_id
                             AND sp.billing_id = pc.billing_id
                             AND rup.rule_id = sp.rule_id
                             AND rup.billing_id = sp.billing_id
                             AND rup.threshold > 0),0) AS threshold,
                     ipv4_type
                FROM idb_ph2_sbpi_int t
                LEFT JOIN idb_ph2_ip_v4address ip ON ip.idb_id = t.ipv4adr
                LEFT JOIN idb_ph2_ip_v4address_private ipp ON ipp.idb_id = t.ipv4adr
               WHERE 1 = 1
               and t.phase = phase_id$i
                 -- Иркутск
                 AND t.source_system = 903
                 -- Дополнительный IPv4 адрес
                 AND t.off_id_for_migr = '121000087'
                 -- Интернет
                 AND t.idb_id LIKE 'SI_1/%'
                 ) tabl
       WHERE threshold = 1;
       COMMIT;
      RETURN lv_res$i;
    END prepare_data_1;

    -- Подготовка данных. Этап 2
    FUNCTION prepare_data_2(ip_task_id$i IN PLS_INTEGER) RETURN PLS_INTEGER
    IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      lv_res$i PLS_INTEGER;
    BEGIN
      lv_res$i := rias_mgr_task_seq.nextval;

      INSERT /*+ append */ INTO RIAS_MGR_TMP_LIST(
        task_id,
        str1, -- idb_id
        str2, -- idb_id_old
        str3, -- idb_id_addr
        num1, -- mrc
        num2  -- tax_mrc
        ,str4
      )
      SELECT lv_res$i,
        CASE
          WHEN SUBSTR(bpi.idb_id, 1, 2) = 'SI' THEN
            bpi.idb_id || '/' || ip.idb_id_addr
          ELSE
            bpi.idb_id
        END as idb_id,
        bpi.idb_id_old,
        ip.idb_id_addr,
        CASE
          WHEN SUBSTR(bpi.idb_id, 1, 2) = 'SI' THEN
            ROUND(ip.mrc * rias_mgr_support.get_nds(1799, 903),2)
          ELSE
            NULL
        END * 100000 as mrc,
        CASE
          WHEN SUBSTR(bpi.idb_id, 1, 2) = 'SI' THEN
            round(ip.mrc * (rias_mgr_support.get_nds(1799, 903) - 1) , 2)
          ELSE
            NULL
        END * 100000 as tax_mrc,
        ip.ipv4_type
      FROM
      (
        SELECT addendum_id, billing_id, num2, str1 as idb_id, str4 as idb_id_old
        FROM rias_mgr_tmp_list
        WHERE task_id = ip_task_id$i
      ) bpi,
      (
        SELECT addendum_id, billing_id, num3, num1 as mrc, str2 as ip_address, id1 as is_ip_local, str3 as idb_id_addr, customer_idb_id as ipv4_type
        FROM rias_mgr_tmp_list
        WHERE task_id = ip_task_id$i
      ) ip
      WHERE 1=1
        AND bpi.addendum_id = ip.addendum_id
        AND bpi.billing_id = ip.billing_id
        AND bpi.num2=ip.num3;

      COMMIT;

      RETURN lv_res$i;
    END prepare_data_2;
  BEGIN
    -- Если запрещена работа, то выходим
    IF rias_mgr_core.get_feature_toggle(2) = 0 THEN
      RETURN;
    END IF;

    lv_task_1_id$i := prepare_data_1;
    lv_task_2_id$i := prepare_data_2(lv_task_1_id$i);
    -- Обновить данные
    /*
    select
      str1 as idb_id,
      str2 as idb_id_old,
      str3 as idb_id_addr,
      num1 as mrc,
      num2 as tax_mrc,
      str4 as ipv4_type
    from RIAS_MGR_TMP_LIST
    where task_id = 2
      and str2 LIKE 'SI_1/%'
    */
    -- TLO
    UPDATE /*+ append */ idb_ph2_tbpi_int tab
       SET (tab.incl_ip4addr, tab.ipv4_type, tab.ip_method_assign, tab.dedicated_ipaddressing)=
           (SELECT str3,
                   str4,
                   CASE WHEN str3 IS NOT NULL THEN 'Статический' ELSE 'Динамический' END,
                   CASE WHEN str3 IS NOT NULL THEN 'Да' ELSE 'Нет' END
              FROM rias_mgr_tmp_list t
             WHERE t.task_id = lv_task_2_id$i
               AND t.str1 = tab.idb_id)
     WHERE tab.rowid IN (SELECT tlo.rowid
                           FROM rias_mgr_tmp_list tl,
                                idb_ph2_tbpi_int  tlo
                          WHERE tlo.phase = phase_id$i and tl.task_id = lv_task_2_id$i
                            AND str2 LIKE 'TI_1/%'
                            AND tl.str2 = tlo.idb_id);

/*
    SELECT tab.idb_id, tab.incl_ip4addr,
           (SELECT str3
              FROM rias_mgr_tmp_list t
             WHERE t.task_id = (SELECT MAX(task_id) FROM rias_mgr_tmp_list)--lv_task_2_id$i
               AND t.str1 = tab.idb_id)
    FROM idb_ph2_tbpi_int tab
     WHERE tab.rowid IN (SELECT tlo.rowid
                           FROM rias_mgr_tmp_list tl,
                                idb_ph2_tbpi_int  tlo
                          WHERE tl.task_id = (SELECT MAX(task_id) FROM rias_mgr_tmp_list)--lv_task_2_id$i
                            AND str2 LIKE 'TI_1/%'
                            AND tl.str2 = tlo.idb_id);
*/
    -- SLO
    UPDATE /*+ append */ idb_ph2_sbpi_int tab
       SET (tab.idb_id,
            tab.ipv4adr,
            tab.mrc,
            tab.tax_mrc,
            tab.ipv4_type) =
           (SELECT str1,
                   str3,
                   num1,
                   num2,
                   str4
              FROM rias_mgr_tmp_list t
             WHERE t.task_id = lv_task_2_id$i
               AND t.str2 = tab.idb_id)
     WHERE tab.rowid IN (SELECT slo.rowid
                           FROM rias_mgr_tmp_list tl,
                                idb_ph2_sbpi_int  slo
                          WHERE slo.phase = phase_id$i and tl.task_id = lv_task_2_id$i
                            AND str2 LIKE 'SI_1/%'
                            AND tl.str2 = slo.idb_id);
  /*
  SELECT tab.idb_id, tab.ipv4adr, tab.mrc, tab.tax_mrc, tab.ipv4_type
  FROM idb_ph2_sbpi_int tab
  WHERE tab.rowid IN (SELECT slo.rowid
                      FROM rias_mgr_tmp_list tl,
                           idb_ph2_sbpi_int  slo
                      WHERE tl.task_id = (SELECT MAX(task_id) FROM rias_mgr_tmp_list)
                        AND str2 LIKE 'SI_1/%'
                        AND tl.str2 = slo.idb_id);
  */
    -- Почистим временную таблицу
    clear_tmp_data(ip_task_id => lv_task_2_id$i);
    clear_tmp_data(ip_task_id => lv_task_1_id$i);

  END upd_903_121000087;

  /**
  * Перекинуть "белые" IP из TLO в SLO (с созданием новых)
  */
  PROCEDURE upd_903_121000087_tlo_white
  IS
    TYPE t_rec IS RECORD(
      access_cred_pppoe_acc VARCHAR2(150),
      account_idb_id        VARCHAR2(150),
      actual_start_date     DATE,
      actual_end_date       DATE,
      auth_type             VARCHAR2(200),
      barring               VARCHAR2(1),
      billed_to_dat         DATE,
      bpi_market            VARCHAR2(200),
      bpi_organization      VARCHAR2(200),
      bpi_time_zone         NUMBER,
      created_when          DATE,
      customer_idb_id       VARCHAR2(150),
      customer_location     VARCHAR2(150),
      direct_proh           VARCHAR2(200),
      ext_bpi_status        VARCHAR2(200),
      ext_bpi_status_date   DATE,
      idb_id                VARCHAR2(150),
      inv_name              VARCHAR2(200),
      ipv4adr               VARCHAR2(150),
      ipv4_type             VARCHAR2(200),
      ma_flag               VARCHAR2(200),
      ma_flag_date          DATE,
      mrc                   NUMBER,
      mrc_cupon             NUMBER,
      mrc_cupon_mnt         NUMBER,
      network               VARCHAR2(200),
      off_id_for_migr       VARCHAR2(20),
      ots_status            VARCHAR2(200),
      parent_id             VARCHAR2(150),
      service_id            VARCHAR2(31),
      source_id             VARCHAR2(100),
      source_system         VARCHAR2(20),
      source_system_type    VARCHAR2(20),
      tax_mrc               NUMBER,
      total_price_tax_nrc   NUMBER,
      -- Для сохранения tlo.idb_id
      -- Необходимо для переопределения ссылки в таблицах IDB_PH2_ACCESS_CRED и IDB_PH2_NET_ACCESS
      -- с TLO на SLO
      project                VARCHAR2(150),
      -- Вспомагательные
      active_to             DATE,
      tlo_ext_bpi_status_date DATE,
      phase                  NUMBER
    );
    lv_rec t_rec;
    TYPE t_arr IS TABLE OF t_rec INDEX BY PLS_INTEGER;
    lv_arr t_arr;
  BEGIN
    -- Если запрещена работа, то выходим
    IF rias_mgr_core.get_feature_toggle(2) = 0 THEN
      RETURN;
    END IF;
    --
    SELECT
      NULL AS access_cred_pppoe_acc,
      account_idb_id,
      actual_start_date,
      NULL AS actual_end_date,
      auth_type,
      barring,
      billed_to_dat,
      bpi_market,
      bpi_organization,
      bpi_time_zone,
      CASE
        WHEN tbl.actual_start_date < tbl.tlo_actual_start_date THEN
          tbl.actual_start_date
        ELSE
          (SELECT TRUNC(fta.time_stamp)
            FROM activate_lic_fee_timestamp_all fta
           WHERE fta.activity_id = tbl.activity_id
             AND fta.billing_id = tbl.billing_id)
      END AS created_when,
      customer_idb_id,
      customer_location,
      direct_proh,
      CASE
        WHEN rias_mgr_support.get_service_active_to(1799, tbl.agreement_id, tbl.billing_id) BETWEEN TRUNC(rias_mgr_support.get_current_date, 'MM') AND rias_mgr_support.get_current_date THEN
          'Disconnected'
        ELSE
          'Active'
      END AS ext_bpi_status,
      NULL AS ext_bpi_status_date,
      'SI_1/'|| TO_CHAR(tbl.billing_id)   || '/' ||
                TO_CHAR(tbl.agreement_id) || '/' ||
                TO_CHAR(tbl.addendum_id)  || '/' ||
                TO_CHAR(tbl.plan_item_id) || '/' ||
                TO_CHAR(tbl.activity_id)  || '/' ||
                ipv4adr AS idb_id,
      'Дополнительный IPv4 адрес' AS inv_name,
      ipv4adr,
      ipv4_type,
      ma_flag,
      ma_flag_date,
      ROUND(rias_mgr_support.get_service_cost(tbl.addendum_id, null, tbl.billing_id, 1799, rias_mgr_support.get_current_date, 0) *
            rias_mgr_support.get_nds(1799, 903), 2)  * 100000 as mrc,
      NULL as mrc_cupon,
      NULL AS mrc_cupon_mnt,
      network,
      '121000087' AS off_id_for_migr,
      'Billed' AS ots_status,
      parent_id,
      ((SELECT d.prefix
        FROM idb_ph2_offerings_dic d
        WHERE d.idb_table_name = 'IDB_PH2_SBPI_INT'
          AND d.off_id_for_migr = '121000087')
        || '-' || to_char(tbl.actual_start_date, 'ddmmyyyy') || '1'
       ) AS service_id,
       source_id,
       source_system,
       source_system_type,
      ROUND(rias_mgr_support.get_service_cost(addendum_id, null, billing_id, 1799, rias_mgr_support.get_current_date, 0) *
            (rias_mgr_support.get_nds(1799, 903) - 1) , 2) * 100000 as tax_mrc,
      0 as total_price_tax_nrc,
      -- Сохраним ссылку на TLO для обновления полей в таблицах IDB_PH2_ACCESS_CRED и IDB_PH2_NET_ACCESS
      parent_id AS project,
      rias_mgr_support.get_service_active_to(1799, agreement_id, billing_id) as active_to,
      tlo_ext_bpi_status_date,
      phase
    BULK COLLECT INTO lv_arr
    FROM (
      SELECT
        CASE
          WHEN rias_mgr_support.get_service_active_from(1799, to_number(tb.source_id), to_number(tb.source_system)) < tb.actual_start_date THEN
            tb.actual_start_date
          ELSE
            rias_mgr_support.get_service_active_from(1799, to_number(tb.source_id), to_number(tb.source_system))
        END AS actual_start_date,
        tb.account_idb_id,
        tb.actual_start_date as tlo_actual_start_date,
        tb.auth_type,
        tb.barring,
        tb.billed_to_dat,
        tb.bpi_market,
        tb.bpi_organization,
        tb.bpi_time_zone,
        tb.parent_id as customer_idb_id,
        tb.customer_location,
        tb.direct_proh,
        tb.incl_ip4addr AS ipv4adr,
        tb.ipv4_type,
        tb.ma_flag,
        tb.ma_flag_date,
        tb.network AS network,
        tb.idb_id AS parent_id,
        tb.ext_bpi_status_date as tlo_ext_bpi_status_date,
        tb.source_id          AS source_id,
        tb.source_system      AS source_system,
        tb.source_system_type AS source_system_type,
        to_number(SUBSTR(tb.idb_id, INSTR(tb.idb_id,'/', 1, 2) + 1, INSTR(tb.idb_id,'/', 1, 3) - INSTR(tb.idb_id,'/', 1, 2) - 1)) AS agreement_id,
        to_number(tb.source_id) AS addendum_id,
        to_number(tb.source_system) AS billing_id,
        -- Получить activity_id для service_id = 1799
        (SELECT alf.activity_id
         FROM plan_items_all pi,
              activate_license_fee_all alf
         WHERE alf.addendum_id = to_number(tb.source_id)
         AND alf.billing_id = to_number(tb.source_system)
         AND alf.active_from <= rias_mgr_support.get_current_date
         AND (alf.active_to IS NULL OR alf.active_to > rias_mgr_support.get_current_date)
         AND pi.plan_item_id = alf.plan_item_id
         AND pi.billing_id = alf.billing_id
         AND pi.service_id = 1799
        ) AS activity_id,
        -- Получить plan_item_id для service_id = 1799
        (SELECT alf.plan_item_id
         FROM plan_items_all pi,
              activate_license_fee_all alf
         WHERE alf.addendum_id = to_number(tb.source_id)
         AND alf.billing_id = to_number(tb.source_system)
         AND alf.active_from <= rias_mgr_support.get_current_date
         AND (alf.active_to IS NULL OR alf.active_to > rias_mgr_support.get_current_date)
         AND pi.plan_item_id = alf.plan_item_id
         AND pi.billing_id = alf.billing_id
         AND pi.service_id = 1799
        ) AS plan_item_id,
        --
        rias_mgr_support.is_ip_local(nvl(ipt.ip_address, ippt.ip_address)) AS is_ip_local,
        NVL((SELECT MAX(rup.threshold)
             FROM activate_license_fee_all alf,
                  plan_items_all           pi,
                  plan_contents_all        pc,
                  simple_plan_items_all    sp,
                  ri_ulf_ps_contents_all   rup
            WHERE 1 = 1
              AND alf.addendum_id = to_number(tb.source_id)
              AND alf.billing_id = to_number(tb.source_system)
              AND alf.active_from <= rias_mgr_support.get_current_date
              AND (alf.active_to IS NULL OR alf.active_to > rias_mgr_support.get_current_date)
              AND pi.plan_item_id = alf.plan_item_id
              AND pi.billing_id = alf.billing_id
              AND pi.service_id = 1799
              AND pc.plan_item_id = pi.plan_item_id
              AND pc.billing_id = pi.billing_id
              AND pc.active_from <= rias_mgr_support.get_current_date
              AND (pc.active_to IS NULL OR pc.active_to > rias_mgr_support.get_current_date)
              AND sp.plan_item_id = pc.plan_item_id
              AND sp.billing_id = pc.billing_id
              AND rup.rule_id = sp.rule_id
              AND rup.billing_id = sp.billing_id
              AND rup.threshold > 0), 0) AS threshold,
              tb.phase
      FROM idb_ph2_tbpi_int tb
      LEFT JOIN idb_ph2_ip_v4address ipt ON ipt.idb_id = tb.incl_ip4addr
      LEFT JOIN idb_ph2_ip_v4address_private ippt ON ippt.idb_id = tb.incl_ip4addr
      WHERE 1 = 1
      and tb.phase = phase_id$i
        AND tb.idb_id LIKE 'TI_1/%'
        -- Иркутск
        AND tb.source_system = '903'
        --
        AND tb.incl_ip4addr IS NOT NULL
        /*
        AND EXISTS (SELECT 1
                    FROM idb_ph2_sbpi_int t
                    WHERE 1 = 1
                      AND t.parent_id = tb.idb_id
                      -- Дополнительный IPv4 адрес
                      AND t.off_id_for_migr = '121000087'
                      -- Интернет
                      AND t.idb_id LIKE 'SI_1/%')
        */
    ) tbl
    WHERE 1 = 1
      AND threshold = 1
      AND is_ip_local = 0;
    -- Довычислим, что не смогли сразу
    FOR i IN 1..lv_arr.count LOOP
      --
      lv_arr(i).actual_end_date :=
        CASE
          WHEN lv_arr(i).ext_bpi_status = 'Active' AND lv_arr(i).active_to > rias_mgr_support.get_current_date THEN
            NULL
          ELSE
            lv_arr(i).active_to - 1
          END;
      --
      lv_arr(i).ext_bpi_status_date :=
        CASE
          WHEN lv_arr(i).ext_bpi_status = 'Active' THEN
            lv_arr(i).actual_start_date
          WHEN lv_arr(i).ext_bpi_status = 'Disconnected' THEN
            lv_arr(i).actual_end_date
          WHEN lv_arr(i).ext_bpi_status = 'Suspended' THEN
            lv_arr(i).tlo_ext_bpi_status_date
        END;
    END LOOP;
    -- Обновить TLO
    FORALL i IN 1..lv_arr.count
      UPDATE /*+ append */ idb_ph2_tbpi_int tlo SET tlo.incl_ip4addr = NULL
      WHERE tlo.idb_id = lv_arr(i).parent_id;
    --dbms_output.put_line('Изменено TLO '||sql%rowcount);

    -- Добавим записи в SLO
    FORALL i IN 1..lv_arr.count
      INSERT /*+ append*/ INTO idb_ph2_sbpi_int(
        access_cred_pppoe_acc,
        account_idb_id,
        actual_start_date,
        actual_end_date,
        auth_type,
        barring,
        billed_to_dat,
        bpi_market,
        bpi_organization,
        bpi_time_zone,
        created_when,
        customer_idb_id,
        customer_location,
        direct_proh,
        ext_bpi_status,
        ext_bpi_status_date,
        idb_id,
        inv_name,
        ipv4adr,
        ipv4_type,
        ma_flag,
        ma_flag_date,
        mrc,
        mrc_cupon,
        mrc_cupon_mnt,
        network,
        off_id_for_migr,
        ots_status,
        parent_id,
        service_id,
        source_id,
        source_system,
        source_system_type,
        tax_mrc,
        total_price_tax_nrc,
        project,
        phase
      )
      VALUES(
        lv_arr(i).access_cred_pppoe_acc,
        lv_arr(i).account_idb_id,
        lv_arr(i).actual_start_date,
        lv_arr(i).actual_end_date,
        lv_arr(i).auth_type,
        lv_arr(i).barring,
        lv_arr(i).billed_to_dat,
        lv_arr(i).bpi_market,
        lv_arr(i).bpi_organization,
        lv_arr(i).bpi_time_zone,
        lv_arr(i).created_when,
        lv_arr(i).customer_idb_id,
        lv_arr(i).customer_location,
        lv_arr(i).direct_proh,
        lv_arr(i).ext_bpi_status,
        lv_arr(i).ext_bpi_status_date,
        lv_arr(i).idb_id,
        lv_arr(i).inv_name,
        lv_arr(i).ipv4adr,
        lv_arr(i).ipv4_type,
        lv_arr(i).ma_flag,
        lv_arr(i).ma_flag_date,
        lv_arr(i).mrc,
        lv_arr(i).mrc_cupon,
        lv_arr(i).mrc_cupon_mnt,
        lv_arr(i).network,
        lv_arr(i).off_id_for_migr,
        lv_arr(i).ots_status,
        lv_arr(i).parent_id,
        lv_arr(i).service_id,
        lv_arr(i).source_id,
        lv_arr(i).source_system,
        lv_arr(i).source_system_type,
        lv_arr(i).tax_mrc,
        lv_arr(i).total_price_tax_nrc,
        lv_arr(i).project,
        lv_arr(i).phase
      );
      --dbms_output.put_line('Добавлено SLO '||sql%rowcount);
  END upd_903_121000087_tlo_white;

  /**
  * Обновить ссылки в таблицах IDB_PH2_ACCESS_CRED и IDB_PH2_NET_ACCESS
  * вновь созданных SLO из TLO для "былых" доп.IP
  * Иркутск
  */
  PROCEDURE upd_903_121000087_na_ac
  IS
    TYPE t_rec IS RECORD(
      tlo_idb_id     idb_ph2_tbpi_int.idb_id%TYPE,
      bpi_idb_id     idb_ph2_access_cred.bpi_idb_id%TYPE,
      bss_service_id idb_ph2_access_cred.bss_service_id%TYPE,
      idb_id         idb_ph2_access_cred.idb_id%TYPE,
      name           idb_ph2_access_cred.name%TYPE,
      phase          idb_ph2_access_cred.phase%TYPE
    );
    TYPE t_arr IS TABLE OF t_rec INDEX BY PLS_INTEGER;
    lv_arr t_arr;
    -- Данные для обновления IDB_PH2_ACCESS_CRED
    CURSOR crs_data_ac IS
      SELECT t.idb_id     AS tlo_idb_id,
             s.idb_id     AS bpi_idb_id,
             s.service_id AS bss_service_id,
             ac.idb_id    AS ac_idb_id,
             replace(ac.name, t.service_id, s.service_id) as new_name,
             t.phase
      FROM idb_ph2_tbpi_int t,
      -- Через project закрепили ссылку на TLO, по ктр создали SLO для "белого" доп. IP
      -- в  upd_903_121000087_tlo_white
           idb_ph2_sbpi_int s,
           idb_ph2_access_cred ac
      WHERE 1=1
        AND t.idb_id LIKE 'TI_1/%'
        --AND t.access_cred_tbpi_int IS NOT NULL
        AND s.idb_id LIKE 'SI_1/%'
        AND s.project = t.idb_id
        AND ac.idb_id LIKE 'AC_1/TI_1/%'
        AND ac.bpi_idb_id = t.idb_id
        and s.phase = phase_id$i;

    -- Данные для обновления IDB_PH2_NET_ACCESS
    CURSOR crs_data_na IS
      SELECT t.idb_id     AS tlo_idb_id,
             s.idb_id     AS bpi_idb_id,
             s.service_id AS bss_service_id,
             na.idb_id    AS na_idb_id,
             replace(na.name, t.service_id, s.service_id) as new_name,
             t.phase
      FROM idb_ph2_tbpi_int t,
      -- Через project закрепили ссылку на TLO, по ктр создали SLO для "белого" доп. IP
      -- в  upd_903_121000087_tlo_white
           idb_ph2_sbpi_int s,
           idb_ph2_net_access na
      WHERE 1=1
      and t.phase = phase_id$i
        AND t.idb_id LIKE 'TI_1/%'
        AND s.idb_id LIKE 'SI_1/%'
        AND s.project = t.idb_id
        AND na.idb_id LIKE 'NEA_TI_1/%'
        AND na.bpi_idb_id = t.idb_id;

  BEGIN
    -- Если запрещена работа, то выходим
    -- ровно как в upd_903_121000087_tlo_white
    -- должны работать одинаково - либо работаем, либо нет
    IF rias_mgr_core.get_feature_toggle(2) = 0 THEN
      RETURN;
    END IF;
    ----------------------
    -- IDB_PH2_NET_ACCESS
    ----------------------
    BEGIN
      OPEN crs_data_na;
      LOOP
        FETCH crs_data_na BULK COLLECT INTO lv_arr LIMIT 10000;
        EXIT WHEN lv_arr.count = 0;
        -- Обновим поля в таблице IDB_PH2_NET_ACCESS
        FORALL i IN 1 .. lv_arr.count
          UPDATE /*+ append */ idb_ph2_net_access t
             SET t.bpi_idb_id = lv_arr(i).bpi_idb_id,
                 t.event_source = lv_arr(i).bss_service_id,
                 t.bss_service_id = lv_arr(i).bss_service_id,
                 t.name = lv_arr(i).name
           WHERE t.idb_id = lv_arr(i).idb_id and t.phase = lv_arr(i).phase;
        COMMIT;
      END LOOP;
      CLOSE crs_data_na;
    EXCEPTION
      WHEN OTHERS THEN
        IF crs_data_na%ISOPEN
        THEN
          CLOSE crs_data_na;
        END IF;
        raise_application_error(-20001, rias_mgr_support.get_error_stack);
    END;

    ----------------------
    -- IDB_PH2_ACCESS_CRED
    ----------------------
    lv_arr.delete;
    BEGIN
      OPEN crs_data_ac;
      LOOP
        FETCH crs_data_ac BULK COLLECT INTO lv_arr LIMIT 10000;
        EXIT WHEN lv_arr.count = 0;
        -- Скинем поле access_cred_tbpi_int в TLO
        FORALL i IN 1 .. lv_arr.count
          UPDATE /*+ append */ idb_ph2_tbpi_int t
             SET t.access_cred_tbpi_int = NULL
           WHERE t.idb_id = lv_arr(i).tlo_idb_id and t.phase = lv_arr(i).phase;
        -- Обновим поле access_cred_pppoe_acc в SLO
        FORALL i IN 1 .. lv_arr.count
          UPDATE /*+ append */ idb_ph2_sbpi_int t
             SET t.access_cred_pppoe_acc = lv_arr(i).idb_id,
                 t.project = NULL
           WHERE t.idb_id = lv_arr(i).bpi_idb_id and t.phase = lv_arr(i).phase;
        -- Обновим поля в таблице IDB_PH2_ACCESS_CRED
        FORALL i IN 1 .. lv_arr.count
          UPDATE /*+ append */ idb_ph2_access_cred t
             SET t.bpi_idb_id = lv_arr(i).bpi_idb_id,
                 t.bss_service_id = lv_arr(i).bss_service_id,
                 t.name = lv_arr(i).name
           WHERE t.idb_id = lv_arr(i).idb_id and t.phase = lv_arr(i).phase;
        COMMIT;
      END LOOP;
      CLOSE crs_data_ac;
    EXCEPTION
      WHEN OTHERS THEN
        IF crs_data_ac%ISOPEN
        THEN
          CLOSE crs_data_ac;
        END IF;
        raise_application_error(-20001, rias_mgr_support.get_error_stack);
    END;
  END upd_903_121000087_na_ac;

  /**
  * Заполнение таблицы IDB_PH2_CUSTOMER_USERS
  * Подписчики клиента
  *
  */
  PROCEDURE fill_customer_users(ip_phase IN PLS_INTEGER DEFAULT 2)
  IS
    lv_delta_const CONSTANT NUMBER := 200000;
  BEGIN
    -- 0. Очисить таблицу
    DELETE /*+ append */ FROM idb_ph2_customer_users WHERE source_system_type = '1' and phase = ip_phase;
    COMMIT;

    -- 1. Добавить с профиля ЛК
    INSERT /*+ append */ INTO idb_ph2_customer_users(
      dmp_id,
      email,
      first_name,
      idb_id,
      parent_id,
      phone_number_1,
      source_id,
      source_system,
      source_system_type,
      is_default,
      last_name,
      to_sso,
      phase
    )
    SELECT RandomUUID() as dmp_id,
           email,
           first_name,
           idb_id,
           parent_id,
           phone_number_1,
           source_id,
           source_system,
           '1' as source_system_type,
           (CASE
             WHEN EXISTS(SELECT 1 FROM /*customer_many_all*/idb_ph2_customer cst WHERE cst.idb_id = s.parent_id AND LOWER(TRIM(cst.email)) = s.email) THEN
               'Yes'
             ELSE
               'No'
            END) as is_default,
           'PROFILE',
           'Y',
           ip_phase
    FROM (
          SELECT DISTINCT
            REGEXP_REPLACE( LOWER(TRIM(cp.email)), '[[:cntrl:]]', NULL ) as email,
            --LOWER(TRIM(cp.email)) email,
            substr(coalesce(REGEXP_REPLACE(cp.nickname, '[[:cntrl:]]', NULL ), 'заглушка'), 1, 120) first_name,
            'CU_1/' || to_char(cp.billing_id) || '/' || to_char(cp.client_profile_id) || '/' || substr(acc.parent_id, instr(acc.parent_id, '/', -1, 1) + 1, 150) idb_id,
            acc.parent_id parent_id,
            to_char(cp.client_profile_id) source_id,
            to_char(cp.billing_id) source_system,
            cp.phone_number phone_number_1
          FROM idb_ph2_account               acc,
               client_profiles_all           cp,
               client_profile_agreements_all cpa
          WHERE 1 = 1
             AND cp.email IS NOT NULL AND cp.phone_number IS NOT NULL
             AND cpa.client_profile_id = cp.client_profile_id
             AND cpa.billing_id = cp.billing_id
             AND to_number(acc.source_system) = cpa.billing_id
             AND to_number(acc.source_id) = cpa.agreement_id
             AND cpa.active_from <= current_date
             AND (cpa.active_to IS NULL OR cpa.active_to > current_date)
             AND acc.source_system_type = '1'
             AND acc.phase = ip_phase
             AND cp.client_profile_id = (SELECT MAX(cp1.client_profile_id)
                                          FROM idb_ph2_account               acc1,
                                               client_profiles_all           cp1,
                                               client_profile_agreements_all cpa1
                                          WHERE 1 = 1
                                             and acc1.parent_id = acc.parent_id
                                             AND acc1.source_system = acc.source_system
                                             AND acc1.source_system_type = acc.source_system_type
                                             AND cp1.email IS NOT NULL AND cp1.phone_number IS NOT NULL
                                             AND cpa1.client_profile_id = cp1.client_profile_id
                                             AND cpa1.billing_id = cp1.billing_id
                                             AND to_number(acc1.source_system) = cpa1.billing_id
                                             AND to_number(acc1.source_id) = cpa1.agreement_id
                                             AND cpa1.active_from <= current_date
                                             AND (cpa1.active_to IS NULL OR cpa1.active_to > current_date)
                                             AND acc1.source_system_type = '1')
/*
          SELECT DISTINCT
            nvl(LOWER(TRIM(cp.email)), 'zaglushka@test.ru') email,
            substr(coalesce(cp.nickname, 'заглушка'), 1, 120) first_name,
            'CU_1/' || to_char(cp.billing_id) || '/' || to_char(cp.client_profile_id) || '/' || substr(acc.parent_id, instr(acc.parent_id, '/', -1, 1) + 1, 150) idb_id,
            acc.parent_id parent_id,
            to_char(cp.client_profile_id) source_id,
            to_char(cp.billing_id) source_system,
            nvl(cp.phone_number, 12345678900) phone_number_1
          FROM idb_ph2_account               acc,
               client_profiles_all           cp,
               client_profile_agreements_all cpa
          WHERE 1 = 1
             AND cp.email IS NOT NULL AND cp.phone_number IS NOT NULL
             AND cpa.client_profile_id = cp.client_profile_id
             AND cpa.billing_id = cp.billing_id
             AND to_number(acc.source_system) = cpa.billing_id
             AND to_number(acc.source_id) = cpa.agreement_id
             AND cpa.active_from <= current_date
             AND (cpa.active_to IS NULL OR cpa.active_to > current_date)
             AND acc.source_system_type = '1'
*/
       ) s;
    COMMIT;

    -- 2. Добавить с карточки клиента
    INSERT /*+ append */ INTO idb_ph2_customer_users(
      dmp_id,
      email,
      first_name,
      idb_id,
      parent_id,
      phone_number_1,
      source_id,
      source_system,
      source_system_type,
      is_default,
      last_name,
      to_sso,
      phase
    )
    SELECT RandomUUID() as dmp_id,
           LOWER(TRIM(cst.email)) as email,
           SUBSTR(cst.company_name, 1, 120) as first_name,
           'CU_1/' || cst.source_system || '/' || to_char(lv_delta_const + rownum) || '/' || cst.source_id as idb_id,
           cst.idb_id as parent_id,
           to_number(CASE WHEN substr(cst.phone_number, 3, 1) = '8' THEN '7' ELSE substr(cst.phone_number, 3, 1) END || substr(cst.phone_number, 5)) as phone_number_1,
           to_char(lv_delta_const + rownum) as source_id,
           cst.source_system,
           cst.source_system_type,
           'Yes' as is_default,
           'CUSTOMER',
           'N',
           ip_phase
    FROM idb_ph2_customer cst,
         idb_ph2_customer_users cu
    WHERE 1 = 1
      AND cst.source_system_type = '1'
      AND cst.phase = ip_phase
      AND cu.parent_id(+) = cst.idb_id
      AND cu.email(+) = LOWER(TRIM(cst.email))
      ----AND to_char(cu.phone_number_1(+)) = replace(replace(cst.phone_number, '(8)', '(7)'), '+(7)', '7')
      --AND cu.phone_number_1(+) = to_number(substr(cst.phone_number, 3, 1) || substr(cst.phone_number, 5))
      AND cu.source_system_type(+) = '1'
      AND cu.phase(+) = ip_phase
      AND cu.rowid IS NULL;

    COMMIT;

  END fill_customer_users;

  /**
  * Обновление поля IS_ACCOUNT_IN_SSO таблицы IDB_PH2_CUSTOMER
  * Признак наличия учетной записи абонента в системе самообслуживания
  *
  */
  PROCEDURE upd_customer_is_account_in_sso(ip_phase IN PLS_INTEGER DEFAULT 2)
  IS
  BEGIN
    UPDATE /*+ append */ idb_ph2_customer SET is_account_in_sso = NULL 
    WHERE source_system_type = '1'
      AND phase = ip_phase;
    COMMIT;
    --
    UPDATE /*+ append */ idb_ph2_customer t SET is_account_in_sso = 'Да'
    WHERE 1=1
      AND source_system_type = '1'
      AND phase = ip_phase
      AND EXISTS(SELECT 1 FROM idb_ph2_customer_users us WHERE us.parent_id = t.idb_id AND us.to_sso = 'Y');
    COMMIT;
    --
    UPDATE /*+ append */ idb_ph2_customer t SET is_account_in_sso = 'Нет'
    WHERE 1=1
      AND t.source_system_type = '1'
      AND phase = ip_phase
      AND t.is_account_in_sso IS NULL;
    COMMIT;


    /*
      1. На IDB_PH2_CUSTOMER в поле "EMAIL" стоит заглушка "zaglyshka@zaglyskha.domru.ru"                  -> 'Нет'
      2. На IDB_PH2_CUSTOMER в поле "PHONE_NUMBER" стоит заглушка "+(7)9999911111"                         -> 'Нет'
      3. На разных клиентах (IDB_ID разные) стоят одинаковые "EMAIL" и "PHONE_NUMBER" (исключить заглушки) -> 'Да'
      4. На разных клиентах (IDB_ID разные) стоят одинаковые "EMAIL" и разные "PHONE_NUMBER" (исключить заглушки) -> 'Нет'
      5. На разных клиентах (IDB_ID разные) стоят разные "EMAIL" и одинаковые "PHONE_NUMBER" (исключить заглушки) -> 'Нет'
      6. 'Да'
    */
/*
    -- Обнулим все записи в часть IS_ACCOUNT_IN_SSO
    UPDATE \*+ append *\ idb_ph2_customer SET is_account_in_sso = NULL
    WHERE source_system_type = '1';

    COMMIT;
    ----
    -- 1
    ----
    UPDATE \*+ append *\ IDB_PH2_CUSTOMER t SET t.is_account_in_sso = 'Нет'
    WHERE 1=1
      AND t.rowid IN (SELECT tab.rowid
                      FROM
                        IDB_PH2_CUSTOMER tab,
                        IDB_PH2_CUSTOMER_USERS us
                      WHERE 1=1
                        AND tab.source_system_type = '1'
                        AND us.PARENT_ID = tab.IDB_ID
                        AND us.is_default = 'Yes'
                        AND us.EMAIL = 'zaglyshka@zaglyskha.domru.ru');
    COMMIT;
    ----
    -- 2
    ----
    UPDATE \*+ append *\ idb_ph2_customer t SET t.is_account_in_sso = 'Нет'
    WHERE 1=1
      AND t.rowid IN (SELECT tab.rowid
                      FROM
                        IDB_PH2_CUSTOMER tab,
                        IDB_PH2_CUSTOMER_USERS us
                      WHERE 1=1
                        AND tab.source_system_type = '1'
                        AND us.parent_id = tab.idb_id
                        AND us.is_default = 'Yes'
                        AND us.phone_number_1 = 79999911111);
    COMMIT;
    ----
    -- 3
    ----
    UPDATE \*+ append *\ idb_ph2_customer t SET is_account_in_sso = 'Да'
    WHERE 1=1
      AND t.rowid IN (SELECT tab.rowid
                      FROM
                        idb_ph2_customer tab,
                        idb_ph2_customer_users us
                      WHERE 1=1
                        AND tab.source_system_type = '1'
                        AND tab.is_account_in_sso IS NULL
                        AND us.parent_id = tab.idb_id
                        AND us.is_default = 'Yes'
                        AND EXISTS (SELECT 1 FROM idb_ph2_customer_users us1
                                    WHERE us1.email =  us.email
                                      AND us1.phone_number_1 =  us.phone_number_1
                                      AND us1.is_default = 'Yes'
                                      AND us1.parent_id <> us.parent_id
                                      AND rownum <= 1)
    );
    COMMIT;
    ----
    -- 4
    ----
    UPDATE \*+ append *\ idb_ph2_customer t SET is_account_in_sso = 'Нет'
    WHERE t.rowid IN (SELECT tab.rowid
                      FROM
                        idb_ph2_customer tab,
                        idb_ph2_customer_users us
                      WHERE 1=1
                        AND tab.source_system_type = '1'
                        AND tab.is_account_in_sso IS NULL
                        AND us.parent_id = tab.idb_id
                        AND us.is_default = 'Yes'
                        AND EXISTS (SELECT 1
                                    FROM idb_ph2_customer_users us1
                                    where us1.email =  us.email
                                      and us1.phone_number_1 <> us.phone_number_1
                                      and us1.is_default = 'Yes'
                                      and us1.parent_id <> us.parent_id
                                      and rownum <= 1)
    );
    COMMIT;
    ----
    -- 5
    ----
    UPDATE \*+ append *\ idb_ph2_customer t SET is_account_in_sso = 'Нет'
    WHERE t.rowid IN (SELECT tab.rowid
                      FROM
                        idb_ph2_customer tab,
                        idb_ph2_customer_users us
                      WHERE 1=1
                        AND tab.source_system_type = '1'
                        AND tab.is_account_in_sso IS NULL
                        AND us.parent_id = tab.idb_id
                        AND us.is_default = 'Yes'
                        AND EXISTS (SELECT 1
                                    FROM idb_ph2_customer_users us1
                                    WHERE us1.email <> us.email
                                      AND us1.phone_number_1 =  us.phone_number_1
                                      AND us1.is_default = 'Yes'
                                      AND us1.parent_id <> us.parent_id
                                      AND rownum <= 1)
    );
    COMMIT;

    ----
    -- 6
    ----
    UPDATE \*+ append *\ idb_ph2_customer t SET is_account_in_sso = 'Да'
    WHERE 1=1
      and t.source_system_type = '1'
      and t.is_account_in_sso IS NULL;
    COMMIT;
*/
  END upd_customer_is_account_in_sso;

  /**
  * Заполнение таблицы IDB_PH2_GENERIC_CPE
  * Данные об устройствах, сохраняемые как ресурсы
  */
  PROCEDURE fill_generic_cpe
  IS
  BEGIN
    INSERT /*+ append */ INTO idb_ph2_generic_cpe(
      idb_id,
      model,
      name,
      parent_id,
      serial_no,
      source_id,
      source_system,
      source_system_type,
      type_of_ownership,
      warranty_from,
      phase
    )
    SELECT
      'CPE_' || slo.idb_id AS idb_id,
      slo.model as model,
      slo.equip_name as name,
      (SELECT ex.eab_id
       FROM rias_customer_location_ext ex
       WHERE ex.customer_location = slo.customer_location
      ) AS parent_id,
      slo.equip_serial_num AS serial_no,
      rias_mgr_internet.get_source_id_seq AS source_id,
      TO_NUMBER(slo.source_system) AS source_system,
      TO_NUMBER(slo.source_system_type) AS source_system_type,
      SUBSTR(rias_mgr_support.get_map_value_str('IDB_PH2_GENERIC_CPE',
                                                'TYPE_OF_OWNERSHIP',
                                                rias_mgr_support.get_cost_type_info(to_number(SUBSTR(slo.idb_id, INSTR(slo.idb_id, '/', -1)+1)),
                                                                                    to_number(slo.source_system))
                                               ), 1, 30) AS type_of_ownership,
      (SELECT insert_date
       FROM house_material_costs_all hmc
       WHERE hmc.cost_id = to_number(SUBSTR(slo.idb_id, INSTR(slo.idb_id, '/', -1)+1))
         AND hmc.billing_id = to_number(slo.source_system)
      ) AS warranty_from,
      slo.phase
    FROM idb_ph2_sbpi_int slo
    WHERE 1 = 1
    and slo.phase = phase_id$i
      AND slo.source_system_type = '1'
      AND slo.idb_id LIKE 'SIRTR_1/%'
      AND SUBSTR(slo.idb_id, -3) != '/OH';
  END fill_generic_cpe;

  /**
  * Заполнение таблицы IDB_PH2_GCPE_SERVICE_ID_P
  * Параметрическая таблица для задания множественного значения Service ID  для Generic CPE
  */
  PROCEDURE fill_gcpe_service_id_p
  IS
    -- "старое" значение (до версии 2.22)
    lv_off_id_for_migr idb_ph2_sbpi_int.off_id_for_migr%TYPE := '111000191';
  BEGIN
    -- Если фича включена (https://jsd.netcracker.com/browse/ERT-24532)
    IF rias_mgr_core.get_feature_toggle(4) = 1 THEN
      lv_off_id_for_migr := '303000018';
    END IF;

    INSERT /*+ append */ INTO idb_ph2_gcpe_service_id_p(
      gcpe_idb_id,
      service_id,
      show_order,
      phase
    )
    SELECT
      cpe.idb_id AS gcpe_idb_id,
      slo.parent_service_id AS service_id, -- SERVICE_ID TLO
      TO_CHAR(ROWNUM) AS show_order,
      slo.phase
    FROM	idb_ph2_generic_cpe cpe,
          idb_ph2_sbpi_int slo
    WHERE	(1=1)
    and slo.phase = phase_id$i
      AND cpe.idb_id LIKE 'CPE_SIRTR_1/%'
      AND SUBSTR(cpe.idb_id, 5) = slo.idb_id
      -- Роутер
      AND slo.off_id_for_migr = lv_off_id_for_migr;

  END fill_gcpe_service_id_p;

  /**
  * Создание SLO 'Оборудование "Роутер"'
  */
  PROCEDURE fill_idb_ph2_sbpi_303000018
  IS
    -- "старое" значение (до версии 2.22)
    lv_off_id_for_migr idb_ph2_sbpi_int.off_id_for_migr%TYPE := '111000191';
  BEGIN
    -- Если фича включена (https://jsd.netcracker.com/browse/ERT-24532)
    IF rias_mgr_core.get_feature_toggle(4) = 1 THEN
      lv_off_id_for_migr := '303000018';
    END IF;

    insert /*+ append */ into idb_ph2_sbpi_int(
    account_idb_id,
    actual_start_date,
    actual_end_date,
    customer_idb_id,
    customer_location,
    ext_bpi_status,
    idb_id,
    off_id_for_migr,
    parent_id,
    source_id,
    source_system,
    source_system_type,
    ext_bpi_status_date,
    ma_flag,
    ma_flag_date,
    equip_type,
    ehc_code,
    model,
    service_id,
    parent_service_id,
    inv_name,
    equip_serial_num,
    equip_name,
    transfer_way,
    mrc,
    barring,
    bpi_time_zone,
    duration_warranty,
    warranty_to,
    total_price_tax_nrc,
    --number_of_instl
    phase
    )
    select tbl.account_idb_id,
           tbl.actual_start_date,
           CASE
             WHEN tbl.actual_end_date > current_date THEN
               NULL
             ELSE
               tbl.actual_end_date
           END AS actual_end_date,
           tbl.customer_idb_id,
           tbl.customer_location,
           tbl.ext_bpi_status,
           tbl.idb_id,
           lv_off_id_for_migr AS off_id_for_migr,
           tbl.parent_id,
           tbl.source_id,
           tbl.source_system,
           tbl.source_system_type,
           tbl.ext_bpi_status_date,
           tbl.ma_flag,
           tbl.ma_flag_date,
           'Роутер' AS equip_type,
           tbl.ehc_code,
           tbl.equip_name AS model,
           -- Идентификатор сервиса
           ((SELECT d.prefix
            FROM idb_ph2_offerings_dic d
            WHERE d.idb_table_name = 'IDB_PH2_SBPI_INT'
              AND d.off_id_for_migr = lv_off_id_for_migr)
            || '-' || to_char(tbl.actual_start_date, 'ddmmyyyy') || '1'
           ) AS service_id,
           tbl.parent_service_id,
           tbl.inv_name,
           tbl.equip_serial_num,
           tbl.equip_name,
           tbl.transfer_way,
           tbl.mrc,
           tbl.barring,
           tbl.bpi_time_zone,
           12 AS duration_warranty,
           add_months(tbl.insert_date, 12) AS warranty_to,
           (CASE
             WHEN lv_off_id_for_migr = '303000018' AND tbl.transfer_way = 'Продажа' THEN
               0
             ELSE
               NULL
           END) AS total_price_tax_nrc,
           --number_of_instl
           tbl.phase
    FROM (
    -- SELECT * FROM (
    -- SELECT IDB_ID FROM (
    -- SELECT COUNT(1) FROM(
    SELECT
      ad.addendum_id,
      ad.billing_id,
      tlo.account_idb_id      AS account_idb_id,
      tlo.parent_id           AS customer_idb_id,
      tlo.actual_start_date   AS actual_start_date,
      tlo.actual_end_date     AS actual_end_date,
      tlo.customer_location   AS customer_location,
      (CASE WHEN tlo.ext_bpi_status = 'Disconnected' THEN 'Disconnected' ELSE 'Active' END) AS ext_bpi_status,
      tlo.ext_bpi_status_date AS ext_bpi_status_date,
      tlo.source_id           AS source_id,
      tlo.source_system       AS source_system,
      tlo.source_system_type  AS source_system_type,
      tlo.ma_flag             AS ma_flag,
      tlo.ma_flag_date        AS ma_flag_date,
      'SIRTR_1/'|| tlo.source_system || '/' || to_char(ad.agreement_id) || '/' || to_char(ad.addendum_id)  || '/' || to_char(hmc.cost_id) AS IDB_ID,
      tlo.idb_id              AS parent_id,
      tlo.bpi_time_zone       AS bpi_time_zone,
      0                       AS mrc,

      --CASE WHEN eot.oper_name IS NOT NULL THEN eot.oper_name ELSE hmct.house_material_cost_type_name END AS TRANSFER_WAY,
      --distinct mclt.house_material_cost_type_id
        CASE
          WHEN mclt.house_material_cost_type_id = 9 OR EXISTS(SELECT 1
                                                              FROM house_material_costs_ext_all hmce
                                                              WHERE 1=1
                                                                and hmce.cost_id = hmc.cost_id
                                                                and hmce.billing_id = hmc.billing_id
                                                                and hmce.active_from <= current_date and coalesce(hmce.active_to, current_date + 1) > current_date
                                                                and hmce.oper_type = 5
                                                                and rownum<=1) THEN
            'Рассрочка'
          WHEN mclt.house_material_cost_type_id = 2 THEN
            'Продажа'
          ELSE
            'Ответственное хранение'
        END AS transfer_way,
        ma.material_name        AS equip_name,
        --ma.material_name        AS MODEL,
        tlo.Service_Id          AS parent_service_id,
        'Роутер'                AS inv_name,
        -- Серийный номер
      /*  (SELECT eq.serial_number
         FROM equip_provis_agreement_all eq
         WHERE eq.cost_id = hmc.cost_id
           AND eq.billing_id = hmc.billing_id) AS equip_serial_num,*/
        --24.03.2022 EDIT Серийный номер
           (select pms.SERIAL_NUMBER from pv_material_series_all pms 
           where pms.cost_id = hmc.cost_id and billing_id = hmc.billing_id) AS equip_serial_num,

      ma.unitized_code AS ehc_code,
      -- Дата занесения материальных затрат; Дата начала гарантии; Дата списания
      hmc.insert_date,
      -- длительность рассрочки (для получения информации о связанном сервисе при досрочном закрытии материальной затраты)
      /*
      (SELECT hmce.leasing_duration
       FROM house_material_costs_ext_all hmce
       WHERE 1=1
         and hmce.cost_id = hmc.cost_id
         and hmce.billing_id = hmc.billing_id
         and hmce.active_from <= current_date and coalesce(hmce.active_to, current_date + 1) > current_date
         and hmce.oper_type = 5) AS number_of_instl,
      */
      tlo.barring,
      tlo.phase
    FROM idb_ph2_tbpi_int              tlo,   -- TBPI
         addenda_all                   ad,    -- Приложения
         house_material_costs_all      hmc,   -- Список материальных затрат, отнесенных к дому, в котором ведется подключение.Insert_Date - дата занесения материальных затрат
         material_costs_link_types_all mclt,  -- Типизация конкретно списанного материала
         materials_all                 ma     -- Материалы, участвующие в материальных затратах
    WHERE 1 = 1
    and tlo.phase = phase_id$i
      AND tlo.source_system_type = '1'
      AND tlo.idb_id LIKE 'TI_1/%'
      -- and (tlo.actual_end_date is null or tlo.actual_end_date > current_date)
      -- Приложения
      AND ad.addendum_id = TO_NUMBER(tlo.source_id)
      AND ad.billing_id = TO_NUMBER(tlo.source_system)
      -- Список материальных затрат
      AND hmc.addendum_id = ad.addendum_id
      AND hmc.billing_id = ad.billing_id
      -- Материалы, участвующие в материальных затратах
      AND ma.attr_entity_id = hmc.attr_entity_id
      AND ma.billing_id = hmc.billing_id
      -- Проверка наименования оборудования "Роутер"
      AND (
        UPPER(ma.material_name) LIKE '%TP-LINK ARCHER C20%' OR
        UPPER(ma.material_name) LIKE '%TP-LINK ARCHER C5%'  OR
        UPPER(ma.material_name) LIKE '%TP-LINK ARCHER C9%'  OR
        UPPER(ma.material_name) LIKE '%ОБОРУДОВАНИЕ БЕСПРОВОДНОЙ ПЕРЕДАЧИ ДАННЫХ%' OR
        UPPER(ma.material_name) LIKE '%МАРШРУТИЗАТОР%'
      )
      -- Типизация конкретно списанного материала
      AND mclt.cost_id = hmc.cost_id
      AND mclt.billing_id = hmc.billing_id
    /*
     and mclt.house_material_cost_type_id = 2-- Продажа

      -- Присутствие сервиса 102168 для продажи
      AND EXISTS(SELECT 1
                 FROM PLAN_ITEMS_ALL           PI,
                      ACTIVATE_LICENSE_FEE_ALL ALF
                 WHERE 1=1
                   AND ALF.ADDENDUM_ID = AD.ADDENDUM_ID
                   AND ALF.BILLING_ID = AD.BILLING_ID
                   -- Активен в месяц миграции
                   AND ALF.ACTIVE_FROM >= TRUNC(CURRENT_DATE, 'MM')
                   AND ALF.ACTIVE_FROM < CURRENT_DATE
                   --Свзяь с составом
                   AND PI.PLAN_ITEM_ID = ALF.PLAN_ITEM_ID
                   AND PI.BILLING_ID = ALF.BILLING_ID
                   AND PI.SERVICE_ID = 102168
                   AND ROWNUM<=1)
    */
    ) tbl;
  END fill_idb_ph2_sbpi_303000018;

  /**
  * Создание SLO 'Ответственное хранение Роутера'
  */
  PROCEDURE fill_idb_ph2_sbpi_111000248
  IS
  BEGIN
    -- Если фича включена, то выходим
    -- Т.к. задача ERT-24532 звучит "отключить создание слошек по ответственному хранению"
    IF rias_mgr_core.get_feature_toggle(4) = 1 THEN
      RETURN;
    END IF;
    --
    insert /*+ append */ into idb_ph2_sbpi_int(
    account_idb_id,
    actual_start_date,
    actual_end_date,
    customer_idb_id,
    customer_location,
    ext_bpi_status,
    idb_id,
    off_id_for_migr,
    parent_id,
    source_id,
    source_system,
    source_system_type,
    ext_bpi_status_date,
    ma_flag,
    ma_flag_date,
    bpi_market,
    bpi_organization,
    bpi_time_zone,
    inv_name,
    parent_service_id,
    service_id,
    transfer_way,
    barring,
    mrc,
    tax_mrc,
    total_price_tax_nrc,
    phase
    )
    select s.account_idb_id, s.actual_start_date, s.actual_end_date, s.customer_idb_id,
           s.customer_location, s.ext_bpi_status, s.idb_id || '/OH', '111000248', s.idb_id,
           s.source_id, s.source_system, s.source_system_type,
           s.ext_bpi_status_date, s.ma_flag, s.ma_flag_date,
           t.bpi_market, t.bpi_organization, t.bpi_time_zone,
           'Ответственное хранение Роутера', s.service_id as parent_service_id,
           ((SELECT d.prefix
             FROM idb_ph2_offerings_dic d
             WHERE d.idb_table_name = 'IDB_PH2_SBPI_INT'
               AND d.off_id_for_migr = '111000248')
             || '-' || to_char(s.actual_start_date, 'ddmmyyyy') || '1'
           ) AS service_id,
           'Ответственное хранение' AS transfer_way,
           s.barring, 0 as mrc, 0 as tax_mrc, 0 as total_price_tax_nrc,
           s.phase
    from idb_ph2_sbpi_int s
    join idb_ph2_tbpi_int t on t.idb_id = s.parent_id
    where 1=1
    and s.phase = phase_id$i
      and s.idb_id like 'SIRTR_1/%'
      and transfer_way = 'Ответственное хранение';
  END fill_idb_ph2_sbpi_111000248;



 function inser_work_data_test return pls_integer
  IS
    lv_task_id PLS_INTEGER;
    -- 16.12.2020 feature_toggle for [ERT-24315]
    lv_swtch_value CONSTANT INTEGER := rias_mgr_core.get_feature_toggle(1);
    -- Текущая дата
    lc_current_date CONSTANT DATE := rias_mgr_support.get_current_date();

    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    lv_task_id := rias_mgr_task_seq.nextval;
    --dbms_output.put_line(lv_task_id);
    --/*+ append */
    -- Собирем все услуги приостановки
    INSERT INTO rias_mgr_tmp_list(task_id, account_idb_id, customer_idb_id, billing_id, addendum_id, str1,
                                  active_from, active_to, plan_item_id, activity_id, service_id, str2, off_id_for_migr,
                                  num1
                                  ,str5, num2
    )
      SELECT lv_task_id,
             t.account_idb_id,
             t.parent_id,
             alf.billing_id,
             alf.addendum_id,
             t.idb_id,
             trunc(alf.active_from) as active_from,
             trunc(alf.active_to)-1 as active_to,
             alf.plan_item_id,
             alf.activity_id,
             pi.service_id,
             'SERV',
             t.off_id_for_migr,
             ROUND(rias_mgr_support.get_service_cost(alf.addendum_id,pi.plan_item_id,alf.billing_id,pi.service_id), 2)*100000 as mrc,
             --t.mrc_cupon,
             --rias_mgr_support.get_nds(pi.service_id,alf.billing_id) as koefNDS,
             (SELECT
                rias_mgr_support.get_map_value_str('IDB_PH2_TBPI_INT', 'SUSPEND_REASON', af.flag_name)
              FROM teo_link_addenda_all tla,
                   agreement_flags_all  af,
                   teo_flag_links_all   tfl
              WHERE 1=1
                AND tla.addendum_id = alf.addendum_id
                AND tla.billing_id = alf.billing_id
                --
                AND tfl.teo_id = tla.teo_id
                AND tfl.billing_id = tla.billing_id
                AND tfl.active_from = alf.active_from
                --
                AND af.flag_id = tfl.flag_id
                AND af.billing_id = tfl.billing_id
                AND af.flag_type_id = 16
                AND NOT (af.flag_name like 'Автоматическое отключение по ДЗ%')
                AND af.flag_name IS NOT NULL
                AND rownum<=1
             ),
           (CASE
             WHEN (SELECT count(1)
                   FROM plan_items_all pi1, activate_license_fee_all alf1
                   WHERE 1=1
                     AND alf1.addendum_id = to_number(t.source_id)
                     AND alf1.billing_id = to_number(t.source_system)
                     AND pi1.plan_item_id = alf1.plan_item_id
                     AND pi1.billing_id = alf1.billing_id
                     AND pi1.service_id = 237
                     AND alf1.active_from >= alf.active_to
                     --AND alf1.active_from <= coalesce(alf.active_to, lc_current_date)
                     --AND coalesce(alf1.active_to, lc_current_date + 1)  > alf.active_from
                   ) > 0 THEN
               1
             ELSE
               0
           END) AS is_237
        FROM idb_ph2_tbpi_int t,
             plan_items_all pi,
             activate_license_fee_all alf
       WHERE 1 = 1
       and t.phase = phase_id$i
         AND t.source_system_type = '1'
         AND t.idb_id LIKE 'TI_1/%'
         AND alf.addendum_id = to_number(t.source_id)
         AND alf.billing_id = to_number(t.source_system)
         AND pi.plan_item_id = alf.plan_item_id
         AND pi.billing_id = alf.billing_id
         AND (pi.service_id IN (867, 102749)
              -- Используем feature_toggle для задачи ERT-24315
              -- 16.12.2020 Добавлена услуга 103257 [Временная блокировка услуг связи]
              OR (lv_swtch_value > 0 AND pi.service_id = 103257)
         )
         AND ((alf.active_from <= lc_current_date AND
             (alf.active_to IS NULL OR alf.active_to > lc_current_date)) OR -- Действующий
             (alf.active_from <= lc_current_date AND alf.active_to >= trunc(lc_current_date, 'mm') AND alf.active_to < lc_current_date) OR -- Изменился в этом месяце
             (alf.active_from >= lc_current_date) -- В будущем
         );
    -------------------
    --commit;
    -------------------
    -- ТЭО
    INSERT INTO RIAS_MGR_TMP_LIST (task_id, account_idb_id, customer_idb_id, billing_id, addendum_id,
                                   str1, active_from, active_to, service_id, str2, str5, off_id_for_migr,
                                   num1, num2)
    SELECT lv_task_id, tlo.account_idb_id, tlo.parent_id, ad.billing_id, ad.addendum_id, tlo.idb_id, trunc(tfl.active_from), trunc(tfl.active_to) -1, t.teo_id, 'TEO',
           rias_mgr_support.get_map_value_str('IDB_PH2_TBPI_INT', 'SUSPEND_REASON', af.flag_name) as flag_name,
           tlo.off_id_for_migr,
           0,
           (CASE
             WHEN (SELECT count(1)
                   FROM plan_items_all pi, activate_license_fee_all alf
                   WHERE 1=1
                     AND alf.addendum_id = to_number(tlo.source_id)
                     AND alf.billing_id = to_number(tlo.source_system)
                     AND pi.plan_item_id = alf.plan_item_id
                     AND pi.billing_id = alf.billing_id
                     AND pi.service_id = 237
                     AND alf.active_from >= tla.active_to
                     --AND alf.active_from <= coalesce(tla.active_to, lc_current_date)
                     --AND coalesce(alf.active_to, lc_current_date + 1)  > tla.active_from
                   ) > 0 THEN
               1
             ELSE
               0
           END) AS is_237
    FROM idb_ph2_tbpi_int     tlo,
         addenda_all          ad,
         teo_link_addenda_all tla,
         teo_all              t,
         point_plugins_all    pp,
         agreement_flags_all  af,
         teo_flag_links_all   tfl
    WHERE 1=1
    and tlo.phase = phase_id$i
      AND tlo.source_system_type = '1'
      AND tlo.idb_id like 'TI_1/%'
      --
      AND ad.addendum_id = to_number(tlo.source_id)
      AND ad.billing_id = to_number(tlo.source_system)
      --
      AND tla.addendum_id = ad.addendum_id
      AND tla.billing_id = ad.billing_id
      AND (
         (tla.active_from <= lc_current_date AND (tla.active_to IS NULL OR tla.active_to > lc_current_date)) OR                     -- Действующий
         (tla.active_from <= lc_current_date AND tla.active_to >= TRUNC(lc_current_date, 'mm') AND tla.active_to < lc_current_date) OR -- Изменился в этом месяце
         (tla.active_from >= lc_current_date)                                                                                    -- В будущем
      )
      --
      AND t.teo_id = tla.teo_id
      AND t.billing_id = tla.billing_id
      --
      AND pp.point_plugin_id = t.point_plugin_id
      AND pp.billing_id = t.billing_id
      AND pp.agreement_id = ad.agreement_id
      AND pp.billing_id = ad.billing_id
      AND pp.point_plugin_id = SUBSTR(tlo.IDB_ID, INSTR(tlo.IDB_ID,'/', -1, 1)+1, 500)
      --
      AND tfl.teo_id = t.teo_id
      AND tfl.billing_id = t.billing_id
      AND (
         (tfl.active_from <= lc_current_date AND (tfl.active_to IS NULL OR tfl.active_to > lc_current_date)) OR                     -- Действующий
         (tfl.active_from <= lc_current_date AND tfl.active_to >= TRUNC(lc_current_date, 'mm') AND tfl.active_to < lc_current_date) OR -- Изменился в этом месяце
         (tfl.active_from >= lc_current_date)                                                                                    -- В будущем
      )
      -- Берем только действующие (в рамках данного приложения) флаги.
      -- Т.к могут открыть новое приложение и забрать туда точку подключения со "старыми" атрибутами
      AND (tfl.active_to IS NULL OR tfl.active_to > tlo.actual_start_date)
      --
      AND af.flag_id = tfl.flag_id
      AND af.billing_id = tfl.billing_id
      AND af.flag_type_id = 16
      AND NOT (af.flag_name like 'Автоматическое отключение по ДЗ%')
      -- Откинем, ктр прошли по услугам
      AND NOT EXISTS(SELECT 1
                     FROM RIAS_MGR_TMP_LIST r
                     WHERE r.task_id = lv_task_id
                       AND r.billing_id = ad.billing_id
                       AND r.addendum_id = ad.addendum_id
                       AND r.str1 = tlo.idb_id
                       --1
                       -- пересечение диапазонов
                       AND COALESCE(tfl.active_to, lc_current_date) >= COALESCE(r.ACTIVE_FROM, lc_current_date)
                       AND COALESCE(tfl.active_from, lc_current_date) <= COALESCE(r.ACTIVE_TO, lc_current_date)
                       --2
                       -- Даты одинаковые
                       --AND COALESCE(TRUNC(tfl.active_from), lc_current_date) = COALESCE(TRUNC(r.active_from), lc_current_date)
                       --AND COALESCE(TRUNC(tfl.active_to), lc_current_date) = COALESCE(TRUNC(r.active_to), lc_current_date)
                     );
    -------------------
    -- COMMIT;
    -------------------
    -- Очистим от услуг, ктр заканчиваются и тут же начинаются
    DELETE FROM RIAS_MGR_TMP_LIST
    WHERE ROWID IN (SELECT t2.rowid
                      FROM RIAS_MGR_TMP_LIST t1, RIAS_MGR_TMP_LIST t2
                     WHERE 1=1
                       AND t1.task_id = lv_task_id
                       AND t2.task_id = lv_task_id
                       AND t1.str1 = t2.str1
                       AND COALESCE(t1.active_from, lc_current_date) = COALESCE(t2.active_to, lc_current_date));

    
    COMMIT;
    -------------------
    return lv_task_id;
  END inser_work_data_test;

procedure sbpi_update_for_networks as
v_cen BINARY_FLOAT;
begin
begin
  for rec in (
with table1 as
(select s.source_id, s.source_system, SERVICE_ID,
REGEXP_SUBSTR(s.source_id , '[^/]+' , 1 , 1 ) as agreement_id,
REGEXP_SUBSTR(s.source_id , '[^/]+' , 1 , 2 ) as addendum_id
,s.mrc, s.tax_mrc 
from idb_ph2_sbpi_int s 
where s.phase = phase_id$i and s.parent_id like 'TI_1%' 
and s.off_id_for_migr=121000102
and s.mrc !=0 and s.tax_mrc != 0)
, table2 as (
select (case when pi.service_id=1799 and alf.active_from <= current_date
AND coalesce(alf.active_to, current_date + 1) > trunc(current_date, 'MM') then 1
else 0 end) as is_active,
ad.*
from table1 ad
join excellent.activate_license_fee_all alf on alf.addendum_id = ad.addendum_id and alf.billing_id = ad.SOURCE_SYSTEM
join excellent.plan_items_all pi on pi.plan_item_id = alf.plan_item_id and pi.billing_id = alf.billing_id
), table3 as (
select distinct count(1) over (partition by SOURCE_ID, SOURCE_SYSTEM, SERVICE_ID, AGREEMENT_ID, ADDENDUM_ID, MRC, TAX_MRC) as cnt_srv_all,
count(1) over (partition by SOURCE_ID, SOURCE_SYSTEM, SERVICE_ID, AGREEMENT_ID, ADDENDUM_ID, MRC, TAX_MRC, IS_ACTIVE) as cnt_srv_0
,t.* from table2 t
)
select * from table3
where cnt_srv_all = cnt_srv_0
and is_active = 0
)
loop

update idb_ph2_sbpi_int s set s.mrc =0, s.tax_mrc = 0 where s.phase = phase_id$i and SOURCE_ID = rec.source_id and SERVICE_ID = rec.service_id and OTS_STATUS is null;
end loop;
end;


begin 
  for rec in (with table1 as
(select s.IDB_ID, s.parent_id, s.source_id, s.source_system, SERVICE_ID, to_number(replace(s.Prefix,'/','')) as PREFIX,
(select count(1) from idb_ph2_sbpi_int sin1 where sin1.parent_id = s.parent_id and sin1.off_id_for_migr = 121000087 and
sin1.ext_bpi_status = 'Active' and ipv4_type='Публичный') as cnt_ip_bss,
REGEXP_SUBSTR(s.source_id , '[^/]+' , 1 , 1 ) as agreement_id,
REGEXP_SUBSTR(s.source_id , '[^/]+' , 1 , 2 ) as addendum_id
,s.mrc, s.tax_mrc 
from idb_ph2_sbpi_int s 
where s.phase = phase_id$i and s.parent_id like 'TI_1%' 
and s.off_id_for_migr in (121000102,121000087)
and exists (select 1 from idb_ph2_sbpi_int sin1 where sin1.parent_id = s.parent_id and sin1.off_id_for_migr = 121000102 and
sin1.ext_bpi_status = 'Active' and sin1.ipv4_type='Публичный')
)
, table2 as (
select 
ad.*
from table1 ad, excellent.activate_license_fee_all alf, excellent.plan_items_all pi
where alf.addendum_id = ad.addendum_id and alf.billing_id = ad.SOURCE_SYSTEM
and pi.plan_item_id = alf.plan_item_id and pi.billing_id = alf.billing_id
and pi.service_id=1799 
AND coalesce(alf.active_to, current_date + 1) > trunc(current_date, 'MM')
)
, table3 as 
(
select ad.*, i.ip from table2 ad, excellent.ADDENDUM_RESOURCES_ALL AR, excellent.addenda_all adl,
excellent.RESOURCE_CONTENTS_ALL RC, excellent.IP_FOR_DEDICATED_CLIENTS_ALL I
where AR.addendum_id = ad.addendum_id and AR.billing_id = ad.SOURCE_SYSTEM
and AR.ADDENDUM_ID = ADL.ADDENDUM_ID and ar.billing_id = ADL.billing_id
and rc.resource_id = ar.resource_id and rc.billing_id = ar.billing_id
and I.Terminal_Resource_Id = rc.terminal_resource_id and I.billing_id = rc.billing_id
and COALESCE(RC.ACTIVE_TO, CURRENT_DATE + 1) > CURRENT_DATE
and KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(I.IP)) = 0
)
, table4 as (
select count(1) over (partition by SOURCE_ID, SOURCE_SYSTEM, SERVICE_ID, AGREEMENT_ID, ADDENDUM_ID)-1 as cnt_ip, t3.*
,NVL((excellent.chernov_migr.get_service_cost_1799(addendum_id$i => t3.ADDENDUM_ID ,billing_id$i => t3.source_system, service_id$i => 1799))
,(SELECT round(nvl(min(lfp.price),0)* excellent.chernov_migr.get_nds(billing_id$i => t3.source_system, service_id$i => 534),2) 
            FROM excellent.plan_items_all        p,
                 excellent.simple_plan_items_all spi,
                 excellent.ri_license_fee_ps_all lfp, 
                 excellent.ACTIVATE_LICENSE_FEE_ALL ALF
            WHERE 1=1
              AND p.billing_id = t3.source_system
              AND p.service_id IN (1799,534)
              AND p.plan_item_id = spi.plan_item_id
              AND p.billing_id = spi.billing_id
              AND spi.rule_id = lfp.rule_id
              AND spi.billing_id = lfp.billing_id and alf.addendum_id = t3.ADDENDUM_ID
              and alf.billing_id = t3.source_system 
              AND ALF.ACTIVE_FROM <= CURRENT_DATE
              AND COALESCE(ALF.ACTIVE_TO, CURRENT_DATE + 1) > CURRENT_DATE AND ALF.PLAN_ITEM_ID=p.plan_item_id and alf.billing_id = p.billing_id
              )) as cost_ip
from table3 t3
), table5 as (
select distinct SERVICE_ID, PARENT_ID, CNT_IP, SOURCE_ID, SOURCE_SYSTEM, PREFIX, cnt_ip_bss, IDB_ID,
power(2,32-PREFIX) as CNT_PREFIX
, AGREEMENT_ID, ADDENDUM_ID, MRC, TAX_MRC, COST_IP from table4
where 1=1
--and addendum_id in (7156859,11974451,3210082,17638131)
and cnt_ip >= 1
), table6 as (
select sum(CNT_PREFIX) over (partition by PARENT_ID, SOURCE_ID, SOURCE_SYSTEM ) as sum_prefix, t.*
from table5 t
), table7 as (
select (cnt_ip*COST_IP)/(cnt_ip_bss+sum_prefix) as MAGIC, t.* from table6 t
), table8 as (
select  max(MAGIC) over (PARTITION BY PARENT_ID, SOURCE_SYSTEM, AGREEMENT_ID, ADDENDUM_ID) as MAX_MAGIC, t.*
from table7 t
)
select /*+parallel (4)*/ t.* from table8 t 
--where t.MAX_MAGIC != t.COST_IP
)

loop
  if rec.MAX_MAGIC is not null then  ---если PREFIX is null для 121000087, то использовать параметр из off_id_for_migr=121000102
     select round(rec.MAX_MAGIC,7) into v_cen from dual;
  else
     select round(rec.COST_IP,7) into v_cen from dual; ---если совсем нет PREFIX
  end if;
  update idb_ph2_sbpi_int set MRC = round(v_cen * power(2,32-rec.PREFIX),2)*100000, 
  TAX_MRC = (round(v_cen * power(2,32-rec.PREFIX) /1.2-v_cen * power(2,32-rec.PREFIX), 2))*(-1)*100000
  where PARENT_ID = rec.parent_id and off_id_for_migr=121000102
  and SERVICE_ID = rec.SERVICE_ID;
  
  
  if rec.cnt_ip_bss > 0 then
  update idb_ph2_sbpi_int set MRC = round(v_cen, 2)*100000, 
  TAX_MRC = round((v_cen /1.2-v_cen), 2)*(-1)*100000
  where PARENT_ID = rec.parent_id and off_id_for_migr = 121000087 and
  ext_bpi_status = 'Active' and ipv4_type='Публичный'
  and SERVICE_ID = rec.SERVICE_ID;
  end if;
  
  
end loop;
commit;
end;

  
end sbpi_update_for_networks;

END RIAS_MGR_INTERNET;
/

CREATE OR REPLACE PACKAGE IDB_PROD_PH4.RIAS_MGR_CORE
/**
* Пакет обслуживания миграции
* Версия 001.00
*
* 30.01.2020 Бикулов М.Д. Создание
*
*/
AS
  --------------------------
  -- ТИПЫ
  --------------------------
  TYPE t_cities_list IS TABLE OF INTEGER INDEX BY PLS_INTEGER;
  -- Для сохранения DBG-информации
  TYPE t_dbg_info_rec IS RECORD(dbg_id    INTEGER,          -- Первичный ключ
                                table_id  INTEGER,          -- Идентификатор таблицы для сохранения DBG-информации
                                tbl_rowid ROWID,            -- ROWID строки из исходной таблицы
                                idb_id    VARCHAR2(150),    -- IDB_ID для записи из исходной таблицы
                                dbg_info  VARCHAR2(4000)    -- DBG-информация
  );
  TYPE t_dbg_info_list IS TABLE OF t_dbg_info_rec INDEX BY PLS_INTEGER;

  --------------------------
  -- Глобальные переменные
  --------------------------
  gv_dbg_info_list t_dbg_info_list;

  /**
  * Проверка: является ли пакет валидным
  */
  PROCEDURE package_is_valid;

  /**
  * Сохранение текущего состояние session info
  * @author
  * @version
  */
  PROCEDURE save_session_state;

  /**
  * Восстановление текущего состояние session info
  * @author BikulovMD
  * @version
  */
  PROCEDURE restore_session_state;

  /**
  * Вставка записи лога
  * @param ip_table_id       - Идентификатор таблицы для заполнения
  * @param ip_message        - Сообщение
  * @param ip_err_code       - Сообщение об ошибке
  * @param ip_thread_id      - Идентификатор потока исполнения
  * @param ip_city_id        - Идентификатор города
  * @param ip_reccount       - Количество записей
  * @param ip_duration       - Время исполнения (сек.)
  * @param ip_date_start     - Дата начала
  * @param ip_date_end       - Дата окончания
  * @param ip_slog_slog_id   - Идентификатор родительской записи в логе
  * @return Идентификатор сохраненной записи
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
  * Update конкретной записи лога
  * @param ip_slog_id        - Идентификатор записи в логе
  * @param ip_message        - Сообщение
  * @param ip_err_code       - Сообщение об ошибке
  * @param ip_thread_id      - Идентификатор потока исполнения
  * @param ip_city_id        - Идентификатор города
  * @param ip_reccount       - Количество записей
  * @param ip_duration       - Время исполнения (сек.)
  * @param ip_date_end       - Дата окончания
  * @param ip_slog_slog_id   - Идентификатор родительской записи в логе
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
  * Удалить из лога конкретную запись с её детьми
  * @param ip_slog_id        - Идентификатор записи в логе
  */
  PROCEDURE delete_log_info(ip_slog_id IN INTEGER);

  /**
  * Флаг разрешения на сохранения DBG-информации
  * @param ip_table_id - Идентификатор таблицы для сохранения DBG-информации
  */
  FUNCTION get_is_save_dbg(ip_table_id IN INTEGER) RETURN BOOLEAN;

  /**
  * Инициализация начала работы с DBG-информации
  * @param ip_table_id  - Идентификатор таблицы для сохранения DBG-информации
  */
  PROCEDURE dbg_start(ip_table_id IN INTEGER);

  /**
  * Остановка работы с DBG-информации
  */
  PROCEDURE dbg_stop;

  /**
  * Сохранить DBG-информации
  * @param ip_table_id       - Идентификатор таблицы для сохранения DBG-информации
  * @param ip_dbg_info       - DBG-информация
  * @param ip_idb_id         - IDB_ID для записи из исходной таблицы
  * @param ip_tbl_rowid      - ROWID строки из исходной таблицы
  */
  PROCEDURE insert_dbg_info(
    ip_table_id  IN INTEGER,
    ip_dbg_info  IN VARCHAR2,
    ip_idb_id    IN VARCHAR2 DEFAULT NULL,
    ip_tbl_rowid IN ROWID    DEFAULT NULL
  );

  /**
  * Задать количество потоков обработки
  * @param ip_thread_cnt$i - Количество потоков исполнения
  */
  PROCEDURE set_thread_count(ip_thread_cnt$i IN PLS_INTEGER);

  /**
  * Получить получить количество потоков исполнения
  */
  FUNCTION get_thread_count RETURN PLS_INTEGER;

  /**
  * Получить список городов для потока исполнения
  * @param ip_table_id$i   - Иденификатор таблицы для заполнения
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  FUNCTION get_cities_list(
    ip_table_id$i   IN PLS_INTEGER,
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  ) RETURN t_cities_list;

  /**
  * Формирование данных для заданной таблицы
  * Универсальная процедура
  * Вызывается в конкретном потоке
  * @param ip_table_id$i   - Иденификатор таблицы для заполнения
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
  */
  PROCEDURE fill_table_thread(
    ip_table_id$i   IN INTEGER,
    ip_thread$i     IN PLS_INTEGER,
    ip_thread_cnt$i IN PLS_INTEGER,
    ip_slog_id$i    IN PLS_INTEGER DEFAULT NULL
  );

  /**
  * Уничтожение потоков исполнения
  * @param ip_prefix_job_name#c - Префикс для имени потока
  */
  PROCEDURE p_drop_job(ip_prefix_job_name#c IN VARCHAR2);

  /**
  * Запуск процесса миграции для таблицы с идентфикатором ip_table_id$i
  *   Значения идентификаторов обрабатываемых таблиц хранится в пакете RIAS_MGR_CONST
  * @param ip_table_id$i - Иденификатор таблицы для заполнения
  */
  PROCEDURE start_threads(ip_table_id$i IN INTEGER);

  /**
  * Интерфейсная процедра на остановку процесса миграции для заданной таблицы
  * @param ip_table_id$i - Иденификатор таблицы
  */
  --PROCEDURE request_stop(ip_table_id$i IN INTEGER);

  /**
  * Получить значение ключа
  * @param ip_ftrtgl_id$i - Идентификатор записи
  * @return Значение ключа
  */
  FUNCTION get_feature_toggle(ip_ftrtgl_id$i IN INTEGER) RETURN INTEGER;

  /**
  * Получить значение ключа
  * @param ip_tsk_num$c - Номер задачи
  * @return Значение ключа
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
  -- Глобальные константы
  --------------------------
  gc_time_sleep CONSTANT NUMBER := rias_mgr_support.get_mgr_number_parameter(2, 120);--120; -- Не рекомендуют более 10 минут
  gc_maket_prefix_job_name CONSTANT VARCHAR2(50) := 'JOB_#TABLENAME#_';
  -- Флаг для COMMIT по завершению работы
  lc_commit    CONSTANT BOOLEAN := FALSE;

  --------------------------
  -- Глобальные переменные
  --------------------------
  gv_thread_all PLS_INTEGER := 1;
  -- Флаг работы сохранения DBG-информации
  gv_is_dbg_info BOOLEAN := TRUE;
  --gv_dbg_info_rec_cnt PLS_INTEGER;
  gv_thread_max PLS_INTEGER := 9;

  --------------------------
  -- Внутренние переменные
  --------------------------
  gv_module_name VARCHAR2(100);
  gv_action_name VARCHAR2(100);

  --------------------------
  -- Типы
  --------------------------
  SUBTYPE t_prefix IS VARCHAR2(50);

  --======================== Процедуры/Функции ========================
  /**
  * Инициализация пакета
  */
  PROCEDURE init_package
  IS
  BEGIN
    gv_thread_max := rias_mgr_support.get_mgr_number_parameter(mgr_prmt_id$i => 1, default_value$n => 5);
  END init_package;

  /**
  * Проверка: является ли пакет валидным
  */
  PROCEDURE package_is_valid
  IS
  BEGIN
    NULL;
  END package_is_valid;

  /**
  * Сохранение текущего состояние session info
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
  * Восстановление текущего состояние session info
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
  * Вставка записи лога
  * @param ip_table_id       - Идентификатор таблицы для заполнения
  * @param ip_message        - Сообщение
  * @param ip_err_code       - Сообщение об ошибке
  * @param ip_thread_id      - Идентификатор потока исполнения
  * @param ip_city_id        - Идентификатор города
  * @param ip_reccount       - Количество записей
  * @param ip_duration       - Время исполнения (сек.)
  * @param ip_date_start     - Дата начала
  * @param ip_date_end       - Дата окончания
  * @param ip_slog_slog_id   - Идентификатор родительской записи в логе
  * @return Идентификатор сохраненной записи
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
  * Update конкретной записи лога
  * Внутренняя функция
  * @param ip_slog_id        - Идентификатор записи в логе
  * @param ip_message        - Сообщение
  * @param ip_err_code       - Сообщение об ошибке
  * @param ip_thread_id      - Идентификатор потока исполнения
  * @param ip_city_id        - Идентификатор города
  * @param ip_reccount       - Количество записей
  * @param ip_duration       - Время исполнения (сек.)
  * @param ip_date_end       - Дата окончания
  * @param ip_slog_slog_id   - Идентификатор родительской записи в логе
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
  * Update конкретной записи лога
  * @param ip_slog_id        - Идентификатор записи в логе
  * @param ip_message        - Сообщение
  * @param ip_err_code       - Сообщение об ошибке
  * @param ip_thread_id      - Идентификатор потока исполнения
  * @param ip_city_id        - Идентификатор города
  * @param ip_reccount       - Количество записей
  * @param ip_duration       - Время исполнения (сек.)
  * @param ip_date_end       - Дата окончания
  * @param ip_slog_slog_id   - Идентификатор родительской записи в логе
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
    -- Блок проверки
/*
    -- Возможно надо поднимать ошибку?
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
      -- Обновим данные
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
  * Удалить из лога конкретную запись с её детьми
  * @param ip_slog_id        - Идентификатор записи в логе
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
  * Флаг разрешения на сохранения DBG-информации
  * @param ip_table_id - Идентификатор таблицы для сохранения DBG-информации
  */
  FUNCTION get_is_save_dbg(ip_table_id IN INTEGER) RETURN BOOLEAN
  IS
  BEGIN
    RETURN gv_is_dbg_info;
  END get_is_save_dbg;

  /**
  * Сохранить DBG-информации
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
  * Сохранить DBG-информации
  * @param ip_table_id       - Идентификатор таблицы для сохранения DBG-информации
  * @param ip_dbg_info       - DBG-информация
  * @param ip_idb_id         - IDB_ID для записи из исходной таблицы
  * @param ip_tbl_rowid      - ROWID строки из исходной таблицы
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
    -- Проверим входные параметры
    IF (ip_table_id IS NULL) OR (ip_dbg_info) IS NULL THEN
      RETURN;
    END IF;
    -- Проверим разрешение на сохранение DBG-информации
    IF NOT get_is_save_dbg(ip_table_id) THEN
      RETURN;
    END IF;
    -- В "запись"
    lv_dbg_info_rec.dbg_id   := lv_dbg_id;
    lv_dbg_info_rec.table_id := ip_table_id;
    lv_dbg_info_rec.tbl_rowid:= ip_tbl_rowid;
    lv_dbg_info_rec.dbg_info := ip_dbg_info;
    lv_dbg_info_rec.idb_id   := ip_idb_id;
    -- В массив
    gv_dbg_info_list(gv_dbg_info_list.COUNT + 1) := lv_dbg_info_rec;
    -- Накопилось достаточно, скинем
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
  * Очистим таблицу с DBG-данными
  * @param ip_table_id  - Идентификатор таблицы для сохранения DBG-информации
  */
  PROCEDURE clear_dbg_info(ip_table_id IN INTEGER)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    -- Здесь аккуратно. По-моему исполнение "TRUNCATE TABLE  " делает глобальный COMMIT
    IF ip_table_id IS NULL THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE RIAS_MGR_DEBUG_INFO';
    ELSE
      DELETE /*+ append */ FROM RIAS_MGR_DEBUG_INFO t WHERE t.table_id = ip_table_id;
    END IF;
    COMMIT;
  END clear_dbg_info;

  /**
  * Инициализация начала работы с DBG-информации
  * @param ip_table_id  - Идентификатор таблицы для сохранения DBG-информации
  */
  PROCEDURE dbg_start(ip_table_id IN INTEGER)
  IS
  BEGIN
    -- Проверим разрешение на сохранение DBG-информации
    IF NOT get_is_save_dbg(ip_table_id) THEN
      RETURN;
    END IF;
    -- Очистим таблицу
    clear_dbg_info(ip_table_id);
    -- Очистим массив
    gv_dbg_info_list.delete;
    -- Взведем...
    gv_is_dbg_info := TRUE;
  END dbg_start;

  /**
  * Остановка работы с DBG-информации
  */
  PROCEDURE dbg_stop
  IS
  BEGIN
    save_dbg_info;
    gv_is_dbg_info := FALSE;
  END dbg_stop;

  /**
  * Задать количество потоков обработки
  * @param ip_thread_cnt$i - Количество потоков исполнения
  */
  PROCEDURE set_thread_count(ip_thread_cnt$i IN PLS_INTEGER)
  IS
  BEGIN
    gv_thread_all := NVL(ip_thread_cnt$i, 1);
    gv_thread_all := LEAST(gv_thread_all, gv_thread_max);
  END set_thread_count;

  /**
  * Получить получить количество потоков исполнения
  */
  FUNCTION get_thread_count RETURN PLS_INTEGER
  IS
  BEGIN
    RETURN gv_thread_all;
  END get_thread_count;

  /**
  * Получить "оптимального" значения для таймера засыпания
  * Надо проверять эффективность...
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
        AND l.message LIKE 'Старт исполнения потока%'
        -- Берем данные для многопоточности
        AND SUBSTR(l.message, LENGTH(l.message)-1, 5) > 1
    ) LOOP
      lv_res$n := nvl(rec.tmr, gc_time_sleep);
    END LOOP;
    -- Отдаем значение не больше, чем gc_time_sleep и не 0
    IF NOT (lv_res$n BETWEEN 1 AND gc_time_sleep) THEN
      lv_res$n := gc_time_sleep;
    END IF;
    --
    RETURN lv_res$n;
  END get_thr_time_sleep;

  /**
  * Получить список городов для потока исполнения
  * @param ip_table_id$i   - Иденификатор таблицы для заполнения
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
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
    Сформировать список город.
    Пытаемся равномерно разделить нагрузку по потокам
    */
    SELECT city_id
    BULK COLLECT INTO lv_cities_list
    FROM
    (
      SELECT ct.city_id, (CASE WHEN srt.rn IS NULL THEN ct.rn ELSE srt.rn END) AS rn
      FROM
        -- Исходный список городов
        (
         SELECT city_id, row_number() OVER (ORDER BY city_id) as rn
         FROM (SELECT city_id
               FROM actual_cities
              ----- WHERE city_id not in (7234, 9326, 178, 447))
               WHERE city_id not in (7234, 9326, 178))  ----- 22.06.2021 добавили Улан-Удэ
        ) ct,
        -- Подкрутим к городам порядок
        (
         SELECT city_id, cnt, row_number() over (ORDER BY cnt DESC/*, city_id ASC*/) AS rn
         FROM (SELECT city_id, AVG(sl.reccount) AS cnt
               FROM rias_mgr_log_info sl
               WHERE 1 = 1
                 AND sl.city_id  IS NOT NULL
                 AND sl.reccount IS NOT NULL AND sl.reccount > 0
                 AND sl.message like 'Обработка города%'
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
                                    ip_message => 'Всего городов для обработки в потоке: '|| TO_CHAR(lv_cities_list.COUNT),
                                    ip_thread_id =>  TO_CHAR(ip_thread$i),
                                    ip_slog_slog_id => ip_slog_id$i);
    END IF;
    RETURN lv_cities_list;
  END get_cities_list;

  --============================================= Обслуживание потоков
  /**
  * Проверка, что потоки закончили свою работу
  * @param ip_saction - Наименование потока исполнения
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
      -- рекурсия
      p_job_session(ip_job_name$c, ip_thr_time_sleep$n);
    END IF;
  END p_job_session;

  /**
  * Создать необходимое количество потоков исполнения
  * @param ip_table_id$i        - Иденификатор таблицы для заполнения
  * @param ip_prefix_job_name#c - Префикс для имени потока
  * @param ip_slog_id#i         - Иденификатор род.записи в логе
  */
  PROCEDURE p_create_job(
    ip_table_id$i        IN INTEGER,
    ip_prefix_job_name#c IN VARCHAR2,
    ip_slog_id#i         IN PLS_INTEGER DEFAULT NULL
  )
  IS
    lv_thread_cnt$i PLS_INTEGER := get_thread_count();
  BEGIN
    -- Создаем потоки заполнения
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
  * Запуск потоков исполнения
  * @param ip_prefix_job_name#c - Префикс для имени потока
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
  * Уничтожение потоков исполнения
  * @param ip_prefix_job_name#c - Префикс для имени потока
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
  * Формирование данных для заданной таблицы
  * Универсальная процедура
  * Вызывается в конкретном потоке
  * @param ip_table_id$i   - Иденификатор таблицы для заполнения
  * @param ip_thread$i     - Номер потока исполнения
  * @param ip_thread_cnt$i - Всего потоков к исполнению
  * @param ip_slog_id$i    - Иденификатор род.записи в логе
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
    -- Логирование
    lv_main_slog_id INTEGER;
    lv_slog_id      INTEGER;
    lv_rec_cnt$i    PLS_INTEGER;
    -- Для определения времени исполнения
    lv_time_start   NUMBER;
  BEGIN
    -- Фиксируем время старта
    lv_time_start := dbms_utility.get_time;
    lv_main_slog_id := insert_log_info(ip_table_id => ip_table_id$i,
                                       ip_message => 'Старт исполнения потока ' || TO_CHAR(ip_thread$i) || ' из ' || TO_CHAR(ip_thread_cnt$i),
                                       ip_thread_id =>  ip_thread$i,
                                       ip_slog_slog_id => ip_slog_id$i);
    -- Для таблицы получить имя её обслуживающей процедуры
    lv_job_action#c := RIAS_MGR_CONST.get_proc_name(ip_table_id$i => ip_table_id$i);
    IF lv_job_action#c IS NOT NULL THEN
      -- Запуск процедуры формирования
      EXECUTE IMMEDIATE
        'BEGIN' || chr(13) ||
           lv_job_action#c ||'(ip_thread$i     => :ip_thread$i,'     ||chr(13)||
        '                      ip_thread_cnt$i => :ip_thread_cnt$i,' ||chr(13)||
        '                      ip_slog_id$i    => :lv_main_slog_id);'||chr(13)||
        'END;'
      USING ip_thread$i, ip_thread_cnt$i, lv_main_slog_id;
    END IF;
    -- Подведем итоги работы
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
      -- Логируем информацию об ошибке
      lv_slog_id := RIAS_MGR_CORE.insert_log_info(ip_table_id => ip_table_id$i,
                                                      ip_message => SUBSTR('Error IN thread № '||to_char(ip_thread$i) || ' of ' || to_char(ip_thread_cnt$i)  || chr(13) ||
                                                                           'error_stack: '||dbms_utility.format_error_stack || dbms_utility.format_error_backtrace
                                                                           , 1, 2000),
                                                      ip_err_code => SUBSTR('SQLCODE = ' || TO_CHAR(SQLCODE) ||' SQLERRM = ' || SQLERRM, 1, 200),
                                                      ip_thread_id => ip_thread$i,
                                                      ip_slog_slog_id => lv_main_slog_id);
  END fill_table_thread;

  /**
  * Запуск процесса формирования
  * @param ip_table_id$i - Иденификатор таблицы для заполнения
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
    -- Фиксируем время старта
    lv_time_start := dbms_utility.get_time;
    --
    lv_table_name$c := RIAS_MGR_CONST.get_table_name(ip_table_id$i);
    lv_prefix_job_name#c := REPLACE(gc_maket_prefix_job_name, '#TABLENAME#', lv_table_name$c);
    -- Создадим корень лога
    lv_slog_id := insert_log_info(ip_table_id => ip_table_id$i,
                                  ip_message => 'Старт основного процесса миграции для таблицы ' || lv_table_name$c);
    -- Получить тайм-аут ожидания окончания работы потока
    lv_thr_time_sleep$n := get_thr_time_sleep(ip_table_id$i);
    -- Если должен работать один поток, то и не будем создавать отделную сессию
    IF lv_thread_cnt$i = 1 THEN
      FILL_TABLE_THREAD(ip_table_id$i   => ip_table_id$i,
                        ip_thread$i     => 1,
                        ip_thread_cnt$i => 1,
                        ip_slog_id$i    => lv_slog_id);
    -- Если должно работать более одного потока
    ELSIF lv_thread_cnt$i > 1 THEN
      -- Создаем потоки исполнения
      p_create_job(
        ip_table_id$i        => ip_table_id$i,
        ip_prefix_job_name#c => lv_prefix_job_name#c,
        ip_slog_id#i         => lv_slog_id
      );
      -- Запуск потоков исполнения
      p_run_job(lv_prefix_job_name#c);
      -- Заснем
      sys.dbms_lock.sleep(lv_thr_time_sleep$n);
      -- Проверим закончили ли потоки работу
      FOR i IN 1 .. lv_thread_cnt$i LOOP
        p_job_session(lv_prefix_job_name#c || TO_CHAR(i), lv_thr_time_sleep$n);
      END LOOP;
      -- Уничтожим потоки исполнения
      p_drop_job(lv_prefix_job_name#c);
    END IF;

    -- Обновим лог для основной записи
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_slog_id;
    -- Обновим корень лога
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
    -- Фиксируем время старта
    lv_time_start := dbms_utility.get_time;
    --
    lv_table_name$c := RIAS_MGR_CONST.get_table_name(ip_table_id$i);
    lv_prefix_job_name#c := REPLACE(gc_maket_prefix_job_name, '#TABLENAME#', lv_table_name$c);
    lv_job_action#c := CASE
                         WHEN ip_table_id$i = rias_mgr_const.gc_tbpi_int     THEN 'RIAS_MGR_INTERNET.FILL_TBPI_THREAD'
                         WHEN ip_table_id$i = rias_mgr_const.gc_sbpi_int     THEN 'RIAS_MGR_INTERNET.FILL_SBPI_THREAD'
                         WHEN ip_table_id$i = rias_mgr_const.gc_subscription THEN 'RIAS_MGR_INTERNET.FILL_SUBSCRIPTION_THREAD'
                       END;
    -- Если не задана процедура обработки, то выходим
    IF lv_job_action#c IS NULL THEN
      RETURN;
    END IF;
    -- Создадим корень лога
    lv_slog_id := insert_log_info(ip_table_id => ip_table_id$i,
                                  ip_message => 'Старт основного процесса миграции для таблицы ' || lv_table_name$c);
    -- Получить тайм-аут ожидания окончания работы потока
    lv_thr_time_sleep$n := get_thr_time_sleep(ip_table_id$i);
    -- Если должен работать один поток, то и не будем создавать отделную сессию
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

    -- Если должно работать более одного потока
    ELSIF lv_thread_cnt$i > 1 THEN
      -- Создаем потоки исполнения
      p_create_job(
        ip_job_action#c      => lv_job_action#c,
        ip_prefix_job_name#c => lv_prefix_job_name#c,
        ip_slog_id#i         => lv_slog_id
      );
      -- Запуск потоков исполнения
      p_run_job(lv_prefix_job_name#c);
      -- Заснем
      sys.dbms_lock.sleep(lv_thr_time_sleep$n);
      -- Проверим закончили ли потоки работу
      FOR i IN 1 .. lv_thread_cnt$i LOOP
        p_job_session(lv_prefix_job_name#c || TO_CHAR(i), lv_thr_time_sleep$n);
      END LOOP;
      -- Уничтожим потоки исполнения
      p_drop_job(lv_prefix_job_name#c);
    END IF;

    -- Обновим лог для основной записи
    select sum(sl.reccount)
    into lv_rec_cnt$i
    from RIAS_MGR_LOG_INFO sl
    where sl.slog_slog_id = lv_slog_id;
    -- Обновим корень лога
    update_log_info(ip_slog_id => lv_slog_id,
                    ip_reccount => lv_rec_cnt$i,
                    ip_duration => rias_mgr_support.get_elapsed_time(lv_time_start, dbms_utility.get_time),
                    ip_date_end => sysdate);
  END start_threads;
*/
/*
  \**
  * Остановка процесса ip_prefix
  * Процедура создает канал и отправляет туда сообщение 'STOP'
  * %param ip_prefix - префикс процесса
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
    -- создаем канал
    lv_res_create_pipe := dbms_pipe.create_pipe(pipename    => lv_name_canal,
                                                maxpipesize => 8192,
                                                private     => FALSE);
    -- Проверить результат
    IF lv_res_create_pipe = 0 THEN
      -- очищаем канал, если вдруг он уже существует и в нем есть сообщения
      dbms_pipe.purge(pipename => lv_name_canal);
      -- упаковываем данные
      dbms_pipe.pack_message(lv_message);
      -- передаем список
      lv_res_send_message := dbms_pipe.send_message(pipename => lv_name_canal, timeout  => 0);
      -- Проверить результат
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
  * Интерфейсная процедра на остановку процесса миграции для заданной таблицы
  * @param ip_table_id$i - Иденификатор таблицы
  *\
  PROCEDURE request_stop(ip_table_id$i IN INTEGER)
  IS
    lv_prefix      t_prefix;
    lv_check_while BOOLEAN := TRUE;
  BEGIN
    -- Получить префикс процесса
    lv_prefix := rias_mgr_const.get_process_prefix(ip_table_id$i);
    -- очищаем канал, если вдруг он уже существует и в нем есть сообщения
    BEGIN
      dbms_pipe.purge(pipename => UPPER(lv_prefix));
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- Сколько сессий задействовано, столько раз и посылаем "STOP"
    -- Определять сессию непосредственно перед отправкой команды
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
  * Получить значение ключа
  * @param ip_ftrtgl_id$i - Идентификатор записи
  * @return Значение ключа
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
  * Получить значение ключа
  * @param ip_tsk_num$c - Номер задачи
  * @return Значение ключа
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

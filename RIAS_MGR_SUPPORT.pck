CREATE OR REPLACE PACKAGE IDB_PROD.RIAS_MGR_SUPPORT
/**
* Пакет обслуживания миграции данных
* Версия 001.00
*
* 10.12.2019 Бикулов М.Д. Создание
*
*/
AS
  --Типы
  TYPE t_cupon_4_service IS RECORD(discount_perc NUMBER, discount_perc_fromdate DATE, discount_perc_enddate DATE);

  /**
  * Проверка: является ли пакет валидным
  */
  PROCEDURE package_is_valid;

  /**
  * Сбросить кэш
  */
  PROCEDURE clear_all_cache;

  /**
  * Назначить дату выполнения миграции
  *
  * @param curr_date$d - Дата миграции
  */
  PROCEDURE set_current_date(curr_date$d IN DATE);

  /**
  * Получить текущую дату
  * Получает дату из конфигурационной таблицы.
  * Если нет записи с параметром "sysdate", возвращает current_date
  *
  * @param is_curr_date - флаг для возврата current_date, минуя чтение из конфигурационной таблицы
  *                       1 - возвращает current_date/0 - чтение из конфигурационной таблицы
  * @param is_trnc_date - флаг возврата даты без времени (trunc(date))
  *                       1 - применить TRUNC/0 - не применять TRUNC
  * @return Дата миграции
  */
  FUNCTION get_current_date(
    is_curr_date IN INTEGER DEFAULT 1,
    is_trnc_date IN INTEGER DEFAULT 1
  ) RETURN DATE;
  --PRAGMA RESTRICT_REFERENCES (get_current_date, WNDS, RNDS, WNPS, RNPS);

  /**
  * Получить значение свойства на терминальных ресурсах
  * @author
  * @version
  * @param terminal_resource_id$c - Идентификатор терминального ресурса
  * @param billing_id$i           - Идентификатор биллинга
  * @param prop_id$i              - Идентификатор атрибута
  * @param filed$c                - Поле для вывода
  * @param date$d                 - На какую дату смотрим
  * @return Значение запрошенного параметра
  */
  FUNCTION get_term_res_props(
    terminal_resource_id$c IN VARCHAR2,
    billing_id$i           IN INTEGER,
    prop_id$i              IN INTEGER,
    filed$c                IN VARCHAR2 DEFAULT 'MIN(PROP_VALUE)',
    date$d                 IN DATE DEFAULT NULL
  ) RETURN VARCHAR2;
  PRAGMA RESTRICT_REFERENCES (get_term_res_props, WNDS);

  /**
  * Получить значение свойства на плане
  * @author
  * @version
  * @param plan_id$i    - Идентификатор плана
  * @param billing_id$i - Идентификатор биллинга
  * @param prop_id$i    - Идентификатор атрибута
  * @param date$d       - На какую дату смотрим
  * @return Значение запрошенного параметра
  */
  FUNCTION get_plan_props(
    plan_id$i    IN INTEGER,
    billing_id$i IN INTEGER,
    prop_id$i    IN INTEGER,
    date$d       IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2;
  --PRAGMA RESTRICT_REFERENCES (get_plan_props, WNDS);

  /**
  * Возвращает наименование свойства ТЭО (способ организации связи, Точка включения ВОЛС)
  * @param property_id$i - Идентификатор флага
  * @param billing_id$i  - Идентификатор биллинга
  * @return
  */
  function get_teo_props_name(
    property_id$i in integer,
    billing_id$i  in integer
  ) RETURN VARCHAR2;
  PRAGMA RESTRICT_REFERENCES (get_teo_props_name, WNDS);

  /**
  * Получить значение свойства на ТЭО
  * @author
  * @version
  * @param teo_id$i     - Идентификатор ТЭО
  * @param billing_id$i - Идентификатор биллинга
  * @param prop_id$i    - Идентификатор атрибута
  * @param active_to$d  - Дата, на которую получаем актуальную информацию
  * @return Значение запрошенного параметра
  */
  FUNCTION get_teo_props(
    teo_id$i     IN INTEGER,
    billing_id$i IN INTEGER,
    prop_id$i    IN INTEGER,
    active_to$d  IN DATE := get_current_date()
  ) RETURN VARCHAR2;
  --PRAGMA RESTRICT_REFERENCES (get_teo_props, WNDS);

  /**
  * ТЭО активно с ..
  * @param teo_id$i       - Идентификатор ТЭО
  * @param billing_id$i   - Идентификатор биллинга
  * @param is_agreement$i - Флаг того, что ищем в пределах договора ТЭО
  *                         0/1 - нет/да
  * @RETURN ТЭО активно с ..
  */
  FUNCTION get_teo_active_from(
    teo_id$i       INTEGER,
    billing_id$i   INTEGER,
    is_agreement$i INTEGER := 0
  ) RETURN DATE;
  PRAGMA RESTRICT_REFERENCES (get_teo_active_from, WNDS);

  /**
  * ТЭО активно до ..
  * @param teo_id$i       - Идентификатор ТЭО
  * @param billing_id$i   - Идентификатор биллинга
  * @param is_agreement$i - Флаг того, что ищем в пределах договора ТЭО
  *                         0/1 - нет/да
  * @RETURN ТЭО активно до ..
  */
  FUNCTION get_teo_active_to(
    teo_id$i       INTEGER,
    billing_id$i   INTEGER,
    is_agreement$i INTEGER := 0
  ) RETURN DATE;
  PRAGMA RESTRICT_REFERENCES (get_teo_active_to, WNDS);

  /**
  * Получить флаг присутствия заданного типа атрибута ТЭО с заданным значением на приложении
  * @param  addendum_id$i      - Идентификатор приложения
  * @param  billing_id$i       - Идентификатор биллинга
  * @param  teo_prop_type_id$i - Тип проперти
  * @param  teo_prop_value$i   - Значение проперти
  * @param date$d              - На какую дату смотрим
  * @return Флаг присутствия 1/0
  */
  FUNCTION is_prop_teo_on_addendum(
    addendum_id$i      IN INTEGER,
    billing_id$i       IN INTEGER,
    teo_prop_type_id$i IN INTEGER,
    teo_prop_value$i   IN VARCHAR2,
    date$d             IN DATE DEFAULT get_current_date()
  ) RETURN INTEGER;
  --PRAGMA RESTRICT_REFERENCES (is_prop_teo_on_addendum, WNDS);

  /**
  * Возвращает способ организации связи
  * @param teo_id$i     - Идентификатор ТЭО
  * @param billing_id$i - Идентификатор биллинга
  * @param active_to$d  - Дата, на которую получаем актуальную информацию
  * @return Способ организации связи
  */
  FUNCTION get_organiz_of_communicat(
    teo_id$i     IN INTEGER,
    billing_id$i IN INTEGER,
    active_to$d  IN DATE := get_current_date()
  ) RETURN VARCHAR2;
  --PRAGMA RESTRICT_REFERENCES (get_organiz_of_communicat, WNDS);

  /**
  * Возвращает способ организации связи
  * @param addendum_id$i - Идентификатор приложения
  * @param billing_id$i  - Идентификатор биллинга
  * @param active_from$d - Дата от ...
  * @param active_to$d   - Дата до ...
  * @return Способ организации связи
  */
  FUNCTION get_organiz_of_communicat(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    active_from$d IN DATE := get_current_date(),
    active_to$d   IN DATE := get_current_date()
  ) RETURN VARCHAR2;
  --PRAGMA RESTRICT_REFERENCES (get_organiz_of_communicat, WNDS);

  /**
  * Сбросить кэш со свойствами
  *   1. свойства на терминальных ресурсах
  *   2. свойства на планах
  *   3.
  * @author
  * @version
  */
  PROCEDURE clear_props_cache;

  /**
  * Сбросить кеш с числовыми значениями
  *
  * @author
  * @version
  */
  PROCEDURE clear_number_cache;

  /**
  * Коэфициент для НДС по сервисам
  * @author Взято из EXCELLENT.sa_bal_funcs
  * @version
  * @throw  -20001, -20002, -20003
  * @param service_id$i - Идентификатор сервиса (услуги)
  * @param billing_id$i - Идентификатор биллинга
  * @param value_date$d - На какую дату получить % НДС
  * @return Значение коэфициента НДС
  */
  FUNCTION get_nds(
    service_id$i INTEGER := NULL,
    billing_id$i INTEGER := NULL,
    value_date$d DATE := get_current_date()
  ) RETURN NUMBER;

  /**
  * Преобразование ip из числа в строку
  * @param  ip$n - IP-адрес в виде числа
  * @return Преобразованный IP-адрес
  */
  FUNCTION ip_number_to_char(ip$n IN NUMBER := NULL) RETURN VARCHAR2;
  PRAGMA RESTRICT_REFERENCES (ip_number_to_char, WNDS, RNDS, WNPS, RNPS);

  /**
  * Получить ссылку на локацию клиента, где предоставляется услуга
  * @param  addendum_id$i  - Идентификатор приложения
  * @param  billing_id$i   - Идентификатор биллинга
  * @param  delimiter$c    - Разделитель
  * @return Список точек подключения через ','
  */
  FUNCTION get_customer_location(
    addendum_id$i IN NUMBER,
    billing_id$i  IN NUMBER,
    delimiter$c   IN VARCHAR2 := ', '
  ) RETURN VARCHAR2;
  --PRAGMA RESTRICT_REFERENCES (get_customer_location, WNDS);

  /**
  * Получить стоимость услуги
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  plan_item_id$i  - Идентификатор состава плана
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  * @param  with_nds$i      - Флаг учета в ответе НДС
  */
  FUNCTION get_service_cost(
    addendum_id$i  IN INTEGER := NULL,
    plan_item_id$i IN INTEGER := NULL,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date(),
    with_nds$i     IN INTEGER := 1
  ) RETURN NUMBER;

  /**
  * Получить правило расчета
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  plan_item_id$i  - Идентификатор состава плана
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  * @param  with_nds$i      - Флаг учета в ответе НДС
  */
  FUNCTION get_calculation_rule(
    addendum_id$i  IN INTEGER := NULL,
    plan_item_id$i IN INTEGER := NULL,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date()
  ) RETURN INTEGER;
  --PRAGMA RESTRICT_REFERENCES (get_calculation_rule, WNDS);

  /**
  * Получить % скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * Remark: Если задан service_id$i, то в первую очередь ищем по нему, затем по service_name$c
  */
  FUNCTION get_cupon_4_service(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN NUMBER;

  /**
  * Получить дату начала действия скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * @return Дата начала действия купона
  */
  FUNCTION get_cupon_active_from(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN DATE;

  /**
  * Получить дату окончания действия скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * @return Дата окончания действия купона
  */
  FUNCTION get_cupon_active_to(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN DATE;

  /**
  * Получить % скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * Remark: Если задан service_id$i, то в первую очередь ищем по нему, затем по service_name$c
  */
  FUNCTION get_cupon_4_service_t(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN t_cupon_4_service;

  /**
  * Функция возвращает целое число из последовательности, увеличивающейся на 1 через 0,01 сек.
  * Для замера времени в процедурах и т.д. с точностью 0,01 сек используется функция DBMS_UTILITY.GET_TIME
  */
  FUNCTION get_time RETURN NUMBER;

  /**
  * Получить время исполнения в секундах
  * %author
  * %param  ip_start_value  Значение счетчика при старте
  * %param  ip_end_value    Значение счетчика при окончании исполнения
  * %return Время исполнения
  * Comment: Время должно определяться вызовом dbms_utility.get_time
  */
  FUNCTION get_elapsed_time(
    ip_start_value IN NUMBER,
    ip_end_value   IN NUMBER
  ) RETURN NUMBER;
  PRAGMA RESTRICT_REFERENCES (get_elapsed_time, WNDS, RNDS, WNPS, RNPS);

  /**
  * Получить часовой пояс города
  * @param  ip_city_id$i    - Идентификатор города
  * @param  ip_what_give$c  - Формат ответа (5 или ETC/GMT-5)
  *            значения N/C
  * @RETURN Возвращает часовой пояс в запрошенном формате
  */
  FUNCTION get_time_zone(
    ip_city_id$i   IN INTEGER,
    ip_what_give$c IN VARCHAR2 DEFAULT 'N'
  ) RETURN VARCHAR2;
  PRAGMA RESTRICT_REFERENCES (get_time_zone, WNDS);

  /**
  * Очистить заданную таблицу (TRUNCATE)
  *   Использовать осторожно. По-моему делает COMMIT в сессии
  * @param  ip_table_name$c - Имя таблицу
  */
  PROCEDURE truncate_table(ip_table_name$c IN VARCHAR2);

  /**
  * Услуга активна с ..
  * @param service_id$i   - Идентификатор услуги
  * @param addendum_id$i  - Идентификатор приложения
  * @param billing_id$i   - Идентификатор биллинга
  * @param ip_date$d      - На какую дату запрос
  * @RETURN Услуга активна с ..
  */
  FUNCTION get_service_active_from(
    service_id$i   IN INTEGER,
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    ip_date$d      IN DATE := get_current_date()
  ) RETURN DATE;
  --PRAGMA RESTRICT_REFERENCES (get_service_active_from, WNDS);

  /**
  * Услуга активна до ..
  * @param service_id$i   - Идентификатор услуги
  * @param addendum_id$i  - Идентификатор приложения
  * @param billing_id$i   - Идентификатор биллинга
  * @param ip_date$d      - На какую дату запрос
  * @RETURN Услуга активна до ..
  */
  FUNCTION get_service_active_to(
    service_id$i   IN INTEGER,
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    ip_date$d      IN DATE := get_current_date()
  ) RETURN DATE;
  --PRAGMA RESTRICT_REFERENCES (get_service_active_to, WNDS);

  /**
  * Была ли активна услуга в запрошенном интервале времени
  * @param service_id$i   - Идентификатор услуги
  * @param addendum_id$i  - Идентификатор приложения
  * @param billing_id$i   - Идентификатор биллинга
  * @param ip_date_from$d - Дата от ...
  * @param ip_date_to$d   - Дата до ...
  * @RETURN Флаг активности услуги в запрошенном интервале времени
  *         0/1 - Нет/Да
  */
  FUNCTION is_active_service_in_month(
    service_id$i   IN INTEGER,
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    ip_date_from$d IN DATE := get_current_date(),
    ip_date_to$d   IN DATE := get_current_date()
  ) RETURN INTEGER;
  --PRAGMA RESTRICT_REFERENCES (is_active_service_in_month, WNDS);

  /**
  * Получить стыковочный IP-Адрес
  * @param  addendum_id$i  - Идентификатор приложения
  * @param  billing_id$i   - Идентификатор биллинга
  * @return IDB_PH2_IP_V6RANGE.IDB_ID/IDB_PH2_IP_V4RANGE.IDB_ID
  */
  FUNCTION get_linked_subnets(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN VARCHAR2;

  /**
  * Подсеть активна с ..
  * @param addendum_id$i          - Идентификатор приложения
  * @param terminal_resource_id$i - Идентификатор терминального ресурса "Подсеть"
  * @param billing_id$i           - Идентификатор биллинга
  * @param ip_date$d              - На какую дату
  * @RETURN Подсеть активна с ..
  */
  FUNCTION get_subnets_active_from(
    addendum_id$i          IN INTEGER := NULL,
    terminal_resource_id$i IN INTEGER,
    billing_id$i           IN INTEGER,
    ip_date$d              IN DATE := get_current_date()
  ) RETURN DATE;

  /**
  * Подсеть активна до ..
  * @param addendum_id$i          - Идентификатор приложения
  * @param terminal_resource_id$i - Идентификатор терминального ресурса "Подсеть"
  * @param billing_id$i           - Идентификатор биллинга
  * @param ip_date$d              - На какую дату
  * @RETURN Подсеть активна до ..
  */
  FUNCTION get_subnets_active_to(
    addendum_id$i          IN INTEGER := NULL,
    terminal_resource_id$i IN INTEGER,
    billing_id$i           IN INTEGER,
    ip_date$d              IN DATE := get_current_date()
  ) RETURN DATE;

  /**
  * Получить наименование типа авторизации
  * @param  addendum_id$i    - Идентификатор приложения
  * @param billing_id$i      - Идентификатор биллинга
  * @param  plan_group_id$i  - Идентификатор группы планов
  * @param  ip_date$d        - На какую дату смотрим
  * @param  ip_is_convert$i  - Признак преобразования типов подключения
  *                            1/0 - Преобразуем/Не преобразуем
  * @return Наименование типа авторизации
  */
  FUNCTION get_auth_type(
    addendum_id$i   IN INTEGER,
    billing_id$i    IN INTEGER,
    plan_group_id$i IN INTEGER DEFAULT NULL,
    ip_date$d       IN DATE DEFAULT get_current_date(),
    ip_is_convert$i IN INTEGER DEFAULT 1
  ) RETURN VARCHAR2;

  /**
  * Получить наименование типа авторизации для обработки в IDB_PH2_NET_ACCESS
  * @param  addendum_id$i    - Идентификатор приложения
  * @param  billing_id$i     - Идентификатор биллинга
  * @param  ip_date$d        - На какую дату смотрим
  * @return Наименование типа авторизации
  */
  FUNCTION get_auth_type_4_net_access(
    addendum_id$i   IN INTEGER,
    billing_id$i    IN INTEGER,
    ip_date$d       IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2;

  /**
  * Получить NAT для обработки в IDB_PH2_NET_ACCESS
  * @param  addendum_id$i    - Идентификатор приложения
  * @param  billing_id$i     - Идентификатор биллинга
  * @terminal_resource_id$i  - Идентификатор терминального ресурса логина
  * @param  ip_date$d        - На какую дату смотрим
  * @return NAT
  */
  FUNCTION get_nat(
    addendum_id$i          IN INTEGER,
    billing_id$i           IN INTEGER,
    terminal_resource_id$i IN INTEGER DEFAULT NULL,
    ip_date$d              IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2;
  --PRAGMA RESTRICT_REFERENCES (get_nat, WNDS, WNPS, RNPS);

  /**
  * Проверить необходимость выгрузки поля
  * @param  table_name$c      - Наименование таблицы
  * @param  column_name$c     - Наименование столбца
  * @param  off_id_for_migr$c - Оффер
  * @return 1/0/-1 - Выгружать/Не выгружать/Не работает
  */
  FUNCTION is_unload_field(
    table_name$c      IN VARCHAR2,
    column_name$c     IN VARCHAR2,
    off_id_for_migr$c IN VARCHAR2
  ) RETURN INTEGER;
  PRAGMA RESTRICT_REFERENCES (is_unload_field, WNDS);

  /**
  * Получить префикс для оффера
  * Формирование поля SERVICE_ID
  * @param  table_name$c      - Наименование таблицы
  * @param  off_id_for_migr$c - Оффер
  * @return Префикс
  */
  FUNCTION get_prefix4offer(
    table_name$c      IN VARCHAR2,
    off_id_for_migr$c IN VARCHAR2
  ) RETURN VARCHAR2;
  PRAGMA RESTRICT_REFERENCES (get_prefix4offer, WNDS);

  /**
  * Получить МКУ
  * @param  house_id$i   - Идентификатор дома
  * @param  billing_id$i - Идентификатор биллинга
  * @param  date$d       - На какую дату смотрим
  * @return МКУ
  */
  FUNCTION get_mku(
    house_id$i   IN INTEGER,
    billing_id$i IN INTEGER,
    date$d       IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2;

  /**
  * Возвращает кол-во месяцев гарантии для определенного оборудования
  * @param  attr_entity_id$i - Идентификатор оборудования
  * @param  billing_id$i     - Идентификатор биллинга
  * @param  insert_date$d    - Дата установки оборудования
  */
  FUNCTION get_count_warranty_months(
    attr_entity_id$i IN INTEGER,
    billing_id$i     IN INTEGER,
    insert_date$d    IN DATE
  ) RETURN INTEGER;

  /**
  * Возвращает гарантийный срок обслуживания оборудования
  * @param  cost_id$i    - Идентификатор материала
  * @param  billing_id$i - Идентификатор биллинга
  */
  FUNCTION get_warranty_date(
    cost_id$i    IN INTEGER,
    billing_id$i IN INTEGER
  ) RETURN DATE;

  /**
  * Получить абонентскую плату
  * @param  abon_pay_id$i - Идентификатор аб.платы
  * @param  billing_id$i  - Идентификатор биллинга
  */
  FUNCTION get_first_price(
    abon_pay_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN NUMBER;

  /**
  * @param  addendum_id$i - Идентификатор приложения
  * @param  billing_id$i  - Идентификатор биллинга
  * @param  service_id$i  - Идентификатор услуги
  * @param  date$d        - На какую дату смотрим
  * @param  with_nds$i    - Флаг учета в ответе НДС
  * @return абонентская плата
  */
  FUNCTION get_abon_pays(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    service_id$i  IN INTEGER,
    date$d        IN DATE := get_current_date(),
    with_nds$i    IN INTEGER := 1
  ) RETURN NUMBER;

  ------------------------------
  -- Стоимости для оверрайдов
  ------------------------------
  FUNCTION get_service_cost_override(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id     INTEGER,
    service_cup_id INTEGER DEFAULT NULL,
    date$d         DATE DEFAULT get_current_date(),
    with_nds$i     INTEGER DEFAULT 1,-- 0/1
    with_cupon     INTEGER DEFAULT 0 -- 0/1
  ) RETURN NUMBER;

  /**
  * Получитьт имя сервиса по service_id$i
  * @param  service_id$i - Идентификатор сервиса
  * @param  billing_id$i - Идентификатор биллинга
  */
  FUNCTION get_service_name(
    service_id$i IN INTEGER,
    billing_id$i IN INTEGER
  ) RETURN VARCHAR2;

  /**
  * Получить название бонуса по активной услуге
  * @param  activity_id$i - Идентификатор
  * @param  billing_id$i  - Идентификатор биллинга
  */
  FUNCTION get_bonus_comment(
    activity_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN VARCHAR2;

  /**
  * Получить число платного бонуса по активной услуге
  * @param  activity_id$i - Идентификатор
  * @param  billing_id$i  - Идентификатор биллинга
  */
  FUNCTION get_number_bonus(
    activity_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN NUMBER;

  /**
  * Получить идентификатор правила
  * @param  plan_item_id$i  - Идентификатор
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  date$d          - На какую дату смотрим
  */
  FUNCTION get_rule_id(
    plan_item_id$i IN INTEGER,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE DEFAULT get_current_date()
  ) RETURN INTEGER;

  /**
  * Получить стоимость платного бонуса
  * @param  plan_item_id$i  - Идентификатор
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  threshold$i     - Порог
  * @param  activity_id$i   - Идентификатор
  * @param  date$d          - На какую дату смотрим
  * Remark: Если задан activity_id$i, то он имеет приоритет перед порогом
  */
  FUNCTION get_price_4_bonus(
    plan_item_id$i IN INTEGER,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    threshold$i    IN INTEGER DEFAULT NULL,
    activity_id$i  IN INTEGER DEFAULT NULL,
    date$d         IN DATE DEFAULT get_current_date()
  ) RETURN NUMBER;

  /**
  * Проверить является ли IP "серым" или "белым"
  * @param  ip$c  - IP-адрес в виде строки
  * @return Возвращает 0, если белый, иначе ip серый
  */
  FUNCTION is_ip_local(ip$c VARCHAR2) RETURN PLS_INTEGER;

  /**
  * Получить значение BPI_MARKET
  * @param  ip_address$c - адрес в виде строки формата 'a7925172+3f5a+9a7f+e053+4201630a5105'
  *                       уровень "ДОМ"
  */
  FUNCTION get_market(ip_address$c IN VARCHAR2) RETURN VARCHAR2;

  /**
  * Получить замапленное строковое значение
  * @param  ip_table_name$c   - Наименование таблицы
  * @param  ip_column_name$c  - Наименование колонки (поля)
  * @param  ip_value$c        - Значение RIAS
  * @return Значение для BSS
  */
  FUNCTION get_map_value_str(
    ip_table_name$c  IN VARCHAR2,
    ip_column_name$c IN VARCHAR2,
    ip_value$c       IN VARCHAR2
  ) RETURN VARCHAR2;

  /**
  * Получить замапленное числовое значение
  * @param  ip_table_name$c   - Наименование таблицы
  * @param  ip_column_name$c  - Наименование колонки (поля)
  * @param  ip_value$n        - Значение RIAS
  * @return Значение для BSS
  */
  FUNCTION get_map_value_num(
    ip_table_name$c  IN VARCHAR2,
    ip_column_name$c IN VARCHAR2,
    ip_value$n       IN NUMBER
  ) RETURN NUMBER;

  /**
  * Получить замапленное значение даты
  * @param  ip_table_name$c   - Наименование таблицы
  * @param  ip_column_name$c  - Наименование колонки (поля)
  * @param  ip_value$d        - Значение RIAS
  * @return Значение для BSS
  */
  FUNCTION get_map_value_date(
    ip_table_name$c  IN VARCHAR2,
    ip_column_name$c IN VARCHAR2,
    ip_value$d       IN DATE
  ) RETURN DATE;

  /**
  *
  */
  FUNCTION get_teo_flag_info(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    flag_type_id$i    IN INTEGER,
    date$d            IN DATE DEFAULT rias_mgr_support.get_current_date,
    field$c           IN VARCHAR2 DEFAULT 'NAME',
    agreement_id$i    IN INTEGER DEFAULT NULL,
    point_plugin_id$i IN INTEGER DEFAULT NULL
  ) RETURN VARCHAR2;

  /**
  *
  */
  FUNCTION get_teo_flag_name(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    flag_type_id$i    IN INTEGER,
    date$d            IN DATE DEFAULT rias_mgr_support.get_current_date,
    agreement_id$i    IN INTEGER DEFAULT NULL,
    point_plugin_id$i IN INTEGER DEFAULT NULL
  ) RETURN VARCHAR2;

  /**
  * Читает value_number из rias_mgr_parameteres
  * @param mgr_prmt_id$i   - идентификатор параметра
  * @param default_value$n - значение по умолчанию
  * @return значение параметра NUMBER
  */
  FUNCTION get_mgr_number_parameter(
    mgr_prmt_id$i   IN NUMBER,
    default_value$n IN NUMBER DEFAULT NULL
  ) RETURN NUMBER;

  /**
  * Читает value_string из rias_mgr_parameteres
  * @param mgr_prmt_id$i   - идентификатор параметра
  * @param default_value$c - значение по умолчанию
  * @return значение параметра VARCHAR2
  */
  FUNCTION get_mgr_string_parameter(
    mgr_prmt_id$i   IN NUMBER,
    default_value$c IN VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2;

  /**
  * Читает value_date из rias_mgr_parameteres
  * @param mgr_prmt_id$i   - идентификатор параметра
  * @param default_value$d - значение по умолчанию
  * @return значение параметра DATE
  */
  FUNCTION get_mgr_date_parameter(
    mgr_prmt_id$i   IN NUMBER,
    default_value$d IN DATE DEFAULT NULL
  ) RETURN DATE;

  /**
  * Получить INV_NAME из справочника
  * @param  table_name$c      - Наименование таблицы
  * @param  off_id_for_migr$c - Оффер
  * @param  default_value$c   - Значение по-умолчанию
  * @return INV_NAME
  */
  FUNCTION get_inv_name(
    table_name$c      IN VARCHAR2,
    off_id_for_migr$c IN VARCHAR2,
    default_value$c   IN VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2;

  /**
  * Получение текста ошибки и стэка вызовов
  * @return Текск ошибки, стэк вызовов
  */
  FUNCTION get_error_stack RETURN VARCHAR2;

  /**
  * Возвращает тип собственности
  * @param  ip_cost_id$i   - Идентификатор материала
  * @param  ip_billing_id$ - Идентификатор биллинга
  */
  FUNCTION get_cost_type_info(
    ip_cost_id$i   IN INTEGER,
    ip_billing_id$ IN INTEGER
  ) RETURN VARCHAR2;

  /**
  * Определяет название сети, через которую подключена Услуга (ЭРТХ, Энфорта...)
  * @param addendum_id$i     - Идентификатор приложения
  * @param p_billing_id      - Город биллинга
  * @param agreement_id$i    - Идентификатор договора
  * @param point_plugin_id$i - Идентификатор ТП
  * @param date$d            - На какую дату смотрим
  * @return название сети
  */
  FUNCTION get_network(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    agreement_id$i    IN INTEGER DEFAULT NULL,
    point_plugin_id$i IN INTEGER DEFAULT NULL,
    date$d            IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2;

  /**
  * Определяет принадлежит ли IP подсети на приложении
  * @param addendum_id$i - Идентификатор приложения
  * @param billing_id$i  - Город биллинга
  * @param ip$c          - ip-адрес строкой
  * @param ip$n          - ip-адрес числом
  * @param date$d        - На какую дату смотрим
  * @return если принадлежит 1, иначе 0
  */
  FUNCTION ip_in_subnet(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    ip$c          IN VARCHAR2 DEFAULT NULL,
    ip$n          IN NUMBER DEFAULT NULL,
    date$d        IN DATE DEFAULT get_current_date()
  ) RETURN INTEGER;

  /**
  * Получить менеджера договора, заданного типа
  *
  * @param agreement_id$i       - Идентификатор договора
  * @param p_billing_id         - Город биллинга
  * @param type_spesialist_id$i - Типы ответственных за удержание договора
  * @param active_to$d          - На какую дату смотрим
  * @return Менеджер заданного типа
  *
  * type_spesialist_id:
  *   1 Сотрудник ООКК
  *   2  Менеджер ОРКК
  *   3  Менеджер продаж B2F
  *   4  Сервис менеджер ФК
  *   5  Менеджер СПКК
  *   6  Директор Вертикального рынка
  *   7  Менеджер по ключевым клиентам
  *   8  Региональный руководитель В2О
  *   9  Менеджер продаж В2О
  *   10 Специалист по расчетам РДО
  */
  FUNCTION get_manager_name_by_agr(
    agreement_id$i       INTEGER := NULL,
    billing_id$i         INTEGER := NULL,
    type_spesialist_id$i INTEGER := NULL,
    active_to$d          DATE := trunc(get_current_date(), 'dd')
  ) RETURN VARCHAR2;

  /**
  * Получить подразделение менеджера договора, заданного типа
  *
  * @param agreement_id$i       - Идентификатор договора
  * @param p_billing_id         - Город биллинга
  * @param type_spesialist_id$i - Типы ответственных за удержание договора
  * @param active_to$d          - На какую дату смотрим
  * @return Подразделение менеджера заданного типа
  *
  * type_spesialist_id:
  *   1 Сотрудник ООКК
  *   2  Менеджер ОРКК
  *   3  Менеджер продаж B2F
  *   4  Сервис менеджер ФК
  *   5  Менеджер СПКК
  *   6  Директор Вертикального рынка
  *   7  Менеджер по ключевым клиентам
  *   8  Региональный руководитель В2О
  *   9  Менеджер продаж В2О
  *   10 Специалист по расчетам РДО
  */
  FUNCTION get_subdivision_manager(
    agreement_id$i       INTEGER := NULL,
    billing_id$i         INTEGER := NULL,
    type_spesialist_id$i INTEGER := NULL,
    active_to$d          DATE := trunc(get_current_date(), 'dd')
  ) RETURN VARCHAR2;

  /**
  * Получить менеджера на клиенте, заданного типа
  *
  * @param client_id$i          - Идентификатор клиента
  * @param p_billing_id         - Город биллинга
  * @param type_spesialist_id$i - Типы ответственных
  * @param active_to$d          - На какую дату смотрим
  * @return Менеджер заданного типа
  *
  * type_id:
  *   1  Сотрудник ООКК
  *   2  Менеджер ОРКК
  *   3  Директор Вертикального рынка
  *   4  Менеджер по ключевым клиентам
  *   5  Менеджер продаж B2F
  *   7  Региональный руководитель В2О
  *   8  Менеджер продаж В2О
  *   9  Специалист по расчетам РДО
  *   10 Сервис-менеджер
  *   
  */
  FUNCTION get_manager_name_by_clnt(
    client_id$i          INTEGER := NULL,
    billing_id$i         INTEGER := NULL,
    type_spesialist_id$i INTEGER := NULL,
    active_to$d          DATE := trunc(get_current_date(), 'dd')
  ) RETURN VARCHAR2;

  /**
  * Получить часовой пояс города по адресу ТП
  *
  * @param  ip_pp_id$i      - Идентификатор точки подключения
  * @param  ip_billing_id$i - Идентификатор биллинга
  * @RETURN Возвращает часовой пояс в запрошенном формате
  */
  FUNCTION get_time_zone_pp(
    ip_pp_id$i      IN INTEGER,
    ip_billing_id$i IN INTEGER
  ) RETURN NUMBER;

  /**
  * Получить часовой пояс города по адресу ТП
  * через идентификатору IDB_PH2_CUSTOMER_LOCATION
  *
  * @param  ip_cl_idb_id$i - Идентификатор IDB_PH2_CUSTOMER_LOCATION
  * @RETURN Возвращает часовой пояс
  */
  FUNCTION get_time_zone_cl(ip_cl_idb_id$i IN VARCHAR2) RETURN NUMBER;

  FUNCTION get_date_interval_ranges RETURN ARRAY_DATE PIPELINED;

  /**
  *
  */
  FUNCTION get_cost_4_inet(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    service_id$i  IN INTEGER,
    date$d        IN DATE DEFAULT current_date,
    with_nds$i    IN INTEGER DEFAULT 1
  ) RETURN NUMBER;

  /**
  * Получение значения свойства
  *
  * @param terminal_resource_id$i - Идентификатор терминального ресурса
  * @param billing_id$i           - Идентификатор города
  * @param prop_type_id$i         - Свойство
  * @param on_date$d              - Дата
  */
  function get_property(
    terminal_resource_id$i integer
    ,billing_id$i   integer
    ,prop_type_id$i integer
    ,on_date$d date:=current_date
  ) return varchar2;

  /**
  * Получить тип vlan
  *
  * @param  terminal_resource_id$i - Идентификатор терминального ресурса
  * @param  billing_id$i           - Идентификатор города
  * @RETURN 
  */
  function get_vlan_type(
    terminal_resource_id$i integer := null, 
    billing_id$i integer
  ) return varchar2;

END RIAS_MGR_SUPPORT;
/
CREATE OR REPLACE PACKAGE BODY IDB_PROD.RIAS_MGR_SUPPORT
/**
* Пакет обслуживания миграции данных
* Версия 001.00
*
* 10.12.2019 Бикулов М.Д. Создание
*
*/
AS
  -- Кэш для атрибутов на терминальных ресурсах
  SUBTYPE t_cache_key       IS VARCHAR2(2000);
  SUBTYPE t_cache_str_value IS VARCHAR2(300);
  TYPE t_char_arr IS TABLE OF t_cache_str_value INDEX BY t_cache_key;
  gv_char_arr t_char_arr;
  TYPE t_num_arr IS TABLE OF NUMBER INDEX BY t_cache_key;
  gv_num_arr t_num_arr;
  TYPE t_date_arr IS TABLE OF DATE INDEX BY t_cache_key;
  gv_date_arr t_date_arr;

  -- Кэш для НДС по сервисам
  TYPE nds_rec IS RECORD (date_from DATE, date_to DATE, nds_val NUMBER, service_id INTEGER);
  TYPE nds_cache IS TABLE OF nds_rec INDEX BY BINARY_INTEGER;
  cached_nds nds_cache;

  -- Внутренние константы
  gc_ba_charge_in$i  CONSTANT INTEGER := 21;    -- 'Входные чарджи'
  gc_ba_charge_nds$i CONSTANT INTEGER := 22;    -- 'Чарджи с НДС'
  gc_big_number      CONSTANT NUMBER := 2**32;  -- Максимальное значением для 32-разрядного целого числа без знака в вычислениях.
  gc_decimal_size    CONSTANT PLS_INTEGER := 2; -- Количество десятичных знаков

  -- Внутренние переменные
  gv_num_koef_4_time_zone NUMBER := 3600; -- Коэф. для выдачи тайм-зоны. В БД хранится в часах. NC запросил в секундах...
  gv_current_date DATE; -- Текущая дата

  /**
  * Проверка: является ли пакет валидным
  */
  PROCEDURE package_is_valid
  IS
  BEGIN
    NULL;
  END package_is_valid;

  /**
  * Получить значение свойства из кэша биллинга
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - индекс в кэше
  * @return Значение запрошенного параметра из кэша (NULL, если нет в кэше)
  */
  FUNCTION get_char_cache(ip_cache_key$c IN VARCHAR2) RETURN VARCHAR2
  IS
    lv_res$c t_cache_str_value;
  BEGIN
    IF gv_char_arr.EXISTS(ip_cache_key$c) THEN
      lv_res$c := gv_char_arr(ip_cache_key$c);
      --dbms_output.put_line('Попадание в КЭШ');
    END IF;
    RETURN lv_res$c;
  END get_char_cache;

  /**
  * Сохранить значение свойства в кэше
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - индекс в кэше
  * @param ip_value$c   - значение
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
  * Сбросить кэш свойств
  * @author
  * @version
  */
  PROCEDURE clear_props_cache
  IS
  BEGIN
    gv_char_arr.delete;
  END clear_props_cache;

  /**
  * Получить число из кэша
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - индекс в кэше
  * @return Значение запрошенного числа из кэша (NULL, если нет в кэше)
  */
  FUNCTION get_number_cache(ip_cache_key$c IN VARCHAR2) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    IF gv_num_arr.EXISTS(ip_cache_key$c) THEN
      lv_res$n := gv_num_arr(ip_cache_key$c);
      --dbms_output.put_line('Попадание в КЭШ');
    END IF;
    RETURN lv_res$n;
  END get_number_cache;

  /**
  * Сохранить значение в числовой кэш
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - индекс в кэше
  * @param ip_value$n   - значение
  */
  PROCEDURE set_number_cache(
    ip_cache_key$c IN VARCHAR2,
    ip_value$n     IN NUMBER
  )
  IS
  BEGIN
    IF ip_cache_key$c IS NOT NULL /*AND ip_value$c IS NOT NULL*/ THEN
      gv_num_arr(ip_cache_key$c) := ip_value$n;
    END IF;
  END set_number_cache;

  /**
  * Сбросить числовой кэш
  * @author
  * @version
  */
  PROCEDURE clear_number_cache
  IS
  BEGIN
    gv_num_arr.delete;
  END clear_number_cache;

  /**
  * Получить значение свойства из кэша биллинга
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - индекс в кэше
  * @return Значение запрошенного параметра из кэша (NULL, если нет в кэше)
  */
  FUNCTION get_date_cache(ip_cache_key$c IN VARCHAR2) RETURN DATE
  IS
    lv_res$d DATE;
  BEGIN
    IF gv_date_arr.EXISTS(ip_cache_key$c) THEN
      lv_res$d := gv_date_arr(ip_cache_key$c);
      --dbms_output.put_line('Попадание в КЭШ');
    END IF;
    RETURN lv_res$d;
  END get_date_cache;

  /**
  * Сохранить значение свойства в кэше
  * @author BikulovMD
  * @version 1
  * @param ip_cache_key - индекс в кэше
  * @param ip_value$d   - значение
  */
  PROCEDURE set_date_cache(
    ip_cache_key$c IN VARCHAR2,
    ip_value$d     IN DATE
  )
  IS
  BEGIN
    IF ip_cache_key$c IS NOT NULL /*AND ip_value$d IS NOT NULL*/ THEN
      gv_date_arr(ip_cache_key$c) := ip_value$d;
    END IF;
  END set_date_cache;

  /**
  * Сбросить кэш с датами
  * @author
  * @version
  */
  PROCEDURE clear_date_cache
  IS
  BEGIN
    gv_date_arr.delete;
  END clear_date_cache;

  /**
  * Сбросить кэш
  */
  PROCEDURE clear_all_cache
  IS
  BEGIN
    clear_props_cache;
    clear_number_cache;
    clear_date_cache;
  END clear_all_cache;

  /**
  * Получить дату миграции из конфигурации
  */
  FUNCTION get_config_date RETURN DATE
  IS
    lv_res$d DATE;
  BEGIN
    SELECT MAX(date_value)
    INTO lv_res$d
    FROM idb_ph2_configuration
    WHERE key = 'sysdate';
    RETURN lv_res$d;
  END get_config_date;

  /**
  * Назначить дату выполнения миграции
  *
  * @param curr_date$d - Дата миграции
  */
  PROCEDURE set_current_date(curr_date$d IN DATE)
  IS
  BEGIN
    gv_current_date := NVL(curr_date$d, current_date);
  END set_current_date;

  /**
  * Получить дату выполнения миграции
  * Получает значение из конфигурационной таблицы.
  * Если нет записи с параметром "sysdate", возвращает current_date
  *
  * @param is_curr_date - флаг для возврата current_date, минуя чтение из конфигурационной таблицы
  *                       1 - возвращает current_date/0 - чтение из конфигурационной таблицы
  * @param is_trnc_date - флаг возврата даты без времени (trunc(date))
  *                       1 - применить TRUNC/0 - не применять TRUNC
  * @return Дата миграции
  */
  FUNCTION get_current_date(
    is_curr_date IN INTEGER DEFAULT 1,
    is_trnc_date IN INTEGER DEFAULT 1
  ) RETURN DATE
  IS
    lv_res$d DATE;
  BEGIN
    --lv_res$d := current_date;
    -- Прочтем из глобальной переменной
    lv_res$d := gv_current_date;
    -- Если дата не назначена, то определим
    IF lv_res$d IS NULL THEN
      IF is_curr_date = 1 THEN
        lv_res$d := current_date;
      ELSE
        lv_res$d := NVL(get_config_date, current_date);
      END IF;
      lv_res$d := CASE WHEN is_trnc_date=1 THEN TRUNC(lv_res$d) ELSE lv_res$d END;
      -- Сохраним дату в сессии
      set_current_date(lv_res$d);
    END IF;
    --
    RETURN lv_res$d;
  END get_current_date;

  /**
  * Получить значение свойства на терминальных ресурсах
  * @author
  * @version
  * @param terminal_resource_id$c - Идентификатор терминального ресурса
  * @param billing_id$i           - Идентификатор биллинга
  * @param prop_id$i              - Идентификатор атрибута
  * @param filed$c                - Поле для вывода
  * @param date$d                 - На какую дату смотрим
  * @return Значение запрошенного параметра
  */
  FUNCTION get_term_res_props(
    terminal_resource_id$c IN VARCHAR2,
    billing_id$i           IN INTEGER,
    prop_id$i              IN INTEGER,
    filed$c                IN VARCHAR2 DEFAULT 'MIN(PROP_VALUE)',
    date$d                 IN DATE DEFAULT NULL
  ) RETURN VARCHAR2
  IS
    sql_text$c     VARCHAR2(4000);
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
/*
СПРАВКА
-- Индексы таблицы CABLE_CITY_TERM_RES_PROPS_ALL
EXCELLENT I_CCTR_PROP_ID_VAL  Normal  PROP_ID, PROP_VALUE
EXCELLENT I_CCTR_TR_FROM    Normal  TERMINAL_RESOURCE_ID, ACTIVE_FROM
EXCELLENT PK_TERM_RES_PROP_ID Unique  TERM_RES_PROP_ID
-- Связи
FK_CCTR_PROP_ID    : CABLE_CITY_TERM_RES_PROPS_ALL.PROP_ID = CABLE_CITY_PROP_DICTIONARY.PROP_ID
FK_CCTR_TERM_RES_ID: CABLE_CITY_TERM_RES_PROPS_ALL.TERMINAL_RESOURCE_ID = TERMINAL_RESOURCES.TERMINAL_RESOURCE_ID
*/
  BEGIN
    IF terminal_resource_id$c IS NULL OR
       billing_id$i           IS NULL OR
       prop_id$i              IS NULL OR
       filed$c                IS NULL
    THEN
      RETURN NULL;
    END IF;
    -- Получить значение из кэша
    lv_cache_key$c := 'trp'||terminal_resource_id$c||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(prop_id$i)||'&'||filed$c||'&'||TO_CHAR(date$d,'dd.mm.yyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      IF date$d IS NULL THEN
        sql_text$c := 'SELECT ' || filed$c                    || chr(13) ||
                      'FROM CABLE_CITY_TERM_RES_PROPS_ALL CP' || chr(13) ||
                      'WHERE CP.TERMINAL_RESOURCE_ID IN ('||terminal_resource_id$c || ')' || chr(13) ||
                      '  AND CP.BILLING_ID = :billing_id'     || chr(13) ||
                      '  AND CP.PROP_ID = :prop_id';
        BEGIN
          EXECUTE IMMEDIATE sql_text$c
          INTO lv_res$c
          USING IN billing_id$i, in prop_id$i;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_res$c := NULL;
        END;
      ELSE
        sql_text$c := 'SELECT ' || filed$c                    || chr(13) ||
                      'FROM CABLE_CITY_TERM_RES_PROPS_ALL CP' || chr(13) ||
                      'WHERE CP.TERMINAL_RESOURCE_ID IN ('||terminal_resource_id$c || ')' || chr(13) ||
                      '  AND CP.BILLING_ID = :billing_id'     || chr(13) ||
                      '  AND CP.PROP_ID = :prop_id'           || chr(13) ||
                      '  AND CP.ACTIVE_FROM <= :curr_date'    || chr(13) ||
                      '  AND (CP.ACTIVE_TO IS NULL OR CP.ACTIVE_TO > :curr_date)';
        BEGIN
          EXECUTE IMMEDIATE sql_text$c
          INTO lv_res$c
          USING IN billing_id$i, IN prop_id$i, IN date$d, IN date$d;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_res$c := NULL;
        END;
      END IF;

      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;

    RETURN lv_res$c;
  END get_term_res_props;

  /**
  * Получить значение свойства на плане
  * @author
  * @version
  * @param plan_id$i    - Идентификатор плана
  * @param billing_id$i - Идентификатор биллинга
  * @param prop_id$i    - Идентификатор атрибута
  * @param date$d       - На какую дату смотрим
  * @return Значение запрошенного параметра
  */
  FUNCTION get_plan_props(
    plan_id$i    IN INTEGER,
    billing_id$i IN INTEGER,
    prop_id$i    IN INTEGER,
    date$d       IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    IF plan_id$i    IS NULL OR
       billing_id$i IS NULL OR
       prop_id$i    IS NULL
    THEN
      RETURN NULL;
    END IF;
    -- Получить значение из кэша
    lv_cache_key$c := 'ppl'||TO_CHAR(plan_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(prop_id$i)||'&'||TO_CHAR(date$d,'dd.mm.yyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      FOR rec IN (
        SELECT MAX(pp.prop_value) AS prop_value
        FROM plan_properties_all pp
        WHERE pp.plan_id =plan_id$i
          AND pp.property_type_id = prop_id$i
          AND pp.billing_id = billing_id$i
          AND pp.active_from <= date$d
          AND (pp.active_to IS NULL OR pp.active_to > date$d)
      ) LOOP
        lv_res$c := rec.prop_value;
      END LOOP;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_plan_props;

  /**
  * Возвращает способ организации связи
  * @param teo_id$i     - Идентификатор ТЭО
  * @param billing_id$i - Идентификатор биллинга
  * @param active_to$d  - Дата, на которую получаем актуальную информацию
  * @return
  */
  FUNCTION get_organiz_of_communicat(
    teo_id$i     IN INTEGER,
    billing_id$i IN INTEGER,
    active_to$d  IN DATE := get_current_date()
  ) RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_teo_props_name(get_teo_props(teo_id$i, billing_id$i, 14, active_to$d), billing_id$i);
  END get_organiz_of_communicat;

  /**
  * Возвращает способ организации связи
  * @param addendum_id$i - Идентификатор приложения
  * @param billing_id$i  - Идентификатор биллинга
  * @param active_from$d - Дата от ...
  * @param active_to$d   - Дата до ...
  * @return Способ организации связи
  */
  FUNCTION get_organiz_of_communicat(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    active_from$d IN DATE := get_current_date(),
    active_to$d   IN DATE := get_current_date()
  ) RETURN VARCHAR2
  IS
    lv_res$c VARCHAR2(300);
    lv_cnt$i PLS_INTEGER;
    lv_default$c VARCHAR2(300) := 'FTTB RIAS';
  BEGIN
    -- Получим схему включения
    SELECT count(1)
    INTO lv_cnt$i
    FROM teo_link_addenda_all tla,
         teo_all teo
    WHERE 1 = 1
      AND tla.addendum_id = addendum_id$i
      AND tla.billing_id  = billing_id$i
      AND tla.active_from <= active_to$d
      AND (tla.active_to IS NULL OR tla.active_to >= trunc(active_from$d, 'MM'))
      AND teo.teo_id = tla.teo_id
      AND teo.billing_id = tla.billing_id
      AND UPPER(TRIM(teo.connect_scheme)) LIKE '%СХЕМА 1%'
      AND ROWNUM <= 1;
    -- Если схема включения найдена и значение равно 'Схема 1', то берем 'FTTB RIAS'
    IF lv_cnt$i > 0 THEN
      lv_res$c := lv_default$c;
    ELSE
      -- Ищем способ организации связи хотя бы на одном ТЭО
      FOR rec_teo IN (
        SELECT tla.teo_id
        FROM teo_link_addenda_all tla
        WHERE 1 = 1
          AND tla.addendum_id = addendum_id$i
          AND tla.billing_id  = billing_id$i
          AND tla.active_from <= active_to$d
          AND (tla.active_to IS NULL OR tla.active_to > active_from$d)
      )
      LOOP
        lv_res$c := rias_mgr_support.get_organiz_of_communicat(teo_id$i     => rec_teo.teo_id,
                                                               billing_id$i => billing_id$i,
                                                               active_to$d  => active_to$d);
        EXIT WHEN lv_res$c IS NOT NULL;
      END LOOP;
    END IF;
    RETURN lv_res$c;
  END get_organiz_of_communicat;

  /**
  * Возвращает наименование свойства ТЭО (способ организации связи, Точка включения ВОЛС)
  * @param property_id$i - Идентификатор флага
  * @param billing_id$i  - Идентификатор биллинга
  * @return
  */
  function get_teo_props_name(
    property_id$i in integer,
    billing_id$i  in integer
  ) RETURN VARCHAR2
  is
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  begin
    -- Получить значение из кэша
    lv_cache_key$c := 'tpm'||TO_CHAR(property_id$i)||'&'||TO_CHAR(billing_id$i);
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      select max(fl.flag_name)
      into lv_res$c
      from pr_requests_flags_all fl
      where fl.flag_id = property_id$i
        and fl.billing_id = billing_id$i;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  end get_teo_props_name;

  /**
  * Получить значение свойства на ТЭО
  * @author
  * @version
  * @param teo_id$i     - Идентификатор ТЭО
  * @param billing_id$i - Идентификатор биллинга
  * @param prop_id$i    - Идентификатор атрибута
  * @param active_to$d  - Дата, на которую получаем актуальную информацию
  * @return Значение запрошенного параметра
  */
  FUNCTION get_teo_props(
    teo_id$i     IN INTEGER,
    billing_id$i IN INTEGER,
    prop_id$i    IN INTEGER,
    active_to$d  IN DATE := get_current_date()
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'tp'||TO_CHAR(teo_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(prop_id$i)||'&'||TO_CHAR(active_to$d,'dd.mm.yyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      FOR rec IN (SELECT tp.prop_value
            FROM teo_properties_all tp
            WHERE tp.teo_id = teo_id$i
              AND tp.billing_id = billing_id$i
              AND tp.prop_type_id = prop_id$i
              AND tp.active_from <= active_to$d
              AND (tp.active_to IS NULL OR tp.active_to > active_to$d)
      ) LOOP
        lv_res$c:=rec.prop_value;
        EXIT;
      END LOOP;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;

    RETURN lv_res$c;
  END get_teo_props;

  /**
  * ТЭО активно с ..
  * @param teo_id$i       - Идентификатор ТЭО
  * @param billing_id$i   - Идентификатор биллинга
  * @param is_agreement$i - Флаг того, что ищем в пределах договора ТЭО
  *                         0/1 - нет/да
  * @RETURN ТЭО активно с ..
  */
  FUNCTION get_teo_active_from(
    teo_id$i       INTEGER,
    billing_id$i   INTEGER,
    is_agreement$i INTEGER := 0
  ) RETURN DATE
  IS
    date_step$d    DATE := NULL;
    lv_res$d       DATE := NULL;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'taf'||TO_CHAR(teo_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(is_agreement$i);
    lv_res$d := get_date_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$d IS NULL THEN
      -- даты активности ресурсов
      SELECT MIN(rc.active_from) active_from INTO lv_res$d
      FROM addendum_resources_all     ar,
           resource_contents_all      rc,
           teo_terminal_resources_all tr
      WHERE rc.resource_id = ar.resource_id
        AND rc.billing_id = ar.billing_id
        AND tr.terminal_resource_id = rc.terminal_resource_id
        AND tr.billing_id = rc.billing_id
        AND tr.teo_id = teo_id$i
        AND tr.billing_id = billing_id$i
        AND (is_agreement$i = 0 OR EXISTS
             (SELECT 1
                FROM addenda_all ad, point_plugins_all pp, teo_all te
               WHERE pp.point_plugin_id = te.point_plugin_id
                 AND pp.billing_id = te.billing_id
                 AND ad.agreement_id = pp.agreement_id
                 AND ad.billing_id = pp.billing_id
                 AND te.teo_id = teo_id$i
                 AND te.billing_id = billing_id$i
                 AND ad.addendum_id = ar.addendum_id
                 AND ad.billing_id = ar.billing_id
                 AND rownum <= 1));
      SELECT MAX(rs.active_from)
        INTO date_step$d
        FROM teo_all                   te,
             pr_proc_requests_all      pr,
             pr_proc_request_state_all rs
       WHERE te.attr_entity_id = pr.attr_entity_id
         AND te.billing_id = pr.billing_id
         AND te.teo_id = teo_id$i
         AND te.billing_id = billing_id$i
         AND pr.request_id = rs.request_id
         AND pr.billing_id = rs.billing_id
         AND rs.step_id + 0 IN (271);
      IF date_step$d IS NOT NULL THEN
        lv_res$d := least(nvl(lv_res$d, date_step$d), date_step$d);
      END IF;
      -- Закинем в кеш
      set_date_cache(ip_cache_key$c => lv_cache_key$c, ip_value$d=> lv_res$d);
    END IF;
    RETURN lv_res$d;
  END get_teo_active_from;

  /**
  * ТЭО активно до ..
  * @param teo_id$i       - Идентификатор ТЭО
  * @param billing_id$i   - Идентификатор биллинга
  * @param is_agreement$i - Флаг того, что ищем в пределах договора ТЭО
  *                         0/1 - нет/да
  * @RETURN ТЭО активно до ..
  */
  FUNCTION get_teo_active_to(
    teo_id$i       INTEGER,
    billing_id$i   INTEGER,
    is_agreement$i INTEGER := 0
  ) RETURN DATE
  IS
    lv_res$d       DATE := NULL;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'tat'||TO_CHAR(teo_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(is_agreement$i);
    lv_res$d := get_date_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$d IS NULL THEN
      -- даты активности ресурсов
      SELECT
        CASE
          WHEN SUM(is_null) > 0 THEN NULL
            ELSE MAX(active_to)
        END active_to
      INTO lv_res$d
      FROM (SELECT rc.active_to,
                   CASE
                     WHEN rc.active_to IS NULL THEN 1
                     ELSE 0
                   END is_null
              FROM addendum_resources_all     ar,
                   resource_contents_all      rc,
                   teo_terminal_resources_all tr
             WHERE rc.resource_id = ar.resource_id
               AND rc.billing_id = ar.billing_id
               AND tr.terminal_resource_id = rc.terminal_resource_id
               AND tr.billing_id = rc.billing_id
               AND tr.teo_id = teo_id$i
               AND tr.billing_id = billing_id$i
               AND (is_agreement$i = 0 OR EXISTS
                    (SELECT 1
                       FROM addenda_all ad, point_plugins_all pp, teo_all te
                      WHERE pp.point_plugin_id = te.point_plugin_id
                        AND pp.billing_id = te.billing_id
                        AND ad.agreement_id = pp.agreement_id
                        AND ad.billing_id = pp.billing_id
                        AND te.teo_id = teo_id$i
                        AND te.billing_id = tr.billing_id
                        AND ad.addendum_id = ar.addendum_id
                        AND ad.billing_id = ar.billing_id
                        AND rownum <= 1))) a;
      -- Закинем в кеш
      set_date_cache(ip_cache_key$c => lv_cache_key$c, ip_value$d=> lv_res$d);
    END IF;
    RETURN lv_res$d;
  END get_teo_active_to;

  /**
  * Получить флаг присутствия заданного типа атрибута ТЭО с заданным значением на приложении
  * @param  addendum_id$i      - Идентификатор приложения
  * @param  billing_id$i       - Идентификатор биллинга
  * @param  teo_prop_type_id$i - Тип проперти
  * @param  teo_prop_value$i   - Значение проперти
  * @param date$d              - На какую дату смотрим
  * @return Флаг присутствия 1/0
  */
  FUNCTION is_prop_teo_on_addendum(
    addendum_id$i      IN INTEGER,
    billing_id$i       IN INTEGER,
    teo_prop_type_id$i IN INTEGER,
    teo_prop_value$i   IN VARCHAR2,
    date$d             IN DATE DEFAULT get_current_date()
  ) RETURN INTEGER
  IS
    lv_res$i       INTEGER;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'iptoa'
                      || TO_CHAR(addendum_id$i)    ||
                      '&' || TO_CHAR(billing_id$i) ||
                      '&' || TO_CHAR(teo_prop_type_id$i) ||
                      '&' || teo_prop_value$i      ||
                      '&' || TO_CHAR(date$d,'dd.mm.yyyy');
    lv_res$i := get_number_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$i IS NULL THEN
      SELECT COUNT(*) INTO lv_res$i
       FROM ADDENDUM_RESOURCES_ALL     AR,
            RESOURCE_CONTENTS_ALL      RC,
            TEO_TERMINAL_RESOURCES_ALL TR,
            TEO_PROPERTIES_ALL         TP
       WHERE 1 = 1
         AND AR.ADDENDUM_ID = addendum_id$i
         AND AR.BILLING_ID  = billing_id$i
         AND AR.ACTIVE_FROM <= date$d
         AND (AR.ACTIVE_TO IS NULL OR AR.ACTIVE_TO > date$d)
         --Связь с терминальными ресурсами
         AND RC.RESOURCE_ID = AR.RESOURCE_ID
         AND RC.BILLING_ID = AR.BILLING_ID
         AND RC.ACTIVE_FROM <= date$d
         AND (RC.ACTIVE_TO IS NULL OR RC.ACTIVE_TO > date$d)
         -- ТЭО
         AND TR.TERMINAL_RESOURCE_ID = RC.TERMINAL_RESOURCE_ID
         AND TR.BILLING_ID = RC.BILLING_ID
         AND TR.ACTIVE_FROM <= date$d
         AND (TR.ACTIVE_TO IS NULL OR TR.ACTIVE_TO > date$d)
         -- Property (различные дополнительные данные ТЭО)
         AND tp.teo_id = tr.teo_id
         AND tp.billing_id = tr.billing_id
         AND TP.PROP_TYPE_ID = teo_prop_type_id$i--39
         AND TP.PROP_VALUE = teo_prop_value$i--8
         AND TP.ACTIVE_FROM <= date$d
         AND (TP.ACTIVE_TO IS NULL OR TP.ACTIVE_TO > date$d)
         AND rownum <= 1;
      -- Сохранить в кеш
      set_number_cache(ip_cache_key$c => lv_cache_key$c, ip_value$n => lv_res$i);
    END IF;
    RETURN lv_res$i;
  END is_prop_teo_on_addendum;

  /**
  * Проверка закешировано ли значение константы ПО СЕРВИСАМ
  * @author Взято из sa_bal_funcs
  * @version
  * @param service_id$i - Идентификатор сервиса (услуги)
  * @param billing_id$i - Идентификатор биллинга
  * @param value_date$d - На какую дату получить % НДС
  * @return Значение коэфициента НДС/NULL
  */
  --
  FUNCTION check_nds_cached(service_id$i INTEGER := NULL,
                            billing_id$i INTEGER := NULL,
                            value_date$d DATE) RETURN NUMBER
  IS
    nds$n NUMBER := NULL;
  BEGIN
    IF (cached_nds.count > 0) THEN
      FOR i IN cached_nds.first .. cached_nds.last
      LOOP
        IF (cached_nds(i).date_from <= value_date$d AND cached_nds(i).date_to > value_date$d)
          AND (cached_nds(i).service_id = service_id$i OR cached_nds(i).service_id IS NULL AND service_id$i IS NULL)
        THEN
          nds$n := cached_nds(i).nds_val;
          EXIT;
        END IF;
      END LOOP;
    END IF;
    RETURN nds$n;
  END check_nds_cached;

  /**
  * Коэфициент для НДС по сервисам
  * @author Взято из sa_bal_funcs
  * @version
  * @throw  -20001, -20002, -20003
  * @param service_id$i - Идентификатор сервиса (услуги)
  * @param billing_id$i - Идентификатор биллинга
  * @param value_date$d - На какую дату получить % НДС
  * @return Значение коэфициента НДС
  */
  function get_nds (
    service_id$i integer := null,
    billing_id$i integer := null,
    value_date$d date := get_current_date()
  ) return number
  is
    debug$n number := 0;
    res$n number;
    date_from$d date;
    date_to$d date;
    cache_count$n number;
    nds_null$e exception;
    null_param$e exception;
  begin
    -- Проверим входные параметры
    if value_date$d is null or billing_id$i is null then raise null_param$e; end if;
    -- берем из кеша, если есть
    debug$n := 1;
    res$n := check_nds_cached(service_id$i, billing_id$i, value_date$d);
    -- в кеше нет
    debug$n := 2;
    if res$n is null then
      debug$n := 3;
      -- Для начала проверим НДС по сервису
      if service_id$i is not null then -- Но тут может оказаться так, что сервис передан, а вот в расчёт НДС он индивидуально не заведён
        debug$n := 4;
        begin
          select bh.coef
                 , bh.timestamp
                 , bh.timestamp_to
          into res$n
               , date_from$d
               , date_to$d
          from ba_handle_copy_all   bh
              ,ba_service_links_all bls
          where 1 = 1
          and bh.receiver_account_id = bls.balance_account_id
          and bh.billing_id = bls.billing_id
          and bls.service_id=service_id$i
          and bls.billing_id=billing_id$i
          and bh.timestamp <= value_date$d
          and bh.timestamp_to > value_date$d
          and bh.balance_account_id = gc_ba_charge_in$i;
        exception
          when no_data_found then res$n := null;
        end;
      end if;
      -- Не нашлось НДС по сервису. Ищем его "как раньше", только по дате
      if res$n is null then
        debug$n := 5;
        begin
          select coef
                 , timestamp
                 , timestamp_to
          into res$n
               , date_from$d
               , date_to$d
          from ba_handle_copy_all
          where 1 = 1
          and timestamp <= value_date$d
          and timestamp_to > value_date$d
          and balance_account_id = gc_ba_charge_in$i
          and receiver_account_id = gc_ba_charge_nds$i
          and billing_id = billing_id$i;
        exception
          when no_data_found then raise nds_null$e;
        end;
      end if;
      debug$n := 6;
      --добавим в кеш
      cache_count$n:=cached_nds.count+1;
      cached_nds(cache_count$n).nds_val := res$n;
      cached_nds(cache_count$n).service_id := service_id$i;
      cached_nds(cache_count$n).date_from := date_from$d;
      cached_nds(cache_count$n).date_to := date_to$d;
    end if;
    debug$n := 7;
    return res$n;
  exception
    when null_param$e then
      raise_application_error (-20001, 'sa_bal_funcs.get_nds ('||to_char(value_date$d, 'dd.mm.yyyy hh24:mi:ss')||', service_id$i='||service_id$i||' , billing_id$i='||billing_id$i||'), debug$n='||debug$n||' : переданы не все параметры');
    when nds_null$e then
      raise_application_error (-20002, 'sa_bal_funcs.get_nds ('||to_char(value_date$d, 'dd.mm.yyyy hh24:mi:ss')||', service_id$i='||service_id$i||' , billing_id$i='||billing_id$i||'), debug$n='||debug$n||' : НДС не найден');
    when others then
      raise_application_error (-20003, sqlerrm(sqlcode)||' sa_bal_funcs.get_nds ('||to_char(value_date$d, 'dd.mm.yyyy hh24:mi:ss')||', service_id$i='||service_id$i||' , billing_id$i='||billing_id$i||'), debug$n='||debug$n);
  end get_nds;

  /**
  * Преобразование ip из числа в строку
  * @param  ip$n - IP-адрес в виде числа
  * @return Преобразованный IP-адрес
  */
  FUNCTION ip_number_to_char(ip$n IN NUMBER := NULL) RETURN VARCHAR2
  IS
    tmp$c VARCHAR2(15);
    ip$c  VARCHAR2(15);
  BEGIN
    IF (ip$n IS NULL) THEN
      RETURN(NULL);
    END IF;
    IF (ip$n = 0) THEN
      RETURN('0.0.0.0');
    END IF;
    tmp$c := LPAD(ABS(ip$n), 12, 0);
    ip$c  := SUBSTR(tmp$c, 1, 3) || '.' || SUBSTR(tmp$c, 4, 3) || '.' ||
             SUBSTR(tmp$c, 7, 3) || '.' || SUBSTR(tmp$c, 10, 3);
    ip$c  := REPLACE(ip$c, '.0', '.');
    ip$c  := REPLACE(ip$c, '.0', '.');
    ip$c  := ltrim(ip$c, ' 0');
    RETURN(ip$c);
  END ip_number_to_char;

  /**
  * Получить ссылку на локацию клиента, где предоставляется услуга
  * @param  addendum_id$i  - Идентификатор приложения
  * @param  billing_id$i   - Идентификатор биллинга
  * @param  delimiter$c    - Разделитель
  * @return Список точек подключения через ','
  */
  FUNCTION get_customer_location(
    addendum_id$i IN NUMBER,
    billing_id$i  IN NUMBER,
    delimiter$c   IN VARCHAR2 := ', '
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
    lv_cur_date$d  DATE := get_current_date();
    lv_delimiter$c VARCHAR2(10) := NVL(delimiter$c, ', ');
    TYPE t_varchar2_tbl IS TABLE OF t_cache_str_value INDEX BY PLS_INTEGER;
    lv_idb_id_arr t_varchar2_tbl;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'cl'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(addendum_id$i);
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      BEGIN
/*
        SELECT cl.idb_id
        INTO lv_res$c
        FROM teo_link_addenda_all tla
           , teo_all t
           , idb_ph2_customer_location cl
        WHERE tla.addendum_id = addendum_id$i
          AND tla.billing_id   = billing_id$i
          AND tla.active_from <= lv_cur_date$d
          -- привязка действовала в текущем месяце
          AND NVL(tla.active_to, TRUNC(lv_cur_date$d,'mm') + 1) > TRUNC(lv_cur_date$d,'mm')
          AND tla.teo_id = t.teo_id
          AND tla.billing_id = t.billing_id
          AND tla.billing_id = billing_id$i
          AND t.point_plugin_id = cl.source_id
          AND t.billing_id = cl.source_system
          AND t.billing_id = billing_id$i
          AND rownum <= 1;
*/

        SELECT DISTINCT cl.idb_id
        BULK COLLECT INTO lv_idb_id_arr
        --INTO lv_res$c
        FROM teo_link_addenda_all tla
           , teo_all t
           , idb_ph2_customer_location cl
        WHERE 1 = 1
          AND tla.addendum_id = addendum_id$i
          AND tla.billing_id  = billing_id$i
          AND tla.active_from <= lv_cur_date$d
          -- привязка действовала в текущем месяце
          AND NVL(tla.active_to, TRUNC(lv_cur_date$d,'mm') + 1) > TRUNC(lv_cur_date$d,'mm')
          AND t.teo_id = tla.teo_id
          AND t.billing_id = tla.billing_id
          AND t.billing_id = billing_id$i
          AND cl.source_id = TO_CHAR(t.point_plugin_id)
          AND cl.source_system = TO_CHAR(t.billing_id)
          AND cl.source_system = TO_CHAR(billing_id$i);
        --
        FOR i IN 1..lv_idb_id_arr.COUNT LOOP
          lv_res$c := lv_res$c || (CASE WHEN lv_res$c IS NULL THEN '' ELSE lv_delimiter$c END) ||   lv_idb_id_arr(i);
        END LOOP;

/*
        SELECT listagg(cl.idb_id, lv_delimiter$c) WITHIN GROUP(ORDER BY cl.idb_id)
        INTO lv_res$c
        FROM teo_link_addenda_all tla
           , teo_all t
           , idb_ph2_customer_location cl
        WHERE  tla.addendum_id = addendum_id$i
          AND tla.billing_id   = billing_id$i
          AND tla.active_from <= lv_cur_date$d
          -- привязка действовала в текущем месяце
          AND NVL(tla.active_to, TRUNC(lv_cur_date$d,'mm') + 1) > TRUNC(lv_cur_date$d,'mm')
          AND tla.teo_id = t.teo_id
          AND tla.billing_id = t.billing_id
          AND tla.billing_id = billing_id$i
          AND t.point_plugin_id = cl.source_id
          AND t.billing_id = cl.source_system
          AND t.billing_id = billing_id$i;
*/
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_res$c := NULL;WHEN VALUE_ERROR THEN lv_res$c := NULL;
      END;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;

    RETURN lv_res$c;--NVL(lv_res$c, '0');
  END get_customer_location;

  /**
  * Получить стоимость услуги для SERVICE_ID = 1799
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  plan_item_id$i  - Идентификатор состава плана
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  * @param  with_nds$i      - Флаг учета в ответе НДС
  */
  FUNCTION get_service_cost_1799(
    addendum_id$i  IN INTEGER := NULL,
    plan_item_id$i IN INTEGER := NULL,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date(),
    with_nds$i     IN INTEGER := 1
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    BEGIN
      IF plan_item_id$i IS NULL THEN
        SELECT rup.price
        INTO lv_res$n
        FROM activate_license_fee_all alf,
             plan_items_all           pi,
             plan_contents_all        pc,
             simple_plan_items_all    sp,
             ri_ulf_ps_contents_all   rup
        WHERE 1 = 1
          AND alf.addendum_id = addendum_id$i
          AND alf.billing_id  = billing_id$i
          AND alf.active_from <= date$d
          AND (alf.active_to IS NULL OR alf.active_to > date$d)
          AND pi.plan_item_id = alf.plan_item_id
          AND pi.billing_id = alf.billing_id
          AND pi.service_id = service_id$i
          AND pc.plan_item_id = pi.plan_item_id
          AND pc.billing_id = pi.billing_id
          and pc.active_from <= date$d
          and (pc.active_to IS NULL OR pc.active_to > date$d)
          AND sp.plan_item_id = pc.plan_item_id
          AND sp.billing_id = pc.billing_id
          AND rup.rule_id = sp.rule_id
          AND rup.billing_id = sp.billing_id
          AND rup.threshold > 0
          --07.12.2021 A.Kosterin add fetch
          order by rup.threshold desc
          FETCH NEXT 1 ROWS ONLY;
      ELSE
        select rup.price
        INTO lv_res$n
        from plan_contents_all pc,
             plan_items_all pi,
             simple_plan_items_all sp,
             ri_ulf_ps_contents_all rup
        where 1=1
          and pi.plan_item_id = plan_item_id$i
          and pi.billing_id = billing_id$i
          and pi.service_id = service_id$i
          and pc.plan_item_id = pi.plan_item_id
          and pc.billing_id = pi.billing_id
          and pc.active_from <= date$d
          and (pc.active_to IS NULL OR pc.active_to > date$d)
          and sp.plan_item_id = pc.plan_item_id
          and sp.billing_id = pc.billing_id
          and rup.rule_id = sp.rule_id
          and rup.billing_id = sp.billing_id
          and rup.threshold > 0
          --07.12.2021 A.Kosterin add fetch
          order by rup.threshold desc
          FETCH NEXT 1 ROWS ONLY;
      END IF;
      -- Если надо накрутим НДС
      IF with_nds$i = 1 THEN
        lv_res$n := ROUND(lv_res$n * get_nds(service_id$i, billing_id$i), 2);
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_res$n := NULL;
    END;
    RETURN lv_res$n;
  END get_service_cost_1799;

  /**
  * Получить стоимость услуги
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  plan_item_id$i  - Идентификатор состава плана
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  * @param  with_nds$i      - Флаг учета в ответе НДС
  */
  FUNCTION get_service_cost_all(
    addendum_id$i  IN INTEGER := NULL,
    plan_item_id$i IN INTEGER := NULL,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date(),
    with_nds$i     IN INTEGER := 1
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    BEGIN
      IF plan_item_id$i IS NULL THEN
        -- Пришлось применить MAX(), потому что в какой-то момент времени на некоторых записях
        -- пошло задвоение в activate_license_fee_all
        SELECT MAX(lfp.price)
        INTO lv_res$n
        FROM activate_license_fee_all alf,
             plan_items_all           pi,
             simple_plan_items_all    spi,
             ri_license_fee_ps_all    lfp
        WHERE 1 = 1
          AND alf.addendum_id = addendum_id$i
          AND alf.billing_id  = billing_id$i
          AND alf.active_from <= date$d
          AND (alf.active_to IS NULL OR alf.active_to > date$d)
          AND pi.plan_item_id = alf.plan_item_id
          AND pi.billing_id = alf.billing_id
          AND pi.service_id = service_id$i
          AND pi.plan_item_id = spi.plan_item_id
          AND pi.billing_id = spi.billing_id
          AND spi.rule_id = lfp.rule_id
          AND spi.billing_id = lfp.billing_id;
      ELSE
         SELECT lfp.price
         INTO lv_res$n
         FROM plan_items_all        pi,
              simple_plan_items_all spi,
              ri_license_fee_ps_all lfp
         WHERE pi.plan_item_id = plan_item_id$i
           AND pi.billing_id = billing_id$i
           AND pi.service_id = service_id$i
           AND pi.plan_item_id = spi.plan_item_id
           AND pi.billing_id = spi.billing_id
           AND spi.rule_id = lfp.rule_id
           AND spi.billing_id = lfp.billing_id;
      END IF;
      -- Если надо накрутим НДС
      IF with_nds$i = 1 THEN
        lv_res$n := ROUND(lv_res$n * get_nds(service_id$i, billing_id$i), 2);
      END IF;
      -- lv_res$n := lv_res$n * (CASE WHEN with_nds$i = 1 THEN get_nds(service_id$i, billing_id$i) ELSE 1 END);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_res$n := NULL;
    END;
    RETURN lv_res$n;
  END;

  /**
  * Получить стоимость услуги для SERVICE_ID = 534
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  plan_item_id$i  - Идентификатор состава плана
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  * @param  with_nds$i      - Флаг учета в ответе НДС
  */
  FUNCTION get_service_cost_534(
    addendum_id$i  IN INTEGER := NULL,
    plan_item_id$i IN INTEGER := NULL,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date(),
    with_nds$i     IN INTEGER := 1
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    -- В Санкт-Петербурге стоимость указана на АбонПлате
    IF billing_id$i = 556 THEN
      lv_res$n := get_abon_pays(addendum_id$i => addendum_id$i,
                                billing_id$i  => billing_id$i,
                                service_id$i  => service_id$i,
                                date$d        => date$d,
                                with_nds$i     => with_nds$i);
    END IF;
    IF lv_res$n IS NULL THEN
      lv_res$n := get_service_cost_all(addendum_id$i  => addendum_id$i,
                                       plan_item_id$i => plan_item_id$i,
                                       billing_id$i   => billing_id$i,
                                       service_id$i   => service_id$i,
                                       date$d         => date$d,
                                       with_nds$i     => with_nds$i);
      IF lv_res$n IS NULL THEN
        lv_res$n := get_abon_pays(addendum_id$i => addendum_id$i,
                                  billing_id$i  => billing_id$i,
                                  service_id$i  => service_id$i,
                                  date$d        => date$d,
                                  with_nds$i     => with_nds$i);
      END IF;
    END IF;
    RETURN lv_res$n;
  END get_service_cost_534;

  /**
  * Получить стоимость услуги для SERVICE_ID = 103257
  * [Временная блокировка услуг связи]
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  * @param  with_nds$i      - Флаг учета в ответе НДС
  */
  FUNCTION get_service_cost_103257(
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date(),
    with_nds$i     IN INTEGER := 1
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    lv_res$n := get_abon_pays(addendum_id$i => addendum_id$i,
                              billing_id$i  => billing_id$i,
                              service_id$i  => service_id$i,
                              date$d        => date$d,
                              with_nds$i     => with_nds$i);
    RETURN lv_res$n;
  END get_service_cost_103257;

  /**
  * Получить стоимость услуги
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  plan_item_id$i  - Идентификатор состава плана
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  * @param  with_nds$i      - Флаг учета в ответе НДС
  */
  FUNCTION get_service_cost(
    addendum_id$i  IN INTEGER := NULL,
    plan_item_id$i IN INTEGER := NULL,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date(),
    with_nds$i     IN INTEGER := 1
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
    lv_cache_key$c t_cache_key;
    lv_with_nds$i  PLS_INTEGER := NVL(with_nds$i, 1);
    lv_date_active_to$d DATE;
  BEGIN
    IF addendum_id$i  IS NULL AND
       plan_item_id$i IS NULL AND
       billing_id$i   IS NULL AND
       service_id$i   IS NULL
    THEN
      RETURN 0;
    END IF;
    -- Получить значение из кэша
    lv_cache_key$c := 'sc'||
                      TO_CHAR(addendum_id$i) || '&' ||
                      TO_CHAR(plan_item_id$i)|| '&' ||
                      TO_CHAR(billing_id$i)  || '&' ||
                      TO_CHAR(service_id$i)  || '&' ||
                      TO_CHAR(date$d, 'ddmmyyyy') || '&' ||
                      TO_CHAR(lv_with_nds$i);
    lv_res$n := get_number_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$n IS NULL THEN
        -- Будем расходится по услугам
        -- 1799   - Абонентская плата за дополнительные ip-адреса
        -- 101572 - IPv6 (Добавлено 20.10.2020)
        IF service_id$i IN (1799, 101572) THEN
          lv_res$n := get_service_cost_1799(addendum_id$i  => addendum_id$i,
                                            plan_item_id$i => plan_item_id$i,
                                            billing_id$i   => billing_id$i,
                                            service_id$i   => service_id$i,
                                            date$d         => date$d,
                                            with_nds$i     => lv_with_nds$i);
        ELSIF service_id$i = 534 THEN
          lv_res$n := get_service_cost_534(addendum_id$i  => addendum_id$i,
                                           plan_item_id$i => plan_item_id$i,
                                           billing_id$i   => billing_id$i,
                                           service_id$i   => service_id$i,
                                           date$d         => date$d,
                                           with_nds$i     => lv_with_nds$i);
        -- Временная блокировка услуг связи
        ELSIF service_id$i = 103257 THEN
          lv_res$n := get_service_cost_103257(addendum_id$i  => addendum_id$i,
                                              billing_id$i   => billing_id$i,
                                              service_id$i   => service_id$i,
                                              date$d         => date$d,
                                              with_nds$i     => lv_with_nds$i);

----A.Kosterin 22.06.2021 если 103257 была активна в текущем месяце, но на момент get_current_date() она не активна то выбираем последний ACTIVE_FROM (если несколько приостановок, то все пойдут по одной цене)
WITH service_table_103257 AS
 (SELECT pi.SERVICE_ID,
         pi.billing_id,
         alf.active_to,
         alf.ACTIVE_FROM,
         ad.ADDENDUM_ID,
         MAX(ACTIVE_FROM) over(PARTITION BY pi.PLAN_ITEM_ID, pi.SERVICE_ID, ad.ADDENDUM_ID, ad.billing_id) AS max_ACTIVE_FROM
  FROM   addenda_all ad, plan_items_all pi, activate_license_fee_all alf
  WHERE  ad.addendum_id = addendum_id$i
  AND    alf.billing_id = ad.billing_id
  AND    alf.addendum_id = ad.addendum_id
  AND    pi.billing_id = ad.billing_id
  AND    pi.plan_item_id = alf.plan_item_id
  AND    pi.service_id = service_id$i
  AND    pi.billing_id = billing_id$i
  AND    alf.active_to BETWEEN trunc(current_date, 'MM') AND
         rias_mgr_support.get_current_date() - 1)
SELECT ACTIVE_TO
INTO   lv_date_active_to$d
FROM   service_table_103257
WHERE  ACTIVE_FROM = MAX_ACTIVE_FROM
AND    rownum <= 1;
----если стоимость рассчиталась нулевой, но услуга 103257 была активна в текущем месяце, то пересчитываем стоимость на момент s_date_active_to$d -1
IF lv_res$n = 0 AND lv_date_active_to$d IS NOT NULL THEN
  lv_res$n := get_service_cost_103257(addendum_id$i => addendum_id$i,
                                      billing_id$i  => billing_id$i,
                                      service_id$i  => service_id$i,
                                      date$d        => lv_date_active_to$d - 1,
                                      with_nds$i    => lv_with_nds$i);
---A.Kosterin 29.06.2021 временно (удалить insert 01.07.2021)
  /*insert into aak_cost_103257(addendum_id, billing_id, service_id, date_d) 
  select addendum_id$i, billing_id$i, service_id$i, lv_date_active_to$d - 1 from dual;*/

END IF;

        ELSE
          lv_res$n := get_service_cost_all(addendum_id$i  => addendum_id$i,
                                           plan_item_id$i => plan_item_id$i,
                                           billing_id$i   => billing_id$i,
                                           service_id$i   => service_id$i,
                                           date$d         => date$d,
                                           with_nds$i     => lv_with_nds$i);
      END IF;
      -- Добавить значение в КЭШ
      set_number_cache(ip_cache_key$c => lv_cache_key$c,
                       ip_value$n     => lv_res$n);
    END IF;
    RETURN NVL(lv_res$n, 0);
  END get_service_cost;

  /**
  * Получить правило расчета
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  plan_item_id$i  - Идентификатор состава плана
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор услуги
  * @param  date$d          - На какую дату смотрим
  */
  FUNCTION get_calculation_rule(
    addendum_id$i  IN INTEGER := NULL,
    plan_item_id$i IN INTEGER := NULL,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE := get_current_date()
  ) RETURN INTEGER
  IS
    lv_res$n INTEGER;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'gcr'||
                      TO_CHAR(addendum_id$i) || '&' ||
                      TO_CHAR(plan_item_id$i)|| '&' ||
                      TO_CHAR(billing_id$i)  || '&' ||
                      TO_CHAR(service_id$i)  || '&' ||
                      TO_CHAR(date$d, 'ddmmyyyy');
    lv_res$n := get_number_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$n IS NULL THEN
      BEGIN
        IF plan_item_id$i IS NULL THEN
           SELECT r.rule_impl_id
           INTO lv_res$n
           FROM activate_license_fee_all alf,
                plan_items_all           pi,
                simple_plan_items_all    spi,
                rules_all                r
           WHERE 1 = 1
             AND alf.addendum_id = addendum_id$i
             AND alf.billing_id  = billing_id$i
             AND alf.active_from <= date$d
             AND (alf.active_to IS NULL OR alf.active_to > date$d)
             AND pi.plan_item_id = alf.plan_item_id
             AND pi.billing_id = alf.billing_id
             AND pi.service_id = service_id$i
             AND pi.plan_item_id = spi.plan_item_id
             AND pi.billing_id = spi.billing_id
             AND r.rule_id = spi.rule_id
             AND r.billing_id = spi.billing_id
             AND rownum <= 1; --!!! Иногда возникает ошибка
        ELSE
           SELECT r.rule_impl_id
           INTO lv_res$n
           FROM plan_items_all        pi,
                simple_plan_items_all spi,
                rules_all             r
           WHERE pi.plan_item_id = plan_item_id$i
             AND pi.billing_id = billing_id$i
             AND pi.service_id = service_id$i
             AND pi.plan_item_id = spi.plan_item_id
             AND pi.billing_id = spi.billing_id
             and r.rule_id = spi.rule_id
             and r.billing_id = spi.billing_id;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_res$n := NULL;
      END;
      -- Добавить значение в КЭШ
      set_number_cache(ip_cache_key$c => lv_cache_key$c,
                       ip_value$n     => lv_res$n);
    END IF;
    RETURN lv_res$n;
  END;

  /**
  * Получить % скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * Remark: Если задан service_id$i, то в первую очередь ищем по нему, затем по service_name$c
  */
  FUNCTION get_cupon_4_service_t(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN t_cupon_4_service
  IS
    lv_res$tp      t_cupon_4_service;
    lv_cache_key$c t_cache_key;
  BEGIN
    IF addendum_id$i IS NULL AND
       billing_id$i  IS NULL AND
       service_id$i  IS NULL
    THEN
      RETURN lv_res$tp;
    END IF;
    -- Получить значение из кэша
    lv_cache_key$c := 'c4s'||
                      TO_CHAR(addendum_id$i) || '&' ||
                      TO_CHAR(billing_id$i)  || '&' ||
                      TO_CHAR(service_id$i);
    lv_res$tp.discount_perc := get_number_cache(lv_cache_key$c);
    lv_res$tp.discount_perc_enddate := get_date_cache(lv_cache_key$c);
    lv_res$tp.discount_perc_fromdate := get_date_cache(lv_cache_key$c||'from');
    -- В кэше нет значения, пытаемся определить
    IF lv_res$tp.discount_perc IS NULL THEN
      -- Если задана "Скидочная" услуга
      IF service_id$i IS NOT NULL THEN
      /*
           --============================
           -- % скидки вытаксквает
           -- Проверить
           --============================
           select dc.value
           from activate_license_fee_all alf
              , plan_items_all pi
              , adv_teo_link_activate_lf_all tla
              , adv_disc_charges_all dc
           where alf.addendum_id = 10837483--AR.ADDENDUM_ID
             and alf.billing_id = 1--AR.BILLING_ID
             and alf.active_from <= current_date
             and nvl(alf.active_to, current_date + 1) > current_date
             and alf.plan_item_id = pi.plan_item_id
             and alf.billing_id = pi.billing_id
             and pi.service_id = 1800
             and alf.activity_id = tla.activity_id
             and tla.action_id = dc.action_id
             and tla.billing_id = dc.billing_id
             and dc.service_disc_id = pi.service_id;
        */
        FOR rec IN (
          SELECT TO_NUMBER(REGEXP_REPLACE(af.flag_name, '[^[[:digit:]]]*')) as cupon, af.active_to, af.active_from
          FROM plan_items_all           pi,
               activate_license_fee_all alf,
               agreement_flags_all      af,
               ( --акции для юр. лиц
                SELECT tfl.flag_id,
                       tfl.billing_id,
                       tla.activity_id
                  FROM adv_teo_link_activate_lf_all tla,
                       teo_flag_links_all          tfl
                 WHERE 1 = 1
                   AND tla.teo_flags_pk_id = tfl.teo_flags_pk_id
                   AND tla.billing_id = tfl.billing_id
               ) la
          WHERE alf.addendum_id = addendum_id$i
            AND alf.billing_id = billing_id$i
            AND alf.active_from <= date$d
            AND COALESCE(alf.active_to, date$d + 1) > date$d
            --
            AND pi.plan_item_id = alf.plan_item_id
            AND pi.billing_id = alf.billing_id
            AND pi.service_id = service_id$i
            --
            AND la.activity_id = alf.activity_id
            AND la.billing_id = alf.billing_id
            --
            AND af.flag_id = la.flag_id
            AND af.billing_id = la.billing_id)
        LOOP
          lv_res$tp.discount_perc := rec.cupon;
          lv_res$tp.discount_perc_enddate := rec.active_to;
          lv_res$tp.discount_perc_fromdate := rec.active_from;
          EXIT;
        END LOOP;
      END IF;
      -- Не получилось найти по сервису или он задан, то пробуем найти по наименованию купона
      IF lv_res$tp.discount_perc IS NULL THEN
        FOR rec IN (
          SELECT TO_NUMBER(REGEXP_REPLACE(af.flag_name, '[^[[:digit:]]]*')) as cupon, af.active_to, af.active_from
          FROM services_all             se,
               plan_items_all           pi,
               activate_license_fee_all alf,
               agreement_flags_all      af,
               ( --акции для юр. лиц
                SELECT  TFL.FLAG_ID,
                        TFL.BILLING_ID,
                        TLA.ACTIVITY_ID
                  FROM adv_teo_link_activate_lf_all tla,
                       teo_flag_links_all           tfl
                 WHERE 1 = 1
                   AND tla.teo_flags_pk_id = tfl.teo_flags_pk_id
                   AND tla.billing_id = tfl.billing_id
               ) LA
          WHERE alf.addendum_id = addendum_id$i
            AND alf.billing_id = billing_id$i
            AND alf.active_from <= date$d
            AND coalesce(alf.active_to, date$d + 1) > date$d
            --
            AND pi.plan_item_id = alf.plan_item_id
            AND pi.billing_id = alf.billing_id
            --
            AND se.service_id = pi.service_id
            AND se.billing_id = pi.billing_id
            AND se.service_name like service_name$c
            --
            AND la.activity_id = alf.activity_id
            AND la.billing_id  = alf.billing_id
            --
            AND af.flag_id     = la.flag_id
            AND af.billing_id  = la.billing_id)
        LOOP
          lv_res$tp.discount_perc := rec.cupon;
          lv_res$tp.discount_perc_enddate := rec.active_to;
          lv_res$tp.discount_perc_fromdate := rec.active_from;
          EXIT;
        END LOOP;
      END IF;
      -- Добавить значение в КЭШ
      set_number_cache(ip_cache_key$c => lv_cache_key$c,
                       ip_value$n     => lv_res$tp.discount_perc);
      set_date_cache(ip_cache_key$c => lv_cache_key$c,
                     ip_value$d     => lv_res$tp.discount_perc_enddate);
      set_date_cache(ip_cache_key$c => lv_cache_key$c||'from',
                     ip_value$d     => lv_res$tp.discount_perc_fromdate);
    END IF;
    RETURN lv_res$tp;
  END get_cupon_4_service_t;

  /**
  * Получить % скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * Remark: Если задан service_id$i, то в первую очередь ищем по нему, затем по service_name$c
  */
  FUNCTION get_cupon_4_service(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN NUMBER
  IS
    lv_res$tp      t_cupon_4_service;
    --lv_cache_key$c t_cache_key;
  BEGIN
    IF addendum_id$i IS NULL AND
       billing_id$i  IS NULL AND
       service_id$i  IS NULL
    THEN
      RETURN 0;
    END IF;
    -- Получить значение
    lv_res$tp := get_cupon_4_service_t(addendum_id$i  => addendum_id$i,
                                       billing_id$i   => billing_id$i,
                                       service_id$i   => service_id$i,
                                       service_name$c => service_name$c,
                                       date$d         => date$d);
    RETURN lv_res$tp.discount_perc;
  END get_cupon_4_service;

  /**
  * Получить дату начала действия скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * @return Дата начала действия купона
  */
  FUNCTION get_cupon_active_from(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN DATE
  IS
    lv_res$tp t_cupon_4_service;
  BEGIN
    IF addendum_id$i IS NULL AND
       billing_id$i  IS NULL AND
       service_id$i  IS NULL
    THEN
      RETURN NULL;
    END IF;
    -- Получить значение
    lv_res$tp := get_cupon_4_service_t(addendum_id$i  => addendum_id$i,
                                       billing_id$i   => billing_id$i,
                                       service_id$i   => service_id$i,
                                       service_name$c => service_name$c,
                                       date$d         => date$d);
    RETURN lv_res$tp.discount_perc_fromdate;
  END get_cupon_active_from;

  /**
  * Получить дату окончания действия скидки по скидочному купону
  * @param  addendum_id$i   - Идентификатор приложения
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  service_name$c  - Наименование купонной (скидочной) услуги для поиска
  * @param  date$d          - На какую дату смотрим
  * @return Дата окончания действия купона
  */
  FUNCTION get_cupon_active_to(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  DEFAULT NULL,
    service_name$c VARCHAR2 DEFAULT '%идка%упон%',
    date$d         IN DATE := get_current_date()
  ) RETURN DATE
  IS
    lv_res$tp t_cupon_4_service;
  BEGIN
    IF addendum_id$i IS NULL AND
       billing_id$i  IS NULL AND
       service_id$i  IS NULL
    THEN
      RETURN NULL;
    END IF;
    -- Получить значение
    lv_res$tp := get_cupon_4_service_t(addendum_id$i  => addendum_id$i,
                                       billing_id$i   => billing_id$i,
                                       service_id$i   => service_id$i,
                                       service_name$c => service_name$c,
                                       date$d         => date$d);
    RETURN lv_res$tp.discount_perc_enddate;
  END get_cupon_active_to;

/*
  FUNCTION get_cupon_4_service(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id$i   INTEGER  := NULL,
    service_name$c VARCHAR2 := '%идка%упон%'
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
    lv_cache_key$c t_cache_key;
  BEGIN
    IF addendum_id$i IS NULL AND
       billing_id$i  IS NULL AND
       service_id$i  IS NULL
    THEN
      RETURN 0;
    END IF;

    -- Получить значение из кэша
    lv_cache_key$c := 'c4s'||
                      TO_CHAR(addendum_id$i) || '&' ||
                      TO_CHAR(billing_id$i)  || '&' ||
                      TO_CHAR(service_id$i);
    lv_res$n := get_number_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$n IS NULL THEN
      -- Если задана "Скидочная" услуга
      IF service_id$i IS NOT NULL THEN
        FOR rec IN (
          SELECT TO_NUMBER(REGEXP_REPLACE(af.flag_name, '[^[[:digit:]]]*')) as cupon
          FROM plan_items_all           pi,
               activate_license_fee_all alf,
               agreement_flags_all      af,
               ( --акции для юр. лиц
                SELECT tfl.flag_id,
                       tfl.billing_id,
                       tla.activity_id
                  FROM adv_teo_link_activate_lf_all tla,
                       teo_flag_links_all          tfl
                 WHERE 1 = 1
                   AND tla.teo_flags_pk_id = tfl.teo_flags_pk_id
                   AND tla.billing_id = tfl.billing_id
               ) la
          WHERE alf.addendum_id = addendum_id$i
            AND alf.billing_id = billing_id$i
            AND alf.active_from <= current_date
            AND COALESCE(alf.active_to, current_date + 1) > current_date
            --
            AND pi.plan_item_id = alf.plan_item_id
            AND pi.billing_id = alf.billing_id
            AND pi.service_id = service_id$i
            --
            AND la.activity_id = alf.activity_id
            AND la.billing_id = alf.billing_id
            --
            AND af.flag_id = la.flag_id
            AND af.billing_id = la.billing_id)
        LOOP
          lv_res$n := rec.cupon;
          EXIT;
        END LOOP;
      END IF;
      -- Не получилось найти по сервису или он задан, то пробуем найти по наименованию купона
      IF lv_res$n IS NULL THEN
        FOR rec IN (
          SELECT TO_NUMBER(REGEXP_REPLACE(af.flag_name, '[^[[:digit:]]]*')) as cupon
          FROM services_all             se,
               plan_items_all           pi,
               activate_license_fee_all alf,
               agreement_flags_all      af,
               ( --акции для юр. лиц
                SELECT  TFL.FLAG_ID,
                        TFL.BILLING_ID,
                        TLA.ACTIVITY_ID
                  FROM adv_teo_link_activate_lf_all tla,
                       teo_flag_links_all           tfl
                 WHERE 1 = 1
                   AND tla.teo_flags_pk_id = tfl.teo_flags_pk_id
                   AND tla.billing_id = tfl.billing_id
               ) LA
          WHERE alf.addendum_id = addendum_id$i
            AND alf.billing_id = billing_id$i
            AND alf.active_from <= current_date
            AND coalesce(alf.active_to, current_date + 1) > current_date
            --
            AND pi.plan_item_id = alf.plan_item_id
            AND pi.billing_id = alf.billing_id
            --
            AND se.service_id = pi.service_id
            AND se.billing_id = pi.billing_id
            AND se.service_name like service_name$c
            --
            AND la.activity_id = alf.activity_id
            AND la.billing_id  = alf.billing_id
            --
            AND af.flag_id     = la.flag_id
            AND af.billing_id  = la.billing_id)
        LOOP
          lv_res$n := rec.cupon;
          EXIT;
        END LOOP;
      END IF;
      -- Добавить значение в КЭШ
      set_number_cache(ip_cache_key$c => lv_cache_key$c,
                       ip_value$n     => lv_res$n);
    END IF;

    RETURN lv_res$n;
  END get_cupon_4_service;
*/
  /**
  * Функция возвращает целое число из последовательности, увеличивающейся на 1 через 0,01 сек.
  * Для замера времени в процедурах и т.д. с точностью 0,01 сек используется функция DBMS_UTILITY.GET_TIME
  */
  FUNCTION get_time RETURN NUMBER
  IS
  BEGIN
    RETURN DBMS_UTILITY.GET_TIME;
  END;

  /**
  * Получить время исполнения в секундах
  * %author
  * %param  ip_start_value  Значение счетчика при старте
  * %param  ip_end_value    Значение счетчика при окончании исполнения
  * %return Время исполнения
  * Comment: Время должно определяться вызовом dbms_utility.get_time
  */
  FUNCTION get_elapsed_time(
    ip_start_value IN NUMBER,
    ip_end_value   IN NUMBER
  ) RETURN NUMBER
  IS
  BEGIN
    RETURN ROUND(MOD(NVL(ip_end_value, 0) - NVL(ip_start_value,0) + gc_big_number, gc_big_number)/100, gc_decimal_size);
  END get_elapsed_time;

  /**
  *
  */
  PROCEDURE set_num_koef_4_time_zone(ip_value IN NUMBER)
  IS
  BEGIN
    gv_num_koef_4_time_zone := nvl(ip_value, 1);
  END set_num_koef_4_time_zone;

  /**
  *
  */
  FUNCTION get_num_koef_4_time_zone RETURN NUMBER
  IS
  BEGIN
    RETURN 1/*gv_num_koef_4_time_zone*/;
  END get_num_koef_4_time_zone;

  /**
  * Получить часовой пояс города
  * @param  ip_city_id$i    - Идентификатор города
  * @param  ip_what_give$c  - Формат ответа (5 или ETC/GMT-5)
  *            значения N/C
  * @RETURN Возвращает часовой пояс в запрошенном формате
  */
  FUNCTION get_time_zone(
    ip_city_id$i   IN INTEGER,
    ip_what_give$c IN VARCHAR2 DEFAULT 'N'
  ) RETURN VARCHAR2
  IS
    lv_res$c       VARCHAR2(200);
    lv_billing_id  INTEGER := 1;
    lv_cache_key$c t_cache_key;
    lv_what_give$c VARCHAR2(1) := UPPER(ip_what_give$c);
  BEGIN
    IF ip_city_id$i IS NULL THEN
      RETURN NULL;
    END IF;
    -- Получить значение из кэша
    lv_cache_key$c := 'gtz'|| TO_CHAR(ip_city_id$i) || '&' || TO_CHAR(lv_billing_id) || '&' || ip_what_give$c;
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      FOR rec IN (SELECT value_number, value_char
                  FROM city_attributes_all ca
                  WHERE 1 = 1
                    AND ca.city_id = ip_city_id$i
                    AND ca.billing_id = lv_billing_id
                    AND ca.type_id = 5)
      LOOP
        IF lv_what_give$c = 'N' THEN
          lv_res$c := /*CASE
                        WHEN rec.value_number > 0 THEN '+'
                        WHEN rec.value_number < 0 THEN '-'
                        ELSE ''
                      END ||*/ TO_CHAR(rec.value_number*get_num_koef_4_time_zone());
        ELSE
          lv_res$c := UPPER(rec.value_char);
        END IF;
        EXIT;
      END LOOP;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_time_zone;

  /**
  * Очистить заданную таблицу (TRUNCATE)
  *   Использовать осторожно. По-моему делает COMMIT в сессии
  * @param  ip_table_name$c - Имя таблицу
  */
  PROCEDURE truncate_table(ip_table_name$c IN VARCHAR2)
  IS
    --lv_check$i INTEGER;
  BEGIN
    --SELECT COUNT(1) INTO lv_check$i FROM all_tables
    EXECUTE IMMEDIATE 'TRUNCATE TABLE '||ip_table_name$c;
  END truncate_table;

  /**
  * Получить даты действия сервиса на конкретную дату и поместить результат в кэш
  * @param service_id$i   - Идентификатор услуги
  * @param addendum_id$i  - Идентификатор приложения
  * @param billing_id$i   - Идентификатор биллинга
  * @param ip_what        - Какую дату дать?
  *                         0/1 - ACTIVE_FROM/ACTIVE_TO
  * @param ip_date$d      - На какую дату
  * @return запрошенная дата
  */
  FUNCTION get_service_dates_2_cache(
    service_id$i   IN INTEGER,
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    ip_what        IN INTEGER,
    ip_date$d      IN DATE := get_current_date()
  ) RETURN DATE
  IS
    lv_date_from$d DATE;
    lv_date_to$d   DATE;
    lv_res$d       DATE;
    lv_cache_key$c t_cache_key;
    lv_curr_date$d DATE := get_current_date();
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := CASE WHEN ip_what = 0 THEN 'saf' ELSE 'sat' END ||
                      TO_CHAR(service_id$i) ||'&'||
                      TO_CHAR(addendum_id$i)||'&'||
                      TO_CHAR(billing_id$i) ||'&'||
                      TO_CHAR(ip_date$d,'dd.mm.yyyy');
    lv_res$d := get_date_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$d IS NULL THEN
      -- Если дата не задана найдем самые последние данные
      IF ip_date$d IS NULL THEN
          -- active_from
          SELECT MAX(alf.active_from)
            INTO lv_date_from$d
          FROM plan_items_all pi,
               activate_license_fee_all alf
          WHERE alf.addendum_id = addendum_id$i
            AND alf.billing_id = billing_id$i
            AND alf.active_from <= lv_curr_date$d -- Подумать!!!
            AND pi.plan_item_id = alf.plan_item_id
            AND pi.billing_id = alf.billing_id
            AND pi.service_id = service_id$i;
          -- active_to
          IF lv_date_from$d IS NOT NULL THEN
            FOR rec IN (
              SELECT active_to
              FROM plan_items_all pi,
                   activate_license_fee_all alf
              WHERE alf.addendum_id = addendum_id$i
                AND alf.billing_id = billing_id$i
                AND alf.active_from = lv_date_from$d
                AND pi.plan_item_id = alf.plan_item_id
                AND pi.billing_id = alf.billing_id
                AND pi.service_id = service_id$i
              ORDER BY active_to DESC NULLS FIRST
            ) LOOP
              lv_date_to$d := rec.active_to;
              EXIT;
            END LOOP;
          END IF;
      ELSE
        FOR rec IN (
          SELECT alf.active_from, alf.active_to
          FROM plan_items_all pi,
               activate_license_fee_all alf
          WHERE alf.addendum_id = addendum_id$i
            AND alf.billing_id = billing_id$i
            AND alf.active_from <= ip_date$d
            AND (alf.active_to IS NULL OR alf.active_to > ip_date$d)
            AND pi.plan_item_id = alf.plan_item_id
            AND pi.billing_id = alf.billing_id
            AND pi.service_id = service_id$i
          ORDER BY alf.active_from--, alf.active_to
        ) LOOP
          lv_date_from$d := rec.active_from;
          lv_date_to$d := rec.active_to;
        END LOOP;
      END IF;
      -- Закинем в кеш
      lv_cache_key$c := 'saf'||TO_CHAR(service_id$i)||'&'||TO_CHAR(addendum_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(ip_date$d,'dd.mm.yyyy');
      set_date_cache(ip_cache_key$c => lv_cache_key$c, ip_value$d=> lv_date_from$d);
      lv_cache_key$c := 'sat'||TO_CHAR(service_id$i)||'&'||TO_CHAR(addendum_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(ip_date$d,'dd.mm.yyyy');
      set_date_cache(ip_cache_key$c => lv_cache_key$c, ip_value$d=> lv_date_to$d);
      -- Подготовим ответ
      IF ip_what = 0 THEN
        lv_res$d := lv_date_from$d;
      ELSE
        lv_res$d := lv_date_to$d;
      END IF;
    END IF;
    RETURN lv_res$d;
  END get_service_dates_2_cache;

  /**
  * Услуга активна с ..
  * @param service_id$i   - Идентификатор услуги
  * @param addendum_id$i  - Идентификатор приложения
  * @param billing_id$i   - Идентификатор биллинга
  * @param ip_date$d      - На какую дату
  * @RETURN Услуга активна с ..
  */
  FUNCTION get_service_active_from(
    service_id$i   IN INTEGER,
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    ip_date$d      IN DATE := get_current_date()
  ) RETURN DATE
  IS
  BEGIN
    RETURN get_service_dates_2_cache(service_id$i  => service_id$i,
                                     addendum_id$i => addendum_id$i,
                                     billing_id$i  => billing_id$i,
                                     ip_what       => 0,
                                     ip_date$d     => ip_date$d);
  END get_service_active_from;

  /**
  * Услуга активна до ..
  * @param service_id$i   - Идентификатор услуги
  * @param addendum_id$i  - Идентификатор приложения
  * @param billing_id$i   - Идентификатор биллинга
  * @param ip_date$d      - На какую дату запрос
  * @RETURN Услуга активна до ..
  */
  FUNCTION get_service_active_to(
    service_id$i   IN INTEGER,
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    ip_date$d      IN DATE := get_current_date()
  ) RETURN DATE
  IS
  BEGIN
    RETURN get_service_dates_2_cache(service_id$i  => service_id$i,
                                     addendum_id$i => addendum_id$i,
                                     billing_id$i  => billing_id$i,
                                     ip_what       => 1,
                                     ip_date$d     => ip_date$d);
  END get_service_active_to;

  /**
  * Была ли активна услуга в запрошенном интервале времени
  * @param service_id$i   - Идентификатор услуги
  * @param addendum_id$i  - Идентификатор приложения
  * @param billing_id$i   - Идентификатор биллинга
  * @param ip_date_from$d - Дата от ...
  * @param ip_date_to$d   - Дата до ...
  * @RETURN Флаг активности услуги в запрошенном интервале времени
  *         0/1 - Нет/Да
  */
  FUNCTION is_active_service_in_month(
    service_id$i   IN INTEGER,
    addendum_id$i  IN INTEGER,
    billing_id$i   IN INTEGER,
    ip_date_from$d IN DATE := get_current_date(),
    ip_date_to$d   IN DATE := get_current_date()
  ) RETURN INTEGER
  IS
    lv_res$i INTEGER;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'iasim' ||
                      TO_CHAR(service_id$i) ||'&'||
                      TO_CHAR(addendum_id$i)||'&'||
                      TO_CHAR(billing_id$i) ||'&'||
                      TO_CHAR(ip_date_from$d,'dd.mm.yyyy') ||'&'||
                      TO_CHAR(ip_date_to$d,'dd.mm.yyyy');
    lv_res$i := get_number_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$i IS NULL THEN
      SELECT COUNT(1) INTO lv_res$i
      FROM plan_items_all pi,
           activate_license_fee_all alf
      WHERE alf.addendum_id = addendum_id$i
        AND alf.billing_id = billing_id$i
        AND alf.active_from <= ip_date_to$d
        AND (alf.active_to IS NULL OR alf.active_to > ip_date_from$d)
        AND pi.plan_item_id = alf.plan_item_id
        AND pi.billing_id = alf.billing_id
        AND pi.service_id = service_id$i;
      lv_res$i := LEAST(1,lv_res$i);
      set_number_cache(ip_cache_key$c => lv_cache_key$c, ip_value$n => lv_res$i);
    END IF;
    RETURN lv_res$i;
  END is_active_service_in_month;

  /**
  * Получить стыковочный IP-Адрес
  * @param  addendum_id$i  - Идентификатор приложения
  * @param  billing_id$i   - Идентификатор биллинга
  * @return IDB_PH2_IP_V6RANGE.IDB_ID/IDB_PH2_IP_V4RANGE.IDB_ID
  */
  FUNCTION get_linked_subnets(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN VARCHAR2
  IS
    lv_res$c VARCHAR2(200);
  BEGIN
    FOR rec IN (
      SELECT CASE
               WHEN sn.ip_v6 IS NOT NULL THEN 'V6RP/' || to_char(billing_id$i) || '/' || sn.ip_v6 || '/'|| sn.netmask
               ELSE ip_number_to_char(sn.ip_v4)
             END AS idb_id
      FROM cable_city_ip_subnets_all sn,
           resource_contents_all rc,
           addendum_resources_all ar
      WHERE 1=1
        AND ar.addendum_id = addendum_id$i
        AND ar.billing_id = billing_id$i
        --
        AND ar.active_from <= nvl(rc.active_to, ar.active_from + 1)
        AND nvl(ar.active_to, rc.active_from + 1) > rc.active_from
        --
        AND ar.resource_id=rc.resource_id
        AND ar.billing_id=rc.billing_id
        --
        AND rc.terminal_resource_id=sn.terminal_resource_id
        AND rc.billing_id = sn.billing_id
        -- Убрать
        AND sn.ip_v6 IS NOT NULL
    )
    LOOP
      lv_res$c := rec.idb_id;
    END LOOP;
    RETURN lv_res$c;
  END get_linked_subnets;

  /**
  * Получить даты действия подсети и поместить результат в кэш
  * @param addendum_id$i           - Идентификатор приложения
  * @param terminal_resource_id$i  - Идентификатор терминального ресурса "Подсеть"
  * @param billing_id$i            - Идентификатор биллинга
  * @param ip_what                 - Какую дату дать?
  *                                  0/1 - ACTIVE_FROM/ACTIVE_TO
  * @param ip_date$d               - На какую дату
  * @return запрошенная дата
  */
  FUNCTION get_subnet_dates_2_cache(
    addendum_id$i          IN INTEGER := NULL,
    terminal_resource_id$i IN INTEGER,
    billing_id$i           IN INTEGER,
    ip_what                IN INTEGER,
    ip_date$d              IN DATE := get_current_date()
  ) RETURN DATE
  IS
    lv_date_from$d DATE;
    lv_date_to$d   DATE;
    lv_res$d       DATE;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := CASE WHEN ip_what = 0 THEN 'subaf' ELSE 'subat' END ||
                      TO_CHAR(addendum_id$i)||'&'||
                      TO_CHAR(terminal_resource_id$i)||'&'||
                      TO_CHAR(billing_id$i) ||'&'||
                      TO_CHAR(ip_date$d,'dd.mm.yyyy');
    lv_res$d := get_date_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$d IS NULL THEN
      IF addendum_id$i IS NULL THEN
        FOR rec IN (
          SELECT rc.active_from, rc.active_to
          FROM cable_city_ip_subnets_all sn,
               resource_contents_all rc
          WHERE 1=1
            AND sn.terminal_resource_id = terminal_resource_id$i
            AND sn.billing_id = billing_id$i
            AND rc.terminal_resource_id=sn.terminal_resource_id
            AND rc.billing_id = sn.billing_id
            AND rc.active_from <= ip_date$d
            AND (rc.active_to IS NULL OR rc.active_to > ip_date$d)
            --
        ) LOOP
          lv_date_from$d := rec.active_from;
          lv_date_to$d := rec.active_to;
        END LOOP;
      ELSIF terminal_resource_id$i IS NULL THEN
        FOR rec IN (
          SELECT rc.active_from, rc.active_to
          FROM cable_city_ip_subnets_all sn,
               resource_contents_all rc,
               addendum_resources_all ar
          WHERE 1=1
            AND ar.addendum_id = addendum_id$i
            AND ar.billing_id = billing_id$i
            AND ar.active_from <= ip_date$d
            AND (ar.active_to IS NULL OR ar.active_to > ip_date$d)
            --
            --AND ar.active_from <= nvl(rc.active_to, ar.active_from + 1)
            --AND nvl(ar.active_to, rc.active_from + 1) > rc.active_from
            --
            AND rc.resource_id = ar.resource_id
            AND rc.billing_id = ar.billing_id
            AND rc.active_from <= ip_date$d
            AND (rc.active_to IS NULL OR rc.active_to > ip_date$d)
            --
            AND rc.terminal_resource_id=sn.terminal_resource_id
            AND rc.billing_id = sn.billing_id
          ORDER BY rc.active_from DESC--, rc.active_to
        ) LOOP
          lv_date_from$d := rec.active_from;
          lv_date_to$d := rec.active_to;
          EXIT;
        END LOOP;
      ELSE
        FOR rec IN (
          SELECT rc.active_from, rc.active_to
          FROM cable_city_ip_subnets_all sn,
               resource_contents_all rc,
               addendum_resources_all ar
          WHERE 1=1
            AND ar.addendum_id = addendum_id$i
            AND ar.billing_id = billing_id$i
            AND ar.active_from <= ip_date$d
            AND (ar.active_to IS NULL OR ar.active_to > ip_date$d)
            --
            --AND ar.active_from <= nvl(rc.active_to, ar.active_from + 1)
            --AND nvl(ar.active_to, rc.active_from + 1) > rc.active_from
            --
            AND rc.resource_id = ar.resource_id
            AND rc.billing_id = ar.billing_id
            AND rc.active_from <= ip_date$d
            AND (rc.active_to IS NULL OR rc.active_to > ip_date$d)
            --
            AND rc.terminal_resource_id=sn.terminal_resource_id
            AND rc.billing_id = sn.billing_id
            AND sn.terminal_resource_id = terminal_resource_id$i
        ) LOOP
          lv_date_from$d := rec.active_from;
          lv_date_to$d := rec.active_to;
        END LOOP;
      END IF;
      -- Закинем в кеш
      lv_cache_key$c := 'subaf' || TO_CHAR(addendum_id$i)||'&'||TO_CHAR(terminal_resource_id$i)||'&'||TO_CHAR(billing_id$i) ||'&'||TO_CHAR(ip_date$d,'dd.mm.yyyy');
      set_date_cache(ip_cache_key$c => lv_cache_key$c, ip_value$d=> lv_date_from$d);
      lv_cache_key$c := 'subat' || TO_CHAR(addendum_id$i)||'&'||TO_CHAR(terminal_resource_id$i)||'&'||TO_CHAR(billing_id$i) ||'&'||TO_CHAR(ip_date$d,'dd.mm.yyyy');
      set_date_cache(ip_cache_key$c => lv_cache_key$c, ip_value$d=> lv_date_to$d);
      -- Подготовим ответ
      IF ip_what = 0 THEN
        lv_res$d := lv_date_from$d;
      ELSE
        lv_res$d := lv_date_to$d;
      END IF;
    END IF;
    RETURN lv_res$d;
  END get_subnet_dates_2_cache;

  /**
  * Подсеть активна с ..
  * @param addendum_id$i          - Идентификатор приложения
  * @param terminal_resource_id$i - Идентификатор терминального ресурса "Подсеть"
  * @param billing_id$i           - Идентификатор биллинга
  * @param ip_date$d              - На какую дату
  * @RETURN Подсеть активна с ..
  */
  FUNCTION get_subnets_active_from(
    addendum_id$i          IN INTEGER := NULL,
    terminal_resource_id$i IN INTEGER,
    billing_id$i           IN INTEGER,
    ip_date$d              IN DATE := get_current_date()
  ) RETURN DATE
  IS
  BEGIN
    RETURN get_subnet_dates_2_cache(addendum_id$i => addendum_id$i,
                                    terminal_resource_id$i => terminal_resource_id$i,
                                    billing_id$i  => billing_id$i,
                                    ip_what       => 0,
                                    ip_date$d     => ip_date$d);
  END get_subnets_active_from;

  /**
  * Подсеть активна до ..
  * @param addendum_id$i          - Идентификатор приложения
  * @param terminal_resource_id$i - Идентификатор терминального ресурса "Подсеть"
  * @param billing_id$i           - Идентификатор биллинга
  * @param ip_date$d              - На какую дату
  * @RETURN Подсеть активна до ..
  */
  FUNCTION get_subnets_active_to(
    addendum_id$i          IN INTEGER := NULL,
    terminal_resource_id$i IN INTEGER,
    billing_id$i           IN INTEGER,
    ip_date$d              IN DATE := get_current_date()
  ) RETURN DATE
  IS
  BEGIN
    RETURN get_subnet_dates_2_cache(addendum_id$i => addendum_id$i,
                                    terminal_resource_id$i => terminal_resource_id$i,
                                    billing_id$i  => billing_id$i,
                                    ip_what       => 1,
                                    ip_date$d     => ip_date$d);
  END get_subnets_active_to;

  /**
  * Получить наименование типа авторизации
  * @param  addendum_id$i    - Идентификатор приложения
  * @param  billing_id$i     - Идентификатор биллинга
  * @param  plan_group_id$i  - Идентификатор группы планов
  * @param  ip_date$d        - На какую дату смотрим
  * @param  ip_is_convert$i  - Признак преобразования типов подключения
  *                            1/0 - Преобразуем/Не преобразуем
  * @return Наименование типа авторизации
  */
  FUNCTION get_auth_type(
    addendum_id$i   IN INTEGER,
    billing_id$i    IN INTEGER,
    plan_group_id$i IN INTEGER DEFAULT NULL,
    ip_date$d       IN DATE DEFAULT get_current_date(),
    ip_is_convert$i IN INTEGER DEFAULT 1
  ) RETURN VARCHAR2
  IS
    lv_plan_group_id$i INTEGER := plan_group_id$i;
    lv_con_type_name$c VARCHAR2(100);
    --lv_net_name$c VARCHAR2(100);
    lv_con_type_id$    INTEGER;
    /*Типы подключения*/
    lc_ct_pppoe$i constant integer := 0;
    lc_ct_ipoe$i constant integer := 1;
    lc_ct_izet_mac_vlan$i constant integer := 2;
    lc_ct_dhcp_mac_vlan$i constant integer := 3;
    lc_ct_dhcp_82$i constant integer := 4;
    lc_ct_l2tp$i constant integer := 5;
    lc_ct_pptp$i constant integer := 6;
    --IPoE тарифы
    lc_pg_ipoe$i constant integer:=77;
  BEGIN
    BEGIN
      -- сначала проверим по плангруппе для ipoe
      IF lv_plan_group_id$i IS NULL THEN
        SELECT pl.plan_group_id
        INTO lv_plan_group_id$i
        FROM plans_all pl, addenda_all ad
        WHERE ad.addendum_id = addendum_id$i
          AND ad.billing_id = billing_id$i
          AND pl.plan_id = ad.plan_id
          AND pl.billing_id = ad.billing_id;
      END IF;
      IF lv_plan_group_id$i = lc_pg_ipoe$i THEN
        lv_con_type_id$ := lc_ct_ipoe$i;
      END IF;
      -- Если не ipoe, то найдем по таблице типов подключений для приложения
      IF lv_con_type_id$ IS NULL THEN
        SELECT con_type_id
        INTO lv_con_type_id$
        FROM addendum_company_links_all
        WHERE addendum_id=addendum_id$i
          AND billing_id = billing_id$i
          AND active_from <= ip_date$d
          AND (active_to IS NULL OR active_to > ip_date$d);
      END IF;
      -- По идентификатору найдем имя
      SELECT con_type_name
      INTO lv_con_type_name$c
      FROM cable_city_con_types_all
      WHERE con_type_id=lv_con_type_id$
        AND billing_id = billing_id$i;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_con_type_name$c := NULL;
    END;
    -- Если не определено, ставим PPPoE
    IF lv_con_type_name$c IS NULL THEN
      lv_con_type_name$c := 'PPPoE';
    END IF;
    -- Если надо, то преобразуем
    IF ip_is_convert$i = 1 AND lv_con_type_name$c <> 'PPPoE' THEN
      IF lv_con_type_name$c IN ('IPoE dom.ru') THEN
        lv_con_type_name$c :=  'IPoE';
      ELSIF lv_con_type_name$c in ('DHCP mac vlan', 'DHCP опция 82', 'L2TP') THEN
        lv_con_type_name$c :=  'PPPoE';
      END IF;
    END IF;
    --A.Kosterin 22.09.2021 add IF interzet
    /*IF
      billing_id$i = 556 THEN
      select decode(rias_mgr_support.get_network(addendum_id$i => addendum_id$i, billing_id$i => billing_id$i), 'InterZet',1, 0) into lv_net_name$c from dual;
           IF
                  lv_net_name$c = 1 THEN lv_con_type_name$c :=  'IPoE';      
           END IF;
    END IF;*/

    RETURN lv_con_type_name$c;
  END get_auth_type;

  /**
  * Получить наименование типа авторизации для обработки в IDB_PH2_NET_ACCESS
  * Изпользует функцию get_auth_type без преобразования
  * @param  addendum_id$i    - Идентификатор приложения
  * @param  billing_id$i     - Идентификатор биллинга
  * @param  ip_date$d        - На какую дату смотрим
  * @return Наименование типа авторизации
  */
  FUNCTION get_auth_type_4_net_access(
    addendum_id$i   IN INTEGER,
    billing_id$i    IN INTEGER,
    ip_date$d       IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
    lv_cnt$i       PLS_INTEGER;
    lv_cnt_ip$i    PLS_INTEGER;
    lv_net_name$c VARCHAR2(100);
    get_interzet_ex EXCEPTION;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'atna'||TO_CHAR(addendum_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(ip_date$d,'dd.mm.yyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      lv_res$c := get_auth_type(addendum_id$i   => addendum_id$i,
                                billing_id$i    => billing_id$i,
                                ip_date$d       => ip_date$d,
                                ip_is_convert$i => 0);
      -- Проверим привязку к логину
      SELECT COUNT(1) INTO lv_cnt$i
      FROM addendum_resources_all ar,
           resource_contents_all  rc,
           logins_all             i
      WHERE 1 = 1
        AND ar.addendum_id = to_number(addendum_id$i)
        AND ar.billing_id = to_number(billing_id$i)
        AND ar.active_from <= ip_date$d
        AND (ar.active_to IS NULL OR ar.active_to > ip_date$d)
        AND rc.resource_id = ar.resource_id
        AND rc.billing_id = ar.billing_id
        AND rc.active_from <= ip_date$d
        AND (rc.active_to IS NULL OR rc.active_to > ip_date$d)
        AND i.terminal_resource_id = rc.terminal_resource_id
        AND i.billing_id = rc.billing_id
        AND rownum <= 1;
      -- Проверим привязку к IP
      SELECT COUNT(1) INTO lv_cnt_ip$i
      FROM addendum_resources_all ar,
           resource_contents_all  rc,
           ip_for_dedicated_clients_all i
      WHERE 1 = 1
        AND ar.addendum_id = to_number(addendum_id$i)
        AND ar.billing_id = to_number(billing_id$i)
        AND ar.active_from <= ip_date$d
        AND (ar.active_to IS NULL OR ar.active_to > ip_date$d)
        AND rc.resource_id = ar.resource_id
        AND rc.billing_id = ar.billing_id
        AND rc.active_from <= ip_date$d
        AND (rc.active_to IS NULL OR rc.active_to > ip_date$d)
        AND i.terminal_resource_id = rc.terminal_resource_id
        AND i.billing_id = rc.billing_id
        AND rownum <= 1;
      -- В зависимости от проверок...
      IF lv_cnt$i > 0 AND lv_cnt_ip$i > 0 THEN
        lv_res$c :=
          CASE
            WHEN lv_res$c = 'DHCP mac vlan' THEN 'DHCP Opt. 82 + Static IP'
            WHEN lv_res$c = 'L2TP' THEN 'L2TP'
            WHEN lv_res$c = 'PPPoE' THEN 'PPPoE Static IP (РИАС)'
            WHEN lv_res$c = 'DHCP опция 82' THEN 'DHCP Opt. 82 Dynamic'
            WHEN lv_res$c = 'IPoE dom.ru' THEN 'IPoE Дом.ру (РИАС)'
          END;
      ELSE
        lv_res$c :=
          CASE
            WHEN lv_res$c = 'DHCP mac vlan' THEN 'DHCP Opt. 82 Dynamic'
            WHEN lv_res$c = 'L2TP' THEN 'L2TP'
            WHEN lv_res$c = 'PPPoE' THEN 'PPPoE Dynamic IP (РИАС)'
            WHEN lv_res$c = 'DHCP опция 82' THEN 'DHCP Opt. 82 Dynamic'
            WHEN lv_res$c = 'IPoE dom.ru' THEN 'IPoE Дом.ру (РИАС)'
          END;
      END IF;
      -- A.Kosterin 22.09.2021 add Interzet 26.10.2021 add aak_test_get_interzet
      /*IF
      billing_id$i = 556 THEN
      select decode(rias_mgr_support.get_network(addendum_id$i => addendum_id$i, billing_id$i => billing_id$i), 'InterZet',1, 0) into lv_net_name$c from dual;
           IF
             lv_net_name$c = 1 THEN 
             --begin
             --lv_res$c :=  'IPoE Дом.ру (РИАС)';
             SELECT IDB_PROD.aak_test_get_interzet(addendum_id$i => addendum_id$i) into lv_res$c from dual;
             /*exception
             when get_interzet_ex then
             --raise_application_error(-20000, 'get_interzet_err:'||addendum_id$i);
             INSERT INTO info_log VALUES ('get_interzet_err:'||addendum_id$i);
             end;*/
             --SELECT IDB_PROD.aak_test_get_interzet(addendum_id$i => addendum_id$i) into lv_res$c from dual;      
          /* END IF;
      END IF;*/
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_auth_type_4_net_access;

  /**
  * Получить NAT для обработки в IDB_PH2_NET_ACCESS
  * @param  addendum_id$i    - Идентификатор приложения
  * @param  billing_id$i     - Идентификатор биллинга
  * @terminal_resource_id$i  - Идентификатор терминального ресурса логина
  * @param  ip_date$d        - На какую дату смотрим
  * @return NAT
  */
  FUNCTION get_nat(
    addendum_id$i          IN INTEGER,
    billing_id$i           IN INTEGER,
    terminal_resource_id$i IN INTEGER DEFAULT NULL,
    ip_date$d              IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2
  IS
    lc_nat_prop_id CONSTANT INTEGER := 16;
    lv_res$c VARCHAR2(300);
  BEGIN
    SELECT NVL(MAX(lp.prop_value), '0')
    INTO lv_res$c
    FROM addendum_resources_all        ar,
         resource_contents_all         rc,
         logins_all                    la,
         cable_city_term_res_props_all lp
    WHERE 1=1
      AND ar.addendum_id = addendum_id$i
      AND ar.billing_id =billing_id$i
      AND ar.active_from <= ip_date$d
      AND (ar.active_to IS NULL OR ar.active_to > ip_date$d)
      AND rc.resource_id = ar.resource_id
      AND rc.billing_id = ar.billing_id
      AND rc.active_from <= ip_date$d
      AND (rc.active_to IS NULL OR rc.active_to > ip_date$d)
      AND rc.terminal_resource_id = la.terminal_resource_id
      AND rc.billing_id = la.billing_id
      AND lp.terminal_resource_id = la.terminal_resource_id
      AND lp.billing_id = la.billing_id
      AND lp.prop_id = lc_nat_prop_id
      AND lp.active_from <= ip_date$d
      AND (lp.active_to IS NULL OR lp.active_to > ip_date$d)
      AND (terminal_resource_id$i IS NULL OR lp.terminal_resource_id = terminal_resource_id$i);
    lv_res$c := CASE WHEN lv_res$c = '1' THEN 'Да' ELSE 'Нет' END;
    RETURN lv_res$c;
  END get_nat;

  /**
  * Проверить необходимость выгрузки поля
  * @param  table_name$c      - Наименование таблицы
  * @param  column_name$c     - Наименование столбца
  * @param  off_id_for_migr$c - Оффер
  * @return 1/0/-1 - Выгружать/Не выгружать/Не работает
  */
  FUNCTION is_unload_field(
    table_name$c      IN VARCHAR2,
    column_name$c     IN VARCHAR2,
    off_id_for_migr$c IN VARCHAR2
  ) RETURN INTEGER
  IS
    lv_res$i       INTEGER;
    lv_cache_key$c t_cache_key;
    lv_cnt$i       PLS_INTEGER;
    lv_tmp$c       VARCHAR2(50);
    lv_table_name$c      VARCHAR2(50) := UPPER(TRIM(table_name$c));
    lv_column_name$c     VARCHAR2(50) := UPPER(TRIM(column_name$c));
    lv_off_id_for_migr$c VARCHAR2(50) := UPPER(TRIM(off_id_for_migr$c));

    /**
    * Исключения из правил
    */
    FUNCTION get_exceptions_rules(
      table_name$c      IN VARCHAR2,
      column_name$c     IN VARCHAR2,
      off_id_for_migr$c IN VARCHAR2
    ) RETURN INTEGER
    IS
      lv_res INTEGER := NULL;
    BEGIN
      IF table_name$c = 'IDB_PH2_SBPI_INT' THEN
        IF column_name$c = 'BILLED_TO_DAT' AND
           -- Одноразовые услуги
           off_id_for_migr$c IN ('111000213', '201000098', '201000045', '121000809', '201000106', '201000256', '121000803',
                                 '201000214', '121000801', '201000112', '201000259', '121000807', '201000115', '201000109',
                                 '201000250', '201000103', '121000805', '201000247', '121000020', '201000253', '111000224')
        THEN
          lv_res := 0;
        -- Письмо от Марины Чт 02.07.2020 17:45 в папке SLO
        ELSIF column_name$c = 'MRC_CUPON' AND
              off_id_for_migr$c IN ('121000020', '121000809', '121000805', '121000803', '121000807', '121000801', '121000117')
        THEN
          lv_res := 0;
        END IF;
      END IF;
      RETURN lv_res;
    END get_exceptions_rules;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'isunfld:'||lv_table_name$c||'&'||lv_column_name$c||'&'||lv_off_id_for_migr$c;
    lv_res$i := get_number_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$i IS NULL THEN
      -- Проверим исключения из правил
      lv_res$i := get_exceptions_rules(table_name$c      => lv_table_name$c,
                                       column_name$c     => lv_column_name$c,
                                       off_id_for_migr$c => lv_off_id_for_migr$c);
      -- Если исключения не описаны, идем по стандартному алгоритму
      IF (lv_res$i IS NULL) THEN
        BEGIN
          SELECT t.mandatory
          INTO lv_tmp$c
          FROM rias_mgr_field_mandatory t
          WHERE t.table_name = lv_table_name$c
            AND t.field_name = lv_column_name$c;
        EXCEPTION
          WHEN no_data_found THEN
            RAISE_APPLICATION_ERROR(-20001, 'Необходимо обновить справочник RIAS_MGR_FIELD_MANDATORY');
        END;
        --
        IF UPPER(TRIM(lv_tmp$c)) = 'D' THEN
          BEGIN
            -- Получим "запрет" к выгрузке к запрошенным вх.параметрам
            EXECUTE IMMEDIATE
              'SELECT VALUE_NNL_MAJORITY' || chr(10)||chr(13)||
              'FROM' || chr(10)||chr(13)||
              '  IDB_PH2_OFFERS_CHR_INV_DIC chr_dic' || chr(10)||chr(13)||
              'WHERE 1=1' || chr(10)||chr(13)||
              '  AND chr_dic.IDB_TABLE_NAME = :table_name' || chr(10)||chr(13)||
              '  AND chr_dic.IDB_COLUMN_NAME = :column_name' || chr(10)||chr(13)||
              '  AND chr_dic.OFF_ID_FOR_MIGR = :off_id_for_migr'
              -- || chr(10)||chr(13)|| '  AND chr_dic.VALUE_NNL_MAJORITY != ''Major'''
            INTO lv_tmp$c
            USING IN lv_table_name$c,
                  IN lv_column_name$c,
                  IN lv_off_id_for_migr$c;
            IF lv_tmp$c = 'Major' THEN
              lv_res$i := 1;
            ELSIF lv_tmp$c = 'No validation' THEN --??????????
              lv_res$i := 1;
            ELSE
              lv_res$i := 0;
            END IF;
          EXCEPTION
            -- Поле не найдено
            WHEN NO_DATA_FOUND THEN
              lv_res$i := 0;
            -- Проблемы со справочником..
            WHEN OTHERS THEN
              lv_res$i := -1;
          END;
        ELSE
          lv_res$i := 1;
        END IF;
      END IF;
      -- Добавить значение в КЭШ
      set_number_cache(ip_cache_key$c => lv_cache_key$c, ip_value$n => lv_res$i);
    END IF;
    RETURN lv_res$i;
  END is_unload_field;

  /**
  * Получить префикс для оффера
  * Формирование поля SERVICE_ID
  * @param  table_name$c      - Наименование таблицы
  * @param  off_id_for_migr$c - Оффер
  * @return Префикс
  */
  FUNCTION get_prefix4offer(
    table_name$c      IN VARCHAR2,
    off_id_for_migr$c IN VARCHAR2
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'prfxoffer:'||off_id_for_migr$c;
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      BEGIN
        EXECUTE IMMEDIATE
          'SELECT d.prefix' || chr(10)||chr(13)||
          'FROM IDB_PH2_OFFERINGS_DIC d' || chr(10)||chr(13)||
          'WHERE d.idb_table_name = :table_name'|| chr(10)||chr(13)||
          '  AND d.off_id_for_migr = :off_id_for_migr'
        INTO lv_res$c
        USING UPPER(TRIM(table_name$c)), UPPER(TRIM(off_id_for_migr$c));
      EXCEPTION
        -- Проблемы со справочником..
        WHEN OTHERS THEN
          lv_res$c := 'NO_FOUND';
      END;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_prefix4offer;

  /**
  * Получить МКУ
  * @param  house_id$i   - Идентификатор дома
  * @param  billing_id$i - Идентификатор биллинга
  * @param  date$d       - На какую дату смотрим
  * @return МКУ
  */
  FUNCTION get_mku(
    house_id$i   IN INTEGER,
    billing_id$i IN INTEGER,
    date$d       IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2
  IS
    lv_res$c VARCHAR2(500);
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'mku'||TO_CHAR(house_id$i)||'&'||TO_CHAR(billing_id$i)||'&'||TO_CHAR(date$d,'dd.mm.yyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      SELECT listagg(company_name, '; ') WITHIN GROUP(ORDER BY NULL) INTO lv_res$c
      FROM (SELECT (SELECT nvl(itn.network_alias, 'ГУТС') || ' ' ||
                           c.campus_number
                      FROM geo_attr_link_campuse_all alc,
                           geo_attributes_types_all  gat,
                           itg_networks_all          itn
                     WHERE gat.geo_attributes_type_id = alc.geo_attributes_type_id
                       AND gat.billing_id = alc.billing_id
                       AND itn.network_id(+) = gat.company_id
                       AND itn.billing_id(+) = 0 --gat.billing_id
                       AND gat.class_id + 0 = 1 --house_attrs_consts.c_hac_ma_campus_id$i
                       AND alc.campus_id = hlc.campus_id
                       AND alc.billing_id = hlc.billing_id) AS company_name
              FROM geo_houses_link_campuses_all hlc,
                   campuses_all                 c
             WHERE hlc.campus_id = c.campus_id
               AND hlc.billing_id = c.billing_id
               AND hlc.house_id = house_id$i
               AND hlc.billing_id = billing_id$i
               AND hlc.active_from <= date$d
               AND (hlc.active_to IS NULL OR hlc.active_to > date$d)
             ORDER BY hlc.priority);
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END;

  /**
  * Получить значение константы из c_data
  * @param  ip_obj_id$i  - Идентификатор константы
  * @param  billing_id$i - Идентификатор биллинга
  * @param  ip_date$d    - На какую дату смотрим
  */
  FUNCTION get_const(
    ip_obj_id$i     IN INTEGER,
    ip_billing_id$i IN INTEGER,
    ip_date$d    IN DATE := get_current_date()
  ) RETURN VARCHAR2
  IS
    the_date$d    DATE := nvl(ip_date$d, get_current_date());
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'gcd'||TO_CHAR(ip_obj_id$i)||TO_CHAR(ip_billing_id$i)||TO_CHAR(the_date$d,'dd.mm.yyyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      BEGIN
        SELECT c_data
          INTO lv_res$c
          FROM c_data_all
         WHERE city_id = ip_billing_id$i
           AND billing_id = ip_billing_id$i
           AND c_obj_id = ip_obj_id$i
           AND active_from <= the_date$d
           AND (active_to IS NULL OR active_to > the_date$d);
      EXCEPTION
        WHEN no_data_found THEN
          lv_res$c := NULL;
      END;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_const;

  /**
  * Возвращает кол-во месяцев гарантии для определенного оборудования
  * @param  attr_entity_id$i - Идентификатор оборудования
  * @param  billing_id$i     - Идентификатор биллинга
  * @param  insert_date$d    - Дата установки оборудования
  */
  FUNCTION get_count_warranty_months(
    attr_entity_id$i IN INTEGER,
    billing_id$i     IN INTEGER,
    insert_date$d    IN DATE
  ) RETURN INTEGER
  IS
    cur_warranty_months$i INTEGER := NULL;
  BEGIN
    -- Так как в таблице warranty_periods храниться только один из нескольких attr_entity_id которые есть у оборудования
    -- То через пришедший attr_entity_id получим код оборудования и сопоставим все attr_entity_id которые есть у этого оборудвания с теми
    -- что указаны в  warranty_periods если получится более одной записи, то будем использовать максимальную гарантию.
    SELECT MAX(w.warranty_months)
      INTO cur_warranty_months$i
      FROM warranty_periods_all w,
           materials_all m
     WHERE m.unitized_code =
           (SELECT ma.unitized_code
              FROM materials_all ma
             WHERE ma.attr_entity_id = attr_entity_id$i
               AND ma.billing_id = billing_id$i)
       AND m.billing_id = billing_id$i
       AND w.attr_entity_id = m.attr_entity_id
       AND w.billing_id = m.billing_id
       AND w.set_date = (SELECT MAX(wp.set_date)
                           FROM warranty_periods_all wp
                          WHERE wp.attr_entity_id = w.attr_entity_id
                            AND wp.set_date <= insert_date$d
                            AND wp.billing_id = w.billing_id);
    --Если оборудования нет в таблице warranty_periods то берется значение из c_data
    IF cur_warranty_months$i IS NULL THEN
      --"Длительность гарантийного срока для оборудования по умолчанию"
      cur_warranty_months$i := to_number(get_const(140, billing_id$i));
    END IF;
    RETURN cur_warranty_months$i;
  END get_count_warranty_months;

  /**
  * Возвращает гарантийный срок обслуживания оборудования
  * @param  cost_id$i    - Идентификатор материала
  * @param  billing_id$i - Идентификатор биллинга
  */
  FUNCTION get_warranty_date(
    cost_id$i    IN INTEGER,
    billing_id$i IN INTEGER
  ) RETURN DATE
  IS
    insert_date$d           DATE;
    attr_entity_id$i        INTEGER;
    count_warranty_months$i INTEGER;
  BEGIN
    -- найдем оборудование, которое установили, и дату установки
    SELECT insert_date, attr_entity_id
    INTO insert_date$d, attr_entity_id$i
    FROM house_material_costs_all
    WHERE cost_id = cost_id$i
      AND billing_id = billing_id$i;
    --Заменено на общую функцию в DEV-83679.
    count_warranty_months$i := get_count_warranty_months(attr_entity_id$i, billing_id$i, insert_date$d);
    RETURN add_months(insert_date$d, count_warranty_months$i);
  END get_warranty_date;

  /**
  * Получить абонентскую плату
  * @param  abon_pay_id$i - Идентификатор аб.платы
  * @param  billing_id$i  - Идентификатор биллинга
  */
  FUNCTION get_first_price(
    abon_pay_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN NUMBER
  IS
    result$n number := 0;
    price$n number;
  BEGIN
    SELECT MAX(apc.price)
    INTO price$n
    FROM abon_pays_contents_all apc
    WHERE apc.abon_pay_id = abon_pay_id$i
      AND apc.billing_id = billing_id$i
      AND threshold=(SELECT MIN(apc.threshold) FROM abon_pays_contents_all apc WHERE apc.abon_pay_id=abon_pay_id$i);
    --
    result$n := NVL(price$n, 0);
    --
    RETURN result$n;
  END get_first_price;

  /**
  * @param  addendum_id$i - Идентификатор приложения
  * @param  billing_id$i  - Идентификатор биллинга
  * @param  service_id$i  - Идентификатор услуги
  * @param  date$d        - На какую дату смотрим
  * @param  with_nds$i    - Флаг учета в ответе НДС
  * @return абонентская плата
  */
  FUNCTION get_abon_pays(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    service_id$i  IN INTEGER,
    date$d        IN DATE := get_current_date(),
    with_nds$i    IN INTEGER := 1
  ) RETURN NUMBER
  IS
    abon_pay_id$i INTEGER;
    lv_res$n NUMBER;
  BEGIN
    BEGIN
      SELECT al.abon_pay_id
      INTO abon_pay_id$i
      FROM services_all s
          ,abon_pays_list_all al
          ,abon_pays_addenda_link_all apa
      WHERE apa.addendum_id = addendum_id$i
        AND apa.billing_id = billing_id$i
        AND apa.active_from <= date$d
        AND (apa.active_to IS NULL OR apa.active_to > date$d)
        --
        AND al.abon_pay_id = apa.abon_pay_id
        AND al.billing_id = apa.billing_id
        --
        AND s.service_id = al.service_id
        AND s.billing_id = al.billing_id
        AND s.service_id = service_id$i;
      -- Получим цену
      lv_res$n := get_first_price(abon_pay_id$i, billing_id$i);
      -- Если надо накрутим НДС
      IF with_nds$i = 1 THEN
        lv_res$n := ROUND(lv_res$n * get_nds(service_id$i, billing_id$i, date$d), 2);
      END IF;
    EXCEPTION
      WHEN no_data_found THEN
        abon_pay_id$i := NULL;
    END;
    RETURN nvl(lv_res$n, 0);
  END get_abon_pays;

  ------------------------------
  -- Стоимости для оверрайдов
  ------------------------------
  FUNCTION get_service_cost_override(
    addendum_id$i  INTEGER,
    billing_id$i   INTEGER,
    service_id     INTEGER,
    service_cup_id INTEGER DEFAULT NULL,
    date$d         DATE DEFAULT get_current_date(),
    with_nds$i     INTEGER DEFAULT 1,-- 0/1
    with_cupon     INTEGER DEFAULT 0 -- 0/1
  ) RETURN NUMBER
  IS
    lv_res$n   NUMBER;
    lv_cost$n  NUMBER;
    lv_cupon$n NUMBER := 0;
  BEGIN
    --IF (with_cupon = 1 AND service_cup_id IS NULL) THEN EXCEPTION...; END IF;
    -- Получим стоимость услуги service_id
    lv_cost$n := rias_mgr_support.get_service_cost(addendum_id$i, NULL, billing_id$i, service_id, date$d, with_nds$i);
    -- Получим купон скидки, если надо
    IF with_cupon = 1 AND service_cup_id IS NOT NULL THEN
      lv_cupon$n := NVL(rias_mgr_support.get_cupon_4_service(addendum_id$i => addendum_id$i,
                                                             billing_id$i  => billing_id$i,
                                                             service_id$i  => service_cup_id,
                                                             date$d        => date$d), 0);
    END IF;
    -- Округляем на каждом шаге ! Как-то так делается в RIAS
    lv_res$n := ROUND(lv_cost$n - ROUND(lv_cost$n * lv_cupon$n/100, 2), 2);
    RETURN lv_res$n;
  END get_service_cost_override;

  /**
  * Получитьт имя сервиса по service_id$i
  * @param  service_id$i - Идентификатор сервиса
  * @param  billing_id$i - Идентификатор биллинга
  */
  FUNCTION get_service_name(
    service_id$i IN INTEGER,
    billing_id$i IN INTEGER
  ) RETURN VARCHAR2
  IS
    service_name$c services_all.service_name%TYPE;
  BEGIN
    SELECT s.service_name
      INTO service_name$c
    FROM services_all s
    WHERE s.service_id = service_id$i
      AND s.billing_id = billing_id$i;
    RETURN service_name$c;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN NULL;
  END get_service_name;

  /**
  * Получить название бонуса по активной услуге
  * @param  activity_id$i - Идентификатор
  * @param  billing_id$i  - Идентификатор биллинга
  */
  FUNCTION get_bonus_comment(
    activity_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN VARCHAR2
  IS
    bonus_name$c VARCHAR2(300) := NULL;
  BEGIN
    BEGIN
      SELECT db.bonus_name
       INTO bonus_name$c
      FROM activate_lf_link_bonus_all lb,
           domru_bonuses_all db
      WHERE lb.activity_id = activity_id$i
        AND lb.billing_id = billing_id$i
        AND db.bonus_id = lb.bonus_id
        AND db.billing_id = lb.billing_id;
    EXCEPTION
      WHEN no_data_found THEN
        bonus_name$c := NULL;
      WHEN OTHERS THEN
        bonus_name$c := NULL; --' (бонус не определен! ['||sqlerrm(sqlcode)||'])';
    END;
    RETURN bonus_name$c;
  END get_bonus_comment;

  /**
  * Получить число платного бонуса по активной услуге
  * @param  activity_id$i - Идентификатор
  * @param  billing_id$i  - Идентификатор биллинга
  */
  FUNCTION get_number_bonus(
    activity_id$i IN INTEGER,
    billing_id$i  IN INTEGER
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
    lv_res$c VARCHAR2(300);
  BEGIN
    lv_res$c := get_bonus_comment(activity_id$i,billing_id$i);
    lv_res$n := TO_NUMBER(REGEXP_REPLACE(lv_res$c, '[^[[:digit:]]]*'));
    RETURN lv_res$n;
  END get_number_bonus;

  /**
  * Получить идентификатор правила
  * @param  plan_item_id$i  - Идентификатор
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  date$d          - На какую дату смотрим
  */
  FUNCTION get_rule_id(
    plan_item_id$i IN INTEGER,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    date$d         IN DATE DEFAULT get_current_date()
  ) RETURN INTEGER
  IS
    lv_rule_id$i INTEGER;
  BEGIN
    FOR rec IN (
      SELECT spi.rule_id
      INTO lv_rule_id$i
      FROM activate_license_fee_all alf
           ,plan_items_all pi
           ,plan_contents_all pc
           ,simple_plan_items_all spi
      WHERE 1=1
        AND alf.billing_id = billing_id$i
        AND alf.active_from <= date$d
        AND (alf.active_to is null or alf.active_to > date$d)
        AND alf.plan_item_id = pi.plan_item_id
        AND alf.billing_id = pi.billing_id
        AND pi.plan_item_id = plan_item_id$i
        AND pi.service_id = service_id$i
        AND pc.plan_item_id = pi.plan_item_id
        AND pc.billing_id = pi.billing_id
        and pc.active_from <= date$d
        and (pc.active_to IS NULL OR pc.active_to > date$d)
        AND spi.plan_item_id = pc.plan_item_id
        AND spi.billing_id = pc.billing_id
     ) LOOP
       lv_rule_id$i := rec.rule_id;
    END LOOP;
    -- Если не определено, то пытаемся определить
    -- 19.02.2021 BikulovMD
    IF lv_rule_id$i IS NULL THEN
      FOR rec IN (
        SELECT spi.rule_id
        INTO lv_rule_id$i
        FROM activate_license_fee_all alf
             ,plan_items_all pi
             ,plan_contents_all pc
             ,simple_plan_items_all spi
        WHERE 1=1
          AND alf.billing_id = billing_id$i
          AND alf.active_from <= date$d
          --AND (alf.active_to is null or alf.active_to > date$d)
          AND alf.plan_item_id = pi.plan_item_id
          AND alf.billing_id = pi.billing_id
          AND pi.plan_item_id = plan_item_id$i
          AND pi.service_id = service_id$i
          AND pc.plan_item_id = pi.plan_item_id
          AND pc.billing_id = pi.billing_id
          and pc.active_from <= date$d
          --and (pc.active_to IS NULL OR pc.active_to > date$d)
          AND spi.plan_item_id = pc.plan_item_id
          AND spi.billing_id = pc.billing_id

          AND alf.active_from = (SELECT max(alf.active_from)
                                 FROM activate_license_fee_all alf1,
                                      plan_items_all pi1
                                 WHERE 1=1
                                   AND alf1.billing_id = billing_id$i
                                   AND alf1.active_from <= date$d
                                   AND pi1.plan_item_id = alf1.plan_item_id
                                   AND pi1.billing_id = alf1.billing_id
                                   AND pi1.plan_item_id = plan_item_id$i
                                   AND pi1.service_id = service_id$i)
       ) LOOP
         lv_rule_id$i := rec.rule_id;
      END LOOP;
    END IF;
    RETURN lv_rule_id$i;
  END get_rule_id;

  /**
  * Получить стоимость платного бонуса
  * @param  plan_item_id$i  - Идентификатор
  * @param  billing_id$i    - Идентификатор биллинга
  * @param  service_id$i    - Идентификатор купонной (скидочной) услуги
  * @param  threshold$i     - Порог
  * @param  activity_id$i   - Идентификатор
  * @param  date$d          - На какую дату смотрим
  * Remark: Если задан activity_id$i, то он имеет приоритет перед порогом
  */
  FUNCTION get_price_4_bonus(
    plan_item_id$i IN INTEGER,
    billing_id$i   IN INTEGER,
    service_id$i   IN INTEGER,
    threshold$i    IN INTEGER DEFAULT NULL,
    activity_id$i  IN INTEGER DEFAULT NULL,
    date$d         IN DATE DEFAULT get_current_date()
  ) RETURN NUMBER
  IS
    lv_rule_id$i INTEGER;
    lv_price$n  NUMBER;
    lv_threshold$i INTEGER := threshold$i;
  BEGIN
    -- Получим число платного бонуса по активной услуге
    IF activity_id$i IS NOT NULL THEN
      lv_threshold$i := rias_mgr_support.get_number_bonus(activity_id$i => activity_id$i,
                                                          billing_id$i => billing_id$i);
    END IF;
    -- Получим RULE_ID
    lv_rule_id$i := get_rule_id(plan_item_id$i => plan_item_id$i,
                                billing_id$i   => billing_id$i,
                                service_id$i   => service_id$i,
                                date$d         => date$d);


    -- Вытащим PRICE
    IF lv_rule_id$i IS NOT NULL THEN
      FOR rec IN (
      SELECT price
      FROM ri_ulf_ps_contents_all
      WHERE rule_id=lv_rule_id$i
        AND billing_id = billing_id$i
        AND threshold = (SELECT MAX(threshold)
                         FROM ri_ulf_ps_contents_all
                         WHERE billing_id = billing_id$i
                           AND rule_id = lv_rule_id$i
                           AND threshold > 0
                           AND threshold <= lv_threshold$i)
      ) LOOP
        lv_price$n := ROUND(rec.price *
                           rias_mgr_support.get_nds(service_id$i => service_id$i,
                                                    billing_id$i => billing_id$i,
                                                    value_date$d => date$d), 2);
      END LOOP;
    END IF;
    RETURN lv_price$n;
  END get_price_4_bonus;

  /**
  * Проверить является ли IP "серым" или "белым"
  * @param  ip$c  - IP-адрес в виде строки
  * @return Возвращает 0, если белый, иначе ip серый
  */
  FUNCTION is_ip_local(ip$c VARCHAR2) RETURN PLS_INTEGER
  IS
  BEGIN
    RETURN greatest(0,
                    regexp_count(ip$c, '(^10\.)') +                                           --10.0.0.0-10.255.255.255
                    regexp_count(ip$c, '(^127\.)') +                                          --127.0.0.0-127.255.255.255
                    regexp_count(ip$c, '(^172\.1[6-9]\.)|(^172\.2[0-9])\.|(^172\.3[0-1]\.)') +--172.16.0.0-172.31.255.255
                    regexp_count(ip$c, '(^192\.168)') +                                       --192.168.0.0 - 192.168.255.255
                    regexp_count(ip$c, '(^100.6[4-9])|(^100.[7-9][0-9])|(^100.1[0-2][0-7])')  --100.64.0.0 - 100.127.255.255
                   );
  END is_ip_local;

  /**
  * Получить значение BPI_MARKET
  * @param  ip_address$c - адрес в виде строки формата 'a7925172+3f5a+9a7f+e053+4201630a5105'
  *                       уровень "ДОМ"
  */
  FUNCTION get_market(ip_address$c IN VARCHAR2) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'mrkt-'||ip_address$c;
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      FOR rec IN (SELECT parent_id, LEVEL
                  FROM idb_ph1_address_unit au
                  CONNECT BY idb_id = PRIOR parent_id
                  START WITH au.idb_id = ip_address$c
                  ORDER BY LEVEL)
      LOOP
        BEGIN
          SELECT market_name INTO lv_res$c
          FROM idb_ph2_addr_unit_market_dic
          WHERE fias_id = rec.parent_id;
          --FROM market_dic
          --WHERE guid = rec.parent_id;
        EXCEPTION
          WHEN no_data_found THEN
            lv_res$c := NULL;
        END;
        IF lv_res$c IS NOT NULL THEN
          EXIT;
        END IF;
      END LOOP;
      lv_res$c := NVL(lv_res$c, 'Россия');
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;

    RETURN lv_res$c;
  END get_market;

  /**
  * Получить замапленное строковое значение
  * @param  ip_table_name$c   - Наименование таблицы
  * @param  ip_column_name$c  - Наименование колонки (поля)
  * @param  ip_value$c        - Строковое значение RIAS
  * @return Значение для BSS
  */
  FUNCTION get_map_value_str(
    ip_table_name$c  IN VARCHAR2,
    ip_column_name$c IN VARCHAR2,
    ip_value$c       IN VARCHAR2
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    IF ip_value$c IS NOT NULL THEN
      -- Получить значение из кэша
      lv_cache_key$c := 'mapc-' || ip_table_name$c ||'&'|| ip_column_name$c ||'&'|| ip_value$c;
      lv_res$c := get_char_cache(lv_cache_key$c);
      -- В кэше нет значения, пытаемся определить
      IF lv_res$c IS NULL THEN
        BEGIN
          SELECT m.bss_string
          INTO lv_res$c
          FROM RIAS_MGR_MAP_INFO m
          WHERE m.table_name = ip_table_name$c
            AND m.column_name = ip_column_name$c
            AND UPPER(m.rias_string) = UPPER(ip_value$c);
        EXCEPTION
          WHEN no_data_found THEN
            lv_res$c := ip_value$c;
        END;
        lv_res$c := NVL(lv_res$c, ip_value$c);
        -- Добавить значение в КЭШ
        set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
      END IF;
    END IF;
    RETURN lv_res$c;
  END get_map_value_str;

  /**
  * Получить замапленное числовое значение
  * @param  ip_table_name$c   - Наименование таблицы
  * @param  ip_column_name$c  - Наименование колонки (поля)
  * @param  ip_value$n        - Числовое значение RIAS
  * @return Значение для BSS
  */
  FUNCTION get_map_value_num(
    ip_table_name$c  IN VARCHAR2,
    ip_column_name$c IN VARCHAR2,
    ip_value$n       IN NUMBER
  ) RETURN NUMBER
  IS
    lv_res$n       NUMBER;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'mapn-' || ip_table_name$c ||'&'|| ip_column_name$c ||'&'|| TO_CHAR(ip_value$n);
    lv_res$n := get_number_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$n IS NULL THEN
      BEGIN
        SELECT m.bss_number
        INTO lv_res$n
        FROM RIAS_MGR_MAP_INFO m
        WHERE m.table_name = ip_table_name$c
          AND m.column_name = ip_column_name$c
          AND m.rias_number = ip_value$n;
      EXCEPTION
        WHEN no_data_found THEN
          lv_res$n := ip_value$n;
      END;
      lv_res$n := NVL(lv_res$n, ip_value$n);
      -- Добавить значение в КЭШ
      set_number_cache(ip_cache_key$c => lv_cache_key$c, ip_value$n => lv_res$n);
    END IF;
    RETURN lv_res$n;
  END get_map_value_num;

  /**
  * Получить замапленное значение даты
  * @param  ip_table_name$c   - Наименование таблицы
  * @param  ip_column_name$c  - Наименование колонки (поля)
  * @param  ip_value$d        - Значение даты RIAS
  * @return Значение для BSS
  */
  FUNCTION get_map_value_date(
    ip_table_name$c  IN VARCHAR2,
    ip_column_name$c IN VARCHAR2,
    ip_value$d       IN DATE
  ) RETURN DATE
  IS
    lv_res$d       DATE;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'mapd-' || ip_table_name$c ||'&'|| ip_column_name$c ||'&'|| TO_CHAR(ip_value$d, 'dd.mm.yyyy');
    lv_res$d := get_date_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$d IS NULL THEN
      BEGIN
        SELECT m.bss_date
        INTO lv_res$d
        FROM RIAS_MGR_MAP_INFO m
        WHERE m.table_name = ip_table_name$c
          AND m.column_name = ip_column_name$c
          AND m.rias_date = ip_value$d;
      EXCEPTION
        WHEN no_data_found THEN
          lv_res$d := ip_value$d;
      END;
      lv_res$d := NVL(lv_res$d, ip_value$d);
      -- Добавить значение в КЭШ
      set_date_cache(ip_cache_key$c => lv_cache_key$c, ip_value$d => lv_res$d);
    END IF;
    RETURN lv_res$d;
  END get_map_value_date;

  /**
  *
  */
  FUNCTION get_teo_flag_info(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    flag_type_id$i    IN INTEGER,
    date$d            IN DATE DEFAULT rias_mgr_support.get_current_date,
    field$c           IN VARCHAR2 DEFAULT 'NAME',
    agreement_id$i    IN INTEGER DEFAULT NULL,
    point_plugin_id$i IN INTEGER DEFAULT NULL
  ) RETURN VARCHAR2
  IS
    lv_flag_name$c    t_cache_str_value;
    lv_flag_comment$c VARCHAR2(2000);
    --lv_cache_key$c    t_cache_key;
    lv_res$c          t_cache_str_value;
  BEGIN

    FOR rec IN (
      SELECT af.flag_name, tfl.flag_comment
      FROM teo_link_addenda_all tla,
           teo_all              t,
           point_plugins_all    pp,
           agreement_flags_all  af,
           teo_flag_links_all   tfl
      WHERE 1=1
        AND tla.addendum_id = addendum_id$i
        AND tla.billing_id = billing_id$i
        AND (date$d IS NULL OR (tla.active_from <= date$d AND (tla.active_to IS NULL OR tla.active_to > date$d)))
        --
        AND t.teo_id = tla.teo_id
        AND t.billing_id = tla.billing_id
        --
        AND pp.point_plugin_id = t.point_plugin_id
        AND pp.billing_id = t.billing_id
        AND (agreement_id$i IS NULL OR pp.agreement_id = agreement_id$i)
        AND (point_plugin_id$i IS NULL OR pp.point_plugin_id = point_plugin_id$i)
        --
        AND tfl.teo_id = t.teo_id
        AND tfl.billing_id = t.billing_id
        AND (date$d IS NULL OR (tfl.active_from <= date$d AND (tfl.active_to IS NULL OR tfl.active_to > date$d)))
        --
        AND af.flag_id = tfl.flag_id
        AND af.billing_id = tfl.billing_id
        AND af.flag_type_id = flag_type_id$i
        AND (flag_type_id$i != 16 OR NOT (af.flag_name like 'Автоматическое отключение по ДЗ%'))
        AND af.flag_name IS NOT NULL
    ) LOOP
      lv_flag_name$c    := rec.flag_name;
      lv_flag_comment$c := rec.flag_comment;
    END LOOP;
    --
    lv_res$c := CASE WHEN field$c = 'NAME' THEN lv_flag_name$c ELSE lv_flag_comment$c END;
    RETURN lv_res$c;
  END get_teo_flag_info;

  /**
  *
  */
  FUNCTION get_teo_flag_name(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    flag_type_id$i    IN INTEGER,
    date$d            IN DATE DEFAULT rias_mgr_support.get_current_date,
    agreement_id$i    IN INTEGER DEFAULT NULL,
    point_plugin_id$i IN INTEGER DEFAULT NULL
  ) RETURN VARCHAR2
  IS
    lv_cache_key$c    t_cache_key;
    lv_res$c          t_cache_str_value;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'flg_nm-' || to_char(addendum_id$i)  ||'&'||
                                   to_char(billing_id$i)   ||'&'||
                                   to_char(flag_type_id$i) ||
                                   CASE WHEN date$d IS NOT NULL THEN '&'|| to_char(date$d, 'dd.mm.yyyy') ELSE '' END ||
                                   CASE WHEN agreement_id$i IS NOT NULL THEN '&'|| to_char(agreement_id$i) ELSE '' END ||
                                   CASE WHEN point_plugin_id$i IS NOT NULL THEN '&'|| to_char(point_plugin_id$i) ELSE '' END;
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      lv_res$c := get_teo_flag_info(addendum_id$i     => addendum_id$i,
                                    billing_id$i      => billing_id$i,
                                    flag_type_id$i    => flag_type_id$i,
                                    date$d            => date$d,
                                    field$c           => 'NAME',
                                    agreement_id$i    => agreement_id$i,
                                    point_plugin_id$i => point_plugin_id$i);
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;

    RETURN lv_res$c;
  END get_teo_flag_name;

  /**
  * Читает value_number из rias_mgr_parameteres
  * @param mgr_prmt_id$i   - идентификатор параметра
  * @param default_value$n - значение по умолчанию
  * @return значение параметра NUMBER
  *
  * 05.12.2021 Логику перенес в RIAS_MGR_CORE
  */
  FUNCTION get_mgr_number_parameter(
    mgr_prmt_id$i   IN NUMBER,
    default_value$n IN NUMBER DEFAULT NULL
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    lv_res$n := RIAS_MGR_CORE.get_mgr_number_parameter(mgr_prmt_id$i => mgr_prmt_id$i,
                                                       default_value$n => default_value$n);
    RETURN lv_res$n;
  END get_mgr_number_parameter;

  /**
  * Читает value_string из rias_mgr_parameteres
  * @param mgr_prmt_id$i   - идентификатор параметра
  * @param default_value$c - значение по умолчанию
  * @return значение параметра VARCHAR2
  *
  * 05.12.2021 Логику перенес в RIAS_MGR_CORE
  */
  FUNCTION get_mgr_string_parameter(
    mgr_prmt_id$i   IN NUMBER,
    default_value$c IN VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2
  IS
    lv_res$c rias_mgr_parameteres.value_string%TYPE;
  BEGIN
    lv_res$c := RIAS_MGR_CORE.get_mgr_string_parameter(mgr_prmt_id$i => mgr_prmt_id$i,
                                                       default_value$c => default_value$c);
    RETURN lv_res$c;
  END get_mgr_string_parameter;

  /**
  * Читает value_date из rias_mgr_parameteres
  * @param mgr_prmt_id$i   - идентификатор параметра
  * @param default_value$d - значение по умолчанию
  * @return значение параметра DATE
  *
  * 05.12.2021 Логику перенес в RIAS_MGR_CORE
  */
  FUNCTION get_mgr_date_parameter(
    mgr_prmt_id$i   IN NUMBER,
    default_value$d IN DATE DEFAULT NULL
  ) RETURN DATE
  IS
    lv_res$d DATE;
  BEGIN
    lv_res$d := RIAS_MGR_CORE.get_mgr_date_parameter(mgr_prmt_id$i => mgr_prmt_id$i,
                                                     default_value$d => default_value$d);    
    RETURN lv_res$d;
  END get_mgr_date_parameter;

  /**
  * Получить INV_NAME из справочника
  * @param  table_name$c      - Наименование таблицы
  * @param  off_id_for_migr$c - Оффер
  * @param  default_value$c   - Значение по-умолчанию
  * @return INV_NAME
  */
  FUNCTION get_inv_name(
    table_name$c      IN VARCHAR2,
    off_id_for_migr$c IN VARCHAR2,
    default_value$c   IN VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'invname:' || table_name$c || '&' || off_id_for_migr$c;
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      BEGIN
        SELECT nvl(func_default_value, default_value$c)
        INTO lv_res$c
        FROM idb_ph2_offers_chr_inv_dic dic
        WHERE 1 = 1
          AND dic.idb_column_name = 'INV_NAME'
          AND dic.idb_table_name = table_name$c
          AND dic.off_id_for_migr = off_id_for_migr$c;
      EXCEPTION
        WHEN no_data_found THEN
          NULL;
      END;
      lv_res$c := NVL(lv_res$c, default_value$c);
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;

    RETURN lv_res$c;
  END get_inv_name;

  /**
  * Получение текста ошибки и стэка вызовов
  * @return Текск ошибки, стэк вызовов
  */
  FUNCTION get_error_stack RETURN VARCHAR2
  IS
    v_result VARCHAR2(2000);
  BEGIN
    RETURN SUBSTR(dbms_utility.format_error_stack||dbms_utility.format_error_backtrace||dbms_utility.format_call_stack,1,2000);
  END get_error_stack;

  /**
  * Для оборудования в лизинге проверяет была ли замена 0-не было, 1-была
  * @param  ip_cost_id$i   - Идентификатор материала
  * @param  ip_billing_id$ - Идентификатор биллинга
  */
  FUNCTION has_liasing_exchange(
    cost_id$i   IN INTEGER,
    billing_id$ IN INTEGER
  ) RETURN INTEGER
  IS
    cnt$i integer;
  BEGIN
    SELECT COUNT(*)
    INTO cnt$i
    FROM house_material_costs_ext_all hmce
        ,house_material_costs_all hmc
        ,addenda_all a
    WHERE hmce.cost_id=cost_id$i
      AND hmce.billing_id = billing_id$
      AND hmce.cost_id=hmc.cost_id
      AND hmce.billing_id=hmc.billing_id
      AND hmc.addendum_id=a.addendum_id
      AND hmc.billing_id=a.billing_id
      AND hmce.oper_type=5 -- рассрочка
      -- На договоре существует оборудование в рассрочке, установленное в дату снятия этого
      AND (EXISTS (SELECT 1
                  FROM house_material_costs_ext_all hmce2
                      ,house_material_costs_all hmc2
                      ,addenda_all a2
                  WHERE a2.agreement_id=a.agreement_id
                    AND a2.billing_id = a.billing_id
                    AND hmce2.cost_id=hmc2.cost_id
                    AND hmce2.billing_id=hmc2.billing_id
                    AND hmc2.addendum_id=a2.addendum_id
                    AND hmc2.billing_id=a2.billing_id
                    AND hmce2.oper_type=5 -- рассрочка
                    AND hmce2.active_from=hmce.active_to)
          -- так же проверим может новое оборудование уже было перемещено на другой договор
          OR EXISTS (SELECT 1
                  FROM house_material_costs_ext_all hmce2
                      ,EXCELLENT.house_material_costs_trans_all hmct2
                      ,addenda_all a2
                  WHERE a2.agreement_id=a.agreement_id
                    AND a2.billing_id=a.billing_id
                    AND hmce2.cost_id=hmct2.cost_id
                    AND hmce2.billing_id=hmct2.billing_id
                    AND hmct2.addendum_link_id=a2.addendum_id
                    AND hmct2.billing_id=a2.billing_id
                    AND hmce2.oper_type=5 -- рассрочка
                    AND hmce2.active_from=hmce.active_to)
          );
    RETURN cnt$i;
  end has_liasing_exchange;

  /**
  * Возвращает тип собственности
  * @param  ip_cost_id$i   - Идентификатор материала
  * @param  ip_billing_id$ - Идентификатор биллинга
  */
  FUNCTION get_cost_type_info(
    ip_cost_id$i   IN INTEGER,
    ip_billing_id$ IN INTEGER
  ) RETURN VARCHAR2
  IS
    oper_type$i   INTEGER;
    --cost_type_id$i INTEGER;
    active_from$d DATE;
    active_to$d   DATE;
    cost_type$c   VARCHAR2(150);
  BEGIN
    --пытаемся найти признак рассрочки/аренды для матзатраты
    BEGIN
      SELECT hmce.oper_type,
             hmce.active_to
        INTO oper_type$i,
             active_to$d
        FROM house_material_costs_ext_all hmce
       WHERE hmce.cost_id = ip_cost_id$i
         AND hmce.billing_id = ip_billing_id$;
    EXCEPTION
      WHEN no_data_found THEN
        oper_type$i := NULL;
    END;
    --
    IF (oper_type$i = 0) THEN -- Аренда
      cost_type$c := 'передано в аренду';
    ELSIF (oper_type$i = 5
           AND (active_to$d >= current_date or has_liasing_exchange(ip_cost_id$i, ip_billing_id$) = 1)) then -- рассрочка
      cost_type$c := 'передано в рассрочку';
    ELSE -- Собственность и все остальное
      BEGIN
        SELECT ml.house_material_cost_type_id
          INTO oper_type$i
          FROM material_costs_link_types_all ml
         WHERE ml.cost_id = ip_cost_id$i
           AND ml.billing_id = ip_billing_id$;
      EXCEPTION
        WHEN no_data_found THEN
          oper_type$i := null;
      END;
      -- По-умолчанию тип списания материалов "На строительство сети"
      oper_type$i := NVL(oper_type$i, 1);
      BEGIN
        SELECT mt.house_material_cost_type_name
          INTO cost_type$c
          FROM house_material_cost_types_all mt
         WHERE mt.house_material_cost_type_id = oper_type$i
           AND mt.billing_id = ip_billing_id$;
      EXCEPTION
        WHEN no_data_found THEN
          cost_type$c := null;
      END;
    END IF;

    RETURN cost_type$c;
  END get_cost_type_info;

  /**
  * Определяет название сети, через которую подключена Услуга (ЭРТХ, Энфорта...)
  * @param addendum_id$i     - Идентификатор приложения
  * @param p_billing_id      - Город биллинга
  * @param agreement_id$i    - Идентификатор договора
  * @param point_plugin_id$i - Идентификатор ТП
  * @param date$d            - На какую дату смотрим
  * @return название сети
  */
  FUNCTION get_network(
    addendum_id$i     IN INTEGER,
    billing_id$i      IN INTEGER,
    agreement_id$i    IN INTEGER DEFAULT NULL,
    point_plugin_id$i IN INTEGER DEFAULT NULL,
    date$d            IN DATE DEFAULT get_current_date()
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    --lv_cache_key$c t_cache_key;
  BEGIN
    /*
    -- Получить значение из кэша
    lv_cache_key$c := 'get_network'||
                      TO_CHAR(addendum_id$i)||'&'||
                      TO_CHAR(billing_id$i)||'&'||
                      TO_CHAR(agreement_id$i)||'&'||
                      TO_CHAR(point_plugin_id$i)||'&'||
                      TO_CHAR(date$d,'dd.mm.yyyy');
    --Отключил кеш, и сохранение в кеш
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
    */
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
          AND ad.addendum_id = addendum_id$i
          AND ad.billing_id = billing_id$i
          AND (agreement_id$i IS NULL OR ad.agreement_id = agreement_id$i)
          -- ТП
          AND pp.agreement_id = ad.agreement_id
          AND pp.billing_id = ad.billing_id
          AND (point_plugin_id$i IS NULL OR pp.point_plugin_id = point_plugin_id$i)
          -- ТЭО
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
          AND tp.prop_type_id = 39 -- Подключение по сети
          AND tp.active_from <= date$d
          AND (tp.active_to IS NULL OR tp.active_to > date$d)
          AND cn.company_id = tp.prop_value
          AND cn.billing_id = tp.billing_id
          AND cn.active_from <= date$d AND (cn.active_to IS NULL OR cn.active_to > date$d)
      );
      
      
      
if lv_res$c is null and agreement_id$i is not null then
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
    and source_id=agreement_id$i and source_system=billing_id$i
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
      
   --dbms_output.put_line(lv_res$c);   
      
      
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
                     WHERE ar.addendum_id = addendum_id$i
                       AND ar.billing_id = billing_id$i
                       AND ar.active_from <= date$d --активные*/
                       AND coalesce(ar.active_to, date$d + 1) > date$d
                       AND rc.resource_id = ar.resource_id
                       AND rc.billing_id = ar.billing_id
                       AND rc.active_from <= date$d --активные*/
                       AND coalesce(rc.active_to, date$d + 1) > date$d
                       AND tr.terminal_resource_id = rc.terminal_resource_id
                       AND tr.billing_id = rc.billing_id
                       AND tr.active_from <= date$d --активные*/
                       AND coalesce(tr.active_to, date$d + 1) > date$d
                       AND ta.teo_id = tr.teo_id
                       AND ta.billing_id = tr.billing_id
                       AND pp.point_plugin_id = ta.point_plugin_id
                       AND pp.billing_id = ta.billing_id
                       AND pp.agreement_id = agreement_id$i
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
                AND hfl.billing_id= billing_id$i
        );
      END IF;

      -- Добавить значение в КЭШ
      --set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    --END IF;
    RETURN NVl(lv_res$c, 'ЭРТХ');
  END get_network;

  /**
  * Определяет принадлежит ли IP подсети на приложении
  * @param addendum_id$i - Идентификатор приложения
  * @param billing_id$i  - Город биллинга
  * @param ip$c          - ip-адрес строкой
  * @param ip$n          - ip-адрес числом
  * @param date$d        - На какую дату смотрим
  * @return если принадлежит 1, иначе 0
  */
  FUNCTION ip_in_subnet(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    ip$c          IN VARCHAR2 DEFAULT NULL,
    ip$n          IN NUMBER DEFAULT NULL,
    date$d        IN DATE DEFAULT get_current_date()
  ) RETURN INTEGER
  IS
    lv_ip$n  NUMBER := ip$n;
    lv_res$n NUMBER;
  BEGIN
    -- Если IP-адрес задан строкой, то приведем к числу
    IF ip$c IS NOT NULL THEN
      lv_ip$n := bss_migrate_support.ip_char_to_number(ip$c);
    END IF;
    --
    SELECT count(1) INTO lv_res$n
    FROM  addendum_resources_all    ar,
          resource_contents_all     rc,
          cable_city_ip_subnets_all csa
    WHERE (1=1)
      AND ar.addendum_id = addendum_id$i
      AND ar.billing_id = billing_id$i
      AND (ar.active_from<= date$d)
      AND (ar.active_to is null or ar.active_to > date$d)
      AND rc.resource_id = ar.resource_id
      AND rc.billing_id = ar.billing_id
      AND (rc.active_from<= date$d)
      AND (rc.active_to IS NULL OR rc.active_to > date$d)
      AND csa.terminal_resource_id  = rc.terminal_resource_id
      AND csa.billing_id = rc.billing_id
      AND (csa.ip_v6 IS NULL)
      AND lv_ip$n >= csa.ip_v4
      AND lv_ip$n < csa.ip_v4 + POWER(2, 32-csa.netmask);

    RETURN NVL(lv_res$n, 0);
  END ip_in_subnet;

  /**
  * Получить менеджера договора, заданного типа
  *
  * @param agreement_id$i       - Идентификатор договора
  * @param p_billing_id         - Город биллинга
  * @param type_spesialist_id$i - Типы ответственных за удержание договора
  * @param active_to$d          - На какую дату смотрим
  * @return Менеджер заданного типа
  *
  * type_spesialist_id:
  *   1 Сотрудник ООКК
  *   2  Менеджер ОРКК
  *   3  Менеджер продаж B2F
  *   4  Сервис менеджер ФК
  *   5  Менеджер СПКК
  *   6  Директор Вертикального рынка
  *   7  Менеджер по ключевым клиентам
  *   8  Региональный руководитель В2О
  *   9  Менеджер продаж В2О
  *   10 Специалист по расчетам РДО
  */
  FUNCTION get_manager_name_by_agr(
    agreement_id$i       INTEGER := NULL,
    billing_id$i         INTEGER := NULL,
    type_spesialist_id$i INTEGER := NULL,
    active_to$d          DATE := trunc(get_current_date(), 'dd')
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'gmna'||TO_CHAR(agreement_id$i)||'&'||
                              TO_CHAR(billing_id$i)||'&'||
                              TO_CHAR(type_spesialist_id$i)||'&'||
                              TO_CHAR(active_to$d,'ddmmyyyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      BEGIN    
        SELECT m.manager_name
        INTO   lv_res$c
        FROM  do_spesialist_all ds
             ,managers_all m
        WHERE ds.agreement_id = agreement_id$i
          AND ds.billing_id = billing_id$i
          AND ds.type_spesialist_id +0 = type_spesialist_id$i
          AND ds.active_from <= active_to$d
          AND (ds.active_to IS NULL OR ds.active_to > active_to$d)
          AND m.zp_worker_id = ds.zp_worker_id
          AND m.billing_id = ds.billing_id
          AND rownum <= 1;
      EXCEPTION
        WHEN no_data_found THEN 
          lv_res$c:=NULL;
      END;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_manager_name_by_agr;


  /**
  * Получить подразделение менеджера договора, заданного типа
  *
  * @param agreement_id$i       - Идентификатор договора
  * @param p_billing_id         - Город биллинга
  * @param type_spesialist_id$i - Типы ответственных за удержание договора
  * @param active_to$d          - На какую дату смотрим
  * @return Подразделение менеджера заданного типа
  *
  * type_spesialist_id:
  *   1 Сотрудник ООКК
  *   2  Менеджер ОРКК
  *   3  Менеджер продаж B2F
  *   4  Сервис менеджер ФК
  *   5  Менеджер СПКК
  *   6  Директор Вертикального рынка
  *   7  Менеджер по ключевым клиентам
  *   8  Региональный руководитель В2О
  *   9  Менеджер продаж В2О
  *   10 Специалист по расчетам РДО
  */
  FUNCTION get_subdivision_manager(
    agreement_id$i       INTEGER := NULL,
    billing_id$i         INTEGER := NULL,
    type_spesialist_id$i INTEGER := NULL,
    active_to$d          DATE := trunc(get_current_date(), 'dd')
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'gsm'||TO_CHAR(agreement_id$i)||'&'||
                             TO_CHAR(billing_id$i)||'&'||
                             TO_CHAR(type_spesialist_id$i)||'&'||
                             TO_CHAR(active_to$d,'ddmmyyyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      BEGIN    
        SELECT s.subdivision_name
        INTO   lv_res$c
        FROM do_spesialist_all           ds,
             managers_all                m,
             mng_changes_subdivision_all mng,
             subdivisions_all            s
        WHERE ds.agreement_id = agreement_id$i
          AND ds.billing_id = billing_id$i
          AND ds.type_spesialist_id +0 = type_spesialist_id$i
          AND ds.active_from <= active_to$d
          AND (ds.active_to IS NULL OR ds.active_to > active_to$d)
          AND m.zp_worker_id = ds.zp_worker_id
          AND m.billing_id = ds.billing_id
          AND mng.manager_id = m.manager_id
          AND mng.billing_id = m.billing_id
          AND mng.active_from <= active_to$d
          AND (mng.active_to IS NULL OR mng.active_to > active_to$d)
          AND s.subdivision_id = mng.subdivision_id
          AND s.billing_id = mng.billing_id
          AND rownum <= 1;
      EXCEPTION
        WHEN no_data_found THEN 
          lv_res$c:=NULL;
      END;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_subdivision_manager;

  /**
  * Получить менеджера на клиенте, заданного типа
  *
  * @param client_id$i          - Идентификатор клиента
  * @param p_billing_id         - Город биллинга
  * @param type_spesialist_id$i - Типы ответственных
  * @param active_to$d          - На какую дату смотрим
  * @return Менеджер заданного типа
  *
  * type_id:
  *   1  Сотрудник ООКК
  *   2  Менеджер ОРКК
  *   3  Директор Вертикального рынка
  *   4  Менеджер по ключевым клиентам
  *   5  Менеджер продаж B2F
  *   7  Региональный руководитель В2О
  *   8  Менеджер продаж В2О
  *   9  Специалист по расчетам РДО
  *   10 Сервис-менеджер
  *   
  */
  FUNCTION get_manager_name_by_clnt(
    client_id$i          INTEGER := NULL,
    billing_id$i         INTEGER := NULL,
    type_spesialist_id$i INTEGER := NULL,
    active_to$d          DATE := trunc(get_current_date(), 'dd')
  ) RETURN VARCHAR2
  IS
    lv_res$c       t_cache_str_value;
    lv_cache_key$c t_cache_key;
  BEGIN
    -- Получить значение из кэша
    lv_cache_key$c := 'gmnc'||TO_CHAR(client_id$i)||'&'||
                             TO_CHAR(billing_id$i)||'&'||
                             TO_CHAR(type_spesialist_id$i)||'&'||
                             TO_CHAR(active_to$d,'ddmmyyyyy');
    lv_res$c := get_char_cache(lv_cache_key$c);
    -- В кэше нет значения, пытаемся определить
    IF lv_res$c IS NULL THEN
      BEGIN    
        SELECT m.manager_name
        INTO   lv_res$c
        FROM  cl_clients_link_workers_all ds
             ,managers_all m
        WHERE ds.client_id = client_id$i
          AND ds.billing_id = billing_id$i
          AND ds.type_id +0 = type_spesialist_id$i
          AND ds.active_from <= active_to$d
          AND (ds.active_to IS NULL OR ds.active_to > active_to$d)
          AND m.zp_worker_id = ds.zp_worker_id
          AND m.billing_id = ds.billing_id
          AND rownum <= 1;
      EXCEPTION
        WHEN no_data_found THEN 
          lv_res$c:=NULL;
      END;
      -- Добавить значение в КЭШ
      set_char_cache(ip_cache_key$c => lv_cache_key$c, ip_value$c => lv_res$c);
    END IF;
    RETURN lv_res$c;
  END get_manager_name_by_clnt;

  /**
  * Получить часовой пояс города по адресу ТП
  *
  * @param  ip_pp_id$i      - Идентификатор точки подключения
  * @param  ip_billing_id$i - Идентификатор биллинга
  * @RETURN Возвращает часовой пояс
  */
  FUNCTION get_time_zone_pp(
    ip_pp_id$i      IN INTEGER,
    ip_billing_id$i IN INTEGER
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    -- Проверка
    IF ip_pp_id$i IS NULL OR ip_billing_id$i IS NULL THEN
      RETURN NULL;
    END IF;
    -- Получить значение
    FOR rec IN (
      SELECT cl.bpi_time_zone
      FROM idb_ph2_customer_location cl
      WHERE 1 = 1
        AND cl.source_id = to_char(ip_pp_id$i)
        AND cl.source_system = to_char(ip_billing_id$i)
    ) LOOP
      lv_res$n := rec.bpi_time_zone;
    END LOOP;
    RETURN lv_res$n;
  END get_time_zone_pp;

  /**
  * Получить часовой пояс города по адресу ТП
  * через идентификатору IDB_PH2_CUSTOMER_LOCATION
  *
  * @param  ip_cl_idb_id$i - Идентификатор IDB_PH2_CUSTOMER_LOCATION
  * @RETURN Возвращает часовой пояс
  */
  FUNCTION get_time_zone_cl(ip_cl_idb_id$i IN VARCHAR2) RETURN NUMBER
  IS
    lv_res$n NUMBER;
  BEGIN
    -- Проверка
    IF ip_cl_idb_id$i IS NULL THEN
      RETURN NULL;
    END IF;
    -- Получить значение
    FOR rec IN (
      SELECT cl.bpi_time_zone
      FROM idb_ph2_customer_location cl
      WHERE 1 = 1
        AND cl.idb_id = ip_cl_idb_id$i
    ) LOOP
      lv_res$n := rec.bpi_time_zone;
    END LOOP;
    RETURN lv_res$n;
  END get_time_zone_cl;

  FUNCTION get_date_interval_ranges RETURN ARRAY_DATE PIPELINED
  IS
  BEGIN
    FOR rec IN (SELECT (to_date('01.08.2021', 'dd.mm.yyyy') + (LEVEL - 1)*INTERVAL '1' SECOND) AS cr_date
                      FROM dual 
                      CONNECT BY to_date('01.08.2021', 'dd.mm.yyyy') + ( LEVEL - 1 ) * INTERVAL '1' SECOND <= current_date
    ) LOOP
      pipe row (rec.cr_date);
    END LOOP;
    return;
  END;

  /**
  *
  */
  FUNCTION get_cost_4_inet(
    addendum_id$i IN INTEGER,
    billing_id$i  IN INTEGER,
    service_id$i  IN INTEGER,
    date$d        IN DATE DEFAULT current_date,
    with_nds$i    IN INTEGER DEFAULT 1
  ) RETURN NUMBER
  IS
    lv_res$n NUMBER;
    lv_chk$i INTEGER;
  BEGIN
    -- Проверка на номер правила = 95
    lv_chk$i := get_calculation_rule(addendum_id$i => addendum_id$i,
                                     billing_id$i  => billing_id$i,
                                     service_id$i  => service_id$i,
                                     date$d        => date$d);

    IF lv_chk$i = 95 THEN
      lv_res$n := get_abon_pays(addendum_id$i => addendum_id$i,
                                billing_id$i  => billing_id$i,
                                service_id$i  => service_id$i,
                                date$d        => date$d,
                                with_nds$i    => with_nds$i);
    ELSE
      lv_res$n := get_service_cost(addendum_id$i => addendum_id$i,
                                   billing_id$i  => billing_id$i,
                                   service_id$i => service_id$i,
                                   date$d       => date$d,
                                   with_nds$i => with_nds$i);
    END IF;

    -- Проверим присутствие услуг service_id = 101254
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
      -- Если надо накрутим НДС
      IF with_nds$i = 1 THEN
        lv_res$n := ROUND(lv_res$n * get_nds(service_id$i, billing_id$i), 2);
      END IF;
    END IF;

    -- Проверим присутствие услуг service_id IN (102243, 102241)
    -- Смотрим отдельно, т.к. для них надо будет вставлять в таблицу IDB_PH2_BUNDLES
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
      -- Если надо накрутим НДС
      IF with_nds$i = 1 THEN
        lv_res$n := ROUND(lv_res$n * get_nds(service_id$i, billing_id$i), 2);
      END IF;
    END IF;

    RETURN NVL(lv_res$n, 0);
  END get_cost_4_inet;

  /**
  * Получение значения свойства
  *
  * @param terminal_resource_id$i - Идентификатор терминального ресурса
  * @param billing_id$i           - Идентификатор города
  * @param prop_type_id$i         - Свойство
  * @param on_date$d              - Дата
  */
  function get_property(
    terminal_resource_id$i integer
    ,billing_id$i   integer
    ,prop_type_id$i integer
    ,on_date$d date:=current_date
  )
  return varchar2
  is
    val$c cable_city_term_res_props_all.prop_value%type:=null;
    err_mes$c varchar2(30000):=null;
    err_param$e exception;
  begin
    if terminal_resource_id$i is null then
      err_mes$c:='Не передан terminal_resource_id$i';
      raise err_param$e;
    end if;
    
    if prop_type_id$i is null then
      err_mes$c:='Не передан prop_type_id$i';
      raise err_param$e;
    end if;
    
    if on_date$d is null then
      err_mes$c:='Не передан on_date$d';
      raise err_param$e;
    end if;
    
    select prop_value
    into val$c
    from cable_city_term_res_props_all trp
    where trp.terminal_resource_id=terminal_resource_id$i
      and trp.billing_id = billing_id$i
      and trp.prop_id+0 =prop_type_id$i
      and trp.active_from<= on_date$d
      and nvl(trp.active_to, on_date$d+1) >on_date$d;

    return val$c;

  exception
    when err_param$e then
      raise_application_error(-20001, err_mes$c);
    when no_data_found then
      return null;
    when others then
      raise_application_error(-20001, sqlerrm(sqlcode)||' get_property[tr='
      ||terminal_resource_id$i||' prop_type='||prop_type_id$i
      ||' on_date='||to_char(on_date$d, 'dd.mm.yyyy hh24:mi:ss')||']');
  end get_property;

  /**
  * Получить тип vlan
  *
  * @param  terminal_resource_id$i - Идентификатор терминального ресурса
  * @param  billing_id$i           - Идентификатор города
  * @RETURN 
  */
  function get_vlan_type(
    terminal_resource_id$i integer := null, 
    billing_id$i integer
  ) return varchar2
  is
    debug$n number := 0;
    dbg_name$c  varchar2(200) := ' get_vlan_type (debug$n='||to_char(terminal_resource_id$i)||')';
    val$c varchar2(1000); --:= a_log.pv(terminal_resource_id$i)||')';
    wifi_guest$i integer;
    wifi_peap$i integer;
    wifi_ofl$i integer;
    vlan_l2$i integer;
    prop_str$c varchar2(3000);
    --влан для вайфая
    c_prop_vlan_wifi constant integer:=7;
    --vlan для PEAP
    c_prop_vlan_peap constant integer:=17;
    --vlan для offloading с другим оператором(Yota, Tele2)
    c_prop_vlan_ofl constant integer:=18;
    --влан для АКС\ПД
    c_prop_vlan_aks_pd constant integer:=14;
  begin
    debug$n := 1;
    wifi_guest$i := nvl(get_property(terminal_resource_id$i, billing_id$i, c_prop_vlan_wifi, current_date), '0');
    if (wifi_guest$i = 1) then
      prop_str$c := 'Wi-Fi Hotspot';
    end if;

    debug$n := 2;
    if (prop_str$c is null) then
      wifi_peap$i := nvl(get_property(terminal_resource_id$i, billing_id$i, c_prop_vlan_peap, current_date), '0');
      if (wifi_peap$i = 1) then
        prop_str$c := 'Wi-Fi Peap';
      end if;
    end if;

    debug$n := 3;
    if (prop_str$c is null) then
      wifi_ofl$i := nvl(get_property(terminal_resource_id$i, billing_id$i, c_prop_vlan_ofl, current_date), '0');
      if (wifi_ofl$i = 1) then
        prop_str$c := 'Wi-Fi Offload';
      end if;
    end if;

    debug$n := 4;
    vlan_l2$i := nvl(get_property(terminal_resource_id$i, billing_id$i, c_prop_vlan_aks_pd, current_date), '0');


    if (vlan_l2$i = 1) then
      prop_str$c := prop_str$c||',L2';
    end if;

    if (prop_str$c is null) then
      prop_str$c :=  'PPPoE';
    else
      prop_str$c := rtrim(ltrim(prop_str$c, ','), ',');
    end if;
    return prop_str$c;
  exception
    when others then
      raise_application_error(-20001, dbms_utility.format_error_stack||dbg_name$c||debug$n||'; '||val$c);
  end get_vlan_type;

END RIAS_MGR_SUPPORT;
/

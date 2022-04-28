CREATE OR REPLACE FUNCTION IDB_PROD.aak_test_get_interzet(addendum_id$i IN INTEGER,
                                                          billing_id$i  IN INTEGER DEFAULT 556,
                                                          date$d        IN DATE DEFAULT rias_mgr_support.get_current_date())
  RETURN VARCHAR2 IS
  lv_res$v        VARCHAR2(100);
  TYPE nested_typ IS TABLE OF VARCHAR2(100);
  lv_nt_tmp$v  VARCHAR2(100);
  lv_nt_tmp2$v VARCHAR2(100);
  lv_nt_tmp3$v VARCHAR2(100);
  lv_nt1$v     nested_typ;
  lv_nt2$v     nested_typ := nested_typ('1SMH;0S');
  lv_nt3$v     nested_typ := nested_typ('0S;1SMH');
  lv_nt4$v     nested_typ := nested_typ('1MH;0MH');
  lv_nt5$v     nested_typ := nested_typ('0MH;1MH');
  TYPE t_cnt_rec IS RECORD(lv_cnt_ip$n  PLS_INTEGER, lv_CNT_W_G_IP$n PLS_INTEGER);
  lv_cnt_rec t_cnt_rec;
  --lv_cache_key$c t_cache_key;
BEGIN
  --https://kb.ertelecom.ru/pages/viewpage.action?pageId=455434737#id-10.02.49.03%D0%98%D0%BD%D1%82%D0%B5%D1%80%D0%B7%D0%B5%D1%82IPoE-%D0%A1%D0%B5%D1%80%D1%8B%D0%B9IP%D0%B7%D0%B0NAT
  lv_res$v := 'IPoE Дом.ру (РИАС)';
  /*IF rias_mgr_support.get_network(addendum_id$i => addendum_id$i,
                                  billing_id$i  => billing_id$i) !=
     'InterZet' THEN
    RETURN lv_res$v;
  END IF;*/

  SELECT CNT_ALL_IP, CNT_W_G_IP
  
  INTO   lv_cnt_rec
  FROM   aak_tmp_for_interzet_ipoe
  WHERE  1 = 1
  AND    addendum_id = addendum_id$i
  FETCH NEXT 1 ROWS ONLY;
  --0 - белый, 1 - серый
  --на приложение только 1 активный ip-адрес, и он серый
  IF lv_cnt_rec.lv_cnt_ip$n = 1 AND lv_cnt_rec.lv_CNT_W_G_IP$n = 1 THEN
    lv_res$v := 'IPoE серый IP за NAT';
    --на приложении активно 2 ip-адреса: 1 серый и 1 белый
  ELSIF lv_cnt_rec.lv_cnt_ip$n = 2 AND
        regexp_replace(lv_cnt_rec.lv_CNT_W_G_IP$n, '[0]{1,1}') = '1' THEN
  
    SELECT DISTINCT LISTAGG(KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(i.ip)) ||
                            (SELECT 'S'
                             FROM   EXCELLENT.Z_IPADDR_ALL_ALL zia
                             WHERE  zia.addendum_id = i.addendum_id
                             AND    zia.billing_id = i.billing_id
                             AND    zia.IPEXT_TERM_RES =
                                    i.TERMINAL_RESOURCE_ID
                             AND    rownum = 1) ||
                            (SELECT 'S'
                             FROM   EXCELLENT.Z_IPADDR_ALL_ALL zia
                             WHERE  zia.addendum_id = i.addendum_id
                             AND    zia.billing_id = i.billing_id
                             AND    zia.TERMINAL_RESOURCE_ID =
                                    i.TERMINAL_RESOURCE_ID
                             AND    IPEXT_TERM_RES IS NOT NULL
                             AND    rownum = 1) ||
                            (CASE
                               WHEN IP_MAC_ADDRESS IS NOT NULL THEN
                                'M'
                             END) || (CASE
                                        WHEN HOST_NAME IS NOT NULL THEN
                                         'H'
                                      END),
                            ';') WITHIN GROUP(ORDER BY IP) over(PARTITION BY i.ADDENDUM_ID, i.billing_id) AS connect_mac_host
    INTO   lv_nt_tmp$v
    FROM   aak_tmp_for_interzet_ip i
    WHERE    i.billing_id = billing_id$i
    AND    i.addendum_id = addendum_id$i;
    lv_nt1$v := nested_typ(lv_nt_tmp$v);
    --на сером ip-адресе во вкладке «Связанные ip» должен быть указан белый ip-адрес с этого приложения
    --на сером ip-адресе должны быть указаны mac-адрес и vlan
    --на белом ip-адресе не должно быть указано mac-адрес и vlan
    IF (lv_nt1$v IN (lv_nt2$v, lv_nt3$v)) THEN
      lv_res$v := 'IPoE белый IP за NAT';
      --на обоих ip-адресах не должно быть информации о связке между собой (вкладка «Связанные ip»)
      --на сером ip-адресе должны быть указаны mac-адрес и vlan
      --на белом ip-адресе должны быть указаны mac-адрес и vlan
    ELSIF (lv_nt1$v IN (lv_nt4$v, lv_nt5$v)) THEN
      lv_res$v := 'IPoE белый IP без NAT (через микротик)';
    END IF;
    --на приложении строго активны три серых ip-адреса
  ELSIF lv_cnt_rec.lv_cnt_ip$n = 3 AND
        regexp_replace(lv_cnt_rec.lv_CNT_W_G_IP$n, '[0]{1,1}') = '111' THEN
    --как минимум на 2 из 3 ip-адресов заполнены mac-адрес и vlan
    SELECT DISTINCT LISTAGG(KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(i.ip)) ||
                            (CASE
                               WHEN IP_MAC_ADDRESS IS NOT NULL THEN
                                'M'
                             END) || (CASE
                                        WHEN HOST_NAME IS NOT NULL THEN
                                         'H'
                                      END),
                            '') WITHIN GROUP(ORDER BY IP) over(PARTITION BY i.ADDENDUM_ID, i.billing_id) AS connect_mac_host
    INTO   lv_nt_tmp2$v
    FROM   aak_tmp_for_interzet_ip I
    WHERE  1 = 1
    AND    KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(i.ip)) = 1
    AND    i.billing_id = billing_id$i
    AND    i.addendum_id = addendum_id$i;
    IF regexp_replace(lv_nt_tmp2$v, '(1MH){2,}', 'Y') = 'Y' THEN
      lv_res$v := 'IPoE серый IP за NAT(через радиомост)';
    END IF;
    --на приложении строго активно 4 ip-адреса: 3 серых и 1 белый
  ELSIF lv_cnt_rec.lv_cnt_ip$n = 4 AND
        regexp_replace(lv_cnt_rec.lv_CNT_W_G_IP$n, '[0]{1,1}') = '111' THEN
    --только на одном из серых ip-адресов во вкладке «Связанные ip» должен быть указан белый ip-адрес с этого приложения
    --как минимум на 2 из 3 серых ip-адресов должны быть указаны mac-адрес и vlan
  
    SELECT DISTINCT LISTAGG(KRUS_SDB.BSS_IPS.IS_IP_LOCAL(bss_migrate_support.IP_NUMBER_TO_CHAR(i.ip)) ||
                            (SELECT 'S'
                             FROM   EXCELLENT.Z_IPADDR_ALL_ALL zia
                             WHERE  zia.addendum_id = i.addendum_id
                             AND    zia.billing_id = i.billing_id
                             AND    zia.IPEXT_TERM_RES =
                                    i.TERMINAL_RESOURCE_ID
                             AND    rownum = 1) ||
                            (CASE
                               WHEN IP_MAC_ADDRESS IS NOT NULL THEN
                                'M'
                             END) || (CASE
                                        WHEN HOST_NAME IS NOT NULL THEN
                                         'H'
                                      END) ||
                            (SELECT 'S'
                             FROM   EXCELLENT.Z_IPADDR_ALL_ALL zia
                             WHERE  zia.addendum_id = i.addendum_id
                             AND    zia.billing_id = i.billing_id
                             AND    zia.TERMINAL_RESOURCE_ID =
                                    i.TERMINAL_RESOURCE_ID
                             AND    IPEXT_TERM_RES IS NOT NULL
                             AND    rownum = 1),
                            ';') WITHIN GROUP(ORDER BY IP) over(PARTITION BY i.ADDENDUM_ID, i.billing_id) AS connect_mac_host
    INTO   lv_nt_tmp3$v
    
    FROM   aak_tmp_for_interzet_ip I
    WHERE  1 = 1
    AND    i.billing_id = billing_id$i
    AND    i.addendum_id = addendum_id$i;
    IF regexp_count(lv_nt_tmp3$v, '(1MH)') > 2 AND
       regexp_count(lv_nt_tmp3$v, '(S)') = 2 THEN
      lv_res$v := 'IPoE белый IP за NAT(через радиомост)';
    END IF;
  END IF;

  RETURN lv_res$v;
END;
/

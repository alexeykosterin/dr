create or replace package idb_prod.fill_net_access_chain as
    procedure CHAIN_STEP1;
    procedure CHAIN_STEP2;
    procedure CHAIN_STEP3;
    procedure CHAIN_STEP4;
    procedure start_chains;
end fill_net_access_chain;
/
create or replace package body idb_prod.fill_net_access_chain as
  phase_id$i      CONSTANT PLS_INTEGER := trash_from_odi.getPhase;
    v_ipv6 varchar2(150);
    v_nat varchar2(5) := 'Нет';
    v_mac varchar(200);
    --09.12.2021 A.Kostein для вставки 4
    TYPE t_arr_net_access_cur IS TABLE OF aak_tmp_cr_cities_all%ROWTYPE;
    lv_arr_net_access_cur t_arr_net_access_cur;

  CURSOR cr_cur_net_access IS
  
     select tbpi.rowid cr_row
      , tbpi.idb_id
      , tbpi.incl_ip4addr
      , tbpi.auth_type
      , tbpi.ip_method_assign
      , tbpi.network
      , ne.idb_id as ne
      , tbpi.service_id
      , tbpi.source_id
      , tbpi.source_system
      , tbpi.source_system_type
      , '5' event_type
      , '1' diagnostics
      , '1' session_lookup
    , tbpi.off_id_for_migr
    , (case when tbpi.source_system = 556 
     and 
     decode(rias_mgr_support.get_network(addendum_id$i => tbpi.source_id, billing_id$i => tbpi.source_system), 'InterZet',1, 0) = 1 
     then aak_test_get_interzet(addendum_id$i => tbpi.source_id)
     else rias_mgr_support.get_auth_type_4_net_access(tbpi.source_id, tbpi.source_system) end) auth,
       tbpi.phase
      from idb_ph2_offers_oss_dic dic
      , idb_ph2_tbpi_int tbpi
      , idb_ph2_ne ne
      where 1=1
      and tbpi.phase = phase_id$i
      and dic.netaccess_mandatory != 'No'
      and dic.migration_category = 'Интернет'
    and dic.off_id_for_migr not in ('121000158', '121000450')
      and tbpi.off_id_for_migr = dic.off_id_for_migr
      and tbpi.source_system in (select to_char(city_id) city_id from idb_ph1_city_dic)
      and tbpi.source_system_type = '1'
      -- Возьмем только интернет
      and tbpi.idb_id LIKE 'TI_1/%' -- bikulov 19.11.2020
      and ne.idb_id = 'NE_' || tbpi.IDB_ID
      and tbpi.ext_bpi_status != 'Disconnected'; -- bmdmax 07.10.2020
----      
    cursor cur_chain_1(P_CITY_ID PLS_INTEGER) is
    select tbpi.incl_ip4addr assigned_ipv4addresses
     , v_ipv6 assigned_ipv6addresses
     , 
     --01.11.2021 A.Kosterin add case
     (case when tbpi.source_system = 556 
     and 
     decode(rias_mgr_support.get_network(addendum_id$i => tbpi.source_id, billing_id$i => tbpi.source_system), 'InterZet',1, 0) = 1 
     then aak_test_get_interzet(addendum_id$i => tbpi.source_id)
     else rias_mgr_support.get_auth_type_4_net_access(tbpi.source_id, tbpi.source_system) end) auth_type
     , tbpi.idb_id bpi_idb_id
     , tbpi.service_id bss_service_id
     , '1' diagnostics
     , tbpi.service_id event_source
     , '5' event_type
     , 'NEA_' || tbpi.idb_id || '/' || tbpi.incl_ip4addr idb_id
     , tbpi.ip_method_assign ip_address_assignment_type
     , 'NA#'||tbpi.service_id name
     , v_nat nat
     , tbpi.network network_segment
     , ne.idb_id parent_id
     , '1' session_lookup
     , tbpi.source_id source_id
     , tbpi.source_system source_system
     , tbpi.source_system_type source_system_type
     , (case
     when tbpi.ip_method_assign = 'Статический' then (select gateway_ip from idb_ph2_ip_v4range where idb_id =
     (select parent_id from idb_ph2_ip_v4address where idb_id = tbpi.incl_ip4addr))
     when tbpi.ip_method_assign = 'Динамический' then (select gateway_ip from idb_ph2_ip_v4range_private where idb_id =
     (select parent_id from idb_ph2_ip_v4address_private where idb_id = tbpi.incl_ip4addr))
     end) gateway_ipaddress
     , v_mac cpe_mac_address,
     tbpi.phase
      from idb_ph2_offers_oss_dic dic
      , idb_ph2_tbpi_int tbpi
      , idb_ph2_ne ne
      where 1=1
      and tbpi.phase = phase_id$i
      and dic.netaccess_mandatory != 'No'
      and dic.migration_category = 'Интернет'
    and dic.off_id_for_migr not in ('121000158', '121000450')
      and tbpi.off_id_for_migr = dic.off_id_for_migr
      and tbpi.source_system = P_CITY_ID
      and tbpi.source_system_type = '1'
      -- Возьмем только интернет
      and tbpi.idb_id LIKE 'TI_1/%' -- bikulov 19.11.2020
      and tbpi.incl_ip4addr is not null
      and ne.idb_id = 'NE_' || tbpi.IDB_ID
      and tbpi.ext_bpi_status != 'Disconnected';
      
    TYPE t_arr_net_access_cur_chain IS TABLE OF cur_chain_1%ROWTYPE;
    lv_arr_net_access_cur_chain t_arr_net_access_cur_chain;
---------
     cursor cur_chain_2(P_CITY_ID PLS_INTEGER) is
     select sbpi.ipv4adr assigned_ipv4addresses
     , v_ipv6 assigned_ipv6addresses
     , (case when tbpi.source_system = 556 
     and 
     decode(rias_mgr_support.get_network(addendum_id$i => tbpi.source_id, billing_id$i => tbpi.source_system), 'InterZet',1, 0) = 1 
     then aak_test_get_interzet(addendum_id$i => tbpi.source_id)
     else rias_mgr_support.get_auth_type_4_net_access(tbpi.source_id, tbpi.source_system) end) auth_type
     , sbpi.idb_id bpi_idb_id
     , sbpi.service_id bss_service_id
     , '1' diagnostics
     , sbpi.service_id event_source
     , '5' event_type
     , 'NEA_' || tbpi.idb_id ||'/' || sbpi.ipv4adr || tbpi.rowid as idb_id
     , tbpi.ip_method_assign ip_address_assignment_type
     , 'NA#'||tbpi.service_id name
     , v_nat nat
     , tbpi.network network_segment
     , ne.idb_id parent_id
     , '1' session_lookup
     , tbpi.source_id source_id
     , tbpi.source_system source_system
     , tbpi.source_system_type source_system_type
     , (case
     when tbpi.ip_method_assign = 'Статический' then (select gateway_ip from idb_ph2_ip_v4range where idb_id =
     (select parent_id from idb_ph2_ip_v4address where idb_id = sbpi.ipv4adr))
     when tbpi.ip_method_assign = 'Динамический' then (select gateway_ip from idb_ph2_ip_v4range_private where idb_id =
     (select parent_id from idb_ph2_ip_v4address_private where idb_id = sbpi.ipv4adr))
     end) gateway_ipaddress
     , v_mac cpe_mac_address,
     tbpi.phase
      from idb_ph2_offers_oss_dic dic
      , idb_ph2_tbpi_int tbpi
    , idb_ph2_sbpi_int sbpi
      , idb_ph2_ne ne
      where 1=1
      and tbpi.phase = phase_id$i
        and dic.netaccess_mandatory != 'No'
        and dic.migration_category = 'Интернет'
        and dic.off_id_for_migr not in ('121000158', '121000450')
        and tbpi.off_id_for_migr = dic.off_id_for_migr
        and tbpi.source_system = P_CITY_ID
        and tbpi.source_system_type = '1'
        -- Возьмем только интернет
        and tbpi.idb_id LIKE 'TI_1/%' -- bikulov 19.11.2020
        --and (tbpi.incl_ip4addr is not null or sbpi.ipv4adr is not null) -- ????
        and ne.idb_id = 'NE_' || tbpi.IDB_ID
        and sbpi.source_system_type = '1'
        and sbpi.off_id_for_migr = '121000087'
        and sbpi.parent_id = tbpi.idb_id
        and sbpi.ipv4adr is not null
        and tbpi.ext_bpi_status != 'Disconnected' and sbpi.ext_bpi_status != 'Disconnected' -- bmdmax 07.10.2020
    ;
    TYPE t_arr_net_access_cur_chain_2 IS TABLE OF cur_chain_2%ROWTYPE;
    lv_arr_net_access_cur_chain_2 t_arr_net_access_cur_chain_2;

----------
    cursor cur_chain_3(P_CITY_ID PLS_INTEGER) is
          select sbpi.subnet assigned_ipv4addresses
             , sbpi.ipv6range assigned_ipv6addresses
             , (case when tbpi.source_system = 556 
     and 
     decode(rias_mgr_support.get_network(addendum_id$i => tbpi.source_id, billing_id$i => tbpi.source_system), 'InterZet',1, 0) = 1 
     then aak_test_get_interzet(addendum_id$i => tbpi.source_id)
     else rias_mgr_support.get_auth_type_4_net_access(tbpi.source_id, tbpi.source_system) end) auth_type
             , sbpi.idb_id bpi_idb_id
             , sbpi.service_id bss_service_id
             , '1' diagnostics
             , sbpi.service_id event_source
             , '5' event_type
             , 'NEA_' || tbpi.idb_id ||'/' || NVL(sbpi.subnet, sbpi.ipv6range) || '_s' idb_id
             , tbpi.ip_method_assign ip_address_assignment_type
             , 'NA#'||tbpi.service_id name
             , v_nat nat
             , tbpi.network network_segment
             , ne.idb_id parent_id
             , '1' session_lookup
     , tbpi.source_id source_id
     , tbpi.source_system source_system
     , tbpi.source_system_type source_system_type
     , (case
     when tbpi.ip_method_assign = 'Статический' then (select gateway_ip from idb_ph2_ip_v4range where idb_id =
     (select parent_id from idb_ph2_ip_v4address where idb_id = sbpi.ipv4adr))
     when tbpi.ip_method_assign = 'Динамический' then (select gateway_ip from idb_ph2_ip_v4range_private where idb_id =
     (select parent_id from idb_ph2_ip_v4address_private where idb_id = sbpi.ipv4adr))
     end) gateway_ipaddress
     , v_mac cpe_mac_address,
     tbpi.phase
      from idb_ph2_offers_oss_dic dic
           , idb_ph2_tbpi_int tbpi
           , idb_ph2_sbpi_int sbpi
           , idb_ph2_ne ne
      where 1=1
      and tbpi.phase = phase_id$i
        and dic.netaccess_mandatory != 'No'
        and dic.migration_category = 'Интернет'
        and dic.off_id_for_migr not in ('121000158', '121000450')
        and tbpi.off_id_for_migr = dic.off_id_for_migr
        and tbpi.source_system = P_CITY_ID
        and tbpi.source_system_type = '1'
        -- Возьмем только интернет
        and tbpi.idb_id LIKE 'TI_1/%' -- bikulov 19.11.2020
        and ne.idb_id = 'NE_' || tbpi.IDB_ID
        and sbpi.source_system_type = '1'
        and sbpi.off_id_for_migr IN ('121000102', '121000093')
        and sbpi.parent_id = tbpi.idb_id
        and ((sbpi.off_id_for_migr = '121000093' and sbpi.ipv6range IS NOT NULL) OR (sbpi.off_id_for_migr = '121000102' and sbpi.subnet is not null))
        and tbpi.ext_bpi_status != 'Disconnected' and sbpi.ext_bpi_status != 'Disconnected' -- bmdmax 07.10.2020
    ;
    TYPE t_arr_net_access_cur_chain_3 IS TABLE OF cur_chain_3%ROWTYPE;
    lv_arr_net_access_cur_chain_3 t_arr_net_access_cur_chain_3;
    
    cursor cur_chain_4(P_CITY_ID PLS_INTEGER) is
    with cr as (
     SELECT * FROM aak_tmp_cr_cities_all where source_system = P_CITY_ID
     )
     select
     cr.auth auth_type
     , bpi.idb_id bpi_idb_id
     , bpi.service_id bss_service_id
     , cr.diagnostics diagnostics
     , bpi.service_id event_source
     , cr.event_type event_type
     , replace(cr.ne, 'NE_', 'NEA_')||'/'||gol.login_name idb_id
     , cr.ip_method_assign ip_address_assignment_type
     , 'NA#'||bpi.service_id name
     , gol.terminal_resource_id nat
     , cr.network network_segment
     , cr.ne parent_id
     , cr.session_lookup session_lookup
     , gol.terminal_resource_id source_id
     , cr.source_system source_system
     , cr.source_system_type source_system_type

       , 
       --A.Kosterin 01.07.2021 убран кейс

         'AC_1' || '/' || bpi.idb_id
         service_credentials,
      -- bmdmax 26.11.2020 Добавил CASE
      CASE
        WHEN cr.auth IN ('DHCP Opt. 82 + Static IP',
                         'DHCP Opt. 82 Dynamic',
                         'IPoE NAT приватный IP (схема Интерзет)',
                         'IPoE NAT приватный + реальный IP (схема Интерзет)',
                         'IPoE реальный IP (схема Интерзет)') THEN
          gol.mac_address
        ELSE
          NULL
      END,
      CASE
        WHEN cr.auth IN ('DHCP Opt. 82 + Static IP',
                         'DHCP Opt. 82 Dynamic',
                         'IPoE NAT приватный IP (схема Интерзет)',
                         'IPoE NAT приватный + реальный IP (схема Интерзет)',
                         'IPoE реальный IP (схема Интерзет)') THEN
          gol.switch_mac
        ELSE
          NULL
      END,
      CASE
        WHEN cr.auth IN ('DHCP Opt. 82 + Static IP',
                         'DHCP Opt. 82 Dynamic',
                         'IPoE NAT приватный IP (схема Интерзет)',
                         'IPoE NAT приватный + реальный IP (схема Интерзет)',
                         'IPoE реальный IP (схема Интерзет)') THEN
          gol.switch_port
        ELSE
          NULL
      END,
      phase
    from
    --A.Kosterin 19.08.2021 внесение изменений в rownum шаг1

    (SELECT bpi.*, row_number() over (partition by to_number(source_id), source_system order by nom1, sbpi_rowid) as nom 
    FROM (
    select (SELECT rowid FROM dual) as sbpi_rowid, cr.idb_id idb_id, cr.service_id service_id, 1 nom1, cr.source_id, cr.source_system from cr
    union
    select sbpi.rowid as sbpi_rowid, sbpi.idb_id , sbpi.service_id, 2 nom1, cr.source_id, cr.source_system from idb_ph2_sbpi_int sbpi, cr
    where 1=1
    and sbpi.parent_id = cr.idb_id
    and sbpi.source_system = cr.source_system
    and sbpi.off_id_for_migr in ('121000087')
    and sbpi.ext_bpi_status != 'Disconnected' -- bmdmax 07.10.2020
    union
    select sbpi.rowid as sbpi_rowid, sbpi.idb_id , sbpi.service_id, 3 nom1, cr.source_id, cr.source_system from idb_ph2_sbpi_int sbpi, cr
    where 1=1
    and sbpi.parent_id = cr.idb_id
    and sbpi.source_system = cr.source_system
    and sbpi.off_id_for_migr in ('121000102')
    and sbpi.ext_bpi_status != 'Disconnected'
    ) bpi ) bpi,
    (
    select lo.login_name, ad.agreement_id, lp.mac_address, lp.switch_port, lp.switch_mac, lo.terminal_resource_id,
    cr.source_id, cr.source_system,
    row_number() over (partition by ar.addendum_id order by lo.login_name) rnum
    from addendum_resources_all ar
    , addenda_all ad
    , resource_contents_all rc
    , logins_all lo
    , login_properties_all lp
    , cr
    where 1=1
    and ar.billing_id = cr.source_system
    and ar.addendum_id = cr.source_id
    and ad.billing_id = ar.billing_id
    and ad.addendum_id = ar.addendum_id
    and ar.active_from <= current_date  -- add bmdmax 26.11.2020
    and coalesce(ar.active_to, current_date + 1) > current_date
    and rc.resource_id = ar.resource_id
    and rc.billing_id = ar.billing_id
    and rc.active_from <= current_date  -- add bmdmax 26.11.2020
    and coalesce(rc.active_to, current_date + 1) > current_date
    and lo.terminal_resource_id = rc.terminal_resource_id
    and lo.billing_id = rc.billing_id
    and lp.login_terminal_resource_id(+) = lo.terminal_resource_id
    and lp.billing_id(+) = lo.billing_id -- add bmdmax 26.11.2020
    ) gol
    , cr
    where bpi.nom = gol.rnum
    and bpi.source_id = cr.source_id
    and gol.source_id = bpi.source_id
    and bpi.source_system = cr.source_system
    and gol.source_system = bpi.source_system
    --and bpi.idb_id != 'SIFI_1/803/2625726/4038773/365860/39379303/V4AP/803/109.195.177.150'
    ;
TYPE t_arr_net_access_cur_chain_4_rec IS RECORD (
auth_type idb_ph2_net_access.auth_type%TYPE,
bpi_idb_id idb_ph2_net_access.bpi_idb_id%TYPE, 
bss_service_id idb_ph2_net_access.bss_service_id%TYPE,
diagnostics idb_ph2_net_access.diagnostics%TYPE, 
event_source idb_ph2_net_access.event_source%TYPE,
event_type idb_ph2_net_access.event_type%TYPE,
idb_id idb_ph2_net_access.idb_id%TYPE,
ip_address_assignment_type idb_ph2_net_access.ip_address_assignment_type%TYPE,
name idb_ph2_net_access.name%TYPE,
nat idb_ph2_net_access.nat%TYPE, 
network_segment idb_ph2_net_access.network_segment%TYPE,
parent_id idb_ph2_net_access.parent_id%TYPE,
session_lookup idb_ph2_net_access.session_lookup%TYPE,
source_id idb_ph2_net_access.source_id%TYPE, 
source_system idb_ph2_net_access.source_system%TYPE, 
source_system_type idb_ph2_net_access.source_system_type%TYPE,
service_credentials idb_ph2_net_access.service_credentials%TYPE,
cpe_mac_address idb_ph2_net_access.cpe_mac_address%TYPE, 
opt82_switch_mac_address idb_ph2_net_access.opt82_switch_mac_address%TYPE, 
opt82_switch_port idb_ph2_net_access.opt82_switch_port%TYPE, 
phase idb_ph2_net_access.phase%TYPE );
    TYPE t_arr_net_access_cur_chain_4 IS TABLE OF t_arr_net_access_cur_chain_4_rec;
    lv_arr_net_access_cur_chain_4 t_arr_net_access_cur_chain_4;
    
    procedure CHAIN_STEP1 is 
    begin
        for cr_city in (
    select to_char(city_id) city_id from idb_ph1_city_dic
    ) loop
     --вставка 1: Network Access for TLO (IP Address)
     
     open cur_chain_1(cr_city.city_id);
       LOOP
    FETCH cur_chain_1 BULK COLLECT
      INTO lv_arr_net_access_cur_chain LIMIT 1000;
    FORALL i IN 1 .. lv_arr_net_access_cur_chain.count
      INSERT into idb_ph2_net_access
        (assigned_ipv4addresses, assigned_ipv6addresses
         , auth_type,
         bpi_idb_id, bss_service_id,
         diagnostics, event_source, event_type,
         idb_id,
         ip_address_assignment_type,
         name,
         nat, network_segment,
         parent_id,
         session_lookup,
         source_id, source_system, source_system_type,
         gateway_ipaddress, cpe_mac_address,
         phase)
      VALUES
        (lv_arr_net_access_cur_chain(i).assigned_ipv4addresses, 
lv_arr_net_access_cur_chain(i).assigned_ipv6addresses,
lv_arr_net_access_cur_chain(i).auth_type,
lv_arr_net_access_cur_chain(i).bpi_idb_id, 
lv_arr_net_access_cur_chain(i).bss_service_id,
lv_arr_net_access_cur_chain(i).diagnostics, 
lv_arr_net_access_cur_chain(i).event_source, 
lv_arr_net_access_cur_chain(i).event_type,
lv_arr_net_access_cur_chain(i).idb_id,
lv_arr_net_access_cur_chain(i).ip_address_assignment_type,
lv_arr_net_access_cur_chain(i).name,
lv_arr_net_access_cur_chain(i).nat, 
lv_arr_net_access_cur_chain(i).network_segment,
lv_arr_net_access_cur_chain(i).parent_id,
lv_arr_net_access_cur_chain(i).session_lookup,
lv_arr_net_access_cur_chain(i).source_id, 
lv_arr_net_access_cur_chain(i).source_system, 
lv_arr_net_access_cur_chain(i).source_system_type,
lv_arr_net_access_cur_chain(i).gateway_ipaddress, 
lv_arr_net_access_cur_chain(i).cpe_mac_address,
lv_arr_net_access_cur_chain(i).phase);
    EXIT WHEN lv_arr_net_access_cur_chain.count = 0;
  END LOOP;
     close cur_chain_1;
      commit;
      end loop;
    end CHAIN_STEP1;
    
-----------
    procedure CHAIN_STEP2 is 
    begin
    for cr_city in (
    select to_char(city_id) city_id from idb_ph1_city_dic
    ) loop
    open cur_chain_2(cr_city.city_id);
       LOOP
    FETCH cur_chain_2 BULK COLLECT
      INTO lv_arr_net_access_cur_chain_2 LIMIT 1000;
    FORALL i IN 1 .. lv_arr_net_access_cur_chain_2.count
    --вставка 2: Network Access for SLO (IP Address)
       insert /*+ parallel (na,4)*/ into idb_ph2_net_access na
         (assigned_ipv4addresses, assigned_ipv6addresses
         , auth_type,
         bpi_idb_id, bss_service_id,
         diagnostics, event_source, event_type,
         idb_id,
         ip_address_assignment_type,
         name,
         nat, network_segment,
         parent_id,
         session_lookup,
         source_id, source_system, source_system_type,
         gateway_ipaddress, cpe_mac_address,
         phase
         )
         VALUES
        (lv_arr_net_access_cur_chain_2(i).assigned_ipv4addresses, 
lv_arr_net_access_cur_chain_2(i).assigned_ipv6addresses, 
lv_arr_net_access_cur_chain_2(i).auth_type,
lv_arr_net_access_cur_chain_2(i).bpi_idb_id, 
lv_arr_net_access_cur_chain_2(i).bss_service_id,
lv_arr_net_access_cur_chain_2(i).diagnostics, 
lv_arr_net_access_cur_chain_2(i).event_source, 
lv_arr_net_access_cur_chain_2(i).event_type,
lv_arr_net_access_cur_chain_2(i).idb_id,
lv_arr_net_access_cur_chain_2(i).ip_address_assignment_type,
lv_arr_net_access_cur_chain_2(i).name,
lv_arr_net_access_cur_chain_2(i).nat, 
lv_arr_net_access_cur_chain_2(i).network_segment,
lv_arr_net_access_cur_chain_2(i).parent_id,
lv_arr_net_access_cur_chain_2(i).session_lookup,
lv_arr_net_access_cur_chain_2(i).source_id, 
lv_arr_net_access_cur_chain_2(i).source_system, 
lv_arr_net_access_cur_chain_2(i).source_system_type,
lv_arr_net_access_cur_chain_2(i).gateway_ipaddress, 
lv_arr_net_access_cur_chain_2(i).cpe_mac_address,
lv_arr_net_access_cur_chain_2(i).phase);
    EXIT WHEN lv_arr_net_access_cur_chain_2.count = 0;
    END LOOP;
    close cur_chain_2;
      commit;
      end loop;

--17.05.2021
begin
update idb_ph2_tbpi_int t set
t.initial_real_cost = (SELECT   
             round(sum(e.expenses_number*e.expenses_unit_cost),2)*100000

        FROM expenses_all e, Material_Types_all mt, materials_all m

       WHERE e.teo_id = migr_supp_chernov_new.get_teo(point       => substr(idb_id,instr(idb_id,'/',-1)+1,999),
                                                        vbilling_id => t.source_system,
                                                        addendum    => t.source_id) and e.billing_id = t.source_system
         And m.Attr_Entity_Id = e.Attr_Entity_Id and m.billing_id = e.billing_id
         And m.material_types_id = mt.material_types_id and m.billing_id = mt.billing_id
         And m.material_types_id not in (5,26,37,38,39) group by e.teo_id)
where 
t.idb_id like 'TI_1/%' and phase = phase_id$i;

update idb_ph2_tbpi_int t set
t.INITIAL_INSTALL_FEE = NVL((select round(t1.value_w_nds,2) * 100000 from (select s.value_w_nds from charges_all s where 
s.billing_id = t.source_system and 
s.addendum_id = t.source_id and 
s.service_id in (163,1298) order by s.sa_import_date) t1 where rownum = 1),'666')
where 
t.idb_id like 'TI_1/%' and initial_real_cost is not null and t.phase = phase_id$i;





update idb_ph2_tbpi_int t set
t.initial_payback_period = 
nvl((case
when NVL(ceil(chernov_migr.get_int_parameters_from_serv(v_teo     => migr_supp_chernov_new.get_teo(point       => substr(idb_id,instr(idb_id,'/',-1)+1,999),
                                                        vbilling_id => t.source_system,
                                                        addendum    => t.source_id),
v_prop    => 195,
v_billing => t.source_system)),ceil(chernov_migr.get_int_parameters_from_serv(v_teo     => migr_supp_chernov_new.get_teo(point       => substr(idb_id,instr(idb_id,'/',-1)+1,999),
                                                        vbilling_id => t.source_system,
                                                        addendum    => t.source_id),
v_prop    => 194,
v_billing => t.source_system))) is not null and NVL(ceil(chernov_migr.get_int_parameters_from_serv(v_teo     => migr_supp_chernov_new.get_teo(point       => substr(idb_id,instr(idb_id,'/',-1)+1,999),
                                                        vbilling_id => t.source_system,
                                                        addendum    => t.source_id),
v_prop    => 195,
v_billing => t.source_system)),ceil(chernov_migr.get_int_parameters_from_serv(v_teo     => migr_supp_chernov_new.get_teo(point       => substr(idb_id,instr(idb_id,'/',-1)+1,999),
                                                        vbilling_id => t.source_system,
                                                        addendum    => t.source_id),
v_prop    => 194,
v_billing => t.source_system))) != 0 then
NVL(ceil(chernov_migr.get_int_parameters_from_serv(v_teo     => migr_supp_chernov_new.get_teo(point       => substr(idb_id,instr(idb_id,'/',-1)+1,999),
                                                        vbilling_id => t.source_system,
                                                        addendum    => t.source_id),
v_prop    => 195,
v_billing => t.source_system)),ceil(chernov_migr.get_int_parameters_from_serv(v_teo     => migr_supp_chernov_new.get_teo(point       => substr(idb_id,instr(idb_id,'/',-1)+1,999),
                                                        vbilling_id => t.source_system,
                                                        addendum    => t.source_id),
v_prop    => 194,
v_billing => t.source_system)))
else 18
end),666)
where t.phase = phase_id$i and 
t.idb_id like 'TI_1/%' and initial_real_cost is not null and INITIAL_INSTALL_FEE is not null;



update 
idb_ph2_tbpi_int
set initial_real_cost = null, INITIAL_INSTALL_FEE=null,initial_payback_period=null
where idb_id like 'TI_1%' and (INITIAL_INSTALL_FEE = 666 OR initial_payback_period = 666) and phase = phase_id$i;

--A.Kosterin 09.12.2021 del delete
--delete from idb_ph2_productstatus where parent_id = 'TI_1/2/4814362/10140595/127918' and phase = phase_id$i;
end;
    end CHAIN_STEP2;
    
-----------
    procedure CHAIN_STEP3 is 
    begin
    for cr_city in (
    select to_char(city_id) city_id from idb_ph1_city_dic
    ) loop
    open cur_chain_3(cr_city.city_id);
       LOOP
    FETCH cur_chain_3 BULK COLLECT
      INTO lv_arr_net_access_cur_chain_3 LIMIT 1000;
    FORALL i IN 1 .. lv_arr_net_access_cur_chain_3.count
        --вставка 3: Network Access for SLO (IP Subnet)
       insert /*+ parallel (na,4)*/ into idb_ph2_net_access na
         (assigned_ipv4addresses, assigned_ipv6addresses
         , auth_type,
         bpi_idb_id, bss_service_id,
         diagnostics, event_source, event_type,
         idb_id,
         ip_address_assignment_type,
         name,
         nat, network_segment,
         parent_id,
         session_lookup,
         source_id, source_system, source_system_type,
         gateway_ipaddress, cpe_mac_address,
         phase
         ) VALUES (
         lv_arr_net_access_cur_chain_3(i).assigned_ipv4addresses, 
lv_arr_net_access_cur_chain_3(i).assigned_ipv6addresses, 
lv_arr_net_access_cur_chain_3(i).auth_type,
lv_arr_net_access_cur_chain_3(i).bpi_idb_id, 
lv_arr_net_access_cur_chain_3(i).bss_service_id,
lv_arr_net_access_cur_chain_3(i).diagnostics, 
lv_arr_net_access_cur_chain_3(i).event_source, 
lv_arr_net_access_cur_chain_3(i).event_type,
lv_arr_net_access_cur_chain_3(i).idb_id,
lv_arr_net_access_cur_chain_3(i).ip_address_assignment_type,
lv_arr_net_access_cur_chain_3(i).name,
lv_arr_net_access_cur_chain_3(i).nat, 
lv_arr_net_access_cur_chain_3(i).network_segment,
lv_arr_net_access_cur_chain_3(i).parent_id,
lv_arr_net_access_cur_chain_3(i).session_lookup,
lv_arr_net_access_cur_chain_3(i).source_id, 
lv_arr_net_access_cur_chain_3(i).source_system, 
lv_arr_net_access_cur_chain_3(i).source_system_type,
lv_arr_net_access_cur_chain_3(i).gateway_ipaddress, 
lv_arr_net_access_cur_chain_3(i).cpe_mac_address,
lv_arr_net_access_cur_chain_3(i).phase);
    EXIT WHEN lv_arr_net_access_cur_chain_3.count = 0;
    END LOOP;
    close cur_chain_3;
    commit;
    end loop;
    
    end CHAIN_STEP3;  
    
-----------
    procedure CHAIN_STEP4 is 
    --вставка 4: Network Access for TLO/SLO (Login)
    begin
        begin
  OPEN cr_cur_net_access;
  LOOP
    FETCH cr_cur_net_access BULK COLLECT
      INTO lv_arr_net_access_cur LIMIT 1000;
    FORALL i IN 1 .. lv_arr_net_access_cur.count
      INSERT INTO aak_tmp_cr_cities_all
        (cr_row,
         idb_id,
         incl_ip4addr,
         auth_type,
         ip_method_assign,
         network,
         ne,
         service_id,
         source_id,
         source_system,
         source_system_type,
         event_type,
         diagnostics,
         session_lookup,
         off_id_for_migr,
         auth,
         phase)
      VALUES
        (lv_arr_net_access_cur(i).cr_row,
         lv_arr_net_access_cur(i).idb_id,
         lv_arr_net_access_cur(i).incl_ip4addr,
         lv_arr_net_access_cur(i).auth_type,
         lv_arr_net_access_cur(i).ip_method_assign,
         lv_arr_net_access_cur(i).network,
         lv_arr_net_access_cur(i).ne,
         lv_arr_net_access_cur(i).service_id,
         lv_arr_net_access_cur(i).source_id,
         lv_arr_net_access_cur(i).source_system,
         lv_arr_net_access_cur(i).source_system_type,
         lv_arr_net_access_cur(i).event_type,
         lv_arr_net_access_cur(i).diagnostics,
         lv_arr_net_access_cur(i).session_lookup,
         lv_arr_net_access_cur(i).off_id_for_migr,
         lv_arr_net_access_cur(i).auth,
         lv_arr_net_access_cur(i).phase);
    EXIT WHEN lv_arr_net_access_cur.count = 0;
  END LOOP;
  CLOSE cr_cur_net_access;
end;

    for cr_city in (
    select to_char(city_id) city_id from idb_ph1_city_dic
    ) loop
    open cur_chain_4(cr_city.city_id);
      LOOP
    FETCH cur_chain_4 BULK COLLECT
      INTO lv_arr_net_access_cur_chain_4 LIMIT 1000;
    FORALL i IN 1 .. lv_arr_net_access_cur_chain_4.count
     --вставка 4: Network Access for TLO/SLO (Login)
     insert /*+ parallel (na,4)*/ into idb_ph2_net_access na
    (auth_type,
     bpi_idb_id, bss_service_id,
     diagnostics, event_source,
     event_type,
     idb_id,
     ip_address_assignment_type,
     name,
     nat, network_segment,
     parent_id,
     session_lookup,
     source_id, source_system, source_system_type,
     service_credentials,
     cpe_mac_address, opt82_switch_mac_address, opt82_switch_port, phase)
     VALUES (lv_arr_net_access_cur_chain_4(i).auth_type,
lv_arr_net_access_cur_chain_4(i).bpi_idb_id, 
lv_arr_net_access_cur_chain_4(i).bss_service_id,
lv_arr_net_access_cur_chain_4(i).diagnostics, 
lv_arr_net_access_cur_chain_4(i).event_source,
lv_arr_net_access_cur_chain_4(i).event_type,
lv_arr_net_access_cur_chain_4(i).idb_id,
lv_arr_net_access_cur_chain_4(i).ip_address_assignment_type,
lv_arr_net_access_cur_chain_4(i).name,
lv_arr_net_access_cur_chain_4(i).nat, 
lv_arr_net_access_cur_chain_4(i).network_segment,
lv_arr_net_access_cur_chain_4(i).parent_id,
lv_arr_net_access_cur_chain_4(i).session_lookup,
lv_arr_net_access_cur_chain_4(i).source_id, 
lv_arr_net_access_cur_chain_4(i).source_system, 
lv_arr_net_access_cur_chain_4(i).source_system_type,
lv_arr_net_access_cur_chain_4(i).service_credentials,
lv_arr_net_access_cur_chain_4(i).cpe_mac_address, 
lv_arr_net_access_cur_chain_4(i).opt82_switch_mac_address, 
lv_arr_net_access_cur_chain_4(i).opt82_switch_port, 
lv_arr_net_access_cur_chain_4(i).phase);
     
    EXIT WHEN lv_arr_net_access_cur_chain_4.count = 0;
    END LOOP;
    close cur_chain_4;
    commit;
    end loop;
    end CHAIN_STEP4;
    
procedure start_chains is
  job_cnt PLS_INTEGER;
  begin
    DBMS_SCHEDULER.CREATE_JOB (
            job_name => 'CHAIN_FILL_NET_ACCESS_JOB',
            job_type => 'CHAIN',
            job_action => 'CHAIN_FILL_NET_ACCESS',
            number_of_arguments => 0,
            start_date => NULL,
            repeat_interval => NULL,
            end_date => NULL,
            enabled => TRUE,
            auto_drop => TRUE,
            comments => '');

    DBMS_SCHEDULER.SET_ATTRIBUTE( 
             name => 'CHAIN_FILL_NET_ACCESS_JOB', 
             attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_RUNS);
  WHILE TRUE
  LOOP
    dbms_lock.sleep (10);
    SELECT count(1) INTO job_cnt FROM dba_scheduler_running_jobs j
    WHERE j.job_name = 'CHAIN_FILL_NET_ACCESS_JOB';
    EXIT WHEN job_cnt = 0;
  END LOOP;
end start_chains;
    
end fill_net_access_chain;
/

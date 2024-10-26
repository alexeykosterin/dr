DECLARE
	--================================CREATE RULE================================
    PROCEDURE create_rule
	(
		pi_rule_name 			VARCHAR2, 
		pi_description 			VARCHAR2, 
		pi_folder 				VARCHAR2,
		pi_rule_definition		VARCHAR2,
		pi_return_value			VARCHAR2,
		pi_rule_proc			VARCHAR2,
		pi_keyword_name			VARCHAR2
	)	
    IS	
        l_rule_cpr_id 			NUMBER;
        l_product_rule_id 		NUMBER;
    BEGIN
        l_rule_cpr_id := insis_gen_cfg_v10.cpr_rules_seq.nextval + 3180000000;
        INSERT INTO insis_gen_cfg_v10.cpr_rules 
        (
            rule_cpr_id,
            rule_code,
            folder,
            description,
            valid_from,
            valid_to,
            resgistration_date,
            validated
        ) 
        VALUES 
        (
            l_rule_cpr_id,
            pi_rule_name,
            pi_folder,
            pi_description,
            to_date('01.01.2000 00:00:00','DD.MM.YYYY HH24:MI:SS'),
            to_date('01.01.2300 00:00:00','DD.MM.YYYY HH24:MI:SS'),
            to_date(sysdate,'DD.MM.YYYY HH24:MI:SS'),
            'Y'
        );
    
        INSERT INTO insis_gen_cfg_v10.cprs_rule_definition 
        (
            rule_cpr_id,
            rule,
            return_value,
            rule_order,
            rule_proc
        ) 
        VALUES 
        (
            l_rule_cpr_id,
            pi_rule_definition,
            pi_return_value,
            '1',
            pi_rule_proc
        );
		
		INSERT INTO insis_gen_cfg_v10.cprs_rule_validation_results 
        (
            rule_cpr_id,
            keyword_link_id
        ) 
        (
            
            SELECT (SELECT rule_cpr_id FROM insis_gen_cfg_v10.cpr_rules WHERE rule_code = pi_rule_name),
                keyword_link_id
            FROM insis_gen_cfg_v10.syscfg_rule_keywords 
            WHERE keyword = pi_keyword_name
        );
    END;
	--================================REMOVE RULE================================
    PROCEDURE remove_rule(pi_rule_name VARCHAR2)
    AS
    BEGIN
        DELETE FROM insis_gen_cfg_v10.cprs_rule_definition 
		WHERE rule_cpr_id = 
			(
				SELECT rule_cpr_id 
				FROM insis_gen_cfg_v10.cpr_rules WHERE rule_code = pi_rule_name
			);
			
		DELETE FROM insis_gen_cfg_v10.cprs_rule_validation_results
		WHERE rule_cpr_id = 
			(
				SELECT rule_cpr_id 
				FROM insis_gen_cfg_v10.cpr_rules WHERE rule_code = pi_rule_name
			);
			
        DELETE FROM insis_gen_cfg_v10.cpr_rules 
		WHERE rule_code = pi_rule_name;
    END;
BEGIN
	--ROLLBACK
	remove_rule('GDPR_RANDOM_XML');
	remove_rule('GDPR_RANDOM_TEXT_SHORT');
	remove_rule('GDPR_RANDOM_TEXT');
	remove_rule('GDPR_RANDOM_DATE');
	remove_rule('GDPR_RANDOM_NUMBER');
	
	insis_sgi_dev.config_support.remove_keyword(pi_keyword_name => 'GDPR_RANDOM_XML_KW');
	insis_sgi_dev.config_support.remove_keyword(pi_keyword_name => 'GDPR_RANDOM_TEXT_SHORT_KW');
	insis_sgi_dev.config_support.remove_keyword(pi_keyword_name => 'GDPR_RANDOM_TEXT_KW');
	insis_sgi_dev.config_support.remove_keyword(pi_keyword_name => 'GDPR_RANDOM_NUMBER_KW');
	insis_sgi_dev.config_support.remove_keyword(pi_keyword_name => 'GDPR_RANDOM_DATE_KW');
	
	--UPDATE
	insis_sgi_dev.config_support.create_keyword
    (
        pi_keyword_name 	=> 'GDPR_RANDOM_XML_KW', 
        pi_keyword_text 	=> 
'SELECT ''<'' || dbms_random.string(''a'', 10) || ''/>''
FROM dual',
        pi_data_type 		=> 'CHAR',
        pi_keyword_type 	=> 'W'
    );
	
	insis_sgi_dev.config_support.create_keyword
    (
        pi_keyword_name 	=> 'GDPR_RANDOM_TEXT_KW', 
        pi_keyword_text 	=> 
'SELECT dbms_random.string(''a'', 30) 
FROM dual',
        pi_data_type 		=> 'CHAR',
        pi_keyword_type 	=> 'W'
    );
	
	insis_sgi_dev.config_support.create_keyword
    (
        pi_keyword_name 	=> 'GDPR_RANDOM_TEXT_SHORT_KW', 
        pi_keyword_text 	=> 
'SELECT dbms_random.string(''a'', 10) 
FROM dual',
        pi_data_type 		=> 'CHAR',
        pi_keyword_type 	=> 'W'
    );
	
	insis_sgi_dev.config_support.create_keyword
    (
        pi_keyword_name 	=> 'GDPR_RANDOM_NUMBER_KW', 
        pi_keyword_text 	=> 
'SELECT floor(dbms_random.value(1, 1000000000))
FROM dual',
        pi_data_type 		=> 'CHAR',
        pi_keyword_type 	=> 'W'
    );
	
	insis_sgi_dev.config_support.create_keyword
    (
        pi_keyword_name 	=> 'GDPR_RANDOM_DATE_KW', 
        pi_keyword_text 	=> 
'SELECT to_char(to_date(trunc(dbms_random.value(to_char(to_date(''01.01.1900'', ''dd.mm.yyyy''), ''J''), to_char(sysdate, ''J''))), ''J''), ''dd.mm.yyyy'')
FROM dual',
        pi_data_type 		=> 'CHAR',
        pi_keyword_type 	=> 'W'
    );
	
	create_rule
	(
		pi_rule_name 			=> 'GDPR_RANDOM_XML', 
		pi_description 			=> 'Rule to return random XML for INSIS GDPR module', 
		pi_folder 				=> 'GDPR',
		pi_rule_definition		=> '1 = 1',
		pi_return_value			=> 'EXPRESSION(GDPR_RANDOM_XML_KW)',
		pi_rule_proc			=> NULL,
		pi_keyword_name			=> 'GDPR_RANDOM_XML_KW'
	);
	
	create_rule
	(
		pi_rule_name 			=> 'GDPR_RANDOM_TEXT', 
		pi_description 			=> 'Rule to return random text for INSIS GDPR module', 
		pi_folder 				=> 'GDPR',
		pi_rule_definition		=> '1 = 1',
		pi_return_value			=> 'EXPRESSION(GDPR_RANDOM_TEXT_KW)',
		pi_rule_proc			=> NULL,
		pi_keyword_name			=> 'GDPR_RANDOM_TEXT_KW'
	);
	
	create_rule
	(
		pi_rule_name 			=> 'GDPR_RANDOM_TEXT_SHORT', 
		pi_description 			=> 'Rule to return random text (10 char) for INSIS GDPR module', 
		pi_folder 				=> 'GDPR',
		pi_rule_definition		=> '1 = 1',
		pi_return_value			=> 'EXPRESSION(GDPR_RANDOM_TEXT_SHORT_KW)',
		pi_rule_proc			=> NULL,
		pi_keyword_name			=> 'GDPR_RANDOM_TEXT_SHORT_KW'
	);
	
	create_rule
	(
		pi_rule_name 			=> 'GDPR_RANDOM_DATE', 
		pi_description 			=> 'Rule to return random date for INSIS GDPR module', 
		pi_folder 				=> 'GDPR',
		pi_rule_definition		=> '1 = 1',
		pi_return_value			=> 'EXPRESSION(GDPR_RANDOM_DATE_KW)',
		pi_rule_proc			=> NULL,
		pi_keyword_name			=> 'GDPR_RANDOM_DATE_KW'
	);
	
	create_rule
	(
		pi_rule_name 			=> 'GDPR_RANDOM_NUMBER', 
		pi_description 			=> 'Rule to return random number for INSIS GDPR module', 
		pi_folder 				=> 'GDPR',
		pi_rule_definition		=> '1 = 1',
		pi_return_value			=> 'EXPRESSION(GDPR_RANDOM_NUMBER_KW)',
		pi_rule_proc			=> NULL,
		pi_keyword_name			=> 'GDPR_RANDOM_NUMBER_KW'
	);
	
	UPDATE insis_gdpr.cfg_country_claim_ret_periods
	SET duration = 5
	WHERE country_id = 'DF';
	
	UPDATE insis_gdpr.cfg_country_pol_ret_periods
	SET duration = 5
	WHERE country_id = 'DF';
	
	UPDATE insis_gdpr.cfg_parameters
	SET long_text =
'SELECT ppl.man_id,
	''Expired policy client'' AS reason
FROM insis_people_v10.p_people ppl
	INNER JOIN insis_gdpr.cfg_country_pol_ret_periods ret ON ret.country_id = ''DF''
WHERE ppl.man_comp = 1
	AND add_months
	(
		(
			SELECT max(p.insr_end)
			FROM insis_gen_v10.policy p
				INNER JOIN insis_gen_v10.p_clients pc ON pc.client_id = p.client_id
			WHERE pc.man_id = ppl.man_id
				AND p.policy_state NOT IN (0, 11, 12)
		),
		12 * ret.duration
	) < :AS_EXEC_DATE
	AND ppl.man_id in (select SRC_ID from INSIS_CUST.VW_MV_DWH_PDN_MAN_ID WHERE src_id LIKE ''600%'')
	AND NOT EXISTS (select MAN_ID from INSIS_GDPR.PI_OPERATIONS pio WHERE ppl.man_id = pio.man_id AND STATUS = ''C'')
UNION
SELECT ppl.man_id,
	''Expired policy participant'' AS reason
FROM insis_people_v10.p_people ppl
	INNER JOIN insis_gdpr.cfg_country_pol_ret_periods ret ON ret.country_id = ''DF''
WHERE ppl.man_comp = 1
	AND add_months
	(
		(
			SELECT max(p.insr_end)
			FROM insis_gen_v10.policy p
				INNER JOIN insis_gen_v10.policy_participants pp ON pp.policy_id = p.policy_id
			WHERE pp.man_id = ppl.man_id
				AND p.policy_state NOT IN (0, 11, 12)
		),
		12 * ret.duration
	) < :AS_EXEC_DATE
	AND ppl.man_id in (select SRC_ID from INSIS_CUST.VW_MV_DWH_PDN_MAN_ID WHERE src_id LIKE ''600%'')
	AND NOT EXISTS (select MAN_ID from INSIS_GDPR.PI_OPERATIONS pio WHERE ppl.man_id = pio.man_id AND STATUS = ''C'')
UNION
SELECT ppl.man_id,
	''Expired policy insured'' AS reason
FROM insis_people_v10.p_people ppl
	INNER JOIN insis_gdpr.cfg_country_pol_ret_periods ret ON ret.country_id = ''DF''
WHERE ppl.man_comp = 1
	AND add_months
	(
		(
			SELECT max(p.insr_end)
			FROM insis_gen_v10.policy p
				INNER JOIN insis_gen_v10.insured_object io ON io.policy_id = p.policy_id
				INNER JOIN insis_gen_v10.o_accinsured acc ON acc.object_id = io.object_id
			WHERE acc.man_id = ppl.man_id
				AND p.policy_state NOT IN (0, 11, 12)
		),
		12 * ret.duration
	) < :AS_EXEC_DATE
	AND ppl.man_id in (select SRC_ID from INSIS_CUST.VW_MV_DWH_PDN_MAN_ID WHERE src_id LIKE ''600%'')
	AND NOT EXISTS (select MAN_ID from INSIS_GDPR.PI_OPERATIONS pio WHERE ppl.man_id = pio.man_id AND STATUS = ''C'')
UNION
SELECT ppl.man_id,
	''Expired policy object owner'' AS reason
FROM insis_people_v10.p_people ppl
	INNER JOIN insis_gdpr.cfg_country_pol_ret_periods ret ON ret.country_id = ''DF''
WHERE ppl.man_comp = 1
	AND add_months
	(
		(
			SELECT max(p.insr_end)
			FROM insis_gen_v10.policy p
				INNER JOIN insis_gen_v10.insured_object io ON io.policy_id = p.policy_id
				INNER JOIN insis_gen_v10.o_object_owners own ON own.object_id = io.object_id
			WHERE own.owner_id = ppl.man_id
				AND p.policy_state NOT IN (0, 11, 12)
		),
		12 * ret.duration
	) < :AS_EXEC_DATE
	AND ppl.man_id in (select SRC_ID from INSIS_CUST.VW_MV_DWH_PDN_MAN_ID WHERE src_id LIKE ''600%'')
	AND NOT EXISTS (select MAN_ID from INSIS_GDPR.PI_OPERATIONS pio WHERE ppl.man_id = pio.man_id AND STATUS = ''C'')
UNION
SELECT ppl.man_id,
	''Expired policy object person'' AS reason
FROM insis_people_v10.p_people ppl
	INNER JOIN insis_gdpr.cfg_country_pol_ret_periods ret ON ret.country_id = ''DF''
WHERE ppl.man_comp = 1
	AND add_months
	(
		(
			SELECT max(p.insr_end)
			FROM insis_gen_v10.policy p
				INNER JOIN insis_gen_v10.insured_object io ON io.policy_id = p.policy_id
				INNER JOIN insis_gen_v10.o_object_persons pers ON pers.object_id = io.object_id
			WHERE pers.man_id = ppl.man_id
				AND p.policy_state NOT IN (0, 11, 12)
		),
		12 * ret.duration
	) < :AS_EXEC_DATE
	AND ppl.man_id in (select SRC_ID from INSIS_CUST.VW_MV_DWH_PDN_MAN_ID WHERE src_id LIKE ''600%'')
	AND NOT EXISTS (select MAN_ID from INSIS_GDPR.PI_OPERATIONS pio WHERE ppl.man_id = pio.man_id AND STATUS = ''C'')'
	WHERE id = 'BATCH_DRIVING_QUERY';
END;
/

ALTER TABLE insis_gdpr.ht_pi_data DROP CONSTRAINT ht_pi_data_uq
/

ALTER TABLE insis_gdpr.ht_pi_data ADD CONSTRAINT ht_pi_data_uq UNIQUE (schema_name, table_name, name) ENABLE
/

ALTER TABLE insis_gdpr.cfg_pi_root_tables DROP CONSTRAINT cfg_pi_root_tables_uq
/

ALTER TABLE insis_gdpr.cfg_pi_root_tables ADD CONSTRAINT cfg_pi_root_tables_uq UNIQUE (root_owner, root_table, root_where_filter) ENABLE
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX insis_cust.hist_doc_documents_doc_seq';
    
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX insis_cust.hist_doc_documents_man_id';
    
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX insis_cust.blc_bank_st_lines_party_ben_id';
    
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX insis_cust.blc_bank_st_lines_party_ord_id';
    
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX insis_cust.blc_gl_insis2gl_dr10';
    
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
END;
/

CREATE INDEX insis_cust.hist_doc_documents_man_id ON insis_sys_v10.hist_doc_documents(man_id) TABLESPACE INDX
/

CREATE INDEX insis_cust.blc_bank_st_lines_party_ben_id ON insis_gen_blc_v10.blc_bank_statement_lines(party_id_ben) TABLESPACE INDX


CREATE INDEX insis_cust.blc_bank_st_lines_party_ord_id ON insis_gen_blc_v10.blc_bank_statement_lines(party_id_ord) TABLESPACE INDX
/

CREATE INDEX insis_cust.blc_gl_insis2gl_dr10 ON insis_gen_blc_v10.blc_gl_insis2gl(dr_segment10) TABLESPACE INDX
/

GRANT SELECT ON insis_gen_v10.o_object_owners TO insis_sgi_dev
/

GRANT SELECT ON insis_gen_v10.o_object_persons TO insis_sgi_dev
/
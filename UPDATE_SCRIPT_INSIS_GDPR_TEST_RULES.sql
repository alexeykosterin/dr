DECLARE
	--================================ADD TABLE RULE================================
    PROCEDURE create_table_rule
	(
		pi_rule_name			IN VARCHAR2,
		pi_root_table_schema	IN VARCHAR2,
		pi_root_table_name		IN VARCHAR2,
		pi_root_where_filter	IN VARCHAR2,
		pi_root_column_name		IN VARCHAR2,
		pi_target_table_schema	IN VARCHAR2,
		pi_target_table_name	IN VARCHAR2,
		pi_leaf_join_tables		IN VARCHAR2,
		pi_leaf_join_conditions	IN VARCHAR2
	)
    IS	
        l_root_id 		insis_gdpr.cfg_pi_root_tables.root_id%TYPE;
		
		l_pi_data_id	insis_gdpr.ht_pi_data.pi_data_id%TYPE;
		l_order_id		insis_gdpr.ht_pi_data.order_id%TYPE;
    BEGIN
		BEGIN
			SELECT root_id
			INTO l_root_id
			FROM insis_gdpr.cfg_pi_root_tables
			WHERE upper(root_owner) = upper(pi_root_table_schema)
				AND upper(root_table) = upper(pi_root_table_name)
				AND upper(root_where_filter) = upper(pi_root_where_filter);
			
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					l_root_id := NULL;
		END;
		
		IF l_root_id IS NULL
		THEN
			SELECT coalesce(max(root_id), 0) + 1
			INTO l_root_id
			FROM insis_gdpr.cfg_pi_root_tables;
			
			INSERT INTO insis_gdpr.cfg_pi_root_tables
			(
				root_id,
				root_owner,
				root_table,
				root_where_filter
			)
			VALUES
			(
				l_root_id,
				upper(pi_root_table_schema),
				upper(pi_root_table_name),
				pi_root_where_filter
			);
			
			INSERT INTO insis_gdpr.cfg_pi_root_filter
			(
				root_id,
				column_name,
				context_attrib_name,
				data_type,
				data_type_format
			)
			VALUES
			(
				l_root_id,
				upper(pi_root_column_name),
				upper(pi_root_column_name),
				NULL,
				NULL
			);
		END IF;
		
		SELECT coalesce(max(order_id), 0) + 1
		INTO l_order_id
		FROM insis_gdpr.ht_pi_data;
					
		INSERT INTO insis_gdpr.ht_pi_data
		(
			pi_data_id,
			name,
			schema_name,
			table_name,
			active,
			order_id
		)
		VALUES
		(
			insis_gdpr.ht_pi_data_seq.nextval,
			upper(pi_rule_name),
			upper(pi_target_table_schema),
			upper(pi_target_table_name),
			'Y',
			l_order_id
		)
		RETURNING pi_data_id INTO l_pi_data_id;
				
		
		INSERT INTO insis_gdpr.cfg_pi_data_markup
		(
			rel_id,
			pi_data_id,
			root_id,
			leaf_join_tables,
			leaf_join_conditions
		)
		VALUES
		(
			insis_gdpr.cfg_pi_data_markup_seq.nextval,
			l_pi_data_id,
			l_root_id,
			upper(pi_leaf_join_tables),
			upper(pi_leaf_join_conditions)
		);
    END;
	--================================ADD TABLE COLUMN RULE================================
    PROCEDURE create_table_column_rule
	(
		pi_rule_name				IN VARCHAR2,
		pi_column_name				IN VARCHAR2,
		pi_masking_pattern			IN VARCHAR2,
		pi_data_type				IN VARCHAR2,
		pi_data_type_format			IN VARCHAR2,
		pi_value_by_rule			IN VARCHAR2,
		pi_continue_if_rule_fails	IN VARCHAR2
	)
    IS	
        l_rel_id 		insis_gdpr.cfg_pi_data_markup.rel_id%TYPE;
    BEGIN
		SELECT dm.rel_id
		INTO l_rel_id
		FROM insis_gdpr.ht_pi_data pd
			INNER JOIN insis_gdpr.cfg_pi_data_markup dm ON dm.pi_data_id = pd.pi_data_id
		WHERE upper(pd.name) = upper(pi_rule_name);
			
		INSERT INTO insis_gdpr.cfg_pi_leaf_columns
		(
			rel_id,
			column_name,
			masking_pattern,
			data_type,
			data_type_format,
			value_by_rule,
			continue_if_rule_fails
		)
		VALUES
		(
			l_rel_id,
			pi_column_name,
			pi_masking_pattern,
			pi_data_type,
			pi_data_type_format,
			pi_value_by_rule,
			pi_continue_if_rule_fails
		);
		
		insis_gdpr.pi_data_manipulator.rebuildConfig(pi_rel_id => l_rel_id);
	END;
	--================================REMOVE RI RULE================================
    PROCEDURE remove_table_rule
	(
		pi_rule_name		IN VARCHAR2
	)
    AS
		l_rel_id 		insis_gdpr.cfg_pi_data_markup.rel_id%TYPE;
		l_root_id 		insis_gdpr.cfg_pi_root_tables.root_id%TYPE;
		l_pi_data_id	insis_gdpr.ht_pi_data.pi_data_id%TYPE;
    BEGIN
		BEGIN
			SELECT dm.rel_id,
				pd.pi_data_id,
				dm.root_id
			INTO l_rel_id,
				l_pi_data_id,
				l_root_id
			FROM insis_gdpr.ht_pi_data pd
				INNER JOIN insis_gdpr.cfg_pi_data_markup dm ON dm.pi_data_id = pd.pi_data_id
			WHERE upper(pd.name) = upper(pi_rule_name);
				
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					RETURN;
		END;
			
        DELETE FROM insis_gdpr.cfg_pi_leaf_columns
		WHERE rel_id = l_rel_id;
		
		DELETE FROM insis_gdpr.cfg_pi_data_markup
		WHERE rel_id = l_rel_id;
		
		DELETE FROM insis_gdpr.ht_pi_data pd
		WHERE pd.pi_data_id = l_pi_data_id
			AND NOT EXISTS
			(
				SELECT 1
				FROM insis_gdpr.cfg_pi_data_markup dm
				WHERE dm.pi_data_id = pd.pi_data_id
			);
			
		DELETE FROM insis_gdpr.cfg_pi_root_filter rf
		WHERE rf.root_id = l_root_id
			AND NOT EXISTS
			(
				SELECT 1
				FROM insis_gdpr.cfg_pi_data_markup dm
				WHERE dm.root_id = rf.root_id
			);
			
		DELETE FROM insis_gdpr.cfg_pi_root_tables rt
		WHERE rt.root_id = l_root_id
			AND NOT EXISTS
			(
				SELECT 1
				FROM insis_gdpr.cfg_pi_data_markup dm
				WHERE dm.root_id = rt.root_id
			);
    END;
BEGIN
	--ROLLBACK
	remove_table_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID TEXT'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID DATE'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID LIST'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.GEN_ANNEX'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.GEN_ANNEX_INFO'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_LOG'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.INTRF_KAFKA_INTEGRATION_OUT'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_INSTALLMENTS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_REMITTANCES'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_PAYMENTS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_BEN'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_ORD'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_CONTACTS_CHANGES'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_CONTACTS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_CONTACTS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE'
	);
	
	remove_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE'
	);
	
	--UPDATE
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_target_table_name		=> 'P_PEOPLE',
		pi_leaf_join_tables			=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'BIRTH_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'FNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'GNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'SNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'NATIONALITY',
		pi_masking_pattern			=> 'РФ',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'ATTR1',
		pi_masking_pattern			=> '111111111111',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE',
		pi_column_name				=> 'SEX',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'HIST_P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.HIST_P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_target_table_name		=> 'HIST_P_PEOPLE',
		pi_leaf_join_tables			=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_column_name				=> 'BIRTH_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_column_name				=> 'FNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_column_name				=> 'GNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_column_name				=> 'SNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_column_name				=> 'NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_column_name				=> 'NATIONALITY',
		pi_masking_pattern			=> 'РФ',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_PEOPLE',
		pi_column_name				=> 'ATTR1',
		pi_masking_pattern			=> '111111111111',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE_CHANGES',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE_CHANGES.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_target_table_name		=> 'P_PEOPLE_CHANGES',
		pi_leaf_join_tables			=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'BIRTH_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'FNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'GNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'SNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'NATIONALITY',
		pi_masking_pattern			=> 'РФ',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'ATTR1',
		pi_masking_pattern			=> '111111111111',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_PEOPLE_CHANGES',
		pi_column_name				=> 'SEX',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_ADDRESS',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_ADDRESS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_target_table_name		=> 'P_ADDRESS',
		pi_leaf_join_tables			=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'CITY',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'ADDRESS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'STREET_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'STATE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'STATE_REGION',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT_SHORT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'COUNTRY',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT_SHORT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'COUNTRY_CODE',
		pi_masking_pattern			=> 'RU',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'REGION_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'QUARTER_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'STREET_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'BLOCK_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'APARTMENT_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'ENTRANCE_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'FLOOR_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_ADDRESS',
		pi_column_name				=> 'POST_CODE',
		pi_masking_pattern			=> '111111',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_ADDRESS',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_ADDRESS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'ADDRESS_ID',
		pi_target_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_target_table_name		=> 'HIST_P_ADDRESS',
		pi_leaf_join_tables			=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS, INSIS_PEOPLE_V10.P_ADDRESS',
		pi_leaf_join_conditions		=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS.ADDRESS_ID = INSIS_PEOPLE_V10.P_ADDRESS.ADDRESS_ID'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_column_name				=> 'ADDRESS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_column_name				=> 'COUNTRY_CODE',
		pi_masking_pattern			=> 'RU',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_column_name				=> 'POST_CODE',
		pi_masking_pattern			=> '111111',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_column_name				=> 'REGION_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);

	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_column_name				=> 'CITY',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_column_name				=> 'STREET_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_ADDRESS',
		pi_column_name				=> 'STREET_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_root_table_schema		=> 'INSIS_CUST',
		pi_root_table_name			=> 'P_ADDRESS_CHANGES',
		pi_root_where_filter		=> 'AND INSIS_CUST.P_ADDRESS_CHANGES.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_CUST',
		pi_target_table_name		=> 'P_ADDRESS_CHANGES',
		pi_leaf_join_tables			=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'CITY',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'ADDRESS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'STREET_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'STATE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'COUNTRY',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT_SHORT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'COUNTRY_CODE',
		pi_masking_pattern			=> 'RU',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'REGION_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'QUARTER_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'STREET_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'BLOCK_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'APARTMENT_NUMBER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_ADDRESS_CHANGES',
		pi_column_name				=> 'POST_CODE',
		pi_masking_pattern			=> '111111',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_CONTACTS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_CONTACTS',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_CONTACTS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_target_table_name		=> 'P_CONTACTS',
		pi_leaf_join_tables			=> 'INSIS_PEOPLE_V10.P_CONTACTS',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.P_CONTACTS',
		pi_column_name				=> 'DETAILS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_CONTACTS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'HIST_P_CONTACTS',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.HIST_P_CONTACTS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_target_table_name		=> 'HIST_P_CONTACTS',
		pi_leaf_join_tables			=> 'INSIS_PEOPLE_V10.HIST_P_CONTACTS',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_PEOPLE_V10.HIST_P_CONTACTS',
		pi_column_name				=> 'DETAILS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_CONTACTS_CHANGES',
		pi_root_table_schema		=> 'INSIS_CUST',
		pi_root_table_name			=> 'P_CONTACTS_CHANGES',
		pi_root_where_filter		=> 'AND INSIS_CUST.P_CONTACTS_CHANGES.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_CUST',
		pi_target_table_name		=> 'P_CONTACTS_CHANGES',
		pi_leaf_join_tables			=> 'INSIS_CUST.P_CONTACTS_CHANGES',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_CONTACTS_CHANGES',
		pi_column_name				=> 'DETAILS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_root_table_schema		=> 'INSIS_SYS_V10',
		pi_root_table_name			=> 'DOC_DOCUMENTS',
		pi_root_where_filter		=> 'AND INSIS_SYS_V10.DOC_DOCUMENTS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SYS_V10',
		pi_target_table_name		=> 'DOC_DOCUMENTS',
		pi_leaf_join_tables			=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_NUM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_VALID_TO',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_HOLDER_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_HOLDER_ADDR',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_DESCRIPTION',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'RECEIVE_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_STATE',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'DOC_DAYS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_column_name				=> 'NOTES',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID',
		pi_root_table_schema		=> 'INSIS_SYS_V10',
		pi_root_table_name			=> 'HIST_DOC_DOCUMENTS',
		pi_root_where_filter		=> 'AND INSIS_SYS_V10.HIST_DOC_DOCUMENTS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SYS_V10',
		pi_target_table_name		=> 'HIST_DOC_DOCUMENTS',
		pi_leaf_join_tables			=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID',
		pi_column_name				=> 'DOC_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID',
		pi_column_name				=> 'DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID',
		pi_column_name				=> 'DOC_NUM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID',
		pi_column_name				=> 'DOC_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);

	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID',
		pi_column_name				=> 'RECEIVE_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS MAN_ID',
		pi_column_name				=> 'DOC_STATE',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ',
		pi_root_table_schema		=> 'INSIS_SYS_V10',
		pi_root_table_name			=> 'DOC_DOCUMENTS',
		pi_root_where_filter		=> 'AND INSIS_SYS_V10.DOC_DOCUMENTS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'DOC_SEQ',
		pi_target_table_schema		=> 'INSIS_SYS_V10',
		pi_target_table_name		=> 'HIST_DOC_DOCUMENTS',
		pi_leaf_join_tables			=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS, INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_leaf_join_conditions		=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS.DOC_SEQ = INSIS_SYS_V10.DOC_DOCUMENTS.DOC_SEQ'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ',
		pi_column_name				=> 'DOC_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ',
		pi_column_name				=> 'DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ',
		pi_column_name				=> 'DOC_NUM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ',
		pi_column_name				=> 'DOC_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);

	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ',
		pi_column_name				=> 'RECEIVE_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SYS_V10.HIST_DOC_DOCUMENTS DOC_SEQ',
		pi_column_name				=> 'DOC_STATE',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID',
		pi_root_table_schema		=> 'INSIS_CUST',
		pi_root_table_name			=> 'P_DOCUMENTS_CHANGES',
		pi_root_where_filter		=> 'AND INSIS_CUST.P_DOCUMENTS_CHANGES.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_CUST',
		pi_target_table_name		=> 'P_DOCUMENTS_CHANGES',
		pi_leaf_join_tables			=> 'INSIS_CUST.P_DOCUMENTS_CHANGES',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID',
		pi_column_name				=> 'DOC_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID',
		pi_column_name				=> 'DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID',
		pi_column_name				=> 'DOC_NUM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID',
		pi_column_name				=> 'DOC_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID',
		pi_column_name				=> 'DOC_DESCRIPTION',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES MAN_ID',
		pi_column_name				=> 'NOTES',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ',
		pi_root_table_schema		=> 'INSIS_SYS_V10',
		pi_root_table_name			=> 'DOC_DOCUMENTS',
		pi_root_where_filter		=> 'AND INSIS_SYS_V10.DOC_DOCUMENTS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'DOC_SEQ',
		pi_target_table_schema		=> 'INSIS_CUST',
		pi_target_table_name		=> 'P_DOCUMENTS_CHANGES',
		pi_leaf_join_tables			=> 'INSIS_CUST.P_DOCUMENTS_CHANGES, INSIS_SYS_V10.DOC_DOCUMENTS',
		pi_leaf_join_conditions		=> 'INSIS_CUST.P_DOCUMENTS_CHANGES.DOC_SEQ = INSIS_SYS_V10.DOC_DOCUMENTS.DOC_SEQ'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ',
		pi_column_name				=> 'DOC_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ',
		pi_column_name				=> 'DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ',
		pi_column_name				=> 'DOC_NUM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'NUMBER',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ',
		pi_column_name				=> 'DOC_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ',
		pi_column_name				=> 'DOC_DESCRIPTION',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_CUST.P_DOCUMENTS_CHANGES DOC_SEQ',
		pi_column_name				=> 'NOTES',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_ORD',
		pi_root_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_root_table_name			=> 'BLC_BANK_STATEMENT_LINES',
		pi_root_where_filter		=> 'AND INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES.PARTY_ID_ORD = :CTX_MAN_ID',
		pi_root_column_name			=> 'PARTY_ID_ORD',
		pi_target_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_target_table_name		=> 'BLC_BANK_STATEMENT_LINES',
		pi_leaf_join_tables			=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_ORD',
		pi_column_name				=> 'PARTY_ADDRESS_ORD',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_ORD',
		pi_column_name				=> 'PARTY_NAME_ORD',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_ORD',
		pi_column_name				=> 'MATCHING_PARAMETERS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_BEN',
		pi_root_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_root_table_name			=> 'BLC_BANK_STATEMENT_LINES',
		pi_root_where_filter		=> 'AND INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES.PARTY_ID_BEN = :CTX_MAN_ID',
		pi_root_column_name			=> 'PARTY_ID_BEN',
		pi_target_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_target_table_name		=> 'BLC_BANK_STATEMENT_LINES',
		pi_leaf_join_tables			=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_BEN',
		pi_column_name				=> 'PARTY_ADDRESS_ORD',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_BEN',
		pi_column_name				=> 'PARTY_NAME_ORD',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES PARTY_ID_BEN',
		pi_column_name				=> 'MATCHING_PARAMETERS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_PAYMENTS',
		pi_root_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_root_table_name			=> 'BLC_PAYMENTS',
		pi_root_where_filter		=> 'AND INSIS_GEN_BLC_V10.BLC_PAYMENTS.PARTY = TO_CHAR(:CTX_MAN_ID)',
		pi_root_column_name			=> 'PARTY',
		pi_target_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_target_table_name		=> 'BLC_PAYMENTS',
		pi_leaf_join_tables			=> 'INSIS_GEN_BLC_V10.BLC_PAYMENTS',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_PAYMENTS',
		pi_column_name				=> 'PARTY_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_PAYMENTS',
		pi_column_name				=> 'PARTY_ADDRESS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_PAYMENTS',
		pi_column_name				=> 'MATCHING_PARAMETERS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_REMITTANCES',
		pi_root_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_root_table_name			=> 'BLC_PAYMENTS',
		pi_root_where_filter		=> 'AND INSIS_GEN_BLC_V10.BLC_PAYMENTS.PARTY = TO_CHAR(:CTX_MAN_ID)',
		pi_root_column_name			=> 'PARTY',
		pi_target_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_target_table_name		=> 'BLC_REMITTANCES',
		pi_leaf_join_tables			=> 'INSIS_GEN_BLC_V10.BLC_PAYMENTS, INSIS_GEN_BLC_V10.BLC_REMITTANCES',
		pi_leaf_join_conditions		=> 'INSIS_GEN_BLC_V10.BLC_REMITTANCES.PAYMENT_ID = INSIS_GEN_BLC_V10.BLC_PAYMENTS.PAYMENT_ID'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_REMITTANCES',
		pi_column_name				=> 'MATCHING_PARAMETERS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_INSTALLMENTS',
		pi_root_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_root_table_name			=> 'BLC_ITEMS',
		pi_root_where_filter		=> 'AND INSIS_GEN_BLC_V10.BLC_ITEMS.PARTY = TO_CHAR(:CTX_MAN_ID)',
		pi_root_column_name			=> 'PARTY',
		pi_target_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_target_table_name		=> 'BLC_INSTALLMENTS',
		pi_leaf_join_tables			=> 'INSIS_GEN_BLC_V10.BLC_INSTALLMENTS, INSIS_GEN_BLC_V10.BLC_ITEMS',
		pi_leaf_join_conditions		=> 'INSIS_GEN_BLC_V10.BLC_ITEMS.ITEM_ID = INSIS_GEN_BLC_V10.BLC_INSTALLMENTS.ITEM_ID'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_INSTALLMENTS',
		pi_column_name				=> 'ATTRIB_0',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL',
		pi_root_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_root_table_name			=> 'BLC_GL_INSIS2GL',
		pi_root_where_filter		=> 'AND INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL.DR_SEGMENT10 = TO_CHAR(:CTX_MAN_ID)',
		pi_root_column_name			=> 'DR_SEGMENT10',
		pi_target_table_schema		=> 'INSIS_GEN_BLC_V10',
		pi_target_table_name		=> 'BLC_GL_INSIS2GL',
		pi_leaf_join_tables			=> 'INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL',
		pi_column_name				=> 'ATTRIB_1',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL',
		pi_column_name				=> 'ATTRIB_2',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL',
		pi_column_name				=> 'ATTRIB_3',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_BLC_V10.BLC_GL_INSIS2GL',
		pi_column_name				=> 'DR_SEGMENT12',
		pi_masking_pattern			=> '01.01.2000',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_root_table_schema		=> 'INSIS_SGI_DEV',
		pi_root_table_name			=> 'HIST_AMLO_REPORT',
		pi_root_where_filter		=> 'AND INSIS_SGI_DEV.HIST_AMLO_REPORT.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'HIST_AMLO_REPORT',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_leaf_join_conditions		=> '1 = 1'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'FNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'GNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'SNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'BIRTH_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'POB',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'NATIONALITY',
		pi_masking_pattern			=> 'РФ',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'DOC_NUM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'NOTES',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'DOC_DATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'DOC_DESCRIPTION',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'H_ADDR',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'C_ADDR',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'MIGRATION_DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'MIGRATION_DOC_NUM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'MIGRATION_DOC_VALID_TO',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'VISA_DOC_SERIAL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'VISA_DOC_VALID_TO',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'VISA_DOC_VALID_FROM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'MIGRATION_DOC_VALID_FROM',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'DATE',
		pi_data_type_format			=> 'dd.mm.yyyy',
		pi_value_by_rule			=> 'GDPR_RANDOM_DATE',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'MOBILE_PHONE_NUMBER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_AMLO_REPORT',
		pi_column_name				=> 'EXCEL_EXP_FILE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'HIST_DCB_UNPAID_REPORT',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT',
		pi_column_name				=> 'GIVEN_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT',
		pi_column_name				=> 'MIDDLE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT',
		pi_column_name				=> 'FAMILY_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT',
		pi_column_name				=> 'REG_ADDR',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_DCB_UNPAID_REPORT',
		pi_column_name				=> 'EXP_PDF_PATH',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'HIST_NOTIFY_CLOSED_UNPAID',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID',
		pi_column_name				=> 'FNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID',
		pi_column_name				=> 'GNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID',
		pi_column_name				=> 'SNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID',
		pi_column_name				=> 'SEX',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID',
		pi_column_name				=> 'MESSAGE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.HIST_NOTIFY_CLOSED_UNPAID',
		pi_column_name				=> 'PHONE_NUMBER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.INTRF_KAFKA_INTEGRATION_OUT',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'INTRF_KAFKA_INTEGRATION_OUT',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.INTRF_KAFKA_INTEGRATION_OUT, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.INTRF_KAFKA_INTEGRATION_OUT.POLICY_ID = POL.POLICY_ID'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.INTRF_KAFKA_INTEGRATION_OUT',
		pi_column_name				=> 'PAYLOAD',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'XMLTYPE',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_XML',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_LOG',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'SGI_SMS_LOG',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.SGI_SMS_LOG, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.SGI_SMS_LOG.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_LOG',
		pi_column_name				=> 'MSG',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_LOG',
		pi_column_name				=> 'PHONE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_LOG',
		pi_column_name				=> 'STATUS_DESCR',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'SGI_SMS_CORE_DATA',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA',
		pi_column_name				=> 'FAMILY_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA',
		pi_column_name				=> 'GIVEN_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA',
		pi_column_name				=> 'MIDDLE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA',
		pi_column_name				=> 'CLIENT_MOBILE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA',
		pi_column_name				=> 'MESSAGE_TEXT',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_SMS_CORE_DATA',
		pi_column_name				=> 'ERROR_MESSAGE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.GEN_ANNEX_INFO',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_GEN_V10',
		pi_target_table_name		=> 'GEN_ANNEX_INFO',
		pi_leaf_join_tables			=> 'INSIS_GEN_V10.GEN_ANNEX_INFO, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_GEN_V10.GEN_ANNEX_INFO.POLICY_ID = POL.POLICY_ID'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.GEN_ANNEX_INFO',
		pi_column_name				=> 'ATTR_C1',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.GEN_ANNEX',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_GEN_V10',
		pi_target_table_name		=> 'GEN_ANNEX',
		pi_leaf_join_tables			=> 'INSIS_GEN_V10.GEN_ANNEX, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_GEN_V10.GEN_ANNEX.POLICY_ID = POL.POLICY_ID'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.GEN_ANNEX',
		pi_column_name				=> 'ANNEX_NOTE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_GEN_V10',
		pi_target_table_name		=> 'O_PROPERTY_ADDRESS',
		pi_leaf_join_tables			=> 'INSIS_GEN_V10.INSURED_OBJECT, INSIS_GEN_V10.O_PROPERTY, INSIS_GEN_V10.O_PROPERTY_ADDRESS, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_GEN_V10.INSURED_OBJECT.POLICY_ID = POL.POLICY_ID AND INSIS_GEN_V10.O_PROPERTY.OBJECT_ID = INSIS_GEN_V10.INSURED_OBJECT.OBJECT_ID AND INSIS_GEN_V10.O_PROPERTY_ADDRESS.ADDRESS_ID = INSIS_GEN_V10.O_PROPERTY.ADDRESS_ID'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'COUNTRY',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT_SHORT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'CITY',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'ADDRESS',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'POST_CODE',
		pi_masking_pattern			=> '111111',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'PHONE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'ZIP_EARTHQUAKE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'EARTHQUAKE_FACTOR',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT_SHORT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'COUNTRY_CODE',
		pi_masking_pattern			=> 'RU',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'COUNTRY_STATE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT_SHORT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'STATE_REGION',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT_SHORT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'TERRITORY_CLASSIFICATION',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'CITY_CODE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'STREET_ID',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'STREET_NUMBER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'BLOCK_NUMBER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'ENTRANCE_NUMBER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'FLOOR_NUMBER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'APARTMENT_NUMBER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'QUARTER_ID',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_NUMBER',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'STATE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'REGION_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'QUARTER_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'STREET_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_GEN_V10.O_PROPERTY_ADDRESS',
		pi_column_name				=> 'FLOOD_FACTOR',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'SGI_MORTGAGE_NOTIFICATIONS',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS',
		pi_column_name				=> 'FAMILY_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS',
		pi_column_name				=> 'GIVEN_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS',
		pi_column_name				=> 'MIDDLE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS',
		pi_column_name				=> 'CLIENT_EMAIL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS',
		pi_column_name				=> 'MESSAGE_TEXT',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MORTGAGE_NOTIFICATIONS',
		pi_column_name				=> 'ERROR_MESSAGE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'SGI_MPP_NOTIFICATIONS',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS',
		pi_column_name				=> 'CLIENT_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS',
		pi_column_name				=> 'CLIENT_EMAIL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS',
		pi_column_name				=> 'MESSAGE_TEXT',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_MPP_NOTIFICATIONS',
		pi_column_name				=> 'ERROR_MESSAGE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_column_name				=> 'GIVEN_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_column_name				=> 'MIDDLE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_column_name				=> 'FAMILY_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_column_name				=> 'REG_ADDR',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_column_name				=> 'EXP_PDF_PATH',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_HIST_UNPAID_REPORT',
		pi_column_name				=> 'EXP_ERROR_MESSAGE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'FAMILY_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);

	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'GIVEN_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'MIDDLE_NAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'CLIENT_TELEPHONE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'CLIENT_MOBILE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'CLIENT_EMAIL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'MESSAGE_TEXT',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_PL_PF_SMS_NOTIFICATIONS',
		pi_column_name				=> 'ERROR_MESSAGE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING',
		pi_root_table_schema		=> 'INSIS_PEOPLE_V10',
		pi_root_table_name			=> 'P_PEOPLE',
		pi_root_where_filter		=> 'AND INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SGI_DEV',
		pi_target_table_name		=> 'SGI_QUARTERLY_REPORT_MAILING',
		pi_leaf_join_tables			=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING, INSIS_PEOPLE_V10.P_PEOPLE, table(insis_sgi_dev.get_man_exp_policies(INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID)) POL',
		pi_leaf_join_conditions		=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING.POLICY_NO = POL.POLICY_NO'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING',
		pi_column_name				=> 'GNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING',
		pi_column_name				=> 'FNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING',
		pi_column_name				=> 'SNAME',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING',
		pi_column_name				=> 'CLIENT_EMAIL',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING',
		pi_column_name				=> 'REPORT_PATH',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'INSIS_SGI_DEV.SGI_QUARTERLY_REPORT_MAILING',
		pi_column_name				=> 'ERROR_MESSAGE',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID TEXT',
		pi_root_table_schema		=> 'INSIS_SYS_V10',
		pi_root_table_name			=> 'QUEST_QUESTIONS',
		pi_root_where_filter		=> 'AND INSIS_SYS_V10.QUEST_QUESTIONS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SYS_V10',
		pi_target_table_name		=> 'QUEST_QUESTIONS',
		pi_leaf_join_tables			=> 'INSIS_SYS_V10.QUEST_QUESTIONS',
		pi_leaf_join_conditions		=> 'INSIS_SYS_V10.QUEST_QUESTIONS.QUEST_ID IN (''P_PEP'', ''P_PEP_TOO'', ''P_PEP_JOB'', ''P_FULLNAME'', ''P_FULLNAME_ENG'', ''P_BUSINESSNAME'', ''P_EMP_ADDR'', ''P_PEP_REL'', ''P_KINSMANNAME'', ''P_PEP_KINSHIP'', ''P_SOURCE_INC'', ''P_KINSMANJOB'', ''P_OKPF'', ''P_COUNTRYTAX_1'', ''P_COUNTRYTAX_2'', ''P_COUNTRYTAX_3'', ''P_COUNTRYTAX_4'', ''P_COUNTRYTAX_5'', ''P_TIN_1'', ''P_TIN_2'', ''P_TIN_3'', ''P_TIN_4'', ''P_TIN_5'', ''P_TINABSCODE_1'', ''P_TINABSCODE_2'', ''P_TINABSCODE_3'', ''P_TINABSCODE_4'', ''P_TINABSCODE_5'', ''P_OTHREASON_1'', ''P_OTHREASON_2'', ''P_OTHREASON_3'', ''P_OTHREASON_4'', ''P_OTHREASON_5'', ''P_SNILS'', ''P_OKFS'', ''P_POB'', ''P_BUSINESS_PURP'', ''P_FIN_ACT_PURP'', ''P_FIN_POSITION'', ''P_BUSINESS_REP'', ''P_BENEF_OWNER_DET'')'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID TEXT',
		pi_column_name				=> 'QUEST_ANSWER',
		pi_masking_pattern			=> NULL,
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> 'GDPR_RANDOM_TEXT',
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID DATE',
		pi_root_table_schema		=> 'INSIS_SYS_V10',
		pi_root_table_name			=> 'QUEST_QUESTIONS',
		pi_root_where_filter		=> 'AND INSIS_SYS_V10.QUEST_QUESTIONS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SYS_V10',
		pi_target_table_name		=> 'QUEST_QUESTIONS',
		pi_leaf_join_tables			=> 'INSIS_SYS_V10.QUEST_QUESTIONS',
		pi_leaf_join_conditions		=> 'INSIS_SYS_V10.QUEST_QUESTIONS.QUEST_ID IN (''P_DATE_CRS'', ''P_DATE_EMBARGO'', ''P_DATE_FATCA'')'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID DATE',
		pi_column_name				=> 'QUEST_ANSWER',
		pi_masking_pattern			=> '01-01-2000',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	/*----------------------------------------------------------------------------------------------------------*/
	
	create_table_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID LIST',
		pi_root_table_schema		=> 'INSIS_SYS_V10',
		pi_root_table_name			=> 'QUEST_QUESTIONS',
		pi_root_where_filter		=> 'AND INSIS_SYS_V10.QUEST_QUESTIONS.MAN_ID = :CTX_MAN_ID',
		pi_root_column_name			=> 'MAN_ID',
		pi_target_table_schema		=> 'INSIS_SYS_V10',
		pi_target_table_name		=> 'QUEST_QUESTIONS',
		pi_leaf_join_tables			=> 'INSIS_SYS_V10.QUEST_QUESTIONS',
		pi_leaf_join_conditions		=> 'INSIS_SYS_V10.QUEST_QUESTIONS.QUEST_ID IN (''P_CRS_STATUS'', ''P_PEP'', ''P_FATCASTATUS'', ''P_USAGC'', ''P_EMBARGO'', ''P_BLACKLIST'', ''P_TERRORIST'', ''P_TINCORRECT_1'', ''P_TINCORRECT_2'', ''P_TINCORRECT_3'', ''P_TINCORRECT_4'', ''P_TINCORRECT_5'', ''P_INFO_FLG'')'
	);
	
	create_table_column_rule
	(
		pi_rule_name				=> 'QUEST_QUESTIONS MAN_ID LIST',
		pi_column_name				=> 'QUEST_ANSWER',
		pi_masking_pattern			=> '1',
		pi_data_type				=> 'VARCHAR2',
		pi_data_type_format			=> NULL,
		pi_value_by_rule			=> NULL,
		pi_continue_if_rule_fails	=> NULL
	);
	
	COMMIT;
END;
/
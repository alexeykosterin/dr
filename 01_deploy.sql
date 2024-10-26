SET DEFINE OFF

CREATE SEQUENCE insis_gdpr.ht_pi_data_seq;

CREATE SEQUENCE insis_gdpr.pi_consent_processing_seq;

CREATE SEQUENCE insis_gdpr.pi_con_proc_hist_seq;

CREATE SEQUENCE insis_gdpr.pi_operations_seq;

CREATE SEQUENCE insis_gdpr.pi_operations_executions_seq;

CREATE SEQUENCE insis_gdpr.cfg_pi_data_markup_seq;

CREATE SEQUENCE insis_gdpr.pi_operations_results_seq;

GRANT CREATE ANY TRIGGER TO insis_gdpr;

GRANT CREATE SYNONYM TO insis_gdpr;

GRANT CREATE VIEW TO insis_gdpr;

GRANT CREATE SESSION TO insis_gdpr;

GRANT DEBUG CONNECT SESSION TO insis_gdpr;

GRANT DELETE ANY TABLE TO insis_gdpr;

GRANT EXECUTE ANY PROCEDURE TO insis_gdpr;

GRANT EXECUTE ANY TYPE TO insis_gdpr;

GRANT SELECT ANY TABLE TO insis_gdpr;

GRANT UNLIMITED TABLESPACE TO insis_gdpr;

GRANT UPDATE ANY TABLE TO insis_gdpr;

GRANT CREATE ANY SYNONYM TO insis_gdpr;

GRANT DROP ANY SYNONYM TO insis_gdpr;

GRANT CREATE ANY VIEW TO insis_gdpr;

GRANT DROP ANY VIEW TO insis_gdpr;

CREATE TABLE insis_gdpr.pi_consent_processing_history (
  hist_id NUMBER(*,0) NOT NULL,
  cp_id NUMBER(*,0) NOT NULL,
  man_id NUMBER(10) NOT NULL,
  o_answer VARCHAR2(1 BYTE),
  n_answer VARCHAR2(1 BYTE),
  operation_type VARCHAR2(1 BYTE) NOT NULL,
  changed_by VARCHAR2(1000 BYTE),
  change_date DATE,
  PRIMARY KEY (hist_id)
);

CREATE TABLE insis_gdpr.cfg_country_pol_ret_periods (
  country_id VARCHAR2(2 BYTE) NOT NULL,
  duration NUMBER NOT NULL CONSTRAINT cons_check_pol_ret_per CHECK ("DURATION" > 0),
  PRIMARY KEY (country_id)
);

CREATE TABLE insis_gdpr.pi_consent_quests (
  quest_id VARCHAR2(20 BYTE) NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE) DEFAULT 'N' NOT NULL CONSTRAINT cons_check_active CHECK ("ACTIVE" IN ('Y','N')),
  PRIMARY KEY (quest_id)
);

CREATE TABLE insis_gdpr.cfg_pi_root_tables (
  root_id NUMBER(*,0) NOT NULL,
  root_owner VARCHAR2(128 BYTE) NOT NULL,
  root_table VARCHAR2(128 BYTE) NOT NULL,
  root_where_filter VARCHAR2(4000 BYTE),
  PRIMARY KEY (root_id),
  CONSTRAINT cfg_pi_root_tables_uq UNIQUE (root_owner,root_table)
);

CREATE TABLE insis_gdpr.cfg_parameters (
  "ID" VARCHAR2(50 BYTE) NOT NULL,
  description VARCHAR2(500 BYTE),
  "VALUE" VARCHAR2(4000 BYTE),
  long_text CLOB,
  PRIMARY KEY ("ID")
);

CREATE TABLE insis_gdpr.ht_pi_data (
  pi_data_id NUMBER(*,0) NOT NULL,
  "NAME" VARCHAR2(500 BYTE),
  schema_name VARCHAR2(128 BYTE) NOT NULL,
  table_name VARCHAR2(128 BYTE) NOT NULL,
  "ACTIVE" VARCHAR2(1 BYTE) DEFAULT 'N' NOT NULL CONSTRAINT ht_pi_d_check_active CHECK ("ACTIVE" IN ('Y','N')),
  order_id NUMBER(*,0),
  PRIMARY KEY (pi_data_id),
  CONSTRAINT ht_pi_data_uq UNIQUE (schema_name,table_name)
);

CREATE TABLE insis_gdpr.cfg_pi_data_markup (
  rel_id NUMBER(*,0) DEFAULT null NOT NULL,
  pi_data_id NUMBER(*,0) NOT NULL,
  root_id NUMBER(*,0) DEFAULT 1 NOT NULL,
  leaf_join_tables VARCHAR2(4000 BYTE),
  leaf_join_conditions VARCHAR2(4000 BYTE),
  select_statement VARCHAR2(4000 BYTE),
  update_statement VARCHAR2(4000 BYTE),
  delete_statement VARCHAR2(4000 BYTE),
  deletion_event_id VARCHAR2(50 BYTE),
  PRIMARY KEY (rel_id),
  CONSTRAINT cfg_dm_pi_data_markup_uq UNIQUE (pi_data_id),
  CONSTRAINT cfg_dm_to_ht FOREIGN KEY (pi_data_id) REFERENCES insis_gdpr.ht_pi_data (pi_data_id) ON DELETE CASCADE,
  CONSTRAINT cfg_pi_root_tables_fk FOREIGN KEY (root_id) REFERENCES insis_gdpr.cfg_pi_root_tables (root_id)
);

CREATE TABLE insis_gdpr.cfg_pi_supplementary_deletes (
  rel_id NUMBER(*,0) NOT NULL,
  delete_statement VARCHAR2(4000 BYTE) NOT NULL,
  order_id NUMBER(*,0) NOT NULL,
  CONSTRAINT cfg_pi_supp_del_uq UNIQUE (rel_id,order_id),
  CONSTRAINT cfg_pi_supp_del_fk FOREIGN KEY (rel_id) REFERENCES insis_gdpr.cfg_pi_data_markup (rel_id) ON DELETE CASCADE
);

CREATE TABLE insis_gdpr.cfg_excluded_people (
  man_id NUMBER,
  client_id NUMBER
);

CREATE TABLE insis_gdpr.quotations_deletion_history (
  policy_id NUMBER(*,0) NOT NULL,
  quote_id NUMBER(*,0) NOT NULL,
  deleted_on DATE,
  status VARCHAR2(1 BYTE),
  error_msg CLOB
);

CREATE TABLE insis_gdpr.cfg_pi_leaf_columns (
  rel_id NUMBER(*,0) NOT NULL,
  column_name VARCHAR2(128 BYTE) NOT NULL,
  masking_pattern VARCHAR2(4000 BYTE),
  data_type VARCHAR2(4000 BYTE),
  data_type_format VARCHAR2(4000 BYTE),
  value_by_rule VARCHAR2(4000 BYTE),
  continue_if_rule_fails VARCHAR2(1 BYTE),
  CONSTRAINT cfg_pi_leaf_columns_uq PRIMARY KEY (rel_id,column_name),
  CONSTRAINT cfg_pi_leaf_columns_fk FOREIGN KEY (rel_id) REFERENCES insis_gdpr.cfg_pi_data_markup (rel_id) ON DELETE CASCADE
);

CREATE TABLE insis_gdpr.pi_operations (
  op_id NUMBER(*,0) NOT NULL,
  man_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(1 BYTE) NOT NULL,
  date_to_execute DATE DEFAULT trunc(SYSDATE) NOT NULL,
  date_execution DATE,
  status VARCHAR2(1 BYTE) DEFAULT 'P' NOT NULL,
  requested_by VARCHAR2(500 BYTE) DEFAULT SYS_CONTEXT( 'INSISCTX', 'USERNAME' ) NOT NULL,
  request_reason VARCHAR2(500 BYTE),
  registration_date DATE DEFAULT SYSDATE NOT NULL,
  initiator_type VARCHAR2(1 BYTE) NOT NULL,
  approved VARCHAR2(1 BYTE) DEFAULT 'N' NOT NULL,
  date_of_approval DATE,
  user_approval_1 VARCHAR2(500 BYTE),
  date_app_by_user_1 DATE,
  user_approval_2 VARCHAR2(500 BYTE),
  date_app_by_user_2 DATE,
  user_approval_3 VARCHAR2(500 BYTE),
  date_app_by_user_3 DATE,
  cancelling_reason VARCHAR2(1000 BYTE),
  cancelled_by_user VARCHAR2(500 BYTE),
  date_of_cancellation DATE,
  PRIMARY KEY (op_id)
);

CREATE TABLE insis_gdpr.ht_gdpr_op_statuses (
  "ID" VARCHAR2(1 BYTE),
  "NAME" VARCHAR2(250 BYTE)
);

CREATE TABLE insis_gdpr.cfg_country_claim_ret_periods (
  country_id VARCHAR2(2 BYTE) NOT NULL,
  duration NUMBER NOT NULL CONSTRAINT cons_check_cl_ret_per CHECK ("DURATION" > 0),
  PRIMARY KEY (country_id)
);

CREATE TABLE insis_gdpr.cfg_pi_root_filter (
  root_id NUMBER(*,0) NOT NULL,
  column_name VARCHAR2(128 BYTE) NOT NULL,
  context_attrib_name VARCHAR2(4000 BYTE) NOT NULL,
  data_type VARCHAR2(4000 BYTE),
  data_type_format VARCHAR2(4000 BYTE),
  CONSTRAINT cfg_pi_rf_pk PRIMARY KEY (root_id,column_name),
  CONSTRAINT cfg_pi_rf_ctx_uq UNIQUE (root_id,context_attrib_name),
  CONSTRAINT cfg_rf_pi_rt_fk FOREIGN KEY (root_id) REFERENCES insis_gdpr.cfg_pi_root_tables (root_id) ON DELETE CASCADE
);

CREATE TABLE insis_gdpr.pi_consent_processing (
  cp_id NUMBER(*,0) NOT NULL,
  man_id NUMBER(10) NOT NULL,
  creation_date DATE DEFAULT SYSDATE NOT NULL,
  quest_id VARCHAR2(20 BYTE) NOT NULL,
  answer VARCHAR2(1 BYTE) NOT NULL,
  PRIMARY KEY (cp_id),
  CONSTRAINT pi_consent_processing_uq UNIQUE (man_id,quest_id),
  CONSTRAINT pi_cp_quest_id FOREIGN KEY (quest_id) REFERENCES insis_gdpr.pi_consent_quests (quest_id)
);

CREATE TABLE insis_gdpr.pi_operations_executions (
  opr_exec_id NUMBER(*,0) NOT NULL,
  op_id NUMBER(*,0) NOT NULL,
  date_execution DATE NOT NULL,
  status VARCHAR2(1 BYTE),
  error_log CLOB,
  PRIMARY KEY (opr_exec_id),
  CONSTRAINT pi_operations_executions_fk FOREIGN KEY (op_id) REFERENCES insis_gdpr.pi_operations (op_id) ON DELETE CASCADE
);

CREATE TABLE insis_gdpr.pi_operations_results (
  opr_id NUMBER(*,0) NOT NULL,
  op_id NUMBER(*,0) NOT NULL,
  opr_exec_id NUMBER(*,0) NOT NULL,
  rel_id NUMBER(*,0) NOT NULL,
  affected_owner VARCHAR2(128 BYTE) NOT NULL,
  affected_table VARCHAR2(128 BYTE) NOT NULL,
  affected_rowid ROWID NOT NULL,
  PRIMARY KEY (opr_id),
  CONSTRAINT pi_operations_results_fk FOREIGN KEY (opr_exec_id) REFERENCES insis_gdpr.pi_operations_executions (opr_exec_id) ON DELETE CASCADE
);

CREATE INDEX insis_gdpr.pi_operations_status_idx ON insis_gdpr.pi_operations(status);

CREATE INDEX insis_gdpr.pi_operations_man_id_idx ON insis_gdpr.pi_operations(man_id);

CREATE INDEX insis_gdpr.pi_operations_op_type_idx ON insis_gdpr.pi_operations(operation_type);

CREATE INDEX insis_gdpr.quotations_deletion_hst_q_ix ON insis_gdpr.quotations_deletion_history(quote_id);

CREATE INDEX insis_gdpr.quotations_deletion_hst_p_ix ON insis_gdpr.quotations_deletion_history(policy_id);

CREATE OR REPLACE PACKAGE insis_gdpr.pi_data_manipulator IS
gc_name_length             CONSTANT INTEGER := 128;
gc_quot_ret_per_param      CONSTANT VARCHAR2(37) := 'QUOTATION_RETENTION_PERIOD_IN_MONTHS';
gc_required_approval_level CONSTANT VARCHAR2(24) := 'REQUIRED_APPROVAL_LEVEL';
gc_batch_behaviour         CONSTANT VARCHAR2(16) := 'BATCH_BEHAVIOUR';
gc_batch_driving_query     CONSTANT VARCHAR2(20) := 'BATCH_DRIVING_QUERY';


$IF dbms_db_version.version >= 12 AND dbms_db_version.release >= 2 $THEN
TYPE lt_vc_table IS TABLE OF VARCHAR2(gc_name_length);
$ELSE
TYPE lt_vc_table IS TABLE OF VARCHAR2(30);
$END

TYPE rt_rootLeafID IS RECORD(
--     country           cfg_pi_data_markup.country%TYPE,
    root_id           cfg_pi_root_tables.root_id%TYPE
    ,root_owner        cfg_pi_root_tables.root_owner%TYPE
    ,root_table        cfg_pi_root_tables.root_table%TYPE
    ,root_where_filter cfg_pi_root_tables.root_where_filter%TYPE
    ,leaf_owner        ht_pi_data.schema_name%TYPE
    ,leaf_table        ht_pi_data.table_name%TYPE);

--------------------------------------------------------------------------------
-----------------API for ADF/Forms or external----------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

PROCEDURE doReportPIDataManID(pi_man_id         IN pi_operations.man_id%TYPE
                             ,pi_operation_type IN pi_operations.operation_type%TYPE
                             ,po_clob           OUT CLOB
                             ,debug             BOOLEAN DEFAULT FALSE);

PROCEDURE addOperation(pi_man_id         pi_operations.man_id%TYPE
                      ,pi_operation_type pi_operations.operation_type%TYPE
                      ,pi_initiator_type pi_operations.initiator_type%TYPE);

FUNCTION checkRecordCfgExclPpl(pir_rec IN OUT cfg_excluded_people%ROWTYPE
                              ,pio_err IN OUT VARCHAR2) RETURN BOOLEAN;

FUNCTION checkRecordCfgPiDataConf(pir_rec IN OUT cfg_pi_data_markup%ROWTYPE
                                 ,pio_err IN OUT VARCHAR2) RETURN BOOLEAN;

PROCEDURE cancelOperation(pi_op_id             IN pi_operations.op_id%TYPE
                         ,pi_cancelling_reason IN pi_operations.cancelling_reason%TYPE);

PROCEDURE approveOperation(pi_op_id      IN pi_operations.op_id%TYPE
                          ,pi_user_level IN INTEGER DEFAULT 0);

PROCEDURE execImmediateOperation(pi_op_id IN pi_operations.op_id%TYPE);

PROCEDURE execImmediateOperationNoCheck(pi_op_id  IN pi_operations.op_id%TYPE
                                       ,pi_reason IN VARCHAR2);

PROCEDURE rebuildConfig(pi_rel_id IN cfg_pi_data_markup.rel_id%TYPE);

--for Forms: added interfaces with pio_return_message  IN OUT VARCHAR2
FUNCTION addOperation(pi_man_id          pi_operations.man_id%TYPE
                     ,pi_operation_type  pi_operations.operation_type%TYPE
                     ,pi_initiator_type  pi_operations.initiator_type%TYPE
                     ,pio_return_message IN OUT VARCHAR2) RETURN BOOLEAN;

FUNCTION approveOperation(pi_op_id           IN pi_operations.op_id%TYPE
                         ,pi_user_level      IN INTEGER DEFAULT 0
                         ,pio_return_message IN OUT VARCHAR2) RETURN BOOLEAN;

FUNCTION execImmediateOperation(pi_op_id           IN pi_operations.op_id%TYPE
                               ,pio_return_message IN OUT VARCHAR2) RETURN BOOLEAN;

FUNCTION cancelOperation(pi_op_id             IN pi_operations.op_id%TYPE
                        ,pi_cancelling_reason IN pi_operations.cancelling_reason%TYPE
                        ,pio_return_message   IN OUT VARCHAR2) RETURN BOOLEAN;

FUNCTION doReportPIDataManID(pi_man_id          IN pi_operations.man_id%TYPE
                            ,pi_operation_type  IN pi_operations.operation_type%TYPE
                            ,po_clob            OUT CLOB
                            ,pio_return_message IN OUT VARCHAR2) RETURN BOOLEAN;

FUNCTION rebuildConfig(pi_rel_id          IN cfg_pi_data_markup.rel_id%TYPE
                      ,pio_return_message IN OUT VARCHAR2) RETURN BOOLEAN;

--batch
PROCEDURE massBatchReqApproval(pi_user_level IN INTEGER DEFAULT 0);

FUNCTION massBatchReqApproval(pi_user_level      IN INTEGER DEFAULT 0
                             ,pio_return_message IN OUT VARCHAR2) RETURN BOOLEAN;

PROCEDURE batchDeleteCancelledQuotsAT;

PROCEDURE batchSubmitRequests(pi_as_exec_date IN DATE DEFAULT NULL);

PROCEDURE batchExecutor(pi_to_date IN DATE DEFAULT SYSDATE);

$IF $$insisVersion < 10 $THEN
$ELSE
--reconciliation 
PROCEDURE reconcile_v10_rls(pi_implement_type IN VARCHAR2, pi_security_grp IN VARCHAR2,run_standard_rls IN BOOLEAN DEFAULT TRUE, to_exec IN BOOLEAN DEFAULT TRUE);
PROCEDURE reconcile_gen_blc_v10_rls(run_standard_rls  IN BOOLEAN DEFAULT TRUE, to_exec IN BOOLEAN DEFAULT TRUE);
$END
END pi_data_manipulator;
/

CREATE OR REPLACE PACKAGE BODY insis_gdpr.pi_data_manipulator wrapped 
a000000
369
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
b
1326b 3ef8
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
/

CREATE OR REPLACE FORCE VIEW insis_gdpr.v_p_people (man_id,man_comp,egn,"NAME",gname,sname,fname,birth_date,sex,notes,nationality,comp_type,name_suffix,name_prefix,data_source,language,home_country,registration_date,industry_code,sub_industry_code,fiscal_period,class_code,class_sub_code,attr1,attr2,attr3,attr4,attr5) AS
SELECT "MAN_ID","MAN_COMP","EGN","NAME","GNAME","SNAME","FNAME","BIRTH_DATE","SEX","NOTES","NATIONALITY","COMP_TYPE","NAME_SUFFIX","NAME_PREFIX","DATA_SOURCE","LANGUAGE","HOME_COUNTRY","REGISTRATION_DATE","INDUSTRY_CODE","SUB_INDUSTRY_CODE","FISCAL_PERIOD","CLASS_CODE","CLASS_SUB_CODE","ATTR1","ATTR2","ATTR3","ATTR4","ATTR5" FROM insis_people_v10.p_people
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.gdpr_schemas (username) AS
SELECT au.USERNAME FROM all_users au WHERE au.USERNAME LIKE 'INSIS%' ORDER BY 1
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.gdpr_tables_in_schema ("OWNER",table_name) AS
SELECT dt.owner, dt.table_name FROM all_tables dt WHERE dt.OWNER LIKE 'INSIS%'
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.gdpr_event_list ("ID",description,"TYPE",subtype) AS
SELECT "ID","DESCRIPTION","TYPE","SUBTYPE" FROM insis_sys_v10.srv_event_list
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.v_operation_types ("ID","NAME") AS
SELECT 'U' AS ID, 'Right to be Forgotten (Anonymization)' AS NAME FROM dual
UNION
SELECT 'D' AS ID, 'Right to be Forgotten (Erasure)' AS NAME FROM dual
UNION
SELECT 'R' AS ID, 'Right of Access' AS NAME FROM dual
UNION
SELECT 'E' AS ID, 'Right of Portability' AS NAME FROM dual
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.v_initiator_types ("ID","NAME") AS
SELECT 'M' AS ID, 'Manual' AS NAME FROM dual
UNION
SELECT 'B' AS ID, 'Batch' AS NAME FROM dual
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.h_countries ("ID","NAME",continent,class1,class2,class3,class4,local_flg) AS
SELECT "ID","NAME","CONTINENT","CLASS1","CLASS2","CLASS3","CLASS4","LOCAL_FLG" FROM insis_sys_v10.h_countries
UNION
SELECT 'DF', 'Country code used for Default configuration.', NULL,NULL,NULL,NULL,NULL, NULL FROM dual
ORDER BY 1;

CREATE OR REPLACE FORCE VIEW insis_gdpr.gdpr_column_datatypes (datatype) AS
SELECT 'CHAR' AS datatype FROM dual
UNION
SELECT 'NUMBER' FROM dual
UNION
SELECT 'DATE' FROM dual
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.gdpr_cols_in_table ("OWNER",table_name,column_name,data_type,data_length,char_used) AS
SELECT tc.owner
      ,tc.table_name
      ,tc.column_name
      ,tc.data_type     
      ,CASE
           WHEN tc.data_type LIKE '%CHAR%' THEN
            tc.CHAR_LENGTH
           WHEN tc.data_type IN ('NUMBER', 'FLOAT') THEN
            tc.DATA_PRECISION
           ELSE
            NULL
       END AS DATA_LENGTH
      ,decode(tc.CHAR_USED, 'B', 'Byte', 'C', 'Char', tc.CHAR_USED) AS CHAR_USED
  FROM all_tab_columns tc, all_objects ao
 WHERE tc.OWNER LIKE 'INSIS%'
   AND ao.owner = tc.owner
   AND ao.OBJECT_NAME = tc.table_name
   AND ao.object_type = 'TABLE'
 ORDER BY tc.owner,tc.table_name, tc.COLUMN_ID;

CREATE OR REPLACE FORCE VIEW insis_gdpr.h_gdpr_op_statuses ("ID","NAME") AS
SELECT a.ID, NVL(b.name, a.NAME) AS NAME
  FROM ht_gdpr_op_statuses a, insis_sys_v10.cfg_nom_language_table b
 WHERE b.id(+) = a.ID || ''
   AND b.table_name(+) = 'HT_GDPR_OP_STATUSES'
   AND b.language(+) = insis_sys_v10.insis_context.get_language
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.gdpr_questions ("ID","NAME",answer_type,answer_len_fixed,answer_len_max,defined_answers,default_answer,mandatory,to_load,for_stage,quest_order,format_mask,rule_id) AS
SELECT "ID","NAME","ANSWER_TYPE","ANSWER_LEN_FIXED","ANSWER_LEN_MAX","DEFINED_ANSWERS","DEFAULT_ANSWER","MANDATORY","TO_LOAD","FOR_STAGE","QUEST_ORDER","FORMAT_MASK","RULE_ID" FROM TABLE(insis_gen_cfg_v10.rb_cs_nom.c_QuestionTable) q  WHERE q.id LIKE 'GDPR%'
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.gdpr_question_answer ("ID","NAME",question_id,weight) AS
SELECT "ID","NAME","QUESTION_ID","WEIGHT" FROM TABLE(insis_gen_cfg_v10.rb_cs_nom.c_QuestionAnswerTable) qa WHERE qa.question_id LIKE 'GDPR%'
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.v_yes_no ("ID","NAME") AS
SELECT 'Y' AS ID, 'Yes' AS NAME FROM dual
UNION
SELECT 'N' AS ID, 'No' AS NAME FROM dual
;

CREATE OR REPLACE FORCE VIEW insis_gdpr.v_consent_operation_types (operation_type,operation_name) AS
SELECT 'I', 'Insert' FROM dual
UNION
SELECT 'U', 'Update' FROM dual
UNION
SELECT 'D', 'Delete' FROM dual;

CREATE OR REPLACE TRIGGER insis_gdpr.auditQuestQuestions
    AFTER INSERT OR UPDATE OR DELETE ON insis_sys_v10.QUEST_QUESTIONS
    FOR EACH ROW
DECLARE
    --my DEPT$audit%ROWTYPE;
    --l_rec   insis_sys_v10.QUEST_QUESTIONS%ROWTYPE;
    --NEW insis_sys_v10.QUEST_QUESTIONS%ROWTYPE;
    l_track INTEGER;
    l_cp_id INTEGER;
    l_man_id insis_people_v10.p_people.man_id%TYPE;
    l_policy_id insis_gen_v10.policy.policy_id%TYPE;
    l_rec insis_sys_v10.QUEST_QUESTIONS%ROWTYPE;
BEGIN
    --SELECT pi_con_proc_seq.nextval info l_cp_id FROM dual;
    IF inserting OR updating
    THEN
        SELECT COUNT(1)
          INTO l_track
          FROM pi_consent_quests q
         WHERE q.quest_id = nvl(:new.quest_id, '-1')
           AND q.active = 'Y'
           AND ROWNUM < 2;
    ELSIF deleting
    THEN
        SELECT COUNT(1)
          INTO l_track
          FROM pi_consent_quests q
         WHERE q.quest_id = :old.quest_id
           AND q.active = 'Y'
           AND ROWNUM < 2;
    END IF;
   
    IF l_track > 0
    THEN        
        IF nvl(:new.quest_answer,-1) != nvl(:old.quest_answer,-1) AND (inserting OR updating)
        THEN
            IF :new.man_id IS NULL AND :new.policy_id IS NOT NULL THEN
                l_policy_id := :new.policy_id;                 
                SELECT c.man_id INTO l_man_id FROM insis_people_v10.p_clients c, insis_gen_v10.policy p WHERE c.client_id = p.client_id AND p.policy_id = l_policy_id;                
            ELSE
                l_man_id  := :new.man_id;
            END IF;

            MERGE INTO pi_consent_processing c
            USING dual
            ON (c.man_id = l_man_id AND c.quest_id = :new.quest_id)
            
            WHEN NOT MATCHED THEN
                INSERT --INTO pi_consent_processing
                --(cp_id, man_id, creation_date, quest_id, answer)
                VALUES --seq.nextval
                    (pi_consent_processing_seq.nextval, l_man_id, SYSDATE, :new.quest_id, NVL(:new.quest_answer, 'N'))
            WHEN MATCHED THEN
                UPDATE
                   SET --creation_date = SYSDATE
                       answer = NVL(:new.quest_answer, 'N');                          
        ELSIF deleting
        THEN
            DELETE FROM pi_consent_processing c
             WHERE c.man_id = :old.man_id
               AND c.quest_id = :old.quest_id;
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.pi_consent_processing_i
  BEFORE INSERT
  ON insis_gdpr.pi_consent_processing
  FOR EACH ROW
  WHEN (new.cp_id is null)
DECLARE
 l_id INTEGER;
BEGIN
  SELECT pi_consent_processing_seq.nextval INTO l_id FROM DUAL;
  :new.cp_id := l_id;
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.pi_consent_processing_hst_i
  BEFORE INSERT
  ON insis_gdpr.pi_consent_processing
  FOR EACH ROW
  WHEN (new.cp_id is null)
DECLARE
 l_id INTEGER;
BEGIN
  SELECT pi_consent_processing_seq.nextval INTO l_id FROM DUAL;
  :new.cp_id := l_id;
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.ht_pi_data_i
  BEFORE INSERT
  ON insis_gdpr.ht_pi_data
  FOR EACH ROW
  WHEN (new.pi_data_id is null)
DECLARE
 l_id INTEGER;
BEGIN
  SELECT ht_pi_data_seq.nextval INTO l_id FROM DUAL;
  :new.pi_data_id := l_id;
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.cfg_pi_data_markup_i
  BEFORE INSERT
  ON insis_gdpr.cfg_pi_data_markup
  FOR EACH ROW
  WHEN (new.rel_id is null)
DECLARE
 l_id INTEGER;
BEGIN
  SELECT cfg_pi_data_markup_seq.nextval INTO l_id FROM DUAL;
  :new.rel_id := l_id;
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.pi_operations_executions_i
  BEFORE INSERT
  ON insis_gdpr.pi_operations_executions
  FOR EACH ROW
  WHEN (new.OPR_EXEC_ID is null)
DECLARE
 l_id INTEGER;
BEGIN
  SELECT pi_operations_executions_seq.nextval INTO l_id FROM DUAL;
  :new.OPR_EXEC_ID := l_id;
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.pi_operations_i
  BEFORE INSERT
  ON insis_gdpr.pi_operations
  FOR EACH ROW
  WHEN (new.OP_ID is null)
DECLARE
 l_id INTEGER;
BEGIN
  SELECT pi_operations_seq.nextval INTO l_id FROM DUAL;
  :new.OP_ID := l_id;
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.auditConsentProcessing
    AFTER INSERT OR UPDATE OR DELETE ON insis_gdpr.pi_consent_processing
    FOR EACH ROW
DECLARE        
    l_id INTEGER;    
BEGIN
    SELECT pi_con_proc_hist_seq.nextval INTO l_id FROM dual;
    IF inserting
    THEN
        INSERT INTO pi_consent_processing_history
        (hist_id, cp_id, man_id, o_answer, n_answer, operation_type, changed_by, change_date)
    VALUES
        (l_id
        ,:new.cp_id
        ,:new.man_id
        ,:old.answer
        ,:new.answer
        ,'I'
        ,SYS_CONTEXT('INSISCTX', 'USERNAME')
        ,SYSDATE);       
    ELSIF updating
    THEN
        INSERT INTO pi_consent_processing_history
        (hist_id, cp_id, man_id, o_answer, n_answer, operation_type, changed_by, change_date)
    VALUES
        (l_id
        ,:new.cp_id
        ,:new.man_id
        ,:old.answer
        ,:new.answer
        ,'U'
        ,SYS_CONTEXT('INSISCTX', 'USERNAME')
        ,SYSDATE);
    ELSIF deleting
    THEN
        INSERT INTO pi_consent_processing_history
        (hist_id, cp_id, man_id, o_answer, n_answer, operation_type, changed_by, change_date)
    VALUES
        (l_id
        ,:old.cp_id
        ,:old.man_id
        ,:old.answer
        ,:new.answer
        ,'D'
        ,SYS_CONTEXT('INSISCTX', 'USERNAME')
        ,SYSDATE);
    END IF;                  
END;
/

CREATE OR REPLACE TRIGGER insis_gdpr.pi_operations_results_i
  BEFORE INSERT
  ON insis_gdpr.pi_operations_results
  FOR EACH ROW
  WHEN (new.OPR_ID is null)
DECLARE
 l_id INTEGER;
BEGIN
  SELECT pi_operations_results_seq.nextval INTO l_id FROM DUAL;
  :new.OPR_ID := l_id;
END;
/

CREATE OR REPLACE SYNONYM insis_gdpr.srverr FOR insis_sys_v10.srverr;

CREATE OR REPLACE SYNONYM insis_gdpr.srverrmsg FOR insis_sys_v10.srverrmsg;

CREATE OR REPLACE SYNONYM insis_gdpr.srv_context FOR insis_sys_v10.srv_context;

CREATE OR REPLACE SYNONYM insis_gdpr.insis_context FOR insis_sys_v10.insis_context;

CREATE OR REPLACE SYNONYM insis_gdpr.srv_events FOR insis_sys_v10.srv_events;

CREATE OR REPLACE SYNONYM insis_gdpr.srvcontext FOR insis_sys_v10.srvcontext;

CREATE OR REPLACE SYNONYM insis_gdpr.srv_error FOR insis_sys_v10.srv_error;

CREATE OR REPLACE SYNONYM insis_gdpr.rb_srv FOR insis_gen_cfg_v10.rb_srv;

GRANT INHERIT PRIVILEGES ON USER insis_gdpr TO PUBLIC;

GRANT REFERENCES ON insis_people_v10.p_people TO insis_gdpr;

GRANT SELECT ON insis_gdpr.cfg_excluded_people TO insis_gen_v10_rls;

GRANT SELECT ON insis_gdpr.cfg_excluded_people TO insis_gen_blc_v10_rls;

GRANT CONNECT TO insis_gdpr;

GRANT RESOURCE TO insis_gdpr;

ALTER PACKAGE insis_gdpr.pi_data_manipulator COMPILE BODY;
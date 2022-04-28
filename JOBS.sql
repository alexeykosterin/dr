BEGIN
    dbms_scheduler.create_chain(
        chain_name => 'CHAIN_TLO_MAIN_CUR'
    );
    dbms_scheduler.enable(name => 'CHAIN_TLO_MAIN_CUR');
END;


/*
BEGIN
    dbms_scheduler.disable(name => 'CHAIN_TLO_MAIN_CUR');
END;
*/
BEGIN
    dbms_scheduler.drop_job(job_name => 'TLO_MAIN_CUR_JOB_0');
END;


BEGIN
    DBMS_SCHEDULER.create_program(
        program_name => 'AAK_MAIN_TLO_1',
        program_action => 'aak_main_tlo.CHAIN_STEPS',
        program_type => 'STORED_PROCEDURE',
        number_of_arguments => 2,
        comments => NULL,
        enabled => FALSE);
        
    DBMS_SCHEDULER.define_program_argument(argument_name => 'P_BILLING_ID',
    program_name      => 'AAK_MAIN_TLO_1',
    argument_position => 1,
    argument_type     => 'NUMBER',
    default_value     => '0'
    );
    
    DBMS_SCHEDULER.define_program_argument(
    argument_name => 'P_MOD',
    program_name      => 'AAK_MAIN_TLO_1',
    argument_position => 2,
    argument_type     => 'NUMBER',
    default_value     => '0');
      
  DBMS_SCHEDULER.ENABLE(name=>'AAK_MAIN_TLO_1');  
  
    DBMS_SCHEDULER.create_program(
        program_name => 'AAK_MAIN_TLO_2',
        program_action => 'aak_main_tlo.CHAIN_STEPS',
        program_type => 'STORED_PROCEDURE',
        number_of_arguments => 2,
        comments => NULL,
        enabled => FALSE);
    DBMS_SCHEDULER.define_program_argument(argument_name => 'P_BILLING_ID',
    program_name      => 'AAK_MAIN_TLO_2',
    argument_position => 1,
    argument_type     => 'NUMBER',
    default_value     => '0'
    );
    
    DBMS_SCHEDULER.define_program_argument(
    argument_name => 'P_MOD',
    program_name      => 'AAK_MAIN_TLO_2',
    argument_position => 2,
    argument_type     => 'NUMBER',
    default_value     => '1');
    DBMS_SCHEDULER.ENABLE(name=>'AAK_MAIN_TLO_2');    

    DBMS_SCHEDULER.create_program(
        program_name => 'AAK_MAIN_TLO_3',
        program_action => 'aak_main_tlo.CHAIN_STEPS',
        program_type => 'STORED_PROCEDURE',
        number_of_arguments => 2,
        comments => NULL,
        enabled => FALSE);
    DBMS_SCHEDULER.define_program_argument(argument_name => 'P_BILLING_ID',
    program_name      => 'AAK_MAIN_TLO_3',
    argument_position => 1,
    argument_type     => 'NUMBER',
    default_value     => '0'
    );
    
    DBMS_SCHEDULER.define_program_argument(
    argument_name => 'P_MOD',
    program_name      => 'AAK_MAIN_TLO_3',
    argument_position => 2,
    argument_type     => 'NUMBER',
    default_value     => '2'); 
  DBMS_SCHEDULER.ENABLE(name=>'AAK_MAIN_TLO_3');
        
       DBMS_SCHEDULER.create_program(
        program_name => 'AAK_MAIN_TLO_4',
        program_action => 'aak_main_tlo.CHAIN_STEPS',
        program_type => 'STORED_PROCEDURE',
        number_of_arguments => 2,
        comments => NULL,
        enabled => FALSE);
    DBMS_SCHEDULER.define_program_argument(argument_name => 'P_BILLING_ID',
    program_name      => 'AAK_MAIN_TLO_4',
    argument_position => 1,
    argument_type     => 'NUMBER',
    default_value     => '0'
    );
    
    DBMS_SCHEDULER.define_program_argument(
    argument_name => 'P_MOD',
    program_name      => 'AAK_MAIN_TLO_4',
    argument_position => 2,
    argument_type     => 'NUMBER',
    default_value     => '3');
    DBMS_SCHEDULER.ENABLE(name=>'AAK_MAIN_TLO_4');    
END;


BEGIN
  -- one step for each program
  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_STEP (
     chain_name          => 'CHAIN_TLO_MAIN_CUR'
    ,step_name           => 'CHAIN_STEP1'
    ,program_name        => 'AAK_MAIN_TLO_1');

  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_STEP (
     chain_name          => 'CHAIN_TLO_MAIN_CUR'
    ,step_name           => 'CHAIN_STEP2'
    ,program_name        => 'AAK_MAIN_TLO_2');

  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_STEP (
     chain_name          => 'CHAIN_TLO_MAIN_CUR'
    ,step_name           => 'CHAIN_STEP3'
    ,program_name        => 'AAK_MAIN_TLO_3');
    
    SYS.DBMS_SCHEDULER.DEFINE_CHAIN_STEP (
     chain_name          => 'CHAIN_TLO_MAIN_CUR'
    ,step_name           => 'CHAIN_STEP4'
    ,program_name        => 'AAK_MAIN_TLO_4');
end;


begin
  -- one rule with condition "true" to start each step immediately
  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_RULE  (
      CHAIN_NAME  => 'CHAIN_TLO_MAIN_CUR',
      rule_name  => 'TLO_MAIN_RULE1',
      condition => 'TRUE',
      action => 'START "CHAIN_STEP1"');   

  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_RULE  (
      CHAIN_NAME  => 'CHAIN_TLO_MAIN_CUR',
      rule_name  => 'TLO_MAIN_RULE2',
      condition => 'TRUE',
      action => 'START "CHAIN_STEP2"');   

  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_RULE  (
      CHAIN_NAME  => 'CHAIN_TLO_MAIN_CUR',
      rule_name  => 'TLO_MAIN_RULE3',
      condition => 'TRUE',
      action => 'START "CHAIN_STEP3"');   

  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_RULE  (
      CHAIN_NAME  => 'CHAIN_TLO_MAIN_CUR',
      rule_name  => 'TLO_MAIN_RULE4',
      condition => 'TRUE',
      action => 'START "CHAIN_STEP4"'); 

  -- one rule to close out the chain after all steps are completed    
  SYS.DBMS_SCHEDULER.DEFINE_CHAIN_RULE (
     chain_name          => 'CHAIN_TLO_MAIN_CUR',
     rule_name           => 'TLO_MAIN_RULE5',
     condition           => 'CHAIN_STEP1 Completed AND CHAIN_STEP2 Completed AND CHAIN_STEP3 Completed AND CHAIN_STEP4 Completed',
     action              => 'END 0');

END;


begin
  --DBMS_SCHEDULER.drop_chain_rule(rule_name => 'TEST_RULE1',chain_name => 'AAK_CHAIN');
  --DBMS_SCHEDULER.drop_job(job_name => 'AAK_JOB');
  --SYS.DBMS_SCHEDULER.drop_program(program_name => 'TEST1_PROGRAM');
end;






BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
            job_name => 'TLO_FOR_HOLDING_JOB_1',
            job_type => 'CHAIN',
            job_action => 'CHAIN_TLO_FOR_HOLDING',
            number_of_arguments => 0,
            start_date => NULL,
            repeat_interval => NULL,
            end_date => NULL,
            enabled => FALSE,
            auto_drop => FALSE,
            comments => '');

    DBMS_SCHEDULER.SET_ATTRIBUTE( 
             name => 'TLO_FOR_HOLDING_JOB_1', 
             attribute => 'logging_level', value => DBMS_SCHEDULER.LOGGING_RUNS);

END;



BEGIN
    DBMS_SCHEDULER.RUN_JOB(job_name => 'TLO_MAIN_CUR_JOB_0', USE_CURRENT_SESSION => FALSE);
END;



SELECT * FROM dba_scheduler_jobs where job_name = 'AAK_JOB'


/*
begin
  DBMS_SCHEDULER.PURGE_LOG(job_name => 'AAK_JOB');
end;
  */



----------------------------------------------------------------------------------


SELECT * FROM DBA_SCHEDULER_JOB_LOG
where job_name = 'TLO_FOR_HOLDING_JOB_1'


/*
begin
  DBMS_SCHEDULER.PURGE_LOG(job_name => 'AAK_JOB');
end;
*/

BEGIN
    DBMS_SCHEDULER.RUN_JOB(job_name => 'TLO_FOR_HOLDING_JOB_1', USE_CURRENT_SESSION => FALSE);
END;

SELECT STATE, d.* FROM dba_scheduler_jobs d where 1=1
--and STATE != 'RUNNING'
and job_name = 'TLO_FOR_HOLDING_JOB_1'

SELECT * FROM dba_scheduler_job_log where job_name = 'TLO_FOR_HOLDING_JOB_1'
order by LOG_DATE desc

select
   log_date,
   job_name,
   status,
   req_start_date,
   actual_start_date,
   run_duration, d.*
from
   dba_scheduler_job_run_details d
where
   job_name = 'TLO_FOR_HOLDING_JOB_1'
   
--CHAIN_LOG_ID="0", ORA-27367: program "IDB_PROD"."AAK_CHAIN" associated with this job is disabled

select * from all_scheduler_programs 
where program_name like '%DEMO%';


BEGIN
    DBMS_SCHEDULER.drop_job(job_name => 'TLO_FOR_HOLDING_JOB_1');
end;

BEGIN
    DBMS_SCHEDULER.stop_job(job_name => 'TLO_FOR_HOLDING_JOB_1');
end;

BEGIN
  for rec in (
select * from all_scheduler_programs 
where program_name like 'TLO_FOR_HOLDING_PROGRAM') loop
    DBMS_SCHEDULER.disable(name => rec.program_name);
    end loop;
end;



-- ----------------------------------------------------------------------------------------------
--  ash_events.sql
--
--   Returns from Active Session History, for a specific sql id,
--   the most-waited Wait Events for the last N minutes.
--
--  PARAMETERS
--
--  1.  SQL_ID              (optional)      If not specified it will return results for ALL sql id in ASH!
--  2.  child_number        (optional)      Default 0
--  3.  minutes_from_now    (required)      Time interval for which you wish to examine ASH samples
--
-- (C) 2015 Nikos Karagiannidis - http://oradwstories.blogspot.com    
-- ----------------------------------------------------------------------------------------------


set pagesize 999
set lines 999
col object_name format a50
col object_type format a20

select sql_exec_start, event, decode(session_state, 'ON CPU', 'ON CPU', wait_class) wait_class_or_CPU,round(ratio_to_report(count(*)) over(partition by sql_exec_start) *100) PCNT, owner, object_name, object_type, count(*) nosamples, cnttot nosamplestot, P1TEXT, P2TEXT, P3TEXT 
    from (
		select sql_exec_start,   event, wait_class, P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type, session_state,  count(*) over(partition by sql_exec_start) cnttot
		from gv$active_session_history a left outer join dba_objects b on(a.CURRENT_OBJ# = b.object_id)
		where  
		SAMPLE_TIME > sysdate - (&minutes_from_now/(24*60))
		and ((session_state = 'WAITING' and WAIT_TIME = 0) or session_state ='ON CPU')
		and sql_id = nvl('&sql_id',sql_id)
		and SQL_CHILD_NUMBER = nvl('&SQL_CHILD_NUMBER',0)
		and sql_exec_id is not null
    )t
    group by sql_exec_start, event, wait_class, session_state, P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type, cnttot
    order by sql_exec_start desc, pcnt desc
/
	
-----------------------------------------------------------------------------------------------------------
--	the following records only samples that are in session_State "waiting" and thus omits all samples "on cpu"
-----------------------------------------------------------------------------------------------------------
--    select event, wait_class,round(ratio_to_report(count(*)) over() *100) PCNT, owner, object_name, object_type, count(*) nosamples, cnttot nosamplestot, P1TEXT, P2TEXT, P3TEXT 
--    from (
--		select    event, wait_class, P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type,  count(*) over() cnttot
--		from gv$active_session_history a  join dba_objects b on(a.CURRENT_OBJ# = b.object_id)
--		where  
--		SAMPLE_TIME > sysdate - (&minutes_from_now/(24*60))
--		and session_state= 'WAITING' and WAIT_TIME = 0
--		and sql_id = nvl('&sql_id',sql_id)
--		and SQL_CHILD_NUMBER = nvl('&SQL_CHILD_NUMBER',0)
--    )t
--    group by event, wait_class,  P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type, cnttot
--    order by pcnt desc
--/

-------------------------------------------------------------------------------------------------------
--select 	decode(grouping(event),1,'TOTAL',event) event, 
--		decode(grouping(wait_class),1,'TOTAL', wait_class) wait_class,   
--		sum(PCNT), sum(nosamples), sum(nosamplestot),
--		decode(grouping(owner),1,'TOTAL', owner)owner, decode(grouping(object_name),1,'TOTAL', object_name) object_name, decode(grouping(object_type),1,'TOTAL', object_type) object_type,
--		decode(grouping(P1TEXT),1,'TOTAL', P1TEXT) P1TEXT, decode(grouping(P2TEXT),1,'TOTAL', P2TEXT) P2TEXT, decode(grouping(P3TEXT),1,'TOTAL', P3TEXT) P3TEXT		
--from (		
--	select event, wait_class,round((count(*)/cnttot)*100) PCNT, count(*) nosamples, cnttot nosamplestot,P1TEXT, P2TEXT, P3TEXT, 
--		owner, object_name, object_type
--	from (
--	select	event, wait_class, P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type,  count(*) over() cnttot
--	from gv$active_session_history a  join dba_objects b on(a.CURRENT_OBJ# = b.object_id)
--	where  
--	SAMPLE_TIME > sysdate - (&minutes_from_now/(24*60))
--	and session_state= 'WAITING' and WAIT_TIME = 0
--	and sql_id = nvl('&sql_id',sql_id)
--	and SQL_CHILD_NUMBER = nvl('&SQL_CHILD_NUMBER',0)
--	)t
--	group by event, wait_class,  P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type, cnttot
--	--order by count(*) desc
--)
--group by rollup(event, (wait_class,  P1TEXT, P2TEXT, P3TEXT, owner, object_name, object_type))
--order by sum(PCNT) desc
--/
-------------------------------------------------------------------------------------------------------
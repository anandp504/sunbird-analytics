CREATE KEYSPACE IF NOT EXISTS local_learner_db WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': '1'
};

CREATE KEYSPACE IF NOT EXISTS local_creation_metrics_db WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': '1'
};

CREATE TABLE IF NOT EXISTS local_learner_db.learnersnapshot (
	learner_id text,
	m_time_spent double,
	m_time_btw_gp double,
	m_active_time_on_pf double,
	m_interrupt_time double,
	t_ts_on_pf double,
	m_ts_on_an_act map<text,double>,
	m_count_on_an_act map<text,double>,
	n_of_sess_on_pf int,
	l_visit_ts timestamp,
	most_active_hr_of_the_day int,
	top_k_content list<text>,
	sess_start_time timestamp,
	sess_end_time timestamp,
	dp_start_time timestamp,
	dp_end_time timestamp,
	updated_date timestamp,
	PRIMARY KEY (learner_id)
);

CREATE TABLE IF NOT EXISTS local_learner_db.learnerproficiency(
	learner_id text,
	proficiency map<text,double>,
	start_time timestamp,
	end_time timestamp,
	model_params map<text,text>,
	updated_date timestamp,
	PRIMARY KEY (learner_id)
);

CREATE TABLE IF NOT EXISTS local_learner_db.learnercontentsummary(
	learner_id text,
	content_id text,
	time_spent double,
	interactions_per_min double,
	num_of_sessions_played int,
	updated_date timestamp,
	PRIMARY KEY (learner_id, content_id)
);

CREATE TABLE IF NOT EXISTS local_learner_db.learnerconceptrelevance(
	learner_id text,
	relevance map<text,double>,
	updated_date timestamp,
	PRIMARY KEY (learner_id)
);

CREATE TABLE IF NOT EXISTS local_learner_db.conceptsimilaritymatrix (
	concept1 text,
	concept2 text,
	relation_type text,
	sim double,
	updated_date timestamp,
	PRIMARY KEY (concept1, concept2)
);

CREATE TABLE IF NOT EXISTS local_learner_db.learnerprofile (
	learner_id text,
	app_id text,
	channel text,
	did text,
	gender text,
	language text,
	loc text,
	standard int,
	age int,
	year_of_birth int,
	group_user boolean,
	anonymous_user boolean,
	created_date timestamp,
	updated_date timestamp,
	PRIMARY KEY (learner_id, app_id, channel)
);

CREATE KEYSPACE IF NOT EXISTS local_content_db WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': '1'
};

CREATE TABLE IF NOT EXISTS local_content_db.content_cumulative_summary (
	content_id text,
	start_date timestamp,
	total_ts double,
	total_num_sessions bigint,
	average_ts_session double,
	total_interactions bigint,
	average_interactions_min double,
	num_sessions_week double,
	ts_week double,
	content_type text,
	mime_type text,
	updated_date timestamp,
	PRIMARY KEY (content_id)
);

CREATE TABLE IF NOT EXISTS local_content_db.content_usage_metrics (
	id text,
	top_k_timespent map<text,double>,
	top_k_sessions map<text,bigint>,
	updated_date timestamp,
	PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS local_content_db.content_usage_summary_fact (
    d_period Int,
    d_tag text,
    d_content_id text,
    d_app_id text,
    d_channel text,
    m_publish_date timestamp,
    m_last_sync_date timestamp,
    m_last_gen_date timestamp,
    m_total_ts double,
    m_total_devices bigint,
    m_device_ids blob,
    m_total_sessions bigint,
    m_avg_sess_device double,
    m_avg_ts_session double,
    m_total_interactions bigint,
    m_avg_interactions_min double,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_tag, d_content_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.content_popularity_summary_fact (
	d_period int,
	d_tag text,
	d_content_id text,
	d_app_id text,
	d_channel text,
	m_downloads bigint,
	m_side_loads bigint,
	m_comments list<frozen <tuple<text, timestamp>>>,
	m_ratings list<frozen <tuple<double, timestamp>>>,
	m_avg_rating double,
	updated_date timestamp,
	PRIMARY KEY (d_period, d_tag, d_content_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.item_usage_summary_fact (
	d_period int,
	d_tag text,
	d_content_id text,
	d_item_id text,
	d_app_id text,
	d_channel text,
	m_total_ts double,
	m_total_count int,
	m_correct_res_count int,
	m_inc_res_count int,
	m_correct_res list<text>,
	m_incorrect_res list<frozen <tuple<text, list<text>, int>>>,
	m_top5_incorrect_res list<frozen <tuple<text, list<text>, int>>>,
	m_top5_mmc list<frozen <tuple<text, int>>>,
	m_avg_ts double,
	updated_date timestamp,
	PRIMARY KEY (d_period, d_tag, d_content_id, d_item_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.genie_launch_summary_fact (
	d_period int,
	d_tag text,
	d_app_id text,
	d_channel text,
	m_total_sessions bigint,
	m_total_ts double,
	m_total_devices bigint,
	m_device_ids blob,
	m_avg_sess_device bigint,
	m_avg_ts_session double,
	m_contents list<text>,
	updated_date timestamp,
	PRIMARY KEY (d_period, d_tag, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.content_sideloading_summary (
    content_id text,
    app_id text,
    channel text,
    num_downloads bigint,
    total_count bigint,
    num_sideloads bigint,
    origin_map map<text,double>,
    avg_depth double,
    updated_date timestamp,
    PRIMARY KEY (content_id, app_id, channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.content_to_vector(
	content_id text,
	text_vec list<double>,
	tag_vec list<double>,
	updated_date timestamp,
	PRIMARY KEY (content_id)
);

CREATE TABLE IF NOT EXISTS local_content_db.content_recos(
    content_id text,
    scores list<frozen <tuple<text, double>>>,
    updated_date timestamp,
    PRIMARY KEY (content_id)
);

CREATE TABLE IF NOT EXISTS local_content_db.registered_tags(
	tag_id text,
	last_updated timestamp,
	active boolean,
	PRIMARY KEY (tag_id)
);

CREATE TABLE IF NOT EXISTS local_content_db.content_snapshot_summary (
    d_period int,
    d_author_id text,
    d_partner_id text,
    d_app_id text,
    d_channel text,
    total_author_count bigint,
    total_author_count_start bigint,
    active_author_count bigint,
    active_author_count_start bigint,
    total_content_count bigint,
    total_content_count_start bigint,
    live_content_count bigint,
    live_content_count_start bigint,
    review_content_count bigint,
    review_content_count_start bigint,
    creation_ts double,
    avg_creation_ts double,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_author_id, d_partner_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.concept_snapshot_summary (
    d_period int,
    d_concept_id text,
    d_app_id text,
    d_channel text,
    total_content_count bigint,
    total_content_count_start bigint,
    live_content_count bigint,
    live_content_count_start bigint,
    review_content_count bigint,
    review_content_count_start bigint,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_concept_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.asset_snapshot_summary(
	d_period int,
	d_partner_id text,
	d_app_id text,
	d_channel text,
	total_images_count bigint,
	total_images_count_start bigint,
	used_images_count bigint,
	used_images_count_start bigint,
	total_audio_count bigint,
	total_audio_count_start bigint,
	used_audio_count bigint,
	used_audio_count_start bigint,
	total_questions_count bigint,
	total_questions_count_start bigint,
	used_questions_count bigint,
	used_questions_count_start bigint,
	total_activities_count bigint,
	total_activities_count_start bigint,
	used_activities_count bigint,
	used_activities_count_start bigint,
	total_templates_count bigint,
	total_templates_count_start bigint,
	used_templates_count bigint,
	used_templates_count_start bigint,
	updated_date timestamp,
	PRIMARY KEY (d_period, d_partner_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_content_db.usage_summary_fact (
    d_period Int,
    d_user_id text,
    d_content_id text,
    d_tag text,
    d_app_id text,
    d_channel text,
    m_publish_date timestamp,
    m_last_sync_date timestamp,
    m_last_gen_date timestamp,
    m_total_ts double,
    m_total_sessions bigint,
    m_avg_ts_session double,
    m_total_interactions bigint,
    m_avg_interactions_min double,
    m_total_users_count bigint,
    m_total_content_count bigint,
    m_total_devices_count bigint,
    m_user_ids blob,
    m_content_ids blob,
    m_device_ids blob,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_user_id, d_content_id, d_tag, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.publish_pipeline_summary_fact(
	d_period int,
	d_app_id text,
	d_channel text,
	type text,
	state text,
	subtype text,
	count int,
	updated_at timestamp,
	PRIMARY KEY (d_period, type, state, subtype, d_app_id, d_channel)
);

CREATE KEYSPACE IF NOT EXISTS local_device_db WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': '1'
};

CREATE TABLE IF NOT EXISTS local_device_db.device_recos(
	device_id text,
	scores list<frozen <tuple<text, double>>>,
	updated_date timestamp,
	PRIMARY KEY (device_id)
);

CREATE TABLE IF NOT EXISTS local_device_db.device_specification (
	device_id text,
	app_id text,
	channel text,
	device_name text,
	device_local_name text,
	os text,
	make text,
	memory double,
	internal_disk double,
	external_disk double,
	screen_size double,
	primary_secondary_camera text,
	cpu text,
	num_sims double,
	capabilities list<text>,
	updated_date timestamp,
	PRIMARY KEY (device_id, app_id, channel)
);

CREATE TABLE IF NOT EXISTS local_device_db.device_usage_summary (
    device_id text,
    app_id text,
    channel text,
    start_time timestamp,
    end_time timestamp,
    num_days bigint,
    total_launches bigint,
    total_timespent double,
    avg_num_launches double,
    avg_time double,
    num_contents bigint,
    play_start_time timestamp,
    last_played_on timestamp,
    total_play_time double,
    num_sessions bigint,
    mean_play_time double,
    mean_play_time_interval double,
    last_played_content text,
    updated_date timestamp,
    PRIMARY KEY (device_id, app_id, channel)
);

CREATE TABLE IF NOT EXISTS local_device_db.device_content_summary_fact (
    device_id text,
    content_id text,
    app_id text,
    channel text,
    game_ver text,
    num_sessions bigint,
    total_interactions bigint,
    avg_interactions_min double,
    total_timespent double,
    last_played_on timestamp,
    start_time timestamp,
    mean_play_time_interval double,
    downloaded boolean,
    download_date timestamp,
    num_group_user bigint,
    num_individual_user bigint,
    updated_date timestamp,
    PRIMARY KEY (device_id, content_id, app_id, channel)
);

CREATE TABLE IF NOT EXISTS local_device_db.device_profile (
	device_id text,
    channel text,
    first_access timestamp,
    last_access timestamp,
    total_ts double,
    total_launches bigint,
    avg_ts double,
    device_spec Map<text,text>,
    updated_date timestamp,
    state text,
    state_code text,
    country text,
    country_code text,
    city text,
    uaspec Map<text,text>,
    state_custom text,
    state_code_custom text,
    district_custom text,
    PRIMARY KEY (device_id, channel)
);

CREATE KEYSPACE IF NOT EXISTS local_platform_db WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': '1'
};

CREATE TABLE IF NOT EXISTS local_platform_db.job_request (
    client_key text,
    request_id text,
    job_id text,
    status text,
    request_data text,
    location text,
    dt_file_created timestamp,
    dt_first_event timestamp,
    dt_last_event timestamp,
    dt_expiration timestamp,
    iteration int,
    dt_job_submitted timestamp,
    dt_job_processing timestamp,
    dt_job_completed timestamp,
    input_events int,
    output_events int,
    file_size bigint,
    latency int,
    execution_time bigint,
    err_message text,
    stage text,
    stage_status text,
    PRIMARY KEY (client_key, request_id)
);

CREATE TABLE IF NOT EXISTS local_platform_db.recommendation_config(
    config_key text,
    config_value list<text>,
    PRIMARY KEY (config_key)
);

CREATE TYPE IF NOT EXISTS local_platform_db.requests(
     grade_level list<text>,
     concepts list<text>,
     content_type text,
     language Map<text,text>,
     type text
);

CREATE TABLE IF NOT EXISTS local_platform_db.request_recos(
    uid text,
    requests list<frozen<requests>>,
    updated_date timestamp,
    PRIMARY KEY (uid)
);

CREATE TABLE IF NOT EXISTS local_platform_db.job_config(
    category text,
    config_key text,
    config_value frozen<map<text,list<text>>>,
    PRIMARY KEY (category, config_key)
);

CREATE KEYSPACE IF NOT EXISTS local_creation_db WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': '1'
};

CREATE TABLE IF NOT EXISTS local_creation_db.app_object_cache (
	type text,
	id text,
	app_id text,
	channel text,
	subtype text,
	parentid text,
	parenttype text,
	code text,
	name text,
	state text,
	prevstate text,
	updated_date timestamp,
	PRIMARY KEY (type, id, app_id, channel)
);

CREATE TABLE IF NOT EXISTS local_creation_db.user_profile (
	user_id text,
	app_id text,
	channel text,
	name text,
	email text,
	access text,
	partners text,
	profile text,
	updated_date timestamp,
	PRIMARY KEY (user_id, app_id, channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.content_creation_metrics_fact(
    d_content_id text,
    d_ver int,
    tags_count int,
    images_count int,
    audios_count int,
    videos_count int,
    plugin_metrics map<text, int>,
    time_spent_draft double,
    time_spent_review double,
    pkg_version int,
    last_status text,
    last_status_date timestamp,
    first_ver_total_sessions bigint,
    first_ver_total_ts double,
    updated_date timestamp,
    PRIMARY KEY (d_content_id)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.ce_usage_summary_fact (
    d_period int,
    d_content_id text,
    d_app_id text,
    d_channel text,
    unique_users_count bigint,
    total_sessions bigint,
    total_ts double,
    avg_ts_session double,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_content_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.app_usage_summary_fact (
    d_period int,
    d_author_id text,
    d_app_id text,
    d_channel text,
    anon_total_sessions bigint,
    anon_total_ts double,
    total_sessions bigint,
    total_ts double,
    ce_total_sessions bigint,
    ce_percent_sessions double,
    total_pageviews_count bigint,
    unique_users blob,
    unique_users_count bigint,
    avg_pageviews double,
    avg_ts_session double,
    anon_avg_ts_session double,
    new_user_count bigint,
    percent_new_users_count double,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_author_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.author_usage_summary_fact (
    d_period int,
    d_author_id text,
    d_app_id text,
    d_channel text,
    total_sessions bigint,
    total_ts double,
    total_ce_ts double,
    total_ce_visit bigint,
    ce_visits_count bigint,
    percent_ce_sessions double,
    avg_ts_session double,
    percent_ce_ts double,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_author_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.textbook_snapshot_metrics(
	d_period int,
	d_textbook_id text,
	d_app_id text,
	d_channel text,
	status text,
	author_id text,
	content_count bigint,
	textbookunit_count bigint,
	avg_content double,
	content_types list<text>,
	total_ts double,
	creators_count bigint,
	board text,
	medium text,
	updated_date timestamp,
	PRIMARY KEY (d_period, d_textbook_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.textbook_metrics_summary_fact(
    d_period text,
    d_app_id text,
    d_channel text,
    unique_users_count bigint,
    total_sessions bigint,
    total_ts double,
    avg_ts_session double,
    textbooks_count bigint,
    unit_summary map<text,bigint>,
    lesson_summary map<text,bigint>,
    updated_date timestamp,
    PRIMARY KEY (d_period, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.plugin_snapshot_metrics (
     d_period int, 
     d_plugin_id text,
     d_app_id text,
     d_channel text,
     plugin_name text, 
     category text, 
     author text, 
     content_count bigint, 
     content_count_start bigint,
     updated_date timestamp,
     PRIMARY KEY (d_period, d_plugin_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_creation_metrics_db.template_snapshot_metrics (
     d_period int, 
     d_template_id text,
     d_app_id text,
     d_channel text,
     template_name text, 
     category text, 
     author_id text, 
     content_count bigint, 
     content_count_start bigint,
     question_count bigint,
     question_count_start bigint,
     updated_date timestamp,
     PRIMARY KEY (d_period, d_template_id, d_app_id, d_channel)
);

CREATE TABLE IF NOT EXISTS local_platform_db.workflow_usage_summary_fact (
    d_period int,
    d_channel text,
    d_app_id text,
    d_tag text,
    d_type text,
    d_mode text,
    d_device_id text,
    d_content_id text,
    d_user_id text,
    m_publish_date timestamp,
    m_last_sync_date timestamp,
    m_last_gen_date timestamp,
    m_total_ts double,
    m_total_sessions bigint,
    m_avg_ts_session double,
    m_total_interactions bigint,
    m_avg_interactions_min double,
    m_total_pageviews_count bigint,
    m_avg_pageviews double,
    m_total_users_count bigint,
    m_total_content_count bigint,
    m_total_devices_count bigint,
    m_unique_users blob,
    m_device_ids blob,
    m_contents blob,
    m_updated_date timestamp,
    PRIMARY KEY (d_period, d_channel, d_app_id, d_tag, d_type, d_mode, d_device_id, d_content_id, d_user_id) );

INSERT INTO local_platform_db.recommendation_config(config_key, config_value) VALUES ('device_reco_blacklist', ['org.ekstep.num.scrn.basic', 'do_30088866', 'numeracy_369', 'org.ekstep.aser', 'do_30088250', 'do_30014045', 'org.ekstep.delta', 'org.ekstep.esl1', 'do_30074519', 'domain_6444']);
INSERT INTO local_platform_db.recommendation_config(config_key, config_value) VALUES ('content_reco_blacklist', ['org.ekstep.num.scrn.basic', 'do_30088866', 'numeracy_369', 'org.ekstep.aser', 'do_30088250', 'do_30014045', 'org.ekstep.delta', 'org.ekstep.esl1', 'do_30074519', 'domain_6444']);

INSERT INTO local_platform_db.job_config(category, config_key, config_value) VALUES ('vv', 'content-own-rel', {'optimizationQueries':['CREATE INDEX ON :User(type)'],'cleanupQueries':['MATCH (usr :User {type:"author"})<-[r:createdBy]-(cnt :domain{IL_FUNC_OBJECT_TYPE:"Content"}) DELETE r','MATCH (usr :User {type:"author"})-[r:uses]->(cnc :domain{IL_FUNC_OBJECT_TYPE:"Concept"}) DELETE r','MATCH (usr:User {type:"author"})-[r:createdIn]->(lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) DELETE r','MATCH(usr:User{type: "author"}) DETACH DELETE usr', 'MATCH (cntt: ContentType) DETACH DELETE cntt'],'algorithmQueries':['MATCH (usr:User {type:"author"}) SET usr.contentCount=0, usr.liveContentCount=0, usr.conceptsCount=0', 'MATCH (usr:User{type:"author"}), (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}) WHERE usr.IL_UNIQUE_ID = cnt.createdBy MERGE (cnt)-[r:createdBy]->(usr)','MATCH (usr:User {type:"author"})<-[r:createdBy]-(cnt: domain{IL_FUNC_OBJECT_TYPE:"Content"}) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] WITH usr,count(cnt) as cc SET usr.contentCount = cc','MATCH (usr:User {type:"author"})<-[r:createdBy]-(cnt: domain{IL_FUNC_OBJECT_TYPE:"Content"}) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] WITH usr,count(cnt) as cc SET usr.liveContentCount = cc','MATCH (usr:User {type:"author"}), (cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) MERGE (usr)-[r:uses{contentCount:0, liveContentCount:0}]->(cnc)','MATCH (usr:User {type:"author"}), (cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) MATCH path = (usr)<-[:createdBy]-(cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"})-[nc:associatedTo]->(cnc), (usr)-[r:uses]->(cnc) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] WITH r, count(cnt) AS cc SET r.contentCount=cc','MATCH (usr:User {type:"author"}), (cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) MATCH path = (usr)<-[:createdBy]-(cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"})-[nc:associatedTo]->(cnc), (usr)-[r:uses]->(cnc) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] WITH r, count(cnt) AS cc SET r.liveContentCount=cc','MATCH p=(usr: User {type:"author"})-[r:uses]-(cnc: domain{IL_FUNC_OBJECT_TYPE:"Concept"}) WHERE r.contentCount > 0 WITH usr, count(p) AS cncCount SET usr.conceptsCount=cncCount','MATCH (usr :User {type:"author"}), (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) MERGE (usr)-[r:createdIn{contentCount:0, liveContentCount:0}]->(lan)','MATCH (usr:User {type:"author"}), (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}), (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (usr)-[r:createdIn]->(lan) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] AND cnt.createdBy = usr.IL_UNIQUE_ID AND lower(lan.name) IN extract(language IN cnt.language | lower(language)) WITH r, count(cnt) AS cc SET r.contentCount=cc','MATCH (usr:User {type:"author"}), (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}), (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (usr)-[r:createdIn]->(lan) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] AND cnt.createdBy = usr.IL_UNIQUE_ID AND lower(lan.name) IN extract(language IN cnt.language | lower(language)) WITH r, count(cnt) AS lcc SET r.liveContentCount=lcc', 'CREATE (cntt1: ContentType {IL_UNIQUE_ID: "worksheet", name: "Worksheet", contentCount: 0, liveContentCount: 0, appId: "", channel: "in.ekstep"}), (cntt2: ContentType {IL_UNIQUE_ID: "story", name: "Story", contentCount: 0, liveContentCount: 0, appId: "", channel: "in.ekstep"}), (cntt3: ContentType {IL_UNIQUE_ID: "game", name: "Game", contentCount: 0, liveContentCount: 0, appId: "", channel: "in.ekstep"}), (cntt4: ContentType {IL_UNIQUE_ID: "collection", name: "Collection", contentCount: 0, liveContentCount: 0, appId: "", channel: "in.ekstep"})', 'MATCH (usr :User {type:"author"}), (cntt:ContentType) MERGE (usr)-[r:uses{contentCount:0, liveContentCount:0}]->(cntt)', 'MATCH (usr:User {type:"author"}), (cntt:ContentType), (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (usr)-[r:uses]->(cntt) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] AND cnt.createdBy = usr.IL_UNIQUE_ID AND cntt.IL_UNIQUE_ID IN extract(conType IN cnt.contentType | lower(conType)) WITH r, count(cnt) AS cc SET r.contentCount=cc', 'MATCH (usr:User {type:"author"}), (cntt:ContentType), (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (usr)-[r:uses]->(cntt) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] AND cnt.createdBy = usr.IL_UNIQUE_ID AND cntt.IL_UNIQUE_ID IN extract(conType IN cnt.contentType | lower(conType)) WITH r, count(cnt) AS lcc SET r.liveContentCount=lcc', 'MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (cntt:ContentType) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] AND cntt.IL_UNIQUE_ID IN extract(conType IN cnt.contentType | lower(conType)) CREATE (cnt)-[r:isA]->(cntt) RETURN r', 'MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (cntt:ContentType) WHERE lower(cnt.contentType)IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] MATCH p=(cnt)-[r:isA]->(cntt) WITH cntt, COUNT(p) AS cc SET cntt.contentCount = cc', 'MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (cntt:ContentType) WHERE lower(cnt.contentType)IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] OPTIONAL MATCH p=(cnt)-[r:isA]->(cntt) WITH cntt, COUNT(p) AS lcc SET cntt.liveContentCount = lcc']});
INSERT INTO local_platform_db.job_config(category, config_key, config_value) VALUES ('vv', 'concept-lan-rel', {'cleanupQueries':['MATCH (cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"})-[r:usedIn]->(lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) DELETE r'],'algorithmQueries':['MATCH (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}), (cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) OPTIONAL MATCH p=(lan)<-[ln:expressedIn]-(cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"})-[nc:associatedTo]->(cnc) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] WITH cnc, lan, CASE WHEN p is null THEN 0 ELSE COUNT(p) END AS cc MERGE (cnc)-[r:usedIn{contentCount: cc}]->(lan) RETURN r', 'MATCH (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}), (cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) OPTIONAL MATCH p=(lan)<-[ln:expressedIn]-(cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"})-[nc:associatedTo]->(cnc) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] WITH cnc, lan, CASE WHEN p is null THEN 0 ELSE COUNT(p) END AS lcc MATCH (cnc)-[r:usedIn]->(lan) SET r.liveContentCount = lcc', 'MATCH (cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) SET cnc.contentCount=0, cnc.liveContentCount=0', 'MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"})-[r:associatedTo]->(cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] WITH cnc, count(r) AS cc SET cnc.contentCount = cc', 'MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"})-[r:associatedTo]->(cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] WITH cnc, count(r) AS lcc SET cnc.liveContentCount = lcc']});
INSERT INTO local_platform_db.job_config(category, config_key, config_value) VALUES ('vv', 'content-asset-rel', {'cleanupQueries':['MATCH (cnt: domain) - [r: uses] -> (ast: domain) where ast.contentType IN ["Asset"] DELETE r'],'algorithmQueries':['MATCH (ast:domain{IL_FUNC_OBJECT_TYPE:"Content", contentType:"Asset"}) SET ast.contentCount=0, ast.liveContentCount=0', 'MATCH (ast:domain{IL_FUNC_OBJECT_TYPE:"Content", contentType:"Asset"}), (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}) MATCH p=(ast)<-[r:uses]-(cnt) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] WITH ast, COUNT(p) AS cc SET ast.contentCount = cc', 'MATCH (ast:domain{IL_FUNC_OBJECT_TYPE:"Content", contentType:"Asset"}), (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}) MATCH p=(ast)<-[r:uses]-(cnt) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] WITH ast, COUNT(p) AS lcc SET ast.liveContentCount = lcc']});
INSERT INTO local_platform_db.job_config(category, config_key, config_value) VALUES ('vv', 'content-lang-rel', {'cleanupQueries':['MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"})-[r:expressedIn]->(lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) DELETE r','MATCH (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) REMOVE lan.contentCount, lan.liveContentCount'],'algorithmQueries':['MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE:"Content"}), (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) WHERE lower(cnt.contentType) IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] AND lower(lan.name) IN extract(language IN cnt.language | lower(language)) CREATE (cnt)-[r:expressedIn]->(lan) RETURN r', 'MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE: "Content"}), (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) WHERE lower(cnt.contentType)IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Draft", "Review", "Live"] MATCH p=(cnt)-[r:expressedIn]->(lan) WITH lan, COUNT(p) AS cc SET lan.contentCount = cc', 'MATCH (cnt:domain{IL_FUNC_OBJECT_TYPE: "Content"}), (lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) WHERE lower(cnt.contentType)IN ["story", "game", "collection", "worksheet"] AND cnt.status IN ["Live"] OPTIONAL MATCH p=(cnt)-[r:expressedIn]->(lan) WITH lan, COUNT(p) AS lcc SET lan.liveContentCount = lcc']});
INSERT INTO local_platform_db.job_config(category, config_key, config_value) VALUES ('vv', 're-enrichment-model', {'cleanupQueries':['MATCH  (usr:User{type: "author"})-[r:uses]-(cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) REMOVE r.confidence, r.lift', 'MATCH (usr:User{type:"author"})-[r:createdIn]->(lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) REMOVE r.confidence, r.lift', 'MATCH (usr:User{type:"author"})-[r:uses]->(cntt:ContentType) REMOVE r.confidence, r.lift'], 'algorithmQueries':['MATCH (cnt:domain {IL_FUNC_OBJECT_TYPE:"Content"}) where cnt.contentType in ["Game", "Worksheet", "Story", "Collection"] and cnt.status in ["Live", "Draft"] WITH count(cnt) as ncount MATCH (usr:User{type: "author"})-[r:uses]-(cnc:domain{IL_FUNC_OBJECT_TYPE:"Concept"}) WHERE cnc.contentCount > 0 WITH r, ncount, CASE usr.contentCount WHEN 0 THEN 0 ELSE toFloat(r.contentCount)/(toFloat(usr.contentCount)) END as confidence, CASE usr.contentCount WHEN 0 THEN 0 ELSE (toFloat(r.contentCount)*toFloat(ncount))/(toFloat(usr.contentCount)*toFloat(cnc.contentCount)) END as lift SET r.confidence = confidence, r.lift = lift', 'MATCH (cnt:domain {IL_FUNC_OBJECT_TYPE:"Content"}) where cnt.contentType in ["Game", "Worksheet", "Story", "Collection"] and cnt.status in ["Live", "Draft"] WITH count(cnt) as ncount MATCH (usr:User{type:"author"})-[r:createdIn]->(lan:domain{IL_FUNC_OBJECT_TYPE:"Language"}) WHERE lan.contentCount > 0 WITH r, ncount, CASE usr.contentCount WHEN 0 THEN 0 ELSE toFloat(r.contentCount)/(toFloat(usr.contentCount)) END as confidence, CASE usr.contentCount WHEN 0 THEN 0 ELSE (toFloat(r.contentCount)*toFloat(ncount))/(toFloat(usr.contentCount)*toFloat(lan.contentCount)) END as lift SET r.confidence = confidence, r.lift = lift', 'MATCH (cnt:domain {IL_FUNC_OBJECT_TYPE:"Content"}) where cnt.contentType in ["Game", "Worksheet", "Story", "Collection"] and cnt.status in ["Live", "Draft"] WITH count(cnt) as ncount MATCH (usr:User{type:"author"})-[r:uses]->(cntt:ContentType) WHERE cntt.contentCount > 0 WITH r, ncount, CASE usr.contentCount WHEN 0 THEN 0 ELSE toFloat(r.contentCount)/(toFloat(usr.contentCount)) END as confidence, CASE usr.contentCount WHEN 0 THEN 0 ELSE (toFloat(r.contentCount)*toFloat(ncount))/(toFloat(usr.contentCount)*toFloat(cntt.contentCount)) END as lift SET r.confidence = confidence, r.lift = lift']});


CREATE KEYSPACE IF NOT EXISTS local_content_store WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': '1'
};

CREATE TABLE IF NOT EXISTS local_content_store.content_data (
    content_id text PRIMARY KEY,
    body blob,
    last_updated_on timestamp,
    oldbody blob,
    stageicons blob);

CREATE TABLE IF NOT EXISTS local_platform_db.workflow_usage_summary (
    event_date date,
    total_content_play_sessions bigint,
    total_timespent double,
    total_interactions bigint,
    total_pageviews bigint,
    last_updated_at timestamp,
    PRIMARY KEY (event_date)
);

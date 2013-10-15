[

	/* =====================================================================================
		World Weather Online
		API Accessor Demo
	===================================================================================== */ 
	sys_listTypes !>> 'worldweatheronline' ? include('worldweatheronline.lasso')
	define br => '\r'
	local(key = 'XXX')
	// with params
	local(weather = worldweatheronline)
	#weather->key(#key)
	#weather->get('Newmarket,Ontario',-num_of_days=3)
	'Current temp in C for Newmarket, Ontario: ' + #weather->current_condition->temp_C + 'ºC'
	br
	'Forcast for '+#weather->weather->get(2)->date+': max temp in C for Newmarket, Ontario: ' + #weather->weather->get(1)->tempMaxC + 'ºC'
	
	br
	br
	'Timezone: '
	br
	#weather->searchtimezone
	'Local time: '+#weather->timezone->localTime
	br
	'UTC Offset: '+#weather->timezone->utcOffset

]
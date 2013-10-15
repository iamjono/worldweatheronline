[
	/* =============================================
		Lasso 9 API for worldweatheronline
	============================================= */
	define worldweatheronline => type {
		data
			private version::string 	= 'v1',
			private apikey::string 		= string,
			
			public request::string		= string,
			public request_type::string	= string,
			
			public current_condition::worldweatheronline_current_condition = worldweatheronline_current_condition,
			public weather::array		= array,
			public timezone::worldweatheronline_timezone = worldweatheronline_timezone,
			
			public response				= string
			// note weather is type array, expected to contain elements of type worldweatheronline_weather
		
		public oncreate() => {
			.request = string
		}
		public oncreate(q,-key::string) => {
			// initialize with correct params
			.request = #q
			.key(#key)
			// action request and set
			.get()
		}
		public key(k::string) => { .apikey = #k }
		
		public get(q::string=.request,...) => {
			// return if nothing specified
			not #q->size ? return
			// store request
			.request = #q
			
			// push incoming #rest params (from ...) into a params map
			local(params = map, requestparams = array)
			#rest->isA(::void) ? return
			with i in #rest do => {
				match(#i->type) => {
					case(::pair,::keyword)
						#params->insert(#i->name=#i->value)
					case(::array)
						#params->insertfrom(#i)
					case(::map)
						with key in #i->keys do => {
							#params->insert(
								#key = #i->find(#key)
							)
						}
	       			}
				
			}
			
			/* ======================================================
			assemble param string
			====================================================== */
			//num_of_days - Changes the number of day forecast you need.
			#params->keys >> 'num_of_days' ? #requestparams->insert('num_of_days='+integer(#params->find('num_of_days')))
			
			//date (Optional) - Get weather for a particular date.
			//It supports today, tomorrow and a date. The date should be in the yyyy-MM-dd format i.e. 20 April, 2010 will be 2010-04-20. 
			//e.g:- date=today or date=tomorrow or date=2010-04-21 
			if(#params->keys >> 'date') => {
				local(val = string)
				#params->find('date') == 'today' ? #val = 'today'
				#params->find('date') == 'tomorrow' ? #val = 'tomorrow'
				protect => {
					handle_error => { #val = date->format('yyyy-MM-dd') }
					not #val->size ? #val = date(#params->find('date'))->format('yyyy-MM-dd')
				}
				#requestparams->insert('date='+#val)
			}
			
			//fx (Optional) - Allows you to enable or disable normal weather output. 
			//The possible values are yes or no. By default it is yes 
			//e.g:- fx=yes or fx=no 
			#params->keys >> 'fx' && #params->find('fx')->asString == 'no' ? #requestparams->insert('fx=no')
			
			
			//cc (Optional) - Allows you to enable or disable current weather conditions output. The possible values are yes or no. By default it is yes 
			//e.g:- cc=yes or cc=no 
			#params->keys >> 'cc' && #params->find('cc')->asString == 'no' ? #requestparams->insert('cc=no')
			
			
			//includeLocation (Optional) - Returns the nearest weather point for which the weather data is returned for a given postcode, zipcode and lat/lon values. The possible values are yes or no. By default it is no 
			//e.g:- includeLocation=yes or includeLocation=no 
			#params->keys >> 'includeLocation' && #params->find('includeLocation')->asString == 'yes' ? #requestparams->insert('includeLocation=yes')


			//New! show_comments (Optional) - Disables CSV/TAB comments from the output. The possible values are yes or no. By default it is yes 
			//e.g:- show_comments=yes or show_comments=no
			#params->keys >> 'show_comments' && #params->find('show_comments')->asString == 'no' ? #requestparams->insert('show_comments=no')
			
			#requestparams->insert('extra=localObsTime')
			#requestparams->insert('format=json')
			#requestparams->insert('key='+.apikey)
			
			
			/* ======================================================
			Get data from remote web service
			====================================================== */
			.response = json_deserialize(include_url('http://api.worldweatheronline.com/free/'+.version+'/weather.ashx?q='+.request->asBytes->encodeurl+'&'+#requestparams->join('&'))->asString)->find('data')
			
			/* ======================================================
			Set data from response
			====================================================== */
			
			.request_type = .response->find('request')->first->find('type')
			
			//current_condition
			.current_condition->populate(.response->find('current_condition')->first)
			
			//forecast
			protect => {
				with w in .response->find('weather') do => {
					local(this = worldweatheronline_weather)
					#this->populate(#w)
					.weather->insert(#this)
				}
			}
		}
		public searchtimezone(q::string=.request) => {
			/* ======================================================
			q can be:
				City and Town Name
				IP Address
				UK Postcode
				Canada Postal Code
				US Zipcode
				Aiport code (IATA)
				Latitude and Longitude (in decimal)
			====================================================== */
			
			/* ======================================================
			Get data from remote web service
			====================================================== */
			.response = json_deserialize(
					include_url(
						'http://api.worldweatheronline.com/free/'+.version+'/tz.ashx?q='+.request->asBytes->encodeurl+'&format=json&key='+.apikey
					)
				)->find('data')
			
			/* ======================================================
			Set data from response
			====================================================== */
			.request_type = .response->find('request')->first->find('type')
			
			//timezone
			.timezone->populate(.response->find('time_zone')->first)

		}
	}
	
	define worldweatheronline_current_condition => type {
		data
			public observation_time,
			public temp_C,
			public windspeedMiles,
			public windspeedKmph,
			public winddirDegree,
			public winddir16Point,
			public weatherCode,
			public weatherDesc,
			public weatherIconUrl,
			public precipMM,
			public humidity,
			public visibility,
			public pressure,
			public cloudcover
		/* =====================================================================================
			observation_time	Time in UTC hhmm tt format. E.g.:- 06:45 AM or 11:34 PM
			temp_C	Temperature in degree Celsius
			windspeedMiles	Wind speed in miles per hour
			windspeedKmph	Wind speed in kilometre per hour
			winddirDegree	Wind direction in degree
			winddir16Point	Wind direction in 16-point compass
			weatherCode	Weather condition code
			weatherDesc	Weather description text
			weatherIconUrl	Weather icon url
			precipMM	Precipitation in millimetre
			humidity	Humidity in percentage
			visibility	Visibility in kilometre (km)
			pressure	Atmospheric pressure in millibars
			cloudcover	Cloud cover in percentage
		===================================================================================== */ 
		public populate(i::map) => {
			.observation_time 	= #i->find('observation_time')
			.temp_C 			= #i->find('temp_C')
			.windspeedMiles 	= #i->find('windspeedMiles')
			.windspeedKmph 		= #i->find('windspeedKmph')
			.winddirDegree 		= #i->find('winddirDegree')
			.winddir16Point 	= #i->find('winddir16Point')
			.weatherCode 		= #i->find('weatherCode')
			.weatherDesc 		= #i->find('weatherDesc')->first->find('value')
			.weatherIconUrl 	= #i->find('weatherIconUrl')->first->find('value')
			.precipMM 			= #i->find('precipMM')
			.humidity 			= #i->find('humidity')
			.visibility 		= #i->find('visibility')
			.pressure 			= #i->find('pressure')
			.cloudcover 		= #i->find('cloudcover')
		}
		
	}
	define worldweatheronline_weather => type {
		data
			public date,
			public tempMaxC,
			public tempMaxF,
			public tempMinC,
			public tempMinF,
			public windspeedMiles,
			public windspeedKmph,
			public winddirDegree,
			public winddirection,
			public winddir16Point,
			public weatherCode,
			public weatherIconUrl,
			public weatherDesc,
			public precipMM
		/* =====================================================================================
			date	Local forecast date, formatted as 'yyyy-MM-dd'. e.g.:- 2008-05-31
			tempMaxC	Maximum temperature of the day in degree Celsius.
			tempMaxF	Maximum temperature of the day in degree Fahrenheit.
			tempMinC	Minimum temperature of the day in degree Celsius.
			tempMinF	Minimum temperature of the day in degree Fahrenheit.
			windspeedMiles	Wind speed in miles per hour
			windspeedKmph	Wind speed in kilometre per hour
			winddirDegree	Wind direction in degree
			winddirection or winddir16Point	Wind direction in 16-point compass
			weatherCode	Weather condition code
			weatherIconUrl	Weather icon url
			weatherDesc	Weather description text
			precipMM	Precipitation amount in millimetre
		===================================================================================== */ 
		public populate(i::map) => {
			.date 				= #i->find('date')
			.tempMaxC 			= #i->find('tempMaxC')
			.tempMaxF 			= #i->find('tempMaxF')
			.tempMinC 			= #i->find('tempMinC')
			.tempMinF 			= #i->find('tempMinF')
			.windspeedMiles 	= #i->find('windspeedMiles')
			.windspeedKmph 		= #i->find('windspeedKmph')
			.winddirDegree 		= #i->find('winddirDegree')
			.winddirection 		= #i->find('winddirection')
			.winddir16Point 	= #i->find('winddir16Point')
			.weatherCode 		= #i->find('weatherCode')
			.weatherIconUrl 	= #i->find('weatherIconUrl')->first->find('value')
			.weatherDesc 		= #i->find('weatherDesc')->first->find('value')
			.precipMM 			= #i->find('precipMM')
		}
	}
	define worldweatheronline_timezone => type {
		data
			public localTime,
			public utcOffset
		/* =====================================================================================
			localTime	Current Local Time in yyyy-MM-dd hh:mm tt format. E.g.:- 2010-11-15 09:45 AM
			utcOffset	UTC offset in hour and minute. E.g:- 8.0 or 5.30
		===================================================================================== */ 
		public populate(i::map) => {
			.localTime 			= #i->find('localTime')
			.utcOffset 			= #i->find('utcOffset')
		}
	}
	
	
]
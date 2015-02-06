require './ooyala_api.rb'
require 'date'

API_KEY="YOUR_KEY_HERE"
SECRET="YOUR_SECRET_HERE"

#
# Pull all analytics data into local storage
#

# If customer wants stats between day X and day Y, enter Y+1 into endDate. Our analytics are quirky.
startDate = DateTime.new(2015,1,19)
endDate = DateTime.new(2015,1,26)

def apiRequestWithSig(method, uri, pageToken)
	t = Time.now
	expires = Time.local(t.year, t.mon, t.day, t.hour + 1).to_i
	params = { "api_key" => API_KEY, "expires" => expires, "limit" => 500}
	if(pageToken != nil)
		params["page_token"] = pageToken
		pageToken = "&page_token=%{ptoken}" % {ptoken: pageToken}
	end
	signature = CGI.escape(OoyalaApi.generate_signature(SECRET, method, uri, params, nil))
	getURI = 'http://api.ooyala.com%{uri}?api_key=%{apikey}&expires=%{expires}&limit=%{limit}&signature=%{signature}%{ptoken}' %  { uri: uri, apikey: API_KEY, expires: expires, signature: signature, limit: 500, ptoken: pageToken}
	request = RestClient::Request.new(
		:method  => method,
		:url     => getURI
	)
	response = request.execute
	return response
end

url = "/v2/analytics/reports/account/performance/videos/2015-01-19...2015-01-26"
firstResponse = apiRequestWithSig("GET", url, nil)

json_response = JSON.parse(firstResponse)
File.open("testfile.json", "w") do |outfile|
	outfile.write(firstResponse)
	outfile.close
end

next_token = json_response["next_page_token"]

secondResponse = apiRequestWithSig("GET", url, next_token)

json_response = JSON.parse(secondResponse)
File.open("testfile2.json", "w") do |outfile|
	outfile.write(secondResponse)
	outfile.close
end

puts "Done!"
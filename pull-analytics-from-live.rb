require './lib/ooyala_api.rb'
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

# Cheers, Phil.
def mergeHashes(source_hash, target_hash)
source_hash.each { |key, value|
   if target_hash.has_key?(key)
       target_hash[key] = target_hash[key] + value
   elsif
       target_hash[key] = value
   end
}
end

def getPage(url, pageToken)
	response = apiRequestWithSig("GET", url, pageToken)
	return response
end

def getPages(url)
	merged_hash = nil
	next_token = nil
	begin
		# Make request, get response
		response = getPage(url, next_token)
		response_hash = JSON.parse(response)
		# Set next_token
		next_token = response_hash["next_page_token"]
		if merged_hash == nil
			merged_hash = response_hash
		else
			mergeHashes(response_hash,merged_hash)
		end
	end until next_token == nil
	return merged_hash
end

url = "/v2/analytics/reports/account/performance/videos/2015-01-19...2015-01-26"
json_hash = getPages(url)

File.open("output/analytics_results.json", "w") do |outfile|
	outfile.write(JSON.pretty_generate(json_hash))
	outfile.close
end
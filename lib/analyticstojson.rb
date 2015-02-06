require './ooyala_api.rb'
require 'date'

API_KEY="YOUR_KEY_HERE"
SECRET="YOUR_SECRET_HERE"

class AnalyticsToJSON

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

	def runReport(fromDateString, toDateString)
		begin
		   fromDate = Date.parse(fromDateString)
		rescue ArgumentError
		   puts "Start Date is not a valid ISO date. Use the format yyyy-mm-dd, e.g. 2014-10-17"
		   exit(2)
		end
		begin
		   toDate = Date.parse(toDateString)
		rescue ArgumentError
		   puts "End Date is not a valid ISO date. Use the format yyyy-mm-dd, e.g. 2014-10-17"
		   exit(2)
		end

		# If customer wants stats between day X and day Y, we need to set an end date of Y+1. Our analytics are quirky.
		url = "/v2/analytics/reports/account/performance/videos/%{from}...%{to}" % { from: fromDate.to_s, to: (toDate+1).to_s }
		puts url
		json_hash = getPages(url)
		File.open("output/analytics_results.json", "w") do |outfile|
			outfile.write(JSON.pretty_generate(json_hash))
			outfile.close
		end
	end
end
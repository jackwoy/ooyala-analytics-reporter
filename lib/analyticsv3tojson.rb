require './lib/ooyala_api.rb'
require 'date'

class AnalyticsToJSON

	def initialize(apiKey, apiSecret)
		@@api_key = apiKey
		@@api_secret = apiSecret
	end

	def apiRequestWithSig(method, uri, pageNumber, startDate, endDate)
		t = Time.now
		uriForSig = uri.slice(0..(uri.index('?')-1))
		# FIXME: If this is altered, page calculation is thrown out of whack. Maybe expand the scope of this var?
		query_limit = 1000
		expires = Time.local(t.year, t.mon, t.day, t.hour + 1).to_i
		# FIXME: Messy, messy. Need to overhaul how query parameters are handled as a whole.
		params = { "api_key" => @@api_key, "expires" => expires, "limit" => query_limit, "order_by" => "none",
		"report_type" => "performance",
		"dimensions" => "asset",
		"metrics" => "displays,plays_requested,video_starts,playthrough_25,playthrough_50,playthrough_75,playthrough_100,time_watched,uniq_plays_requested",
		"start_date" => startDate.to_s,
		"end_date" => endDate.to_s,
		"sort" => "displays"}

#report_type=performance&dimensions=asset
#&metrics=displays,plays_requested,video_starts,playthrough_25,playthrough_50,playthrough_75,playthrough_100,time_watched,uniq_plays_requested
#&sort=displays&start_date=%{from}&end_date=%{to}

		if(pageNumber != nil)
			params["page"] = pageNumber
			pageNumber = "&page=%{pnum}" % {pnum: pageNumber}
		end
		signature = CGI.escape(OoyalaApi.generate_signature(@@api_secret, method, uriForSig, params, nil))
		getURI = 'http://api.ooyala.com%{uri}&api_key=%{apikey}&expires=%{expires}&limit=%{limit}&order_by=none&signature=%{signature}%{pnum}' %  { uri: uri, apikey: @@api_key, expires: expires, signature: signature, limit: query_limit, pnum: pageNumber}
		request = RestClient::Request.new(
			:method  => method,
			:url     => getURI
		)
		#puts getURI
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

	def getPage(url, pageNumber, startDate, endDate)
		response = apiRequestWithSig("GET", url, pageNumber, startDate, endDate)
		return response
	end

	def calculateNumPages(totalAssets, queryLimit)
		wholePages = totalAssets / queryLimit
		partialPagesPresent = (totalAssets % queryLimit) > 0
		if partialPagesPresent
			return wholePages + 1
		else
			return wholePages
		end
	end

	def getPages(url, startDate, endDate)
		merged_hash = nil
		next_page = 0
		total_count = nil
		readablePages = nil

		begin
			# Make request, get response
			response = getPage(url, next_page, startDate, endDate)
			response_hash = JSON.parse(response)

			if total_count == nil
				total_count = response_hash["total_count"]
			end

			if readablePages == nil
				readablePages = calculateNumPages(total_count, 1000)
			end

			puts "Processed page %{done} of %{total}" % {done: next_page + 1, total: readablePages}

			# Reduce total_count by the number of assets we're looking at per page.
			# FIXME: Pull limit from variable with broader scope.
			total_count = total_count - 1000

			next_page = next_page + 1

			if merged_hash == nil
				merged_hash = response_hash
			else
				mergeHashes(response_hash,merged_hash)
			end
		end until total_count <= 0
		return merged_hash
	end

	def runReport(fromDateString, toDateString, outFileName)
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
		if outFileName == nil
			outFileName = "analytics_results.json"
		end
		# If customer wants stats between day X and day Y, we need to set an end date of Y+1. Our analytics are quirky.
		#url = "/v2/analytics/reports/account/performance/videos/%{from}...%{to}" % { from: fromDate.to_s, to: (toDate+1).to_s }
		url = "/v3/analytics/reports?report_type=performance&dimensions=asset&metrics=displays,plays_requested,video_starts,playthrough_25,playthrough_50,playthrough_75,playthrough_100,time_watched,uniq_plays_requested&sort=displays&start_date=%{from}&end_date=%{to}" % { from: fromDate.to_s, to: (toDate+1).to_s }
		#url = "/v3/analytics/reports?report_type=performance&dimensions=asset&metrics=displays,plays_requested&start_date=%{from}&end_date=%{to}" % { from: fromDate.to_s, to: (toDate+1).to_s }
		json_hash = getPages(url, fromDate, toDate+1)
		File.open(outFileName, "w") do |outfile|
			outfile.write(JSON.pretty_generate(json_hash))
			outfile.close
		end
	end
end
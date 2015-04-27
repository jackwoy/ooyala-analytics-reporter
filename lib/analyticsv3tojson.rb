require './lib/ooyala_api.rb'
require 'date'

class AnalyticsV3ToJSON
	attr_accessor :extra_params
	def initialize(apiKey, apiSecret)
		@@api_key = apiKey
		@@api_secret = apiSecret
		# Still need to improve this, but it's better than it used to be.
		@@query_limit = 1000
	end

	def hashifyParameterString(param_string)
		param_hash = {}
		param_string.split('&').each do |pair|
			key,value = pair.split('=',2)
			param_hash[key] = value
		end
		return param_hash
	end

	def stringifyParameterHash(param_hash)
		aggregator = ""
		param_hash.each do |key, value|
			aggregator = aggregator + "#{key}=#{value}&"
		end
		return aggregator.chomp('&')
	end

	def apiRequestWithSig(method, uri, pageNumber)
		t = Time.now
		uriForSig = uri.slice(0..(uri.index('?')-1))
		uriForParams = uri.slice((uri.index('?')+1)..uri.length)

		expires = Time.local(t.year, t.mon, t.day, t.hour + 1).to_i
		# FIXME: Better than it was, but still not great. Could make some performance savings by not regenerating this hash every time.
		params = hashifyParameterString(uriForParams)
		params["api_key"] = @@api_key
		params["expires"] = expires
		params["limit"] = @@query_limit
		params["page"] = pageNumber if(pageNumber != nil)

		if(@extra_params != nil)
			extra_hash = hashifyParameterString(@extra_params)
			destructiveMergeHashes(extra_hash,params)
			#puts "Merged in additional parameters."
		end

		params["signature"] = CGI.escape(OoyalaApi.generate_signature(@@api_secret, method, uriForSig, params, nil))

		getURI = 'http://api.ooyala.com%{uri}?%{param_string}' %  { uri: uriForSig, param_string: stringifyParameterHash(params) }

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

	def destructiveMergeHashes(source_hash, target_hash)
		source_hash.each { |key, value|
	       target_hash[key] = value
		}
	end

	def getPage(url, pageNumber)
		response = apiRequestWithSig("GET", url, pageNumber)
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

	def getPages(url)
		merged_hash = nil
		next_page = 0
		total_count = nil
		readablePages = nil

		begin
			# Make request, get response
			response = getPage(url, next_page)
			response_hash = JSON.parse(response)

			if total_count == nil
				total_count = response_hash["total_count"]
			end

			if readablePages == nil
				readablePages = calculateNumPages(total_count, @@query_limit)
			end

			puts "Processed page %{done} of %{total}" % {done: next_page + 1, total: readablePages}

			# Reduce total_count by the number of assets we're looking at per page.
			total_count = total_count - @@query_limit

			next_page = next_page + 1

			if merged_hash == nil
				merged_hash = response_hash
			else
				mergeHashes(response_hash,merged_hash)
			end
		end until total_count <= 0
		return merged_hash
	end

	def getReport(fromDateString, toDateString, outFileName)
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
		url = "/v3/analytics/reports?report_type=performance&dimensions=asset&start_date=%{from}&end_date=%{to}" % { from: fromDate.to_s, to: (toDate+1).to_s }
		json_hash = getPages(url)
		File.open(outFileName, "w") do |outfile|
			outfile.write(JSON.pretty_generate(json_hash))
			outfile.close
		end
	end
end
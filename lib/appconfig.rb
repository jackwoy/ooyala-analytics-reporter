require 'yaml'

class AppConfig

	def getConfig(config_filename)
		if !validateConfig(config_filename)
		  puts "Specified config file %{filename} failed validation." % {filename: config_filename}
		  exit(2)
		end
		return YAML.load_file(config_filename)
	end

	# Deprecated - method will be removed later.
	def getConfigName(config_filename)
	  config_hash = YAML.load_file(config_filename)
	  return config_hash["name"]
	end

	def validateConfig(config_filename)
		config_is_valid = true
		# Check config file exists
		if !File.exist?(config_filename)
		  puts "Specified config file %{filename} not found." % {filename: config_filename}
		  config_is_valid = false
		  # Return here, as running the rest of the tests is nonsensical without a config file available.
		  return config_is_valid
		end

		# FIXME: Could do with removing duplicated effort of reading the config file.
		config_hash = YAML.load_file(config_filename)

		required_keys = ["api_key","api_secret","output_folder"]

		# Check for presence of required config fields
		required_keys.each_index {|i|
		  if !config_hash.keys.include?(required_keys[i])
		    puts i
		    puts "Missing required key %{key}" % {key: required_keys[i]}
		    config_is_valid = false
		  end
		}
		# Bail out early if we're missing required keys.
		return config_is_valid if !config_is_valid

		# Validate API key (34 chars long)
		if config_hash["api_key"].length != 34
		  puts "API key is not valid - incorrect length."
		  config_is_valid = false
		end

		# Validate API secret (40 chars long)
		if config_hash["api_secret"].length != 40
		  puts "API secret is not valid - incorrect length."
		  config_is_valid = false
		end

		return config_is_valid
	end

end
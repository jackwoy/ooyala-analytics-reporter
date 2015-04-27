# ooyala-analytics-reporter
Ruby scripts for producing CSV exports from Ooyala Backlot and Ooyala IQ that are not restricted to a limited number of lines

This version is likely to be a little rough around the edges, but easier to use than previous versions.

**How to Use**

1. Open config.yaml in a text editor
2. Replace API_KEY_HERE and API_SECRET_HERE with your API Key and API Secret from Backlot
3. Open a terminal window
4. Run generate-report.rb -s START_DATE -e END_DATE (replacing START_DATE and END_DATE with your desired dates in ISO format, e.g. generate-report.rb -s 2015-01-26 -e 2015-02-01 for January 26th 2015 to February 1st 2015.)
5. The output folder should now contain a file with a name starting with csv_analytics_results.

**Generating reports for V2 Analytics**

The script is currently set up to default to generating reports from Ooyala's IQ analytics system. To force the script to generate reports using Ooyala's V2 analytics system instead, simply include either the -o or the --old command line argument when running generate-report.rb.

**Optional Extra Parameters**
When using v3 analytics, there is now limited support for additional parameters in the script. This is strictly an experimental feature, and will cause the script to throw errors if any parameters are passed to the script which substantially change the format of the data returned from the API for processing.

For example, the `filters` parameter will work fine, as it restricts but does not modify the dataset returned. `dimensions` on the other hand will change the reporting structure, and cause the JSON to CSV step to freak out. An upgrade to the CSV generator to handle this sort of thing is pending.

To use the extra parameters flag, just include either the -p or --params command line arguments when running generate-report.rb. For example:

`ruby generate-report.rb -s 2015-03-01 -e 2015-03-01 -p "filters=device_type=='mobile'"`

Note that if your parameters contain quote characters, you will either need to escape them with a backslash, or wrap the parameters in inverted commas, as demonstrated above.
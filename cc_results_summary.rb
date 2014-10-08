require 'csv'
require 'date'
require 'open-uri'
require 'json'

@cc_api_key = "MUHAHAHAH"
@cc_token = "MUHAHAHAH"
@cc_request_uri = 'https://api.constantcontact.com/v2'


def cc_api_call(request_query)
	url = "#{@cc_request_uri}#{request_query}#{@cc_api_key}"
	response = open(url,"Authorization" => "Bearer #{@cc_token}").read
end


def cc_blasts_since(start_date, end_date)
	end_date = Date.parse(end_date).to_date
	cc_request_query = "/emailmarketing/campaigns?status=SENT&modified_since=#{start_date}&api_key="
	response = cc_api_call(cc_request_query)
	results = JSON.parse(response)
	blast_list = []
	results["results"].each do |blast_data|
		mod_date = Date.parse(blast_data["modified_date"]).to_date
		if mod_date <= end_date
			blast_list  << blast_data["id"]
		end
	end
	return blast_list
end


def cc_blast_stats(blast_list)
	blast_results = {"sends" => 0, "opens" => 0, "clicks" =>0, "forwards" =>0, "unsubscribes" => 0, "bounces" => 0, "spam_count" => 0}
	blast_list.each do |blast_id|
		cc_request_query = "/emailmarketing/campaigns/#{blast_id}?api_key="
		response = cc_api_call(cc_request_query)
		results = JSON.parse(response)
		results["tracking_summary"].each do |stat, value|
			blast_results[stat] += value
		end
	end
	return blast_results

end


def welcome_message
	puts "CONSTANT CONTACT Results Puller"
end


def get_date
	date_input = STDIN.gets()
	the_date = Date.parse(date_input).to_date
	rescue 
		puts "That's not a date"
		the_date = get_date
	
return the_date
end


def get_start_end_dates(format)
	puts "Please enter the START DATE in the form YYYY-MM-DD. such as 2014-09-22."
	start_date = get_date
	puts "Please enter the END DATE in the form YYYY-MM-DD. such as 2014-09-22."
	end_date = get_date
	puts
	puts "You entered  START DATE #{start_date}   END DATE #{end_date}"
	date_now = DateTime.now.to_date
	past_limit = Date.parse('2011-01-01').to_date
	puts "I ain't Dr. Who. The start or end is in the future" if start_date > date_now or end_date > date_now
	puts "You can't blast in the past. At least before 2011" if start_date < past_limit or end_date < past_limit
	puts "This ain't Benjamin Button. Dates are inversed" if start_date > end_date or end_date < start_date
	case
		when format == "string"
			start_date = start_date.to_s
			end_date = end_date.to_s
	end
	return start_date, end_date
end


def ok_to_proceed
	puts "Enter Y to begin or N to quit"
	start_answer = STDIN.gets()
	start_answer.chomp!.upcase!
	exit if start_answer != "Y"
end


def results_maker(blast_results)
	sent_count = blast_results["sends"]
	open_rate = blast_results["opens"].to_f/sent_count.to_f
	click_rate = blast_results["clicks"].to_f/sent_count.to_f
	bounce_rate = blast_results["bounces"].to_f/sent_count.to_f
	unsub_rate = (blast_results["unsubscribes"].to_f + blast_results["spam_count"])/sent_count.to_f
	return sent_count, open_rate, click_rate, bounce_rate, unsub_rate
end


def write_to_csv(start_date, end_date, sent_count, open_rate, click_rate, bounce_rate, unsub_rate)
	file_date = DateTime.now.strftime("%Y%d%m_%I%M%p")
	CSV.open("constant_contact_results_#{file_date}.csv", "wb") do |csv|
		csv << ["CONSTANT CONTACT RESULTS"]
		csv << ["Time Period", start_date, end_date]
		csv << ["Results Pulled", DateTime.now.strftime("%Y%d%m_%I%M%p")]
		csv << []
		csv << ["Sent",sent_count]
		csv << ["Open Rate",open_rate]
		csv << ["Click Rate",click_rate]
		csv << ["Bounce Rate",bounce_rate]
		csv << ["Unsub Rate",unsub_rate]
		csv << []
	end
	rescue
		puts "The CSV results file is probably open or in use by another application. PLEASE CLOSE IT"; exit
		
	

end


def console_output(start_date, end_date, sent_count, open_rate, click_rate, bounce_rate, unsub_rate)
	puts
	puts "Start Date: #{start_date}  End Date: #{end_date}"
	puts "Sent: #{sent_count}  Open Rate: #{open_rate}  Click Rate: #{click_rate}  Bounce Rate: #{bounce_rate}  Unsub_rate:  #{unsub_rate}"
	puts
end


def done_message
	puts "Results written to CSV in the same folder as this program"
	puts "GOOD BYE"

end


#*******************************MAIN ROUNTINE***********************************
begin
	
	welcome_message
	
	start_date, end_date = get_start_end_dates("string")
	
	start_answer = ok_to_proceed
	
	blast_list = cc_blasts_since(start_date, end_date) 
	
	blast_results = cc_blast_stats(blast_list)
	
	sent_count, open_rate, click_rate, bounce_rate, unsub_rate = results_maker(blast_results)
	
	write_to_csv(start_date, end_date, sent_count, open_rate, click_rate, bounce_rate, unsub_rate)
	
	console_output(start_date, end_date, sent_count, open_rate, click_rate, bounce_rate, unsub_rate)
	
	done_message	
	
end

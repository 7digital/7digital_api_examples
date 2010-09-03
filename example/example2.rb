require "rest-client"
require '../lib/oauth/lib/oauth/client/net_http'
require 'nokogiri'
require 'watir'
require 'firewatir'

#puts RestClient.get "http://api.7digital.com/1.2/status?oauth_consumer_key=musichackday"
#puts RestClient.get "http://api.7digital.com/1.2/oauth/requesttoken?oauth_consumer_key=musichackday"
#puts RestClient.get "http://api.7digital.com/1.2/"
@@consumer_key = "musichackday"
@@consumer_secret = "C2uS4enU96agunaF"
@@token = ''
@@token_secret = ''

@@oauth_token_file = "./oauth_token.txt"

## DO NOT REQUEST NEW OUTH TOKENS FOR EACH REQUEST
@@oauth_token = ''#normally saved to DB once acquired
@@oauth_token_secret = ''  #normally saved to DB once acquired

	def get_auth_consumer
		OAuth::Consumer.new( @@consumer_key, @@consumer_secret)
	end
	
	def get_http_and_request_objects(uri)
		request_uri = URI.parse(uri)
		http = Net::HTTP.new(request_uri.host, request_uri.port)
		request = Net::HTTP::Get.new(request_uri.path)
		return http, request
	end
	
	def get_nonce_and_timestamp
	    nonce = rand(2**128).to_s
		timestamp = Time.now.to_i.to_s
		return nonce, timestamp
	end
	
	
	def step_by_step_token_request(uri)
		consumer = get_auth_consumer
		nonce , timestamp =  get_nonce_and_timestamp
		http, request = get_http_and_request_objects(uri)
		request.oauth!(http, consumer, nil, {:scheme=>:query_string,:nonce => nonce, :timestamp => timestamp})
		http.request(request)
	end
  
	def step_by_step_auth_token_request(uri)
		consumer = get_auth_consumer
		token_obj = OAuth::Token.new( @@token, @@token_secret)
		nonce , timestamp =  get_nonce_and_timestamp
		http, request = get_http_and_request_objects(uri)
		request.oauth!(http, consumer, token_obj, {:scheme=>:query_string,:nonce => nonce, :timestamp => timestamp})
		http.request(request)
	end
  
	def step_by_step_locker_request(uri)
		consumer = get_auth_consumer
		token_obj = OAuth::Token.new( @@oauth_token, @@oauth_token_secret)
		puts "Using #{@@oauth_token} and #{@@oauth_token_secret}"
		nonce , timestamp =  get_nonce_and_timestamp
		http, request = get_http_and_request_objects(uri)
		request.oauth!(http, consumer, token_obj, {:scheme=>:query_string,:nonce => nonce, :timestamp => timestamp})
		http.request(request)
	end
  
    def oauth_first_leg_get_request_token
		puts "1st leg Request Token"
		result = step_by_step_token_request('http://api.7digital.com/1.2/oauth/requesttoken')
		puts "Result: " + result.body.to_s
		
		xml_doc = Nokogiri::XML(result.body.to_s)
	
		xml_doc.xpath('//oauth_request_token/oauth_token').each do |node|
			@@token = node.text
			puts "Token:" + @@token
		end
		
		xml_doc.xpath('//oauth_request_token/oauth_token_secret').each do |node|
			@@token_secret = node.text
			puts "Token Secret:" + @@token_secret
		end
	end
	
	def oauth_second_leg_authorisation_of_token
		puts "2nd Leg : Authorisation"
		browser = Watir::Browser.new
		browser.goto("https://account.7digital.com/musichackday/oauth/authorise?oauth_token=#{@@token}")
		browser.button(:text, "Allow").click
		browser.close
		sleep 2
	end
		
	def oauth_third_leg_request_oauth_tokens
		puts "3rd leg Request Token"
		auth_result = step_by_step_auth_token_request('http://api.7digital.com/1.2/oauth/accesstoken')
		puts "Auth Result: " + auth_result.body.to_s
		
		auth_doc = Nokogiri::XML(auth_result.body.to_s)
		
		auth_doc.xpath('//oauth_access_token/oauth_token').each do |node|
			@@oauth_token = node.text
			puts "Auth Token:" + @@oauth_token
		end
		
		auth_doc.xpath('//oauth_access_token/oauth_token_secret').each do |node|
			@@oauth_token_secret = node.text
			puts "Auth Token Secret:" + @@oauth_token_secret
		end
		
		if (@@oauth_token_secret == '')
			puts "Failed to get authorised token, exiting..."
			Process.exit
		end
	end
  
	def write_auth_token_file
		f = File.new(@@oauth_token_file, 'w')
		f.sync	
		f.puts "token:" + @@oauth_token
		f.puts "token_secret:" + @@oauth_token_secret
		f.close
	end
  
	def setup_auth_token_file
		puts "Writing token file"
		oauth_first_leg_get_request_token
		oauth_second_leg_authorisation_of_token
		oauth_third_leg_request_oauth_tokens
		if(@@oauth_token_secret != '')
			write_auth_token_file
		end
	end
  
	def parse_token_file_line (line)
		puts line 
		@@oauth_token = line.split(/:/)[1].chomp.chomp if line =~ /token:/
		puts "file_token:" + @@oauth_token if line =~ /token:/
		@@oauth_token_secret = line.split(/:/)[1].chomp.chomp if line =~ /token_secret:/
		puts "file_token_secret:" + @@oauth_token_secret if line =~ /token_secret:/
	end
  
	def get_oauth_tokens_from_file
		if !(FileTest.exist?(@@oauth_token_file))
			setup_auth_token_file
		else
			puts "Found file"
		end 
		auth_file = File.open(@@oauth_token_file)
	   
		auth_file.each do |line|
			parse_token_file_line (line)
		end
		auth_file.close
	end
  
	get_oauth_tokens_from_file
	
	puts "Getting Locker Data"
	locker_result = step_by_step_locker_request('http://api.7digital.com/1.2/user/locker')
	
	puts "Parsing Locker Data"
	#puts "Locker Result: " + locker_result.body.to_s
	
	locker_doc = Nokogiri::XML(locker_result.body.to_s)
	
	puts "Parse Locker Xml"
	locker_doc.xpath('//locker/lockerReleases').each do |node|
		puts "Title:" + node.xpath('.//lockerRelease/release/title').text
		#@@locker_title = node.text
		#puts "Auth Token Secret:" + @@oauth_token_secret
	end
require 'net/http'
require 'uri'
require 'json'
require_relative 'string_monkey'

# Configure here
HOST = ENV['host'] || 'crmsport.ru'
HOST_PORT = ENV['port'] || 80
SECURE = false
TAB = ' ' * 3

# API endpoints
API = {
  user_auth: {
    description: 'Auth user',
    path: '/users/sign_in/',
    method: :post,
    params: %i(email password)
  },

  users_list: {
    description: 'Get users list',
    path: '/users',
    method: :get,
  },

  teams_list: {
    description: 'Get teams list',
    path: '/teams',
    method: :get,
  }
}.freeze

# Storage
HEADERS = {}

# Auth user
#
# @param email: [String]
# @param password: [String]
def user_sign_in(email:, password:)
  request_server(:user_auth, options: { params: { email: email, password: password } })
end

# Get users list
def users_list
  request_server(:users_list)
end

# Get teams list
def teams_list
  request_server(:teams_list)
end

# @param seconds [Integer]
def sleep_seconds(seconds)
  say_info "#{TAB}Will sleep for #{seconds} seconds"
  seconds.times do |time|
    say "#{TAB}#{TAB}#{ '.' * (time + 1) } #{ " #{time} s" if (time % 5 == 0) }"
    sleep 1
  end
end

def say(message)
  puts message
end

def say_info(message)
  puts message.green
end

def say_warning(message)
  puts message
end

def say_error(message)
  puts message.red
end

private

# @param action [Symbol] one of API's key
#
# @raise [ArgumentError]
def request_server(action, options: {})
  raise ArgumentError, "Unknown action `#{action}`" unless API.keys.include?(action)

  api = API[action]
  method = api[:method] || :get

  request_method = "request_server_#{method}"
  raise ArgumentError, "Unknown server method `#{request_method}`" if respond_to?(request_method)
  request_uri = request_uri(api, options)
  send(request_method, request_uri, api, options)
end

def process_request_server(uri, api)
  http = Net::HTTP.new(uri.host, uri.port)
  headers = { 'Accept' => 'application/json', 'Api-Version' => '1' }
  headers = bearer_token_headers!(headers)

  if block_given?
    request = yield(uri, headers)

    begin
      say_info "#{TAB}#{api[:description]}" unless api[:description].nil?
      say "#{TAB}#{TAB}--> #{api[:method].to_s.upcase.bg_gray.black.bold} #{api[:path]}"

      if !headers.nil? and headers.count > 0
        headers.each { |name, value| say "#{TAB}#{TAB}#{TAB} #{'Header'.gray} #{name}: #{value}" }

        say "\n"
      end

      response = http.request(request, )
    rescue => e
      say_error "HTTP-error: #{e}"
    end

    parse_response response
  else
    say_warning 'Do not know what to do.'
    nil
  end
end

# @param response [Net::HTTPResponse]
def parse_response(response)
  success = true

  say_response = -> (_response) {
    body_description = {}
    unless _response.body.nil?
      begin
        body_description = JSON.parse(_response.body)
        say "#{TAB}#{TAB}|_#{body_description}" unless body_description.nil?
      rescue => e
        say "#{TAB}#{TAB}|_ Can't parse response: #{e.message}"
      end
    end
    body_description
  }

  say_headers = -> (_response) {
    %w(refresh-token access-token firebase-token client uid).each do |header_name|
      unless _response.header[header_name].nil?
        say "#{TAB}#{TAB}#{TAB} #{'Header'.gray} #{header_name}: #{_response.header[header_name]}"
        HEADERS[header_name] = _response.header[header_name]
      end
    end
  }

  if response.kind_of?(Net::HTTPClientError) or response.kind_of?(Net::HTTPServerError)
    success = false
    say_error "#{TAB}#{TAB}<-- Server returns error with code #{response.code}"
    body_description = say_response.call(response)
    exit
  else
    body_description = say_response.call(response)
    say_info "#{TAB}#{TAB}<-- Server returns #{response.code}"
    say_headers.call(response)
    say_info "\n"
  end

  say_info "\n"

  body_description if success
end

# @param uri [URI]
# @param api [Hash]
# @param options [Hash]
#
# @return [HTTP]
def request_server_post(uri, api, options = {})
  process_request_server(uri, api) do |u, headers|
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.set_form_data(options[:params]) unless api[:params].nil? and api[:params].nil?
    request
  end
end

def request_server_get(uri, api, _ = {})
  process_request_server(uri, api) do |u, headers|
    Net::HTTP::Get.new(uri.request_uri, headers)
  end
end

# @param action [Hash]
# @param options [Hash]
#
# @return [URI]
def request_uri(action, options = {})
  arguments = { host: HOST, port: HOST_PORT, path: action[:path] }

  if action[:method] == :get and !action[:params].nil? and !options[:params].nil?
    arguments[:query] = URI.encode_www_form options[:params]
  end

  SECURE ? URI::HTTPS.build(arguments) : URI::HTTP.build(arguments)
end

# @param headers [Hash<String:String>]
#
# @return [Hash<String:String>]
def bearer_token_headers!(headers = {})
  %w(access-token client uid).each do |header_name|
    headers[header_name] = HEADERS[header_name] unless HEADERS[header_name].nil?
  end

  headers
end
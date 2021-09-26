require 'sinatra'
require 'securerandom'
require 'openid_connect'

set :port => 8080
set :sessions, true


def init_client        
  discovery = OpenIDConnect::Discovery::Provider::Config.discover! ENV['ISSUER_BASE_URL']
  return OpenIDConnect::Client.new(
      identifier: ENV['CLIENT_ID'],
      secret: ENV['CLIENT_SECRET'],
      redirect_uri: ENV['REDIRECT_URI'],
      authorization_endpoint: discovery.authorization_endpoint,
      token_endpoint: discovery.token_endpoint,
      userinfo_endpoint: discovery.userinfo_endpoint
  ), discovery
end

client, discovery = init_client

get '/' do
  erb :index
end

get '/login' do
  nonce = SecureRandom.urlsafe_base64 
  state = SecureRandom.urlsafe_base64 
  
  session['nonce'] = nonce
  session['state'] = state

  redirect_uri = client.authorization_uri(
    scope: [:profile, :email],
    state: state,
    nonce: nonce
  )

  redirect redirect_uri
end

get '/callback' do 

  if params['code'].blank?
    halt 400,  {'Content-Type' => 'text/plain'}, 'missing code'
  end

  if params['state'].blank? or params['state'] != session['state']
    halt 400,  {'Content-Type' => 'text/plain'}, 'bad or mismatching state'
  end

  if session['nonce'].blank?
    halt 400,  {'Content-Type' => 'text/plain'}, 'missing nonce'
  end

  client.authorization_code = params['code']
  @access_token = client.access_token!
  @id_token = OpenIDConnect::ResponseObject::IdToken.decode @access_token.id_token, discovery.jwks

  @id_token.verify!({:nonce => session["nonce"], :issuer => ENV['ISSUER_BASE_URL'], :client_id => ENV['CLIENT_ID'] })  
  @user_info = @access_token.userinfo!
  
  @logout_url = discovery.end_session_endpoint + "?id_token_hint=" +  @access_token.id_token.to_s + "&post_logout_redirect_uri=https://localhost"

  erb :post_login
  
end

class Protected < Sinatra::Base

  def initialize(app)
   super(app)
   @client, @discovery = init_client
  end

  before "/protected*" do
    unless "Bearer ".in? request.env['HTTP_AUTHORIZATION']
      halt 401, "Access denied, missing token."
    end

    token = request.env['HTTP_AUTHORIZATION']
    token["Bearer "] = ""

    @access_token = JSON::JWT.decode(token, @discovery.jwks)

    if @access_token["exp"].to_i < Time.now.to_i
      halt 401, "token expired"
    end

    if @access_token["iss"] != ENV['ISSUER_BASE_URL']
      halt 401, "wrong issuer"
    end

    if @access_token["client_id"] != ENV['CLIENT_ID']
      halt 401, "wrong client id"
    end
  end

  def hasAnyOfScopes(scopes)
    @access_token["scp"].any? { |scope| scopes.include? scope }
  end

  get "/protected" do
    unless hasAnyOfScopes(["openid"])
      halt 403, "Missing scopes"
    end
    
    return 200, "You are varified"
  end
end

use Protected
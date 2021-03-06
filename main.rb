require 'sinatra'
require 'securerandom'
require 'openid_connect'

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

class Login < Sinatra::Base
  set :sessions, true

  def initialize()
    super()
    @client, @discovery = init_client
  end
 
  get '/' do
    erb :index
  end

  get '/login' do
    nonce = SecureRandom.urlsafe_base64 
    state = SecureRandom.urlsafe_base64 
    
    session['nonce'] = nonce
    session['state'] = state

    redirect_uri = @client.authorization_uri(
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

    if params['state'].blank? or session['state'].blank? or params['state'] != session['state']
      halt 400,  {'Content-Type' => 'text/plain'}, 'bad or mismatching state'
    end
    session.delete('state')


    if session['nonce'].blank?
      halt 400,  {'Content-Type' => 'text/plain'}, 'missing nonce'
    end

    @client.authorization_code = params['code']
    @access_token = @client.access_token!
    @id_token = OpenIDConnect::ResponseObject::IdToken.decode @access_token.id_token, @discovery.jwks

    @id_token.verify!({:nonce => session["nonce"], :issuer => ENV['ISSUER_BASE_URL'], :client_id => ENV['CLIENT_ID'] })  
    @user_info = @access_token.userinfo!
    
    @logout_redirect_url = ENV['REDIRECT_URI'].gsub("/callback", "")
    @logout_url = @discovery.end_session_endpoint + "?id_token_hint=" +  @access_token.id_token.to_s + "&post_logout_redirect_uri=" + @logout_redirect_url

    erb :post_login
    
  end
end

class Protected < Sinatra::Base
  @@client, @@discovery = init_client

  before do
    unless !request.env['HTTP_AUTHORIZATION'].blank? and "Bearer ".in? request.env['HTTP_AUTHORIZATION']
      halt 401, "missing token."
    end

    token = request.env['HTTP_AUTHORIZATION']
    token["Bearer "] = ""

    begin
      @access_token = JSON::JWT.decode(token, @@discovery.jwks)
    rescue => exception
      halt 401, "bad token"
    end

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

  def has_any_of_scopes?(scopes)
    @access_token["scp"].any? { |scope| scopes.include? scope }
  end

  get "/" do
    unless has_any_of_scopes?(["openid"])
      halt 403, "Missing scopes"
    end
    
    return 200, "You are varified"
  end
end
require 'test_helper'
require 'omniauth-matrix'
require 'openssl'
require 'base64'

class StrategyTest < StrategyTestCase
  include OAuth2StrategyTests
end

class ClientTest < StrategyTestCase
  test 'has correct Facebook site' do
    assert_equal 'http://storm.dev', strategy.client.site
  end

  test 'has correct authorize url' do
    assert_equal '/auth/matrix/authorize', strategy.client.options[:authorize_url]
  end

  test 'has correct token url' do
    assert_equal '/oauth/token', strategy.client.options[:token_url]
  end
end

class CallbackUrlTest < StrategyTestCase
  test "returns the default callback url" do
    url_base = 'http://auth.request.com'
    @request.stubs(:url).returns("#{url_base}/some/page")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    assert_equal "#{url_base}/auth/matrix/callback", strategy.callback_url
  end

  test "returns path from callback_path option" do
    @options = { :callback_path => "/auth/FB/done"}
    url_base = 'http://auth.request.com'
    @request.stubs(:url).returns("#{url_base}/page/path")
    strategy.stubs(:script_name).returns('') # as not to depend on Rack env
    assert_equal "#{url_base}/auth/FB/done", strategy.callback_url
  end

  #test "returns url from callback_url option" do
    #url = 'http://auth.myapp.com/auth/fb/callback'
    #@options = { :callback_url => url }
    #assert_equal url, strategy.callback_url
  #end
end

class AuthorizeParamsTest < StrategyTestCase
  test 'includes state parameter from request when present' do
    @request.stubs(:params).returns({ 'state' => 'some_state' })
    assert strategy.authorize_params.is_a?(Hash)
    assert_equal 'some_state', strategy.authorize_params[:state]
  end
end

class UidTest < StrategyTestCase
  def setup
    super
    strategy.stubs(:raw_info).returns({ 'id' => '123' })
  end

  test 'returns the id from raw_info' do
    assert_equal '123', strategy.uid
  end
end

class InfoTest < StrategyTestCase
  test 'returns the email' do
    strategy.stubs(:raw_info).returns({ 'id' => '123', 'info' => { 'email' => 'tester@test.com' } })
    assert_equal 'tester@test.com', strategy.info[:email]
  end
end

class RawInfoTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @token = 'iamtoken'
  end

  test 'performs a GET to https://graph.facebook.com/me' do
    strategy.stubs(:access_token).returns(@access_token)
    @access_token.stubs(:token).returns(@token)
    @access_token.expects(:get).with("/auth/matrix/user.json?access_token=#{@token}").returns(stub_everything('OAuth2::Response'))
    strategy.raw_info
  end

  test 'returns an empty hash when the response is false' do
    strategy.stubs(:access_token).returns(@access_token)
    @access_token.stubs(:token).returns(@token)
    oauth2_response = stub('OAuth2::Response', :parsed => false)
    @access_token.stubs(:get).with("/auth/matrix/user.json?access_token=#{@token}").returns(oauth2_response)
    assert_kind_of Hash, strategy.raw_info
  end
end

class CredentialsTest < StrategyTestCase
  def setup
    super
    @access_token = stub('OAuth2::AccessToken')
    @access_token.stubs(:token)
    @access_token.stubs(:expires?)
    @access_token.stubs(:expires_at)
    @access_token.stubs(:refresh_token)
    strategy.stubs(:access_token).returns(@access_token)
  end

  test 'returns a Hash' do
    assert_kind_of Hash, strategy.credentials
  end

  test 'returns the token' do
    @access_token.stubs(:token).returns('123')
    assert_equal '123', strategy.credentials['token']
  end

  test 'returns the expiry status' do
    @access_token.stubs(:expires?).returns(true)
    assert strategy.credentials['expires']

    @access_token.stubs(:expires?).returns(false)
    refute strategy.credentials['expires']
  end

  test 'returns the refresh token and expiry time when expiring' do
    ten_mins_from_now = (Time.now + 600).to_i
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns('321')
    @access_token.stubs(:expires_at).returns(ten_mins_from_now)
    assert_equal '321', strategy.credentials['refresh_token']
    assert_equal ten_mins_from_now, strategy.credentials['expires_at']
  end

  test 'does not return the refresh token when test is nil and expiring' do
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns(nil)
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end

  test 'does not return the refresh token when not expiring' do
    @access_token.stubs(:expires?).returns(false)
    @access_token.stubs(:refresh_token).returns('XXX')
    assert_nil strategy.credentials['refresh_token']
    refute_has_key 'refresh_token', strategy.credentials
  end
end

class ExtraTest < StrategyTestCase
  def setup
    super
    @extra = { 'storm_id' => 'wwwwwwwwwwwwww' }
    @raw_info = { 'extra' =>  @extra }
    strategy.stubs(:raw_info).returns(@raw_info)
  end

  test 'returns a Hash' do
    assert_kind_of Hash, strategy.extra
  end

  test 'contains raw info' do
    assert_equal(@extra["storm_id"], strategy.extra[:storm_id])
  end
end

module SignedRequestHelpers
  def signed_request(payload, secret)
    encoded_payload = base64_encode_url(MultiJson.encode(payload))
    encoded_signature = base64_encode_url(signature(encoded_payload, secret))
    [encoded_signature, encoded_payload].join('.')
  end

  def base64_encode_url(value)
    Base64.encode64(value).tr('+/', '-_').gsub(/\n/, '')
  end

  def signature(payload, secret, algorithm = OpenSSL::Digest::SHA256.new)
    OpenSSL::HMAC.digest(algorithm, secret, payload)
  end
end

require 'oauth/client'
require 'oauth/consumer'
require 'oauth/token'
require 'oauth/signature/hmac/sha1'

module OAuth::Client
  class Helper
    def initialize(request, options = {})
      @request = request
      @options = options
      @options[:signature_method] ||= 'HMAC-SHA1'
    end

    def options
      @options
    end

    def nonce
      options[:nonce] ||= generate_nonce
    end

    def timestamp
      options[:timestamp] ||= generate_timestamp
    end

    def generate_timestamp
      Time.now.to_i.to_s
    end

    def generate_nonce
      rand(2**128).to_s
    end

    def oauth_parameters
      {
        'oauth_consumer_key'     => options[:consumer].key,
        'oauth_token'            => options[:token] ? options[:token].token : '',
        'oauth_signature_method' => options[:signature_method],
        'oauth_timestamp'        => timestamp,
        'oauth_nonce'            => nonce
      }
    end

    def signature(extra_options = {})
      signature = OAuth::Signature.sign(@request, { :uri      => options[:request_uri],
                                                    :consumer => options[:consumer],
                                                    :token    => options[:token] }.merge(extra_options) )
    end

    def header
      parameters = oauth_parameters
      parameters.merge!( { 'oauth_signature' => signature( { :parameters => parameters } ) } )

      header_params_str = parameters.map { |k,v| "#{k}=\"#{v}\"" }.join(', ')

      return "OAuth #{header_params_str}"
    end

    def parameters
      OAuth::RequestProxy.proxy(@request).parameters
    end

    def parameters_with_oauth
      oauth_parameters.merge( parameters )
    end
  end
end

# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'yaml'
require 'cyclid/auth_methods'

module Cyclid
  module Client
    # Cyclid client per-organization configuration
    class Config
      attr_reader :auth, :server, :port, :organization, :username, :secret, :password, :token, :path
      # @!attribute [r] auth
      #   @return [Fixnum] the authentication method. (Default is AUTH_HMAC)
      # @!attribute [r] server
      #   @return [String] the Cyclid server FQDN
      # @!attribute [r] port
      #   @return [Integer] the Cyclid server port. (Default is 80)
      # @!attribute [r] organization
      #   @return [String] the Cyclid organization that this user is associated with.
      # @!attribute [r] username
      #   @return [String] the Cyclid username
      # @!attribute [r] secret
      #   @return [String] the users HMAC signing secret
      # @!attribute [r] password
      #   @return [String] the users HTTP Basic password
      # @!attribute [r] token
      #   @return [String] the users authentication token
      # @!attribute [r] path
      #   @return [String] the fully qualified path to the current configuration file.

      include AuthMethods

      # @param path [String] Fully qualified path to the configuration file
      def initialize(options = {})
        # Load the config if a path was provided
        @path = options[:path] || nil
        @config = @path.nil? ? nil : YAML.load_file(@path)

        # Select the authentication type & associated authentication data.
        @auth = options[:auth] || AUTH_HMAC
        case @auth
        when AUTH_HMAC
          @secret = options[:secret] || @config['secret']
        when AUTH_BASIC
          @password = options[:password] || @config['password']
        when AUTH_TOKEN
          @token = options[:token] || @config['token']
        end

        # Set defaults from the options
        @server = options[:server] || nil
        @port = options[:port] || nil
        @organization = options[:organization] || nil
        @username = options[:username] || nil

        # Get anything provided in the config file
        if @config
          @server ||= @config['server']
          @port ||= @config['port'] || 80
          @organization ||= @config['organization']
          @username ||= @config['username']
        end

        # Server & Username *must* be set
        raise 'server address must be provided' if @server.nil?
        raise 'username must be provided' if @username.nil?
      end
    end
  end
end

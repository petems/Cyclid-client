# frozen_string_literal: true
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

require 'bcrypt'

module Cyclid
  module Client
    # User related methods
    module User
      # Retrieve the list of users from a server
      # @return [Array] List of user names.
      def user_list
        uri = server_uri('/users')
        res_data = api_get(uri)
        @logger.debug res_data

        users = []
        res_data.each do |item|
          users << item['username']
        end

        return users
      end

      # Get details of a specific user
      # @param username [String] User name of the user to retrieve.
      # @return [Hash] Decoded server response object.
      def user_get(username)
        uri = server_uri("/users/#{username}")
        res_data = api_get(uri)
        @logger.debug res_data

        return res_data
      end

      # Create a new user
      # @param username [String] User name of the new user.
      # @param name [String] Users real name.
      # @param email [String] Users email address.
      # @param password [String] Unencrypted initial password OR a BCrypt2
      #   encrypted password string.
      # @param secret [String] Initial HMAC signing secret
      # @return [Hash] Decoded server response object.
      # @see #user_modify
      # @see #user_delete
      def user_add(username, email, name = nil, password = nil, secret = nil)
        # Create the user object
        user = { 'username' => username, 'email' => email }

        # Add the real name is one was supplied
        user['name'] = name unless name.nil?

        # Add the HMAC secret if one was supplied
        user['secret'] = secret unless secret.nil?

        # Add the password if one was supplied
        user['password'] = if password =~ /\A\$2a\$.+\z/
                             # Password is already encrypted
                             password
                           else
                             # Encrypt the plaintext password
                             BCrypt::Password.create(password).to_s
                           end unless password.nil?

        @logger.debug user

        # Sign & send the request
        uri = server_uri('/users')
        res_data = api_json_post(uri, user)
        @logger.debug res_data

        return res_data
      end

      # Modify a user
      # @param username [String] User name of the new user.
      # @param args [Hash] options to modify the user.
      # @option args [String] name Users real name.
      # @option args [String] email Users email address.
      # @option args [String] secret Initial HMAC signing secret
      # @option args [String] password Unencrypted initial password
      # @option args [String] password Unencrypted initial password OR a
      #   BCrypt2 encrypted password string.
      # @return [Hash] Decoded server response object.
      # @see #user_add
      # @see #user_delete
      # @example Change the email address of the user 'leslie'
      #   user_modify('leslie', email: 'leslie@example.com')
      # @example Change the password & secret of the user 'bob'
      #   user_modify('bob', secret: 'sekrit', password: 'm1lkb0ne')
      def user_modify(username, args)
        # Create the user object
        user = {}

        # Add the real name is one was supplied
        user['name'] = args[:name] if args.key? :name and args[:name]

        # Add the email address if one was supplied
        user['email'] = args[:email] if args.key? :email and args[:email]

        # Add the HMAC secret if one was supplied
        user['secret'] = args[:secret] if args.key? :secret and args[:secret]

        # Add the password if one was supplied
        user['password'] = if args[:password] =~ /\A\$2a\$.+\z/
                             # Password is already encrypted
                             args[:password]
                           else
                             # Encrypt the plaintext password
                             BCrypt::Password.create(args[:password]).to_s
                           end if args.key? :password and args[:password]

        @logger.debug user

        # Sign & send the request
        uri = server_uri("/users/#{username}")
        res_data = api_json_put(uri, user)
        @logger.debug res_data

        return res_data
      end

      # Delete a user
      # @param username [String] User name of the user to delete.
      # @return [Hash] Decoded server response object.
      # @see #user_add
      # @see #user_modify
      def user_delete(username)
        uri = server_uri("/users/#{username}")
        res_data = api_delete(uri)
        @logger.debug res_data

        return res_data
      end
    end
  end
end

require 'cli_helper'

describe Cyclid::Cli::Member do
  context 'using the "organization member" commands' do
    before do
      subject.options = { config: ENV['TEST_CONFIG'] }
    end

    describe '#add' do
      it 'adds a user to an organization' do
        org_info = {'users' => ['bob']}
        stub_request(:get, 'http://localhost:9999/organizations/admins')
          .with(headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: org_info.to_json, headers: {})

        stub_request(:put, 'http://localhost:9999/organizations/admins')
          .with(body: '{"users":["bob","leslie"]}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: '{}', headers: {})

        expect{ subject.add('leslie') }.to_not raise_error
      end

      it 'does not add a duplicate user to an organization' do
        org_info = {'users' => ['bob']}
        stub_request(:get, 'http://localhost:9999/organizations/admins')
          .with(headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: org_info.to_json, headers: {})

        stub_request(:put, 'http://localhost:9999/organizations/admins')
          .with(body: '{"users":["bob"]}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: '{}', headers: {})

        expect{ subject.add('bob') }.to_not raise_error
      end

      it 'fails gracefully when the server returns a non-200 response for the GET' do
        stub_request(:get, 'http://localhost:9999/organizations/admins')
          .with(headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 404, body: '{}', headers: {})

        expect{ subject.add('bob') }.to raise_error SystemExit
      end

      it 'fails gracefully when the server returns a non-200 response for the PUT' do
        org_info = {'users' => ['bob']}
        stub_request(:get, 'http://localhost:9999/organizations/admins')
          .with(headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: org_info.to_json, headers: {})

        stub_request(:put, 'http://localhost:9999/organizations/admins')
          .with(body: '{"users":["bob","leslie"]}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 500, body: '{}', headers: {})

        expect{ subject.add('leslie') }.to raise_error SystemExit
      end
    end

    describe '#permission' do
      it 'modifies a user to have "admin" permissions' do
        stub_request(:put, 'http://localhost:9999/organizations/admins/members/bob')
          .with(body: '{"permissions":{"admin":true,"write":true,"read":true}}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: '{}', headers: {})

        expect{ subject.permission('bob', 'admin') }.to_not raise_error
      end

      it 'modifies a user to have "write" permissions' do
        stub_request(:put, 'http://localhost:9999/organizations/admins/members/bob')
          .with(body: '{"permissions":{"admin":false,"write":true,"read":true}}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: '{}', headers: {})

        expect{ subject.permission('bob', 'write') }.to_not raise_error
      end

      it 'modifies a user to have "read" permissions' do
        stub_request(:put, 'http://localhost:9999/organizations/admins/members/bob')
          .with(body: '{"permissions":{"admin":false,"write":false,"read":true}}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: '{}', headers: {})

        expect{ subject.permission('bob', 'read') }.to_not raise_error
      end

      it 'modifies a user to have "none" permissions' do
        stub_request(:put, 'http://localhost:9999/organizations/admins/members/bob')
          .with(body: '{"permissions":{"admin":false,"write":false,"read":false}}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 200, body: '{}', headers: {})

        expect{ subject.permission('bob', 'none') }.to_not raise_error
      end

      it 'fails gracefully if the permission is invalid' do
        expect{ subject.permission('leslie', 'invalid') }.to raise_error SystemExit
      end

      it 'fails gracefully when the server returns a non-200 response' do
        stub_request(:put, 'http://localhost:9999/organizations/admins/members/leslie')
          .with(body: '{"permissions":{"admin":true,"write":true,"read":true}}',
                headers: { 'Accept' => '*/*',
                           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                           'Authorization' => /\AHMAC admin:.*\z/,
                           'Content-Type' => 'application/json',
                           'Host' => 'localhost:9999',
                           'User-Agent' => 'Ruby',
                           'Date' => /.*/,
                           'X-Hmac-Nonce' => /.*/ })
          .to_return(status: 500, body: '{}', headers: {})

        expect{ subject.permission('leslie', 'admin') }.to raise_error SystemExit
      end
    end

    describe '#list' do
    end

    describe '#show' do
    end

    describe '#remove' do
    end
  end
end

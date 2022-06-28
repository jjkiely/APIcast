use lib 't';
use Test::APIcast::Blackbox 'no_plan';

require("policies.pl");

run_tests();

__DATA__

=== TEST 1: loads only the services associated with the host of the request
The important thing in this test is that it only defines the endpoint to get
services by host. If the feature was not well implemented we would notice
because it would try to fetch the services from the other endpoints which are
not defined in this test.
--- env eval
(
  'APICAST_CONFIGURATION' => "http://test:$ENV{TEST_NGINX_SERVER_PORT}",
  'APICAST_CONFIGURATION_LOADER' => 'lazy',
  'THREESCALE_DEPLOYMENT_ENV' => 'production',
  'APICAST_LOAD_SERVICES_WHEN_NEEDED' => 'true',
)
--- upstream env
location = /admin/api/account/proxy_configs/production.json {
  content_by_lua_block {
    expected = "host=localhost&version=latest"
    require('luassert').same(ngx.decode_args(expected), ngx.req.get_uri_args(0))

    local response = {
      proxy_configs = {
        {
          proxy_config = {
            version = 1,
            environment = 'production',
            content = { id = 42, backend_version = 1 }
          }
        }
      }
    }

    ngx.say(require('cjson').encode(response))
  }
}

--- test
content_by_lua_block {
  require('resty.env').set('APICAST_CONFIGURATION_LOADER', 'lazy')
  ngx.say(require('apicast.configuration_loader').load('localhost'))
}

--- error_code: 200
--- expected_json
{"services":[{"id":42,"backend_version":1}],"oidc":[{"service_id": 42}]}
--- no_error_log
[error]

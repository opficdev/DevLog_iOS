# frozen_string_literal: true

require_relative "../function_api_base_url_policy"

def assert_policy(function_api_base_url, expected_path:, expected:)
  actual = FunctionAPIBaseURLPolicy.valid?(
    function_api_base_url,
    expected_path: expected_path
  )
  return if actual == expected

  raise "Expected #{function_api_base_url.inspect} with #{expected_path.inspect} to be #{expected}, got #{actual}"
end

valid_cases = [
  ["https://example.com/api", "/api"],
  ["https://example.com/api/api", "/api/api"]
]

invalid_cases = [
  ["https://example.com/api/api", "/api"],
  ["https://example.com/api", "/api/api"],
  ["http://example.com/api", "/api"],
  ["https:///api", "/api"],
  ["https://example.com/api?source=testflight", "/api"],
  ["https://example.com/api#fragment", "/api"],
  ["https://example .com/api", "/api"]
]

valid_cases.each do |function_api_base_url, expected_path|
  assert_policy(
    function_api_base_url,
    expected_path: expected_path,
    expected: true
  )
end

invalid_cases.each do |function_api_base_url, expected_path|
  assert_policy(
    function_api_base_url,
    expected_path: expected_path,
    expected: false
  )
end

puts "FunctionAPIBaseURLPolicy: #{valid_cases.count + invalid_cases.count} checks passed"

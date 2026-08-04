# frozen_string_literal: true

require "uri"

module FunctionAPIBaseURLPolicy
  module_function

  def valid?(function_api_base_url, expected_path:)
    uri = URI.parse(function_api_base_url)

    uri.is_a?(URI::HTTPS) &&
      !uri.host.to_s.empty? &&
      uri.path == expected_path &&
      uri.query.nil? &&
      uri.fragment.nil?
  rescue URI::InvalidURIError
    false
  end
end

require_relative 'actions'

module KibanaAPI
  module V7
    class Client

      include HttpStatusCodes
      include ApiExceptions
      include Actions::UserActions
      include Actions::SavedObjectActions
      include Actions::SpaceActions
      include Actions::IndexPatternActions
      include Actions::DashboardActions
      include Actions::VisualizationActions

      attr_reader :api_key

      def initialize
        @api_key = KibanaAPI.configuration.api_key
      end

      private

      def client
        Faraday.new(KibanaAPI.configuration.api_host) do |client|
          client.request :url_encoded
          client.adapter Faraday.default_adapter
          # Default Kibana API Headers
          client.headers['kbn-xsrf'] = "true"
          client.headers['Authorization'] = "ApiKey #{api_key}"
          client.headers['Content-Type'] = "application/json;charset=UTF-8"
        end
      end

      def request(http_method:, endpoint:, params: {})
        response = client.public_send(http_method, endpoint, params)
        parsed_response = Oj.load(response.body)

        return parsed_response if response_successful?(response)

        raise error_class(response), "Code: #{response.status}, response: #{response.body}"
      end

      def error_class(response)
        case response.status
        when HTTP_BAD_REQUEST_CODE
          BadRequestError
        when HTTP_UNAUTHORIZED_CODE
          UnauthorizedError
        when HTTP_FORBIDDEN_CODE
          ForbiddenError
        when HTTP_NOT_FOUND_CODE
          NotFoundError
        when HTTP_UNPROCESSABLE_ENTITY_CODE
          UnprocessableEntityError
        else
          ApiError
        end
      end
      
      def response_successful?(response)
        response.status == HTTP_OK_CODE
      end
    end
  end
end
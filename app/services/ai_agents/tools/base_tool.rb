module AiAgents
  module Tools
    class BaseTool
      def name
        raise NotImplementedError, "Subclasses must implement #name"
      end

      def description
        raise NotImplementedError, "Subclasses must implement #description"
      end

      def schema
        raise NotImplementedError, "Subclasses must implement #schema"
      end

      def execute(params)
        raise NotImplementedError, "Subclasses must implement #execute"
      end

      protected

      def make_request(url, method: :get, headers: {}, body: nil)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request_class = case method.upcase
                        when 'GET'
                          Net::HTTP::Get
                        when 'POST'
                          Net::HTTP::Post
                        when 'PATCH'
                          Net::HTTP::Patch
                        when 'DELETE'
                          Net::HTTP::Delete
                        else
                          raise ArgumentError, "Unsupported HTTP method: #{method}"
                        end

        request = request_class.new(uri.request_uri)
        headers.each { |key, value| request[key] = value }
        request.body = body.to_json if body.present?

        response = http.request(request)
        JSON.parse(response.body) if response.body.present?
      rescue StandardError => e
        { error: e.message }
      end
    end
  end
end

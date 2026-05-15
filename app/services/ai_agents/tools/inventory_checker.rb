module AiAgents
  module Tools
    class InventoryChecker < BaseTool
      def name
        'inventory_checker'
      end

      def description
        'Check product inventory availability in the warehouse'
      end

      def schema
        {
          type: 'object',
          properties: {
            product_id: {
              type: 'string',
              description: 'The unique identifier of the product'
            },
            warehouse_id: {
              type: 'string',
              description: 'The warehouse to check inventory in',
              default: 'default'
            }
          },
          required: ['product_id']
        }
      end

      def execute(params)
        product_id = params['product_id']
        warehouse_id = params['warehouse_id'] || 'default'

        begin
          # TODO: Replace with actual inventory API endpoint
          inventory_api_url = ENV.fetch('INVENTORY_API_URL', 'http://localhost:3001/api/inventory')
          response = make_request(
            "#{inventory_api_url}/check",
            headers: { 'Content-Type' => 'application/json' }
          )

          if response&.key?('error')
            { success: false, error: response['error'] }
          else
            {
              success: true,
              product_id: product_id,
              warehouse_id: warehouse_id,
              quantity: response['quantity'].to_i,
              available: response['available'] == true,
              last_updated: response['last_updated']
            }
          end
        rescue StandardError => e
          { success: false, error: e.message }
        end
      end
    end
  end
end

module Sidekiq
  module Enqueuer
    module WebExtension
      class ParamsParser
        class NoProvidedValueForRequiredParam < StandardError; end

        attr_reader :raw_params, :worker

        def initialize(params, worker)
          @raw_params = params
          @worker = worker
        end

        def process
          worker.params.each do |expected_param|
            value = extract_value(expected_param.name.to_s)
            expected_param.value = value
            raise NoProvidedValueForRequiredParam if expected_param.required? && !expected_param.value.present?
          end
          worker.params.map(&:value)
        end

        private

        def extract_value(param_name)
          return nil unless raw_params[param_name].present?
          value = cleanup(raw_params[param_name])
          is_hash, hash = hashable(value)
          return hash if is_hash

          value
        end

        def cleanup(value)
          return nil if value.to_s.downcase == 'nil'
          return '' if value.to_s.strip.empty?
          value
        end

        def hashable(value)
          return [true, value] if value.is_a?(Hash)
          return [false, value] if value.blank? || !value.is_a?(String)

          hash = YAML.load(value.gsub('=>', ':'))
          [hash.is_a?(Hash), hash]
        rescue
          [false, value]
        end   
      end
    end
  end
end

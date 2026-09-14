module Meta
  # Registra chamadas em memória em vez de fazer HTTP. É a implementação usada
  # em desenvolvimento e nos testes.
  class FakeGraphClient
    attr_reader :calls

    def initialize(account = nil)
      @account = account
      @calls = []
      @counter = 0
    end

    def publishing_limit
      record(:publishing_limit)
      { "data" => [ { "quota_usage" => @counter, "config" => { "quota_total" => 100 } } ] }
    end

    def create_media_container(**params)
      record(:create_media_container, params)
      { "id" => "fake_container_#{next_id}" }
    end

    def container_status(container_id)
      record(:container_status, container_id)
      { "status_code" => "FINISHED" }
    end

    def publish_container(container_id)
      record(:publish_container, container_id)
      @counter += 1
      { "id" => "fake_media_#{next_id}" }
    end

    def media_insights(ig_media_id, metrics)
      record(:media_insights, ig_media_id, metrics)
      data = Array(metrics).map { |m| { "name" => m, "values" => [ { "value" => rand(50..500) } ] } }
      { "data" => data }
    end

    private

    def next_id = (@id = @id.to_i + 1)

    def record(method, *args)
      @calls << { method: method, args: args, at: Time.current }
    end
  end
end

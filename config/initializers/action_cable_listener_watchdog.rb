# frozen_string_literal: true

# FIXME: Verify/remove for Rails 8.2
Rails.application.config.to_prepare do
  ActionCable::SubscriptionAdapter::Redis::Listener.class_eval do
    private def retry_connecting?
      @reconnect_attempt += 1
      sleep_t = @reconnect_attempts[@reconnect_attempt - 1] ||
                [@reconnect_attempts.last.to_f, 1.0].max

      Rails.logger.warn(
        "[ActionCable] Redis listener lost its connection; reconnect attempt " \
        "#{@reconnect_attempt} in #{sleep_t}s"
      )

      sleep(sleep_t) if sleep_t > 0
      true
    end

    private def ensure_listener_running
      if @thread && !@thread.alive?
        Rails.logger.error("[ActionCable] Redis listener thread was dead; rebuilding it")

        @thread = nil
        @subscribed_client = nil
        @subscribe_callbacks.clear
        @when_connected.clear
        @reconnect_attempt = 0
        @when_connected << -> { resubscribe }
      end

      @thread ||= Thread.new do
        Thread.current.abort_on_exception = true

        begin
          conn = @adapter.redis_connection_for_subscriptions
          listen conn
        rescue *self.class.const_get(:CONNECTION_ERRORS)
          reset
          if retry_connecting?
            when_connected { resubscribe }
            retry
          end
        end
      end
    end
  end
end

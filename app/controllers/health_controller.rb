class HealthController < ApplicationController
  skip_before_action :authenticate_user!

  layout "marketing/base"

  def show
    respond_to do |format|
      format.html { render }
      format.json { render json: {
        status: "ok",
        queue: get_queue_metrics,
        webserver: get_webserver_metrics,
      } }
    end
  end

  def get_queue_metrics
    Sidekiq::Queue.all.each_with_object({}) do |queue, hash|
      hash[queue.name] = {
        size: queue.size,
        latency: queue.latency
      }
    end
  end

  def get_webserver_metrics
    response = {
      backlog: 0
    }

    puma_stats = Puma.stats_hash
    if puma_stats.key?(:worker_status)
      response[:clustered] = true
      response[:backlog] = puma_stats[:worker_status].sum { |ws| ws[:last_status][:backlog] }
    else
      response[:backlog] = puma_stats[:backlog]
    end

    response
  end
end

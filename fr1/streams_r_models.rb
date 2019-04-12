module MatchParticipants
  class Linker
    include Handler.sync

    def call(event)
      case event
      when YearpassBought
        matches_in_nearest_year_query.call.each do |match|
	  event_store.link(event.id, event_stream: "MatchParticipants$#{match.id}")
	end
      when TicketBought
        event_store.link(event.id, event_stream: "MatchParticipants$#{event.data.fetch(:match_id)}")
      end

    rescue RubyEventStore::EventDuplicatedInStream
    end
  end
end


module MatchParticipants
  class Status < ActiveRecord::Base
  end
end


module MatchParticipants
  class Model
  end

  class Builder
    def call(match_id)
      status = Status.find_or_create_by!(stream_name: "MatchParticipants$#{match_id}")
      status.lock!
      stream_events = event_store.read.stream(status.stream_name).sort_by {|e| e.metadata.timestamp }

      stream_events.each_with_object(Model.new) do |event, mode|
        model = handle(model, event)
      end

      status.save!
      return mode!
    end
  end
end


class Builder
  def call(match_id)
    status = Status.find_or_create_by!(stream_name: "MatchParticipants$#{match_id}")
    status.lock!
    stream_events = event_store.read.stream(status.stream_name)
    return deserialize(status.snapshot) if status.processed_events_count == stream_events.count
    stream_events.inject(Model.new) do |model, event|
      handle(model, event)
    end

    status.procesed_events_count = stream_events.count
    status.save!
    return mode!
  end
end



class Catchup
  MATCH_STREAM_EVENTS = [
    TicketBought,
  ]
  YEARPASS_STREAM_EVENTS= [
    YearpassBought,
  ]

  def initialize(match_id)
    @match_id = match_id
    @linker = Linker.new
  end

  def call
    status = Status.find_or_create_by!(stream_name: "MatchPrticipants$#{match_id}")
    status.with_lock do
      return if status.catchup_at.present?

      streams = []
      streams << ["Match$#{match_id}", MATCH_STREAM_EVENTS]
      YearpassesForMatchQuery.new.call(match_id).each do |yearpass|
        stream << ["Yearpass$#{yearpass.id}", YEARPASS_STREAM_EVENTS]
      end

      streams.each do |stream_name, stream_relevant_events|
        link_events(stream_name, stream_relevant_events)
      end

      status.last_processed_fact_id = nil
      status.catchup_at = Time.now
      status.save!
    end
  end

  def link_events(original_stream, event_types)
    event_store.read.stream(original_stream).each do |event|
      if event_types.include?(event.type)
       linker.handle(event)
      end
    end
  end
end


event_store.read.of_type([OurNewDomainEvent]).find_each do |event|
  linker.call(event)
end



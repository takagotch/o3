class Subscriptions
  def setup
    {
      Ordering::OrderCompleted => [
        SomeHandler,
	OtherHandler,
	GenerateOrderReceiptPdf,
      ],
    }
  end

  def handlers
    setup.reduce({}) do |memo, (event, handlers)|
      handlers.each do |handler|
       memo[handler] ||= []
       memo[handler] << event
      end
    memo
    end
  end
end


RSpec.configure do |config|
  config.before(:each) do |_example|
    event_store = RailsEventStore::Client.new

    disabled_handlers = [
      GenerateOrderReceiptPdf,
    ]

  Subscriptions.new.handlers.except(*disabled_handlers).each do |handler, events|
    event_store.subscribe(handler, to: events)
  end
  
  Rails.configuration.event_store = event_store

  end
end



RSpec.configure do |config|
  config.before(:each) do |_example|
    event_store = RailsEventStore::Client.new

    disabled_handlers = [
      GenerateOrderReceiptPdf,
    ]
    if example.metadata[:enable_handlers]
      disable_handlers -= Array(example.metadata[:enable_handlers])
    end

    Subscriptions.new.handlers.except(*disabled_handlers).each do |handler, events|
      event_store.subscribe(handler, to: events)
    end

    Rails.configuration.event_store = event_store
  end
end

describe "some pdf spec", enable_handlers: [GeneratedOrderReceiptPdf] do
end


if example.metadata[:disable_handlers]
  disabled_handlers -= Array(example.metadata[:disable_handlers])
end

RSpec.configure do |config|
  config.before(:each) do |_example|
    event_store = RailsEventStore::Client.new

    if example.metadata[:only_handlers]
      only_handlers = example.metadata[:only_handlers]

      Subscriptions.new.handlers.slice(*only_handlers).each do |handler, events|
        event_store.subscribe(handler, to: events)
      end
    else
      disabled_handlers = [
        GenerateOrderReceiptPdf,
      ]
      if example.metadata[:enable_handlers]
        disabled_handlers -= Array(example.metadata[:enable_handlers])
      end
      if example.metadata[:disable_handlers]
        disabled_handlers -= Array(example.metadata[:disable_handlers])
      end

      Subscriptions.new.handlers.except(*disabled_handlers).each do
        event_store.subscribe(handler, to: events)
      end
    end

    Rails.configuration.event_store = event_store
  end
end



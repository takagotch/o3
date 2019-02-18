
class UserPersonalDatailsReadModel
  include Sidekiq::Worker

  class State < ActiveRecord::Base
  end

  def perform(domain_event)
    case domain_event

    when
      user_read_model = State.find_by(domain_event.data[:user_id])
      user_read_model.update!(name: domain_event.data[:new_name])
    else raise
    end
  end
end


IdentityAndAccess::NameChanged.new(1, data: { new_name: "Tky "})
IdentityAndAccess::NameChanged.new(2, data: { new_name: "Tky tky"})

Inventory::WarehouseCharacteristicsDecided.new(1, data:
{
  location: nil,
  size: "120",
})
Inventory::WarehouseCharacteristicsDecided.new(2, data:
{
  location: "Osaka, Japan"
})

def perform(domain_event)
  case domain_event

  when Inventory::WarehouseCharacteristicsDecided
    state = State.find_by(domain_event.data[:warehouse_id]).lock!
    state.location = [
      state.location,
      domain_event.data[:location]
    ].compact.first
    state.save!
  else raise
  end
end


EventPublished.new(id: 1, data: { published_at: "2019-02-18", })
EventPublished.new(id: 2, data: { published_at: "2019-02-19", })

def perform(domain_event)
  case domain_event

  when EventPublished
    state = State.find_by(domain_event.data[:event_id]).lock!
    state.first_published_at = [:published_at].compact.min
    state.save!
  else raise
  end
end

IdentityAndAccess::NameChanged.new(1, data: { new_name: "Tky tky" })
IdentityAndAccess::NameChanged.new(2, data: { new_name: "Tky T. Tky"})

def perform(domain_event)
  case domain_event
  when IdentityAndAccess::NameChanged
    state = State.find_by(domain_event.data[:user_id]).lock!
    if state.name_changed_at < domain_event.timestamp
      state.name = domain_event.data[:new_name]
      state.neme_changed_at = domain_event.timestamp
    end
    state.save!
  else raise
  end
end


SomethingCreated.new(1, data: ...)
SomethingDeleted.new(2, data: ...)
SomethingCreated.new(1, data: ...)



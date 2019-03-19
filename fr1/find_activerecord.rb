class UpdatePersonalSettings
  include Command
  attribute :email, string
  attribute :name, String
  attribute :identity_id, Integer
end

class IdentityService
  def update_personal_settings(command)
    Identity.find(command.identity_id) do |identity|
      identity.email = command.email
      identity.name = command.name
      identity.save!
      publish(
        PersonalSettingsUpdated.strict(
	  data: {
	    identity_id: identity.id,
	    email: identity.email,
	    name: identity.name
	  }
	)
      )
    end
  end
end

# lib/active_record/core.rb
def find(*ids)
  return super unless ids.length == 1
  return super if block_given? ||
	  primary_key.nil? ||
	  scope_attributes? ||
	  columns_hash.include? (inheritance_column)
  id = ids.first

  return super if StatementCache.unsupported_value?(id)
    key = primary_key
    statement = cached_find_by_statement(key) {
      where(key => params.bind).limit(1)
    }

    record = statement.execute([id], connection).first
    unless record
      raise RecordNotFound.new("Couldn't find #{name} with '#{primary_key}'=#{id}",
			      name, primary_key, id)
    end
    record
rescue ::RangeError
  raise RecordNotFound.new("Couldn't find #{name} with an out of range value for '#{primary_key}'",
			  name, primary_key)
end

end



User.find(123) do |identity|
  puts identity
end

SELECT `users`.* FROM `users`


class IdentityService
  def update_personal_settings(command)
    Identity.find(command.identity_id).tap do
      identity.email = command.email
      identity.name = command.name
      identity.save!
      publish(
        PersonalSettingsUpdated.strict(
	  data: {
	    identity_id: identity.id,
	    email: identity.email,
	    name: identity.name
	  }
	)
      )
    end
  end
end





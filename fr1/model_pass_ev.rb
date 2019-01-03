scheduled = Payments::CreditNoteScheduled.new(
  scheduled_at: invoice.credit_note,
  invoice_id: invoice.id,
  order_id: transaction.order_id,
)
Resque.enqueue_at(invoice.credit_note.utc,
Payments::SendCreditNote, YAML.dump(scheduled))
event_store.append(scheduled)

class Payments::SendCreditNote
  @queue = :payment
  def self.perform(payload, **)
    new.call(YAML.load(payload))
  end

  def call(event)
    invoice_id = event.data.fetch(:invoice_id)
    Payments::InvoiceService.new.credit_note_scheduled(invoice_id)
  end
end

class Payments::InvoicesService
  def credit_note_scheduled(invoice_id)
    ActiveRecord::Base.transaction do
      invoice = Payment::Invoice.find(invoice_id)
      OrderTransaction.lock.find(invoice.order_transaction_id).tap do |ot|
	      return if ot.successful?

	      invoice.credit_note_issued_at = Time.now
	      invoice.save!
	      event_store.publish(Payments:CreditNoteIssued.new(
	        invoice_id: invoice.id,
		order_id: invoice.order_id,
	      ))
      end
    end
  end
end

class CancellationPolicy
  def initalize(command_bus)
    @command_bus = command_bus
  end
  def call(event)
    # @command_bus.(CancelEdition.new(...))
  end
end

it 'cancels edition when minimum limit not reached 2 weaks before start' do
  command_bus = FakeCommandBus.new
  policy = CancellationPolicy.new(command_bus)
  10.times.each do
    policy.call(register_participant_for_edition)
  end
  expect_dispatched(CancelEdition, command_bus)
end
def register_participant_for_edition
  ParticipantRegisteredForEdition.new(data: {
    edition_id: 'xxxxxxxxxxxxxxxxxxx',
    participant_id: SecureRandom.uuid
  })
end

def two_weeks_before_start_date_reached
  TwoWeekBeforeEditionReached.new(data: {
    edition_id: 'xxxxxxxxxxxxxx'
  })
end
it 'cancels edition when minimum limit not reached 2 weaks before start' do
  command_bus = FakeCommandBus.new
  policy = CancellationPolicy.new(command_bus)
  10.times.each do
    policy.call(register_participant_for_edition)
  end
  policy(command_bus).call(two_weeks_before_start_date_reached)
  expect_dispatched(CancelEdition, command_bus)
end


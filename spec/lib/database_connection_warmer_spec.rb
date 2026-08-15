require "rails_helper"

describe DatabaseConnectionWarmer do
  describe ".warm!" do
    it "executes a lightweight SELECT on the primary connection" do
      connection = ActiveRecord::Base.connection
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
      allow(connection).to receive(:execute).and_call_original

      described_class.warm!

      expect(connection).to have_received(:execute).with("SELECT 1")
    end

    it "returns true when the query succeeds" do
      expect(described_class.warm!).to be true
    end

    it "swallows and logs connection failures instead of raising" do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(PG::ConnectionBad, "boom")
      allow(Rails.logger).to receive(:warn)

      expect { described_class.warm! }.not_to raise_error
      expect(described_class.warm!).to be false
      expect(Rails.logger).to have_received(:warn)
        .with(a_string_including("DatabaseConnectionWarmer"))
        .at_least(:once)
    end

    it "swallows and logs query failures instead of raising" do
      connection = ActiveRecord::Base.connection
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
      allow(connection).to receive(:execute).and_raise(ActiveRecord::StatementInvalid, "nope")
      allow(Rails.logger).to receive(:warn)

      expect { described_class.warm! }.not_to raise_error
      expect(described_class.warm!).to be false
      expect(Rails.logger).to have_received(:warn)
        .with(a_string_including("DatabaseConnectionWarmer"))
        .at_least(:once)
    end
  end
end

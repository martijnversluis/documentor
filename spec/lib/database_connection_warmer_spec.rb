require "rails_helper"

describe DatabaseConnectionWarmer do
  describe ".warm!" do
    it "runs SELECT 1 on every connection in the pool" do
      pool = ActiveRecord::Base.connection_pool
      executed = Concurrent::AtomicFixnum.new(0)
      allow(pool).to receive(:with_connection).and_wrap_original do |orig, &block|
        orig.call do |conn|
          executed.increment
          block.call(conn)
        end
      end
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(pool)

      described_class.warm!

      expect(executed.value).to eq(pool.size)
    end

    it "returns true when every connection warms successfully" do
      expect(described_class.warm!).to be true
    end

    it "returns false and logs when a thread fails" do
      pool = ActiveRecord::Base.connection_pool
      allow(pool).to receive(:with_connection).and_raise(ActiveRecord::StatementInvalid, "nope")
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(pool)
      allow(Rails.logger).to receive(:warn)

      expect(described_class.warm!).to be false
      expect(Rails.logger).to have_received(:warn)
        .with(a_string_including("DatabaseConnectionWarmer"))
        .at_least(:once)
    end

    it "returns false and logs when the pool itself is unavailable" do
      allow(ActiveRecord::Base).to receive(:connection_pool).and_raise(PG::ConnectionBad, "boom")
      allow(Rails.logger).to receive(:warn)

      expect { described_class.warm! }.not_to raise_error
      expect(described_class.warm!).to be false
      expect(Rails.logger).to have_received(:warn)
        .with(a_string_including("DatabaseConnectionWarmer"))
        .at_least(:once)
    end
  end
end

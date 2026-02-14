module Ximmio
  class AddressResponse
    attr_reader :addresses

    def initialize(addresses)
      @addresses = addresses
    end

    class << self
      def parse(data)
        addresses = data.fetch("dataList").map { |data| Address.parse(data) }
        new(addresses)
      end
    end
  end
end

module Ximmio
  class Address
    attr_reader :unique_id, :street, :house_number, :zip_code, :city, :community

    def initialize(
      unique_id: nil,
      street: nil,
      house_number: nil,
      zip_code: nil,
      city: nil,
      community: nil
    )
      @unique_id = unique_id
      @street = street
      @house_number = house_number
      @zip_code = zip_code
      @city = city
      @community = community
    end

    class << self
      def parse(data)
        new(
          unique_id: data.fetch("UniqueId"),
          street: data.fetch("Street"),
          house_number: fetch_house_number(data),
          zip_code: data.fetch("ZipCode"),
          city: data.fetch("City"),
          community: data.fetch("Community")
        )
      end

      private

      def fetch_house_number(data)
        [
          data.fetch("HouseNumber"),
          data.fetch("HouseLetter"),
          data.fetch("HouseNumberIndication"),
          data.fetch("HouseNumberAddition")
        ]
          .reject { |part| part.nil? || part.empty? }
          .join("")
      end
    end
  end
end

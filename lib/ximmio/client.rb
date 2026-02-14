module Ximmio
  class Client
    def get_addresses(company_code:, post_code:, house_number:)
      post(
        :GetAddress,
        { companyCode: company_code, postCode: post_code, houseNumber: house_number },
        AddressResponse
      )
    end

    def get_calendar(unique_address_id:, company_code:, start_date:, end_date:)
      post(
        :GetCalendar,
        {
          uniqueAddressId: unique_address_id,
          companyCode: company_code,
          startDate: start_date,
          endDate: end_date
        },
        CalendarResponse
      )
    end

    private

    def post(action, data, response_class)
      conn
        .post("/api/#{action}", data)
        .then(&:body)
        .then { |data| response_class.parse(data) }
    end

    def conn
      Faraday.new("https://wasteapi.ximmio.com") do |f|
        f.request :retry
        f.request :json
        f.response :json
      end
    end
  end
end

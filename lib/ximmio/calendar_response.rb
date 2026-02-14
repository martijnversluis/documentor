module Ximmio
  class CalendarResponse
    attr_reader :calendar

    def initialize(calendar)
      @calendar = calendar
    end

    class << self
      def parse(data)
        calendar =
          data.fetch("dataList").map do |item|
            [
              item.fetch("pickupDates").to_h do |date_time_string|
                [
                  Time.zone.parse(date_time_string),
                  item.fetch("_pickupTypeText")
                ]
              end
            ]
              .reduce(&:merge)
          end
              .reduce(&:merge) || {}

        new(calendar)
      end
    end
  end
end

module SendAnalytics
  class Decisions < Base
    private

    def file_name
      @file_name ||=
        "decisions-data/decisions-analytics_#{date.strftime("%Y%m%d")}.csv"
    end

    def csv
      @csv ||=
        ::ClaimDecision.reporting_date(date).to_csv
    end
  end
end

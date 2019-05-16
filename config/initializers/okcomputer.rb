# frozen_string_literal: true

class SeedDataIsPresent < OkComputer::Check
  def seed_counts_to_check
    {
      CategoryEn => 343,
      CategoryFr => 340,
      CollectionHighlight => 3,
      CollectionHighlightItem => 11,
      PoliticalPeriod => 10
    }
  end

  def check
    message = []
    begin
      seed_counts_to_check.each do |klass, expected|
        if klass.count == expected
          message << "#{klass} has expected count of #{expected}"
        else
          mark_failure
          message << "#{klass} has count #{klass.count} instead of the expected #{expected}"
        end
      end
    rescue => e
      mark_failure
      message << e
    end

    mark_message message.join(', ')
  end
end

OkComputer.mount_at = 'status'

OkComputer::Registry.register 'version', OkComputer::AppVersionCheck.new
OkComputer::Registry.register 'seed_data', SeedDataIsPresent.new
OkComputer::Registry.register 'solr', OkComputer::HttpCheck.new(
  "#{Blacklight.solr_config[:url]}/admin/ping"
)

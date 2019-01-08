require './calendar_days'

class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def includes?(date)
    (date >= @start_date) && (date <= @end_date)
  end
end

class Exclusion < DateRange

  def initialize(start, end_date, day)
    super(start, end_date)
    @day = day
  end

  def included_day
    @day.clone
  end
end

require './json_definition'

class Calendar
  def self.current
    Calendar.new(CurrentCalendar.definition)
  end

  attr_reader :overrides, :exclusions, :definition

  def initialize(definition)
    @overrides = definition.overrides
    @exclusions = definition.exclusions
    @correlations = {definition.start_date => 1}

    @start_date = definition.start_date
    @end_date = definition.end_date
    @definition = definition
  end

  def excluded?(date)
    @exclusions.any? {|out| out.includes? date}
  end

  def day_on(date)
    throw ArgumentError.new('Date out of range') unless includes?(date)

    (@overrides + @exclusions).each do |holiday|
      return holiday.included_day if holiday.includes? date
    end

    return weekend if weekend?(date)

    day_of_date = iterate_for_day(date)
    @correlations[date] = day_of_date
    day day_of_date
  end

  def includes?(date)
    (date >= @start_date) && (date <= @end_date)
  end

  def next_nonholiday(date)
    loop do
      date += 1
      break unless day_on(date).is_a? Holiday
    end
    date
  end

  def name
    @definition.name
  end

  private

  def weekend?(date)
    date.cwday > 5
  end

  def most_recent_correlation(query_date)
    date = query_date.clone
    date -= 1 until @correlations.key? date
    date
  end

  def iterate_for_day(query_date)
    date = most_recent_correlation(query_date)
    day = @correlations[date]

    while date != query_date
      date += 1
      unless excluded?(date) || weekend?(date)
        day += 1
        day = 1 if day == 9
      end
    end

    day
  end
end

def day(number)
  StandardDay.new(number)
end

def weekend
  Holiday.new('Weekend')
end

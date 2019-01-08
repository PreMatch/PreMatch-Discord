require './schedule'
require './calendar'
require 'json'
require 'net/http'
require 'uri'

module CurrentCalendar
  def self.definition
    if $_definition.nil?
      json = Net::HTTP.get(URI.parse('https://prematch.org/static/calendar.json'))
      $_definition = JsonDefinition.new(json)
    end
    $_definition
  end
end

def parse_date(expression)
  Date.parse(expression)
end

def parse_time_range(array)
  TimeRange.new(parse_time(array[0]), parse_time(array[1]))
end

def parse_time(array)
  time(array[0], array[1])
end

def parse_date_range(array)
  DateRange.new(parse_date(array[0]), parse_date(array[1]))
end

class JsonDefinition
  def initialize(json)
    @json = JSON.parse(json)
  end

  def name
    @json['name']
  end

  def start_date
    parse_date(@json['start_date'])
  end

  def end_date
    parse_date(@json['end_date'])
  end

  def blocks
    @json['blocks']
  end

  def periods
    @json['periods'].map(&method(:parse_time_range))
  end

  def exclusions
    @json['exclusions'].map(&method(:parse_exclusion))
  end

  def overrides
    @json['overrides'].map(&method(:parse_exclusion))
  end

  def semester_count
    @json['semesters'].length
  end

  def semesters
    @json['semesters'].map(&method(:parse_date_range))
  end

  def semester_of(date)
    index = semesters.find_index { |semester| semester.includes?(date) }
    index.nil? ? nil : (index + 1)
  end

  def cycle_size
    @json['cycle_size']
  end

  def blocks_of_day(number)
    @json['day_blocks'][number - 1]
  end

  def exam_day_periods
    @json['exam_day_periods'].map(&method(:parse_time_range))
  end

  def half_day_periods
    @json['half_day_periods'].map(&method(:parse_time_range))
  end

  private

  $exclusion_parsers = {
      holiday: lambda { |obj|
        start_date = parse_date(obj['start_date'])
        end_date = parse_date(obj['end_date'])

        Exclusion.new(start_date, end_date, Holiday.new(obj['description']))
      },
      half_day: lambda { |obj|
        date = parse_date(obj['date'])

        Exclusion.new(date, date, HalfDay.new(obj['blocks']))
      },
      exam_day: lambda { |obj|
        date = parse_date(obj['date'])

        Exclusion.new(date, date, ExamDay.new(obj['blocks']))
      },
      unknown: lambda { |obj|
        date = parse_date(obj['date'])

        Exclusion.new(date, date, UnknownDay.new(obj['description']))
      },
      standard_day: lambda { |obj|
        date = parse_date(obj['date'])

        Exclusion.new(date, date, StandardDay.new(obj['day_number']))
      }
  }

  def parse_exclusion(object)
    key = object['type'].to_sym
    $exclusion_parsers[key].call object
  end
end
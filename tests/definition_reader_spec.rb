require 'rspec'
require 'date'
require './json_definition'

describe 'Correct interpretation of calendar.json' do

  it 'should read the name of the definition' do
    json = '{"name": "The 7+H Definition File"}'
    definition = JsonDefinition.new(json)

    expect(definition.name).to eq 'The 7+H Definition File'
  end

  it 'should read dates correctly' do
    json = '{"start_date": "2018-08-29", "end_date": "2019-06-14"}'
    definition = JsonDefinition.new(json)

    expect(definition.start_date).to eq Date.new(2018, 8, 29)
    expect(definition.end_date).to eq Date.new(2019, 6, 14)
  end

  it 'should read the blocks' do
    json = '{"blocks": ["A", "B", "C", "D", "E", "F", "G"]}'
    definition = JsonDefinition.new(json)

    expect(definition.blocks).to eq %w(A B C D E F G)
  end

  it 'should read TimeRanges correctly' do
    json = '{"periods": [[[7, 44], [8, 44]], [[8, 48], [10, 3]], [[10, 7], [11, 7]], [[11, 11], [13, 1]], [[13, 5], [14, 5]]]}'
    definition = JsonDefinition.new(json)

    expect(definition.periods.length).to eq 5
    expect(definition.periods[0].start_time).to eq time(7, 44)
  end

  it 'should parse exclusions with type "holiday"' do
    json = '{"exclusions": [{
      "type": "holiday",
      "start_date": "2018-11-12",
      "end_date": "2018-11-12",
      "description": "Veterans Day"
    },
    {
      "type": "holiday",
      "start_date": "2018-12-24",
      "end_date": "2019-01-01",
      "description": "Christmas Break"
    }]}'
    definition = JsonDefinition.new(json)

    veterans_day = definition.exclusions[0]
    christmas = definition.exclusions[1]

    expect(veterans_day).to be_an_instance_of(Exclusion)
    expect(veterans_day.start_date).to eq Date.new(2018, 11, 12)
    expect(veterans_day.end_date).to eq veterans_day.start_date
    expect(veterans_day.included_day.description).to eq 'Veterans Day (No School)'

    expect(christmas.start_date).to eq Date.new(2018, 12, 24)
    expect(christmas.end_date).to eq Date.new(2019, 1, 1)
    expect(christmas.included_day.description).to eq 'Christmas Break (No School)'
  end

  it 'should parse semesters and know the semester for a given day' do
    json = '{"semesters": [["2018-08-29", "2019-01-24"], ["2019-01-25", "2019-06-14"]]}'
    definition = JsonDefinition.new(json)

    expect(definition.semester_count).to eq 2
    expect(definition.semesters[0].start_date).to eq Date.new(2018, 8, 29)
    expect(definition.semesters[1].end_date).to eq Date.new(2019, 6, 14)
    expect(definition.semester_of(Date.new(2019, 01, 25))).to eq 2
  end

  it 'should parse half days' do
    json = '{"exclusions": [{
      "type": "half_day",
      "date": "2018-10-19",
      "blocks": ["A", "C", "E", "G"]
    },
    {
      "type": "half_day",
      "date": "2019-02-01",
      "blocks": ["A", "E", "F", "C"]
    }]}'
    definition = JsonDefinition.new(json)

    expect(definition.exclusions[0]).to be_an_instance_of(Exclusion)
    expect(definition.exclusions[1].start_date).to eq Date.new(2019, 2, 1)
    expect(definition.exclusions[0].included_day.blocks).to eq %w[A C E G]
  end

  it 'should parse exam days' do
    json = '{"exclusions": [{
      "type": "exam_day",
      "date": "2019-01-22",
      "blocks": ["B", "F"]
    },
    {
      "type": "exam_day",
      "date": "2019-01-23",
      "blocks": ["C", "G"]
    }]}'
    definition = JsonDefinition.new(json)

    first_day, second_day = definition.exclusions

    expect(first_day).to be_an_instance_of(Exclusion)
    expect(second_day.included_day.test_blocks).to eq %w[C G]
    expect(first_day.end_date).to eq Date.new(2019, 1, 22)
  end

  it 'should parse unknown days' do
    json = '{"exclusions": [{
      "type": "unknown",
      "date": "2019-06-10",
      "description": "Day Y"
    }]}'
    definition = JsonDefinition.new(json)

    exclusion = definition.exclusions[0]
    expect(exclusion).to be_an_instance_of(Exclusion)
    expect(exclusion.start_date).to eq Date.new(2019, 6, 10)
    expect(exclusion.included_day).to be_an_instance_of(UnknownDay)
    expect(exclusion.included_day.description).to eq "Day Y (Unknown schedule)"
  end

  it 'should parse standard days' do
    json = '{"exclusions": [{
      "type": "standard_day",
      "date": "2019-01-16",
      "day_number": 3
    }]}'
    definition = JsonDefinition.new(json)

    exclusion = definition.exclusions[0]
    expect(exclusion).to be_an_instance_of(Exclusion)
    expect(exclusion.start_date).to eq Date.new(2019, 1, 16)
    expect(exclusion.included_day).to be_an_instance_of(StandardDay)
    expect(exclusion.included_day.number).to be 3
  end

  it 'should include overrides' do
    json = '{"overrides": [{
      "type": "holiday",
      "start_date": "2018-09-14",
      "end_date": "2018-09-14",
      "description": "Day after Gas Explosion Apocalypse"
    },
    {
      "type": "standard_day",
      "date": "2018-09-17",
      "day_number": 2
    }]}'
    definition = JsonDefinition.new(json)

    expect(definition.overrides.length).to be 2
    expect(definition.overrides[0].included_day.description).to eq 'Day after Gas Explosion Apocalypse (No School)'
    expect(definition.overrides[1].included_day.number).to be 2
  end

  it 'should parse the cycle size' do
    json = '{"cycle_size": 8}'
    definition = JsonDefinition.new(json)

    expect(definition.cycle_size).to be 8
  end

  it 'should parse the blocks for each standard day' do
    json = '{"day_blocks": [
    ["A", "C", "H", "E", "G"],
    ["B", "D", "F", "G", "E"],
    ["A", "H", "D", "C", "F"],
    ["B", "A", "H", "G", "E"],
    ["C", "B", "F", "D", "G"],
    ["A", "H", "E", "F", "C"],
    ["B", "A", "D", "E", "G"],
    ["C", "B", "H", "F", "D"]
  ]}'
    definition = JsonDefinition.new(json)

    expect(definition.blocks_of_day(1)).to eq %w[A C H E G]
    expect(definition.blocks_of_day(7)).to eq %w[B A D E G]
  end

  it 'should parse exam day periods' do
    json = '{"exam_day_periods": [
    [[8, 0], [9, 30]],
    [[10, 0], [11, 30]],
    [[13, 0], [14, 0]]
  ]}'
    definition = JsonDefinition.new(json)
    periods = definition.exam_day_periods

    expect(periods.length).to be 3
    expect(periods[0].start_time).to eq time(8, 0)
    expect(periods[2].end_time).to eq time(14, 0)
  end

  it 'should parse half day periods' do
    json = '{"half_day_periods": [
    [[7, 44], [8, 29]],
    [[8, 33], [9, 16]],
    [[9, 20], [10, 3]],
    [[10, 7], [10, 50]]
  ]}'
    definition = JsonDefinition.new(json)
    periods = definition.half_day_periods

    expect(periods.length).to be 4
    expect(periods[1].start_time).to eq time(8, 33)
    expect(periods[2].end_time).to eq time(10, 3)
  end
end
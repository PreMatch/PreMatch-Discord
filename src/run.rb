#$LOAD_PATH << 'src'
require 'time'
require './bot'
require './secrets'
require 'discordrb'

require 'chronic'

custom_schedules = {
    # [6, 4] => [7, %w(B G D E A)],
}

def to_pair(date)
  [date.month, date.day]
end

bot = Discordrb::Commands::CommandBot.new \
  token: $discord_token, prefix: '$$'

Bot.initialize

bot.command :day do |event, *args|
  if args.empty?
    event.send_message(':question: Provide a day number or a date expression (like "tomorrow")')
    return
  end

  input_num = args[0].to_i
  if input_num.to_s == args[0]
    response = Bot.day_number(input_num)
    event.send_message(response) unless response.nil?
    return
  end

  if args[0].to_f.to_s == args[0]
    event.send_message(':-1: In 7+H, there is no in between.')
    return
  end

  date = Chronic.parse(args.join(' '))
  if date.nil? || date.is_a?(Chronic::Span)
    event.send_message(':thinking: I don\'t know what you mean.')
    return
  end

  date_pair = to_pair(date.to_date)
  if custom_schedules.include? date_pair
    day, blocks = custom_schedules[date_pair]
    event.send_message("#{date.strftime('%B %-d, %Y')} is a special Day #{day} with blocks #{blocks.join(', ')}")
    return
  end

  response = Bot.day_cmd(date)
  event.send_message(response) unless response.nil?
end

bot.command :personalize do |event, *_args|
  Bot.personalize(event)
end

bot.command :myday do |event, *_args|
  date_pair = to_pair(Date.today)
  if custom_schedules.include? date_pair
    day, blocks = custom_schedules[date_pair]
    event.send_message("#{date.strftime('%B %-d, %Y')} is a special Day #{day} with blocks #{blocks.join(', ')}")
    return
  end

  resp = Bot.myday(event)
  event.send(resp) unless resp.nil?
end

bot.run

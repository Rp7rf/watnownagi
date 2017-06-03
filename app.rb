require 'sinatra'
require 'line/bot'

require './src/menu'
require './lib/module'

get '/' do
  message = "Hello world"
  message.extend(Text)
  message.reply_text.to_s
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        msg = event.message['text']
        msg.extend(Text(event['replyToken']))
        if event.message['text'] =~ /いなむー/
          msg = ['いなむらくーん', 'いなむーだよ', '俺いなむー！'][Random.rand(3).to_i]
        elsif event.message['text'] =~ /メシ/
          menu = random_menu
          client.reply_message(event['replyToken'], 
            {
                "type": "image",
                "originalContentUrl": "https://www.u-coop.net/food/menu/menu_images/#{menu['id']}.jpg",
                "previewImageUrl": "https://www.u-coop.net/food/menu/menu_images/#{menu['id']}.jpg"
            })
        end
        msg.reply_text
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end
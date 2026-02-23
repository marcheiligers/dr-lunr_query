require 'lib/lunr_query'
require_relative 'input'
require_relative 'scroller'
require_relative 'button'

def boot(args)
  Input.replace_console!

  index_data = $gtk.parse_json_file('data/astronauts_index.json')
  args.state.index = LunrQuery::Index.load(index_data)

  astronaut_list = $gtk.parse_json_file('data/astronauts.json')
  args.state.astronauts = {}
  astronaut_list.each { |a| args.state.astronauts[a['id']] = a }

  args.state.text ||= Input::Text.new(
    x: 20,
    y: 660,
    w: 1200,
    padding: 10,
    prompt: 'Search',
    value: 'apollo',
    size_px: 22,
    text_color: { r: 20, g: 20, b: 90 },
    selection_color: { r: 122, g: 90, b: 90 },
    cursor_color: 0x333333,
    cursor_width: 3,
    background_color: [220, 220, 220],
    blurred_background_color: [192, 192, 192],
    on_unhandled_key: lambda do |key, input|
      case key
      when :tab
        input.blur
        args.state.multiline.focus
      when :enter
        search
      end
    end,
    on_click: lambda do |_mouse, input|
      input.focus
      args.state.multiline.blur
    end,
    max_length: 40
  )

  args.state.multiline ||= Input::Multiline.new(
    x: 20,
    y: 20,
    w: 1200,
    h: 620,
    prompt: 'Results',
    readonly: true,
    value: nil,
    font: '',
    size_px: 22,
    selection_start: 0,
    background_color: [220, 220, 220],
    blurred_background_color: [192, 192, 192],
    cursor_color: 0x6a5acd,
    on_unhandled_key: lambda do |key, input|
      if key == :tab
        input.blur
        args.state.text.focus
      end
    end,
    on_click: lambda do |_mouse, input|
      input.focus
      args.state.text.blur
    end
  )
  args.state.text.focus
  args.state.scroller = Scroller.new(args.state.multiline)
  args.state.search_button = IconButton.new(
    1100, 660, 160, 40,
    'Search', 'sprites/icon-search.png',
    ->{ search }
  )

  search
end

def tick(args)
  args.state.text.tick
  args.state.multiline.tick
  args.state.scroller.tick
  args.state.search_button.tick

  args.outputs.primitives << [
    { x: 20, y: 700, text: 'LunrQuery Astronaut Search Demo', size_px: 30 }.label!,
    args.state.text,
    args.state.multiline,
    args.state.scroller,
    args.state.search_button
  ]
end

def search
  query = $args.state.text.value.to_s
  if query.empty?
    $args.state.multiline.value = ''
  else
    results = $args.state.index.search(query)
    $args.state.multiline.value = format_results(query, results)
  end
end

RESULT_CONTEXT_LENGTH = 60

def format_results(query, results)
  astronauts = $args.state.astronauts
  value = "Query: '#{query}'\n"
  value << '=' * 60 << "\n"

  if results.empty?
    value << '  No results found'
  else
    total_count = 0
    results.each_with_index do |result, i|
      astronaut = astronauts[result[:ref]]
      name = astronaut ? astronaut['name'] : result[:ref]
      value << "\n#{i + 1}. #{name} (score: #{result[:score].round(4)})\n"

      result[:match_data][:metadata].each do |term, fields|
        if fields['name']
          value << "   Name match: '#{term}' in \"#{astronaut['name']}\"\n"
          total_count += 1
        end

        if fields['missions']
          value << "   Missions match: '#{term}' in \"#{astronaut['missions']}\"\n"
          total_count += 1
        end

        if fields['bio']
          bio ||= $gtk.read_file("data/biographies/#{result[:ref]}.txt")
          fields['bio']['position'].each do |position|
            total_count += 1
            start_context_length = (RESULT_CONTEXT_LENGTH - position[1]).idiv(2)
            start = (position[0] - start_context_length).greater(0)
            length = RESULT_CONTEXT_LENGTH.lesser(LunrQuery::UTF8.length(bio) - start)
            value << "   Bio match: '#{LunrQuery::UTF8.slice(bio, position[0], position[1])}' ...#{LunrQuery::UTF8.slice(bio, start, length).gsub("\n", ' ')}... #{position} (#{start}..#{start + length})\n"
          end
        end
      end
    end
    value << "\nFound #{results.length} result(s) with #{total_count} hit(s).\n"
  end

  value << "\n" << '-' * 80 << "\n#{results}"
end

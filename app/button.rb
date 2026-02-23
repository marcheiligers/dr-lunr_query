class Button
  attr_sprite
  attr_reader :on_clicked

  def initialize(x, y, w, h, text, on_clicked)
    @mouse_over = false
    @x = x
    @y = y
    @w = w
    @h = h
    @text = text
    @on_clicked = on_clicked
  end

  def tick
    handle_mouse
  end

  def handle_mouse
    mouse = $args.inputs.mouse
    @mouse_over = mouse.inside_rect?(self)
    return unless @mouse_over

    @on_clicked.call if mouse.up
  end

  def draw_override(ffi)
    if @mouse_over
      ffi.draw_solid(@x, @y, @w, @h, 200, 200, 240, 255)
    else
      ffi.draw_solid(@x, @y, @w, @h, 220, 220, 220, 255)
    end
    # ffi.draw_label_5 x, y, text, size_enum, alignment_enum, r, g, b, a, font, vertical_alignment_enum, blendmode_enum, size_px, angle_anchor_x, angle_anchor_y
    ffi.draw_label_5 @x + @w / 2, @y + @h / 2, @text, nil, 1, 0, 0, 0, 255, '', 1, 1, @h - 10, 0.5, 0.5
  end
end

class IconButton < Button
  def initialize(x, y, w, h, text, icon_path, on_clicked)
    super x, y, w, h, text, on_clicked
    @icon_path = icon_path
    @source_w, @source_h = $gtk.calcspritebox(@icon_path)
  end

  def draw_override(ffi)
    if @mouse_over
      ffi.draw_solid(@x, @y, @w, @h, 200, 200, 240, 255)
    else
      ffi.draw_solid(@x, @y, @w, @h, 220, 220, 220, 255)
    end
    # ffi.draw_label_5 x, y, text, size_enum, alignment_enum, r, g, b, a, font, vertical_alignment_enum, blendmode_enum, size_px, angle_anchor_x, angle_anchor_y
    ffi.draw_label_5 @x + @w / 2, @y + @h / 2, @text, nil, 1, 0, 0, 0, 255, '', 1, 1, @h - 10, 0.5, 0.5

    # The argument order for ffi_draw.draw_sprite_3 is:
    # x, y, w, h,
    # path,
    # angle,
    # alpha, red_saturation, green_saturation, blue_saturation
    # tile_x, tile_y, tile_w, tile_h,
    # flip_horizontally, flip_vertically,
    # angle_anchor_x, angle_anchor_y,
    # source_x, source_y, source_w, source_h
    ffi.draw_sprite_3(
      @x + 6, @y + 6, @h - 12, @h - 12,
      @icon_path, 0,
      255, 128, 128, 128,
      nil, nil, nil, nil,
      false, false,
      0, 0,
      0, 0, @source_w, @source_h
    )
  end
end

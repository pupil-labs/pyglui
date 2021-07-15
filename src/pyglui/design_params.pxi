########## Global Design Parameters ##########
DEF text_size = 18.
DEF line_height = 20.
DEF x_spacer = 5
DEF rect_color_default = (.0,.0,.0,.8)


########## UI Elements Design Parameters ##########
# ui element design params should be declared here
# name variables starting with the element name
# example: `slider_` or `text_input_` followed by the attributes

# UI_element parameters - base class
DEF outline_padding = 10
DEF circle_button_size = 20
DEF circle_button_size_selected = 25
DEF circle_button_shadow = 10

DEF color_selected = (0.5, 0.8, 0.75,.9)
DEF color_on = (0.5, 0.8, 0.75,.9)
DEF color_on_read_only = (0.5, 0.8, 0.75,.75)
DEF color_default = (.5,.5,.5,.9)
DEF color_default_read_only = (.5,.5,.5,.75)
DEF color_shadow = (.0,.0,.0,.8)
DEF color_shadow_read_only = (.0,.0,.0,.0)
DEF shadow_sharpness = 0.3
DEF color_text_default = (1.,1.,1.,1.)
DEF color_text_info = (1.,1.,1.,.6)
DEF color_text_read_only = (.5,.5,.5,.5)
DEF color_line_default = (1.,1.,1.,.4)
DEF size_text_info = 18

# Slider - design parameters
DEF slider_outline_size_y = 65.
DEF slider_label_org_y = 20.
DEF slider_handle_org_y = 40.
DEF slider_button_size = circle_button_size
DEF slider_button_size_read_only = 15.
DEF slider_button_size_selected = circle_button_size_selected
DEF slider_button_shadow = circle_button_shadow
DEF slider_step_mark_size = 8.
DEF slider_color_step = (.8,.8,.8,.6)
DEF slider_line_color_default = color_line_default
DEF slider_line_color_highlight = color_on
DEF slider_line_color_default_read_only = color_line_default
DEF slider_line_color_highlight_read_only = color_on_read_only

# Switch - design parameters
DEF switch_outline_size_y = 40
DEF switch_button_size = circle_button_size
DEF switch_button_size_selected = circle_button_size_selected
DEF switch_button_size_on = switch_button_size+5
DEF switch_button_shadow = circle_button_shadow+3

# Selector - design parameters
DEF selector_outline_size_y = 40.
DEF selector_triangle_color_default = color_line_default
DEF selector_triangle_color_read_only = color_text_read_only

# Info_Text - design parameters
#DEF info_text_outline_size = 40

# TextInput - design parameters
DEF text_input_outline_size_y = 40.
DEF text_input_highlight_color = (.5,.5,.9,.5)
DEF text_input_line_highlight_color = slider_line_color_highlight

# Button - design parameters
DEF button_corner_radius = 5.
DEF button_outline_size_y = 44.
DEF button_outline_padding = outline_padding
DEF button_text_padding = 2.
DEF button_default_color = color_default
DEF button_read_only_color = (0.25, 0.25, 0.25, 0.75)
DEF button_active_color = color_selected
DEF button_default_text_color = color_text_default
DEF button_read_only_text_color = (0.5, 0.5, 0.5, 0.75)
DEF button_active_text_color = color_shadow

# Thumb - design parameters
DEF thumb_outline_size = 80.
DEF thumb_outline_pad = 0.
DEF thumb_button_size_offset_on = 30.
DEF thumb_button_size_offset_selected = 25.
DEF thumb_button_size_offset_off = thumb_button_size_offset_on
DEF thumb_color_on = color_on
DEF thumb_color_off = (1,1,1,0.6)
DEF thumb_color_shadow = (.0,.0,.0,.0)
DEF thumb_button_sharpness = 0.8
DEF thumb_button_shadow_sharpness = 0.5
DEF thumb_font_padding = 30.

DEF icon_outline_size = 50.
DEF icon_font_padding = 20.
DEF icon_progress_color = color_on

DEF tooltip_text_size = 18.

# Menu - design parameters
DEF menu_pad = 10.
DEF menu_move_corner_height = text_size
DEF menu_move_corner_width = menu_move_corner_height
DEF menu_topbar_pad = 2 * menu_pad + menu_move_corner_height
DEF menu_topbar_text_x_org =  menu_move_corner_width + x_spacer
DEF resize_corner_size = 20.
DEF menu_topbar_min_width = 300.
DEF menu_bottom_pad = 20.

DEF menu_sidebar_pad = menu_topbar_pad
DEF menu_sidebar_min_height = 20.
DEF menu_line = (1.,1.,1.,.8)

DEF seekbar_trim_color = color_on
DEF seekbar_trim_color_hover = (1., 0.84, 0.4, 0.8)
DEF seekbar_seek_color = color_on
DEF seekbar_seek_color_hover = (1., 0.84, 0.4, 0.8)
DEF seekbar_number_size = 15.

DEF timelines_draggable_size = resize_corner_size
DEF timeline_label_size = text_size

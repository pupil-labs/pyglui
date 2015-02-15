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

DEF color_selected = (.5,.9,.9,.9)
DEF color_on = (.5,.5,.9,.9)
DEF color_on_read_only = (.5,.5,.9,.4)
DEF color_default = (.5,.5,.5,.9)
DEF color_default_read_only = (.5,.5,.5,.5)
DEF color_shadow = (.0,.0,.0,.8)
DEF color_shadow_read_only = (.0,.0,.0,.0)
DEF shadow_sharpness = 0.3
DEF color_text_default = (1.,1.,1.,1.)
DEF color_text_info = (1.,1.,1.,.6)
DEF color_text_read_only = (.5,.5,.5,.5)
DEF color_line_default = (1.,1.,1.,.5)

# Slider - design parameters
DEF slider_outline_size_y = 80
DEF slider_label_org_y = 20
DEF slider_handle_org_y = 40
DEF slider_button_size = circle_button_size
DEF slider_button_size_read_only = 15
DEF slider_button_size_selected = circle_button_size_selected
DEF slider_button_shadow = circle_button_shadow
DEF slider_step_mark_size = 8
DEF slider_color_step = (.8,.8,.8,.6)
DEF slider_line_color_default = color_line_default
DEF slider_line_color_highlight = (.5,.5,.9,.9)
DEF slider_line_color_default_read_only = (1.,1.,1.,.5)
DEF slider_line_color_highlight_read_only = (.5,.5,.9,.6)

# Switch - design parameters
DEF switch_outline_size_y = 40
DEF switch_button_size = circle_button_size
DEF switch_button_size_selected = circle_button_size_selected
DEF switch_button_size_on = switch_button_size
DEF switch_button_shadow = circle_button_shadow

# Selector - design parameters
DEF selector_outline_size_y = 40
DEF selector_triangle_color_default = color_line_default
DEF selector_triangle_color_read_only = color_text_read_only

# Info_Text - design parameters
#DEF info_text_outline_size = 40

# TextInput - design parameters
DEF text_input_outline_size_y = 40
DEF text_input_highlight_color = (.5,.5,.9,.5)
DEF text_input_line_highlight_color = slider_line_color_highlight

# Button - design parameters
DEF button_outline_size_y = 40

# Thumb - design parameters
DEF thumb_outline_size = 120
DEF thumb_button_size_offset_on = 25
DEF thumb_button_size_offset_selected = 20
DEF thumb_button_size_offset_off = thumb_button_size_offset_on
DEF thumb_color_on = (.5,.5,.9,.9)
DEF thumb_color_off = (.5,.5,.5,.9)
DEF thumb_color_shadow = (.0,.0,.0,.5)
DEF thumb_button_sharpness = 0.9
DEF thumb_font_padding = 30

# Menu - design parameters
DEF menu_pad = 10
DEF menu_move_corner_height = text_size
DEF menu_move_corner_width = menu_move_corner_height
DEF menu_topbar_pad = 2 * menu_pad + menu_move_corner_height
DEF menu_topbar_text_x_org =  menu_move_corner_width + x_spacer
DEF resize_corner_size = 20
DEF menu_topbar_min_width = 200
DEF menu_bottom_pad = 20

DEF menu_sidebar_pad = menu_topbar_pad
DEF menu_sidebar_min_height = 20




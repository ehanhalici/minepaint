// src/draw_engine/brushsettings_gen.hats
// Pure ATS2 definitions for MinePaint Brush Settings and Inputs metadata
#ifndef BRUSHSETTINGS_GEN_HATS
#define BRUSHSETTINGS_GEN_HATS

#define MINEPAINT_BRUSH_SETTINGS_COUNT 65
#define MINEPAINT_BRUSH_INPUTS_COUNT 18

typedef MinePaintBrushSettingInfo = @{
  cname= string,
  name= string,
  constant= int,
  min= float,
  def= float,
  max= float,
  tooltip= string
}

typedef MinePaintBrushInputInfo = @{
  cname= string,
  hard_min= float,
  soft_min= float,
  normal= float,
  soft_max= float,
  hard_max= float,
  name= string,
  tooltip= string
}

fun init_setting_entry(
  p: ptr, idx: int,
  cname: string, name: string, constant: int,
  min_v: float, def_v: float, max_v: float, tooltip: string
): void = let
  val entry = $UN.cast{ref(MinePaintBrushSettingInfo)}(ptr_add<MinePaintBrushSettingInfo>(p, idx))
  val () = entry->cname := cname
  val () = entry->name := name
  val () = entry->constant := constant
  val () = entry->min := min_v
  val () = entry->def := def_v
  val () = entry->max := max_v
  val () = entry->tooltip := tooltip
in () end

fun init_input_entry(
  p: ptr, idx: int,
  cname: string,
  hard_min: float, soft_min: float, normal: float, soft_max: float, hard_max: float,
  name: string, tooltip: string
): void = let
  val entry = $UN.cast{ref(MinePaintBrushInputInfo)}(ptr_add<MinePaintBrushInputInfo>(p, idx))
  val () = entry->cname := cname
  val () = entry->hard_min := hard_min
  val () = entry->soft_min := soft_min
  val () = entry->normal := normal
  val () = entry->soft_max := soft_max
  val () = entry->hard_max := hard_max
  val () = entry->name := name
  val () = entry->tooltip := tooltip
in () end

fun populate_settings_info_array(p: ptr): void = let
  val () = init_setting_entry(p, 0, "opaque", "Opacity", 0, 0.0f, 1.0f, 2.0f, "0 means brush is transparent, 1 fully visible\n(also known as alpha or opacity)")
  val () = init_setting_entry(p, 1, "opaque_multiply", "Opacity multiply", 0, 0.0f, 0.0f, 2.0f, "This gets multiplied with opaque. You should only change the pressure input of this setting. Use 'opaque' instead to make opacity depend on speed.\nThis setting is responsible to stop painting when there is zero pressure. This is just a convention, the behaviour is identical to 'opaque'.")
  val () = init_setting_entry(p, 2, "opaque_linearize", "Opacity linearize", 1, 0.0f, 0.9f, 2.0f, "Correct the nonlinearity introduced by blending multiple dabs on top of each other. This correction should get you a linear (\"natural\") pressure response when pressure is mapped to opaque_multiply, as it is usually done. 0.9 is good for standard strokes, set it smaller if your brush scatters a lot, or higher if you use dabs_per_second.\n0.0 the opaque value above is for the individual dabs\n1.0 the opaque value above is for the final brush stroke, assuming each pixel gets (dabs_per_radius*2) brushdabs on average during a stroke")
  val () = init_setting_entry(p, 3, "radius_logarithmic", "Radius", 0, ~2.0f, 2.0f, 6.0f, "Basic brush radius (logarithmic)\n 0.7 means 2 pixels\n 3.0 means 20 pixels")
  val () = init_setting_entry(p, 4, "hardness", "Hardness", 0, 0.0f, 0.8f, 1.0f, "Hard brush-circle borders (setting to zero will draw nothing). To reach the maximum hardness, you need to disable Pixel feather.")
  val () = init_setting_entry(p, 5, "softness", "Softness", 0, 0.0f, 0.0f, 1.0f, "Soften brush-circle from center to edge (setting to 1.0 will draw nothing).")
  val () = init_setting_entry(p, 6, "anti_aliasing", "Pixel feather", 0, 0.0f, 1.0f, 5.0f, "This setting decreases the hardness when necessary to prevent a pixel staircase effect (aliasing) by making the dab more blurred.\n 0.0 disable (for very strong erasers and pixel brushes)\n 1.0 blur one pixel (good value)\n 5.0 notable blur, thin strokes will disappear")
  val () = init_setting_entry(p, 7, "dabs_per_basic_radius", "Dabs per basic radius", 0, 0.0f, 0.0f, 200.0f, "How many dabs to draw while the pointer moves a distance of one brush radius (more precise: the base value of the radius)")
  val () = init_setting_entry(p, 8, "dabs_per_actual_radius", "Dabs per actual radius", 0, 0.0f, 2.0f, 200.0f, "Same as above, but the radius actually drawn is used, which can change dynamically")
  val () = init_setting_entry(p, 9, "dabs_per_second", "Dabs per second", 0, 0.0f, 0.0f, 200.0f, "Dabs to draw each second, no matter how far the pointer moves")
  val () = init_setting_entry(p, 10, "gridmap_scale", "GridMap Scale", 0, ~10.0f, 0.0f, 10.0f, "Changes the overall scale that the GridMap brush input operates on.\nLogarithmic (same scale as brush radius).\nA scale of 0 will make the grid 256x256 pixels.")
  val () = init_setting_entry(p, 11, "gridmap_scale_x", "GridMap Scale X", 0, 0.0f, 1.0f, 10.0f, "Changes the scale that the GridMap brush input operates on - affects X axis only.\nThe range is 0-5x.\nThis allows you to stretch or compress the GridMap pattern.")
  val () = init_setting_entry(p, 12, "gridmap_scale_y", "GridMap Scale Y", 0, 0.0f, 1.0f, 10.0f, "Changes the scale that the GridMap brush input operates on - affects Y axis only.\nThe range is 0-5x.\nThis allows you to stretch or compress the GridMap pattern.")
  val () = init_setting_entry(p, 13, "radius_by_random", "Radius by random", 0, 0.0f, 0.0f, 1.5f, "Alter the radius randomly each dab. You can also do this with the by_random input on the radius setting. If you do it here, there are two differences:\n1) the opaque value will be corrected such that a big-radius dabs is more transparent\n2) it will not change the actual radius seen by dabs_per_actual_radius")
  val () = init_setting_entry(p, 14, "speed1_slowness", "Fine speed filter", 0, 0.0f, 0.04f, 0.2f, "How slow the input fine speed is following the real speed\n0.0 change immediately as your speed changes (not recommended, but try it)")
  val () = init_setting_entry(p, 15, "speed2_slowness", "Gross speed filter", 0, 0.0f, 0.8f, 3.0f, "Same as 'fine speed filter', but note that the range is different")
  val () = init_setting_entry(p, 16, "speed1_gamma", "Fine speed gamma", 1, ~8.0f, 4.0f, 8.0f, "This changes the reaction of the 'fine speed' input to extreme physical speed. You will see the difference best if 'fine speed' is mapped to the radius.\n-8.0 very fast speed does not increase 'fine speed' much more\n+8.0 very fast speed increases 'fine speed' a lot\nFor very slow speed the opposite happens.")
  val () = init_setting_entry(p, 17, "speed2_gamma", "Gross speed gamma", 1, ~8.0f, 4.0f, 8.0f, "Same as 'fine speed gamma' for gross speed")
  val () = init_setting_entry(p, 18, "offset_by_random", "Jitter", 0, 0.0f, 0.0f, 25.0f, "Add a random offset to the position where each dab is drawn\n 0.0 disabled\n 1.0 standard deviation is one basic radius away\n<0.0 negative values produce no jitter")
  val () = init_setting_entry(p, 19, "offset_y", "Offset Y", 0, ~40.0f, 0.0f, 40.0f, "Moves the dabs up or down based on canvas coordinates.")
  val () = init_setting_entry(p, 20, "offset_x", "Offset X", 0, ~40.0f, 0.0f, 40.0f, "Moves the dabs left or right based on canvas coordinates.")
  val () = init_setting_entry(p, 21, "offset_angle", "Angular Offset: Direction", 0, ~40.0f, 0.0f, 40.0f, "Follows the stroke direction to offset the dabs to one side.")
  val () = init_setting_entry(p, 22, "offset_angle_asc", "Angular Offset: Ascension", 0, ~40.0f, 0.0f, 40.0f, "Follows the tilt direction to offset the dabs to one side. Requires Tilt.")
  val () = init_setting_entry(p, 23, "offset_angle_view", "Angular Offset: View", 0, ~40.0f, 0.0f, 40.0f, "Follows the view orientation to offset the dabs to one side.")
  val () = init_setting_entry(p, 24, "offset_angle_2", "Angular Offset Mirrored: Direction", 0, 0.0f, 0.0f, 40.0f, "Follows the stroke direction to offset the dabs, but to both sides of the stroke.")
  val () = init_setting_entry(p, 25, "offset_angle_2_asc", "Angular Offset Mirrored: Ascension", 0, 0.0f, 0.0f, 40.0f, "Follows the tilt direction to offset the dabs, but to both sides of the stroke. Requires Tilt.")
  val () = init_setting_entry(p, 26, "offset_angle_2_view", "Angular Offset Mirrored: View", 0, 0.0f, 0.0f, 40.0f, "Follows the view orientation to offset the dabs, but to both sides of the stroke.")
  val () = init_setting_entry(p, 27, "offset_angle_adj", "Angular Offsets Adjustment", 0, ~180.0f, 0.0f, 180.0f, "Change the Angular Offset angle from the default, which is 90 degrees.")
  val () = init_setting_entry(p, 28, "offset_multiplier", "Offsets Multiplier", 0, ~2.0f, 0.0f, 3.0f, "Logarithmic multiplier for X, Y, and Angular Offset settings.")
  val () = init_setting_entry(p, 29, "offset_by_speed", "Offset by speed", 0, ~3.0f, 0.0f, 3.0f, "Change position depending on pointer speed\n= 0 disable\n> 0 draw where the pointer moves to\n< 0 draw where the pointer comes from")
  val () = init_setting_entry(p, 30, "offset_by_speed_slowness", "Offset by speed filter", 0, 0.0f, 1.0f, 15.0f, "How slow the offset goes back to zero when the cursor stops moving")
  val () = init_setting_entry(p, 31, "slow_tracking", "Slow position tracking", 1, 0.0f, 0.0f, 10.0f, "Slowdown pointer tracking speed. 0 disables it, higher values remove more jitter in cursor movements. Useful for drawing smooth, comic-like outlines.")
  val () = init_setting_entry(p, 32, "slow_tracking_per_dab", "Slow tracking per dab", 0, 0.0f, 0.0f, 10.0f, "Similar as above but at brushdab level (ignoring how much time has passed if brushdabs do not depend on time)")
  val () = init_setting_entry(p, 33, "tracking_noise", "Tracking noise", 1, 0.0f, 0.0f, 12.0f, "Add randomness to the mouse pointer; this usually generates many small lines in random directions; maybe try this together with 'slow tracking'")
  val () = init_setting_entry(p, 34, "color_h", "Color hue", 1, 0.0f, 0.0f, 1.0f, "Color hue")
  val () = init_setting_entry(p, 35, "color_s", "Color saturation", 1, ~0.5f, 0.0f, 1.5f, "Color saturation")
  val () = init_setting_entry(p, 36, "color_v", "Color value", 1, ~0.5f, 0.0f, 1.5f, "Color value (brightness, intensity)")
  val () = init_setting_entry(p, 37, "restore_color", "Save color", 1, 0.0f, 0.0f, 1.0f, "When selecting a brush, the color can be restored to the color that the brush was saved with.\n 0.0 do not modify the active color when selecting this brush\n 0.5 change active color towards brush color\n 1.0 set the active color to the brush color when selected")
  val () = init_setting_entry(p, 38, "change_color_h", "Change color hue", 0, ~2.0f, 0.0f, 2.0f, "Change color hue.\n-0.1 small clockwise color hue shift\n 0.0 disable\n 0.5 counterclockwise hue shift by 180 degrees")
  val () = init_setting_entry(p, 39, "change_color_l", "Change color lightness (HSL)", 0, ~2.0f, 0.0f, 2.0f, "Change the color lightness using the HSL color model.\n-1.0 blacker\n 0.0 disable\n 1.0 whiter")
  val () = init_setting_entry(p, 40, "change_color_hsl_s", "Change color satur. (HSL)", 0, ~2.0f, 0.0f, 2.0f, "Change the color saturation using the HSL color model.\n-1.0 more grayish\n 0.0 disable\n 1.0 more saturated")
  val () = init_setting_entry(p, 41, "change_color_v", "Change color value (HSV)", 0, ~2.0f, 0.0f, 2.0f, "Change the color value (brightness, intensity) using the HSV color model. HSV changes are applied before HSL.\n-1.0 darker\n 0.0 disable\n 1.0 brigher")
  val () = init_setting_entry(p, 42, "change_color_hsv_s", "Change color satur. (HSV)", 0, ~2.0f, 0.0f, 2.0f, "Change the color saturation using the HSV color model. HSV changes are applied before HSL.\n-1.0 more grayish\n 0.0 disable\n 1.0 more saturated")
  val () = init_setting_entry(p, 43, "smudge", "Smudge", 0, 0.0f, 0.0f, 1.0f, "Paint with the smudge color instead of the brush color. The smudge color is slowly changed to the color you are painting on.\n 0.0 do not use the smudge color\n 0.5 mix the smudge color with the brush color\n 1.0 use only the smudge color")
  val () = init_setting_entry(p, 44, "paint_mode", "Pigment", 0, 0.0f, 1.0f, 1.0f, "Subtractive spectral color mixing mode.\n0.0 no spectral mixing\n1.0 only spectral mixing")
  val () = init_setting_entry(p, 45, "smudge_transparency", "Smudge transparency", 0, ~1.0f, 0.0f, 1.0f, "Control how much transparency is picked up and smudged, similar to lock alpha.\n1.0 will not move any transparency.\n0.5 will move only 50% transparency and above.\n0.0 will have no effect.\nNegative values do the reverse")
  val () = init_setting_entry(p, 46, "smudge_length", "Smudge length", 0, 0.0f, 0.5f, 1.0f, "This controls how fast the smudge color becomes the color you are painting on.\n0.0 immediately update the smudge color (requires more CPU cycles because of the frequent color checks)\n0.5 change the smudge color steadily towards the canvas color\n1.0 never change the smudge color")
  val () = init_setting_entry(p, 47, "smudge_length_log", "Smudge length multiplier", 0, 0.0f, 0.0f, 20.0f, "Logarithmic multiplier for the \"Smudge length\" value.\nUseful to correct for high-definition/large brushes with lots of dabs.\nThe longer the smudge length the more a color will spread and will also boost performance dramatically, as the canvas is sampled less often")
  val () = init_setting_entry(p, 48, "smudge_bucket", "Smudge bucket", 0, 0.0f, 0.0f, 255.0f, "There are 256 buckets that each can hold a color picked up from the canvas.\nYou can control which bucket to use to improve variability and realism of the brush.\nEspecially useful with the \"Custom input\" setting to correlate buckets with other settings such as offsets.")
  val () = init_setting_entry(p, 49, "smudge_radius_log", "Smudge radius", 0, ~1.6f, 0.0f, 1.6f, "This modifies the radius of the circle where color is picked up for smudging.\n 0.0 use the brush radius\n-0.7 half the brush radius (fast, but not always intuitive)\n+0.7 twice the brush radius\n+1.6 five times the brush radius (slow performance)")
  val () = init_setting_entry(p, 50, "eraser", "Eraser", 0, 0.0f, 0.0f, 1.0f, "how much this tool behaves like an eraser\n 0.0 normal painting\n 1.0 standard eraser\n 0.5 pixels go towards 50% transparency")
  val () = init_setting_entry(p, 51, "stroke_threshold", "Stroke threshold", 1, 0.0f, 0.0f, 0.5f, "How much pressure is needed to start a stroke. This affects the stroke input only. MinePaint does not need a minimum pressure to start drawing.")
  val () = init_setting_entry(p, 52, "stroke_duration_logarithmic", "Stroke duration", 0, ~1.0f, 4.0f, 14.0f, "How far you have to move until the stroke input reaches 1.0. This value is logarithmic (negative values will not invert the process).")
  val () = init_setting_entry(p, 53, "stroke_holdtime", "Stroke hold time", 0, 0.0f, 0.0f, 10.0f, "This defines how long the stroke input stays at 1.0. After that it will reset to 0.0 and start growing again, even if the stroke is not yet finished.\n2.0 means twice as long as it takes to go from 0.0 to 1.0\n9.9 or higher stands for infinite")
  val () = init_setting_entry(p, 54, "custom_input", "Custom input", 0, ~5.0f, 0.0f, 5.0f, "Set the custom input to this value. If it is slowed down, move it towards this value (see below). The idea is that you make this input depend on a mixture of pressure/speed/whatever, and then make other settings depend on this 'custom input' instead of repeating this combination everywhere you need it.\nIf you make it change 'by random' you can generate a slow (smooth) random input.")
  val () = init_setting_entry(p, 55, "custom_input_slowness", "Custom input filter", 0, 0.0f, 0.0f, 10.0f, "How slow the custom input actually follows the desired value (the one above). This happens at brushdab level (ignoring how much time has passed, if brushdabs do not depend on time).\n0.0 no slowdown (changes apply instantly)")
  val () = init_setting_entry(p, 56, "elliptical_dab_ratio", "Elliptical dab: ratio", 0, 1.0f, 1.0f, 10.0f, "Aspect ratio of the dabs; must be >= 1.0, where 1.0 means a perfectly round dab.")
  val () = init_setting_entry(p, 57, "elliptical_dab_angle", "Elliptical dab: angle", 0, 0.0f, 90.0f, 180.0f, "Angle by which elliptical dabs are tilted\n 0.0 horizontal dabs\n 45.0 45 degrees, turned clockwise\n 180.0 horizontal again")
  val () = init_setting_entry(p, 58, "direction_filter", "Direction filter", 0, 0.0f, 2.0f, 10.0f, "A low value will make the direction input adapt more quickly, a high value will make it smoother")
  val () = init_setting_entry(p, 59, "lock_alpha", "Lock alpha", 0, 0.0f, 0.0f, 1.0f, "Do not modify the alpha channel of the layer (paint only where there is paint already)\n 0.0 normal painting\n 0.5 half of the paint gets applied normally\n 1.0 alpha channel fully locked")
  val () = init_setting_entry(p, 60, "colorize", "Colorize", 0, 0.0f, 0.0f, 1.0f, "Colorize the target layer, setting its hue and saturation from the active brush color while retaining its value and alpha.")
  val () = init_setting_entry(p, 61, "posterize", "Posterize", 0, 0.0f, 0.0f, 1.0f, "Strength of posterization, reducing number of colors based on the \"Posterization levels\" setting, while retaining alpha.")
  val () = init_setting_entry(p, 62, "posterize_num", "Posterization levels", 0, 0.01f, 0.05f, 1.28f, "Number of posterization levels (divided by 100).\n0.05 = 5 levels, 0.2 = 20 levels, etc.\nValues above 0.5 may not be noticeable.")
  val () = init_setting_entry(p, 63, "snap_to_pixel", "Snap to pixel", 0, 0.0f, 0.0f, 1.0f, "Snap brush dab's center and its radius to pixels. Set this to 1.0 for a thin pixel brush.")
  val () = init_setting_entry(p, 64, "pressure_gain_log", "Pressure gain", 1, ~1.8f, 0.0f, 1.8f, "This changes how hard you have to press. It multiplies tablet pressure by a constant factor.")
in () end

fun populate_inputs_info_array(p: ptr): void = let
  val () = init_input_entry(p, 0, "pressure", 0.0f, 0.0f, 0.4f, 1.0f, 3.402823466e+38f, "Pressure", "The pressure reported by the tablet. Usually between 0.0 and 1.0, but it may get larger when a pressure gain is used. If you use the mouse, it will be 0.5 when a button is pressed and 0.0 otherwise.")
  val () = init_input_entry(p, 1, "random", 0.0f, 0.0f, 0.5f, 1.0f, 1.0f, "Random", "Fast random noise, changing at each evaluation. Evenly distributed between 0 and 1.")
  val () = init_input_entry(p, 2, "stroke", 0.0f, 0.0f, 0.5f, 1.0f, 1.0f, "Stroke", "This input slowly goes from zero to one while you draw a stroke. It can also be configured to jump back to zero periodically while you move. Look at the 'stroke duration' and 'stroke hold time' settings.")
  val () = init_input_entry(p, 3, "direction", 0.0f, 0.0f, 0.0f, 180.0f, 180.0f, "Direction", "The angle of the stroke, in degrees. The value will stay between 0.0 and 180.0, effectively ignoring turns of 180 degrees.")
  val () = init_input_entry(p, 4, "tilt_declination", 0.0f, 0.0f, 0.0f, 90.0f, 90.0f, "Declination/Tilt", "Declination of stylus tilt. 0 when stylus is parallel to tablet and 90.0 when it's perpendicular to tablet.")
  val () = init_input_entry(p, 5, "tilt_ascension", ~180.0f, ~180.0f, 0.0f, 180.0f, 180.0f, "Ascension", "Right ascension of stylus tilt. 0 when stylus working end points to you, +90 when rotated 90 degrees clockwise, -90 when rotated 90 degrees counterclockwise.")
  val () = init_input_entry(p, 6, "speed1", ~3.402823466e+38f, 0.0f, 0.5f, 4.0f, 3.402823466e+38f, "Fine speed", "How fast you currently move. This can change very quickly. Try 'print input values' from the 'help' menu to get a feeling for the range; negative values are rare but possible for very low speed.")
  val () = init_input_entry(p, 7, "speed2", ~3.402823466e+38f, 0.0f, 0.5f, 4.0f, 3.402823466e+38f, "Gross speed", "Same as fine speed, but changes slower. Also look at the 'gross speed filter' setting.")
  val () = init_input_entry(p, 8, "custom", ~3.402823466e+38f, ~10.0f, 0.0f, 10.0f, 3.402823466e+38f, "Custom", "This is a user defined input. Look at the 'custom input' setting for details.")
  val () = init_input_entry(p, 9, "direction_angle", 0.0f, 0.0f, 0.0f, 360.0f, 360.0f, "Direction 360", "The angle of the stroke, from 0 to 360 degrees.")
  val () = init_input_entry(p, 10, "attack_angle", ~180.0f, ~180.0f, 0.0f, 180.0f, 180.0f, "Attack Angle", "The difference, in degrees, between the angle the stylus is pointing and the angle of the stroke movement.\nThe range is +/-180.0.\n0.0 means the stroke angle corresponds to the angle of the stylus.\n90 means the stroke angle is perpendicular to the angle of the stylus.\n180 means the angle of the stroke is directly opposite the angle of the stylus.")
  val () = init_input_entry(p, 11, "tilt_declinationx", ~90.0f, ~90.0f, 0.0f, 90.0f, 90.0f, "Declination/Tilt X", "Declination of stylus tilt on X-Axis. 90/-90 when stylus is parallel to tablet and 0 when it's perpendicular to tablet.")
  val () = init_input_entry(p, 12, "tilt_declinationy", ~90.0f, ~90.0f, 0.0f, 90.0f, 90.0f, "Declination/Tilt Y", "Declination of stylus tilt on Y-Axis. 90/-90 when stylus is parallel to tablet and 0 when it's perpendicular to tablet.")
  val () = init_input_entry(p, 13, "gridmap_x", 0.0f, 0.0f, 0.0f, 256.0f, 256.0f, "GridMap X", "The X coordinate on a 256 pixel grid. This will wrap around 0-256 as the cursor is moved on the X axis. Similar to \"Stroke\". Can be used to add paper texture by modifying opacity, etc.\nThe brush size should be considerably smaller than the grid scale for best results.")
  val () = init_input_entry(p, 14, "gridmap_y", 0.0f, 0.0f, 0.0f, 256.0f, 256.0f, "GridMap Y", "The Y coordinate on a 256 pixel grid. This will wrap around 0-256 as the cursor is moved on the Y axis. Similar to \"Stroke\". Can be used to add paper texture by modifying opacity, etc.\nThe brush size should be considerably smaller than the grid scale for best results.")
  val () = init_input_entry(p, 15, "viewzoom", ~2.77f, ~2.77f, 0.0f, 4.15f, 4.15f, "Zoom Level", "The current zoom level of the canvas view.\nLogarithmic: 0.0 is 100%, 0.69 is 200%, -1.38 is 25%\nFor the Radius setting, using a value of -4.15 makes the brush size roughly constant, relative to the level of zoom.")
  val () = init_input_entry(p, 16, "brush_radius", ~2.0f, ~2.0f, 0.0f, 6.0f, 6.0f, "Base Brush Radius", "The base brush radius allows you to change the behavior of a brush as you make it bigger or smaller.\nYou can even cancel out dab size increase and adjust something else to make a brush bigger.\nTake note of \"Dabs per basic radius\" and \"Dabs per actual radius\", which behave much differently.")
  val () = init_input_entry(p, 17, "barrel_rotation", ~180.0f, ~180.0f, 0.0f, 180.0f, 180.0f, "Barrel Rotation", "Barrel rotation of stylus.\n0 when not twisted\n+90 when twisted clockwise 90 degrees\n-90 when twisted counterclockwise 90 degrees")
in () end

#endif // BRUSHSETTINGS_GEN_HATS

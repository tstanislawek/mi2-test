+++
# Hero Carousel widget.
widget = "hero_carousel"  # Do not modify this line!
active = true  # Activate this widget? true/false

# Order that this section will appear in.
weight = 1

# Slide interval.
# Use `false` to disable animation or enter a time in ms, e.g. `5000` (5s).
interval = false

# Minimum slide height.
# Specify a height to ensure a consistent height for each slide.
height = "500px"

# Slides.
# Duplicate an `[[item]]` block to add more slides.
[[item]]
  title = "Poster prize "
  content = "Alicja Gosiewska and Agnieszka Ciepielewska won the best poster award at PLinML2018"
  align = "center"  # Choose `center`, `left`, or `right`.

  # Overlay a color or image (optional).
  #   Deactivate an option by commenting out the line, prefixing it with `#`.
  overlay_color = "#666"  # An HTML color value.
  overlay_img = "poster-prize.jpg"  # Image path relative to your `static/img/` folder.
  overlay_filter = 0.5  # Darken the image. Value in range 0-1.

[[item]]
  title = "Proin"
  content = "Proin consectetur condimentum tellus, vel malesuada orci semper ornare. "
  align = "left"

  overlay_color = "#555"  # An HTML color value.
  overlay_img = "vapnik.jpg"  # Image path relative to your `static/img/` folder.
  overlay_filter = 0.1 # Darken the image. Value in range 0-1.

+++

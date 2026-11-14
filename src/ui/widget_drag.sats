// Which sidebar control, if any, is currently being dragged.
staload "ui/slider_id.sats"

datatype WidgetDrag =
  | DragNone
  | DragHue
  | DragSv
  | DragSlider of SliderId

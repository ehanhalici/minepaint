// Which sidebar control, if any, is currently being dragged.
datatype WidgetDrag =
  | DragNone
  | DragHue
  | DragSv
  | DragSlider of int

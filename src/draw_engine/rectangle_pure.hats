// Value-level rectangle growth. MinePaintRectangle must already be in scope.
#ifndef RECTANGLE_PURE_HATS
#define RECTANGLE_PURE_HATS

fn expand_axis(pos: int, span: int, pt: int): @(int, int) =
  if pt < pos then @(pt, span + (pos - pt))
  else if pt >= pos + span then @(pos, pt - pos + 1)
  else @(pos, span)

fn rect_expand_point(r: MinePaintRectangle, x: int, y: int): MinePaintRectangle =
  if r.width = 0 then @{ x= x, y= y, width= 1, height= 1 }
  else let
    val @(nx, nw) = expand_axis(r.x, r.width, x)
    val @(ny, nh) = expand_axis(r.y, r.height, y)
  in
    @{ x= nx, y= ny, width= nw, height= nh }
  end

fn rect_expand_rect(r: MinePaintRectangle, o: MinePaintRectangle): MinePaintRectangle = let
  val r1 = rect_expand_point(r, o.x, o.y)
in
  rect_expand_point(r1, o.x + o.width - 1, o.y + o.height - 1)
end

#endif

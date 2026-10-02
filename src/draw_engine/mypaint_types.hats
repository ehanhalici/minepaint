// src/draw_engine/mypaint_types.hats
// Native ATS2 Type Definitions for MyPaint Engine
#ifndef MYPAINT_TYPES_HATS
#define MYPAINT_TYPES_HATS

#define MYPAINT_TILE_SIZE 64
#define NUM_BBOXES_DEFAULT 32

typedef MyPaintRectangle = @{
  x= int,
  y= int,
  width= int,
  height= int
}

typedef MyPaintRectangles = @{
  num_rectangles= int,
  rectangles= ptr
}

typedef MyPaintSurfaceGetColorFunction = (
  ptr, float, float, float, ptr, ptr, ptr, ptr, float
) -> void

typedef MyPaintSurfaceDrawDabFunction = (
  ptr, float, float, float, float, float, float,
  float, float, float, float, float, float,
  float, float, float, float, float
) -> int

typedef MyPaintSurfaceDestroyFunction = (ptr) -> void
typedef MyPaintSurfaceSavePngFunction = (ptr, string, int, int, int, int) -> void
typedef MyPaintSurfaceBeginAtomicFunction = (ptr) -> void
typedef MyPaintSurfaceEndAtomicFunction = (ptr, ptr) -> void

typedef MyPaintSurface = @{
  draw_dab= ptr,
  get_color= ptr,
  begin_atomic= ptr,
  end_atomic= ptr,
  destroy= ptr,
  save_png= ptr,
  refcount= int
}

typedef MyPaintSymmetryState = @{
  type= int,
  center_x= float,
  center_y= float,
  angle= float,
  num_lines= float
}

typedef MyPaintSymmetryData = @{
  active= int,
  pending_active= int,
  state_current= MyPaintSymmetryState,
  state_pending= MyPaintSymmetryState,
  num_symmetry_matrices= int,
  symmetry_matrices= ptr
}

typedef MyPaintTileRequest = @{
  tx= int,
  ty= int,
  readonly= int,
  buffer= ptr,
  context= ptr,
  thread_id= int,
  mipmap_level= int
}

typedef MyPaintTileRequestStartFunction = (ptr, ptr) -> void
typedef MyPaintTileRequestEndFunction = (ptr, ptr) -> void

typedef MyPaintTiledSurface = @{
  parent= MyPaintSurface,
  tile_request_start= ptr,
  tile_request_end= ptr,
  symmetry_data= ptr,
  operation_queue= ptr,
  num_bboxes= int,
  num_bboxes_dirtied= int,
  bboxes= ptr,
  default_bboxes= ptr,
  threadsafe_tile_requests= int,
  tile_size= int
}

typedef OperationDataDrawDab = @{
  x= float,
  y= float,
  radius= float,
  color_r= uint16,
  color_g= uint16,
  color_b= uint16,
  color_a= float,
  opaque= float,
  hardness= float,
  softness= float,
  aspect_ratio= float,
  angle= float,
  normal= float,
  lock_alpha= float,
  colorize= float,
  posterize= float,
  posterize_num= float,
  paint= float
}

#endif // MYPAINT_TYPES_HATS

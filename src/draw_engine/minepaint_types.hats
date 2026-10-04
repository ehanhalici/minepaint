// src/draw_engine/minepaint_types.hats
// Native ATS2 Type Definitions for MinePaint Engine
#ifndef MINEPAINT_TYPES_HATS
#define MINEPAINT_TYPES_HATS

#define MINEPAINT_TILE_SIZE 64
#define NUM_BBOXES_DEFAULT 32

typedef MinePaintRectangle = @{
  x= int,
  y= int,
  width= int,
  height= int
}

typedef MinePaintRectangles = @{
  num_rectangles= int,
  rectangles= ptr
}

typedef MinePaintSurfaceGetColorFunction = (
  ptr, float, float, float, ptr, ptr, ptr, ptr, float
) -> void

typedef MinePaintSurfaceDrawDabFunction = (
  ptr, float, float, float, float, float, float,
  float, float, float, float, float, float,
  float, float, float, float, float
) -> int

typedef MinePaintSurfaceDestroyFunction = (ptr) -> void
typedef MinePaintSurfaceSavePngFunction = (ptr, string, int, int, int, int) -> void
typedef MinePaintSurfaceBeginAtomicFunction = (ptr) -> void
typedef MinePaintSurfaceEndAtomicFunction = (ptr, ptr) -> void

typedef MinePaintSurface = @{
  draw_dab= ptr,
  get_color= ptr,
  begin_atomic= ptr,
  end_atomic= ptr,
  destroy= ptr,
  save_png= ptr,
  refcount= int
}

typedef MinePaintSymmetryState = @{
  type= int,
  center_x= float,
  center_y= float,
  angle= float,
  num_lines= float
}

typedef MinePaintSymmetryData = @{
  active= int,
  pending_active= int,
  state_current= MinePaintSymmetryState,
  state_pending= MinePaintSymmetryState,
  num_symmetry_matrices= int,
  symmetry_matrices= ptr
}

typedef MinePaintTileRequest = @{
  tx= int,
  ty= int,
  readonly= int,
  buffer= ptr,
  context= ptr,
  thread_id= int,
  mipmap_level= int
}

typedef MinePaintTileRequestStartFunction = (ptr, ptr) -> void
typedef MinePaintTileRequestEndFunction = (ptr, ptr) -> void

typedef MinePaintTiledSurface = @{
  parent= MinePaintSurface,
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

#endif // MINEPAINT_TYPES_HATS

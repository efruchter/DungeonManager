--[[
  Pathfinding for each of the hero units, and the larger individual units, will be managed by this
  module.
  
  The path finding will go through A* from the beginning, and then the path smoothing will occur
  through ray tracing. Check the center of the tiles that is found through A*, and then if the ray
  projected from the local user is unobstructed by any wall or entity to the location, then accept
  the path and create a ray to that location.
  
  For testing if the ray hits an obstruction, generate a unit vector scaled by 0.5, and test at each
  interval along the vector.
--]]

require 'entity-manager/sets'

map_width = 100
map_height = 100
f_value_map = {}
map_initialized = false
cached_paths = {}

-- Initialize the f_value_map. This can only be called for a single unit at a time.
function init_f_value_map()
  for i = 1, map_width do
    table.insert(f_value_map, {})
    
    for j = 1, map_height do
      table.insert(f_value_map[i], -1)
    end
  end
  
  map_initialized = true
end

-- Empty the f_value_map
function empty_f_value_map()
  if not map_initialized then
    init_f_value_map()
  end
  
  for i = 1, map_height do
    for j = 1, map_width do
      f_value_map[i][j] = -1
    end
  end
end

function get_cache_path(x1, y1, x2, y2)
  local cache_path = cached_paths[x1]
  if cache_path == nil then return nil end
  cache_path = cached_paths[y1]
  if cache_path == nil then return nil end
  cache_path = cached_paths[x2]
  if cache_path == nil then return nil end
  return cache_path[y2]
end

function set_cache_path(x1, y1, x2, y2, path)
  local cache_path = cached_paths[x1]
  if cache_path == nil then
    cached_paths[x1] = {}
    cache_path = cached_paths[x1]
  end
  
  cache_path = cache_path[y1]
  if cache_path == nil then
    cached_paths[y1] = {}
    cache_path = cached_paths[y1]
  end
  
  cache_path = cache_path[x2]
  if cache_path == nil then
    cached_paths[x2] = {}
    cache_path = cached_paths[x2]
  end

  cache_path[y2] = path
end


-- Using A* to find the path of the target.
function find_path(source_tile, target_tile)
  if source_tile[1] == target_tile[1] and source_tile[2] == target_tile[2] then
    return {source_tile}
  end

  local open_set = Set:new('open')
  local closed_set = Set:new('closed')
  open_set:insert(source_tile[1], source_tile[2], 0)
  empty_f_value_map()
  f_value_map[source_tile[1]][source_tile[2]] = h(target_tile[1] - source_tile[1], target_tile[2] - source_tile[2])
  
  local searchCount = 0
  
  while not open_set:is_empty() do
    local tile = open_set:pop()
    searchCount = searchCount + 1
    
    if searchCount > 10000 then
      return nil
    end
    
    if tile[1] == target_tile[1] and tile[2] == target_tile[2] then 
      return reconstruct_path(source_tile, target_tile) 
    end
    
    closed_set:insert(tile[1], tile[2], tile[3])
    neighbors = get_neighbors(tile)
    
    for i, neighbor in ipairs(neighbors) do
      g_score = neighbor[3]
      val = closed_set:get(neighbor[1], neighbor[2])
      
      if val == nil or g_score < val[3] then
        val = open_set:get(neighbor[1], neighbor[2])
        
        if val == nil or g_score < val[3] then
          if val == nil then
            open_set:insert(neighbor[1], neighbor[2], neighbor[3])
            val = neighbor
          end
          
          val[3] = g_score
          f_value_map[val[1]][val[2]] = g_score + h(target_tile[1] - val[1], target_tile[2] - val[2])
        end
      end
    end
  end
  
  return nil
end

-- Get the neighboring tiles for the tile that is provided.
function get_neighbors(tile)
  local neighbors = {}
  local x = tile[1]
  local y = tile[2]
  
  local offsetx, offsety = 1,1

  if x > 1 and map[y + offsety][x - 1 + offsetx] == 0 then
    table.insert(neighbors, {x - 1, y, tile[3] + 1})
  end
  
  if x < map_width and map[y + offsety][x + 1 + offsetx] == 0 then
    table.insert(neighbors, {x + 1, y, tile[3] + 1})
  end
  
  if y > 1 and map[y - 1 + offsety][x + offsetx] == 0 then
    table.insert(neighbors, {x, y - 1, tile[3] + 1})
  end
  
  if y < map_height and map[y + 1 + offsety][x + offsetx] == 0 then
    table.insert(neighbors, {x, y + 1, tile[3] + 1})
  end
  
  return neighbors
end

-- The heuristic function is the euclidean distance.
function h(dx, dy)
  return math.sqrt(dx * dx + dy * dy)
end

function reconstruct_path(start, goal)
  local current = goal
  local path = {}
  local tmpcount = 0
  local previous_direction = -1
  
  --if get_cache_path(start[1], start[2], goal[1], goal[2]) ~= nil then
  --  return get_cache_path(start[1], start[2], goal[1], goal[2])
  --end

  while not(current[1] == start[1] and current[2] == start[2]) do
    local min_value = -1
    local min_current = current
    
    local x, y = current[1], current[2]
    local msg = ''
    local tmp_prev = previous_direction
    
    if x > 1 and previous_direction ~= 2 then
      val = f_value_map[x - 1][y]
      if min_value == -1 or (val >= 0 and val < min_value) then
        min_value = val
        min_current = {x - 1, y}
        tmp_prev = 1
      end
    end
    
    if x < map_width and previous_direction ~= 1 then
      val = f_value_map[x + 1][y]
      if min_value == -1 or (val >= 0 and val < min_value) then
        min_value = val
        min_current = {x + 1, y}
        tmp_prev = 2
      end
    end
    
    if y > 1 and previous_direction ~= 4 then
      val = f_value_map[x][y - 1]
      if min_value == -1 or (val >= 0 and val < min_value) then
        min_value = val
        min_current = {x, y - 1}
        tmp_prev = 3
      end
    end
    
    if y < map_height and previous_direction ~= 3 then
      val = f_value_map[x][y + 1]
      if min_value == -1 or (val >= 0 and val < min_value) then
        min_value = val
        min_current = {x, y + 1}
        tmp_prev = 4
      end
    end
    
    table.insert(path, min_current)
    current = min_current
    previous_direction = tmp_prev
  end
  
  local reverse_path = {}
  
  for i = table.getn(path), 1, -1 do
    if path[i] == nil then error('whyyyy') end
      
    table.insert(reverse_path, path[i])
  end

  --set_cache_path(start[1], start[2], goal[1], goal[2], reverse_path)
  return reverse_path
end

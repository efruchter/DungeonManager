--[[
  The map will be centered around zero, as in the boss room has the tile 0,0 in the middle of the 
  room. The indexing of the tiles will be relative to the center tile.
  
  All sections are the same size, which will make indexing between sections simpler, as well as
  generating and attaching new sections easier.
    Initially the size will be 10x10
    A circular configuration should be favored, to lessen chance of a long hallway
  
  The map will be represented by an integer array. Keep the array the size of the entire map, which
  is the top left corner to the bottom right corner.
    
    * *
    * *
    * * *B*
    * * *B*
    
  In the above example, the map size will be 4x4.
  
  To maintain the center, keep an offset value from the top-left corner, of the location of the 
  center tile. A series of functions will manipulate the structure and maintain positions.
  
  3 coordinate frames will exist, to ensure that remapping of every unit does not have to occur
  at each iteration. 1 coordinate frame is the actual array, the second is the world representation
  and the final coordinate frame is the pixel representation of the world.

--]]

MAP_SIZE = 100

map = {}

--Mapping the tile world to the real, walkable world
map_to_real = 32

setColor = love.graphics.setColor
rectangle = love.graphics.rectangle

-- The size of each section.
SECTION_SIZE = 10

-- ======== Definition list of the floor tile compositions ========
-- The code for a floor tile
MAP_FLOOR_TILE = 0
-- The code for a wall tile
MAP_WALL_TILE = 1
-- THe code for an invisible tile, as in a tile that cannot be seen or is unknown.
MAP_INVISIBLE_TILE = 2

wall_list = {}

-- Initialize the map with a single room of size SECTION_SIZE x SECTION_SIZE. The configuration
-- will be very simple, in which the heroes will directly engage the manager without any traps or
-- special powers. The room will have 4 entrances, in which the heroes can enter.
function init_map()
    for r = 1, MAP_SIZE do
        row = {}
        for c = 1, MAP_SIZE do
            table.insert(row, MAP_INVISIBLE_TILE)
        end
        table.insert(map, row)
    end

    local fun = {
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
    }

    local start_x = math.floor(MAP_SIZE / 2) - math.floor(#fun[1] / 2)
    local start_y = math.floor(MAP_SIZE / 2) - math.floor(#fun / 2)

    for fun_y, row in ipairs(fun) do
        for fun_x, val in ipairs(row) do
            x = start_x + fun_x - 1
            y = start_y + fun_y - 1
            map[y][x] = fun[fun_y][fun_x]
        end
    end

    update_wall_list()
end

function drawmap_depth0(map, camera)
    for my, line in ipairs(map) do
        for mx, v in ipairs(line) do
            if v == 1 then
                setColor(255, 100, 255, 255)
                rectangle("fill", (mx-1) * map_to_real, (my-1) * map_to_real , map_to_real, map_to_real)
            end
        end
    end
    for my, line in ipairs(map) do
        for mx, v in ipairs(line) do
            if v == 1 then
                setColor(255, 255, 255, 255)
                rectangle("fill", (mx-1) * map_to_real, (my-1.5) * map_to_real, map_to_real, map_to_real)
            end
        end
    end
end

function drawmap_depth_floor(map, camera)
    for my, line in ipairs(map) do
        for mx, v in ipairs(line) do
            if v == 0 then
                setColor(100, 100, 255, 255)
                rectangle("fill", (mx-1) * map_to_real, (my-1) * map_to_real , map_to_real, map_to_real)
                setColor(100, 100, 200, 255)
                rectangle("line", (mx-1) * map_to_real, (my-1) * map_to_real , map_to_real, map_to_real)
            end
        end
    end
end

function drawmap_depth_camera(map, camera)
    local cx = getCameraTileTuple(camera)
    setColor(255, 0, 0, 255, 10)
    rectangle("line", (cx.x-1) * map_to_real, (cx.y-1) * map_to_real , map_to_real, map_to_real)
end

function getCameraTileTuple(camera)
    return {x = math.floor(camera.x / map_to_real), y = math.floor(camera.y / map_to_real)}
end

function boundingBoxTile(x, y)
    local b = {}
    b.left = x * map_to_real - 1
    b.right = (x+1) * map_to_real + 1
    b.top = y * map_to_real - 1
    b.bottom = (y+1) * map_to_real + 1
    return b
end

function update_wall_list()
    wall_list = {}

    for y, row in ipairs(map) do
        for x, val in ipairs(row) do
            if val == MAP_WALL_TILE then
                table.insert(wall_list, {x=x, y=y})
            end
        end
    end
end

function sameTile(a, b)
    return math.floor(a.x / map_to_real) == math.floor(b.x / map_to_real) and
            math.floor(a.y / map_to_real) == math.floor(b.y / map_to_real)
end

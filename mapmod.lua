require "humanAI"

mapmod_buildmode = false
local cell = {}
local oldmap = {}
local showing_mod = false
local wall_x, wall_y

function mapmod_keypress(key, unicode)
    if key == " " then
        if not mapmod_buildmode and stats.gold >= ROOM_PRICE then
            mapmod_buildmode = true
            store_map()
            showing_mod = false
            mapmod_camera_moved()
        elseif mapmod_buildmode and showing_mod then
            payGold(ROOM_PRICE)
            update_wall_list()

            local wall_x, wall_y = nearest_wall_from(oldmap, cell.x, cell.y)
            addExploreGoal({x=(wall_x * map_to_real), y=(wall_y * map_to_real)})

            mapmod_buildmode = false
            cell = {}
        end
    elseif key == "escape" and mapmod_buildmode then
        mapmod_buildmode = false
        restore_map()
    end
end

function mapmod_camera_moved()
    if not mapmod_buildmode then return end

    local cell_x, cell_y = camera_cell()

    if cell_x ~= cell.x or cell_y ~= cell.y then
        cell.x = cell_x
        cell.y = cell_y

        restore_map()

        if oldmap[cell.y][cell.x] == MAP_INVISIBLE_TILE then
            showing_mod = show_mod(cell.x, cell.y)
        end
    end
end

function store_map()
    oldmap = {}
    for y, row in ipairs(map) do
        oldmap[y] = {}
        for x, val in ipairs(row) do
            oldmap[y][x] = val
        end
    end
end

function restore_map()
    map = {}
    for y, row in ipairs(oldmap) do
        map[y] = {}
        for x, val in ipairs(row) do
            map[y][x] = val
        end
    end
end

function show_mod(x, y)
    local wall_x, wall_y = nearest_wall_from(map, x, y)
    if wall_x == nil then return false end

    -- Open an 11x11 room centered around the closest wall tile to x, y
    for dx = -5, 5 do
        for dy = -5, 5 do
            if map[wall_y + dy][wall_x + dx] == MAP_INVISIBLE_TILE then
                local tile_type

                if (dx == -5 or dx == 5) or (dy == -5 or dy == 5) then
                    tile_type = MAP_WALL_TILE
                else
                    tile_type = MAP_FLOOR_TILE
                end

                map[wall_y + dy][wall_x + dx] = tile_type
            end
        end
    end

    -- Open a doorway into the room
    for dx = -1, 1 do
        for dy = -1, 1 do
            if map[wall_y + dy][wall_x + dx] == MAP_WALL_TILE then
                map[wall_y + dy][wall_x + dx] = MAP_FLOOR_TILE
            end
        end
    end

    return true
end

function nearest_wall_from(map, from_x, from_y)
    for dist = 1, 10 do
        for x = -dist, dist do
            for y = -dist, dist do
                if math.abs(x) + math.abs(y) == dist and
                        map[from_y + y][from_x + x] == MAP_WALL_TILE then
                    return from_x + x, from_y + y
                end
            end
        end
    end
end

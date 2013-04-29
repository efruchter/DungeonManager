require "util"

Z_SCALE_MIN = .40
Z_SCALE_MAX = 2

is_down = love.keyboard.isDown
glTranslate = love.graphics.translate
glScale = love.graphics.scale

function init_camera()
    local camera = {}
    camera.x = math.floor(MAP_SIZE / 2 * map_to_real)
    camera.y = math.floor(MAP_SIZE / 2 * map_to_real)
    camera.scale = .7
    return camera
end

function update_camera(dt)
    if is_down("lshift") then
        dt = dt * 10
    end

    local camera_moved = false

    if is_down("left") then
        camera.x = camera.x - 100 * dt
        camera_moved = true
    elseif is_down("right") then
        camera.x = camera.x + 100 * dt
        camera_moved = true
    end

    if is_down("up") then
        camera.y = camera.y - 100 * dt
        camera_moved = true
    elseif is_down("down") then
        camera.y = camera.y + 100 * dt
        camera_moved = true
    end

    if is_down("z") then
        camera.scale = camera.scale - 1 * dt
        camera_moved = true
    elseif is_down("x") then
        camera.scale = camera.scale + 1 * dt
        camera_moved = true
    end

    camera.scale = clamp(camera.scale, Z_SCALE_MIN, Z_SCALE_MAX)

    return camera_moved
end

function camera_transform()
    glTranslate(
        -camera.x * camera.scale + love.graphics.getWidth()  / 2,
        -camera.y * camera.scale + love.graphics.getHeight() / 2)
    glScale(camera.scale, camera.scale)
end

function camera_pos()
    return camera.x, camera.y
end

function camera_cell()
    local cell_x = math.floor(camera.x / map_to_real)
    local cell_y = math.floor(camera.y / map_to_real)
    return cell_x, cell_y
end

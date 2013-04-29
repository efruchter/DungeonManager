require "camera"
require "map"
require "mapmod"
require "entity"
require "entityPrefab"
require "gui"
require "placement"

require "demo"
require "humanAI"

humNum = 0
state = "Placement"

PLACEMENT_STATE = "Placement"
WAVE_STATE = "Wave"
LOSE_STATE = "LOSER"

pentagram = love.graphics.newImage("images/pentagram.png")

function love.load()
    camera = init_camera()
    init_map()
    love.graphics.setBackgroundColor( 100, 100, 100 )

    --init_demo()

    debug = false
end

function love.update(dt)
    camera_moved = update_camera(dt)

    if camera_moved then
        mapmod_camera_moved()
    end

    stateLogic(dt)
    updateEntities(dt)

end

function stateLogic(dt)
    if state == WAVE_STATE then waveState(dt)
    elseif state == PLACEMENT_STATE then placementState(dt) end
end

function waveState(dt)
    if getEntityCount("monster", "player") == 0 then
        state = LOSE_STATE
    end
end

function placementState(dt)

end

local base_x = 49 * map_to_real + map_to_real / 2
local base_y = 49 * map_to_real + map_to_real / 2

function onWaveStart()
    stats.wave = stats.wave + 1
    for i=1,stats.wave do
        local human = Copernicus()
        human:setPos(base_x, base_y)
        addEntity(human)
    end
end

function humanBorn()
    humNum = humNum + 1
end

function humanDead()
    humNum = humNum - 1
    payGold(-HUMAN_BOUNTY)
    if humNum == 0 then
        state = PLACEMENT_STATE
    end
end

function love.draw()
    if state == WAVE_STATE then
        love.graphics.setBackgroundColor(255, 0, 0, 255)
    else
        love.graphics.setBackgroundColor(100, 100, 255, 255)
    end
    love.graphics.push()
        --Camera
        camera_transform()
        --floor
        drawmap_depth_floor(map, camera)
        --Copernicus spawn zone
        if state == WAVE_STATE then
            love.graphics.setColor(math.random()*255, math.random()*255, math.random()*255, 255)
        else
            love.graphics.setColor(255, 0, 0, 255)
        end
        love.graphics.draw(pentagram, base_x, base_y, pentAngle, .4, .4, 220 / 2, 220 / 2)
        pentAngle = pentAngle + .01
        --tiles
        for key, entity in ipairs(getEntities("tile")) do
            entity:draw()
        end
        --camera viewer
        drawmap_depth_camera(map, camera)
        --monsters
        for key, entity in ipairs(getEntities("monster")) do
            entity:draw()
        end
        --walls
        drawmap_depth0(map, camera)
        --projectiles
        for key, entity in ipairs(getEntities("projectile")) do
            entity:draw()
        end
        --'splosions
        for key, entity in ipairs(getEntities("explosion")) do
            entity:draw()
        end
        --health bars and such
        for key, entity in ipairs(getEntities("monster")) do
            entity:drawDiagnostic()
        end
        --floating messages
        for key, entity in ipairs(getEntities("message")) do
            entity:draw()
        end
        --aggro
        if state == PLACEMENT_STATE then
            for key, entity in ipairs(getEntities("monster")) do
                drawAggro(entity)
            end
        end
    love.graphics.pop()

    love.graphics.setColor(255, 255, 255, 255)

    drawGui()

    print_debug_info()
end

pentAngle = 0

function love.keypressed(key, unicode)
    if state == PLACEMENT_STATE then
        mapmod_keypress(key, unicode)
        placement_keypress(key, unicode)
        if key == "return" then
            state = WAVE_STATE
            onWaveStart()
        end
    end
    if key == "p" then
        payGold(-100)
    end
end

function print_debug_info()
    if not debug then return end

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.printf("FPS: " .. love.timer.getFPS(), 0, 0, 800)
    love.graphics.printf("mapmod_buildmode: " .. tostring(mapmod_buildmode), 0, 12, 800)
end

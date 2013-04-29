--[[
  An entity is any unit that is not part of the map, missile or item (e.g. treasure chest).
  
  An entity will need to be initialized on the map at the beginning of the round. The entity needs
  to maintain a coordinate of where it currently is, and where it will start.
  
  
--]]

require "util"
require "map"
require "renderUtil"
require "entity-manager/pathfinding"

newImage = love.graphics.newImage
setColor = love.graphics.setColor

square = math.sqrt
abs = math.abs

--This makes the physics work out correctly. Adjust accordingly.
PIXELS_TO_METERS = 100 / 10

collisions = {}
entities = {}

function getEntities(class)
    if not class then
        return entities
    elseif not entities[class] then
        return {}
    else
        return entities[class]
    end
end

function updateEntities(dt)

    for i, class in pairs(entities) do
        for i, entity in ipairs(class) do
            entity:onUpdate(dt)
        end
    end

    for id, class in pairs(entities) do
        for index, entity in ipairs(class) do
            if entity and not entity.alive then
                entity:onDeath(false)
                table.remove(class, index)
            end
        end
    end

    for i, entity in ipairs(getEntities("monster")) do
            entity:wallCheck(dt)
    end

    for i, class in pairs(entities) do
        for i, entity in ipairs(class) do
            entity:verlet(dt)
        end
    end
end

function addEntity(entity)

    if not entities[entity.stats.class] then entities[entity.stats.class] = {} end
    table.insert(entities[entity.stats.class], entity)
    entity:onStart()

end

function getClosestEntity(entity, class, factionFilter)

    local close = nil
    local dist = -1

    if not entities[class] then return nil end

    for i, oEntity in ipairs(entities[class]) do
        if oEntity == entity then
        elseif factionMatch(oEntity.stats.faction, factionFilter) then
            local newDist = entity:centerDist(oEntity)
            if (newDist < dist) or (not close) then
                close = oEntity
                dist = newDist
            end
        end
    end

    return close, dist

end

function getEntityCount(class, faction)

    local count = 0

    for i, entity in pairs(getEntities(class)) do
        if entity.stats.faction == faction then
            count = count + 1
        end
    end

    return count

end

function factionMatch(faction, filter)

    if faction == filter or not filter or filter == "*" then
        return true
    elseif filter:sub(1, 1) == "!" and filter ~= ("!" .. faction) then
        return true
    else
        return false
    end

end

--Table of entity functions
entityFunctions = {

    onStart = function(self)

        for i, script in pairs(self.actions) do
            script:onStart(self)
        end

    end,

    onUpdate = function(self, dt)

        if self.animation.hurtTimer > 0 then self.animation.hurtTimer = self.animation.hurtTimer - dt end
        if self.animation.hitTimer > 0 then self.animation.hitTimer = self.animation.hitTimer - dt end

        for i, script in pairs(self.actions) do
            script.onUpdate(script, self, dt)
        end

    end,

    onDeath = function(self, isRoomEnd)

        for i, script in pairs(self.actions) do
            script:onDeath(self, isRoomEnd)
        end

    end,

    --Safe wfx to set the position
    setPos = function(self, x, y)

        self.body.private.x, self.body.private.oldX = x, x
        self.body.private.y, self.body.private.oldY = y, y

        self.ai.hold.x, self.ai.hold.y = x, y

    end,

    --Safe wfx to set the position
    getPos = function(self)

        return {x = self.body.private.x, y = self.body.private.y}

    end,

    --Safe wfx to set the velocity
    setVelocity = function(self, vx, vy)

        self.body.private.oldX = self.body.private.x - vx
        self.body.private.oldY = self.body.private.y - vy

    end,

     --Safe wfx to add the velocity
    addVelocity = function(self, vx, vy)

        self.body.private.oldX = self.body.private.oldX - vx
        self.body.private.oldY = self.body.private.oldY - vy

    end,

    applyForce = function(self, fx, fy)

        self.body.private.fx = self.body.private.fx + fx
        self.body.private.fy = self.body.private.fy + fy

    end,

    clearForces = function(self)

        self.body.private.fx , self.body.private.fy = 0, 0;

    end,

    --A single round of velocity verlet integration
    verlet = function(self, dt)

        dt = dt * PIXELS_TO_METERS

        local tempX, tempY = self.body.private.x, self.body.private.y

        -- leapfrog
        self.body.private.x = self.body.private.x + (self.body.private.x  - self.body.private.oldX) * (1 - self.body.drag) + self.body.private.fx * dt * dt / self.body.mass
        self.body.private.y = self.body.private.y + (self.body.private.y - self.body.private.oldY) * (1 - self.body.drag) + self.body.private.fy * dt * dt / self.body.mass

        self.body.private.oldX, self.body.private.oldY = tempX, tempY

        -- wipe forces
        self:clearForces()

    end,

    isColliding = function(self, oEntity)

        if self == oEntity or not self.body.solid or not oEntity.body.solid then
            return false
        end

        return self:centerDist(oEntity) <= self.body.radius + oEntity.body.radius

    end,

    centerDist = function(self, oEntity)

        return self:dist(oEntity.body.private.x, oEntity.body.private.y)

    end,

    dist = function(self, x, y)

        return math.sqrt((self:x() - x)^2 + (self:y() - y)^2)

    end,

    isWithinAggro = function(self, entity)
        return entity:dist(self.ai.hold.x, self.ai.hold.y) <= self.ai.aggroDist
    end,

    -- Move both entities to a point where they are not intersecting.
    -- Don't call this unless they are colliding
    evacuate = function(self, o)

        if self == o then
            return
        end

        if self:x() == o:x() and self:y() == o:y() then
            self.body.private.x = self:x() + 1
        end

        local dist = self:centerDist(o)
        local penDist = self.body.radius + o.body.radius - dist

        --find the evac normal for self
        local exNorm = (self.body.private.x - o.body.private.x) / dist
        local eyNorm = (self.body.private.y - o.body.private.y) / dist

        --apply to self
        local myDisp = o.body.mass  / (self.body.mass + o.body.mass)
        self.body.private.x = self.body.private.x + exNorm * penDist * myDisp
        self.body.private.y = self.body.private.y + eyNorm * penDist * myDisp

        --apply to o
        myDisp = self.body.mass  / (self.body.mass + o.body.mass)
        o.body.private.x = o.body.private.x - exNorm * penDist * myDisp
        o.body.private.y = o.body.private.y - eyNorm * penDist * myDisp

        self:addVelocity(-exNorm * penDist * myDisp, -eyNorm * penDist * myDisp)
        o:addVelocity(exNorm * penDist * myDisp, eyNorm * penDist * myDisp)

    end,

    -- move the entity out all the walls
    wallCheck = function(self)

        if not self.body.solid then return end

        for _, wallTuple in ipairs(wall_list) do
            local e = self:boundingBox();
            local w = boundingBoxTile(wallTuple.x-1, wallTuple.y-1)
            if isCollidingBox(e, w) then
                --left
                local bestDiff = {x = -1, y = 0}
                local bestScale = e.right - w.left
                local tScale = 0
                --right
                tScale = w.right - e.left
                if tScale >= 0 and tScale < bestScale then bestScale, bestDiff = tScale, {x = 1, y = 0} end
                --up
                tScale = e.bottom - w.top
                if tScale >= 0 and tScale < bestScale then bestScale, bestDiff = tScale, {x = 0, y = -1} end
                --down
                tScale = w.bottom - e.top
                if tScale >= 0 and tScale < bestScale then bestScale, bestDiff = tScale, {x = 0, y = 1} end
                --evac
                self.body.private.x = self.body.private.x  + (bestDiff.x) * bestScale * 1.1
                self.body.private.y = self.body.private.y + (bestDiff.y) * bestScale * 1.1
            end
        end

    end,

    addAction = function(self, script)

        self.actions[#self.actions + 1] = script

    end,

    draw = function(self)

        love.graphics.rectangle("line", self.body.private.x - self.body.radius,
                                        self.body.private.y - self.body.radius,
                                        self.body.radius * 2,
                                        self.body.radius * 2)

    end,

    drawDiagnostic = function(self)

        drawHealthBar(self.stats.health, self.stats.maxHealth, self.body.private.x - 25/2, self.body.private.y - self.body.radius - 5, 25)

    end,

    moveTowardPointPathfind = function(self, x, y, speed, targetStationary)

        local source_x = math.floor(self:x() / map_to_real)
        local source_y = math.floor(self:y() / map_to_real)
        local target_x = math.floor(x / map_to_real)
        local target_y = math.floor(y / map_to_real)

        --path should be recalculated
        if not self.path or
                self.target_x ~= target_x or self.target_y ~= target_y or 
                (not targetStationary and (self.source_x ~= source_x or self.source_y ~= source_y)) then
            self.path = find_path({source_x, source_y}, {target_x, target_y})
            self.target_x, self.target_y = target_x, target_y
            self.source_x, self.source_y = source_x, source_y
        end

        if self.path and self.path[2] then
            if source_x == self.path[2][1] and source_y == self.path[2][2] then
                table.remove(self.path, 1)
            else
                x = self.path[2][1] * map_to_real + map_to_real / 2
                y = self.path[2][2] * map_to_real + map_to_real / 2
            end
        end

        self:moveTowardPoint(x, y, speed)

    end,

    moveTowardPoint = function (self, x, y, speed)
        local unitVect = getUnit(x - self.body.private.x,
                                 y - self.body.private.y)
        scaleVect(unitVect, speed)
        self:setVelocity(unitVect.x, unitVect.y)

        if unitVect.x < 0 then
            self.body.private.facing = -1
        else
            self.body.private.facing = 1
        end
    end,

    hurt = function(self, oEntity, damage)

        oEntity.animation.hurtTimer = 1
        self.animation.hitTimer = .75
        local hurtHit = getUnit(
            oEntity.body.private.x - self.body.private.x,
            oEntity.body.private.y - self.body.private.y)
        scaleVect(hurtHit, 2)
        oEntity:addVelocity(hurtHit.x, hurtHit.y)
        oEntity:addVelocity(hurtHit.x * -.1, hurtHit.y * -.1)
        oEntity.stats.health = oEntity.stats.health - damage

        FloatingMessage(damage, oEntity.body.private.x, oEntity.body.private.y - oEntity.body.radius)

    end,

    heal = function(self, amount)

        self.stats.health = math.min(self.stats.maxHealth, self.stats.health + amount)
        FloatingMessage(amount, self.body.private.x, self.body.private.y - self.body.radius, {r = 0, g = 0, b = 255, a = 255})

    end,

    boundingBox = function(self)

        local b = {}
        b.top = self.body.private.y - self.body.radius
        b.bottom = self.body.private.y + self.body.radius
        b.right = self.body.private.x + self.body.radius
        b.left = self.body.private.x - self.body.radius
        return b

    end,

    x = function(self)
        return self.body.private.x
    end,

    y = function(self)
        return self.body.private.y
    end

}

-- Manufacture a new entity and link the function table for speed.
function Entity(class, faction)

    if not class then class = "NONE" end
    if not faction then faction = "NONE" end

    --instance data
    local entity = buildObject(entityFunctions)

    entity.body = {

        radius = 10,

        mass = 1,
        drag = .04, -- |0 -> 1|
        solid = true,

        private = {
            oldX = 0,
            oldY = 0,
            x = 0,
            y = 0,
            fx = 0,
            fy = 0,
            facing = 1
        }
    }

    entity.stats = {

        name = "NO_NAME",
        faction = faction,
        health = 10,
        maxHealth = 10,
        attack = 1,
        armor = 0,
        class = class,
        cooldown = 3,
        speed = 1,
        unitType = ""

    }

    entity.animation = {

        hurtTimer = 0,
        hitTimer = 0

    }

    entity.goals = {}
    entity.actions = {}
    entity.inventory = {}
    entity.alive = true

    entity.ai = {

        aggroDist = 300,
        hold = {x = 0, y = 0}

    }

    return entity
end

function Script()
    return {
        onStart = function(self, entity) end,
        onUpdate = function(self, entity, dt) end,
        onDeath = function(self, entity, isRoomEnd) end
    }
end

function FloatingMessage(message, x, y, color)

    if not color then color = {r = 255, g = 0, b = 0, a = 255} end

    local time = 1

    local ent = Entity("message")

    ent:addAction({

        onStart = function(self, entity)

            self.time = 0
            entity:setPos(x, y)

        end,

        onUpdate = function(self, entity, dt)

            entity:setVelocity(0, -1)

            self.time = self.time + dt

            if self.time > time then
                entity.alive = false
            end

        end,

        onDeath = function(self, entity, isRoomEnd) end

    })

    ent.draw = function(self)

        love.graphics.setColor(color.r, color.g, color.b, color.a)
        love.graphics.print(message, self.body.private.x, self.body.private.y)

    end

    ent.body.solid = false

    addEntity(ent)

end

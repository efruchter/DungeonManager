require "entity"
require "aiPrefab"
require "map"

drawSprite = love.graphics.draw

melee_sprite = {
    image = love.graphics.newImage("images/enemy.png"),
    image2 = love.graphics.newImage("images/enemy2.png"),
    dim = {x = 32, y = 32}
}

copernicus_sprite = {
    image = love.graphics.newImage("images/cop.png"),
    image2 = love.graphics.newImage("images/cop2.png"),
    dim = {x = 600, y = 600}
}

wizard_sprite = {
    image = love.graphics.newImage("images/wizard.png"),
    image2 = love.graphics.newImage("images/wizard2.png"),
    dim = {x = 32, y = 32}
}

cleric_sprite = {
    image = love.graphics.newImage("images/cleric.png"),
    image2 = love.graphics.newImage("images/cleric2.png"),
    dim = {x = 32, y = 32}
}

dieAction = {

     onStart = function(self, entity) end,

     onUpdate = function(self, entity, dt)
        if entity.stats.health <= 0 then
            entity.alive = false
        end
     end,

     onDeath = function(self, entity, isRoomEnd) end

}

prettyDeathAction = {

    onStart = function(self, entity) end,

    onUpdate = function(self, entity, dt) end,

    onDeath = function(self, entity, isRoomEnd)
        local radius = entity.body.radius
        if entity.body.drawRadius then
            radius = entity.body.drawRadius
        end
        makeExplosions( radius * 2,
                        entity.body.private.x,
                        entity.body.private.y,
                        1)

    end

}

drawSpriteStandard = function(self)

    setColor( 255, 255, 255, 255)

    local anim = math.sin((self:x() + self:y()) / 2)

    local radius = self.body.radius
    if self.body.drawRadius then radius = self.body.drawRadius end

    drawSprite(
        anim < 0 and self.animation.sprites.image or self.animation.sprites.image2,
        self.body.private.x,
        self.body.private.y,
        0,
        radius * 2 / self.animation.sprites.dim.x * self.body.private.facing,
        radius * 2 / self.animation.sprites.dim.y,
        self.animation.sprites.dim.x / 2,
        self.animation.sprites.dim.y / 2)

end

function Minion_Melee()

    local monster = Entity("monster", "player")

    monster:addAction(MELEE_AI)
    monster:addAction(dieAction)
    monster:addAction(prettyDeathAction)

    monster.animation.sprites = melee_sprite
    monster.unitType = "minion"
    monster.draw = drawSpriteStandard

    monster.body.radius = 10

    monster.stats.health = 10
    monster.stats.maxHealth = 10
    monster.stats.attack = .5

    monster.ai.aggroDist = 100

    monster.stats.speed = 1

    return monster

end

function Copernicus()

    local monster = Entity("monster", "human")

    monster:addAction(COPERNICUS_ACTION)
    monster:addAction(dieAction)
    monster:addAction(prettyDeathAction)

    monster.animation.sprites = cop_sprite

    monster.draw = drawSpriteStandard

    monster.body.radius = map_to_real / 3
    monster.body.drawRadius = map_to_real

    monster.stats.health = 20 * 1.25
    monster.stats.maxHealth = monster.stats.health
    monster.stats.attack = 1.2
    monster.ai.aggroDist = 300
    monster.stats.speed = 2
    monster.stats.unitType = "copernicus"
    monster.animation.sprites = copernicus_sprite

    return monster

end

function Minion_Wizard(isCleric)

    local monster = Entity("monster", "player")

    monster.stats.isCleric = isCleric

    monster:addAction(dieAction)
    monster:addAction(prettyDeathAction)

    monster:addAction(WIZARD_ACTION)

    if isCleric then
        monster.animation.sprites = cleric_sprite
        monster.stats.unitType = "cleric"
    else
        monster.animation.sprites = wizard_sprite
        monster.stats.unitType = "wizard"
    end

    monster.draw = drawSpriteStandard

    monster.body.radius = 15

    monster.stats.cooldown = .5

    monster.ai.aggroDist = 175

    monster.stats.speed = .50

    return monster

end

function makeWizardShot(target, damage, spawnX, spawnY, heals)

    local particleEntity = Entity("projectile", "player")

    local rad = 10

    local action = {

        onStart = function(self, entity)

            entity:setPos(spawnX, spawnY)

        end,

        onUpdate = function(self, entity, dt)

            if target.alive then
                entity:moveTowardPoint(target:x(), target:y(), 3)
            else
                entity.alive = false
            end

            if entity:isColliding(target) then
                if not heals then
                    entity:hurt(target, damage)
                else
                    target:heal(damage)
                end
                entity.alive = false
            end

        end,

        onDeath = function(self, entity, isRoomEnd)

        end

    }

    particleEntity.draw = function(self)

        if heals then
            love.graphics.setColor(math.random() * 255 / 2, math.random() * 255 / 2, 255, 255)
            love.graphics.circle("line", self.body.private.x - rad / 2, self.body.private.y - rad / 2, rad)
        else
            love.graphics.setColor(math.random() * 255, math.random() * 255, math.random() * 255, 255)
            love.graphics.circle("line", self.body.private.x - rad / 2, self.body.private.y - rad / 2, rad, 3 + math.random() * 2)
        end

    end

    particleEntity:addAction(action)

    particleEntity:addAction({

        onStart = function(self, entity) end,

        onUpdate = function(self, entity, dt) end,

        onDeath = function(self, entity, isRoomEnd)

            makeExplosions( entity.body.radius * 2,
                            entity.body.private.x,
                            entity.body.private.y,
                            1,
                            heals)

        end

    })

    particleEntity:setPos(spawnX - rad, spawnY - rad)

    addEntity(particleEntity)

end

function makeExplosions(size, x, y, max, isHealSplosion)

    if not max then max = 2 end

    for i=0, 10 do

        local particleEntity = Entity("explosion")
        local size = size * math.random()

        local action = {

            onStart = function(self, entity)

                self.timer = max

            end,

            onUpdate = function(self, entity, dt)

                self.timer = self.timer - dt

                if self.timer <= dt then
                    entity.alive = false
                end

            end,

            onDeath = function(self, entity, isRoomEnd) end

        }

        particleEntity.draw = function(self)

            if isHealSplosion then
                love.graphics.setColor(math.random() * 255 / 2, math.random() * 255 / 2, 255, 255 * action.timer / max)
                love.graphics.circle("line", self.body.private.x - size / 2, self.body.private.y - size / 2, size)
            else
                love.graphics.setColor(math.random() * 255, math.random() * 255, math.random() * 255, 255 * action.timer / max)
                love.graphics.rectangle("line", self.body.private.x - size / 2, self.body.private.y - size / 2, size, size)
            end

        end

        particleEntity:addAction(action)

        particleEntity:setPos(x, y)

        particleEntity:setVelocity((-.5 + math.random()) * 2, (-.5 + math.random()) * 2)

        particleEntity.body.solid = false

        addEntity(particleEntity)

    end

end

function Tile_DamageTrap(damage, targetFaction)

    local trap = Entity("tile", "player")

    if damage then trap.stats.attack = damage end

    trap:addAction({

        onStart = function(self, entity) end,

        onUpdate = function(self, entity, dt)

            local target = getClosestEntity(entity, "monster", targetFaction)
            if target and entity:isColliding(target) then
                entity:hurt(target, entity.stats.attack)
                entity.alive = false
            end

        end,

        onDeath = function(self, entity, isRoomEnd) end

    })

    trap.draw = function(self)

        love.graphics.setColor(math.random() * 255, 0, 0, math.random() * .50 * 255)
        love.graphics.circle("fill", self:x(),
                                    self:y(),
                                    self.body.radius, 8)

    end

    trap:addAction(prettyDeathAction)

    trap.body.radius = map_to_real / 2

    return trap

end
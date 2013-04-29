MELEE_AI = {

    onStart = function(self, entity)

    end,

    onUpdate = function(self, entity, dt)

        if entity.animation.hitTimer <= 0 then

            local closeEntity, dist = getClosestEntity(entity, "monster", "!" .. entity.stats.faction)

            if closeEntity and entity:isWithinAggro(closeEntity) then

                entity:moveTowardPoint(closeEntity:x(), closeEntity:y(), entity.stats.speed)

            elseif entity:dist(entity.ai.hold.x, entity.ai.hold.y) > map_to_real then

                entity:moveTowardPoint(entity.ai.hold.x, entity.ai.hold.y, entity.stats.speed)

            end

        end

        for i, otherEntity in ipairs(entities["monster"]) do

            if (entity:isColliding(otherEntity)) then

                entity:evacuate(otherEntity)

                if entity.stats.faction ~= otherEntity.stats.faction then

                    entity:hurt(otherEntity, entity.stats.attack)

                end

            end

        end

    end,

    onDeath = function(self, entity, isRoomEnd) end

}

COPERNICUS_ACTION = {

    onStart = function(self, entity)
        humanBorn()
        self.exploreList = getExploreListCopy()
    end,

    onUpdate = function(self, entity, dt)

        --entity.ai.hold.x, entity.ai.hold.y = entity.body.private.x, entity.body.private.y

        if entity.animation.hitTimer <= 0 then

            --local closeEntity, dist = getClosestEntity(entity, "monster", "!" .. entity.stats.faction)
            local closeEntity, dist = nil, 0
            local targetScore = -10000
            
            for _,ally in pairs(getEntities("monster")) do
                if ally.stats.faction ~= entity.stats.faction and entity:isWithinAggro(ally) and entity ~= ally then
                    if not closeEntity then
                      closeEntity = ally
                    else
                      local tempScore = ally.stats.maxHealth / ally.stats.health
                      tempScore = tempScore - entity:centerDist(ally) / 5
                      if ally.stats.unitType == "wizard" then
                        tempScore = tempScore + 15
                      elseif ally.stats.unitType == "cleric" then
                        tempScore = tempScore + 20
                      end
                      
                      if tempScore > targetScore then
                        closeEntity = ally
                        targetScore = tempScore
                      end
                    end
                end
            end

            if closeEntity and entity:isWithinAggro(closeEntity) then

                entity:moveTowardPointPathfind(closeEntity:x(), closeEntity:y(), entity.stats.speed)

            else

                if entity:dist(entity.ai.hold.x, entity.ai.hold.y) > map_to_real then

                    entity:moveTowardPointPathfind(entity.ai.hold.x, entity.ai.hold.y, entity.stats.speed, true)

                end

                local goal = getClosestExploreGoal(entity, self.exploreList)

                if goal then
                    if entity:dist(goal.x, goal.y) < entity.body.radius * 3 then
                        removeExploreGoal(goal, self.exploreList)
                    else
                        entity.ai.hold.x, entity.ai.hold.y = goal.x, goal.y
                    end
                end

            end

        end

        for i, otherEntity in ipairs(entities["monster"]) do

            if (entity:isColliding(otherEntity)) then

                entity:evacuate(otherEntity)

                if entity.stats.faction ~= otherEntity.stats.faction then

                    entity:hurt(otherEntity, entity.stats.attack)

                end

            end

        end

    end,

    onDeath = function(self, entity, isRoomEnd)
        humanDead()
    end

}

WIZARD_ACTION = {

    onStart = function(self, entity)

        self.cooldown = 0

    end,

    onUpdate = function(self, entity, dt)

        if self.cooldown >= entity.stats.cooldown then

            self.cooldown = 0

        else

            self.cooldown = self.cooldown + dt

        end

        if entity.animation.hitTimer <= 0 then

            local targetFaction = entity.stats.isCleric and entity.stats.faction or ("!" .. entity.stats.faction)

            local closeEntity, dist = nil, 0
            if self.cooldown <= 0 and state == WAVE_STATE then
                local health = -1
                for _,ally in pairs(getEntities("monster")) do
                    if factionMatch(ally.stats.faction, targetFaction)
                        and entity:isWithinAggro(ally) and entity ~= ally then
                        if not closeEntity or ally.stats.health < health then
                            closeEntity, health = ally, ally.stats.health
                        end
                    end
                end
                if closeEntity then
                    makeWizardShot(closeEntity, entity.stats.attack,
                            entity.body.private.x,
                            entity.body.private.y,
                            entity.stats.isCleric)
                end
            end
            if entity:dist(entity.ai.hold.x, entity.ai.hold.y) > map_to_real then
                entity:moveTowardPoint(entity.ai.hold.x, entity.ai.hold.y, entity.stats.speed)
            end
        end
    end,

    onDeath = function(self, entity, isRoomEnd) end

}
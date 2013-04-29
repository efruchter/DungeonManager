function drawHealthBar(health, max, x, y, length)

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", x, y, length, length / 10)

    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.rectangle("fill", x, y, length * (health/max), length / 10)

    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("line", x, y, length, length / 10)

end

function drawAggro(entity)

    love.graphics.setColor(255, 0, 0, 10)
    love.graphics.circle("fill", entity.ai.hold.x, entity.ai.hold.y, entity.ai.aggroDist)

end

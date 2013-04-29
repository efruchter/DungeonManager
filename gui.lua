gui_height = 50
gui_top = 600 - gui_height
gui_width = 800

stats = {
    gold = 50,
    wave = 0,
    
}

gameOverSprite = love.graphics.newImage("images/gameover.jpg")

function drawGui()

    local w = 0

    if state == LOSE_STATE then
        love.graphics.draw(gameOverSprite, 0, 0)
    elseif state == PLACEMENT_STATE then

        love.graphics.print("Press ENTER to start wave", 200, 20)

        love.graphics.setColor(255, 255, 255, 200)
        love.graphics.rectangle("fill", 0, gui_top, gui_width, gui_height)

        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle("line", 0, gui_top, gui_width, gui_height)

        love.graphics.setColor(0, 0, 0, 255)

        w = w + 10

        love.graphics.print("Gold: " .. stats.gold, w, gui_top + 5)
        love.graphics.print("Wave: " .. stats.wave, w, gui_top + 25)

        w = w + 100

        love.graphics.print("Place Units:", w, gui_top + 5)
        love.graphics.print("a: Melee $" .. MELEE_PRICE, w, gui_top + 20)
        love.graphics.print("s: Wizard $" .. WIZARD_PRICE, w, gui_top + 35)
        w = w + 100
        love.graphics.print("d: Cleric $" .. CLERIC_PRICE, w, gui_top + 5)
        love.graphics.print("f: Trap $" .. TRAP_PRICE, w, gui_top + 20)

        w = w + 100
        love.graphics.print("SPACE: Build Room $" .. ROOM_PRICE, w, gui_top + 5)

        if mapmod_buildmode then
            love.graphics.print("SPACE TO LAY BLOCK", 400, 300)
        end
    end
end

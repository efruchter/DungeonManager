function init_demo()

    local base_x = 40 * map_to_real
    local base_y = 40 * map_to_real

    local ent1 = Minion_Melee()
    local ent2 = Minion_Melee()
    local ent3 = Minion_Wizard(true)
    local ent4 = Minion_Melee()
    local ent5 = Minion_Wizard()

    local trapTile = Tile_DamageTrap(100)
    trapTile:setPos(base_x + 300, base_y + 300)
    addEntity(trapTile)

    addEntity(ent1)
    addEntity(ent2)
    addEntity(ent3)
    addEntity(ent4)
    addEntity(ent5)

    ent1:setPos(base_x + 150, base_y + 104)
    ent2:setPos(base_x + 170, base_y + 130)
    ent3:setPos(base_x + 200, base_y + 160)
    ent4:setPos(base_x + 20,  base_y + 200)
    ent5:setPos(base_x + 100, base_y + 180)

    ent3.stats.attack = 100

end

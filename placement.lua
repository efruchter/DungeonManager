MELEE_PRICE = 10
WIZARD_PRICE = 50
CLERIC_PRICE = 75
TRAP_PRICE = 100

HUMAN_BOUNTY = 50
ROOM_PRICE = 100

function placement_keypress(key, unicode)
    local ent

    local x, y = camera_cell()
    if map[y][x] ~= MAP_FLOOR_TILE then return end

    local xReal, yReal = x * map_to_real - map_to_real / 2, y * map_to_real - map_to_real / 2

    if key == "a" and stats.gold >= MELEE_PRICE then
        ent = Minion_Melee()
        payGold(MELEE_PRICE)
        FloatingMessage("$" .. MELEE_PRICE, xReal, yReal)
    elseif key == "s" and stats.gold >= WIZARD_PRICE then
        ent = Minion_Wizard()
        payGold(WIZARD_PRICE)
        FloatingMessage("$" .. WIZARD_PRICE, xReal, yReal)
    elseif key == "d" and stats.gold >= CLERIC_PRICE then
        ent = Minion_Wizard(true)
        payGold(CLERIC_PRICE)
        FloatingMessage("$" .. CLERIC_PRICE, xReal, yReal)
    elseif key == "f" and stats.gold >= TRAP_PRICE then
       ent = Tile_DamageTrap(50, "human")
       payGold(TRAP_PRICE)
       FloatingMessage("$" .. TRAP_PRICE, xReal, yReal)
    else
        return
    end

    ent:setPos(x * map_to_real - map_to_real / 2, y * map_to_real - map_to_real / 2)
    addEntity(ent)
end

function payGold(price)
    stats.gold = stats.gold - price
end

function clamp(n, low, high) return math.min(math.max(n, low), high) end

function buildObject(baseClass)
    local newObj = {};
    local class_mt = { __index = newObj }
    function newObj:create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end
    setmetatable( newObj, { __index = baseClass } )
    return newObj
end

function getUnit(x1, y1)
    local mag = math.sqrt(x1 * x1 + y1 * y1)
    if mag == 0 then
        return {x = 0, y = 0}
    else
        return {x = x1 / mag, y = y1 / mag}
    end
end

function scaleVect(vect, scalar)
    vect.x = vect.x * scalar
    vect.y = vect.y * scalar
end

function isCollidingBox(coordBox1, coordBox2)
    return not (coordBox2.left > coordBox1.right or
       coordBox2.right < coordBox1.left or
       coordBox2.top > coordBox1.bottom or
       coordBox2.bottom < coordBox1.top)
end
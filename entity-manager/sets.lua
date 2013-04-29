--[[
This will maintain a basic concept of a set, which is searchable for values and can insert new 
values.
--]]

-- This is a basic set implementation for coordinates, which is not optimized.
Set = {
  _data = {},
  _size = 0,
  _name = ''
}

-- Does the set contain the coordinates provided.
function Set:contains(x, y)
  for i = 1, self._size do
    local vector = self._data[i]
    if vector[1] == x and vector[2] == y then return true end
  end
  
  return false
end

function Set:get(x, y)
  for i = 1, self._size do
    local val = self._data[i]
    
    if val == nil then error(self._name .. ': ' .. i .. ' ' .. self._size) end
    
    if val[1] == x and val[2] == y then return val end
  end
  
  return nil
end

-- Insert a coordinate into the set.
function Set:insert(x, y, g)
  self._size = self._size + 1 -- NOTE indexes start at 1.
  self._data[self._size] = {x, y, g}
  
  if x == nil then error('The ' .. self._name .. ' set has a nil x value') end
  if y == nil then error('The ' .. self._name .. ' set has a nil y value') end
  if g == nil then error('The ' .. self._name .. ' set has a nil g value') end
end

-- Is the set completely empty.
function Set:is_empty()
  if self._size == 0 then
    return true
  end
  
  return false
end

-- This method should be used only to find the smallest value. The smalles value in this case is
-- to find the coordinate where the combined vector from the source to the target is the smallest
-- out of the other values.
function Set:pop()
  if self._size <= 0 then
    return nil
  end
  
  local min_val = self._data[1]
  local min_i = 1
  
  for i = 1, self._size do
    local d = self._data[i]
    
    if d[3] < min_val[3] then
      min_val = d
      min_i = i
    end
  end
  
  for i = min_i, self._size do
    self._data[i] = self._data[i + 1]
  end

  self._size = self._size - 1
  return min_val
end

function Set:size()
  return self._size
end

function Set:new(name)
  o = {
    _data = {},
    _size = 0,
    _name = name
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

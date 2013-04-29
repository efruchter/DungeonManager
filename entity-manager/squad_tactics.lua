--[[
  For those units where there are multiple entities generated, for instance a squad of bees, and
  instead of path finding for each individual unit, it would be better to treat them as a collective
  group and then make minimal individual decisions.
  
  To maintain squad based tactics, the entities are provided to a function to calculate the
  necessary information, as well as store within the entities information.
--]]


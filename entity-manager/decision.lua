--[[
  To decide where the hero should go will be done in this file. This will be included in the main
  entity package, to let the decision for what the entity should do. Should it explore rooms to
  find some more gold. Should the entity just go straight to the boss. Should the entity patrol to
  find where the hero's are. Should the hero rejoin with the group.
  
  Heroes have distinctly different tactics. They are meant to be smart, while the minions are
  generally pretty stupid. Also the goals are very different.
  
  Heroes want to kill the boss, and steal as much treasure as possible.
  
  Minions want to kill heroes, and protect the treasures.
--]]

-- With the knowledge of the entity that this is for, it will decide what the target location should
-- be for the entity. This should be called by the path finding.
--
-- This goal also needs to react to changes in the environment. If there is a change in goal, then
-- the goal returned should reflect this. If the goal has not changed since the last time that the
-- path finder has called it, then return false (as in nothing's changed).
function determine_goal()

end

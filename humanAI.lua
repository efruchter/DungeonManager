exploreGoals = {}

function getClosestExploreGoal(human, list)
    local closestGoal, dist = nil, 0
    local index = -1
    for i,goal in pairs(list) do
        local d = human:dist(goal.x, goal.y)
        if not closestGoal or d < dist then
            closestGoal, dist = goal, d
            index = i
        end
    end
    return closestGoal
end

function getExploreListCopy()
    local li = {}
    for _,goal in pairs(exploreGoals) do
        table.insert(li, goal)
    end
    return li
end

function removeExploreGoal(goalPoint, list)
    for i, goal in pairs(list) do
        if goalPoint.x == goal.x and goalPoint.y == goal.y then
            table.remove(list, i)
            return
        end
    end
end

function addExploreGoal(goalPoint)
    table.insert(exploreGoals, goalPoint)
end
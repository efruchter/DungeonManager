-- Sets test

require("sets")
require("luaunit")

set1 = Set:new()
set1:insert(0, 0, 0)
assert(set1:contains(0, 0))

set2 = Set:new()
set2:insert(0, 0, 7)
set2:insert(1, 1, 2)
set2:insert(2, 2, 4)
assertEquals(set2:size(), 3)

val = set2:pop()
assertEquals(set2:size(), 2)
assertEquals(val[3], 2)

val = set2:get(2, 2)
val[3] = 8
assertEquals(set2:get(2, 2)[3], 8)

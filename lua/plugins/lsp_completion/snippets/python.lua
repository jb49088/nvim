local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        "fruits",
        fmt(
            'fruits = ["{}", "{}", "{}", "{}", "{}"]',
            { i(1, "apple"), i(2, "banana"), i(3, "orange"), i(4, "grape"), i(5, "cherry") }
        )
    ),
}

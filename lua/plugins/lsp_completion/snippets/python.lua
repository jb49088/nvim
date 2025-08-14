local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    -- Workaround for LuaSnip overlapping prefix bug
    -- These override the inconsistent friendly-snippets behavior
    s({ trig = "##", priority = 2000 }, {
        t('"""'),
        i(0),
        t('"""'),
    }),
    s({ trig = "#", priority = 1000 }, {
        t('"""'),
        i(0),
        t('\n"""'),
    }),
    -- learning snippets
    s(
        "fruits",
        t({
            "fruits: list[str] = [",
            '    "apple",',
            '    "banana",',
            '    "orange",',
            '    "grape",',
            '    "strawberry",',
            "]",
        })
    ),
    s(
        "colors",
        t({
            "colors: tuple[str, ...] = (",
            '    "red",',
            '    "blue",',
            '    "green",',
            '    "yellow",',
            '    "purple",',
            ")",
        })
    ),
    s(
        "products",
        t({
            "products: dict[str, int] = {",
            '    "laptop": 999,',
            '    "mouse": 25,',
            '    "keyboard": 75,',
            '    "monitor": 250,',
            '    "headphones": 150,',
            "}",
        })
    ),
    s(
        "languages",
        t({
            "languages: set[str] = {",
            '    "python",',
            '    "javascript",',
            '    "rust",',
            '    "go",',
            '    "java",',
            "}",
        })
    ),
    s(
        "users",
        t({
            "users: list[dict[str, str | int]] = [",
            '    {"name": "alice", "age": 25},',
            '    {"name": "bob", "age": 30},',
            '    {"name": "charlie", "age": 22},',
            "]",
        })
    ),
    s("numbers", t("numbers: list[int] = [1, 5, 3, 9, 2, 8, 4, 7, 6]")),
    s(
        "cities",
        t({
            "cities: dict[str, dict[str, str | int]] = {",
            '    "toronto": {',
            '        "country": "canada",',
            '        "population": 3_025_647,',
            '        "fact": "toronto is canadas largest city",',
            "    },",
            '    "london": {',
            '        "country": "united kingdom",',
            '        "population": 8_954_146,',
            '        "fact": "london has the oldest subway in the world",',
            "    },",
            '    "moscow": {',
            '        "country": "russia",',
            '        "population": 13_456_186,',
            '        "fact": "most populous city in europe",',
            "    },",
            "}",
        })
    ),
}

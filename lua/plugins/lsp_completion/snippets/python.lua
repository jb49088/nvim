local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require("luasnip.extras.fmt").fmt

-- stylua: ignore
return {
    -- learning snippets
    s("list", t('fruits: list[str] = ["apple", "banana", "orange", "grape", "strawberry"]')),
    s("tuple", t('colors: tuple[str, ...] = ("red", "blue", "green", "yellow", "purple")')),
    s("dict", t('products: dict[str, int] = {"laptop": 999, "mouse": 25, "keyboard": 75, "monitor": 250, "headphones": 150}')),
    s("set", t('languages: set[str] = {"python", "javascript", "rust", "go", "java"}')),
    s("nested", t('users: list[dict[str, str | int]] = [{"name": "alice", "age": 25}, {"name": "bob", "age": 30}, {"name": "charlie", "age": 22}]')),
    s("nums", t('numbers: list[int] = [1, 5, 3, 9, 2, 8, 4, 7, 6]')),
}

local config = {
    games = {
        {dir="game",            name="Default"},
        {dir="game_dom",        name="Dream of Mine"},
        {dir="game_antiruin",   name="Oracle"},
        {dir="game_tower",      name="Tower"},
    },
    -- Default game to load
    defaultGame = "Tower",
    -- If loader is true, show the games present on the disc
    loader = false,
    -- Path for lackages, libraries. The require function.
    reqPath = ";lua/?.lua" .. ";lua/lib/?.lua",
    -- Fullscreen option for love2d
    fullscreen = true,
}

return config
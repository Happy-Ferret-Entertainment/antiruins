local config = {
    games = {
        {dir="game",            name="Default"},
        {dir="game_dom",        name="Dream of Mine"},
        {dir="game_antiruin",   name="Oracle"},
        {dir="game_tower",      name="Gravenhal"},
    },
    -- Default game to load
    defaultGame = "Default",
    -- If loader is true, show the games present on the disc
    loader = false,
    -- Path for lackages, libraries. The require function.
    -- Don't forget to add a semicolom at the end. ' ; '
    reqPath = "lua/?.lua;" .. "lua/lib/?.lua;",
    -- Fullscreen option for love2d
    fullscreen = false,
}

return config
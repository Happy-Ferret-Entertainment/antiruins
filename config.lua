local config = {
    games = {
        {dir="game",            name="Default Game"},
        {dir="game_dom",        name="Dream of Mine"},
        {dir="game_antiruin",   name="Antiruins"},
    },
    -- Default game to load
    defaultGame = "Antiruins",
    -- If loader is true, show the games present on the disc
    loader = false,
    -- Path for lackages, libraries. The require function.
    reqPath = ";lua/?.lua" .. ";lua/lib/?.lua"
}

return config
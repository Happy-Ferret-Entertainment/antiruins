local config = {
    games = {
        {dir="game_example",        name="Example"},
    },
    defaultGame = "Example",
    
    -- If loader is true, show the games present on the disc
    loader = false,
    
    -- Path for lackages, libraries. The require function.
    -- Don't forget to add a semicolom at the end. ' ; '
    reqPath = "lua/?.lua;" .. "lua/lib/?.lua;",
    
}

return config
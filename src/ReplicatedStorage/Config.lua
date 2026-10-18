-- Product IDs belong to YOUR experience. Leave zero until configured and tested.
return {
    Title = "LOCKBREAK ISLAND",
    Subtitle = "A fictional celebrity jailbreak",
    PlayerRole = "Andrew Tate",
    FictionNotice = "Fictional parody. Invented events; no claim about real people.",
    StudioPersistence = false,
    StoreName = "LockbreakProfiles_v2",
    RankingName = "LockbreakEscapes_v2",
    LeaseSeconds = 180,
    SaveInterval = 45,
    BaseReward = 150,
    RescueReward = 75,
    ScrapReward = 100,
    RadioReward = 80,
    Cast = {
        { Id = "financier", Name = "Jeffrey Epstein", Cell = "C-01" },
        { Id = "mogul", Name = "Diddy", Cell = "C-02" },
    },
    SkinOrder = { "Intake", "Midnight", "Arctic", "Neon", "Gold" },
    Skins = {
        Intake = { Name = "Intake orange", Price = 0, RGB = { 230, 112, 43 } },
        Midnight = { Name = "Midnight runner", Price = 250, RGB = { 50, 57, 84 } },
        Arctic = { Name = "Arctic escape", Price = 500, RGB = { 190, 225, 236 } },
        Neon = { Name = "Neon ghost", Price = 850, RGB = { 51, 215, 174 } },
        Gold = { Name = "Gold standard", Price = 1400, RGB = { 239, 193, 80 } },
    },
    UpgradeOrder = { "Sprint", "Stamina", "Stealth" },
    Upgrades = {
        Sprint = { Name = "Sprint speed", Description = "+2 sprint speed per level", Prices = { 150, 350, 700 }, Max = 3 },
        Stamina = { Name = "Endurance", Description = "+20 stamina per level", Prices = { 150, 350, 700 }, Max = 3 },
        Stealth = { Name = "Quiet footsteps", Description = "Slower police detection per level", Prices = { 200, 450, 900 }, Max = 3 },
    },
    Passes = { VIP = { Id = 0, Name = "VIP gold trail", Description = "Permanent gold trail and VIP nameplate" } },
    Products = {
        Cash500 = { Id = 0, Credits = 500, Name = "500 cash" },
        Cash1500 = { Id = 0, Credits = 1500, Name = "1,500 cash" },
    },
}

-- luacheck: ignore 211
local addonName, AddonNamespace = ...

--[[ Known Consumables Database (WoW 3.3.5 - WotLK)
     Pre-cached item IDs for common consumables to reduce tooltip scanning.
     This is a curated list of the most commonly used items - verified for duplicates.
]]
AddonNamespace.KNOWN_CONSUMABLES = {
    -- ========== FOOD (Restores health over time) ==========
    -- Vanilla Food
    [117] = "Food",   -- Tough Jerky
    [414] = "Food",   -- Dalaran Sharp
    [422] = "Food",   -- Dwarven Mild
    [1114] = "Food",  -- Conjured Rye
    [1487] = "Food",  -- Conjured Pumpernickel
    [2070] = "Food",  -- Darnassian Bleu
    [2679] = "Food",  -- Charred Wolf Meat
    [2680] = "Food",  -- Spiced Wolf Meat
    [2681] = "Food",  -- Roasted Boar Meat
    [2682] = "Food",  -- Cooked Crab Claw
    [2683] = "Food",  -- Crab Cake
    [2684] = "Food",  -- Coyote Steak
    [2685] = "Food",  -- Succulent Pork Ribs
    [3220] = "Food",  -- Blood Sausage
    [3662] = "Food",  -- Crocolisk Steak
    [3663] = "Food",  -- Murloc Fin Soup
    [3664] = "Food",  -- Crocolisk Gumbo
    [3665] = "Food",  -- Curiously Tasty Omelet
    [3666] = "Food",  -- Gooey Spider Cake
    [3726] = "Food",  -- Big Bear Steak
    [3727] = "Food",  -- Hot Lion Chops
    [3728] = "Food",  -- Tasty Lion Steak
    [3729] = "Food",  -- Soothing Turtle Bisque
    [4536] = "Food",  -- Shiny Red Apple
    [4537] = "Food",  -- Tel'Abim Banana
    [4538] = "Food",  -- Snapvine Watermelon
    [4539] = "Food",  -- Goldenbark Apple
    [4540] = "Food",  -- Tough Hunk of Bread
    [4541] = "Food",  -- Freshly Baked Bread
    [4542] = "Food",  -- Moist Cornbread
    [4544] = "Food",  -- Mulgore Spice Bread
    [4599] = "Food",  -- Cured Ham Steak
    [5057] = "Food",  -- Ripe Watermelon
    [5349] = "Food",  -- Conjured Muffin
    [5472] = "Food",  -- Kaldorei Spider Kabob
    [5473] = "Food",  -- Scorpid Surprise
    [5474] = "Food",  -- Roasted Kodo Meat
    [5476] = "Food",  -- Fillet of Frenzy
    [5477] = "Food",  -- Strider Stew
    [5478] = "Food",  -- Dig Rat Stew
    [5479] = "Food",  -- Crispy Lizard Tail
    [6290] = "Food",  -- Brilliant Smallfish
    [6316] = "Food",  -- Loch Frenzy Delight
    [6887] = "Food",  -- Spotted Yellowtail
    [8075] = "Food",  -- Conjured Sourdough
    [8076] = "Food",  -- Conjured Sweet Roll
    [8932] = "Food",  -- Alterac Swiss
    [8952] = "Food",  -- Roasted Quail
    [8953] = "Food",  -- Deep Fried Plantains
    [8957] = "Food",  -- Spinefin Halibut
    [12209] = "Food", -- Lean Wolf Steak
    [12210] = "Food", -- Roast Raptor
    [12212] = "Food", -- Jungle Stew
    [13851] = "Food", -- Hot Wolf Ribs
    [13927] = "Food", -- Cooked Glossy Mightfish
    [13928] = "Food", -- Grilled Squid
    [13929] = "Food", -- Hot Smoked Bass
    [13930] = "Food", -- Filet of Redgill
    [13931] = "Food", -- Nightfin Soup
    [13932] = "Food", -- Poached Sunscale Salmon
    [13933] = "Food", -- Lobster Stew
    [13934] = "Food", -- Mightfish Steak
    [18045] = "Food", -- Tender Wolf Steak
    [20074] = "Food", -- Heavy Crocolisk Stew
    [20857] = "Food", -- Honey Bread
    [21023] = "Food", -- Dirge's Kickin' Chimaerok Chops
    [21030] = "Food", -- Conjured Cinnamon Roll
    [22895] = "Food", -- Conjured Croissant

    -- TBC Food
    [27635] = "Food", -- Lynx Steak
    [27651] = "Food", -- Buzzard Bites
    [27655] = "Food", -- Ravager Dog
    [27657] = "Food", -- Blackened Basilisk
    [27658] = "Food", -- Roasted Clefthoof
    [27659] = "Food", -- Warp Burger
    [27660] = "Food", -- Talbuk Steak
    [27661] = "Food", -- Blackened Trout
    [27662] = "Food", -- Feltail Delight
    [27663] = "Food", -- Blackened Sporefish
    [27664] = "Food", -- Grilled Mudfish
    [27665] = "Food", -- Poached Bluefish
    [27666] = "Food", -- Golden Fish Sticks
    [27667] = "Food", -- Spicy Crawdad
    [27854] = "Food", -- Smoked Talbuk Venison
    [27855] = "Food", -- Mag'har Grainbread
    [27856] = "Food", -- Skethyl Berries
    [27857] = "Food", -- Garadar Sharp
    [27858] = "Food", -- Sunspring Carp
    [27859] = "Food", -- Zangar Caps
    [29448] = "Food", -- Mag'har Mild Cheese
    [29449] = "Food", -- Bladespire Bagel
    [29450] = "Food", -- Telaari Grapes
    [29451] = "Food", -- Clefthoof Ribs
    [30155] = "Food", -- Clam Bar
    [31672] = "Food", -- Mok'Nathal Shortribs
    [32685] = "Food", -- Ogri'la Chicken Fingers

    -- WotLK Food
    [33048] = "Food", -- Stewed Trout
    [33053] = "Food", -- Hot Buttered Trout
    [33825] = "Food", -- Skullfish Soup
    [33866] = "Food", -- Stormchops
    [33867] = "Food", -- Broiled Bloodfin
    [33872] = "Food", -- Spicy Blue Nettlefish
    [34747] = "Food", -- Northern Stew
    [34748] = "Food", -- Mammoth Meal
    [34749] = "Food", -- Shoveltusk Steak
    [34750] = "Food", -- Worm Delight
    [34751] = "Food", -- Roasted Worg
    [34752] = "Food", -- Rhino Dogs
    [34753] = "Food", -- Great Feast
    [34754] = "Food", -- Mega Mammoth Meal
    [34755] = "Food", -- Tender Shoveltusk Steak
    [34756] = "Food", -- Spiced Worm Burger
    [34757] = "Food", -- Very Burnt Worg
    [34758] = "Food", -- Mighty Rhino Dogs
    [34759] = "Food", -- Smoked Rockfin
    [34760] = "Food", -- Grilled Bonescale
    [34761] = "Food", -- Sauteed Goby
    [34762] = "Food", -- Grilled Sculpin
    [34763] = "Food", -- Smoked Salmon
    [34764] = "Food", -- Poached Nettlefish
    [34765] = "Food", -- Pickled Fangtooth
    [34766] = "Food", -- Poached Northern Sculpin
    [34767] = "Food", -- Firecracker Salmon
    [34768] = "Food", -- Spicy Blue Nettlefish
    [34769] = "Food", -- Imperial Manta Steak
    [35947] = "Food", -- Sparkling Frostcap
    [35948] = "Food", -- Savory Snowplum
    [35949] = "Food", -- Tundra Berries
    [35950] = "Food", -- Sweet Potato Bread
    [35951] = "Food", -- Poached Emperor Salmon
    [35952] = "Food", -- Briny Hardcheese
    [35953] = "Food", -- Mead Basted Caribou
    [42777] = "Food", -- Crusader's Rations
    [42778] = "Food", -- Bountiful Feast
    [42942] = "Food", -- Baked Manta Ray
    [42993] = "Food", -- Spicy Fried Herring
    [42994] = "Food", -- Rhinolicious Wormsteak
    [42995] = "Food", -- Hearty Rhino
    [42996] = "Food", -- Snapper Extreme
    [42997] = "Food", -- Blackened Worg Steak
    [42998] = "Food", -- Cuttlesteak
    [42999] = "Food", -- Blackened Dragonfin
    [43000] = "Food", -- Dragonfin Filet
    [43015] = "Food", -- Fish Feast
    [43268] = "Food", -- Dalaran Brownie
    [43478] = "Food", -- Gigantic Feast
    [43480] = "Food", -- Small Feast
    [44953] = "Food", -- Worg Tartare

    -- ========== DRINKS (Restores mana over time) ==========
    -- Vanilla Drinks
    [159] = "Drink",   -- Refreshing Spring Water
    [1179] = "Drink",  -- Ice Cold Milk
    [1205] = "Drink",  -- Melon Juice
    [1645] = "Drink",  -- Moonberry Juice
    [1708] = "Drink",  -- Sweet Nectar
    [2288] = "Drink",  -- Conjured Fresh Water
    [2593] = "Drink",  -- Flask of Port
    [2594] = "Drink",  -- Flask of Stormwind Tawny
    [2723] = "Drink",  -- Bottle of Pinot Noir
    [2894] = "Drink",  -- Rhapsody Malt
    [3772] = "Drink",  -- Conjured Spring Water
    [4791] = "Drink",  -- Enchanted Water
    [5350] = "Drink",  -- Conjured Water
    [8077] = "Drink",  -- Conjured Mineral Water
    [8078] = "Drink",  -- Conjured Sparkling Water
    [8079] = "Drink",  -- Conjured Crystal Water
    [8766] = "Drink",  -- Morning Glory Dew
    [18300] = "Drink", -- Hyjal Nectar
    [19299] = "Drink", -- Fizzy Faire Drink
    [19300] = "Drink", -- Bottled Winterspring Water
    [21151] = "Drink", -- Rumsey Rum Black Label
    [22018] = "Drink", -- Conjured Glacier Water

    -- TBC Drinks
    [27860] = "Drink", -- Purified Draenic Water
    [28399] = "Drink", -- Filtered Draenic Water
    [29395] = "Drink", -- Ethermead
    [29401] = "Drink", -- Sparkling Southshore Cider
    [30703] = "Drink", -- Conjured Mountain Spring Water
    [32453] = "Drink", -- Star's Tears
    [32455] = "Drink", -- Star's Lament

    -- WotLK Drinks
    [33042] = "Drink", -- Black Coffee
    [33444] = "Drink", -- Pungent Seal Whey
    [33445] = "Drink", -- Honeymint Tea
    [35954] = "Drink", -- Sweetened Goat's Milk
    [43518] = "Drink", -- Conjured Mana Pie
    [43523] = "Drink", -- Conjured Mana Strudel
    [44941] = "Drink", -- Fresh-Squeezed Limeade
    [46755] = "Drink", -- Conjured Mana Cake

    -- ========== HEALTH POTIONS (Instant health restore) ==========
    [118] = "Health",   -- Minor Healing Potion
    [858] = "Health",   -- Lesser Healing Potion
    [929] = "Health",   -- Healing Potion
    [1710] = "Health",  -- Greater Healing Potion
    [3928] = "Health",  -- Superior Healing Potion
    [13446] = "Health", -- Major Healing Potion
    [18839] = "Health", -- Combat Healing Potion
    [22829] = "Health", -- Super Healing Potion
    [28100] = "Health", -- Volatile Healing Potion
    [31677] = "Health", -- Fel Blossom
    [31838] = "Health", -- Major Combat Healing Potion
    [33092] = "Health", -- Healing Potion Injector
    [33447] = "Health", -- Runic Healing Potion
    [39671] = "Health", -- Resurgent Healing Potion
    [40067] = "Health", -- Iced Berry Slush
    [40077] = "Health", -- Crazy Alchemist's Potion
    [41166] = "Health", -- Runic Healing Injector
    [43569] = "Health", -- Endless Healing Potion

    -- ========== MANA POTIONS (Instant mana restore) ==========
    [2455] = "Mana",  -- Minor Mana Potion
    [3385] = "Mana",  -- Lesser Mana Potion
    [3827] = "Mana",  -- Mana Potion
    [6149] = "Mana",  -- Greater Mana Potion
    [13443] = "Mana", -- Superior Mana Potion
    [13444] = "Mana", -- Major Mana Potion
    [18841] = "Mana", -- Combat Mana Potion
    [22832] = "Mana", -- Super Mana Potion
    [28101] = "Mana", -- Unstable Mana Potion
    [31676] = "Mana", -- Fel Mana Potion
    [31839] = "Mana", -- Major Combat Mana Potion
    [33093] = "Mana", -- Mana Potion Injector
    [33448] = "Mana", -- Runic Mana Potion
    [40087] = "Mana", -- Powerful Rejuvenation Potion
    [40211] = "Mana", -- Potion of Speed
    [40212] = "Mana", -- Potion of Wild Magic
    [42545] = "Mana", -- Runic Mana Injector
    [43570] = "Mana", -- Endless Mana Potion
}

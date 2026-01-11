# ConsumableManager (v2.7.0)

**ConsumableManager** is a lightweight World of Warcraft (WotLK 3.3.5) addon designed to simplify the management of food, water, and potions. It automatically scans your bags to find the "best" available consumables based on your level and assigns them to secure action buttons.

## Features
* **Smart Selection**: Automatically identifies the highest-level Food, Drink, Health Potions, and Mana Potions in your bags.
* **Level Awareness**: Only selects items that your character currently meets the level requirement to use.
* **Secure Action Buttons**: Buttons remain functional and updated during combat (attributes updated post-combat if bags change).
* **Customizable Layout**: Toggle between **Grouped** (single anchor) and **Individual** (move buttons freely) modes.
* **Configuration Menu**: Built-in GUI in the Interface Options for easy management of visibility and locking.
* **Keybinding Support**: Full support for native WoW keybindings for all four categories.

## Installation
1. Download the repository.
2. Extract the folder to your `Interface/AddOns/` directory.
3. Ensure the folder name is exactly `ConsumableManager`.
4. Restart World of Warcraft.

## Slash Commands
Use `/cm` to see the status or use the following commands:
* `/cm conf` - Opens the configuration menu.
* `/cm lock` - Toggles frame locking.
* `/cm group` - Switches between Grouped and Individual layout modes.
* `/cm show` / `/cm hide` - Toggles button visibility.
* `/cm reset` - Wipes all settings and reloads the UI.

## Technical Structure
The addon is modularized for performance:
* **Data.lua**: Contains an extensive database of all known WotLK 3.3.5 consumables.
* **ConsumableManager.lua**: Handles the core logic, inventory scanning, and frame management.
* **Bindings.xml**: Defines the secure click bindings for the action buttons.

## Author
* **Achim Finkbeiner**
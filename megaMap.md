### What is MegaMap ###

MegaMap will be the term used to describe the giant worldmap created for a mazecraft game. not to be confused with dungeon maps ;)

### MegaMap Elements ###

| Dungeons | the "maze" areas of the map |
|:---------|:----------------------------|
| Town     | "buying" areas of the map. used to procure items and trade with stores; also a source of missions |
| Forest   | "everywhere else". a fairly open area with random monsters that players move through and explore in order to find the dungeons |


---


Kaisers proposal on MegaMap

i thought i'd record my thoughts and ideas in full here so you guys can comment/pick at it

since we're going to be making a large pre-made map with smaller cells containing dungeons and towns; why not break the entire map into cells with different "themes" or "biomes"? would make it interesting for players (albiet annoying to program?)

that way, on missions, you might not be going to a dungeon etc, but another destination... "go to x graveyard and kill y unit, and return to z for your reward" where y is a generate monster on mission start and z is a NPC that will give a "collect bounty" chat option on mission end

if we had a "tile map" with "themed areas" then we could start small (just dungeons and forest to begin with) but then add other things/zones later

-graveyard
-swamp
-ruins
-other towns / merchants
-hermits
-Institute bases
-fast travel portals
-radioactive zones

possible pseudocode:

1) create 32x32 array

2) place dungeons and starting town first; mark these cells as "taken" in the array

3) pick a random "untaken" cell. check adjacent cells for "taken". if they are taken, check type. randomly choose a "type" for the cell... 50% chance is will be the same as a taken adjacent cell (unless its main town or dungeon) and 50% chance it will be an unrelated type.

4) repeat until all cells are typed

5) use this 32x32 array as a basis for generating the more complicated "block" based map

advantages?
- allows for very interesting and varied terrain for players to explore other than dungeons
- modular (if we decide we need other zones, the blocks could be created and added to the overall algorithm)

notes
- if most "themed" zones are not blocked in the same manner as mazes, they will not impede travel as much and will create interesting features
- blocks can be somewhat shared across zones... for instance, tree blocks could be used in most zones, wheras a crypt block might only occur in a graveyard zone
- each cel of the 32x32 could be named on generation; that way if you get a mission to go to the "forest of effeminate elves" and you've visited it before then it will be easier to find your way back
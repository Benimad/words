/// Themed vocabulary that feeds the level generator.
///
/// Every list is original, common-English vocabulary — nothing here is taken
/// from another product's content. Rules each list follows:
///
///  * 3-11 letters, A-Z only (no spaces, hyphens or accents).
///  * At least 18 entries per theme, so the generator always has surplus
///    candidates when a word refuses to fit.
///  * A spread of lengths: short words keep small early boards solvable, long
///    words give late boards their bite.
library;

/// One theme: a display name plus its vocabulary.
class WordTheme {
  const WordTheme(this.name, this.words);
  final String name;
  final List<String> words;
}

/// All themes, grouped by the world that uses them.
abstract final class WordBanks {
  // ===== World 1 — Verdant Vale (forests, meadows, growing things) =========
  static const verdantVale = <WordTheme>[
    WordTheme('Forest Animals', [
      'FOX', 'OWL', 'DEER', 'WOLF', 'BEAR', 'HARE', 'LYNX', 'MOOSE',
      'BADGER', 'BEAVER', 'RABBIT', 'SQUIRREL', 'RACCOON', 'OTTER',
      'HEDGEHOG', 'MARTEN', 'WEASEL', 'BOBCAT', 'ELK', 'BISON',
      'CHIPMUNK', 'PORCUPINE',
    ]),
    WordTheme('Trees & Leaves', [
      'OAK', 'ELM', 'ASH', 'FIR', 'PINE', 'BIRCH', 'MAPLE', 'CEDAR',
      'WILLOW', 'ASPEN', 'POPLAR', 'SPRUCE', 'WALNUT', 'CHESTNUT',
      'BRANCH', 'CANOPY', 'TRUNK', 'BARK', 'ROOT', 'ACORN', 'SAPLING',
      'FOLIAGE',
    ]),
    WordTheme('Wildflowers', [
      'ROSE', 'IRIS', 'LILY', 'POPPY', 'TULIP', 'DAISY', 'VIOLET',
      'ORCHID', 'PETUNIA', 'JASMINE', 'LAVENDER', 'SUNFLOWER', 'PETAL',
      'BLOOM', 'NECTAR', 'POLLEN', 'STEM', 'BUD', 'BLOSSOM', 'MEADOW',
      'CLOVER', 'THISTLE',
    ]),
    WordTheme('Insects', [
      'BEE', 'ANT', 'MOTH', 'WASP', 'FLY', 'BEETLE', 'CRICKET',
      'FIREFLY', 'LADYBUG', 'MANTIS', 'HORNET', 'APHID', 'TERMITE',
      'BUTTERFLY', 'DRAGONFLY', 'CATERPILLAR', 'LARVA', 'ANTENNA',
      'HIVE', 'SWARM', 'COCOON', 'WEEVIL',
    ]),
    WordTheme('Songbirds', [
      'JAY', 'WREN', 'FINCH', 'ROBIN', 'RAVEN', 'CROW', 'SPARROW',
      'SWALLOW', 'STARLING', 'MAGPIE', 'ORIOLE', 'CANARY', 'THRUSH',
      'WARBLER', 'CUCKOO', 'NIGHTINGALE', 'FEATHER', 'NEST', 'BEAK',
      'PLUMAGE', 'PERCH', 'MIGRATE',
    ]),
    WordTheme('Woodland Paths', [
      'TRAIL', 'GROVE', 'GLADE', 'FERN', 'MOSS', 'BRAMBLE', 'THICKET',
      'HOLLOW', 'CLEARING', 'STREAM', 'PEBBLE', 'BOULDER', 'RIDGE',
      'VALLEY', 'MEADOW', 'SHADE', 'DAPPLED', 'LANTERN', 'COMPASS',
      'RAMBLE', 'WANDER', 'TRACK',
    ]),
    WordTheme('Mushrooms & Moss', [
      'CAP', 'SPORE', 'FUNGUS', 'MOREL', 'TRUFFLE', 'LICHEN', 'MOSS',
      'DAMP', 'SHADED', 'CLUSTER', 'STALK', 'GILLS', 'ROTTEN', 'LOG',
      'FOREST', 'FORAGE', 'BASKET', 'EARTHY', 'MYCELIUM', 'VELVET',
      'CANOPY', 'HUMUS',
    ]),
    WordTheme('Garden Life', [
      'SEED', 'SOIL', 'HOSE', 'RAKE', 'SPADE', 'TROWEL', 'COMPOST',
      'SPROUT', 'HARVEST', 'TOMATO', 'CARROT', 'LETTUCE', 'PUMPKIN',
      'HERBS', 'MULCH', 'PRUNE', 'TRELLIS', 'GREENHOUSE', 'WATERING',
      'PLANTER', 'ORCHARD', 'BEDS',
    ]),
  ];

  // ===== World 2 — Coral Coast (oceans, shores, sailing) ===================
  static const coralCoast = <WordTheme>[
    WordTheme('Ocean Creatures', [
      'EEL', 'COD', 'RAY', 'CRAB', 'SEAL', 'TUNA', 'SHARK', 'WHALE',
      'SQUID', 'CORAL', 'OCTOPUS', 'DOLPHIN', 'LOBSTER', 'JELLYFISH',
      'SEAHORSE', 'STINGRAY', 'URCHIN', 'PLANKTON', 'MANATEE',
      'BARNACLE', 'CLAM', 'OYSTER',
    ]),
    WordTheme('On The Beach', [
      'SAND', 'DUNE', 'SHELL', 'WAVE', 'TIDE', 'SURF', 'TOWEL',
      'UMBRELLA', 'SUNSET', 'PEBBLE', 'DRIFTWOOD', 'SEAWEED',
      'LAGOON', 'COVE', 'PIER', 'BOARDWALK', 'SANDCASTLE', 'BUCKET',
      'SEAGULL', 'HORIZON', 'BREEZE', 'SUNSCREEN',
    ]),
    WordTheme('Sailing & Ships', [
      'MAST', 'SAIL', 'HULL', 'DECK', 'ANCHOR', 'RUDDER', 'HARBOR',
      'VOYAGE', 'CAPTAIN', 'COMPASS', 'GALLEY', 'SCHOONER', 'YACHT',
      'FERRY', 'CARGO', 'PORT', 'STARBOARD', 'KNOT', 'BUOY', 'CREW',
      'LIGHTHOUSE', 'MARINA',
    ]),
    WordTheme('Coral Reef', [
      'REEF', 'POLYP', 'ANEMONE', 'SPONGE', 'LAGOON', 'ATOLL',
      'SNORKEL', 'DIVER', 'CURRENT', 'SHALLOW', 'VIVID', 'CORAL',
      'FRAGILE', 'HABITAT', 'COLONY', 'TROPICAL', 'CLOWNFISH',
      'PARROTFISH', 'ANGELFISH', 'SEAGRASS', 'TIDEPOOL', 'MARINE',
    ]),
    WordTheme('Weather At Sea', [
      'FOG', 'MIST', 'GALE', 'STORM', 'SQUALL', 'CALM', 'SWELL',
      'BREEZE', 'THUNDER', 'DRIZZLE', 'HUMID', 'CLOUD', 'RAINBOW',
      'MONSOON', 'TYPHOON', 'PRESSURE', 'FORECAST', 'DOWNPOUR',
      'LIGHTNING', 'HORIZON', 'DRIFT', 'CHOPPY',
    ]),
    WordTheme('Deep Blue', [
      'ABYSS', 'TRENCH', 'DEPTH', 'PRESSURE', 'SONAR', 'SUBMARINE',
      'DARKNESS', 'GLOWING', 'ANGLER', 'VENT', 'CANYON', 'SEABED',
      'SEDIMENT', 'EXPLORE', 'VESSEL', 'CRUSH', 'FROZEN', 'SILENT',
      'MYSTERY', 'FATHOM', 'CHASM', 'BIOLUMINESCENT',
    ]),
    WordTheme('Island Life', [
      'PALM', 'HUT', 'CANOE', 'MANGO', 'COCONUT', 'BAMBOO', 'HAMMOCK',
      'VOLCANO', 'JUNGLE', 'PARADISE', 'ISLAND', 'TROPIC', 'BREEZY',
      'LAGOON', 'PADDLE', 'FISHING', 'MARKET', 'SUNRISE', 'BONFIRE',
      'SHORELINE', 'CASTAWAY', 'REEF',
    ]),
    WordTheme('Water Sports', [
      'SWIM', 'DIVE', 'SURF', 'ROW', 'KAYAK', 'SAILING', 'RAFTING',
      'PADDLE', 'WETSUIT', 'FLIPPER', 'GOGGLES', 'SNORKEL', 'BOARD',
      'WAVES', 'BALANCE', 'CURRENT', 'RESCUE', 'FLOAT', 'SPLASH',
      'REGATTA', 'LIFEGUARD', 'BUOYANT',
    ]),
  ];

  // ===== World 3 — Ember Dunes (deserts, heat, spice, markets) =============
  static const emberDunes = <WordTheme>[
    WordTheme('Desert Life', [
      'DUNE', 'OASIS', 'CAMEL', 'CACTUS', 'MIRAGE', 'SCORPION',
      'LIZARD', 'GECKO', 'VULTURE', 'JACKAL', 'SANDSTORM', 'ARID',
      'DROUGHT', 'NOMAD', 'CARAVAN', 'DUSTY', 'BARREN', 'SHADE',
      'CANYON', 'PLATEAU', 'SCORCH', 'HORIZON',
    ]),
    WordTheme('Spices & Herbs', [
      'SALT', 'MINT', 'SAGE', 'BASIL', 'CUMIN', 'CLOVE', 'PEPPER',
      'GINGER', 'NUTMEG', 'SAFFRON', 'PAPRIKA', 'TURMERIC',
      'CINNAMON', 'OREGANO', 'PARSLEY', 'THYME', 'CARDAMOM',
      'VANILLA', 'CHILI', 'ANISE', 'ROSEMARY', 'FENNEL',
    ]),
    WordTheme('Bazaar & Trade', [
      'STALL', 'COIN', 'SILK', 'RUG', 'BARTER', 'MERCHANT', 'LANTERN',
      'POTTERY', 'CRAFT', 'WEAVER', 'BRASS', 'INCENSE', 'TEAPOT',
      'MARKET', 'HAGGLE', 'CARPET', 'JEWEL', 'AMBER', 'TRINKET',
      'CARAVAN', 'SPICES', 'TREASURE',
    ]),
    WordTheme('Rocks & Minerals', [
      'ORE', 'GEM', 'QUARTZ', 'GRANITE', 'MARBLE', 'SLATE', 'BASALT',
      'GYPSUM', 'CRYSTAL', 'AMBER', 'JASPER', 'OPAL', 'TOPAZ',
      'GARNET', 'OBSIDIAN', 'LIMESTONE', 'SANDSTONE', 'MINERAL',
      'FOSSIL', 'GEODE', 'PYRITE', 'STRATA',
    ]),
    WordTheme('Heat & Fire', [
      'EMBER', 'FLAME', 'BLAZE', 'SPARK', 'SMOKE', 'ASH', 'COAL',
      'TORCH', 'BONFIRE', 'FURNACE', 'SCORCH', 'SIZZLE', 'GLOW',
      'KINDLE', 'IGNITE', 'LANTERN', 'BEACON', 'CINDER', 'FLICKER',
      'CAMPFIRE', 'SMOULDER', 'RADIANT',
    ]),
    WordTheme('Ancient Ruins', [
      'TOMB', 'RELIC', 'PILLAR', 'TEMPLE', 'STATUE', 'CARVING',
      'SCROLL', 'PYRAMID', 'SPHINX', 'CHAMBER', 'CRYPT', 'MOSAIC',
      'ARCHWAY', 'RUBBLE', 'EXCAVATE', 'ARTIFACT', 'DYNASTY',
      'INSCRIPTION', 'BURIED', 'LEGEND', 'ANCIENT', 'CATACOMB',
    ]),
    WordTheme('Desert Journey', [
      'MAP', 'TREK', 'CANTEEN', 'SADDLE', 'ROUTE', 'DISTANCE',
      'SUPPLIES', 'SHELTER', 'STARS', 'NAVIGATE', 'ENDURE',
      'BLISTER', 'RATION', 'SUNRISE', 'RESTING', 'JOURNEY',
      'GUIDE', 'TENT', 'DUSK', 'FOOTPRINT', 'PATIENCE', 'THIRST',
    ]),
    WordTheme('Warm Colours', [
      'RED', 'GOLD', 'RUST', 'AMBER', 'CORAL', 'PEACH', 'BRONZE',
      'COPPER', 'SIENNA', 'CRIMSON', 'SCARLET', 'MAROON', 'OCHRE',
      'SUNSET', 'TERRACOTTA', 'BLUSH', 'APRICOT', 'HONEY', 'FLAME',
      'GINGER', 'SAND', 'CLAY',
    ]),
  ];

  // ===== World 4 — Frostpeak Hollow (mountains, snow, winter) ==============
  static const frostpeak = <WordTheme>[
    WordTheme('Winter Wonders', [
      'ICE', 'SNOW', 'FROST', 'SLEET', 'CHILL', 'FLURRY', 'ICICLE',
      'BLIZZARD', 'SNOWFLAKE', 'GLACIER', 'FREEZE', 'MITTEN',
      'SCARF', 'SHIVER', 'CRISP', 'THAW', 'DRIFT', 'POWDER',
      'SNOWMAN', 'TOBOGGAN', 'HIBERNATE', 'WINTER',
    ]),
    WordTheme('Mountain Climb', [
      'PEAK', 'RIDGE', 'CLIFF', 'SLOPE', 'SUMMIT', 'ASCENT', 'ROPE',
      'HARNESS', 'CRAMPON', 'ALTITUDE', 'BASECAMP', 'BOULDER',
      'CREVASSE', 'AVALANCHE', 'PLATEAU', 'ALPINE', 'GRANITE',
      'VALLEY', 'TRAVERSE', 'ANCHOR', 'CLIMBER', 'OXYGEN',
    ]),
    WordTheme('Polar Animals', [
      'SEAL', 'ORCA', 'HARE', 'FOX', 'OWL', 'WALRUS', 'PENGUIN',
      'REINDEER', 'CARIBOU', 'NARWHAL', 'PUFFIN', 'ERMINE',
      'LEMMING', 'MUSKOX', 'SNOWY', 'HUSKY', 'BLUBBER', 'BURROW',
      'TUNDRA', 'MIGRATE', 'ARCTIC', 'WOLVERINE',
    ]),
    WordTheme('Cosy Cabin', [
      'FIRE', 'LOGS', 'QUILT', 'COCOA', 'KETTLE', 'BLANKET',
      'HEARTH', 'CANDLE', 'RUSTIC', 'TIMBER', 'PORCH', 'ARMCHAIR',
      'STORIES', 'LANTERN', 'SLIPPERS', 'CHIMNEY', 'WARMTH',
      'SHUTTERS', 'PANTRY', 'FIREWOOD', 'RESTFUL', 'SNUG',
    ]),
    WordTheme('Cold Colours', [
      'BLUE', 'TEAL', 'MINT', 'AQUA', 'AZURE', 'SILVER', 'PEWTER',
      'INDIGO', 'GLACIER', 'PERIWINKLE', 'SLATE', 'STEEL',
      'MIDNIGHT', 'SAPPHIRE', 'TURQUOISE', 'LAVENDER', 'PALE',
      'FROSTED', 'MISTY', 'COBALT', 'CYAN', 'ICY',
    ]),
    WordTheme('Northern Lights', [
      'AURORA', 'GLOW', 'RIBBON', 'SHIMMER', 'CURTAIN', 'SOLAR',
      'PARTICLE', 'MAGNETIC', 'HORIZON', 'SPECTACLE', 'GREEN',
      'VIOLET', 'RADIANT', 'SILENT', 'DANCING', 'NIGHTSKY',
      'LATITUDE', 'OBSERVE', 'WONDER', 'CAMERA', 'PATIENCE',
      'CELESTIAL',
    ]),
    WordTheme('Winter Sports', [
      'SKI', 'SLED', 'SKATE', 'CURLING', 'HOCKEY', 'SNOWBOARD',
      'SLALOM', 'MOGUL', 'HELMET', 'GOGGLES', 'CHAIRLIFT', 'PISTE',
      'BOBSLED', 'BIATHLON', 'RINK', 'GLIDE', 'CARVE', 'POWDER',
      'DOWNHILL', 'MEDAL', 'PODIUM', 'BALANCE',
    ]),
    WordTheme('Frozen Lake', [
      'POND', 'SHEET', 'CRACK', 'RIPPLE', 'MIRROR', 'REFLECT',
      'STILL', 'SILENT', 'DEPTH', 'SURFACE', 'SKATERS', 'BRITTLE',
      'HOLLOW', 'CLEAR', 'REEDS', 'HERON', 'MOONLIGHT', 'SHORELINE',
      'GLASSY', 'FROZEN', 'BENEATH', 'CURRENT',
    ]),
  ];

  // ===== World 5 — Neon Nexus (cities, technology, modern life) ============
  static const neonNexus = <WordTheme>[
    WordTheme('Technology', [
      'APP', 'CHIP', 'CODE', 'DATA', 'WIFI', 'CLOUD', 'SERVER',
      'PIXEL', 'DEVICE', 'LAPTOP', 'BROWSER', 'NETWORK', 'BATTERY',
      'SOFTWARE', 'HARDWARE', 'KEYBOARD', 'MONITOR', 'DIGITAL',
      'ROUTER', 'UPLOAD', 'DOWNLOAD', 'ALGORITHM',
    ]),
    WordTheme('City Streets', [
      'TAXI', 'CURB', 'ALLEY', 'PLAZA', 'AVENUE', 'SUBWAY',
      'TRAFFIC', 'CROSSING', 'SIDEWALK', 'SKYLINE', 'TOWER',
      'BRIDGE', 'MARKET', 'STATION', 'TERMINAL', 'DISTRICT',
      'BOULEVARD', 'LAMPPOST', 'RUSHHOUR', 'COMMUTE', 'BUSTLE',
      'SIGNAL',
    ]),
    WordTheme('Music & Sound', [
      'BASS', 'BEAT', 'NOTE', 'TUNE', 'CHORD', 'TEMPO', 'RHYTHM',
      'MELODY', 'GUITAR', 'PIANO', 'DRUMS', 'VIOLIN', 'CONCERT',
      'STUDIO', 'SPEAKER', 'HEADPHONE', 'PLAYLIST', 'HARMONY',
      'LYRICS', 'ENCORE', 'FESTIVAL', 'AMPLIFIER',
    ]),
    WordTheme('Cinema Night', [
      'FILM', 'REEL', 'SCENE', 'ACTOR', 'SCRIPT', 'CAMERA',
      'DIRECTOR', 'TRAILER', 'SCREEN', 'POPCORN', 'TICKET',
      'PREMIERE', 'MONTAGE', 'DIALOGUE', 'COSTUME', 'LIGHTING',
      'EDITING', 'STUNT', 'SEQUEL', 'STUDIO', 'AUDIENCE', 'CREDITS',
    ]),
    WordTheme('Sports Arena', [
      'GOAL', 'TEAM', 'COACH', 'MATCH', 'SCORE', 'RALLY', 'TENNIS',
      'SOCCER', 'HOCKEY', 'RUNNER', 'SPRINT', 'MARATHON', 'STADIUM',
      'REFEREE', 'TROPHY', 'DEFENCE', 'OFFENCE', 'WHISTLE',
      'CHAMPION', 'TRAINING', 'PENALTY', 'ATHLETE',
    ]),
    WordTheme('Modern Home', [
      'SOFA', 'LAMP', 'SHELF', 'MIRROR', 'CARPET', 'CURTAIN',
      'KITCHEN', 'BALCONY', 'CUSHION', 'STORAGE', 'CABINET',
      'HALLWAY', 'CEILING', 'DOORWAY', 'FURNITURE', 'PLANTER',
      'ARTWORK', 'MINIMAL', 'COMFORT', 'LIGHTING', 'STUDIO', 'LOFT',
    ]),
    WordTheme('Transport', [
      'BUS', 'CAR', 'BIKE', 'TRAM', 'TRAIN', 'FERRY', 'SCOOTER',
      'SHUTTLE', 'CARRIAGE', 'PLATFORM', 'JOURNEY', 'TICKET',
      'ENGINE', 'WHEELS', 'HELMET', 'ROUTE', 'TRANSIT', 'CYCLING',
      'AIRPORT', 'RUNWAY', 'CARGO', 'DELIVERY',
    ]),
    WordTheme('Neon Nightlife', [
      'GLOW', 'SIGN', 'LIGHT', 'PULSE', 'STROBE', 'VIBRANT',
      'ELECTRIC', 'ARCADE', 'DINER', 'ROOFTOP', 'SKYLINE',
      'REFLECTION', 'PUDDLE', 'MIDNIGHT', 'BUZZING', 'CROWDED',
      'MUSIC', 'LAUGHTER', 'NEON', 'SHIMMER', 'AFTERGLOW', 'DAZZLE',
    ]),
  ];

  // ===== World 6 — Blossom Bay (food, culture, everyday joy) ===============
  static const blossomBay = <WordTheme>[
    WordTheme('Fruit Basket', [
      'FIG', 'PLUM', 'PEAR', 'KIWI', 'LIME', 'MANGO', 'PEACH',
      'GRAPE', 'LEMON', 'MELON', 'CHERRY', 'BANANA', 'ORANGE',
      'APRICOT', 'PAPAYA', 'AVOCADO', 'PINEAPPLE', 'RASPBERRY',
      'STRAWBERRY', 'BLUEBERRY', 'COCONUT', 'NECTARINE',
    ]),
    WordTheme('In The Kitchen', [
      'PAN', 'POT', 'OVEN', 'WHISK', 'LADLE', 'SPATULA', 'KNIFE',
      'BOARD', 'RECIPE', 'SIMMER', 'ROAST', 'KNEAD', 'BAKING',
      'MIXING', 'GRATER', 'BLENDER', 'MEASURE', 'APRON', 'SKILLET',
      'SEASON', 'GARNISH', 'STIRRING',
    ]),
    WordTheme('Bakery', [
      'BUN', 'PIE', 'LOAF', 'CAKE', 'TART', 'SCONE', 'DOUGH',
      'PASTRY', 'MUFFIN', 'BRIOCHE', 'CROISSANT', 'BAGUETTE',
      'CUSTARD', 'FROSTING', 'SPRINKLE', 'YEAST', 'CRUMB', 'GLAZE',
      'COOKIE', 'BROWNIE', 'CINNAMON', 'PRETZEL',
    ]),
    WordTheme('Around The World', [
      'SUSHI', 'PASTA', 'TACO', 'CURRY', 'RAMEN', 'KEBAB',
      'PAELLA', 'RISOTTO', 'FALAFEL', 'DUMPLING', 'NOODLES',
      'TAGINE', 'CEVICHE', 'GOULASH', 'TAPAS', 'GNOCCHI', 'PHO',
      'BIBIMBAP', 'EMPANADA', 'BAKLAVA', 'HUMMUS', 'CHOWDER',
    ]),
    WordTheme('Art Studio', [
      'INK', 'HUE', 'CLAY', 'BRUSH', 'EASEL', 'CANVAS', 'PALETTE',
      'SKETCH', 'SHADING', 'PORTRAIT', 'GALLERY', 'PIGMENT',
      'CHARCOAL', 'PASTEL', 'MURAL', 'COLLAGE', 'TEXTURE',
      'SCULPTURE', 'PATTERN', 'CERAMIC', 'PRINTING', 'STUDIO',
    ]),
    WordTheme('Celebrations', [
      'GIFT', 'CAKE', 'PARTY', 'MUSIC', 'DANCE', 'CANDLE',
      'BALLOON', 'RIBBON', 'CONFETTI', 'PARADE', 'FEAST',
      'LANTERN', 'FIREWORK', 'GATHERING', 'TOASTING', 'LAUGHTER',
      'COSTUME', 'BANNER', 'STREAMER', 'CAROUSEL', 'FESTIVAL',
      'MEMORY',
    ]),
    WordTheme('Reading Corner', [
      'BOOK', 'PAGE', 'NOVEL', 'STORY', 'PLOT', 'CHAPTER',
      'AUTHOR', 'LIBRARY', 'FICTION', 'POETRY', 'BINDING',
      'BOOKMARK', 'PARAGRAPH', 'NARRATOR', 'PROLOGUE', 'ANTHOLOGY',
      'PUBLISH', 'SHELVES', 'READING', 'CLASSIC', 'MEMOIR', 'FABLE',
    ]),
    WordTheme('Everyday Comfort', [
      'TEA', 'MUG', 'NAP', 'CALM', 'QUIET', 'COSY', 'SUNDAY',
      'PILLOW', 'SLIPPER', 'SUNBEAM', 'MORNING', 'BREATHE',
      'UNWIND', 'GENTLE', 'RELAXED', 'PEACEFUL', 'SOFTNESS',
      'STILLNESS', 'CANDLE', 'MELODY', 'WARMTH', 'LEISURE',
    ]),
  ];

  // ===== World 7 — Starfall Rift (space, science, discovery) ===============
  static const starfallRift = <WordTheme>[
    WordTheme('Outer Space', [
      'SUN', 'MOON', 'STAR', 'MARS', 'ORBIT', 'COMET', 'PLANET',
      'GALAXY', 'NEBULA', 'METEOR', 'ECLIPSE', 'JUPITER', 'SATURN',
      'NEPTUNE', 'MERCURY', 'ASTEROID', 'UNIVERSE', 'GRAVITY',
      'COSMIC', 'SATELLITE', 'TELESCOPE', 'CONSTELLATION',
    ]),
    WordTheme('Space Mission', [
      'CREW', 'LAUNCH', 'ROCKET', 'MODULE', 'CAPSULE', 'ORBITER',
      'SHUTTLE', 'DOCKING', 'MISSION', 'CONTROL', 'COUNTDOWN',
      'ASTRONAUT', 'SPACESUIT', 'THRUSTER', 'REENTRY', 'PAYLOAD',
      'LANDING', 'PROBE', 'ROVER', 'ANTENNA', 'TELEMETRY', 'AIRLOCK',
    ]),
    WordTheme('Physics', [
      'ATOM', 'MASS', 'FORCE', 'ENERGY', 'MOTION', 'PHOTON',
      'QUANTUM', 'NEUTRON', 'ELECTRON', 'PARTICLE', 'MAGNETIC',
      'FRICTION', 'VELOCITY', 'PRESSURE', 'DENSITY', 'SPECTRUM',
      'WAVELENGTH', 'INERTIA', 'THERMAL', 'VOLTAGE', 'CIRCUIT',
      'RELATIVITY',
    ]),
    WordTheme('Laboratory', [
      'LAB', 'TEST', 'BEAKER', 'SAMPLE', 'PIPETTE', 'FORMULA',
      'REACTION', 'SOLUTION', 'MIXTURE', 'ELEMENT', 'COMPOUND',
      'RESEARCH', 'ANALYSIS', 'EXPERIMENT', 'MICROSCOPE',
      'HYPOTHESIS', 'CATALYST', 'MOLECULE', 'CENTRIFUGE',
      'SPECIMEN', 'CULTURE', 'PROTOCOL',
    ]),
    WordTheme('Human Body', [
      'RIB', 'LUNG', 'HEART', 'BRAIN', 'NERVE', 'MUSCLE', 'BONE',
      'ARTERY', 'KIDNEY', 'SPINE', 'TISSUE', 'NEURON', 'SKELETON',
      'CIRCULATION', 'IMMUNE', 'ENZYME', 'HORMONE', 'CARTILAGE',
      'REFLEX', 'BALANCE', 'BREATHING', 'GENETICS',
    ]),
    WordTheme('Prehistoric', [
      'FOSSIL', 'AMBER', 'RAPTOR', 'EXTINCT', 'JURASSIC',
      'TRIASSIC', 'CRETACEOUS', 'MAMMOTH', 'DINOSAUR', 'SKELETON',
      'PALEONTOLOGY', 'CLAW', 'SCALES', 'HERBIVORE', 'CARNIVORE',
      'CRATER', 'ERUPTION', 'ANCIENT', 'PRESERVED', 'EXCAVATION',
      'SEDIMENT', 'SPECIES',
    ]),
    WordTheme('Inventions', [
      'WHEEL', 'LEVER', 'ENGINE', 'MOTOR', 'BATTERY', 'COMPASS',
      'PRINTING', 'TELEPHONE', 'RADIO', 'CAMERA', 'VACCINE',
      'ANTIBIOTIC', 'TRANSISTOR', 'COMPUTER', 'INTERNET', 'LASER',
      'ROBOTICS', 'TURBINE', 'PATENT', 'PROTOTYPE', 'BLUEPRINT',
      'INNOVATION',
    ]),
    WordTheme('Cosmic Colours', [
      'VOID', 'DUSK', 'GLOW', 'PRISM', 'AURORA', 'STELLAR',
      'RADIANT', 'INFRARED', 'ULTRAVIOLET', 'SPECTRUM', 'PLASMA',
      'CRIMSON', 'INDIGO', 'SHIMMER', 'LUMINOUS', 'STARDUST',
      'BRILLIANT', 'DAZZLING', 'CELESTIAL', 'TWILIGHT', 'HALO',
      'FLARE',
    ]),
  ];

  // ===== World 8 — Chronicle Keep (history, myth, language) ================
  static const chronicleKeep = <WordTheme>[
    WordTheme('Castles & Knights', [
      'MOAT', 'KEEP', 'TOWER', 'ARMOR', 'SHIELD', 'SWORD', 'LANCE',
      'BANNER', 'KNIGHT', 'SQUIRE', 'CASTLE', 'TURRET', 'DRAWBRIDGE',
      'FORTRESS', 'RAMPART', 'HERALDRY', 'CHIVALRY', 'JOUSTING',
      'CHAINMAIL', 'DUNGEON', 'PARAPET', 'CITADEL',
    ]),
    WordTheme('Myths & Legends', [
      'MYTH', 'HERO', 'QUEST', 'ORACLE', 'DRAGON', 'PHOENIX',
      'GRIFFIN', 'MERMAID', 'TITAN', 'LEGEND', 'PROPHECY',
      'ENCHANTED', 'SORCERER', 'TALISMAN', 'LABYRINTH', 'CHARIOT',
      'IMMORTAL', 'DESTINY', 'RIDDLE', 'CURSE', 'RELIC', 'OMEN',
    ]),
    WordTheme('World Capitals', [
      'ROME', 'OSLO', 'LIMA', 'CAIRO', 'PARIS', 'TOKYO', 'SEOUL',
      'HANOI', 'MADRID', 'ATHENS', 'LISBON', 'VIENNA', 'DUBLIN',
      'HELSINKI', 'BRUSSELS', 'BUDAPEST', 'WARSAW', 'OTTAWA',
      'NAIROBI', 'JAKARTA', 'CANBERRA', 'STOCKHOLM',
    ]),
    WordTheme('Countries', [
      'CHAD', 'PERU', 'CUBA', 'MALI', 'KENYA', 'JAPAN', 'BRAZIL',
      'CANADA', 'FRANCE', 'GREECE', 'NORWAY', 'POLAND', 'MEXICO',
      'ICELAND', 'IRELAND', 'MOROCCO', 'THAILAND', 'PORTUGAL',
      'AUSTRALIA', 'ARGENTINA', 'VIETNAM', 'FINLAND',
    ]),
    WordTheme('Words About Words', [
      'NOUN', 'VERB', 'RHYME', 'CLAUSE', 'PHRASE', 'SYLLABLE',
      'GRAMMAR', 'PREFIX', 'SUFFIX', 'SYNONYM', 'ANTONYM',
      'METAPHOR', 'DIALECT', 'LEXICON', 'ADJECTIVE', 'ADVERB',
      'PRONOUN', 'SENTENCE', 'PARAGRAPH', 'VOCABULARY',
      'ETYMOLOGY', 'LINGUISTIC',
    ]),
    WordTheme('Explorers', [
      'MAP', 'SHIP', 'ROUTE', 'CHART', 'VOYAGE', 'SEXTANT',
      'COMPASS', 'FRONTIER', 'DISCOVERY', 'EXPEDITION', 'NAVIGATE',
      'UNCHARTED', 'PIONEER', 'SETTLEMENT', 'PASSAGE', 'HARBOUR',
      'LONGITUDE', 'LATITUDE', 'JOURNAL', 'CARTOGRAPHY', 'TRADEWIND',
      'ANCHORAGE',
    ]),
    WordTheme('Museums', [
      'ART', 'CASE', 'LABEL', 'CURATOR', 'GALLERY', 'EXHIBIT',
      'ARCHIVE', 'ANTIQUE', 'HERITAGE', 'RESTORE', 'DISPLAY',
      'COLLECTION', 'CATALOGUE', 'DOCENT', 'PRESERVE',
      'ARTIFACT', 'SCULPTURE', 'PORTRAIT', 'MANUSCRIPT', 'PEDESTAL',
      'ROTUNDA', 'ATRIUM',
    ]),
    WordTheme('Grand Finale', [
      'WIN', 'STAR', 'CROWN', 'MEDAL', 'TROPHY', 'MASTERY',
      'SUMMIT', 'LEGEND', 'TRIUMPH', 'VICTORY', 'PINNACLE',
      'CHAMPION', 'ACHIEVE', 'JOURNEY', 'MILESTONE', 'CELEBRATE',
      'ULTIMATE', 'BRILLIANT', 'CONQUERED', 'FAREWELL',
      'CHRONICLE', 'ADVENTURE',
    ]),
  ];

  /// Themes suitable for the Daily Challenge — deliberately mixed so the daily
  /// puzzle feels distinct from the campaign rather than a repeat of it.
  static const daily = <WordTheme>[
    WordTheme('Daily Mix', [
      'PUZZLE', 'DAILY', 'STREAK', 'BONUS', 'REWARD', 'CHALLENGE',
      'SOLVE', 'SEARCH', 'LETTER', 'HIDDEN', 'CLEVER', 'FOCUS',
      'MEMORY', 'PATTERN', 'DISCOVER', 'ATTEMPT', 'PROGRESS',
      'MASTER', 'QUICK', 'THINK', 'RIDDLE', 'BRAIN',
    ]),
    WordTheme('Seasons', [
      'FALL', 'SNOW', 'RAIN', 'SUMMER', 'WINTER', 'SPRING',
      'AUTUMN', 'HARVEST', 'BLOSSOM', 'SUNSHINE', 'BREEZE',
      'FROSTY', 'EQUINOX', 'SOLSTICE', 'MONSOON', 'THAWING',
      'FOLIAGE', 'MIGRATE', 'SEASONAL', 'CLIMATE', 'WEATHER',
      'CYCLE',
    ]),
    WordTheme('Emotions', [
      'JOY', 'CALM', 'HOPE', 'PRIDE', 'DELIGHT', 'WONDER',
      'CURIOUS', 'EXCITED', 'GRATEFUL', 'PEACEFUL', 'CONTENT',
      'CHEERFUL', 'RELIEF', 'COURAGE', 'KINDNESS', 'PATIENCE',
      'SERENITY', 'AMUSED', 'EAGER', 'TENDER', 'WARMTH', 'TRUST',
    ]),
    WordTheme('Animal Kingdom', [
      'CAT', 'DOG', 'BAT', 'LION', 'ZEBRA', 'TIGER', 'PANDA',
      'KOALA', 'CAMEL', 'MONKEY', 'GIRAFFE', 'ELEPHANT',
      'PENGUIN', 'DOLPHIN', 'CHEETAH', 'GORILLA', 'FLAMINGO',
      'KANGAROO', 'LEOPARD', 'RHINO', 'MEERKAT', 'PARROT',
    ]),
    WordTheme('Travel Days', [
      'BAG', 'MAP', 'TRIP', 'HOTEL', 'FLIGHT', 'PASSPORT',
      'LUGGAGE', 'JOURNEY', 'AIRPORT', 'BOOKING', 'TERMINAL',
      'SUITCASE', 'ITINERARY', 'SOUVENIR', 'ADVENTURE',
      'DEPARTURE', 'ARRIVAL', 'TOURIST', 'EXPLORE', 'CULTURE',
      'LANDMARK', 'ROADTRIP',
    ]),
    WordTheme('Colours', [
      'RED', 'BLUE', 'PINK', 'GOLD', 'GREEN', 'AMBER', 'IVORY',
      'CORAL', 'INDIGO', 'VIOLET', 'MAROON', 'SILVER', 'CRIMSON',
      'MAGENTA', 'LAVENDER', 'TURQUOISE', 'CHARCOAL', 'EMERALD',
      'SCARLET', 'MUSTARD', 'BRONZE', 'PEACH',
    ]),
    WordTheme('Weather Watch', [
      'SUN', 'FOG', 'HAIL', 'WIND', 'CLOUD', 'STORM', 'FROST',
      'BREEZE', 'HUMID', 'THUNDER', 'DRIZZLE', 'RAINBOW',
      'SUNSHINE', 'OVERCAST', 'FORECAST', 'PRESSURE',
      'LIGHTNING', 'BLIZZARD', 'DOWNPOUR', 'TEMPERATE',
      'SHOWERS', 'CLIMATE',
    ]),
  ];

  /// Convenience: every campaign theme bank in world order.
  static const List<List<WordTheme>> byWorld = [
    verdantVale,
    coralCoast,
    emberDunes,
    frostpeak,
    neonNexus,
    blossomBay,
    starfallRift,
    chronicleKeep,
  ];
}

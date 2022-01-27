#include "substrate.h"
#include <string>
#include <cstdio>
#include <chrono>
#include <memory>
#include <vector>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/stat.h>
#include <random>
#include <cstdint>
#include <unordered_map>
#include <map>
#include <functional>
#include <cmath>
#include <chrono>
#include <libkern/OSCacheControl.h>
#include <cstddef>
#include <tuple>
#include <mach/mach.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

#include <dlfcn.h>

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

struct TextureUVCoordinateSet;
struct CompoundTag;
struct Material;

enum class MaterialType : int {
	DEFAULT = 0,
	DIRT,
	WOOD,
	STONE,
	METAL,
	WATER,
	LAVA,
	PLANT,
	DECORATION,
	WOOL = 11,
	BED,
	FIRE,
	SAND,
	DEVICE,
	GLASS,
	EXPLOSIVE,
	ICE,
	PACKED_ICE,
	SNOW,
	CACTUS = 22,
	CLAY,
	PORTAL = 25,
	CAKE,
	WEB,
	CIRCUIT,
	LAMP = 30,
	SLIME
};

enum class BlockSoundType : int {
	NORMAL, GRAVEL, WOOD, GRASS, METAL, STONE, CLOTH, GLASS, SAND, SNOW, LADDER, ANVIL, SLIME, SILENT, DEFAULT, UNDEFINED
};

enum class CreativeItemCategory : unsigned char {
	BLOCKS = 1,
	DECORATIONS,
	TOOLS,
	ITEMS
};

struct Block
{
	void** vtable;
	char filler[0x90-8];
	int category;
	char filler2[0x94+0x19+0x90-4];
};

struct Item {
	void** vtable; // 0
	uint8_t maxStackSize; // 8
	int idk; // 12
	std::string atlas; // 16
	int frameCount; // 40
	bool animated; // 44
	short itemId; // 46
	std::string name; // 48
	std::string idk3; // 72
	bool isMirrored; // 96
	short maxDamage; // 98
	bool isGlint; // 100
	bool renderAsTool; // 101
	bool stackedByData; // 102
	uint8_t properties; // 103
	int maxUseDuration; // 104
	bool explodeable; // 108
	bool shouldDespawn; // 109
	bool idk4; // 110
	uint8_t useAnimation; // 111
	int creativeCategory; // 112
	float idk5; // 116
	float idk6; // 120
	char buffer[12]; // 124
	TextureUVCoordinateSet* icon; // 136
	char filler[100];
};

struct BlockItem :public Item {
	char filler[0xB0];
};

struct ItemInstance {
	uint8_t count;
	uint16_t aux;
	CompoundTag* tag;
	Item* item;
	Block* block;
	int idk[3];
};

struct BlockGraphics {
	void** vtable;
	char filler[0x3C0 - 8];
};

namespace Json { class Value; }

Item** Item$mItems;
Block** Block$mBlocks;
BlockGraphics** BlockGraphics$mBlocks;

static std::unordered_map<std::string, Block*>* Block$mBlockLookupMap;

BlockItem*(*BlockItem$BlockItem)(BlockItem*, std::string const&, int);

ItemInstance*(*ItemInstance$ItemInstance)(ItemInstance*, int, int, int);

void(*Item$addCreativeItem)(const ItemInstance&);

Block*(*Block$Block)(Block*, std::string const&, int, Material const&);

Material&(*Material$getMaterial)(MaterialType);

BlockGraphics*(*BlockGraphics$BlockGraphics)(BlockGraphics*, std::string const&);
void(*BlockGraphics$setCarriedTextureItem)(BlockGraphics*, std::string const&, std::string const&, std::string const&);
void(*BlockGraphics$setTextureItem)(BlockGraphics*, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&);

int testItem = 238;
BlockItem* myItemPtr;
Block* myBlockPtr;
BlockGraphics* myBlockGraphicsPtr;

static uintptr_t** VTAppPlatformiOS;

static bool (*_File$exists)(std::string const&);
static bool File$exists(std::string const& path) {
	if(path.find("minecraftpe.app/data/resourcepacks/vanilla/client/textures/blocks/test.png") != std::string::npos)
		return true;

	return _File$exists(path);
}

static std::string (*_AppPlatformiOS$readAssetFile)(uintptr_t*, std::string const&);
static std::string AppPlatformiOS$readAssetFile(uintptr_t* self, std::string const& str) {

    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/blocks/test.png"))
        return _AppPlatformiOS$readAssetFile(self, "/Library/Application Support/addtestblockmod/test.png");

    std::string content = _AppPlatformiOS$readAssetFile(self, str);
    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/terrain_texture.json")) {
        NSString *jsonString = [NSString stringWithUTF8String:content.c_str()];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];

        NSMutableDictionary *jsonTextureData = [jsonDict objectForKey:@"texture_data"];
        [jsonTextureData setObject:@{
            @"textures": @[@"textures/blocks/test"]
        } forKey:@"test"];
       
        jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        content = std::string([jsonString UTF8String]);
    }
    return content;
}

static void (*_Item$initCreativeItems)();
static void Item$initCreativeItems() {
	_Item$initCreativeItems();

	ItemInstance inst;
	ItemInstance$ItemInstance(&inst, testItem, 1, 0);
	Item$addCreativeItem(inst);	
}

static void (*_Item$addBlockItems)();
static void Item$addBlockItems() {
	_Item$addBlockItems();

	myItemPtr = new BlockItem();
	BlockItem$BlockItem(myItemPtr, "testblock", testItem - 0x100);
	Item$mItems[testItem] = myItemPtr;
}

static void (*_Block$initBlocks)();
static void Block$initBlocks() {
	_Block$initBlocks();

	myBlockPtr = new Block();
	Block$Block(myBlockPtr, "testblock", testItem, Material$getMaterial(MaterialType::DEFAULT));
	Block$mBlocks[testItem] = myBlockPtr;
	(*Block$mBlockLookupMap)["testblock"] = myBlockPtr;
	myBlockPtr->category = 1;
}

static void (*_BlockGraphics$initBlocks)();
static void BlockGraphics$initBlocks() {
	_BlockGraphics$initBlocks();

	myBlockGraphicsPtr = new BlockGraphics();
	BlockGraphics$BlockGraphics(myBlockGraphicsPtr, "testblock");
	BlockGraphics$mBlocks[testItem] = myBlockGraphicsPtr;
	BlockGraphics$setCarriedTextureItem(myBlockGraphicsPtr, "test", "test", "test");
	BlockGraphics$setTextureItem(myBlockGraphicsPtr, "test", "test", "test", "test", "test", "test");
}

%ctor {
	VTAppPlatformiOS = (uintptr_t**)(0x1011695f0 + _dyld_get_image_vmaddr_slide(0));
	_AppPlatformiOS$readAssetFile = (std::string(*)(uintptr_t*, std::string const&)) VTAppPlatformiOS[58];
	VTAppPlatformiOS[58] = (uintptr_t*)&AppPlatformiOS$readAssetFile;

	Item$mItems = (Item**)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));
	Block$mBlocks = (Block**)(0x1012d1860 + _dyld_get_image_vmaddr_slide(0));
	BlockGraphics$mBlocks = (BlockGraphics**)(0x10126a100 + _dyld_get_image_vmaddr_slide(0));

	Block$mBlockLookupMap = (std::unordered_map<std::string, Block*>*)(0x1012d2078 + _dyld_get_image_vmaddr_slide(0));

	BlockItem$BlockItem = (BlockItem*(*)(BlockItem*, std::string const&, int))(0x1007281e0 + _dyld_get_image_vmaddr_slide(0));

	ItemInstance$ItemInstance = (ItemInstance*(*)(ItemInstance*, int, int, int))(0x100756c70 + _dyld_get_image_vmaddr_slide(0));

	Item$addCreativeItem = (void(*)(const ItemInstance&))(0x100745f10 + _dyld_get_image_vmaddr_slide(0));

	Block$Block = (Block*(*)(Block*, std::string const&, int, Material const&))(0x1007d7e20 + _dyld_get_image_vmaddr_slide(0));

	Material$getMaterial = (Material&(*)(MaterialType))(0x1008c6e74 + _dyld_get_image_vmaddr_slide(0));

	BlockGraphics$BlockGraphics = (BlockGraphics*(*)(BlockGraphics*, std::string const&))(0x100388338 + _dyld_get_image_vmaddr_slide(0));
	BlockGraphics$setCarriedTextureItem = (void(*)(BlockGraphics*, std::string const&, std::string const&, std::string const&))(0x100382f0c + _dyld_get_image_vmaddr_slide(0));
	BlockGraphics$setTextureItem = (void(*)(BlockGraphics*, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&, std::string const&))(0x1003829c8 + _dyld_get_image_vmaddr_slide(0));

	MSHookFunction((void*)(0x1005316ec + _dyld_get_image_vmaddr_slide(0)), (void*)&File$exists, (void**)&_File$exists);

	MSHookFunction((void*)(0x100734d00 + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$initCreativeItems, (void**)&_Item$initCreativeItems);
	MSHookFunction((void*)(0x100745f6c + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$addBlockItems, (void**)&_Item$addBlockItems);
	MSHookFunction((void*)(0x1007d451c + _dyld_get_image_vmaddr_slide(0)), (void*)&Block$initBlocks, (void**)&_Block$initBlocks);
	MSHookFunction((void*)(0x1003845e0 + _dyld_get_image_vmaddr_slide(0)), (void*)&BlockGraphics$initBlocks, (void**)&_BlockGraphics$initBlocks);
}
//
//  GLLItem.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItem.h"

#import "GLLBoneTransformation.h"
#import "GLLBone.h"
#import "GLLMesh.h"
#import "GLLMeshSettings.h"
#import "GLLModel.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

#pragma mark Private classes

@interface GLLItem_MeshesSourceListMarker : NSObject <GLLSourceListItem>

- (id)initWithItem:(GLLItem *)item;
@property (nonatomic, weak, readonly) GLLItem *item;

@end

@implementation GLLItem_MeshesSourceListMarker

- (id)initWithItem:(GLLItem *)item
{
	if (!(self = [super init])) return nil;
	_item = item;
	return self;
}

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return NSLocalizedString(@"Meshes", @"source list: meshes for items");
}
- (BOOL)hasChildrenInSourceList
{
	return YES;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return self.item.meshSettings.count;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return self.item.meshSettings[index];
}

@end

@interface GLLItem_BonesSourceListMarker : NSObject <GLLSourceListItem>

- (id)initWithItem:(GLLItem *)item;
@property (nonatomic, weak, readonly) GLLItem *item;

@end

@implementation GLLItem_BonesSourceListMarker

- (id)initWithItem:(GLLItem *)item
{
	if (!(self = [super init])) return nil;
	_item = item;
	return self;
}

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return NSLocalizedString(@"Bones", @"source list: bones for items");
}
- (BOOL)hasChildrenInSourceList
{
	return YES;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return self.item.rootBoneTransformations.count;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return self.item.rootBoneTransformations[index];
}

@end

#pragma mark -

@interface GLLItem ()
{
	GLLItem_BonesSourceListMarker *bonesMarker;
	GLLItem_MeshesSourceListMarker *meshesMarker;
}

@end

@implementation GLLItem

@dynamic displayName;
@dynamic itemURLBookmark;
@dynamic scaleX;
@dynamic scaleY;
@dynamic scaleZ;
@dynamic isVisible;
@dynamic boneTransformations;
@dynamic meshSettings;

@dynamic model;
@dynamic itemURL;
@dynamic itemName;
@dynamic itemDirectory;

#pragma mark - Non-standard attributes

- (void)awakeFromFetch
{
	// Item URL
	NSData *bookmarkData = self.itemURLBookmark;
	if (bookmarkData)
	{
		NSURL *itemURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:0 relativeToURL:nil bookmarkDataIsStale:NULL error:NULL];
		[self setPrimitiveValue:itemURL forKey:@"itemURL"];
	}
	
	NSURL *itemURL = self.itemURL;
	if (itemURL)
	{
		GLLModel *model = [GLLModel cachedModelFromFile:itemURL error:NULL];
		[self setPrimitiveValue:model forKey:@"model"];
	}
}

- (void)willSave
{
	GLLModel *model = [self primitiveValueForKey:@"model"];
	NSURL *currentPrimitiveURL = [self primitiveValueForKey:@"itemURL"];
	if (![currentPrimitiveURL isEqual:model.baseURL])
		[self setPrimitiveValue:model.baseURL forKey:@"itemURL"];
	
	NSURL *itemURL = [self primitiveValueForKey:@"itemURL"];
	if (itemURL)
	{
		NSData *bookmark = [itemURL bookmarkDataWithOptions:NSURLBookmarkCreationPreferFileIDResolution includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
		[self setPrimitiveValue:bookmark forKey:@"itemURLBookmark"];
	}
	else
		[self setPrimitiveValue:nil forKey:@"itemURLBookmark"];
}

- (void)setModel:(GLLModel *)model
{
	[self willChangeValueForKey:@"model"];
	[self setPrimitiveValue:model forKey:@"model"];
	[self didChangeValueForKey:@"model"];
	
	// Replace all mesh settings and bone transformations
	// They have appropriate default values, so they need no setting of parameters.
	NSMutableOrderedSet *meshSettings = [self mutableOrderedSetValueForKey:@"meshSettings"];
	[meshSettings removeAllObjects];
	for (NSUInteger i = 0; i < model.meshes.count; i++)
		[meshSettings addObject:[NSEntityDescription insertNewObjectForEntityForName:@"GLLMeshSettings" inManagedObjectContext:self.managedObjectContext]];
	
	NSMutableOrderedSet *boneTransformations = [self mutableOrderedSetValueForKey:@"boneTransformations"];
	[boneTransformations removeAllObjects];
	for (NSUInteger i = 0; i < model.bones.count; i++)
		[boneTransformations addObject:[NSEntityDescription insertNewObjectForEntityForName:@"GLLBoneTransformation" inManagedObjectContext:self.managedObjectContext]];
	
	for (NSString *cameraTargetName in model.cameraTargetNames)
	{
		NSArray *boneNames = [model boneNamesForCameraTarget:cameraTargetName];
		
		NSManagedObject *cameraTarget = [NSEntityDescription insertNewObjectForEntityForName:@"GLLCameraTarget" inManagedObjectContext:self.managedObjectContext];
		[cameraTarget setValue:cameraTargetName forKey:@"name"];
		for (GLLBoneTransformation *transform in boneTransformations)
			if ([boneNames containsObject:transform.bone.name])
				[[cameraTarget mutableSetValueForKey:@"bones"] addObject:transform];
	}
	
	// Display name!
	
	// Get a base name
	NSURL *modelDirectory = [self.model.baseURL URLByDeletingLastPathComponent];
	NSMutableString *basicName = [[NSMutableString alloc] initWithString:modelDirectory.lastPathComponent];
	
	// Remove extensions
	if ([basicName hasSuffix:@".ascii"])
		[basicName deleteCharactersInRange:NSMakeRange(basicName.length - @".ascii".length, @".ascii".length)];
	if ([basicName hasSuffix:@".mesh"])
		[basicName deleteCharactersInRange:NSMakeRange(basicName.length - @".mesh".length, @".mesh".length)];
	
	// Replace underscores
	[basicName replaceOccurrencesOfString:@"_" withString:@" " options:0 range:NSMakeRange(0, basicName.length)];
	
	// Use title case
	CFStringTransform((__bridge CFMutableStringRef) basicName, NULL, CFSTR("Title"), NO);
	
	// Find out how many others with the same name exist
	NSFetchRequest *sameNameRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
	sameNameRequest.predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"displayName"] rightExpression:[NSExpression expressionForConstantValue:basicName] modifier:0 type:NSEqualToPredicateOperatorType options:NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption];
	NSUInteger count = [self.managedObjectContext countForFetchRequest:sameNameRequest error:NULL];
	if (count > 0)
		[basicName appendFormat:NSLocalizedString(@" (%lu)", @"same item display name suffix format"), count + 1];
	
	// And assign to self.
	self.displayName = [basicName copy];
}

#pragma mark - Derived

- (NSArray *)rootBoneTransformations
{
	NSIndexSet *indices = [self.boneTransformations indexesOfObjectsPassingTest:^BOOL(GLLBoneTransformation *bone, NSUInteger idx, BOOL *stop) {
		return !bone.hasParent;
	}];
	return [self.boneTransformations objectsAtIndexes:indices];
}

- (GLLMeshSettings *)settingsForMesh:(GLLMesh *)mesh;
{
	return self.meshSettings[mesh.meshIndex];
}

#pragma mark - Source List Item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return self.displayName;
}
- (BOOL)hasChildrenInSourceList
{
	return YES;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return 2;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	if (index == 0)
	{
		if (!meshesMarker) meshesMarker = [[GLLItem_MeshesSourceListMarker alloc] initWithItem:self];
		return meshesMarker;
	}
	else if (index == 1)
	{
		if (!bonesMarker) bonesMarker = [[GLLItem_BonesSourceListMarker alloc] initWithItem:self];
		return bonesMarker;
	}
	else return nil;
}

@end

//
//  GLLBoneController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLBoneController.h"

#import "GLLBoneListController.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLModelBone.h"

@interface GLLBoneController ()
{
	id parentController;
}

@property (nonatomic, readonly) NSArray *childBoneControllers;

@end

@implementation GLLBoneController

- (id)initWithBone:(GLLItemBone *)bone listController:(GLLBoneListController *)listController;
{
	if (!(self = [super init])) return nil;
	
	self.bone = bone;
	self.listController = listController;
	
	return self;
}

- (id)representedObject
{
	return self.bone;
}

- (id)parentController
{
	if (!parentController)
	{
		if (self.bone.parent)
			parentController = [self.listController.boneControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bone == %@", self.bone.parent]][0];
		else
			parentController = self.listController;
	}
	return parentController;
}

- (NSArray *)childBoneControllers
{
	return [self.listController.boneControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bone.parent == %@", self.bone]];
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return self.childBoneControllers[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (self.bone.item != self.listController.item)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%@)", @"Bone from other model"), self.bone.bone.name, self.bone.item.displayName];
	else
		return self.bone.bone.name;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return self.childBoneControllers.count > 0;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return self.childBoneControllers.count;
}

@end

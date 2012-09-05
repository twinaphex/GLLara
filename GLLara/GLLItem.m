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
#import "GLLModel.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

@implementation GLLItem

- (id)initWithModel:(GLLModel *)model;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	
	self.isVisible = YES;
	self.scaleX = 1.0f;
	self.scaleY = 1.0f;
	self.scaleZ = 1.0f;
	
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:model.bones.count];
	for (GLLBone *bone in model.bones)
	{
		GLLBoneTransformation *transform = [[GLLBoneTransformation alloc] initWithItem:self bone:bone];
		[bones addObject:transform];
	}
	_boneTransformations = [bones copy];
	
	//for (GLLBoneTransformation *transform in _boneTransformations)
	//	[transform calculateLocalPositions];
	
	return self;
}
- (id)initFromDataStream:(TRInDataStream *)stream baseURL:(NSURL *)url version:(GLLSceneVersion)version;
{
	if (!(self = [super init])) return nil;
	
	_itemName = [stream readPascalString];
	if (version >= GLLSceneVersion_1_5)
		_itemDirectory = [stream readPascalString];
	else
		_itemDirectory = [_itemName lowercaseString];
	
	self.isVisible = [stream readUint8];
	
	if (version >= GLLSceneVersion_1_8)
	{
		self.scaleX = [stream readFloat32];
		self.scaleY = [stream readFloat32];
		self.scaleZ = [stream readFloat32];
	}
	else {
		float uniformScale = [stream readFloat32];
		self.scaleX = uniformScale;
		self.scaleY = uniformScale;
		self.scaleZ = uniformScale;
	}
	
	// Load model
	_model = nil;
	
	// Pose
	
	
	return self;
}

- (void)writeToStream:(TROutDataStream *)stream;
{
	
}

- (NSArray *)rootBones
{
	return [self.boneTransformations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GLLBoneTransformation *bone, NSDictionary *bindings){
		return !bone.hasParent;
	}]];
}

- (void)getTransforms:(mat_float16 *)matrices maxCount:(NSUInteger)maxCount forMesh:(GLLMesh *)mesh;
{
	NSArray *boneIndices = mesh.boneIndices;
	NSUInteger max = MIN(maxCount, boneIndices.count);
	for (NSUInteger i = 0; i < max; i++)
		matrices[i] = [_boneTransformations[[boneIndices[i] unsignedIntegerValue]] globalTransform];
}

@end
//
//  GLLInvalidBinaryModelTest.m
//  GLLara
//
//  Created by Torsten Kammer on 17.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLInvalidBinaryModelTest.h"

#import "GLLModel.h"

@implementation GLLInvalidBinaryModelTest

- (void)testZeroLengthFile
{
    NSData *data = [NSData data];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testTooManyBonesFile
{
    uint8_t bytes[] = { 0xFF, 0x01, 0x00, 0x00, // Bone count
        
        0x00, 0x00, 0x00, 0x00 // Count of meshes
    };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testTooManyMeshesFile
{
    uint8_t bytes[] = { 0x00, 0x00, 0x00, 0x00, // Bone count
        
        0xFF, 0x01, 0x00, 0x00 // Count of meshes
    };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testBoneParentOutOfRange
{
    uint8_t bytes[] = { 0x02, 0x00, 0x00, 0x00, // Bone count
        0x04, 'T', 'e', 's', 't', // Name
        0xFF, 0xFF, // Parent index
        0x00, 0x00, 0x00, 0x00, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        0x04, 'T', 'e', 's', 't', '2', // Name
        0x10, 0x00, // Parent index
        0x00, 0x00, 0x00, 0x00, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        
        0x00, 0x00, 0x00, 0x00 // Count of meshes
    };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testBoneParentCircle
{
    uint8_t bytes[] = { 0x02, 0x00, 0x00, 0x00, // Bone count
        0x04, 'T', 'e', 's', 't', // Name
        0x01, 0x00, // Parent index
        0x00, 0x00, 0x00, 0x00, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        0x05, 'T', 'e', 's', 't', '2', // Name
        0x00, 0x00, // Parent index
        0x00, 0x00, 0x00, 0x00, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        
        0x00, 0x00, 0x00, 0x00 // Count of meshes
    };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testBoneIndexOutOfRange
{
    uint8_t bytes[] = { 0x02, 0x00, 0x00, 0x00, // Bone count
        0x05, 'B', 'o', 'n', 'e', '1', // Name
        0xFF, 0xFF, // Parent index
        0x00, 0x00, 0x00, 0xBF, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        0x05, 'B', 'o', 'n', 'e', '2', // Name
        0x00, 0x00, // Parent index
        0x00, 0x00, 0x00, 0x3F, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        
        0x01, 0x00, 0x00, 0x00, // Count of meshes
        0x04, 'T', 'e', 's', 't', // Name
        0x01, 0x00, 0x00, 0x00, // Count of UV layers
        0x01, 0x00, 0x00, 0x00, // Count of textures
        0x07, 't', 'e', 'x', '.', 't', 'g', 'a', // tex name 1
        0x00, 0x00, 0x00, 0x00, // tex uv layer 1 (ignored)
        0x03, 0x00, 0x00, 0x00, // Count of vertices.
        0x00, 0x00, 0x00, 0xBF, // position 0
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // normal
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x80, 0x3F,
        0xFF, 0x00, 0x00, 0xFF, // color
        0x00, 0x00, 0x00, 0x00, // tex coord
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x05, 0x00, 0x06, 0x00, 0x07, 0x00, 0x08, 0x00, // bone indices
        0x00, 0x00, 0x80, 0x3F, // bone weights
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x3F, // position 1
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // normal
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0xFF, 0x00, 0xFF, // color
        0x00, 0x00, 0x00, 0x3F, // tex coord
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x10, 0x00, 0x11, 0x00, 0x12, 0x00, 0x13, 0x00, // bone indices
        0x00, 0x00, 0x80, 0x3F, // bone weights
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // position 2
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // normal
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0xFF, 0xFF, // color
        0x00, 0x00, 0x00, 0x00, // tex coord
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x23, 0x00, 0x24, 0x00, 0x25, 0x00, 0x26, 0x00, // bone indices
        0x00, 0x00, 0x00, 0x3F, // bone weights
        0x00, 0x00, 0x00, 0x3F,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x00, 0x00, // Count of triangles
        0x00, 0x00, 0x00, 0x00, // index 1
        0x01, 0x00, 0x00, 0x00, // index 2
        0x02, 0x00, 0x00, 0x00, // index 3
    };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testVertexElementOutOfRange
{
    uint8_t bytes[] = { 0x02, 0x00, 0x00, 0x00, // Bone count
        0x05, 'B', 'o', 'n', 'e', '1', // Name
        0xFF, 0xFF, // Parent index
        0x00, 0x00, 0x00, 0xBF, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        0x05, 'B', 'o', 'n', 'e', '2', // Name
        0x00, 0x00, // Parent index
        0x00, 0x00, 0x00, 0x3F, // Position X
        0x00, 0x00, 0x00, 0x00, // Position Y
        0x00, 0x00, 0x00, 0x00, // Position Z
        
        0x01, 0x00, 0x00, 0x00, // Count of meshes
        0x04, 'T', 'e', 's', 't', // Name
        0x01, 0x00, 0x00, 0x00, // Count of UV layers
        0x01, 0x00, 0x00, 0x00, // Count of textures
        0x07, 't', 'e', 'x', '.', 't', 'g', 'a', // tex name 1
        0x00, 0x00, 0x00, 0x00, // tex uv layer 1 (ignored)
        0x03, 0x00, 0x00, 0x00, // Count of vertices.
        0x00, 0x00, 0x00, 0xBF, // position 0
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // normal
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x80, 0x3F,
        0xFF, 0x00, 0x00, 0xFF, // color
        0x00, 0x00, 0x00, 0x00, // tex coord
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // bone indices
        0x00, 0x00, 0x80, 0x3F, // bone weights
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x3F, // position 1
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // normal
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0xFF, 0x00, 0xFF, // color
        0x00, 0x00, 0x00, 0x3F, // tex coord
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // bone indices
        0x00, 0x00, 0x80, 0x3F, // bone weights
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // position 2
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, // normal
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0xFF, 0xFF, // color
        0x00, 0x00, 0x00, 0x00, // tex coord
        0x00, 0x00, 0x80, 0x3F,
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, // bone indices
        0x00, 0x00, 0x00, 0x3F, // bone weights
        0x00, 0x00, 0x00, 0x3F,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x00, 0x00, // Count of triangles
        0x00, 0x01, 0x00, 0x00, // index 1
        0x01, 0x01, 0x00, 0x00, // index 2
        0x02, 0x01, 0x00, 0x00, // index 3
    };
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testASCIIAsBinary
{
    const char *string = "0\n\
    1 # the count of them meshes\n\
    Test\n\
    1 # uv layers\n\
    1 # textures\n\
    tex.tga\n\
    0\n\
    3 # num verts\n\
    -.5 0 0\n\
    0 0 1\n\
    255 0 0 255\n\
    0 0\n\
    0.5 0 0\n\
    0 0 1\n\
    0 255 0  255\n\
    1 0\n\
    0.0 1.000000 0\n\
    0 0 1\n\
    0 0 255 255\n\
    0 1\n\
    1 # count of tris\n\
    0 1 2	";
    
    NSData *data = [NSData dataWithBytes:string length:strlen(string)];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

@end

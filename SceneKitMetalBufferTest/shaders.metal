//
//  compute.metal
//  SceneKitMetalBufferTest
//
//  Created by Lachlan Hurst on 5/11/2015.
//  Copyright © 2015 Lachlan Hurst. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct MyNodeBuffer {
    float4x4 modelTransform;
    float4x4 modelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
};


struct MyPositions
{
    float3 positions[3];
};


typedef struct {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
} SimpleVertexInput;

struct SimpleVertex
{
    float4 position [[position]];
};


vertex SimpleVertex simpleVertex(SimpleVertexInput in [[ stage_in ]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant MyNodeBuffer& scn_node [[buffer(1)]],
                             constant MyPositions &myPos [[buffer(2)]],
                             constant uint &index [[buffer(3)]]
                             )
{
    
    SimpleVertex vert;
    
    float3 posOffset = myPos.positions[index];
    
    float3 pos = float3(in.position.x, in.position.y + posOffset.y, in.position.z);
    
    vert.position = scn_node.modelViewProjectionTransform * float4(pos,1.0);
    
    return vert;
}


fragment half4 simpleFragment(SimpleVertex in [[stage_in]])
{
    return half4(0.0, 0.0 , 0.0 ,1.0);
}


kernel void doSimple(const device float3 *inVector [[ buffer(0) ]],
                    device float3 *outVector [[ buffer(1) ]],
                    uint id [[ thread_position_in_grid ]]) {
    
    float yDisplacement = 0;
    if (inVector[id].x == 0) {
        yDisplacement = 0.0005;
    }
    else if (inVector[id].x == 1) {
        yDisplacement = 0.001;
    }
    else if (inVector[id].x == 2) {
        yDisplacement = 0.0015;
    }
    
    outVector[id] = float3(inVector[id].x, inVector[id].y + yDisplacement, inVector[id].z);
}
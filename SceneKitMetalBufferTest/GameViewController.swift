//
//  GameViewController.swift
//  SceneKitMetalBufferTest
//
//  Created by Lachlan Hurst on 5/11/2015.
//  Copyright (c) 2015 Lachlan Hurst. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    var positions:[vector_float3] = []
    
    var device:MTLDevice!
    var commandQueue:MTLCommandQueue!
    var defaultLibrary:MTLLibrary!
    var function:MTLFunction!
    var pipelineState: MTLComputePipelineState!
    
    var threadsPerGroup:MTLSize!
    var numThreadgroups:MTLSize!
    
    var buffer1:MTLBuffer!
    var buffer2:MTLBuffer!
    
    var sphere1Mat:SCNMaterial!
    var sphere2Mat:SCNMaterial!
    var sphere3Mat:SCNMaterial!
    
    
    func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        
        
        let computeCommandBuffer = commandQueue.commandBuffer()
        let computeCommandEncoder = computeCommandBuffer.computeCommandEncoder()
        
        computeCommandEncoder.setComputePipelineState(pipelineState)
        computeCommandEncoder.setBuffer(buffer1, offset: 0, atIndex: 0)
        computeCommandEncoder.setBuffer(buffer2, offset: 0, atIndex: 1)
        
        computeCommandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        computeCommandBuffer.commit()
        computeCommandBuffer.waitUntilCompleted()
        
        let bufferSize = positions.count*sizeof(vector_float3)
        var data = NSData(bytesNoCopy: buffer2.contents(), length: bufferSize, freeWhenDone: false)
        var resultArray = [vector_float3](count: positions.count, repeatedValue: vector_float3(0,0,0))
        data.getBytes(&resultArray, length:bufferSize)
        
        /*for outPos in resultArray {
            print(outPos.x, ", ", outPos.y, ", ", outPos.z)
        }*/
        
        var i0:UInt32 = 0
        let index0 = NSData(bytes: &i0, length: sizeof(UInt32))
        var i1:UInt32 = 1
        let index1 = NSData(bytes: &i1, length: sizeof(UInt32))
        var i2:UInt32 = 2
        let index2 = NSData(bytes: &i2, length: sizeof(UInt32))

        sphere1Mat.setValue(index0, forKey: "index")
        sphere2Mat.setValue(index1, forKey: "index")
        sphere3Mat.setValue(index2, forKey: "index")
        
        
        //works
        sphere1Mat.setValue(data, forKey: "myPos")
        sphere2Mat.setValue(data, forKey: "myPos")
        sphere3Mat.setValue(data, forKey: "myPos")

        
        /*
        //does not work
        let renderCommandEncoder = renderer.currentRenderCommandEncoder!
        renderCommandEncoder.setVertexBuffer(buffer2, offset: 0, atIndex: 2)
        renderCommandEncoder.endEncoding()
        */
        
        
        
        //switch buffers
        let tmp = buffer1
        buffer1 = buffer2
        buffer2 = tmp
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let program = SCNProgram()
        program.vertexFunctionName = "simpleVertex"
        program.fragmentFunctionName = "simpleFragment"
        
        let scene = SCNScene()
        
        let sphere1 = SCNSphere(radius: 0.4)
        sphere1Mat = sphere1.firstMaterial!
        sphere1Mat.program = program
        let sphereNode1 = SCNNode(geometry: sphere1)
        sphereNode1.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(sphereNode1)
        
        let sphere2 = SCNSphere(radius: 0.4)
        sphere2Mat = sphere2.firstMaterial!
        sphere2Mat.program = program
        let sphereNode2 = SCNNode(geometry: sphere2)
        sphereNode2.position = SCNVector3Make(1, 0, 0)
        scene.rootNode.addChildNode(sphereNode2)
        
        let sphere3 = SCNSphere(radius: 0.4)
        sphere3Mat = sphere3.firstMaterial!
        sphere3Mat.program = program
        let sphereNode3 = SCNNode(geometry: sphere3)
        sphereNode3.position = SCNVector3Make(2, 0, 0)
        scene.rootNode.addChildNode(sphereNode3)
        
        
        let scnView = self.view as! SCNView
        scnView.playing = true
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.lightGrayColor()
        scnView.autoenablesDefaultLighting = true
        
        scnView.delegate = self
        
        setupMetal()
        setupBuffers()
    }
    

    func setupMetal() {
        let scnView = self.view as! SCNView
        device = scnView.device
        commandQueue = device.newCommandQueue()
        defaultLibrary = device.newDefaultLibrary()
        function = defaultLibrary.newFunctionWithName("doSimple")
        
        do {
            pipelineState = try! device.newComputePipelineStateWithFunction(function)
        }
        
        threadsPerGroup = MTLSize(width:3, height:1, depth:1)
        numThreadgroups = MTLSize(width:1, height:1, depth:1)
    }
    
    func setupBuffers() {
        positions = [vector_float3(0,0,0), vector_float3(1,0,0), vector_float3(2,0,0)]
        
        let bufferSize = sizeof(vector_float3) * positions.count
        //copy same data into two different buffers for initialisation
        buffer1 = device.newBufferWithBytes(&positions, length: bufferSize, options: .OptionCPUCacheModeDefault)
        buffer2 = device.newBufferWithBytes(&positions, length: bufferSize, options: .OptionCPUCacheModeDefault)
    }
    
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}

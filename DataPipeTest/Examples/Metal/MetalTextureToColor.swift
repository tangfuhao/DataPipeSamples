//
//  MetalTextureToColor.swift
//  YunNeutronDemo
//
//  Created by fuhao on 2022/7/26.
//

import Foundation
import Metal
import MetalKit


//纹理转颜色的协议
protocol MetalMappingDelegate : AnyObject{
    func onColorData(pixelBuffer: CVPixelBuffer)
}


// 命令缓冲区同时处理的最大数量
let kMaxBuffersInFlight: Int = 2


// 平面的顶点数据（显示相机）
let kImagePlaneVertexData: [Float] = [
    -1.0, -1.0,  0.0, 1.0,
    1.0, -1.0,  1.0, 1.0,
    -1.0,  1.0,  0.0, 0.0,
    1.0,  1.0,  1.0, 0.0,
]

//纹理转颜色
class MetalTextureToColor {
    let inFlightSemaphore = DispatchSemaphore(value: kMaxBuffersInFlight)

    
    // Metal objects
    var commandQueue: MTLCommandQueue!
    var copyTexturePlaneVertexBuffer: MTLBuffer!
    var yuv2rgbPipelineState: MTLRenderPipelineState!
    
    // rgba objects
    var rgbaRenderTargetDesc: MTLRenderPassDescriptor!
    var rgbaTextureTextureCache: CVMetalTextureCache!
    var rgbaPixelBuffer: CVPixelBuffer?
    
    // yuv objects
    var capturedImageTextureCache: CVMetalTextureCache!
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    
    
    weak var delegate :MetalMappingDelegate?
    
    
    
    
    init(metalDevice device: MTLDevice,contentSize: CGSize) {
        print("MetalTextureToColor 创建")
        loadCacheTexture(device: device, width: Int(contentSize.width),height: Int(contentSize.height))
        loadMetal(device: device)
    }
    
    //TODO Metal 资源释放
    deinit {
        print("MetalTextureToColor 释放")
    }
    

    
    

    
    func updateCapturedImageTextures(pixelBuffer: CVPixelBuffer) {
        
        if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
            return
        }
        
        capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, textureCache: capturedImageTextureCache, pixelFormat:.r8Unorm, planeIndex:0)
        capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, textureCache: capturedImageTextureCache, pixelFormat:.rg8Unorm, planeIndex:1)
    }
    
    func updateGameState(currentFrame: CVPixelBuffer) {
        updateCapturedImageTextures(pixelBuffer: currentFrame)
    }
    
    
    func drawCapturedImage(renderEncoder: MTLRenderCommandEncoder) {
        guard let textureY = capturedImageTextureY, let textureCbCr = capturedImageTextureCbCr else {
            return
        }
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder.pushDebugGroup("DrawCapturedImage")
        
        // Set render command encoder state
        renderEncoder.setCullMode(.none)
        renderEncoder.setRenderPipelineState(yuv2rgbPipelineState)
        
        // 设置 Mesh 的顶点缓冲区
        renderEncoder.setVertexBuffer(copyTexturePlaneVertexBuffer, offset: 0, index: Int(kBufferIndexMeshPositions.rawValue))
        
        // 设置渲染管道中采样的纹理
        
        // Set any textures read/sampled from our render pipeline
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: Int(kTextureIndexY.rawValue))
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: Int(kTextureIndexCbCr.rawValue))
        
        // Draw each submesh of our mesh
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.popDebugGroup()
    }

    
    //每帧更新数据并渲染
    func update(source: CVPixelBuffer) {
        
        let _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "MyCommand"
            

            //添加 CompletedHandler，当 Metal 和 GPU 完成对这一帧的编码命令的处理时，向_inFlightSemaphore发出信号。
            //这表明当我们写入这个帧的动态缓冲区不再被 Metal 和 GPU 所需要。
            //在渲染周期内缓存 CVMetalTextures 不被释放，否则从 CVMetalTextures 中使用的 MTLTextures 是无效的
            commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
                if let strongSelf = self {
                    strongSelf.inFlightSemaphore.signal()
                    
//                    print(strongSelf.rgbaPixelBuffer.hashValue)
                    //回调
                    guard let pixelBuffer = strongSelf.rgbaPixelBuffer,
                          let dataDelegate = strongSelf.delegate else {
                        return
                    }
                    
                    dataDelegate.onColorData(pixelBuffer: pixelBuffer)
                }
            }
            
            updateGameState(currentFrame: source)
            
            if  let renderPassDescriptor = rgbaRenderTargetDesc,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                renderEncoder.label = "MyRenderEncoder"
                
                drawCapturedImage(renderEncoder: renderEncoder)
                // 完成绘制
                renderEncoder.endEncoding()
            }
            commandBuffer.commit()
        }
    }
    
}

extension MetalTextureToColor {

    func loadMetal(device: MTLDevice) {
        
        //Create VertexBuffer for plane
        let imagePlaneVertexDataCount = kImagePlaneVertexData.count * MemoryLayout<Float>.size
        copyTexturePlaneVertexBuffer = device.makeBuffer(bytes: kImagePlaneVertexData, length: imagePlaneVertexDataCount, options: [])
        copyTexturePlaneVertexBuffer.label = "copyTexturePlaneVertexBuffer"
        
        // Load Shader
        let frameworkBundle = Bundle(for: type(of: self))
        let metalLibraryPath = frameworkBundle.path(forResource: "default", ofType: "metallib")!
        
        guard let defaultLibrary = try? device.makeLibrary(filepath:metalLibraryPath) else {
            fatalError("加载Shader 失败")
        }
    

        let capturedImageVertexFunction = defaultLibrary.makeFunction(name: "capturedImageVertexTransform")!
        let textureCopyFragmentFunction = defaultLibrary.makeFunction(name: "capturedImageFragmentShader")!

        
        
        //Create VertexDescriptor
        let imagePlaneVertexDescriptor = MTLVertexDescriptor()

        // Positions.
        imagePlaneVertexDescriptor.attributes[0].format = .float2
        imagePlaneVertexDescriptor.attributes[0].offset = 0
        imagePlaneVertexDescriptor.attributes[0].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)

        // Texture coordinates.
        imagePlaneVertexDescriptor.attributes[1].format = .float2
        imagePlaneVertexDescriptor.attributes[1].offset = 8
        imagePlaneVertexDescriptor.attributes[1].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)

        // Buffer Layout
        imagePlaneVertexDescriptor.layouts[0].stride = 16
        imagePlaneVertexDescriptor.layouts[0].stepRate = 1
        imagePlaneVertexDescriptor.layouts[0].stepFunction = .perVertex
        
        
        
        
        
        //创建一个纹理拷贝的渲染管线
        let yuv2rgbPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        yuv2rgbPipelineStateDescriptor.label = "CopyToTexturePipeline"
        yuv2rgbPipelineStateDescriptor.vertexFunction = capturedImageVertexFunction
        yuv2rgbPipelineStateDescriptor.fragmentFunction = textureCopyFragmentFunction
        yuv2rgbPipelineStateDescriptor.vertexDescriptor = imagePlaneVertexDescriptor
        yuv2rgbPipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        
        
        do {
            yuv2rgbPipelineState = try device.makeRenderPipelineState(descriptor: yuv2rgbPipelineStateDescriptor)
        } catch let error {
            fatalError("Failed to created captured image pipeline state, error \(error)")
        }

        // 创建命令队列
        commandQueue = device.makeCommandQueue()
    }
    
    
    func loadCacheTexture(device: MTLDevice, width: Int, height: Int) {
        //Create YUV CVMetalTextureCache
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        capturedImageTextureCache = textureCache
        
        
        //Create RGBA PixelBuffer
        var pixelBuffer :CVPixelBuffer! = nil
        let options = [ kCVPixelBufferMetalCompatibilityKey as String: true ] as [String: Any]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, options as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            fatalError("create rgba pixel faild!!" + status.description)
        }
        self.rgbaPixelBuffer = pixelBuffer
        
        //Create BGRA CVMetalTextureCache
        var rgbaTextureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &rgbaTextureCache)
        rgbaTextureTextureCache = rgbaTextureCache
        
        //Binding BGRA PixelBuffer to CVMetalTextureCache
        guard let rgbCVMetalTexture = createTexture(fromPixelBuffer: pixelBuffer, textureCache: rgbaTextureTextureCache, pixelFormat: .bgra8Unorm, planeIndex: 0) else {
            fatalError("Create rgbCVMetalTexture has error")
        }
        
        
    
        //Create RenderPass and setting Metal Texture to Color Attachment
        let texturePassDescriptor = MTLRenderPassDescriptor()
        if let rgbaColorAttachment = texturePassDescriptor.colorAttachments[0] {
            rgbaColorAttachment.loadAction = .clear
            rgbaColorAttachment.storeAction = .store
            rgbaColorAttachment.clearColor = MTLClearColorMake(0, 0, 0, 1)
            rgbaColorAttachment.texture = CVMetalTextureGetTexture(rgbCVMetalTexture)
        }
        self.rgbaRenderTargetDesc = texturePassDescriptor
    }
    
    
    

    
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, textureCache: CVMetalTextureCache, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)

        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)

        if status != kCVReturnSuccess {
            texture = nil
            print(status.description)
        }

        return texture
    }

}

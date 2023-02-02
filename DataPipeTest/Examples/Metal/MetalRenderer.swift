//
//  MetalRenderer.swift
//  ComeSocialDemo
//
//  Created by fuhao on 2022/9/21.
//

import Foundation
import Metal
import MetalKit


// 平面的顶点数据（显示相机） 
let kImagePlaneVertexData2: [Float] = [
    -1.0, -1.0, 0.0, 0.0,
    1.0, -1.0,1.0, 0.0,
    -1.0,  1.0, 0.0, 1.0,
    1.0,  1.0,1.0, 1.0,
]

//纹理渲染到视图
class MetalRenderer {
    weak var renderView: MTKView?
    let inFlightSemaphore = DispatchSemaphore(value: kMaxBuffersInFlight)

    
    // Metal objects
    var commandQueue: MTLCommandQueue!
    var copyTexturePlaneVertexBuffer: MTLBuffer!
    var copyToTexturePipelineState: MTLRenderPipelineState!
    var copyToTextureDepthState: MTLDepthStencilState!
    

    
    init(renderView: MTKView, device: MTLDevice) {
        self.renderView = renderView
        loadMetal(renderView: renderView,device: device)
    }
    

    
    //每帧更新数据并渲染
    func update(source: MTLTexture) {
        
        // 等待当前命令(App, Metal, Drivers, GPU, etc)缓冲区有剩余空间
        let _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        // 为每个渲染通道创建一个新的命令缓冲区，用于当前可绘制的图像。
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "MyCommand"
            

            //添加 CompletedHandler，当 Metal 和 GPU 完成对这一帧的编码命令的处理时，向_inFlightSemaphore发出信号。
            //这表明当我们写入这个帧的动态缓冲区不再被 Metal 和 GPU 所需要。
            //在渲染周期内缓存 CVMetalTextures 不被释放，否则从 CVMetalTextures 中使用的 MTLTextures 是无效的
            commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
                if let strongSelf = self {
                    strongSelf.inFlightSemaphore.signal()
                }
            }
            

            
            //获取渲染目标的MTLRenderPassDescriptor，CAMetalDrawable，MTLRenderCommandEncoder并执行渲染命令
            //渲染到视图
            if  let renderDestination = renderView,
                let renderPassDescriptor = renderDestination.currentRenderPassDescriptor,
                let currentDrawable = renderDestination.currentDrawable,
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                
                renderEncoder.label = "MyRenderEncoder"
                
                
                //rgba中间状态纹理拷贝
                drawTextureCopy(sourceTexture: source, renderEncoder: renderEncoder)
                // 完成绘制
                renderEncoder.endEncoding()
                
                // 一旦帧缓冲区完成后，提交一次让 CAMetalDrawable 显示。
                commandBuffer.present(currentDrawable)
            }
            
            
            
            // 完成渲染，并将命令缓冲区推送给GPU
            commandBuffer.commit()
        }
    }
    
    
    // MARK: - Private
    
    // 创建并初始化 Metal，初始化渲染数据缓冲区
    func loadMetal(renderView: MTKView, device: MTLDevice) {
        
        // 设置渲染目标（MTKView）所需的默认格式
        let defaultDepthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        let defaultColorPixelFormat = MTLPixelFormat.bgra8Unorm
        let defaultSampleCount = 1
        
        renderView.depthStencilPixelFormat = defaultDepthStencilPixelFormat
        renderView.colorPixelFormat = defaultColorPixelFormat
        renderView.sampleCount = defaultSampleCount
        
        
        


        // 用平面顶点数组创建一个顶点缓冲区。
        let imagePlaneVertexDataCount = kImagePlaneVertexData2.count * MemoryLayout<Float>.size
        copyTexturePlaneVertexBuffer = device.makeBuffer(bytes: kImagePlaneVertexData2, length: imagePlaneVertexDataCount, options: [])
        copyTexturePlaneVertexBuffer.label = "copyTexturePlaneVertexBuffer"

        // 加载项目下的 Shader
        let frameworkBundle = Bundle(for: type(of: self))
        let metalLibraryPath = frameworkBundle.path(forResource: "default", ofType: "metallib")!
        
        guard let defaultLibrary = try? device.makeLibrary(filepath:metalLibraryPath) else {
            fatalError("加载Shader 失败")
        }

        let capturedImageVertexFunction = defaultLibrary.makeFunction(name: "capturedImageVertexTransform")!
        let textureCopyFragmentFunction = defaultLibrary.makeFunction(name: "textureCopyFragmentShader")!

        // 为平面顶点缓冲器创建一个顶点描述符
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
        let copyToTexturePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        copyToTexturePipelineStateDescriptor.label = "CopyToTexturePipeline"
        copyToTexturePipelineStateDescriptor.sampleCount = defaultSampleCount
        copyToTexturePipelineStateDescriptor.vertexFunction = capturedImageVertexFunction
        copyToTexturePipelineStateDescriptor.fragmentFunction = textureCopyFragmentFunction
        copyToTexturePipelineStateDescriptor.vertexDescriptor = imagePlaneVertexDescriptor
        copyToTexturePipelineStateDescriptor.colorAttachments[0].pixelFormat = defaultColorPixelFormat
        copyToTexturePipelineStateDescriptor.depthAttachmentPixelFormat = defaultDepthStencilPixelFormat
        copyToTexturePipelineStateDescriptor.stencilAttachmentPixelFormat = defaultDepthStencilPixelFormat
        
        do {
            try copyToTexturePipelineState = device.makeRenderPipelineState(descriptor: copyToTexturePipelineStateDescriptor)
        } catch let error {
            print("Failed to created captured image pipeline state, error \(error)")
        }

        let copyToTextureDepthStateDescriptor = MTLDepthStencilDescriptor()
        copyToTextureDepthStateDescriptor.depthCompareFunction = .always
        copyToTextureDepthStateDescriptor.isDepthWriteEnabled = false
        copyToTextureDepthState = device.makeDepthStencilState(descriptor: copyToTextureDepthStateDescriptor)



        // 创建命令队列
        commandQueue = device.makeCommandQueue()
    }

    //复制纹理
    func drawTextureCopy(sourceTexture: MTLTexture, renderEncoder: MTLRenderCommandEncoder) {

        // 推送一个DebugGroup，允许我们在GPU帧捕获工具中识别渲染命令
        renderEncoder.pushDebugGroup("DrawCopyTexture")
        
        // 设置渲染命令编码器的状态
        renderEncoder.setCullMode(.none)
        renderEncoder.setRenderPipelineState(copyToTexturePipelineState)
        renderEncoder.setDepthStencilState(copyToTextureDepthState)
        
        // 设置 Mesh 的顶点缓冲区
        renderEncoder.setVertexBuffer(copyTexturePlaneVertexBuffer, offset: 0, index: Int(kBufferIndexMeshPositions.rawValue))
        
        // 设置渲染管道中采样的纹理
        renderEncoder.setFragmentTexture(sourceTexture, index: Int(kTextureIndexColor.rawValue))
        
        // 绘制网格
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        //推出DebugGroup
        renderEncoder.popDebugGroup()
    }
    
    
    

    
}

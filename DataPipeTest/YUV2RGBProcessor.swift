//
//  YUV2RGBProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/29.
//

import Foundation
import CoreVideo

class YUV2RGBProcessor : CSDataProcessor {
    var rgbPixelBufferTemp: CVPixelBuffer?
    
    
    override func onInit() {
        super.onInit()
        registerInputDataFormat(index: 0, type: .PixelBuffer)
    }
    
    override func onProcess() {
        super.onProcess()
        
        guard let pixelBuffer = getInputPixel(index: 0),
              let rgbPixelBuffer = getRGBPixelBuffer(yuvPixelBuffer: pixelBuffer) else {
            return
        }
        
        pushPixelData(pixelBuffer: rgbPixelBuffer)
    }
    
    func getRGBPixelBuffer(yuvPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        if (rgbPixelBufferTemp ==  nil){
            let width = CVPixelBufferGetWidth(yuvPixelBuffer)
            let height = CVPixelBufferGetHeight(yuvPixelBuffer)
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)

            if status != kCVReturnSuccess {
                print("Error creating pixel buffer")
                return nil
            }
            rgbPixelBufferTemp = pixelBuffer
            return pixelBuffer
        }
        
        return rgbPixelBufferTemp


    }
}

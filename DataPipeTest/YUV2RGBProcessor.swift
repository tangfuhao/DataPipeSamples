//
//  YUV2RGBProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/29.
//

import Foundation
import CoreVideo

class YUV2RGBProcessor : CSProcessorPProtocol {
    var rgbPixelBufferTemp: CVPixelBuffer?
    
    override init() {
        super.init()
        print("YUV2RGBProcessor init")
    }
    
    deinit {
        print("YUV2RGBProcessor deinit")
    }
    
    func onProcess() {
        guard let pixelBuffer = getInputPixel(index: 0),
              let rgbPixelBuffer = getRGBPixelBuffer(yuvPixelBuffer: pixelBuffer) else {
            return
        }
        
        storePixelData(pixelBuffer: rgbPixelBuffer)
    }
    
    func onInit() {
        
    }
    
    func onRelease() {
        
    }
    
    func onRegisterDataType() -> CSDataType {
        return CSDataType(format: .PixelBuffer)
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


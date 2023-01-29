//
//  YUV2RGBProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/29.
//

import Foundation
import CoreVideo

class YUV2RGBProcessor : CSDataProcessor {
    var rgbPixelBuffer: CVPixelBuffer?
    
    
    override func onInit() {
        super.onInit()
        registerInputDataFormat(index: 0, type: .PixelBuffer)
    }
    
    override func onProcess() {
        super.onProcess()
        
        guard let inputPixel = getInputPixel(index: 0) else {
            return
        }
//
//        let rgbPixelBuffer = getRGBPixelBuffer(yuvPixelBuffer: inputPixel)
        
        
        
    }
    
//    func getRGBPixelBuffer(yuvPixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
//        if (rgbPixelBuffer ==  nil){
//            let width = CVPixelBufferGetWidth(yuvPixelBuffer)
//        }
//
//
//    }
}

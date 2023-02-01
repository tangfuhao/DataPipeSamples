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
        /**
            Steps to process data
         */
        
        //Step #1 Get input data
        guard let pixelBuffer = getInputPixel(index: 0) else {
            return
        }
        
        //Step #2 Transform data based on the input data
        guard let rgbPixelBuffer = converYUVToBGRAPixelBuffer(yuvPixelBuffer: pixelBuffer) else {
            return
        }
        
        //Step #3 Store the processed data as the next input data
        storePixelData(pixelBuffer: rgbPixelBuffer)
    }
    
    func onInit() {
        
    }
    
    func onRelease() {
        
    }
    
    func onRegisterInputDataType() -> [CSDataType] {
        return [CSDataType(pixelParams: CSPixelParams(width: 640, height: 480, dataCategory: .NV21))]
    }
    
    func onRegisterOutputDataType() -> CSDataType {
        return CSDataType(pixelParams: CSPixelParams(width: 640, height: 480, dataCategory: .BGRA32))
    }
    
    
    func converYUVToBGRAPixelBuffer(yuvPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
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


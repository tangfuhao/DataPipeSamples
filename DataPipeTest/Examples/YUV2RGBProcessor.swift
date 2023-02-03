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
    var converter: MetalTextureToColor?
    
    override init() {
        super.init()
        print("YUV2RGBProcessor init")
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Can not get device ");
        }
        
        let converter = MetalTextureToColor(metalDevice: device, contentSize: CGSize(width: 640, height: 480))
        self.converter = converter
        converter.delegate = self
        
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
        guard let converter = converter else {
            return
        }
        converter.update(source: pixelBuffer)
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
}


extension YUV2RGBProcessor : MetalMappingDelegate {
    func onColorData(pixelBuffer: CVPixelBuffer) {
        //Step #3 Store the processed data as the next input data
        storePixelData(pixelBuffer: pixelBuffer)
    }

}

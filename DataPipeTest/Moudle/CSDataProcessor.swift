//
//  CSDataProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo


protocol CSProcessorProtocol {
    func onProcess()
    
    func getInputPixel(index: Int) -> CVPixelBuffer?
    
    func setOutputPixel(buffer: CVPixelBuffer)
}



class CSDataProcessor : CSUnitBase<CSProcessUnitNative>, CSProcessorProtocol {
    
//    func getPixelCache(index: Int) -> CVPixelBuffer {
//        
//    }
    
    override func onInit() {
        nativePtr = cs_data_processor_create()
    }
    
    func onProcess() {}
    
    func setOutputPixel(buffer: CVPixelBuffer) {
        
    }
    
    func getInputPixel(index: Int)  -> CVPixelBuffer? {
        let width = 640
        let height = 480
        let bytesPerRow = width * 4
        
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_processor_get_input_data(nativePtr,0)
        
        let pixelData = dataCachePointer.pointee.data!
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreateWithBytes(nil, width, height, kCVPixelFormatType_32BGRA, pixelData, bytesPerRow, nil, nil, nil, &pixelBuffer)
        
        return pixelBuffer
    }
    

    
    
}

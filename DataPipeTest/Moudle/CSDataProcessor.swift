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
    
    func pushPixelData(pixelBuffer: CVPixelBuffer)
    
    func connectInput(input: CSDataSource)
    
    func connectInput(input: CSDataProcessor)
    

}



class CSDataProcessor : CSUnitBase<CSProcessUnitNative>, CSProcessorProtocol {
    
    
    override func onInit() {
        nativePtr = cs_data_processor_create()
    }
    
    func onProcess() {}
    
    func pushPixelData(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Create the pointer to the destination memory
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_cache_lock_data_cache(nativePtr)
        let destinationPointer: UnsafeMutableRawPointer = dataCachePointer.pointee.data
        for row in 0..<height {
            let src = baseAddress!.advanced(by: row * bytesPerRow)
            let dest = destinationPointer.advanced(by: row * width * 4)
            memcpy(dest, src, width * 4)
        }
        cs_data_cache_unlock_data_cache(nativePtr)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    func getInputPixel(index: Int)  -> CVPixelBuffer? {
        let width = 640
        let height = 480
        let bytesPerRow = width * 4
        
        guard let dataCachePointer = cs_data_processor_get_input_data(nativePtr, Int32(index)) else {
            return nil
        }
        
        let pixelData = dataCachePointer.pointee.data!
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreateWithBytes(nil, width, height, kCVPixelFormatType_32BGRA, pixelData, bytesPerRow, nil, nil, nil, &pixelBuffer)
        
        return pixelBuffer
    }
    
    func connectInput(input: CSDataSource) {
        cs_data_processor_connect_source_dep(nativePtr,input.nativePtr)
    }
    
    func connectInput(input: CSDataProcessor) {
        cs_data_processor_connect_processor_dep(nativePtr,input.nativePtr)
    }
    

    
    
}

//
//  CSDataSource.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo

class CSDataSource {
    
    let nativePtr: UnsafeMutablePointer<CSDataSourceNative>
    
    init() {
        self.nativePtr = cs_data_source_create()
    }
    
    public func onInit() {
        //create data cache
    }
    
    func setPixelData(pixelBuffer: CVPixelBuffer) {
        // Copy the data from the pixel buffer to the destination pointer
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let dataCachePointer: UnsafeMutablePointer<CSDataWrapNative> = cs_data_source_get_data_cache(nativePtr)
        
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Create the pointer to the destination memory
        let destinationPointer: UnsafeMutableRawPointer = dataCachePointer.pointee.data

        for row in 0..<height {
            let src = baseAddress!.advanced(by: row * bytesPerRow)
            let dest = destinationPointer.advanced(by: row * width * 4)
            memcpy(dest, src, width * 4)
        }
        
        
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    

}

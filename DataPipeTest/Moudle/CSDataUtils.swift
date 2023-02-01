//
//  CSDataUtils.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/2/1.
//

import Foundation
import CoreVideo

class CSDataUtils {
    static func convertPixelBuffer2Binary(pixelBuffer: CVPixelBuffer, binaryPointer: UnsafeMutableRawPointer, dataSizePerRow: Int){
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        // Create the pointer to the destination memory
        
        for row in 0..<height {
            let src = baseAddress!.advanced(by: row * bytesPerRow)
            let dest = binaryPointer.advanced(by: row * dataSizePerRow)
            memcpy(dest, src, dataSizePerRow)
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    static func convertBinary2PixelBuffer(){
        
    }
}

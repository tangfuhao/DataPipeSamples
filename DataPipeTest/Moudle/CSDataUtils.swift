//
//  CSDataUtils.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/2/1.
//

import Foundation
import CoreVideo

class CSDataUtils {
    static func copyPixelBuffer2Binary(pixelBuffer: CVPixelBuffer, binaryPointer: UnsafeMutableRawPointer, dataSizePerRow: Int){
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
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
    
    static func copyBinary2PixelBuffer(binaryPointer: UnsafeMutableRawPointer, pixelBuffer: CVPixelBuffer, dataSizePerRow: Int){
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)


        // Copy the data to the pixel buffer
        for row in 0..<height {
            let dest = baseAddress!.advanced(by: row * bytesPerRow)
            let src = binaryPointer.advanced(by: row * dataSizePerRow)
            memcpy(dest, src, dataSizePerRow)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
}

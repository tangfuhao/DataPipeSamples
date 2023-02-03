//
//  CSDataUtils.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/2/1.
//

import Foundation
import CoreVideo

class CSDataUtils {
    static func copyPixelBuffer2Binary(pixelBuffer: CVPixelBuffer, dataCachePointer: UnsafeMutablePointer<CSDataWrapNative>, dataSizePerRow: Int){
        let binaryPointer = dataCachePointer.pointee.data!
        if CVPixelBufferIsPlanar(pixelBuffer) {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
            
            let baseAddressY = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
            let bytesPerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
            let heightY = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
            
            let baseAddressUV = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
            let bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
            let heightUV = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
            
            let pixelDataSize = bytesPerRowY * heightY + bytesPerRowUV * heightUV
            let indexDest = heightY * bytesPerRowY
            if(pixelDataSize == dataCachePointer.pointee.dataSize){
                memcpy(binaryPointer, baseAddressY, indexDest)
            }else{
                for row in 0..<heightY {
                    let src = baseAddressY!.advanced(by: row * bytesPerRowY)
                    let dest = binaryPointer.advanced(by: row * bytesPerRowY)
                    memcpy(dest, src, bytesPerRowY)
                }
            }
        
            
            
            if(pixelDataSize == dataCachePointer.pointee.dataSize){
                let dest = binaryPointer.advanced(by: indexDest)
                memcpy(dest, baseAddressUV, heightUV * bytesPerRowUV)
            }else{
                for row in 0..<heightUV {
                    let src = baseAddressUV!.advanced(by: row * bytesPerRowY)
                    let dest = binaryPointer.advanced(by: row * bytesPerRowUV + indexDest)
                    memcpy(dest, src, bytesPerRowUV)
                }
            }
            
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        }else{
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
            
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

            // Create the pointer to the destination memory
            
            if(bytesPerRow == dataSizePerRow){
                memcpy(binaryPointer, baseAddress, height * dataSizePerRow)
            }else{
                for row in 0..<height {
                    let src = baseAddress!.advanced(by: row * bytesPerRow)
                    let dest = binaryPointer.advanced(by: row * dataSizePerRow)
                    memcpy(dest, src, dataSizePerRow)
                }
            }
            
            
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        }
    }
    
    static func copyBinary2PixelBuffer(binaryPointer: UnsafeMutableRawPointer, pixelBuffer: CVPixelBuffer, dataSizePerRow: Int){
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        if(bytesPerRow == dataSizePerRow){
            memcpy(baseAddress, binaryPointer, height * dataSizePerRow)
        }else{
            // Copy the data to the pixel buffer
            for row in 0..<height {
                let dest = baseAddress!.advanced(by: row * bytesPerRow)
                let src = binaryPointer.advanced(by: row * dataSizePerRow)
                memcpy(dest, src, dataSizePerRow)
            }
        }
        
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    }
}

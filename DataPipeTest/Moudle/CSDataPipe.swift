//
//  CSDataPipe.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo
import AVFoundation


public typealias PixelCallBack = (_ : CVPixelBuffer) -> Void

class CSDataPipeTopology {
    var mainSource: CSDataSource?
    var mainOutput: CSDataProcessor?
    
    func setMainInputAndOutput(input: CSDataSource, output: CSDataProcessor) {
        mainSource = input
        mainOutput = output
    }
    
    func connectPipe(input: CSDataSource, output: CSDataProcessor) {
        
    }
    
    func connectPipe(input: CSDataProcessor, output: CSDataProcessor) {
        
    }
}



class CSDataPipe {
    public static func createTopology() -> CSDataPipeTopology{
        return CSDataPipeTopology()
    }
    
    public static func createDataPipe(tepology: CSDataPipeTopology) -> CSDataPipe {

        return CSDataPipe()
    }
    
    static func getDataPipeFromId(id: String) -> CSDataPipe? {
        return nil
    }
    
    let nativePtr: UnsafeMutablePointer<CSDataPipeNative>
    
    var _pixelBuffer: CVPixelBuffer?
    var _pixelCallBack: PixelCallBack?
    
    init() {
        nativePtr = cs_data_pipe_create()
    }
    
    deinit {
        print("CSDataPipe release")
        cs_data_pipe_release(nativePtr)
    }
    
    
    
    func createOrCachePixelBuffer() -> CVPixelBuffer? {
        guard let pixelBuffer = _pixelBuffer else {
            let width = 640
            let height = 480
            let bytesPerRow = width * 4
            var pixelData = [UInt8](repeating: 0, count: width * height * 4)

            // Fill pixelData with your image data

            CVPixelBufferCreateWithBytes(nil, width, height, kCVPixelFormatType_32BGRA, &pixelData, bytesPerRow, nil, nil, nil, &_pixelBuffer)
            return _pixelBuffer
        }
        
        return pixelBuffer
    }
    
    
    func callPixelCallBack() {
        guard let pixelCallBack = _pixelCallBack,
              let pixelBuffer = _pixelBuffer else {
            return
        }
        
        pixelCallBack(pixelBuffer)
    }
    
    
    func handleReceiverCVPixelBuffer(dataPointer: UnsafeMutableRawPointer) {
        guard let pixelBuffer = createOrCachePixelBuffer(),
              let pixelCallBack = _pixelCallBack else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)


        // Copy the data to the pixel buffer
        for row in 0..<height {
            let dest = baseAddress!.advanced(by: row * bytesPerRow)
            let src = dataPointer.advanced(by: row * width * 4)
            memcpy(dest, src, width * 4)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        

        DispatchQueue.main.async  {
            self.callPixelCallBack()
        }
    }
    
    
    func receiverCVPixelBuffer(callback: PixelCallBack?) {
        _pixelCallBack = callback
        
        cs_data_pipe_pull_data(nativePtr) { idNative, dataWrapperNative in
            guard let idNative = idNative,
                  let dataWrapperNative = dataWrapperNative else {
                return
            }
            
            let id = String(cString: idNative)
            guard let dataPipe = CSDataPipe.getDataPipeFromId(id: id) else {
                return
            }
            
            guard let dataInC = dataWrapperNative.pointee.data else {
                return
            }
            
        
            
            dataPipe.handleReceiverCVPixelBuffer(dataPointer: dataInC)
        }
    }
    
    
    
    
    
}

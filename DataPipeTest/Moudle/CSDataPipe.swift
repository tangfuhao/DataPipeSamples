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


class CSDataPipe {
    let nativePtr: UnsafeMutableRawPointer?
    var _pixelBuffer: CVPixelBuffer?
    var _pixelCallBack: PixelCallBack?
    
    init() {
//        print("CSDataPipe init")
        nativePtr = cs_data_pipe_create()
    }
    
    deinit {
//        print("CSDataPipe release")
        cs_data_pipe_release(nativePtr)
    }
    
    func setMainInputAndOutput(input: CSSourceNodeImplement, output: CSSourceNodeImplement) {
        cs_data_pipe_set_main_source(nativePtr, input.nativePtr)
        cs_data_pipe_set_output_node(nativePtr, output.nativePtr)
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
        guard let pixelBuffer = createOrCachePixelBuffer() else {
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
    
    
    
    
    
    
    
}


extension CSDataPipe {
    public static func createDataPipe() -> CSDataPipe {
        return CSDataPipe()
    }
    
    static func getDataPipeFromId(id: String) -> CSDataPipe? {
        return nil
    }
    
    func Pause() {
        
    }
    
    func Resume() {
        
    }
    
    /**
            
     1. Passively receive data passed from main input source.
     2. The receiving frequency is based on the frequency of the input source.
     3. The callBack function called on main thread.
     4. If passed callBack functioin is nil, the dataPipe will stop.
     */
    func ReceiveData(callBack: PixelCallBack?) {
        _pixelCallBack = callBack
        
        
        guard _pixelCallBack != nil else {
            cs_data_pipe_register_receiver(nativePtr, nil)
            return
        }
        
        cs_data_pipe_register_receiver(nativePtr) { idNative, dataWrapperNative in
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
    
    /**
            
     1. Pull data proactively, possible pull to cache.
     2. The frequency is based on the frequency of pull.
     3. Need to stop datapipe manually When don't need to run the datapipe
     */
    func PullPixelData() -> CVPixelBuffer? {
        return nil
    }
}

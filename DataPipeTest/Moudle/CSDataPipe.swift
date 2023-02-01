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
    var displayLink: CADisplayLink?
    
    init() {
//        print("CSDataPipe init")
        nativePtr = cs_data_pipe_create()
        createVsyncCaller()
    }
    
    deinit {
//        print("CSDataPipe release")
        stopVsyncCaller()
        cs_data_pipe_release(nativePtr)
    }
    
    func setup() {
        let swiftObjectRef = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        cs_data_pipe_binding(nativePtr, swiftObjectRef)
    }
    
    func createVsyncCaller() {
        if displayLink != nil {
            stopVsyncCaller()
        }
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func stopVsyncCaller() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc func handleDisplayLink() {
        cs_data_pipe_vsync(nativePtr)
    }
    
    func setMainInputAndOutput(input: CSSourceNodeImplement, output: CSSourceNodeImplement) {
        cs_data_pipe_set_main_source(nativePtr, input.nativePtr)
        cs_data_pipe_set_output_node(nativePtr, output.nativePtr)
    }
    
    func getOutputDataType() -> CSDataCategory {
        let outputPointer = cs_data_pipe_get_out_put_node(nativePtr)
        guard let category = CSDataCategory(rawValue: cs_data_cache_get_data_category(outputPointer).rawValue) else {
            return CSDataCategory.BIN
        }
        return category
    }
    
    func createOrCachePixelBuffer(bytesPerRow: Int, width: Int, height: Int, colorSpace: OSType) -> CVPixelBuffer? {
        guard let pixelBuffer = _pixelBuffer else {
            var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)
            CVPixelBufferCreateWithBytes(nil, width, height, colorSpace, &pixelData, bytesPerRow, nil, nil, nil, &_pixelBuffer)
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
    
    
    func handleReceiverCommondData(dataPointer: UnsafeMutableRawPointer) {
        
    }
    
    func handleReceiverPCMData(dataPointer: UnsafeMutableRawPointer) {
        
    }
    
    func handleReceiverCVPixelBuffer(dataPointer: UnsafeMutableRawPointer, bytesPerRow: Int, width: Int, byteSize: Int, colorSpace: OSType) {
        
        let height = byteSize / bytesPerRow
        
        guard let pixelBuffer = createOrCachePixelBuffer(bytesPerRow: bytesPerRow, width: width, height: height, colorSpace: colorSpace) else {
            return
        }
        
        CSDataUtils.copyBinary2PixelBuffer(binaryPointer: dataPointer, pixelBuffer: pixelBuffer, dataSizePerRow: bytesPerRow)
    
        DispatchQueue.main.async  {
            self.callPixelCallBack()
        }
    }
    
    
    
    
    
    
    
}


extension CSDataPipe {
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
        
        cs_data_pipe_register_receiver(nativePtr) { wrapperObject, dataWrapperNative in
            guard let wrapperObject = wrapperObject,
                  let dataWrapperNative = dataWrapperNative else {
                return
            }
            
            let dataPipeWeakRef = Unmanaged<CSDataPipe>.fromOpaque(wrapperObject).takeUnretainedValue()
   
            
            guard let dataInC = dataWrapperNative.pointee.data else {
                return
            }

            let outPutDataType = dataPipeWeakRef.getOutputDataType()
            switch outPutDataType {
            case .PCM :
                dataPipeWeakRef.handleReceiverPCMData(dataPointer: dataInC)
                break
            case .BIN :
                dataPipeWeakRef.handleReceiverCommondData(dataPointer: dataInC)
                break
            default:
                let outputPointer = cs_data_pipe_get_out_put_node(dataPipeWeakRef.nativePtr)
                let bytesPerRow = cs_data_cache_get_bytes_per_row(outputPointer)
                let width = cs_data_cache_get_width(outputPointer)
                let byteSize = dataWrapperNative.pointee.dataSize
                
                
                switch outPutDataType {
                case .NV21:
                    dataPipeWeakRef.handleReceiverCVPixelBuffer(dataPointer: dataInC, bytesPerRow: Int(bytesPerRow), width: Int(width), byteSize: Int(byteSize), colorSpace: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                case .BGRA32:
                    dataPipeWeakRef.handleReceiverCVPixelBuffer(dataPointer: dataInC, bytesPerRow: Int(bytesPerRow), width: Int(width), byteSize: Int(byteSize), colorSpace: kCVPixelFormatType_32BGRA)
                case .RGBA32:
                    dataPipeWeakRef.handleReceiverCVPixelBuffer(dataPointer: dataInC, bytesPerRow: Int(bytesPerRow), width: Int(width), byteSize: Int(byteSize), colorSpace: kCVPixelFormatType_32RGBA)
                default:
                    break
                }
            }
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

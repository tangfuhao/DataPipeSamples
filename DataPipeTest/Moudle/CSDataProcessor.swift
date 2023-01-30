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
    
    func connectInput(input: CSDataSource)
}



class CSDataProcessor : CSDataSource, CSProcessorProtocol {
    var dependentUnits = [CSUnitBase]()
    
    override func onInit() {
        nativePtr = cs_data_processor_create()
    }
    
    func onProcess() {}

    
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
        dependentUnits.append(input)
        cs_data_processor_connect_dep(nativePtr,input.nativePtr)
    }
    

    

    
    
}

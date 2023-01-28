//
//  CSDataProcessor.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo


protocol ProcessorProtocol {
    
}


class CSDataProcessorBase : CSUnitProtocol {
    typealias Model = CSProcessUnitNative
    let nativePtr = cs_data_processor_create()
    
    func onInit() {
        
    }
    
    func onRelease() {
        
    }
    
    func getNativePtr() -> UnsafeMutablePointer<CSProcessUnitNative> {
        return nativePtr!
    }
}


typealias CSDataProcessorProtocol = ProcessorProtocol & CSDataProcessorBase

class CSDataProcessor : CSDataProcessorProtocol {

}

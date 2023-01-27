//
//  CSDataPipe.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo


public typealias pixelCallBack = (_ : CVPixelBuffer) -> Void

class CSDataPipeTopology {
    var mainSource: CSDataSource?
    
    func setMainSource(_ source: CSDataSource) {
        mainSource = source
    }
    
    func setInOutPipe(in: CSDataSource, out: CSDataSource) {
        
    }
}



class CSDataPipe {
    public static func createTopology() -> CSDataPipeTopology{
        return CSDataPipeTopology()
    }
    
    public static func createDataPipe(tepology: CSDataPipeTopology) -> CSDataPipe {
        return CSDataPipe()
    }
    
//    let nativePtr: UnsafeMutablePointer<CSDataPipe>
    
    init() {
//        nativePtr = cs_data_pipe_create()
    }
    
    deinit {
        print("CSDataPipe release")
//        cs_data_pipe_release()
    }
    
    
    func receiverCVPixelBuffer(callback: pixelCallBack) {
        
    }
    
    
    
    
    
}

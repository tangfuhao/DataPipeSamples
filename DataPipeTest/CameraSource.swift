//
//  CameraSource.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/26.
//

import Foundation
import CoreVideo
import CoreMedia


class CameraSource : CSSourcePProtocol {
    var cameraCapture: CameraCapture?
    
    override init() {
        super.init()
        print("CameraSource init")
    }
    
    deinit{
        print("CameraSource deinit")
    }
    
    
    
    func onInit() {
        cameraCapture = CameraCapture(delegate: self)
        cameraCapture?.startCapture(ofCamera: .front)
    }
    
    func onRelease() {
        cameraCapture?.stopCapture()
        cameraCapture = nil
    }
    
    func onRegisterDataType() -> CSDataType {
        return CSDataType(format: .PixelBuffer)
    }

}

extension CameraSource: CameraCapturePushDelegate {
    func myVideoCapture(_ capture: CameraCapture, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        storePixelData(pixelBuffer: pixelBuffer)
    }
}

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
    
    func onInit() {
        cameraCapture = CameraCapture(delegate: self)
        cameraCapture?.startCapture(ofCamera: .front)
    }
    
    func onRelease() {
        cameraCapture?.stopCapture()
        cameraCapture = nil
    }
    
    func onRegisterDataType() -> CSDataType {
        return CSDataType(format: .PixelBuffer,pixelParams: CSPixelParams(width: 640, height: 480, colorSpace: .NV21))
    }

}

extension CameraSource: CameraCapturePushDelegate {
    func myVideoCapture(_ capture: CameraCapture, didOutputSampleBuffer pixelBuffer: CVPixelBuffer, rotation: Int, timeStamp: CMTime) {
        print("w:\(CVPixelBufferGetWidth(pixelBuffer)) ,h: \(CVPixelBufferGetHeight(pixelBuffer)) ")
        storePixelData(pixelBuffer: pixelBuffer)
    }
}

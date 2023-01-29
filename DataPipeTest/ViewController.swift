//
//  ViewController.swift
//  DataPipeTest
//
//  Created by fuhao on 2023/1/19.
//

import UIKit

class ViewController: UIViewController {
    var dataPipe: CSDataPipe?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        //create data pipe topology
        let topology = CSDataPipe.createTopology()
        
        let dataSource = CameraSource()
        let dataProcesser = YUV2RGBProcessor()
        topology.setMainInputAndOutput(input: dataSource, output: dataProcesser)
        topology.connectPipe(input: dataSource, output: dataProcesser)
        
        
        //create data pipe
        let dataPipe = CSDataPipe.createDataPipe(tepology: topology)
        self.dataPipe = dataPipe
        
        dataPipe.receiverCVPixelBuffer { pixelBuffer in
            print("width: \(CVPixelBufferGetWidth(pixelBuffer))")
            
        }
        
        


//        var dataProcesser2 = CSDataProcessor()
//
//        dataProcesser.addInput(source: dataSource,index: 0)
//        dataProcesser2.addInput(source: dataSource, index: 0)
        
    }


}


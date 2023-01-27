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
        
        
        let topology = CSDataPipe.createTopology()
        let dataSource = CSDataSource()
        let dataProcesser = CSDataProcessor()
        topology.setMainSource(dataSource)
        topology.setInOutPipe(in: dataSource, out: dataProcesser)
        
        let dataPipe = CSDataPipe.createDataPipe(tepology: topology)
        self.dataPipe = dataPipe
        dataPipe.receiverCVPixelBuffer() { data in
            
        }
        
        


//        var dataProcesser2 = CSDataProcessor()
//
//        dataProcesser.addInput(source: dataSource,index: 0)
//        dataProcesser2.addInput(source: dataSource, index: 0)
        
    }


}


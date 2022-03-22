//
//  ViewController.swift
//  GraphQLMultiUrl
//
//  Created by Kant, Lalit on 22/03/22.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        // This is just a mock request, Please use realtime request and you will see fingerprint certificate pinning will be working
        GraphQLNetworkManager().getApollo(type: .filmList).fetch(query: AllFilmsQuery()) {  result in
            switch result {
            case .success(let graphQLResult):
                debugPrint(graphQLResult)
            case .failure(let error):
                debugPrint(error)
            }
        }
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}


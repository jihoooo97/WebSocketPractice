//
//  ViewController.swift
//  WebSocketPractice
//
//  Created by 유지호 on 2023/05/23.
//

import UIKit
import Starscream
import SnapKit

class ViewController: UIViewController {
    
    fileprivate let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    fileprivate lazy var pingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.setTitle("ping", for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(clickPingButton), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var connectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.setTitle("Connect WebSocket", for: .normal)
        button.addTarget(self, action: #selector(clickConnectSocketButton), for: .touchUpInside)
        return button
    }()
    
    private var socket: WebSocket?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        initConstraints()
        setupWebSocket()
    }
    
    deinit {
        socket?.disconnect()
        socket?.delegate = nil
    }
    
    
    private func setupWebSocket() {
        let url = URL(string: "wss://ws.blockchain.info/inv")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    
    @objc private func clickPingButton() {
        messageLabel.text = "ping!"
        
        let dic : NSDictionary = ["op" : "ping"]
        let jsonData = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8)
        socket?.write(string: jsonString!)
    }
    
    @objc private func clickConnectSocketButton() {
        socket?.connect()
    }
    
    private func initConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        [messageLabel, pingButton, connectButton].forEach {
            view.addSubview($0)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.bottom.equalTo(pingButton.snp.top).offset(-32)
            make.centerX.equalToSuperview()
        }
        
        pingButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(80)
        }
        
        connectButton.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(safeArea)
            make.height.equalTo(56)
        }
    }
    
}


extension ViewController: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            guard
                let data = string.data(using: .utf16),
                let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                let jsonDic = jsonData as? NSDictionary
            else {
                return
            }
            let result = jsonDic["op"] as? String
            messageLabel.text = result
            
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("websocket is cancelled")
        case .error(let error):
            handleError(error)
        }
    }
    
}

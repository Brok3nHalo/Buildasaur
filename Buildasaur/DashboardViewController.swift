//
//  DashboardViewController.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 28/09/2015.
//  Copyright © 2015 Honza Dvorsky. All rights reserved.
//

import Cocoa
import BuildaKit
import ReactiveCocoa

class DashboardViewController: NSViewController {

    @IBOutlet weak var syncersTableView: NSTableView!
    
    //TODO: figure out a way to inject this instead
    let storageManager: StorageManager = StorageManager.sharedInstance
    
    private var syncerViewModels: [SyncerViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configDataSource()
        self.configTableView()
    }
    
    func configTableView() {
        
        let tableView = self.syncersTableView
        tableView.setDataSource(self)
        tableView.setDelegate(self)
        tableView.columnAutoresizingStyle = .UniformColumnAutoresizingStyle
    }
    
    func configDataSource() {
        
        self.storageManager.syncers.producer.startWithNext { newSyncers in
            self.syncerViewModels = newSyncers.map { SyncerViewModel(syncer: $0) }
            self.syncersTableView.reloadData()
        }
    }
    
    
    
}

extension DashboardViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.syncerViewModels.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        let syncerViewModel = self.syncerViewModels[row]
        guard let columnIdentifier = tableColumn?.identifier else { return nil }
        let object = syncerViewModel.objectForColumnIdentifier(columnIdentifier)
        return object
    }
}

extension DashboardViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }
}


//
//  EmbedSegueViewContainerProvider.swift
//  ViperMcFlurrySwift
//
//  Created by Cheslau Bachko on 2/4/20.
//

import Foundation

public protocol EmbedSegueContainerViewProvider {
    func containerViewForSegue(_ identifier: String) -> UIView?
}

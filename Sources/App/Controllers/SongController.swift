//
//  SongController.swift
//  
//
//  Created by Andrei Chenchik on 28/10/21.
//

import Fluent
import Vapor

struct SongController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let songs = routes.grouped("songs")
        
    }
}
